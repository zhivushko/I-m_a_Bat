shader_type canvas_item;

uniform vec2 wave_centers[8];
uniform float wave_radii[8];
uniform float max_radii[8];
uniform float global_alphas[8];
uniform int active_waves_count = 0;

uniform float edge_softness = 20.0;
uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float reveal_alpha : hint_range(0.0, 1.0) = 0.0;

varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float max_sonar_alpha = reveal_alpha;

	for (int i = 0; i < 8; i++) {
		if (i >= active_waves_count) {
			break;
		}

		float dist = distance(world_position, wave_centers[i]);
		float current_r = wave_radii[i];
		float max_r = max_radii[i];
		float g_alpha = global_alphas[i];

		float wave_front = smoothstep(current_r + edge_softness, current_r, dist);
		float boundary = 1.0 - smoothstep(max_r - edge_softness * 2.0, max_r, dist);

		float visibility = wave_front * boundary * g_alpha;

		if (visibility > max_sonar_alpha) {
			max_sonar_alpha = visibility;
		}
	}

	vec4 col = base_color;
	col.a *= max_sonar_alpha;
	COLOR = col;
}
