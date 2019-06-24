"""
A base class for a controllable entity; i.e. a person, or a walker.
"""
extends KinematicBody2D
class_name Actor

#Moves the actor towards the target, and whether they should turn to face the target.
func move_towards(var delta : float, var target : Vector2, var is_rotation_locked : bool):
	pass

#Tells the actor it has stopped moving.
func stop_moving():
	pass

#Tells the actor to charge.
func start_charging():
	pass

#Tells the actor to fire at a point.
func fire_at(var target : Vector2):
	pass

#Tells the actor it has stopped firing.
func stop_firing():
	pass

#Tells the actor to perform a melee strike.
func melee():
	pass