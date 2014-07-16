uniform sampler2D uBaseSampler;
uniform sampler2D uProjSampler;

varying MEDP vec2 vUV;
varying MEDP float vProjPosition;

void main()
{
	vec4 baseColor = texture2D(uBaseSampler, vUV);
	vec4 projColor = texture2D(uProjSampler, vec2(vUV.s, vProjPosition));
	vec4 mixedColor = mix(baseColor, projColor, 0.6);
	bool inProj = 0.0 <= vProjPosition && vProjPosition <= 1.0;
	gl_FragColor = mix(baseColor, mixedColor, float(inProj));
}
