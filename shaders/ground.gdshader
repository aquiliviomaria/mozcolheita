shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D detalhe : repeat_enable, filter_linear_mipmap;
uniform vec3 relva : source_color = vec3(0.08,0.16,0.045);
uniform vec3 terra : source_color = vec3(0.19,0.15,0.07);
varying vec3 posicao_mundo;
void vertex() { posicao_mundo = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
 vec2 p = posicao_mundo.xz;
 vec3 fino = texture(detalhe,p*0.16).rgb;
 float manchas = texture(detalhe,p*0.012).r;
 float grao = texture(detalhe,p*0.72).g;
 float seco = smoothstep(0.35,0.65,manchas);
 ALBEDO = mix(relva,terra,seco*0.25)*(0.84+fino.r*0.24);
 ALBEDO += vec3(0.012,0.010,0.007)*smoothstep(0.65,0.82,grao);
 ROUGHNESS = 0.88+grao*0.12;
 SPECULAR = 0.12;
}
