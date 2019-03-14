"""
Author:	George Mostyn-Parry

A tree to show the teams in the game; the players that are in that team, and the roles those players hold.
"""
extends Tree

#Stores a look-up table to the team TreeItems in the player tree indexed by their ID.
var _table_team_branches = Dictionary();
#Stores a look-up table to all player TreeItems in the player tree indexed by their ID.
var _table_player_leaves = Dictionary();

var _team_row_colour = Color(0.12, 0.11, 0.15);

#Restore PlayerTree to a default setting.
func reset():
	#Empty the tree.
	clear();

	#Create the root.
	create_item();

#Adds a team to the PlayerTree.
func add_team(team_id, team_info):
	var team_branch = create_item(get_root());
	team_branch.set_text(1, team_info.name);

	#Store reference to TreeItem in table for later look-up.
	_table_team_branches[team_id] = team_branch;

	#Change background to team colour.
	set_team_colour(team_id, team_info.colour);

#Sets the name of the team, with the passed ID.
func set_team_name(team_id, team_name):
	_table_team_branches[team_id].set_text(1, team_name);

#Sets background of team row to team colour.
func set_team_colour(team_id, team_colour):
	var team_branch = _table_team_branches[team_id];

	#Sets background to team colour.
	team_branch.set_custom_bg_color(0, team_colour);
	team_branch.set_custom_bg_color(1, team_colour);
	team_branch.set_custom_bg_color(2, team_colour);

	#Sets text colour to white if the colour is too light.
	if team_colour.gray() < 0.6:
		team_branch.set_custom_color(1, Color(1, 1, 1));
	#Otherwise, the text colour is black.
	else:
		team_branch.set_custom_color(1, Color(0, 0, 0));

#Returns if the team contains no players.
func is_team_empty(team_id):
	return _table_team_branches[team_id].get_children() == null;

#Removes team, with the passed ID, from the PlayerTree.
func remove_team(team_id):
	get_root().remove_child(_table_team_branches[team_id]);
	_table_team_branches.erase(team_id);

#Add the player with the passed ID to the tree.
func add_player(player_id, is_ready, player_info):
	_create_player_leaf(_table_team_branches[player_info.team_id], player_id, is_ready, player_info.name, player_info.role);

#Set the player's ready checkbox with the boolean value passed.
func set_player_ready(player_id, is_ready):
	_table_player_leaves[player_id].set_checked(0, is_ready);

#Set the displayed name of the player.
func set_player_name(player_id, new_name):
	_table_player_leaves[player_id].set_text(1, new_name);

#Swap player from old team to new team; will update role if it has changed.
func change_player_team(player_id, old_team_id, new_team_id, new_role):
	#Get TreeItems for the two teams.
	var old_team_branch = _table_team_branches[old_team_id];
	var new_team_branch = _table_team_branches[new_team_id];
	var old_player_leaf = _table_player_leaves[player_id];

	#Create new player leaf on new team's branch.
	_create_player_leaf(new_team_branch, player_id, old_player_leaf.is_checked(0), old_player_leaf.get_text(1), new_role);

	#Remove player from old team branch.
	old_team_branch.remove_child(old_player_leaf);

#Set the displayed role of the player.
func set_player_role(player_id, new_role):
	_table_player_leaves[player_id].set_text(2, new_role);

#Removes all references to player with passed ID.
func remove_player(player_id):
	#We have to delete a TreeItem through the parent TreeItem.
	var team_branch = _table_player_leaves[player_id].get_parent()
	team_branch.remove_child(_table_player_leaves[player_id]);

	_table_player_leaves.erase(player_id);

### PRIVATE FUNCTIONS ###

#Creates a leaf formatted to contain the player's information on the passed branch.
func _create_player_leaf(parent_branch, player_id, is_ready, player_name, player_role):
	#Create TreeItem that displays the player's information.
	var player_leaf = create_item(parent_branch);
	player_leaf.set_cell_mode(0, TreeItem.CELL_MODE_CHECK);
	player_leaf.set_checked(0, is_ready);
	player_leaf.set_text(1, player_name);
	player_leaf.set_text(2, player_role);

	#Store reference to TreeItem in table for later look-up.
	_table_player_leaves[player_id] = player_leaf;

## INHERITED ##

func _ready():
	#Only take as much space as necessary for checkbox.
	set_column_expand(0, false);
	set_column_min_width(0, 32);