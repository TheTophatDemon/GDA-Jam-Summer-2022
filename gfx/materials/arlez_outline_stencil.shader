/*
	アウトラインシルエットシェーダー Pass #1 （ステンシル） by あるる（きのもと 結衣）
	Outline Silhouette Shader Pass #1 (Stencil) by Yui Kinomoto @arlez80

	MIT License
*/

shader_type spatial;
render_mode depth_draw_always, unshaded;

uniform float bias = 1.0;

varying mat4 camera_matrix;

void vertex( )
{
	camera_matrix = CAMERA_MATRIX;
}

void fragment( )
{
	vec4 screen_pixel_vertex = vec4( vec3( SCREEN_UV, textureLod( DEPTH_TEXTURE, SCREEN_UV, 0.0 ).x ) * 2.0 - 1.0, 1.0 );
	vec4 screen_pixel_coord = INV_PROJECTION_MATRIX * screen_pixel_vertex;
	screen_pixel_coord.xyz /= screen_pixel_coord.w;
	float depth = -screen_pixel_coord.z;

	float z = -VERTEX.z;

	ALPHA = 0.0;
	DEPTH = 1.0 - float( depth < z + bias );
}

