varying MEDP vec2 vUV;

uniform sampler2D sampler;

void main()
{
	gl_FragColor = texture2D(sampler, vUV);
}
