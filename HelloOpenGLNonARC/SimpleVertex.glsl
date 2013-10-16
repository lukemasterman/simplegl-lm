attribute vec4 Position;
attribute vec4 SourceColour;

varying vec4 DestinationColour;

uniform mat4 Projection;
uniform mat4 ModelView;

void main(void) {
    DestinationColour = SourceColour;
    gl_Position = Projection * ModelView * Position;
}