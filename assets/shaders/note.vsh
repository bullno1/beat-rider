attribute vec4 position;

uniform mat4 transform;
uniform vec4 ucolor;

varying LOWP vec4 vColor;

void main()
{
	gl_Position = position * transform;
	vColor = ucolor;
}
