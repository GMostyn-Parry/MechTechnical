"""
Author:	George Mostyn-Parry

Screen that tells the user their connection attempt has been accepted, and the application is attempting to join.
Gives the user the ability to cancel their connection attempt.
"""
extends MarginContainer

#Tells listening that the user wants to cancel their attempt to join the server.
signal cancel_connect()

#Emits signal to cancel the connection attempt when the user presses the cancel button.
func _on_Cancel_pressed():
	emit_signal("cancel_connect")