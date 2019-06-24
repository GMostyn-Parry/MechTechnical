"""
Author:	George Mostyn-Parry

Class for a Walker(mechanical vehicle that moves on legs) it can fire a weapon, charge, and melee attack.
"""
extends Actor

#Walker was stunned for passed amount of time.
signal stun_started(time_on_stun)
#Walker is no longer stunned.
signal stun_ended
#Walker has died.
signal died

#Enumeration of the charging states the walker can be in.
enum ChargeState{
	NOT_CHARGING,
	TURNING,
	CHARGING
}

#The length in pixels from the centre of the walker to the furthest point in the visual shooting arc.
const SHOOTING_ARC_SIZE = 400
#The factor to increase how much force is applied by a shove.
const SHOVE_FORCE_FACTOR = 40
#The factor at which the Walker decelerates from a shove.
const DECELERATE_SHOVE_FACTOR = 10
#The minimum angle that the Walker can shoot.
#Constants can't be used in export range declarations, update max_shoot_angle range aswell.
const MIN_SHOOT_ANGLE = 5.0
#Time that must pass before the walker starts rotating.
const TIME_BEFORE_ROTATE : float = 0.2

#The maximum angle the Walker can fire its gun.
#When set it will convert degrees to radians, and return radians when accessed.
#Passing degrees from the editor is more intuitive for a human.
export(float, 5, 180) var max_shoot_angle = 60.0 setget set_max_shoot_angle
#The current health of the Walker.
export(int) var health = 100

#How fast the Walker will move when walking.
export(int) var speed_walk = 128
#How fast the Walker will move when sprinting.
export(int) var speed_sprint = 512
#How fast the Walker will rotate when walking.
export(int) var rotation_speed_walk = 10
#How fast the Walker will rotate when sprinting.
export(int) var rotation_speed_sprint = 0.5

#The amount of damage dealt by the Walker by its melee attack.
export(int) var damage_melee = 10
#The amount of damage dealt by the Walker by its charge.
export(int) var damage_charge = 5

#How long the Walker is stunned after being shoved.
export(float) var shove_stun_time = 2.0
#How long the Walker is stunned after crashing into something.
export(float) var crash_stun_time = 1.0

#The minimum distance, in pixels, of a move command for the Walker to move.
export(float) var minimum_move_distance = 8

#What charging state the walker is in.
var _charge_state = ChargeState.NOT_CHARGING setget set_charge_state
#How long the Walker has left until it is no longer stunned.
var _time_until_unstunned = 0.0

#The velocity applied to the walker from being shoved aside by a physical attack.
var _velocity_shove = Vector2()

#Amount of time since the object was last synced with the server.
var _time_since_last_sync : float = NetworkController.TICK_RATE_INTERVAL
#Amount of time since walker started moving, by its own accord.
var _time_since_started_moving : float = 0

#The Weapon class "mounted" on this Walker.
var _chassis_gun

#Causes the walker to move towards the target.
#Returns where the movement occurred.
func move_towards(var delta : float, var target : Vector2, var is_rotation_locked : bool):
	#Don't move if we are stunned, or too close to the destination.
	if is_stunned() || (target - position).length() < minimum_move_distance:
		return false

	_time_since_started_moving += delta

	#Set rotation speed depending on whether the Walker is sprinting, or walking.
	var rotation_speed = rotation_speed_sprint if _charge_state == ChargeState.CHARGING else rotation_speed_walk

	#The angle the Walker needs to rotate to face the target.
	var angle_to_point = get_local_mouse_position().angle()
	#The velocity the Walker will rotate modified by the sign of the angle, so it will rotate along the shortest route.
	var rotation_velocity = delta * rotation_speed * sign(angle_to_point)

	#Stores if the walker reached its rotation goal.
	var is_finished_rotating = false

	#Don't rotate the walker if the user is pressing to lock rotation.
	if is_rotation_locked:
		#Stop charging if the walker was trying to to turn to target to prevent it just sitting there.
		if _charge_state == ChargeState.TURNING:
			set_charge_state(ChargeState.NOT_CHARGING)
	#Otherwise, rotate the walker normally; if we have not just started moving, or we are in the turning state.
	elif _time_since_started_moving >= TIME_BEFORE_ROTATE || _charge_state == ChargeState.TURNING:
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
			set_charge_state(ChargeState.CHARGING if is_finished_rotating else ChargeState.TURNING)
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

	return true

#Tell the walker it has stopped moving.
func stop_moving():
	set_charge_state(ChargeState.NOT_CHARGING)
	_time_since_started_moving = 0

#Tell the walker to start charging.
#Returns whether the call caused the walker to start charging.
func start_charging():
	if _charge_state != ChargeState.NOT_CHARGING:
		return false

	set_charge_state(ChargeState.TURNING)
	return true

#Tell the walker to fire at the target.
#Returns whether a shot was made.
func fire_at(var target : Vector2):
	if is_stunned() || abs(get_local_mouse_position().angle()) > max_shoot_angle:
		stop_firing()

		return false

	#Return whether the shot was fired.
	return _chassis_gun.fire_at(target)

#Tells the walker it has stopped firing.
func stop_firing():
	_chassis_gun.stop_firing()

#Causes the walker to shove objects in-front of it.
#Returns whether the strike occurred.
func melee():
	if is_stunned():
		return false

	$AudioMelee.play()
	$RightPunch/TimerMelee.start()
	$RightPunch.monitoring = true

	return true

#Sets stun time to the largest value between the current time until unstunned and the passed value.
#Also signals the walker was stunned if the value changed.
func maximise_stun_time(time_to_stun):
	if time_to_stun > _time_until_unstunned:
		_time_until_unstunned = time_to_stun
		emit_signal("stun_started", _time_until_unstunned)

#Returns the amount of stun time remaining will return zero if the time is negative.
func get_stun_remaining():
	return _time_until_unstunned if _time_until_unstunned > 0 else 0

#Returns whether the walker is stunned.
func is_stunned():
	return _time_until_unstunned > 0

#Set the max shooting angle of the weapon takes degrees, and sets it to radians.
func set_max_shoot_angle(angle_in_degrees):
	#Bug causes setget to be called twice on exported variables when they are inherited into another class.
	#Radians have small values so you can catch this by creating a minimum angle for the max angle.
	if angle_in_degrees >= MIN_SHOOT_ANGLE:
		max_shoot_angle = deg2rad(angle_in_degrees)
	else:
		#Passed value is converted value due to inheritance bug.
		max_shoot_angle = angle_in_degrees

#Handles changing of the charge state of the Walker.
func set_charge_state(new_charge_state):
	_charge_state = new_charge_state

	#Applies special conditions for when the Walker changes charging state.
	match(new_charge_state):
		ChargeState.CHARGING:
			#The Walker can not charge forever, so start timer to stop Walker charging.
			$TimerCharge.start()
		ChargeState.NOT_CHARGING:
			$TimerCharge.stop()

## NETWORKED ##

#Tells the Walker it was shot by a projectile.
#damage_position is the location of the damage source, and damage_amount is how much raw damage was dealt.
sync func shot(damage_position, damage_amount):
	_take_damage(damage_amount)

#Tells the Walker it was shoved by a physical force.
#damage_position is the location of the damage source, and damage_amount is how much raw damage was dealt.
sync func shoved(damage_position, damage_amount):
	#Add velocity to Walker as it was shoved.
	_velocity_shove += (position - damage_position) * SHOVE_FORCE_FACTOR
	#Stun the walker for as long as the shove entails.
	maximise_stun_time(shove_stun_time)

	_take_damage(damage_amount)

### PRIVATE FUNCTIONS ###

#Causes the Walker to take the damage amount passed, and "kills" the Walker when its health reaches zero.
func _take_damage(amount):
	health -= amount
	#Update the health bar with the change in health.
	$HealthBar.value = health

	#While the walker is still alive, change the colour to a more red tint the more damage it takes.
	if health > 0:
		#Reddening of the sprite as basic feedback for damage.
		$Sprite.modulate = Color(1.0 + (1.0 - health / 100.0) / 2.0, 1.0, 1.0)
	#Only signal death if this was the attack that killed the walker.
	elif health + amount > 0:
		#Walker has died tell all that are listening.
		emit_signal("died")

#Fix position and rotation of health bar, so it is viewable by the user.
func _adjust_health_bar_transform():
	$HealthBar.rect_global_position = position + Vector2(-65, -85)
	$HealthBar.set_rotation(-rotation)

## NETWORKED ##

#Override the transform of the Walker with the transform from the master of the walker.
puppet func _receive_transform(new_transform):
	transform = new_transform
	_adjust_health_bar_transform()

## INHERITED ##

func _ready():
	#Add default gun to the Walker.
	_chassis_gun = load("res://Scenes/Entities/Gun.gd").new()
	add_child(_chassis_gun)

func _physics_process(delta):
	_time_since_last_sync += delta

	#Move walker from a shove action against it, and remove some of the shove force.
	move_and_slide(_velocity_shove)
	_velocity_shove -= _velocity_shove * delta * DECELERATE_SHOVE_FACTOR

	#Walker has possibly moved. Adjust the health bar's position.
	_adjust_health_bar_transform()

	#Update stun timer, if the walker is stunned.
	if is_stunned():
		_time_until_unstunned -= delta
		#Signal the walker is no longer stunned if the last of its time was paid off.
		if !is_stunned():
			emit_signal("stun_ended")

	#Send the walker's transform over the network, if the user is the controller, the walker is still alive, and we have not updated too recently.
	if get_tree().has_network_peer() && is_network_master() && health > 0 && _time_since_last_sync >= NetworkController.TICK_RATE_INTERVAL:
		rpc("_receive_transform", transform)
		_time_since_last_sync = 0

#Stop the walker's charge, when time runs out.
func _on_TimerCharge_timeout():
	print("Well?")
	set_charge_state(ChargeState.NOT_CHARGING)

#If a body, likely another player, enters the area of the right punch when activated.
func _on_RightPunch_body_entered(body):
	#Shove the body that entered the area, if the body has a "shove" method and the body was not the Walker that punched.
	if body.has_method("shoved") && body != self:
		#Use a remote procedure call if we are connected over the network.
		if get_tree().has_network_peer():
			body.rpc("shoved", $RightPunch.global_position, damage_melee)
		#Otherwise, just use a regular function call.
		else:
			body.shoved($RightPunch.global_position, damage_melee)

#If the punch is over, then stop monitoring for impacts.
func _on_TimerMelee_timeout():
	$RightPunch.monitoring = false