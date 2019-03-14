"""
Author:	George Mostyn-Parry

Menu that appears on program start, and allows the user to navigate to deeper menus.
"""
extends MarginContainer

#Signals to "bubble-up" the user's intention; i.e. which button they pressed.
signal join_game();
signal host_game();
signal open_options();

#Tell menu that the user wants to join a server.
func _on_Join_pressed():
	emit_signal("join_game");

#Tell menu that the user wants to host a server.
func _on_Host_pressed():
	emit_signal("host_game");

#Tell menu that the user wants to view the options menu.
func _on_Options_pressed():
	emit_signal("open_options");

#Quits the application when the user pressed the quit button.
func _on_Quit_pressed():
	get_tree().quit();