shader_type canvas_item;
// Destello al recibir daño y disolución al morir.

uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec4 c = COLOR;
	c.rgb = mix(c.rgb, flash_color.rgb * 2.2, flash);
	if (dissolve > 0.0) {
		float n = hash(floor(FRAGCOORD.xy / 3.0));
		if (n < dissolve) {
			discard;
		}
		c.rgb += vec3(0.4, 1.6, 1.8) * smoothstep(dissolve, dissolve + 0.08, n) * (1.0 - smoothstep(dissolve + 0.08, dissolve + 0.16, n)) * step(0.01, dissolve);
	}
	COLOR = c;
}
