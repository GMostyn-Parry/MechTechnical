Author: George Mostyn-Parry
Compiled using Godot 3.0 in GDScript.
Started in December 2018, and worked on most recently in January 2019.

The project files include a Windows executable in the "Export" folder.

A small game with most of the work done on ensuring robustness of the lobby, and networking, system.
User can start a game by joining a lobby and then all players reading up; this can be done singleplayer by pressing the Host button, and then the Ready button.
User can move and fire the gun of a Walker; represented by a circle.
User can paint the ground with simple canvas editing tools enabled with the F4 key.

#Menu
The user can host a lobby by pressing the Host button; or join a lobby by pressing the Join button, and then entering their name and the details of the server.
The options menu may be opened by pressing the Options button, but there are currently no configurable options.
The user must enter a name when joining a server, and a valid IP address.

#Lobby
The user may host a server with at most eight players.
The user can create a team with the Create Team button located at the top; but this currently serves no functionality in the game.
Teams have a name, and a colour, which can be configured; a name must be entered. When the team is created the user may choose if they wish to be driver.
A team can be joined by pressing either of the role button on the team slot in the centre-left of the screen.
The window in the team slot currently serves no purpose, but would display a preview of the walker.
The team list on the right displays all teams, and players in those teams.
When all players in the lobby press the Ready button, and are marked in the ready state, the game will begin after five seconds; this can be cancelled.
Currently being in a team has no effect on the actual game part, but the information will be loaded back into the lobby when the game ends.

#Game
The user may move their mech around the screen, and fire its gun aslong as the point is at not too great an angle; more than 60 degrees from the front.
The user may paint the ground by entering canvas-editing mode; here a slider element will appear with the strength of the brush and the user may draw directly onto the ground in real-time. The "paint" used may be changed with the middle-mouse. Refer to the #Controls heading.
The game ends when one or less Walker remains.

#Networking
The user can host or join a server hosted on port 27005; or simply join on their own local machine by leaving the IP box empty on join, or entering "localhost".
There is currently no way for the host to change their display name, or the port they host on, without changing the source code.
The user can join on a lobby in-progress; i.e. teams have been created, and players joined.
The user can not join on a game in-progress.

#Network Security#
The user will be kicked if they somehow call a function to change team details of a team they are not a member of.

#Controls
For the pre-game stage the only controls are with the mouse; using it to click on UI elements to navigate the menus, and create and join teams.

In-game (Walker):
Right-Click			|	Hold	|	Move to mouse position.
Left-Click			|	Hold	|	Shoot at mouse position (provided it is within the shooting arc).
Middle-Click		|	Press	|	Melee; works on any other walker's directly in-front of the walker.
Space(Hold)			|	Hold	|	Prevents the walker from rotating while moving.
Mouse-Wheel-Up		|	Press	|	Charges at the selected point; not possible while rotation is locked.
Shift				|	Press	|	Charges at the selected point; not possible while rotation is locked.
Right-Click(Double)	|	Press	|	Charges at the selected point; not possible while rotation is locked.

In-game (Canvas):
F4(Function Key 4)	|	Press	|	Toggles editing of the canvas blendmap.
Right-Click			|	Hold	|	Paint on surface.
Middle-Click		|	Press	|	Change paint.

#Options
There are currently no configurable options, even if there is an options menu.
You may quit back to the main menu with the Leave button.

#Quitting
The user may quit at any time by using the close button on the window, or the Quit button on the main menu.
The user can only quit a game with the window's close button.

#Unimplemented
The idea is to have one player drive the walker, and then a variable amount of player controls guns attached to the walker.
The game would also need terrain to block shots, impair movement, and possibly block sight.

The main trouble with the asymmetrical co-operation is giving the players in control of the guns enough to do; or, likely if you take away the Walker's gun, preventing the Walker from running directly at enemies to melee them.