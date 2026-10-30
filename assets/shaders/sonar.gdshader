shader_type canvas_item;

uniform vec2 wave_centers[8];
uniform float wave_radii[8];
uniform float wave_thicknesses[8];
uniform float wave_intensities[8];
uniform int active_waves_count = 0;

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
		float r = wave_radii[i];
		float thick = wave_thicknesses[i];

		float ring_dist = abs(dist - r);
		if (ring_dist < thick) {
			float ring_factor = 1.0 - (ring_dist / thick);
			ring_factor = smoothstep(0.0, 1.0, ring_factor);
			float current_alpha = ring_factor * wave_intensities[i];
			if (current_alpha > max_sonar_alpha) {
				max_sonar_alpha = current_alpha;
			}
		}
	}

	vec4 col = base_color;
	col.a *= max_sonar_alpha;
	COLOR = col;
}
