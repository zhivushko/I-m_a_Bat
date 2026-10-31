shader_type canvas_item;

uniform vec4 wave_color : source_color = vec4(1.0);
uniform float reveal_alpha : hint_range(0.0, 1.0) = 0.0;
uniform int active_waves_count = 0;
uniform vec2 wave_centers[8];
uniform float wave_radii[8];
uniform float max_radii[8];
uniform float global_alphas[8];

// Передаём мировые координаты из vertex в fragment
varying vec2 world_position;

void vertex() {
    // MODEL_MATRIX доступна здесь: преобразуем локальные координаты вершины в мировые
    world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;

	float glow = 0.0;
	for (int i = 0; i < 8; i++) {
		if (i >= active_waves_count) break;
		float r = wave_radii[i];
		if (r <= 0.5) continue;
		float d = distance(world_position, wave_centers[i]);
		float thickness = 4.0;
		float ring = smoothstep(r - thickness, r, d) * (1.0 - smoothstep(r, r + thickness, d));
		glow += ring * global_alphas[i];
	}
	glow = clamp(glow, 0.0, 1.0);
	glow = max(glow, reveal_alpha * step(0.01, glow));

	COLOR = base + wave_color * glow;   // ← аддитивно, без пересвета
}