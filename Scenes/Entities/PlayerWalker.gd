"""
Author:	George Mostyn-Parry

An extension of the Walker class to give control over the Walker via player input.

TODO:
	-	Don't rotate Walker on walk action if walk action has not been held for a brief moment.
			Stops awkward part-rotation on a double-click for a charge.
"""
extends "res://Scenes/Entities/Walker.gd"

## INHERITED ##

func _input(event):
	#End input processing if the player is stunned.
	if is_stunned():
		return

	#Activate the melee attack, if the user input the melee action.
	if event.is_action_released("walker_melee"):
		$AudioMelee.play()
		$RightPunch/TimerMelee.start()
		$RightPunch.monitoring = true
	#Cause the walker to charge if the user double clicks the move action.
	#Only registers double-click on press event.
	if event is InputEventMouseButton && event.is_action_pressed("walker_move") && event.doubleclick:
		set_charge_state(ChargeState.TURNING)
	#Causes the walker to charge if the user releases the charge action, and walker is not currently charging.
	if event.is_action_released("walker_charge") && _charge_state == ChargeState.NOT_CHARGING:
		set_charge_state(ChargeState.TURNING)

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

func _physics_process(delta):
	#Handle polling input if the Walker is not currently stunned.
	if !is_stunned():
		#Move the walker, if the user is pressing the move action and the distance to move is not too short.
		if Input.is_action_pressed("walker_move") && get_local_mouse_position().length() > minimum_move_distance:
			#Set rotation speed depending on whether the Walker is sprinting, or walking.
			var rotation_speed = rotation_speed_sprint if _charge_state == ChargeState.CHARGING else rotation_speed_walk

			#The angle the Walker needs to rotate to face the target.
			var angle_to_point = get_local_mouse_position().angle()
			#The velocity the Walker will rotate modified by the sign of the angle, so it will rotate along the shortest route.
			var rotation_velocity = delta * rotation_speed * sign(angle_to_point)

			#Stores if the walker reached its rotation goal.
			var is_finished_rotating = false

			#Don't rotate the walker if the user is pressing to lock rotation.
			if Input.is_action_pressed("walker_lock_rotation"):
				#Stop charging if the walker was trying to to turn to target to prevent it just sitting there.
				if _charge_state == ChargeState.TURNING:
					set_charge_state(ChargeState.NOT_CHARGING)
			#Otherwise, rotate the walker normally.
			else:
				#Perform a basic rotation if the angle to rotate to is further than the rotation velocity.
				if abs(angle_to_point) > abs(rotation_velocity):
					rotate(rotation_velocity)
				#Otherwise, set rotation to the rotation goal and flag we finished rotating.
				else:
					rotation = rotation + angle_to_point
					is_finished_rotating = true

			#Handle what should happen on each charge state for a movement action.
			match _charge_state:
				#Simply move the walker and "slide" it across edges at a walking speed.
				ChargeState.NOT_CHARGING:
					move_and_slide(Vector2(speed_walk, 0).rotated(rotation + angle_to_point))
				#Turn the walker to face the target before charging at it.
				ChargeState.TURNING:
					#Update to charging state if the walker finished rotating, otherwise continue turning.
					_charge_state = ChargeState.CHARGING if is_finished_rotating else ChargeState.TURNING
				#Charge at the target and handle any collision that may occur.
				ChargeState.CHARGING:
					#Move the walker and store collision data.
					var info_collision = move_and_collide(Vector2(speed_sprint, 0).rotated(rotation) * delta)

					#Stop charging, stun the walker, and shove the crash victim if a collision occured.
					if info_collision:
						#Walker must stop charging as it hit something.
						set_charge_state(ChargeState.NOT_CHARGING)
						maximise_stun_time(crash_stun_time)

						#Only shove the collider if it can be shoved.
						if info_collision.collider.has_method("shoved"):
							#Use a remote procedure call if we are connected over the network.
							if get_tree().has_network_peer():
								info_collision.collider.rpc("shoved", position, damage_charge)
							#Otherwise, just use a regular function call.
							else:
								info_collision.collider.shoved(position, damage_charge)
		#Walker is not charging if it is not moving.
		else:
			set_charge_state(ChargeState.NOT_CHARGING)

		#Fire the Walker's gun if the walker has a gun, and the angle is not greater than the maximum angle the walker can fire the weapon.
		if _chassis_gun && Input.is_action_pressed("walker_shoot") && abs(get_local_mouse_position().angle()) <= max_shoot_angle:
			_chassis_gun.fire_at(get_global_mouse_position(), position)