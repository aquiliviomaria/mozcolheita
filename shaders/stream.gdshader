shader_type spatial;
render_mode cull_disabled;
void fragment() {
	float onda = sin(UV.x * 7.0 - TIME * 1.7 + sin(UV.y * 16.0)) * 0.5 + 0.5;
	float espuma = smoothstep(0.91, 1.0, onda) * 0.14;
	ALBEDO = mix(vec3(0.055,0.24,0.25),vec3(0.11,0.38,0.40),onda) + espuma;
	ROUGHNESS = 0.24;
	METALLIC = 0.15;
}
