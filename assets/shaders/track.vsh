attribute vec4 position;

uniform mat4 transform;
uniform float distanceToTexture;

varying MEDP vec2 uv;

void main()
{
	gl_Position = position * transform;

	float u = (sign(position.x) + 1.0) * 0.5;
	float v = position.z * distanceToTexture;
	uv = vec2(u, v);
}
