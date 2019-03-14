"""
Author: George Mostyn-Parry

Debug script for a Line2D that draws the path of the object that had it's NodePath passed to the script.
For example, viewing the turning circle of a vehicle defined as a physics object.
"""
extends Line2D

#The path to the node that the line draws the path of.
export(NodePath) var follow;

func _input(event):
	#Clear all points of the line, so the trail can be restarted.
	if event is InputEventKey && event.scancode == KEY_R:
		points = PoolVector2Array();

func _process(delta):
	#Get the position of the node we are following.
	var follow_position = get_node(follow).position

	#Add the Node's current position to the Line2D; if the Line2D has no points,
	#or if the length of the difference between the last point and the current position is more than or equal to one pixel.
	if points.size() == 0 || (points[points.size() - 1] - follow_position).length() >= 1:
		add_point(follow_position);