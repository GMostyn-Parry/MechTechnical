"""
Author:	George Mostyn-Parry

A menu where the user may change their keybindings, and video and audio settings.

TODO:
	- Add video settings.
	- Add audio settings.
	- Add keybindings options.
"""
extends MarginContainer

#Tells listening that the user wants to quit the options menu.
signal leave_options()

#Emits signal to leave the options menu when the leave button is pressed.
func _on_Leave_pressed():
	emit_signal("leave_options")

#Resets the current tab when the user hides the options menu.
func _on_OptionsMenu_hide():
	$Ordering/OptionSelect.current_tab = 0