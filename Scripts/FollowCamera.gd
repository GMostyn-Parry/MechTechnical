"""
A simple camera script that tracks the node set as the target.
"""
extends Camera2D

var target : Node2D; #What the camera is tracking.

func _process(delta):
	#Track the target, if we have a target.
	if(target):
		position = target.position;