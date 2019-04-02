"""
Author:	George Mostyn-Parry

Allows painting of a RGBA blendmap to display different textures on the surface.
Assumes blendmap is not changed during runtime especially not for a blendmap of a different size.
"""
extends Sprite

#The texture of the brush that is used to paint on the canvas
#Provides an easier interface for uploading brushes through the editor.
export(Texture) var brush
#The strength of the brush painting on the blendmap multiplied by the strengths defined by the brush.
export(float, 0, 1.0, 0.01) var brush_strength = 1.0

#The ratio difference to convert the ground sprite's size to the blendmap texture's size.
var global_to_canvas_ratio

#The colour that will be painted on to the blend texture.
var _paint_colour = Color(1, 0, 0, 0)
#The points that will be painted on with the brush when the idle process is called.
#Runs smoother than when painting immediately from the _input() function.
var _paint_points = Array()

#The image data of the canvas that is being painted to.
var _image_canvas
#The image data of the brush used to paint on the canvas.
#Always locked for write access, as such do NOT perform actions that are not reading the data.
var _image_brush

#Add a point to be painted on the canvas.
func add_point(global_point):
	#Transform global_point to the canvas' dimensions.
	var canvas_point = global_point / global_to_canvas_ratio

	#Insert canvas_point as floored Vector2 remaining fraction can cause issues, such as on bottom-right of frame.
	_paint_points.append(canvas_point.floor())

#Disables input to the canvas, and hides UI tools for altering canvas.
func toggle_editing():
	set_process_input(!is_processing_input())
	$PaintingTools/StrengthControl.visible = !$PaintingTools/StrengthControl.visible

### PRIVATE FUNCTIONS ###

func _ready():
	#Store image data of canvas, and brush.
	_image_canvas = texture.get_data()
	_image_brush = brush.get_data()
	#We only need the brush to check the strength values, as such we leave it locked in write access.
	_image_brush.lock()

	#Set the texture to an ImageTexture, so we can easily set the data.
	texture = ImageTexture.new()
	#Draw canvas on new texture.
	texture.create_from_image(_image_canvas)

	#Set ratio to size of sprite divided by the size of the blendmap texture.
	global_to_canvas_ratio = region_rect.size / _image_canvas.get_size()

	#Don't process input by default.
	toggle_editing()

func _input(event):
	if event is InputEventMouseButton:
		#Cycle through blend colours, if switch colour action was released.
		if event.is_action("canvas_switch_colour") && !event.pressed:
			match (_paint_colour):
				Color(0, 0, 0, 0):
					_paint_colour = Color(1, 0, 0, 0)
				Color(1, 0, 0, 0):
					_paint_colour = Color(0, 1, 0, 0)
				Color(0, 1, 0, 0):
					_paint_colour = Color(0, 0, 1, 0)
				Color(0, 0, 1, 0):
					_paint_colour = Color(0, 0, 0, 1)
				Color(0, 0, 0, 1):
					_paint_colour = Color(0, 0, 0, 0)
		#Add point to paint on canvas, if paint action was pressed.
		elif event.is_action("canvas_paint") && event.pressed:
			add_point(get_global_mouse_position())

	#Add point to paint on canvas, when the user drags their mouse with the paint action pressed.
	if event is InputEventMouseMotion && Input.is_action_pressed("canvas_paint"):
		add_point(get_global_mouse_position())

func _process(delta):
	#Update canvas if there are points to "paint" on.
	if _paint_points.size() != 0:
		#Lock canvas for write access, so pixels may be changed.
		_image_canvas.lock()

		#Draw all of the paint points onto the canvas.
		for point in _paint_points:
			#The top-left position of the brush if centred on the painting point.
			var brush_top_left = point - _image_brush.get_size() / 2.0

			#Perform operations to prevent drawing attempts that leave the bounds of the canvas.
			var x_start = max(0, -brush_top_left.x)
			var y_start = max(0, -brush_top_left.y)
			var x_end = min(_image_brush.get_width(), -(brush_top_left.x - _image_canvas.get_width()))
			var y_end = min(_image_brush.get_height(), -(brush_top_left.y - _image_canvas.get_height()))

			#Use the brush to draw changes on to canvas by using the white strength to determine the strength of the edit.
			for y in range(y_start, y_end):
				for x in range(x_start, x_end):
					#The pixel we are changing on the canvas.
					var pixel = Vector2(brush_top_left.x + x, brush_top_left.y + y)
					#The colour of the brush at the current position.
					var	brush_colour = _image_brush.get_pixel(x, y)
					#The strength at which to modify the canvas pixel's current colour based on the strength of the white on the brush pixel.
					var strength = brush_colour.r * brush_colour.g * brush_colour.b * brush_strength

					#Prevent exclusion texture coming through in dark areas of brush.
					if strength > 0.01:
						#Set pixel colour by interpolating between current colour and the colour to be changed to, by the strength defined.
						_image_canvas.set_pixel(pixel.x, pixel.y, _image_canvas.get_pixel(pixel.x, pixel.y).linear_interpolate(_paint_colour, strength))

		#Clear points, as we have painted to them.
		_paint_points.clear()

		#Unlock canvas from write access, so it may be drawn.
		_image_canvas.unlock()
		#Generate mip-maps for new image, and display the image through the sprite's texture.
		_image_canvas.generate_mipmaps()
		texture.set_data(_image_canvas)

## SIGNALS AUTOMATIC ##

#Updates the brush strength when the value is changed on the user interface.
func _on_BrushStrength_value_changed(value):
	brush_strength = value
	$PaintingTools/StrengthControl/Ordering/Label.text = String(value)