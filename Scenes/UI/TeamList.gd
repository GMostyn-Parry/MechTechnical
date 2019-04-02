"""
Author:	George Mostyn-Parry

A list that displays all of the teams in the game, and the players that are in each team, using a list of TeamItems.
"""
extends PanelContainer

#Stores a instanceable team item node to display team information.
var TeamItemNode = preload("res://Scenes/UI/TeamItem.tscn")

#Sets the team list to its default state.
func reset():
	#Removes all displayed teams from the list.
	for child in $ScrollContainer/Teams.get_children():
		$ScrollContainer/Teams.remove_child(child)
		child.queue_free()

## TEAM FUNCTIONS ##

#Adds a team to the TeamList.
func add_team(team_id, team_info):
	var new_team = TeamItemNode.instance()
	new_team.set_team_name(team_info.name)
	new_team.set_team_colour(team_info.colour)
	#Store the ID as metadata so we can use it to compare IDs.
	new_team.set_meta("ID", team_id)
	#Set the node's name to something unique.
	new_team.name = "TeamItem" + String(team_id)

	$ScrollContainer/Teams.add_child(new_team)

#Removes a team from the TeamList.
func remove_team(team_id):
	_find_team(team_id).queue_free()

#Sets the displayed team name to the new value.
func set_team_name(team_id, new_name):
	_find_team(team_id).set_team_name(new_name)

#Sets the displayed team colour to the new value.
func set_team_colour(team_id, new_colour):
	_find_team(team_id).set_team_colour(new_colour)

## PLAYER FUNCTIONS ##

#Adds a player to the TeamList.
func add_player(player_id, player_info, is_ready):
	_find_team(player_info.team_id).add_player(player_id, player_info, is_ready)

#Removes a player from the TeamList.
func remove_player(player_id, team_id):
	_find_team(team_id).remove_player(player_id)

#Sets whether the player is displayed as ready.
func set_player_ready(player_id, is_ready, team_id):
	_find_team(team_id).set_player_ready(player_id, is_ready)

#Sets the displayed name of the player.
func set_player_name(player_id, new_name, team_id):
	_find_team(team_id).set_player_name(player_id, new_name)

#Sets the players team to the new team, and removes them from the old team.
#Does not keep player's ready state if you want to player to still be ready on a team change you must set them to ready.
#player_info is the updated player information, not the old information.
func set_player_team(player_id, player_info, old_team_id):
	#Remove the player from their old team.
	remove_player(player_id, old_team_id)

	#Add the player to their new team, as not ready.
	add_player(player_id, player_info, false)

#Sets the displayed role of the player.
func set_player_role(player_id, new_role, team_id):
	_find_team(team_id).set_player_role(player_id, new_role)

### PRIVATE FUNCTIONS ###

#Returns the TeamItem that stores the information on the team.
#Returns null if the team could not be found.
func _find_team(team_id):
	#The item that was found.
	var found_team_item = null

	#The list of TeamItems and an interator to go through them.
	var children = $ScrollContainer/Teams.get_children()
	var i = 0

	#Iterate through and search for the TeamItem that represents the team break when found.
	while !found_team_item && i < children.size():
		if children[i].get_meta("ID") == team_id:
			found_team_item = children[i]
		i += 1

	return found_team_item