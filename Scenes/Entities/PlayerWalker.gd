"""
Author:	George Mostyn-Parry

An extension of the Walker class to give control over the Walker via player input.
"""
extends "res://Scenes/Entities/Walker.gd"

## INHERITED ##

func _ready():
	#Create visual representation of the max shooting angle for the player with an arc.
	#Stores untranslated point for each angle e.g. 10, 20, 30 degrees.
	var angle_points = PoolVector2Array()

	#Calculate untranslated points that will appear in arc.
	for angle_deg in range(rad2deg(max_shoot_angle), 0, -10):
		angle_points.append(Vector2(SHOOTING_ARC_SIZE, 0).rotated(deg2rad(angle_deg)))

	#The amount of points that will be represented in the arc.
	var point_amount = angle_points.size() * 2 + 1

	#An array of the points in the sector representing the shooting arc.
	var sector_points = PoolVector2Array()
	sector_points.resize(point_amount)

	#Insert untranslated points into sector by mirroing the untranslated points.
	#Point 0 should be {0, 0} so the arc goes to the centre of the Walker.
	for i in angle_points.size():
		sector_points.set(i + 1, Vector2(angle_points[i].x, -angle_points[i].y))
		sector_points.set(point_amount - i - 1, angle_points[i])

	#Insert centre/furthest/middle point at centre of array.
	sector_points.set(angle_points.size(), Vector2(SHOOTING_ARC_SIZE, 0))

	#Set polygon to use calculated arc to show player the shooting arc of their weapon.
	$ShootingArc.polygon = sector_points

#Handle one-off commands.
func _input(event):
	#Move action stopped.
	if event.is_action_released("walker_move"):
		Command.StopMoveCommand.new().execute(self)
	#Shoot action stopped.
	elif event.is_action_released("walker_shoot"):
		Command.StopFireCommand.new().execute(self)
	#Melee action triggered.
	elif event.is_action_released("walker_melee"):
		Command.MeleeCommand.new().execute(self)
	#Charge action triggered.
	elif (event is InputEventMouseButton && event.is_action_pressed("walker_move") && event.doubleclick) || \
			event.is_action_released("walker_charge"):
		Command.ChargeCommand.new().execute(self)

#Handle continuous commands.
func _physics_process(delta):
	#Move in direction of cursor; don't rotate if action is being pressed.
	if Input.is_action_pressed("walker_move"):
		Command.MoveCommand.new(delta, get_global_mouse_position(), Input.is_action_pressed("walker_lock_rotation")).execute(self)

	#Shoot in direction of cursor.
	if Input.is_action_pressed("walker_shoot"):
		Command.FireCommand.new(get_global_mouse_position()).execute(self)