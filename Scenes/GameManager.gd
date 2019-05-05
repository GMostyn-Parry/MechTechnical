"""
Author:	George Mostyn-Parry

Manager for the entire game state of the application.

TODO:
	- Some form of spawn selection for the Walker instead of placing them wherever.
	- Add gunner role, and add players who selected that role to the same team as their teamed driver and fellow gunners.
	- Add menu to quit back to start menu, or allow host to boot everyone back to lobby, and access options.
	- Add terrain/obstructions.
"""
extends Node2D

#Instanceable walker that the local player controls.
var PlayerWalkerNode = preload("res://Scenes/Entities/PlayerWalker.tscn")
#Instanceable walker that represents other players.
var WalkerNode = preload("res://Scenes/Entities/Walker.tscn")

#Stores a reference to the local player's walker.
var _local_players_walker

onready var _Camera = $MainCamera #The main camera of the scene.

#Adds a walker to the game at the position and with rotation, representing which player, and if it is the local players.
#is_local_players is passed to allow the method to be used offline.
#You can't check the network id when there is no network.
func _add_walker(spawn_position, spawn_rotation, player_id, is_local_players):
	#Stores a reference to the Walker we are adding.
	var walker
	#Add a PlayerWalker if it is the local players.
	if is_local_players:
		walker = PlayerWalkerNode.instance()
		_local_players_walker = walker

		walker.connect("stun_started", self, "_on_player_walker_stun_started")
		walker.connect("stun_ended", self, "_on_player_walker_stun_ended")

		#Set target to the player's walker.
		_Camera.target = walker;
	#Otherwise, add a regular walker.
	else:
		walker = WalkerNode.instance()

	#Set the name of the walker to something unique for networking.
	walker.name = "Walker" + String(player_id)
	#Set starting position and rotation of walker.
	walker.position = spawn_position
	walker.rotation = spawn_rotation

	#Add Walker to SceneTree, so it can be properly drawn and referenced.
	#Walker has to be added to SceneTree before signal connection otherwise we can't find the "Gun" sub-node.
	$Walkers.add_child(walker)

	#Retrieve the node that stores information on the Walker's gun.
	var gun = walker.get_node("Gun")
	#Connects signal from walker that they fired to bullet effects manager to display the bullet firing.
	#If the walker has a gun.
	if gun:
		walker.get_node("Gun").connect("bullet_fired", $Bullets, "add_bullet_trail")

	#Connects death signal from walker to handle their death passes the walker itself to give access for death handling.
	walker.connect("died", self, "_handle_dead_walker", [walker])

	#Set network master to passed player ID this doesn't matter if we are offline.
	walker.set_network_master(player_id)

#Leaves the game scene, and goes back to the start menu.
func _back_to_menu():
	#Stop processing to remaining walkers a half-second before ending the game to catch remaining RPC calls to arrive.
	for walker in $Walkers.get_children():
		walker.set_physics_process(false)
		walker.set_process_input(false)

	#Pause before leave to let any remaining RPC calls to arrive.
	yield(get_tree().create_timer(0.5), "timeout")

	#Switch back to menu.
	get_tree().change_scene("res://Scenes/Menu.tscn")

## NETWORKED ##

#Creates walkers synchronously across the network.
sync func _synchronised_add_walker(spawn_position, spawn_rotation, player_id):
	_add_walker(spawn_position, spawn_rotation, player_id, player_id == get_tree().get_network_unique_id())

#End connection to the game.
puppet func _quit_game():
	NetworkController.end_connection()

## INHERITED ##

func _ready():
	#End the connection if there is only the host.
	#Will cause at least one other walker to be present in the game.
	if get_tree().has_network_peer() && get_tree().get_network_connected_peers().size() == 0:
		NetworkController.end_connection()

	#End connection when disconnected from the server.
	get_tree().connect("server_disconnected", self, "_quit_game")
	#Go back to start menu when the connection ends.
	NetworkController.connect("connection_ended", self, "_back_to_menu")

	#Add walker for every player, if we are connected via a network and the server host.
	#We only want the host to set where each walker is.
	if get_tree().has_network_peer():
		if is_network_master():
			#Get the list of IDs of players connected to the server.
			var peers = get_tree().get_network_connected_peers()

			#Stores offset to prevent walkers from being placed inside each other.
			var offset = 200
			for player_id in peers:
				rpc("_synchronised_add_walker", Vector2(200 + offset, 200 + offset), 0, player_id)
				offset += 150

			#Add walker for host.
			rpc("_synchronised_add_walker", Vector2(200, 200), 0, get_tree().get_network_unique_id())
	#Otherwise, only add a player walker and a base walker i.e. for debugging.
	else:
		_add_walker(Vector2(400, 400), deg2rad(180), 0, false)
		_add_walker(Vector2(200, 200), 0, 1, true)

func _input(event):
	#Stop input to blend-map of background, if "canvas_stop_input" action pressed.
	if Input.is_action_just_pressed("canvas_toggle_input"):
		$Background.toggle_editing()

func _process(delta):
	#Updates the stun overlay while the local player's walker is alive.
	if _local_players_walker:
		$Effects/StunOverlay.material.set_shader_param("time_left", _local_players_walker.get_stun_remaining())

## SIGNALS MANUAL ##

#Show the stun overlay, and start changing it, on the local player's walker being stunned.
func _on_player_walker_stun_started(time_on_stun):
	#Store values the shader needs for displaying the stun.
	$Effects/StunOverlay.material.set_shader_param("time_starting", _local_players_walker._time_until_unstunned)
	$Effects/StunOverlay.material.set_shader_param("time_left", _local_players_walker._time_until_unstunned)
	$Effects/StunOverlay.visible = true

#Hide the stun overlay, on the local player's walker no longer being unstunned.
func _on_player_walker_stun_ended():
	$Effects/StunOverlay.visible = false

#Cleans up walkers on their death leaves a corpse to show where the walker died.
func _handle_dead_walker(walker):
	#Strip sprite from walker to represent the death.
	var sprite = walker.get_node("Sprite")
	#Must be removed from walker, before adding new parent.
	walker.remove_child(sprite)
	$Debris.add_child(sprite)

	#Transform sprite to walker's position.
	sprite.transform = walker.transform

	#Null the reference to the local player's walker if it was the killed walker.
	if walker == _local_players_walker:
		_local_players_walker = null
		_Camera.target = null

	#Pause cleanup to let any remaining RPC calls to arrive.
	yield(get_tree().create_timer(0.5), "timeout")

	#Remove the now dead walker from child list child must be removed for next check on child count.
	$Walkers.remove_child(walker)
	walker.queue_free()

	#Quit to lobby if all, bar one, of the walkers are dead.
	if $Walkers.get_child_count() <= 1:
		$Timers/ReturnTimer.start()

#Return to menu when the return timer elapses.
func _on_ReturnTimer_timeout():
	_back_to_menu()