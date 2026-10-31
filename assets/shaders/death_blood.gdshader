shader_type canvas_item;
render_mode unshaded;

uniform vec2 origin = vec2(0.5);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float blackout : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 center = mix(vec2(0.5), origin, 0.08);
	vec2 p = abs(UV - center) * 2.0;
	// A soft rounded vignette gradually closes in, leaving the center readable.
	float edge_distance = pow(pow(p.x, 4.0) + pow(p.y, 4.0), 0.25);
	float inward_edge = mix(0.94, 0.28, progress);
	float vignette = smoothstep(inward_edge, 1.18, edge_distance);
	float entrance = smoothstep(0.0, 0.12, progress);
	float pulse = 1.0 + sin(progress * 6.2831853) * 0.035;
	float alpha = entrance * (0.08 + vignette * mix(0.32, 0.54, progress)) * pulse;
	vec3 color = mix(vec3(0.62, 0.018, 0.04), vec3(0.28, 0.004, 0.018), vignette);
	COLOR = vec4(mix(color, vec3(0.0), blackout), mix(alpha, 1.0, blackout));
}
