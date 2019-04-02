"""
Author:	George Mostyn-Parry

Middle-man between base Networking singleton, and the distinct implementation details of this project.
"""
extends "res://Scripts/Networking.gd"

#Tell listening that the player with the passed ID has changed name.
signal player_changed_name(player_id, new_name)
#Tell listening that the player with the passed ID has changed team.
signal player_changed_team(player_id, player_info, old_team_id)
#Tell listening that the player with the passed ID has changed role is not called when team changes aswell.
signal player_changed_role(player_id, new_role)

#Tells listening when a team changes its name.
signal team_changed_name(team_id, new_name)
#Tells listening when a team changes its colour.
signal team_changed_colour(team_id, new_colour)

#The value that stores the id for the next created team.
var _next_team_id = 1

#Host a server on the passed port, which can take at most max_players, as a player identified with player_name.
func create_server(port, max_players, player_name):
	_setup_peer_host(port, max_players)

	#Perform set-up for server creation, only if the server was successfully created.
	if get_tree().has_network_peer():
		_set_local_player_info({name = player_name, team_id = 0, role = "Spectator"})

		#We only want the host to send the information to the new player.
		connect("new_player", self, "_on_new_player")

#Joins a server with the passed ip on the passed port, as a player identified with player_name.
func join_server(ip, port, player_name):
	_setup_peer_client(ip, port)

	#Perform set-up for client creation, only if the client was successfully created.
	if get_tree().has_network_peer():
		_set_local_player_info({name = player_name, team_id = 0, role = "Spectator"})

#Updates the info of the local player, and tells server of changes.
func update_local_player_info(new_name, new_team_id, new_role):
	#Get old information on local player.
	var old_player_info = get_local_player_info()
	var new_player_info = {name = new_name, team_id = new_team_id, role = new_role}

	#Update local information.
	_set_local_player_info(new_player_info)

	#Tell other players to update their information on this player.
	rpc("_update_player_info", new_player_info)

	#Tell listening that the players name changed, if it has.
	if new_name != old_player_info.name:
		emit_signal("player_changed_name", get_tree().get_network_unique_id(), new_name)

	#If the player changed teams, then emit a signal to tell the rest of the program.
	if new_team_id != old_player_info.team_id:
		emit_signal("player_changed_team", get_tree().get_network_unique_id(), new_player_info, old_player_info.team_id)
		rpc("_player_team_changed", new_player_info, old_player_info.team_id)

		#Remove the team if it was not the spectating team, and if it has no players.
		if old_player_info.team_id != 0 && !_team_has_players(old_player_info.team_id):
			_remove_team(old_player_info.team_id)
	#Only check the role changed if the team has not changed if so tell all that are listening of the change.
	elif new_role != old_player_info.role:
		emit_signal("player_changed_role", get_tree().get_network_unique_id(), new_role)
		rpc("_player_role_changed", new_role)

#Updates the local player's name as passed parameter.
func update_local_player_name(new_name):
	update_local_player_info(new_name, get_local_player_info().team_id, get_local_player_info().role)

#Updates the local player's team ID as passed parameter.
func update_local_player_team(new_team_id, new_role):
	update_local_player_info(get_local_player_info().name, new_team_id, new_role)

#Updates the local player's role as passed parameter.
func update_local_player_role(new_role):
	update_local_player_info(get_local_player_info().name, get_local_player_info().team_id, new_role)

#Create team with name and colour, and tell peers.
#Returns the ID of the new team.
func create_team(team_name, team_colour):
	#Create ID for team.
	var team_id = _create_next_team_id()

	#Synchronise the creation of the team.
	rpc("_synchronised_team_creation", team_id, {name = team_name, colour = team_colour})

	return team_id

#Return a list of the IDs of all of the currently active teams.
func get_team_ids():
	return _info_teams.keys()

#Updates the team information, and sends new information to peers.
func set_team_info(team_id, team_name, team_colour):
	#Store old information, and form new information.
	var old_team_info = _info_teams[team_id]
	var new_team_info = {name = team_name, colour = team_colour}

	#Update information, and check for changes.
	_set_team_info(team_id, new_team_info)
	_check_team_changes(team_id, old_team_info)

	#Send new information to peers.
	rpc("_receive_team_info", team_id, new_team_info)

#Return the information stored on the team with the passed ID.
func get_team_info(team_id):
	return _info_teams[team_id]

#Set the team's name to the new value.
func set_team_name(new_name, team_id):
	set_team_info(team_id, new_name, get_team_info(team_id).colour)

#Set the team's colour to the new value.
func set_team_colour(new_colour, team_id):
	set_team_info(team_id, get_team_info(team_id).name, new_colour)

## NETWORKED ##

#End all network connections can be called remotely to disconnect a user from the server.
puppet func end_connection():
	#If the host ended their connection, then stop listening for new players on this client.
	if is_network_master():
		disconnect("new_player", self, "_on_new_player")

	#Call base end connection to handle closing of connection.
	.end_connection()

### PRIVATE FUNCTIONS ###

#Increments next team ID variable and returns the ID for a new team.
func _create_next_team_id():
	#Increment and update value.
	_next_team_id += 1
	rpc("_sync_next_team_id", _next_team_id)

	#Return team ID that was stored.
	return _next_team_id - 1

#Handles synchronisation of player that has joined the server.
func _on_new_player(player_id):
	rpc_id(player_id, "_sync_next_team_id", _next_team_id)

#Handles state changing on the player leaving the server.
func _on_lost_player(player_id):
	var player_info = get_player_info(player_id)

	#Remove the team if it was not the spectating team, and if it has no players.
	if player_info.team_id != 0 && !_team_has_players(player_info.team_id, player_id):
		_remove_team(player_info.team_id)

#Returns whether a team has any players.
func _team_has_players(team_id, ignore_player_id = null):
	var is_player_in_team = false

	#An array of the player IDs.
	var keys = _info_players.keys()
	var i = 0

	#Erase the ignored player from the key list, if there is one to be removed.
	if ignore_player_id:
		keys.erase(ignore_player_id)

	#Search through player array for a player in the team break out if a player in the team was found.
	while !is_player_in_team && i < keys.size():
		is_player_in_team = team_id == _info_players[keys[i]].team_id
		i += 1

	return is_player_in_team

#Delete team with passed ID.
func _remove_team(team_id):
	rpc("_synchronised_team_deletion", team_id)

#Informs program of any changes to team information.
func _check_team_changes(team_id, old_team_info):
	var new_team_info = _info_teams[team_id]

	#Tell the rest of the program of the name change, if it occurred.
	if old_team_info.name != new_team_info.name:
		emit_signal("team_changed_name", team_id, new_team_info.name)

	#Tell the rest of the program of the colour change, if it occurred.
	if old_team_info.colour != new_team_info.colour:
		emit_signal("team_changed_colour", team_id, new_team_info.colour)

## INHERITED ##

func _ready():
	connect("lost_player", self, "_on_lost_player")

## NETWORKED ##

#Tells peers about team change.
remote func _player_team_changed(player_info, old_team_id):
	var player_id = get_tree().get_rpc_sender_id()
	emit_signal("player_changed_team", player_id, get_player_info(player_id), old_team_id)

#Tells peers about role change.
remote func _player_role_changed(new_role):
	emit_signal("player_changed_role", get_tree().get_rpc_sender_id(), new_role)

#Syncs next team ID across the network.
remote func _sync_next_team_id(_new_next_team_id):
	var sender_id = get_tree().get_rpc_sender_id()

	#Disconnect sender of RPC if data change isn't valid e.g. packet injection.
	#Host is immune.
	if sender_id != 1 && _new_next_team_id != _next_team_id + 1:
		rpc_id(sender_id, "leave_lobby")
	#Otherwise accept new value.
	else:
		_next_team_id = _new_next_team_id

#Sets the information on the team with the received data.
remote func _receive_team_info(team_id, new_team_info):
	var sender_id = get_tree().get_rpc_sender_id()

	#Disconnect sender of RPC if data change isn't valid e.g. packet injection.
	if get_player_info(sender_id).team_id != team_id:
		#Only send the kick from the master.
		if is_network_master():
			rpc_id(sender_id, "end_connection")
	else:
		#Store old team information before it is overridden.
		var old_team_info = _info_teams[team_id]

		#Update the old information with the new.
		_set_team_info(team_id, new_team_info)

		#Check for changes in the team information.
		_check_team_changes(team_id, old_team_info)