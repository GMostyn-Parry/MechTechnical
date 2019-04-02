"""
Author:	George Mostyn-Parry

Node that represents a hit-scan gun with affiliated variables such as damage, range, and timers for managing fire-rate.

Currently only a script.
TODO:
	- Turn into node, and have it loaded as a scene store a sprite and an initial firing position.
	- Have server master validate the shot for security.
	- Reset _time_since_started_firing when a shot fails i.e. angle was too great to fire.
"""
extends Node2D

#Tells any that catch the signal where a bullet was fired to, and where it came from.
signal bullet_fired(start_point, end_point)

#The maximum range a bullet fired will travel.
export(int) var range_ranged = 2000 + 64
#How long, in seconds, until the the walker can fire again.
export(float) var rate_of_fire = 0.025
#The amount of damage dealt by the gun.
export(int) var damage_shot = 1
#Max angle, in degrees, that the weapon's shots can spread from inaccuracy.
export(int) var max_angle_of_bullet_spread = 5

#How long since the weapon was fired.
var _time_since_last_shot = rate_of_fire
#How long the trigger has been held down on the weapon.
var _time_since_started_firing = 0.0

#Fires a bullet at target_position from start_position.
func fire_at(target_position, start_position):
	#Fire a hit-scan bullet, if the weapon has not been fired too recently.
	if _time_since_last_shot >= rate_of_fire:
		#The current world space state for raycasting the shot.
		var space_state = get_world_2d().direct_space_state

		#Direction the bullet will travel where the player pointed subtracted from where it will be fired from.
		var direction = (target_position - start_position).normalized()

		#Calculate angle bounds of shots taken if greater than max angle, then it is set to the max angle.
		var angle_of_fire = _time_since_started_firing
		if angle_of_fire > max_angle_of_bullet_spread:
			angle_of_fire = max_angle_of_bullet_spread

		#Bullet maximum end_point is calculated from starting position plus direction of travel times range then rotated randomly, depending on inaccuracy.
		var bullet_end_point = start_position + (direction * range_ranged).rotated(rand_range(deg2rad(-angle_of_fire), deg2rad(angle_of_fire)))

		#Raycast hitscan projectile to end-point hitting any object that is terrain, a player, or a collideable projectile.
		var raycast = space_state.intersect_ray(start_position, bullet_end_point, [], 1 + 2 + 4)

		#If there was a collision, then handle the collision.
		if raycast:
			#If the collided object has a shot method, then call it.
			if raycast.collider.has_method("shot"):
				#Network the shot across the network.
				if get_tree().has_network_peer():
					raycast.collider.rpc("shot", raycast.position, damage_shot)
				#Otherwise, call as a regular function.
				else:
					raycast.collider.shot(raycast.position, damage_shot)

			#If there was a collison, then the end-point for the purposes of the bullet trail is where the raycast collided.
			bullet_end_point = raycast.position

		#Network the shot across the network.
		if get_tree().has_network_peer():
			rpc("_synced_shot", start_position, bullet_end_point)
		#Otherwise, call as a regular function.
		else:
			_synced_shot(start_position, bullet_end_point)

### PRIVATE FUNCTIONS ###

#Tells program that a shot was fired, and where it started and terminated, synchronously across the network.
#Also resets time since last shot.
sync func _synced_shot(start_position, end_position):
	#Tell game that a bullet was fired from position, and ended at bullet_end_point.
	emit_signal("bullet_fired", start_position, end_position)
	#Bullet was just fired, so reset time since last shot taken.
	_time_since_last_shot = 0

## INHERTIED ##

func _ready():
	#Script needs identifier, because it is not a proper node "scene".
	name = "Gun"

func _physics_process(delta):
	_time_since_last_shot += delta

	#Increase inaccuracy as trigger is held down.
	if Input.is_action_pressed("walker_shoot"):
		_time_since_started_firing += delta
	#Reset inaccuracy if trigger is released.
	else:
		_time_since_started_firing = 0.0