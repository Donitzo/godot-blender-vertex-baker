shader_type spatial;

const mat4 bayer_matrix = mat4(
    vec4(00.0 / 16.0, 12.0 / 16.0, 03.0 / 16.0, 15.0 / 16.0),
    vec4(08.0 / 16.0, 04.0 / 16.0, 11.0 / 16.0, 07.0 / 16.0),
    vec4(02.0 / 16.0, 14.0 / 16.0, 01.0 / 16.0, 13.0 / 16.0),
    vec4(10.0 / 16.0, 06.0 / 16.0, 09.0 / 16.0, 05.0 / 16.0));

uniform sampler2D albedo: source_color, hint_default_white;
uniform vec4 albedo_color: source_color = vec4(1.0);

uniform sampler2D emission: source_color, hint_default_black;
uniform vec3 emission_color: source_color = vec3(0.0);
uniform float emission_strength: hint_range(0.0, 16.0) = 1.0;

uniform sampler2D normal_map: hint_normal;
uniform float normal_scale: hint_range(-8.0, 8.0) = 1.0;

uniform float metallic: hint_range(0.0, 1.0) = 0.0;
uniform float roughness: hint_range(0.0, 1.0) = 0.8;

void fragment() {
    vec4 color = texture(albedo, UV) * albedo_color * COLOR;
    ALBEDO = color.rgb;
    EMISSION = texture(emission, UV).rgb * emission_color * emission_strength;
    NORMAL_MAP = normalize(texture(normal_map, UV).rgb * 2.0 - 1.0) * vec3(normal_scale, normal_scale, 1.0);
    METALLIC = metallic;
    ROUGHNESS = roughness;
    ALPHA = color.a;
    int x = int(FRAGCOORD.x - 4.0 * floor(FRAGCOORD.x / 4.0));
    int y = int(FRAGCOORD.y - 4.0 * floor(FRAGCOORD.y / 4.0));
    ALPHA_SCISSOR_THRESHOLD = bayer_matrix[x][y];
}