"""
Author:	George Mostyn-Parry

Networked menu to process players joining session, and passing them to the game.

TODO:
	- Give max team amount an effect.
	- Reload max team amount on coming back from the game.
	- Handle when player joins mid-game.
"""
extends MarginContainer

#Instanceable node that allows control over team information, and allows players to join that team in a certain role.
var TeamSlotNode = preload("res://Scenes/UI/TeamSlot.tscn");

#Stores a look-up table to the TeamSlots indexed by their team's ID.
var _table_team_slots = Dictionary();
#A look-up table of the players, and their ready state.
var _table_ready_players = Dictionary();

#The maximum amount of teams allowed.
var _max_team_amount = 8;

#The team ID of the spectator team.
const SPECTATOR_ID = 0;
#The information on the spectator team.
const SPECTATOR_INFO = {name = "Spectators", colour = Color(1, 1, 1)};

#Load information back into lobby after a game has finished.
func load_information_after_game():
	#Add "Spectators" team to list of teams; as it is the team that can't be removed it should be on the top of the list.
	$Ordering/TeamArea/Ordering/TeamList.add_team(SPECTATOR_ID, SPECTATOR_INFO);
	#Add teams to lobby.
	for team_id in NetworkController.get_team_ids():
		_add_team(team_id, NetworkController.get_team_info(team_id));

	#Add players to lobby.
	for player_id in get_tree().get_network_connected_peers():
		_add_player(player_id, NetworkController.get_player_info(player_id), false);
	#Add the local player; local player is not a connected peer so must be done in addition to the loop.
	_add_player(get_tree().get_network_unique_id(), NetworkController.get_local_player_info(), false);

### PRIVATE FUNCTIONS ###

#Sets lobby to default state.
func _reset():
	#Clear dictionary.
	_table_ready_players.clear();

	#Remove all TeamSlot's that exist, so blank TeamSlot's can take their place.
	for team_slot in $Ordering/TeamArea/Ordering/Teams.get_children():
		#Not removing the child can cause issues if a new node is added with the same name before it was freed.
		$Ordering/TeamArea/Ordering/Teams.remove_child(team_slot);
		team_slot.queue_free();

	#Reset max team amount; setting value comes first to prevent RPC call.
	_max_team_amount = 8;
	$Ordering/TopControls/MaxTeamAmount/ValueSelect.value = 8;

	#Reset team list to default state.
	$Ordering/TeamArea/Ordering/TeamList.reset();

#Creates representations of the team for the lobby, when a team is added.
func _add_team(team_id, team_info):
	#Create, and setup, the TeamSlot.
	var new_team_slot = TeamSlotNode.instance();
	new_team_slot.setup_team(team_id, team_info.name, team_info.colour);

	#Connect signals to functions to pass on updates of state.
	new_team_slot.connect("changed_team_name", NetworkController, "set_team_name", [team_id]);
	new_team_slot.connect("changed_team_colour", NetworkController, "set_team_colour", [team_id]);
	new_team_slot.connect("player_applied_for_role", self, "_on_player_applied_for_role", [team_id]);
	new_team_slot.connect("team_emptied", NetworkController, "remove_team", [team_id]);

	#Add as a child node, and add a reference to the table.
	$Ordering/TeamArea/Ordering/Teams.add_child(new_team_slot);
	_table_team_slots[team_id] = new_team_slot;

	#Add new team to team list.
	$Ordering/TeamArea/Ordering/TeamList.add_team(team_id, team_info);

#Removes representations of the team in the lobby, when a team is removed.
func _remove_team(team_id):
	_table_team_slots[team_id].queue_free();
	_table_team_slots.erase(team_id);

	$Ordering/TeamArea/Ordering/TeamList.remove_team(team_id);

#Adds the player to the lobby with the passed information.
func _add_player(player_id, player_info, is_ready):
	#Update member variables.
	_table_ready_players[player_id] = is_ready;
	#Updates display.
	$Ordering/TeamArea/Ordering/TeamList.add_player(player_id, player_info, is_ready);

#Sets whether a player is ready, and updates the display with the new state.
func _set_player_ready(player_id, is_ready):
	#Update stored value.
	_table_ready_players[player_id] = is_ready;
	#Update display of ready state.
	$Ordering/TeamArea/Ordering/TeamList.set_player_ready(
			player_id,
			is_ready,
			NetworkController.get_player_info(player_id).team_id);

	#Check if the transition timer can start, if the player's ready state was set to true.
	if is_ready:
		_start_transition_timer_if_ready();
	#Stop the timer if a player was set to not ready.
	else:
		$Timers/StartGameTimer.stop();

#Starts the timer to switch to Game scene, if all conditions are met; i.e. all players ready, enough teams, etc.
func _start_transition_timer_if_ready():
	var are_all_players_ready = true;

	#Find if any player is not set to ready, and set flag to false.
	#Will break out on finding a player that is not ready.
	for is_player_ready in _table_ready_players.values():
		if !is_player_ready:
			are_all_players_ready = false;
			break;

	#Only start timer if all players are ready.
	if are_all_players_ready:
		$Timers/StartGameTimer.start();

## INHERITED ##

func _ready():
	#Handle when a player joins, or leaves, the server.
	NetworkController.connect("new_player", self, "_on_new_player");
	NetworkController.connect("lost_player", self, "_on_lost_player");
	#Quit lobby when disconnected from the server.
	get_tree().connect("server_disconnected", self, "_quit_lobby");

	#Update displayed information when a player changes their information.
	NetworkController.connect("player_changed_name", self, "_on_player_changed_name");
	NetworkController.connect("player_changed_team", self, "_on_player_changed_team");
	NetworkController.connect("player_changed_role", self, "_on_player_changed_role");

	#Update displayed information when a team is added, or removed.
	NetworkController.connect("team_added", self, "_add_team");
	NetworkController.connect("team_removed", self, "_remove_team");

	#Update displayed information when a team's information is updated.
	NetworkController.connect("team_changed_name", self, "_on_team_changed_name");
	NetworkController.connect("team_changed_colour", self, "_on_team_changed_colour");

func _input(event):
	#~~ Fix to mouse locking bug with Spinbox. May be fixed in Godot 3.1 ###
	if event is InputEventMouseButton && event.button_index == BUTTON_LEFT && !event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);
	### Fix to mouse locking bug with Spinbox. May be fixed in Godot 3.1 ~~#

func _process(delta):
	#Get the time left on the transition timer.
	var time_left = $Timers/StartGameTimer.time_left;

	#Tell users that all players must be ready to start, if the timer is not running; i.e. not all players are ready.
	if time_left == 0:
		$Ordering/BottomControls/CenterContainer/TimeToStart.text = "All players must be ready to start.";
	#Otherwise, show how much time is left on the timer.
	else:
		#Displayed in steps of 0.05 to prevent the clock getting stuck on just above 0.00.
		#There are other methods, such as background loading,
		#but this is the easiest and it barely makes a visual difference.
		$Ordering/BottomControls/CenterContainer/TimeToStart.text = \
				"Game Starts in: %0.2f Seconds." % stepify(time_left, 0.05);

## NETWORKED ##

#Changes max team amount on clients to passed parameter.
slave func _override_max_team_amount(new_max_team_amount):
	_max_team_amount = new_max_team_amount;

	$Ordering/TopControls/MaxTeamAmount/ValueSelect.value = _max_team_amount;

#Changes the table of ready players to the passed parameter, and adds themselves to it.
slave func _override_table_ready_players(server_table_ready_players):
	_table_ready_players = server_table_ready_players;
	_table_ready_players[get_tree().get_network_unique_id()] = false;

#Reloads displayed information about teams into lobby.
slave func _reload_teams():
	#Add teams to the lobby's displayed information.
	for team_id in NetworkController.get_team_ids():
		_add_team(team_id, NetworkController.get_team_info(team_id));

	#Add each player into their team.
	for player_id in get_tree().get_network_connected_peers():
		var player_info = NetworkController.get_player_info(player_id);

		#Add the player to the list of players.
		_add_player(player_id, player_info, _table_ready_players[player_id]);

#Tells program to leave the lobby.
slave func _quit_lobby():
	NetworkController.end_connection();

#Receive whether the sender is ready, and update information on sender.
remote func _receive_sender_ready(is_ready):
	#Update sender's ready state with received value.
	_set_player_ready(get_tree().get_rpc_sender_id(), is_ready);

## SIGNALS MANUAL ##

#Updates players team or role, depending on if the team and role was different.
func _on_player_applied_for_role(new_role, team_id):
	var player_info = NetworkController.get_local_player_info();

	#If the team was different, then change their team.
	if team_id != player_info.team_id:
		NetworkController.update_local_player_team(team_id, new_role);
	#Otherwise, make sure the role actually changed before calling for an update.
	elif new_role != player_info.role:
		NetworkController.update_local_player_role(new_role);

#Updates the player's displayed name when a change in the player's name has been signalled.
func _on_player_changed_name(player_id, new_name):
	$Ordering/TeamArea/Ordering/TeamList.set_player_name(
			player_id,
			new_name,
			NetworkController.get_player_info(player_id).team_id);

	#Player is not ready if they are changing information.
	_set_player_ready(player_id, false);

#Swap display showing player's team from the old team to the new team.
func _on_player_changed_team(player_id, player_info, old_team_id):
	$Ordering/TeamArea/Ordering/TeamList.set_player_team(player_id, player_info, old_team_id);

	#Only change editability if the team was the local player's team.
	if player_id == get_tree().get_network_unique_id():
		#Spectators do not have a TeamSlot.
		if old_team_id != 0:
			#Remove player's ability to edit the old team.
			_table_team_slots[old_team_id].set_editable(false);

		#Give the player the ability to edit the new team.
		_table_team_slots[player_info.team_id].set_editable(true);

	#Player is not ready if they are changing information.
	_set_player_ready(player_id, false);

#Updates the player's displayed role when a change in the player's role has been signalled.
func _on_player_changed_role(player_id, new_role):
	$Ordering/TeamArea/Ordering/TeamList.set_player_role(
			player_id,
			new_role,
			NetworkController.get_player_info(player_id).team_id);

	#Player is not ready if they are changing information.
	_set_player_ready(player_id, false);

#Handles when a player connects to the server.
func _on_new_player(player_id):
	if is_network_master():
		#Sync member variables.
		rpc_id(player_id, "_override_max_team_amount", _max_team_amount);
		rpc_id(player_id, "_override_table_ready_players", _table_ready_players);

		#Reload display of teams.
		rpc_id(player_id, "_reload_teams");

	#Add player to the list of players.
	_add_player(player_id, NetworkController.get_player_info(player_id), false);

#Handles when a player disconnects from the server; cleaning up information on them.
func _on_lost_player(player_id):
	#Remove player from display.
	$Ordering/TeamArea/Ordering/TeamList.remove_player(
			player_id,
			NetworkController.get_player_info(player_id).team_id);

	#Remove player from member variables.
	_table_ready_players.erase(player_id);

#Updates displayed team name when a change is signalled.
func _on_team_changed_name(team_id, new_name):
	_table_team_slots[team_id].set_team_name(new_name);
	$Ordering/TeamArea/Ordering/TeamList.set_team_name(team_id, new_name);

#Updates displayed team colour when a change is signalled.
func _on_team_changed_colour(team_id, new_colour):
	_table_team_slots[team_id].set_team_colour(new_colour);
	$Ordering/TeamArea/Ordering/TeamList.set_team_colour(team_id, new_colour);

## SIGNALS AUTOMATIC ##

#Sets Lobby to correct state when made visible, or hidden.
func _on_Lobby_visibility_changed():
	if visible:
		#Disable max team amount value select, if the player is not the network master.
		$Ordering/TopControls/MaxTeamAmount/ValueSelect.editable = is_network_master();

		#Check it wasn't already connected from double visibility changed call; will be fixed in Godot 3.1.
		if $Ordering/TeamArea/Ordering/TeamList/ScrollContainer/Teams.get_child_count() == 0:
			#Add "Spectators" team to list of teams.
			$Ordering/TeamArea/Ordering/TeamList.add_team(SPECTATOR_ID, SPECTATOR_INFO);

			#Only let host add themselves; joining will reload the teams, and insert themselves.
			if is_network_master():
				#Add host to lobby.
				_add_player(get_tree().get_network_unique_id(), NetworkController.get_local_player_info(), false);
	#Free stored data, when they leave the lobby.
	else:
		# on lobby close.
		_reset();

#Syncs value of max allowed teams, if there value is different (i.e. it was re networked)
func _on_MaxTeamAmount_ValueSelect_value_changed(value):
	#If the _max_team_amount was set before hand, i.e. reset, or networked value.
	if _max_team_amount != value:
		_max_team_amount = value;
		rpc("_override_max_team_amount", value);

#Show the team creation dialog, when the user presses the create team button.
func _on_CreateTeam_pressed():
	$Dialogs/TeamCreationDialog.popup_centered();

#Creates team with information entered into the dialog, when the user confirms the dialog.
func _on_TeamCreationDialog_confirmed():
	#Retrieve information needed to create team.
	var dialog_information = $Dialogs/TeamCreationDialog.get_validated_information();

	#Only create the team if the user entered valid information.
	if dialog_information:
		#Dialog is no longer needed.
		$Dialogs/TeamCreationDialog.hide();
		#Create the team with the retrieved information, and store team ID returned.
		var team_id = NetworkController.create_team(dialog_information.name, dialog_information.colour);

		#Update the local player as joining the team.
		NetworkController.update_local_player_team(team_id, "Driver" if dialog_information.is_driver else "Gunner");

#Toggle ready state, when ready button is pressed.
#When all players have clicked ready a timer will begin counting down to the game starting.
func _on_Ready_pressed():
	#We are changing the state of the local player.
	var player_id = get_tree().get_network_unique_id()
	#Get inverse of stored ready state, as button represents a toggle.
	var is_ready = !_table_ready_players[player_id]

	#Toggle local player's ready state.
	_set_player_ready(player_id, is_ready);
	#Tell peers of their new state.
	rpc("_receive_sender_ready", is_ready);

#Change to game scene when the timer runs out.
func _on_StartGameTimer_timeout():
	get_tree().change_scene("res://Scenes/Game.tscn")