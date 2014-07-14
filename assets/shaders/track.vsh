attribute vec4 aPosition;
attribute vec2 aUV;

uniform mat4 uTransform;

varying MEDP vec2 vUV;

void main()
{
	gl_Position = aPosition * uTransform;
	vUV = aUV;
}
