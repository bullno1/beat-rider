attribute vec2 position;
attribute vec4 color;

uniform mat4 transform;

varying MEDP vec4 colorVarying;

void main()
{
	gl_Position = vec4(position.x, position.y, 0, 1) * transform;
	colorVarying = color;
}
