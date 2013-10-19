attribute vec4 Position;
attribute vec4 Normals;
uniform vec4 SourceColour;

varying vec4 DestinationColour;

uniform mat4 Projection;
uniform mat4 ModelView;
uniform vec3 LightPosition;

void main(void) {
  vec3 ModelViewVertex = vec3(ModelView * Position);
  vec3 ModelViewNormal = vec3(ModelView * Normals);
  float Distance = length(LightPosition - ModelViewVertex);
  vec3 LightVector = normalize(LightPosition - ModelViewVertex);
  float Diffuse = max(dot(ModelViewNormal, LightVector), 0.1);
  Diffuse = Diffuse * (1.0/ (0.1 * Distance * Distance));
  DestinationColour = SourceColour * Diffuse;
  gl_Position = Projection * ModelView * Position;
}