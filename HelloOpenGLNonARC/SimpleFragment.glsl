varying mediump vec4 DestinationColour;
varying mediump vec2 TexCoordOut;
varying mediump vec4 Diffusion;
uniform sampler2D Texture;

void main(void)
{
    gl_FragColor = Diffusion * texture2D(Texture, TexCoordOut);
//    gl_FragColor = DestinationColour;
}