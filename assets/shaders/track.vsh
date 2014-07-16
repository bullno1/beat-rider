attribute vec4 aPosition;
attribute vec2 aUV;
attribute float aDistance;

uniform mat4 uTransform;
uniform float uProjStart;
uniform float uProjLength;

varying MEDP vec2 vUV;
varying MEDP float vProjPosition;

void main()
{
	gl_Position = aPosition * uTransform;
	vUV = aUV;
	vProjPosition = (aDistance - uProjStart) / uProjLength;
}
