shader_type canvas_item;

uniform sampler2D state_tex : filter_nearest; // last frame
uniform sampler2D boundary_tex : filter_nearest; // boundaries: fire (red) and snow (blue)
uniform vec2 texel; // texture coordinate shift to get to our next pixel

void fragment() {
    vec2 uv = UV;
	
	// Look up our existing state
    float t  = texture(state_tex, uv + vec2(0.0, 0.0)).r;
	
	// Look up our block data to set boundary conditions.
    // block data encoding: block.r if fire, block.b if snow
    vec4 block = texture(boundary_tex, uv);

	// Interior points do averaging
    // 5-point discrete Laplace operator for Jacobi iteration
    float t_left  = texture(state_tex, uv + vec2(-texel.x, 0.0)).r;
    float t_right = texture(state_tex, uv + vec2( texel.x, 0.0)).r;
    float t_up    = texture(state_tex, uv + vec2(0.0, -texel.y)).r;
    float t_down  = texture(state_tex, uv + vec2(0.0,  texel.y)).r;

    float neighbors = 0.25 * (t_left + t_right + t_up + t_down);
	if (block.b>0.5) { // snow pixel: heat travels slowly (this doesn't seem to work well?)
		t = mix(t,neighbors,0.05); // mostly our old temperature
	} else { // ordinary pixel
		t = mix(t,neighbors,0.95); // mostly neighbors (too much neighbor gives jangly checkerboards)
	}
	
	// color temperature of snow (cool, but *much* less cold than the sky)
	//  fun fact: 20C to 0C is *halfway* to -20C
	const float t_snow = 0.5; 
	const float insulate_snow=0.98; // mostly old temperature
	if (block.b>0.5) { // snow pixel
		t=mix(t_snow,t,insulate_snow); 
	}
	
	const float t_fire = 2.0; // fire is really hot!
	const float propagate_fire=0.05; // low heat travel rate (less than neighboring pixels)
	if (block.r>0.5) { // fire pixel
		t=mix(t_fire,t,propagate_fire); // add heat, but in a limited way 
	}
	
	const float t_sky = 0.0; // sky is really cold
	if (uv.y<=texel.y) {  // top row: set cold sky boundary color
		t=t_sky; // sky is maximum cold, maximum strength
	}
	
	
	// Apply red (hot) to blue (cold) default gradient
	//  subtle: red needs to be raw temperature, it's used by this shader
	float g = 0.0, b = 1.0-t;
	// Temperatures over 1.0 overflow into white hot
	float over = 0.0;
	if (t>1.0) {
		over = t-1.0;
	}
	const float underthresh = 0.2;
	float under = 0.0; // visible undercooling
	if (t<underthresh) {
		under = underthresh - t;
	}
    COLOR = vec4(t, g + over, b + over - 3.0*under, 1.0);
}
