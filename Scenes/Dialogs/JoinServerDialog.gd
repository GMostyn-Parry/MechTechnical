"""
Author: George Mostyn-Parry

A dialog to allow the user to input information on the server they want to join.
Also allows them to enter their display name.
"""
extends ConfirmationDialog

#References to the nodes that are used for receiving input.
onready var PlayerNameValue = $Ordering/Controls/PlayerNameValue
onready var IPValue = $Ordering/Controls/IPValue
onready var PortValue = $Ordering/Controls/PortValue

#Reference to the warning text that shows when the user gives invalid input.
onready var WarningText = $Ordering/WarningText

#Return the information input to the dialog box, if it was valid otherwise return null.
func get_validated_information():
	#Strip non-printable characters from ends of player name and IP.
	var player_name = PlayerNameValue.text.strip_edges(true, true)
	var ip = IPValue.text.strip_edges(true, true)
	#Tracks whether any checks failed.
	var failed_a_check = false

	#Clear text as no errors are known.
	WarningText.bbcode_text = ""

	#Set IP as local IP if box was empty, or the user entered "localhost".
	if ip.empty() || ip == "localhost":
		ip = IP.get_local_addresses()[0]

	#Tell user to enter valid IP, if they have not.
	if !ip.is_valid_ip_address():
		WarningText.bbcode_text += "[center]- Please enter a valid IP address.[/center]"

		failed_a_check = true
		#Grab focus, so the user can enter a valid IP.
		IPValue.grab_focus()

	#Tell user to enter valid player name, if they did not.
	if player_name.empty():
		WarningText.bbcode_text += "[center]- Please enter a display name.[/center]"

		failed_a_check = true
		#Grab focus, so the user can enter a valid name which takes precedence over the IP.
		PlayerNameValue.grab_focus()

	#Return null if the user failed a check.
	if failed_a_check:
		WarningText.set_target_size(Vector2(WarningText.rect_size.x, 30))
		return null
	#Otherwise return the input information.
	else:
		return \
				{
					player_name = player_name,
					ip = ip,
					port = PortValue.value
				}

### PRIVATE FUNCTIONS ###

#Sets the dialog to its original configuration, before showing it to the user.
func _on_JoinServerDialog_about_to_show():
	PlayerNameValue.text = ""
	IPValue.text = ""
	PortValue.value = NetworkController.DEFAULT_PORT
	#Hide warning text on show.
	WarningText.set_size(Vector2(WarningText.rect_size.x, 0))

	#Reset height from expansion from warning text.
	rect_size.y = 0

#Set text to red, if the user did not enter a valid IP address.
func _on_IPValue_text_changed(new_text):
	#If the IP address is valid, or localhost, then remove the font colour override.
	if new_text.is_valid_ip_address() || new_text == "localhost":
		IPValue.set("custom_colors/font_color", null)
	#Otherwise, set the colour of the font to red.
	else:
		IPValue.add_color_override("font_color", Color(1,0,0))