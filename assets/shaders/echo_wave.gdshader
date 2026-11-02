shader_type canvas_item;

uniform vec4 wave_color : source_color = vec4(1.0);
uniform int active_waves_count = 0;
uniform vec2 wave_centers[8];
uniform float wave_radii[8];
uniform float max_radii[8];
uniform float global_alphas[8];

varying vec2 world_position;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
    vec4 base = texture(TEXTURE, UV) * COLOR;
    float glow = 0.0;

    for (int i = 0; i < 8; i++) {
        if (i >= active_waves_count) break;

        float r = wave_radii[i];
        float max_r = max_radii[i];
        if (r <= 0.5) continue;

        float d = distance(world_position, wave_centers[i]);
        if (d > max_r) continue;

        float thickness = 4.0;
        float ring = smoothstep(r - thickness, r, d) * (1.0 - smoothstep(r, r + thickness, d));
        float falloff = 1.0 - smoothstep(max_r * 0.7, max_r, d);

        glow += ring * global_alphas[i] * falloff;
    }
    
    glow = clamp(glow, 0.0, 1.0);

    // Никакого base.rgb + glow. Мы просто делаем тайл белым там, где проходит волна
    // Но если хочешь сохранить цвет тайла, используй mix:
    vec3 final_color = mix(base.rgb, wave_color.rgb, glow);
    COLOR = vec4(final_color, base.a);
}