shader_type spatial;
render_mode unshaded;

uniform vec3 base_color = vec3(1.0, 0.5, 0.2);
uniform float shimmer_speed = 1.0;
uniform float shimmer_intensity = 0.5;

void fragment() {
    vec3 color = base_color;
    float shimmer = sin(TIME * shimmer_speed + FRAGCOORD.x * 0.1 + FRAGCOORD.y * 0.1) * shimmer_intensity;
    ALBEDO = color + shimmer;
}