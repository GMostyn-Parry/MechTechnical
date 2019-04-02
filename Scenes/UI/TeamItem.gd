"""
A individual element in the Teamlist to display a single team, and its players.

TODO:
	- Make ROLE column more general, such as OTHER instead.
"""
extends PanelContainer

#An enumeration to identify what each column contains.
enum {CHECKBOX, IDENTIFIER, ROLE}

#Sets displayed team name to passed name.
func set_team_name(new_name):
	$Ordering/TeamName.text = new_name

#Changes the background colour to the passed colour.
func set_team_colour(new_colour):
	self_modulate = new_colour

	#Sets text colour to white if the colour is too light.
	if new_colour.v < 0.6:
		$Ordering/TeamName.add_color_override("font_color", Color(1, 1, 1))
	#Otherwise, the text colour is black.
	else:
		$Ordering/TeamName.add_color_override("font_color", Color(0, 0, 0))

#Add a player to display in the team's player list.
func add_player(player_id, player_info, is_ready):
	#Create TreeItem that displays the player's information.
	var player_leaf = $Ordering/TeamPlayers.create_item($Ordering/TeamPlayers.get_root())

	#Create a checkbox, and mark it correctly.
	player_leaf.set_cell_mode(CHECKBOX, TreeItem.CELL_MODE_CHECK)
	player_leaf.set_checked(CHECKBOX, is_ready)

	#Display player name, and store the player's ID in the cell.
	player_leaf.set_text(IDENTIFIER, player_info.name)
	player_leaf.set_metadata(IDENTIFIER, player_id)

	#Display player role.
	player_leaf.set_text(ROLE, player_info.role)

#Sets whether the player is displayed as ready.
func set_player_ready(player_id, is_ready):
	_find_player(player_id).set_checked(CHECKBOX, is_ready)

#Sets the players name to the passed value.
func set_player_name(player_id, new_name):
	_find_player(player_id).set_text(IDENTIFIER, new_name)

#Sets the players role to the passed value.
func set_player_role(player_id, new_role):
	_find_player(player_id).set_text(ROLE, new_role)

#Removes the player from the team's player list.
func remove_player(player_id):
	#You must go through the parent node to remove an item from the tree.
	var player_tree_item = _find_player(player_id)
	player_tree_item.get_parent().remove_child(player_tree_item)

	#Update deletion of player.
	$Ordering/TeamPlayers.update()

### PRIVATE FUNCTIONS ###

#Returns the TreeItem that stores the information on the player.
#Returns null if the player could not be found.
func _find_player(player_id):
	var _has_found_player = false
	#Returns first TreeItem, and then we must iterate through them.
	var current_child = $Ordering/TeamPlayers.get_root().get_children()

	#Iterate through all children to found where player's information is stored breaking when the player's TreeItem is found.
	while !_has_found_player && current_child != null:
		if player_id == current_child.get_metadata(IDENTIFIER):
			_has_found_player = true
		else:
			current_child = current_child.get_next()

	#Return reference to TreeItem.
	return current_child

## INHERITED ##

func _ready():
	#Create tree root.
	$Ordering/TeamPlayers.create_item()

	#Only take as much space as necessary for checkbox.
	$Ordering/TeamPlayers.set_column_expand(CHECKBOX, false)
	$Ordering/TeamPlayers.set_column_min_width(CHECKBOX, 20)