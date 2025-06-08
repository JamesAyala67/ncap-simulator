shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float time;
uniform float slowdown_intensity : hint_range(0.0, 1.0) = 0.0;

vec2 curve(vec2 uv) {
	uv = (uv - 0.5) * 2.0;
	uv *= 1.05; // Slightly reduced curve strength
	uv.x *= 1.0 + pow((abs(uv.y) / 5.0), 2.0);
	uv.y *= 1.0 + pow((abs(uv.x) / 4.0), 2.0);
	uv = (uv / 2.0) + 0.5;
	uv = uv * 0.94 + 0.03; // Less cropping
	return uv;
}

void fragment() {
	vec2 iResolution = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 q = FRAGCOORD.xy / iResolution.xy;
	vec2 uv = curve(q);
	vec3 col;

	// Reduced CRT wiggle
	float x = sin(0.3 * time + uv.y * 21.0) *
	          sin(0.7 * time + uv.y * 29.0) *
	          sin(0.3 + 0.33 * time + uv.y * 31.0) * 0.0003;

	col.r = texture(screen_texture, vec2(x + uv.x + 0.001, uv.y + 0.001)).r + 0.04;
	col.g = texture(screen_texture, vec2(x + uv.x + 0.000, uv.y - 0.002)).g + 0.04;
	col.b = texture(screen_texture, vec2(x + uv.x - 0.002, uv.y + 0.000)).b + 0.04;

	col.r += 0.06 * texture(screen_texture, 0.75 * vec2(x + 0.025, -0.027) + vec2(uv.x + 0.001, uv.y + 0.001)).r;
	col.g += 0.04 * texture(screen_texture, 0.75 * vec2(x - 0.022, -0.02) + vec2(uv.x + 0.000, uv.y - 0.002)).g;
	col.b += 0.06 * texture(screen_texture, 0.75 * vec2(x - 0.02, -0.018) + vec2(uv.x - 0.002, uv.y + 0.000)).b;

	// Slightly boost brightness and clarity
	col = clamp(col * 0.65 + 0.35 * col * col * 1.0, 0.0, 1.0);

	// Vignette
	float vig = 12.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y);
	col *= vec3(pow(vig, 0.3)); // Slightly shallower falloff

	// Tint & brightness
	col *= vec3(0.98, 1.03, 0.98); // Softer green tint
	col *= 2.7; // Slightly brighter

	// Scan roll effect
	float scans = clamp(0.4 + 0.3 * sin(3.5 * time + uv.y * iResolution.y * 1.5), 0.0, 1.0);
	col *= vec3(0.5 + 0.6 * pow(scans, 1.6));

	// Subtle flicker
	float comp = smoothstep(0.2, 0.8, sin(time));
	col *= 0.96 + 0.04 * comp;

	// Horizontal sync lines (less intense)
	col *= 1.0 - 0.15 * vec3(clamp((mod(FRAGCOORD.x, 2.0) - 1.0) * 2.0, 0.0, 1.0));

	// Subtle scanlines
	float scan = sin(FRAGCOORD.y * 3.5 + time * 8.0) * 0.05;
	float brightness = dot(col, vec3(0.299, 0.587, 0.114));
	scan *= smoothstep(0.0, 0.8, 1.0 - brightness);
	col -= vec3(scan);

	// Power-on flash
	float startup_flash = clamp(1.0 - time * 1.5, 0.0, 1.0);
	col = mix(vec3(1.0), col, 1.0 - startup_flash);

	// === Subtle Bloom ===
	vec3 blur = vec3(0.0);
	float blur_strength = 0.01;

	blur += texture(screen_texture, uv + vec2(-1.0, -1.0) * blur_strength).rgb;
	blur += texture(screen_texture, uv + vec2(1.0, -1.0) * blur_strength).rgb;
	blur += texture(screen_texture, uv + vec2(-1.0, 1.0) * blur_strength).rgb;
	blur += texture(screen_texture, uv + vec2(1.0, 1.0) * blur_strength).rgb;
	blur /= 4.0;

	col = mix(col, blur, 0.1); // Slight bloom

	// Soft clarity
	col = mix(col, vec3(1.0), 0.02);

	// Bounds check
	col = clamp(col, 0.0, 1.0);
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)
		col *= 0.0;

	// === BORDER FRAME ===
float edge_softness = 0.015; // Edge fade width
float border_thickness = 0.04; // Border width from edges

float bx = smoothstep(border_thickness, border_thickness + edge_softness, uv.x);
float by = smoothstep(border_thickness, border_thickness + edge_softness, uv.y);
float bxn = smoothstep(1.0 - border_thickness, 1.0 - border_thickness - edge_softness, uv.x);
float byn = smoothstep(1.0 - border_thickness, 1.0 - border_thickness - edge_softness, uv.y);

float border_mask = bx * by * bxn * byn;

col *= border_mask; // Darkens outer region


	COLOR = vec4(col, 1.0);
}
