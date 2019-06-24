"""
Class of commands the user, or an AI, can trigger on an Actor.
"""
extends Node
class_name Command

#Base class of the command pattern; tracks when the command was created.
class _BaseCommand:
	var tick_created : float = OS.get_ticks_msec()

	func execute(actor : Actor):
		pass

#Commands an actor towards a target.
class MoveCommand:
	extends _BaseCommand

	var _delta : float #The delta of on the creation of the command.
	var _target : Vector2 #The target destination.
	var _is_rotation_locked : bool #Whether the actor should turn towards the target.

	func _init(delta : float, target : Vector2, is_rotation_locked : bool):
		_target = target
		_delta = delta
		_is_rotation_locked = is_rotation_locked

	func execute(actor : Actor):
		actor.move_towards(_delta, _target, _is_rotation_locked)

#Informs an actor it has stopped moving.
class StopMoveCommand:
	extends _BaseCommand

	func execute(actor : Actor):
		actor.stop_moving()

#Commands an actor to charge.
class ChargeCommand:
	extends _BaseCommand

	func execute(actor : Actor):
		actor.start_charging()

#Commands an actor to fire at a target.
class FireCommand:
	extends _BaseCommand

	var _target : Vector2 #Where to fire at.

	func _init(target : Vector2):
		_target = target

	func execute(actor : Actor):
		actor.fire_at(_target)

#Informs an actor it has stopped firing.
class StopFireCommand:
	extends _BaseCommand

	func execute(actor : Actor):
		actor.stop_firing()

#Commands an actor to perform a melee strike.
class MeleeCommand:
	extends _BaseCommand

	func execute(actor : Actor):
		actor.melee()