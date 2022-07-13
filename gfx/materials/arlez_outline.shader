/*
	アウトラインシルエットシェーダー Pass #2 （アウトライン） by あるる（きのもと 結衣）
	Outline Silhouette Shader Pass #2 (Outline) by Yui Kinomoto @arlez80

	MIT License
*/

shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 color : hint_color = vec4( 1.0, 1.0, 1.0, 1.0 );
uniform float bias = -1.0;
uniform float thickness = 0.05;

varying mat4 camera_matrix;

void vertex( )
{
	VERTEX += NORMAL * thickness;
	camera_matrix = CAMERA_MATRIX;
}

void fragment( )
{
	vec4 screen_pixel_vertex = vec4( vec3( SCREEN_UV, textureLod( DEPTH_TEXTURE, SCREEN_UV, 0.0 ).x ) * 2.0 - 1.0, 1.0 );
	vec4 screen_pixel_coord = INV_PROJECTION_MATRIX * screen_pixel_vertex;
	screen_pixel_coord.xyz /= screen_pixel_coord.w;
	float depth = -screen_pixel_coord.z;

	float z = -VERTEX.z;

	ALBEDO = color.rgb;
	ALPHA = color.a * float( depth < z + bias );
	DEPTH = 0.00001;
}

