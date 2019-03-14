shader_type canvas_item;
/*
 * Author: George Mostyn-Parry
 *
 * Blends textures on a surface together using a blendmap that is stored
 * as the surface's texture. Uses RGBA blending, so five textures may be used.
 * Uses the transparency of each texture to determine depth for more natural blending
 * along grooves, cracks, etc.
 */

//Texture for when each value is at one.
uniform sampler2D r : hint_albedo;
uniform sampler2D g : hint_albedo;
uniform sampler2D b : hint_albedo;
uniform sampler2D a : hint_albedo;
//Texture for when every value is zero.
uniform sampler2D exclude : hint_albedo;

//Blend the five textures input via a RGBA blendmap, and the alpha of the textures formed by their grayscale. 
vec3 depthBlend(vec4 blend, vec4 first, vec4 second, vec4 third, vec4 fourth, vec4 fifth){	
	//The depth of other textures we want to include.
	float depth = 0.2;
	//Exclusion of the values from the blend-map.
	float blendsExclude = (1.0 - blend.r - blend.g - blend.b - blend.a);
	
	//Find maximum of all textures on this pixel, and remove the depth value.
	float ma = max(max(max(max(first.a + blend.r,
			second.a + blend.g),
			third.a + blend.b),
			fourth.a + blend.a),
			fifth.a + blendsExclude)
			- depth;
	
	//How much to include of each texture at this pixel.
	float b1 = max(first.a + blend.r - ma, 0);
	float b2 = max(second.a + blend.g - ma, 0);
	float b3 = max(third.a + blend.b - ma, 0);
	float b4 = max(fourth.a + blend.a - ma, 0);
	float b5 = max(fifth.a + blendsExclude - ma, 0);

	//Return a blend of all of the textures.
	return (first.rgb * b1 + second.rgb * b2 + third.rgb * b3 + fourth.rgb * b4 + fifth.rgb * b5) / (b1 + b2 + b3 + b4 + b5);
}

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
	
	//Use the opaque result of the depth blend as the background texture.
	COLOR = vec4(depthBlend(blend, first, second, third, fourth, fifth), 1.0);
}