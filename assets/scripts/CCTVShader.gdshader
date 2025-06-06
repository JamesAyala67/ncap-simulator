shader_type canvas_item;
render_mode blend_mix;

uniform float time;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	float scan = sin(FRAGCOORD.y * 4.0 + time * 8.0) * 0.1;
    vec4 overlay = vec4(0.0, 0.0, 0.0, 0.25); // base transparency
    overlay.rgb -= scan;
    COLOR = overlay;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
