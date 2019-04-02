"""
Author:	George Mostyn-Parry

Node to display the bullets fired, i.e. their bullet trails.
The bullets are drawn from the start-point to their end-point, and slowly vanish starting from their start-point.
"""
extends Node2D

#The speed the bullet trail disappears.
export(float) var trail_speed = 50

#List of all the information on the shots currently being drawn.
var _info_trails = Array()

#Adds a bullet trail initially drawn from the start-point to the end-point.
func add_bullet_trail(start_point, end_point):
	#The direction the trail is travelling.
	var direction = (end_point - start_point).normalized()
	#The start-point needs to be adjusted, so the bullet trail actually visibly starts from the start-point.
	var start_compensation = direction * trail_speed

	#Add trail with start compenstation to the list.
	_info_trails.append(
			{
				start = start_point - start_compensation,
				end = end_point,
				dir = direction,
				#Whether the trail has finished being displayed.
				is_finished = false
			})

func _process(delta):
	#Move all of the trails flag all of the trails that have finished.
	for trail in _info_trails:
		var difference = trail.end - trail.start
		var velocity = trail.dir * trail_speed

		#Move the start by the trail's velocity, if the velocity's length is less than the length of the difference.
		if velocity.length() < difference.length():
			trail.start = trail.start + velocity
		#Otherwise, move the start to just before the end, and flag the trail as finished.
		else:
			trail.start = trail.end - trail.dir
			trail.is_finished = true

	#Flag the node to redraw itself i.e. update trails.
	update()

func _draw():
	#Stores trails that are to be removed.
	var finished = Array()

	#Using numerical iterator for use of remove.
	#I believe this to be more efficient as it does not have to search for the element to remove untested.
	for i in _info_trails.size():
		#Draw line from start of trail to the trail end.
		draw_line(_info_trails[i].start, _info_trails[i].end, Color(1, 0, 0))

		#Add trail index to finished array, if it was set as finished.
		if _info_trails[i].is_finished:
			finished.append(i)

	#Remove completed trails.
	for i in finished.size():
		#Subtract i as the array gets shifted as elements are removed.
		_info_trails.remove(finished[i] - i)