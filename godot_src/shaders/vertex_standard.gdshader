shader_type spatial;

const mat4 bayer_matrix = mat4(
    vec4(00.0 / 16.0, 12.0 / 16.0, 03.0 / 16.0, 15.0 / 16.0),
    vec4(08.0 / 16.0, 04.0 / 16.0, 11.0 / 16.0, 07.0 / 16.0),
    vec4(02.0 / 16.0, 14.0 / 16.0, 01.0 / 16.0, 13.0 / 16.0),
    vec4(10.0 / 16.0, 06.0 / 16.0, 09.0 / 16.0, 05.0 / 16.0));

uniform vec4 albedo_color: source_color = vec4(1.0);

uniform vec3 emission_color: source_color = vec3(0.0);
uniform float emission_strength: hint_range(0.0, 16.0) = 1.0;

void fragment() {
    //float custom = UV.x;
    float emission_factor = (1.0 - UV.y) * emission_strength;
    ALBEDO = COLOR.rgb * albedo_color.rgb * (1.0 - emission_factor);
    EMISSION = (COLOR.rgb + emission_color) * emission_factor;
    METALLIC = UV2.x;
    ROUGHNESS = 1.0 - UV2.y;
    ALPHA = COLOR.a;
    int x = int(FRAGCOORD.x - 4.0 * floor(FRAGCOORD.x / 4.0));
    int y = int(FRAGCOORD.y - 4.0 * floor(FRAGCOORD.y / 4.0));
    ALPHA_SCISSOR_THRESHOLD = bayer_matrix[x][y];
}