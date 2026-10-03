shader_type canvas_item;

uniform float reveal_progress : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	// The incoming opaque plate is revealed spatially, rather than alpha-
	// blended with a different building layout. Keep a small soft edge.
	float boundary = mix(-0.03, 1.03, reveal_progress);
	float coverage = 1.0 - smoothstep(boundary - 0.012, boundary + 0.012, UV.x);
	COLOR.a *= coverage;
}
