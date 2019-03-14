"""
Author:	George Mostyn-Parry

Dialog for inputting information to create a team.
"""
extends ConfirmationDialog

#References to controls player enter input into.
onready var NameValue = $VBoxContainer/GridContainer/NameValue;
onready var ColourValue = $VBoxContainer/GridContainer/ColourValue;
onready var IsDriver = $VBoxContainer/IsDriver;

#Reference to label that displays warning about incorrect input.
onready var WarningText = $VBoxContainer/WarningText;

#Return the information input to the dialog box.
func get_validated_information():
	#Strip non-printable characters from edges of name.
	NameValue.text = NameValue.text.strip_edges(true, true);

	#Tell the user to enter a team name, if they did not, and return null.
	if NameValue.text.empty():
		#Display warning, and bring it to size.
		WarningText.bbcode_text = "[center]- Please enter a team name.[/center]";
		WarningText.set_target_size(Vector2(WarningText.rect_size.x, 15));
		#Grab focus for user to enter the team's name.
		NameValue.grab_focus();
		return null;
	#Otherwise, return the information the player entered.
	else:
		return \
				{
					name = NameValue.text,
					colour = ColourValue.color,
					is_driver = IsDriver.pressed
				};

### PRIVATE FUNCTIONS ###

#Sets the dialog to its original configuration, before showing it to the user.
func _on_TeamCreationDialog_about_to_show():
	NameValue.text = "";
	ColourValue.color = Color(1, 1, 1);
	IsDriver.pressed = true;
	#Prevent warning text from altering appearance when it has no text.
	WarningText.set_size(Vector2(WarningText.rect_size.x, 0));

	#Reset height from expansion from warning text.
	rect_size.y = 0;