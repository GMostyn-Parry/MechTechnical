"""
Author:	George Mostyn-Parry

A script that can be added to a control to cause it to gradually grow to a size.
This script can not override any blockers that may prevent resize; e.g. a child node with a minimum size.
"""
extends Control

#How many pixels per second the control resizes.
export(float, 0) var resize_rate = 300.0;

#The size the control will try to reach.
var _target_size;
#The size of the control in real numbers; rect_size is in integers and will truncate change otherwise.
var _float_size;

#Gradually sets the size to the passed size.
func set_target_size(new_size):
	_target_size = new_size;

#Instantly sets the size to the passed size.
func set_size(new_size):
	#We change min size to force it to expand in controls that shrink their children.
	rect_min_size = new_size;
	rect_size = new_size;

### PRIVATE FUNCTIONS ###

func _ready():
	#Store starting size.
	_float_size = rect_size;

func _process(delta):
	#Gradually change size, if there is a size we are trying to reach.
	if _target_size:
		#The difference between our target size, and the current size.
		#We use float size, so the resizing will eventually end.
		#It may not for rect_size because there may be blockers preventing the resize.
		var difference = _target_size - _float_size;
		#How fast we will change the size of the control.
		var add_size = difference.normalized() * delta * resize_rate;

		#Add on change in size, if we will not overshoot the difference.
		if difference.length() > add_size.length():
			_float_size += add_size;
		#Otherwise, set it to the target size.
		else:
			_float_size = _target_size;
			_target_size = null;

		#Set size to the real number size.
		set_size(_float_size);
