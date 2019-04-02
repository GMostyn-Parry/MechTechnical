"""
Author:	George Mostyn-Parry

Generic Networking singleton to handle when players join, and leave the server or their information is updated.
Also handles teams, and their information.
"""
extends Node

#Default networking values.
var DEFAULT_PORT = 27005
var DEFAULT_MAX_PLAYERS = 8

#Stores all of the information on the connected players uses their unique id as an index.
var _info_players = Dictionary()
#Stores the information on each team and is indexed by the team's ID.
var _info_teams = Dictionary()

#The RPC manager only pass to SceneTree when connected, or connecting, to server.
var _peer

#Tells listening that the player with id was gained.
signal new_player(id)
#Tells listening that the player with id was lost.
signal lost_player(id)
#Tells listening that the player's connection ended, and they need to return to the main menu.
signal connection_ended

#Tells listening when a team is added.
signal team_added(team_id, team_info)
#Tells listening when a team is removed.
signal team_removed(team_id)

#Returns the information of the player that had their ID passed.
func get_player_info(id):
	return _info_players[id]

#Returns the information of the local user.
func get_local_player_info():
	return get_player_info(get_tree().get_network_unique_id())

### NETWORKED FUNCTIONS ###

#Closes network connections function is networked, so client may be kicked from server.
puppet func end_connection():
	#Close connections.
	_peer.close_connection()
	get_tree().network_peer = null

	#Clear data.
	_info_players.clear()
	_info_teams.clear()

	#Tell listening that the connection ended, and they should handle the state change.
	emit_signal("connection_ended")

### PRIVATE FUNCTIONS ###

#Setup RPC peer for when the user creates a server.
func _setup_peer_host(port, max_players):
	#I've noticed issues with the list of connected peers if this is created once, and re-used.
	#i.e. Host leaves before client, and re-hosts, so it is created for each connection.
	_peer = NetworkedMultiplayerENet.new()

	#Only proceed if the server was successfully created.
	if _peer.create_server(port, max_players) == OK:
		get_tree().network_peer = _peer

#Setup RPC peer for when the user is joining a server.
func _setup_peer_client(ip, port):
	#I've noticed issues with the list of connected peers if this is created once, and re-used.
	#i.e. Host leaves before client, and re-hosts, so it is created for each connection.
	_peer = NetworkedMultiplayerENet.new()

	#Only proceed if the client was successfully created.
	if _peer.create_client(ip, port) == OK:
		get_tree().network_peer = _peer

#Sets the information of the local user.
func _set_local_player_info(new_player_info):
	_info_players[get_tree().get_network_unique_id()] = new_player_info

#Sends a message to the server, with the local player's player information, that they successfully joined.
func _successfully_joined_server():
	rpc("_confirm_join", get_local_player_info())

#Handles a player being removed from the server.
func _remove_player(id):
	#Tell nodes to remove their references to the player before the information is deleted.
	emit_signal("lost_player", id)
	_info_players.erase(id)

## INHERITED ##

func _ready():
	get_tree().connect("connected_to_server", self, "_successfully_joined_server")
	get_tree().connect("network_peer_disconnected", self, "_remove_player")

## NETWORKED ##

#Confirms to server that the player that called successfully joined the server, and passes their info to the server.
master func _confirm_join(info):
	var id = get_tree().get_rpc_sender_id()

	#Sync the new player with the network information.
	rpc_id(id, "_sync_data", _info_players, _info_teams)

	#Tell peers about the new player.
	rpc("_add_player", id, info)

#Overwrites client data with passed data.
puppet func _sync_data(server_info_players, server_info_teams):
	_info_players = server_info_players
	_info_teams = server_info_teams

# PLAYER FUNCTIONS #

#Handles a player being added to the server.
sync func _add_player(id, info):
	_info_players[id] = info
	emit_signal("new_player", id)

#Updates a player's information on remote peers.
remote func _update_player_info(info):
	var id = get_tree().get_rpc_sender_id()
	_info_players[id] = info

# TEAM #

#Creates a new team across the network with synchronised data.
sync func _synchronised_team_creation(team_id, team_info):
	#Create team with passed information.
	_info_teams[team_id] = team_info
	#Tell listening about the new team.
	emit_signal("team_added", team_id, team_info)

#Deletes the team with the passed ID synchronously across the network.
sync func _synchronised_team_deletion(team_id):
	#Tell listening about the new team.
	emit_signal("team_removed", team_id)
	#Removes information on team with passed ID.
	_info_teams.erase(team_id)

#Update the team's information to the passed parameter.
func _set_team_info(team_id, new_team_info):
	_info_teams[team_id] = new_team_info