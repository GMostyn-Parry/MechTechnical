"""
Author:	George Mostyn-Parry

Control for joining and editing teams, also allows changing role in the team.
"""
extends PanelContainer

#The team's name was changed.
signal changed_team_name(new_name);
#The team's colour was changed.
signal changed_team_colour(new_colour);

#The player wants to change their role.
signal player_applied_for_role(new_role);
#The team has lost its final player.
signal team_emptied();

#Stores the information to check for changes.
var _stored_name = "";
var _stored_colour = Color(1, 1, 1);

#Passes the initial information of the team this TeamSlot represents.
func setup_team(team_id, team_name, team_colour):
	$Ordering/Identifiers/Name.text = team_name;
	$Ordering/Identifiers/Colour.color = team_colour;

	name = "TeamSlot" + String(team_id);
	_stored_name = team_name;
	_stored_colour = team_colour;

#Change the team's displayed name to the passed name.
func set_team_name(new_name):
	$Ordering/Identifiers/Name.text = new_name;
	_stored_name = new_name;

#Change the team's displayed colour to the passed colour.
func set_team_colour(new_colour):
	$Ordering/Identifiers/Colour.color = new_colour;
	_stored_colour = new_colour;

#Sets whether the local user can edit this team slot.
func set_editable(is_editable):
	$Ordering/Identifiers/Name.editable = is_editable;
	$Ordering/Identifiers/Colour.disabled = !is_editable;

### PRIVATE FUNCTIONS ###

func _ready():
	var colour_picker = $Ordering/Identifiers/Colour.get_picker();
	colour_picker.connect("hide", self, "_on_ColourPicker_hide");

## SIGNALS MANUAL ##

#Update colour changes when the ColourPicker is hidden (closed).
func _on_ColourPicker_hide():
	var colour = $Ordering/Identifiers/Colour.get_picker().color;

	#Only emit the signal if there was actually a change.
	if colour != _stored_colour:
		emit_signal("changed_team_colour", colour);

## SIGNALS AUTOMATIC ##

#Updates the <user/local player>'s information to reflect them joining the team, on pressing a button to join the team.
func _on_player_join_team(is_driver):
	var role = "Driver" if is_driver else "Gunner";
	emit_signal("player_applied_for_role", role);

#Release focus on text entered to cause focus to be lost, causing the team name change to be verified in focus_exited.
func _on_Name_text_entered(new_text):
	$Ordering/Identifiers/Name.release_focus();

#Update the team name, whenever the node loses focus.
func _on_Name_focus_exited():
	#Strip blank characters from the input name.
	var text_value = $Ordering/Identifiers/Name.text.strip_edges(true, true);

	#Set the name back to the name before editing, if the input was blank.
	if text_value.empty():
		$Ordering/Identifiers/Name.text = _stored_name;
	#Emit the team name has changed, only if there was actually a change.
	elif text_value != _stored_name:
		#Signal that the team's name was changed.
		emit_signal("changed_team_name", text_value);