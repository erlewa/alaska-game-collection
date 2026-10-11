# Simulate heatflow using a GPU texture
# Code written by Orion Lawlor 2026-10 (this file Public Domain)
class_name SimDisplay
extends Sprite2D

# Import sim size from BlockControl
const MAXGRID_X = BlockControl.MAXGRID_X
const MAXGRID_Y = BlockControl.MAXGRID_Y

# Our boundary values, initialized from the CPU by BlockControl
@export var boundaries : Image = Image.create(MAXGRID_X,MAXGRID_Y,false,Image.FORMAT_RGBAF)
@export var boundaries_texture : ImageTexture = ImageTexture.create_from_image(boundaries)

# Simulation parameters
@export var heat_texture : ImageTexture = ImageTexture.create_from_image(boundaries)

# Called by BlockControl when our boundaries change
func boundaries_updated():
	boundaries_texture.update(boundaries)

# Take one timestep of our simulation. Returns an Image of our current state.
func timestep():
	step_simulation()
	var curtex : Texture2D = get_current_result_texture()
	texture = curtex # show sim state onscreen
	
	return boundaries # FIXME: copy out latest curtex to an Image



# Render-to-texture code only slightly modified from Google Gemini Thinking (2026-10-09)
@export var sim_size := Vector2i(MAXGRID_X, MAXGRID_Y)

@onready var vp_a: SubViewport = $ViewportA
@onready var vp_b: SubViewport = $ViewportB
@onready var rect_a: ColorRect = $ViewportA/RectA
@onready var rect_b: ColorRect = $ViewportB/RectB

var mat_a: ShaderMaterial
var mat_b: ShaderMaterial
var targetA := false

# Initialize uniforms for this shader
func set_uniforms(mat : ShaderMaterial):
	var texel = Vector2(1.0 / sim_size.x, 1.0 / sim_size.y)

	mat.set_shader_parameter("texel", texel)
	mat.set_shader_parameter("boundary_tex", boundaries_texture)

func _ready() -> void:
	_setup_viewports()

	mat_a = rect_a.material as ShaderMaterial
	mat_b = rect_b.material as ShaderMaterial
	
	# Set the pingpong textures A -> B and B->A
	mat_a.set_shader_parameter("state_tex", vp_b.get_texture())
	mat_b.set_shader_parameter("state_tex", vp_a.get_texture())
	
	# Set the other uniforms
	set_uniforms(mat_a)
	set_uniforms(mat_b)


func _setup_viewports() -> void:
	for vp in [vp_a, vp_b]:
		vp.size = sim_size
		vp.use_hdr_2d = true
		vp.disable_3d = true
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED

	rect_a.custom_minimum_size = Vector2(sim_size)
	rect_b.custom_minimum_size = Vector2(sim_size)

# Call this method to execute one Jacobi iteration step on GPU
func step_simulation() -> void:
	if targetA:
		vp_a.render_target_update_mode = SubViewport.UPDATE_ONCE
	else:
		vp_b.render_target_update_mode = SubViewport.UPDATE_ONCE

	targetA = !targetA

# Returns the latest heat state texture
#  This is the texture *not* being rendered by the GPU right now
func get_current_result_texture() -> Texture2D:
	return vp_b.get_texture() if targetA else vp_a.get_texture()
