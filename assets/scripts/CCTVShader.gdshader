// CRT + Scanlines + CCTV Flicker Shader
// Based on: https://www.shadertoy.com/view/Ms23DR
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float time;

vec2 curve(vec2 uv)
{
	uv = (uv - 0.5) * 2.0;
	uv *= 1.1;
	uv.x *= 1.0 + pow((abs(uv.y) / 5.0), 2.0);
	uv.y *= 1.0 + pow((abs(uv.x) / 4.0), 2.0);
	uv = (uv / 2.0) + 0.5;
	uv = uv * 0.92 + 0.04;
	return uv;
}

void fragment()
{
	vec2 iResolution = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 q = FRAGCOORD.xy / iResolution.xy;
	vec2 uv = curve(q);
	vec3 col;

	// CRT distortion pattern
	float x = sin(0.3 * time + uv.y * 21.0) *
	          sin(0.7 * time + uv.y * 29.0) *
	          sin(0.3 + 0.33 * time + uv.y * 31.0) * 0.0017;

	col.r = texture(screen_texture, vec2(x + uv.x + 0.001, uv.y + 0.001)).r + 0.05;
	col.g = texture(screen_texture, vec2(x + uv.x + 0.000, uv.y - 0.002)).g + 0.05;
	col.b = texture(screen_texture, vec2(x + uv.x - 0.002, uv.y + 0.000)).b + 0.05;

	col.r += 0.08 * texture(screen_texture, 0.75 * vec2(x + 0.025, -0.027) + vec2(uv.x + 0.001, uv.y + 0.001)).r;
	col.g += 0.05 * texture(screen_texture, 0.75 * vec2(x - 0.022, -0.02) + vec2(uv.x + 0.000, uv.y - 0.002)).g;
	col.b += 0.08 * texture(screen_texture, 0.75 * vec2(x - 0.02, -0.018) + vec2(uv.x - 0.002, uv.y + 0.000)).b;

	col = clamp(col * 0.6 + 0.4 * col * col * 1.0, 0.0, 1.0);

	// Vignette
	float vig = 16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y);
	col *= vec3(pow(vig, 0.3));

	// Slight color tint + brightness boost
	col *= vec3(0.95, 1.05, 0.95);
	col *= 2.8;

	// Rolling brightness scan (CRT)
	float scans = clamp(0.35 + 0.35 * sin(3.5 * time + uv.y * iResolution.y * 1.5), 0.0, 1.0);
	col *= vec3(0.4 + 0.7 * pow(scans, 1.7));

	// Subtle flicker (CCTV-style)
	float comp = smoothstep(0.1, 0.9, sin(time));
	col *= 0.95 + 0.05 * comp;

	// Horizontal sync lines (emulates alternating pixel striping)
	col *= 1.0 - 0.65 * vec3(clamp((mod(FRAGCOORD.x, 2.0) - 1.0) * 2.0, 0.0, 1.0));

	// Scanline overlay (darkens alternating rows)
	float scan = sin(FRAGCOORD.y * 4.0 + time * 8.0) * 0.1;
	col -= vec3(scan);

	// Clamp & cleanup
	col = clamp(col, 0.0, 1.0);
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)
		col *= 0.0;

	COLOR = vec4(col, 1.0);
}
