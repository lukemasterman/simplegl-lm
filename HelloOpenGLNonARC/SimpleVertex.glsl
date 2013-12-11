attribute vec4 Position;
attribute vec4 Normals;
attribute vec2 TexCoordIn;

uniform mat4 Projection;
uniform mat4 ModelView;
uniform vec3 LightPosition;
uniform vec4 SourceColour;

varying vec4 DestinationColour;
varying vec2 TexCoordOut;
varying vec4 Diffusion;

void main(void) {
  vec3 ModelViewVertex = vec3(ModelView * Position);
  vec3 ModelViewNormal = vec3(ModelView * Normals);
  float Distance = length(LightPosition - ModelViewVertex);
  vec3 LightVector = normalize(LightPosition - ModelViewVertex);
  float Diffuse = max(dot(ModelViewNormal, LightVector), 0.1);
  Diffuse = Diffuse * (1.0/ (0.2 * Distance * Distance));
  DestinationColour = SourceColour * Diffuse;
  Diffusion = vec4 (1.0) * Diffuse;
  TexCoordOut = TexCoordIn;
  gl_Position = Projection * ModelView * Position;
}