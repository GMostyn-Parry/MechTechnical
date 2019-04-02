"""
Author:	George Mostyn-Parry

Main menu for access to pre-game menus.
"""
extends Panel

func _ready():
	#Connect signals for functions to handle when the user successfully connects and when it fails to connect.
	get_tree().connect("connected_to_server", self, "_successfully_connected")
	get_tree().connect("connection_failed", self, "_failed_to_connect")

	#Connects signal for function to handle when the user loses connection to the server.
	NetworkController.connect("connection_ended", self, "_on_connection_ended")

	#Recreate the lobby, and show the lobby, after the players come back from a game.
	if get_tree().has_network_peer():
		$Lobby.load_information_after_game()

		#Comes after, otherwise the teams won't exist and the host will be added to to a null reference.
		$StartMenu.hide()
		$Lobby.show()

## SIGNALS MANUAL ##

#Shows the lobby when the user successfully connects to a server.
func _successfully_connected():
	$ConnectScreen.hide()
	$Lobby.show()

#Cleans up the connection, and shows the start menu, when the user fails to connect to the server.
func _failed_to_connect():
	NetworkController.end_connection()
	$ConnectScreen.hide()
	$StartMenu.show()

#Shows the start menu when the user loses connection to the server.
func _on_connection_ended():
	$Lobby.hide()
	$StartMenu.show()

## SIGNALS AUTOMATIC ##

#Brings up join server dialog when the user presses the join button.
func _on_StartMenu_join_game():
	$Dialogs/JoinServerDialog.popup_centered()

#Hosts a server on the local machine when the user presses the host button.
func _on_StartMenu_host_game():
	NetworkController.create_server(NetworkController.DEFAULT_PORT, NetworkController.DEFAULT_MAX_PLAYERS, "Host")

	#Only switch menus if the server was created.
	if get_tree().has_network_peer():
		$StartMenu.hide()
		$Lobby.show()
	#Otherwise, inform the user the program failed to create a server.
	else:
		$Dialogs/HostFailDialog.popup_centered()

#Shows the options menu when the options button is pressed.
func _on_StartMenu_open_options():
	$StartMenu.hide()
	$OptionsMenu.show()

#Shows start menu when the user presses the leave button in the options menu.
func _on_OptionsMenu_leave_options():
	$OptionsMenu.hide()
	$StartMenu.show()

#Attempts to join the server when the user confirms the join attempt with the input given.
func _on_JoinServerDialog_confirmed():
	#Retrieve input information input to the dialog box.
	var dialog_information = $Dialogs/JoinServerDialog.get_validated_information()

	#Attempt to join the server, if the information entered in the dialog was created.
	if dialog_information != null:
		NetworkController.join_server(dialog_information.ip, dialog_information.port, dialog_information.player_name)
		#The dialog doesn't hide until we tell it to, so we can tell the user to check their input.
		$Dialogs/JoinServerDialog.hide()

		#Only switch menus if the client was created.
		if get_tree().has_network_peer():
			$StartMenu.hide()
			$ConnectScreen.show()
		#Otherwise, inform the user the program failed to create a network peer.
		else:
			$Dialogs/HostFailDialog.popup_centered()

#Abort the attempt join by pressing the cancel button on the connecting screen .
func _on_ConnectScreen_cancel_connect():
	_failed_to_connect()