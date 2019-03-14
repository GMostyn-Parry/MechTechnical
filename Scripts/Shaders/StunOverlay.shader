shader_type canvas_item;
/*
 * Author:	George Mostyn-Parry
 *
 * Creates a double-vision effect around everything around the screen, and
 * darkens everything on screen. These effects fade as the time_left reaches zero.
 * Uses the starting time and remaining time to determine strength.
 */

//The initial time left when the stun occurred.
uniform float time_starting : hint_range(0, 100);
//The time left in the stun.
uniform float time_left : hint_range(0, 100);

void fragment()
{
	//Adjusts the screen's UV horizontally, and creates an adjusted version of the screen with it.
	vec2 adjusted_screen_uv = SCREEN_UV;
	//Effect lessens as time goes on.
	adjusted_screen_uv.x += (time_left / time_starting) * 0.01;
	vec4 first_double = texture(SCREEN_TEXTURE, adjusted_screen_uv);
	
	//Does the same, but the other way.
	adjusted_screen_uv = SCREEN_UV;
	adjusted_screen_uv.x -= (time_left / time_starting) * 0.01;
	vec4 second_double = texture(SCREEN_TEXTURE, adjusted_screen_uv);
	
	//Blends the two doubles equally.
	COLOR = first_double * 0.5 + second_double * 0.5;
	
	//Uniform transparency of half-transparent.
	COLOR.a = 0.5;
	//Brighten the overlay as less time is left; but not fully, so it will pop when the stun ends.
	COLOR.xyz = COLOR.xyz * ((time_starting - time_left - 0.5) / time_starting);
}