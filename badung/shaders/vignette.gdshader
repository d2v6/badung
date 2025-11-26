shader_type canvas_item;

uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	// Get the UV coordinates (0 to 1)
	vec2 uv = UV;
	
	// Calculate distance from center
	vec2 center = vec2(0.5, 0.5);
	float dist = distance(uv, center);
	
	// Create vignette effect (darkens towards edges)
	float vignette = smoothstep(vignette_intensity, vignette_intensity * 2.5, dist);
	
	// Apply vignette
	COLOR = vec4(0.0, 0.0, 0.0, vignette * vignette_opacity);
}
