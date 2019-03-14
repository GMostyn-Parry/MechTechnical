shader_type canvas_item;
/*
 * Author: George Mostyn-Parry
 *
 * Blends textures on a surface together using a blendmap that is stored
 * as the surface's texture. Uses RGBA blending, so five textures may be used.
 */

//Texture for when each value is at one.
uniform sampler2D r : hint_albedo;
uniform sampler2D g : hint_albedo;
uniform sampler2D b : hint_albedo;
uniform sampler2D a : hint_albedo;
//Texture for when every value is zero.
uniform sampler2D exclude : hint_albedo;

void fragment()
{
	//Base texture should be of blend-map.
	vec4 blend = texture(TEXTURE, UV * 0.125);
	
	//Vectorise textures, so they may have their influence on the pixel calculated.
	vec4 first = texture(r, UV);
	vec4 second = texture(g, UV);
	vec4 third = texture(b, UV);
	vec4 fourth = texture(a, UV);
	vec4 fifth = texture(exclude, UV);
	
	//Blend the textures together with the values of the blend-map.
	COLOR = first * blend.r +
			second * blend.g + 
			third * blend.b +
			fourth * blend.a +
			+ fifth * (1.0 - blend.r - blend.g - blend.b - blend.a);
}