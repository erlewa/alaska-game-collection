# User interface controller for blocks.
#   "Mega class" that handles:
#   - User interface clicks
#   - Graphical display
#   - Simulation
# Somehow, this should probably be broken up?
#
# Architected with help from Google Gemini, 
# Code written by Orion Lawlor 2026-10 (this file Public Domain)
class_name BlockControl
extends Control

const GRID_SIZE := 16 # Build anchor grid spacing in pixels
const BLOCK_SIZE := 32 # Visual block size in pixels
const MAXGRID_X = 64
const MAXGRID_Y = 32

# This is the main data storage for all blocks!
# Dictionary where Key = Vector2i(x, y), Value = BlockData
var grid: Dictionary = {}

# Grid scroll distance, in anchor grid cells. This is the block under pixel (0,0)
var grid_corner : Vector2i = Vector2i(0,0)

# Link to our toolbar's button group, so we know what tool is active
@export var toolbar : ButtonGroup 

# Enum of the block types
const BlockType = BlockData.BlockType

@export var gui_output : Control # gui output area (ourselves!)

# Graphical block instance for displaying mouse hover
var gui_hoverblock : Sprite2D 
var gui_hoverblock_type : BlockType = BlockType.ERROR 

# List of block types (somehow match this with strings?)
# Preloaded visual/physics scenes for that block type
@export var gui_block_delete: PackedScene  # used for hover only
@export var gui_block_snow: PackedScene 
@export var gui_block_fire: PackedScene 


# Set up our variables
func _ready():
	# Add strip of snow along bottom
	for x in range(0,MAXGRID_X,2):
		try_place_block(Vector2i(x,MAXGRID_Y-2),BlockType.SNOW)

# Create a gui block of this type
func gui_block_create(type : BlockType) -> Sprite2D:
	# FIXME: check string and add other block types here
	if type == BlockType.DELETE: 
		return gui_block_delete.instantiate() as Sprite2D
	if type == BlockType.SNOW: 
		return gui_block_snow.instantiate() as Sprite2D
	if type == BlockType.FIRE: 
		return gui_block_fire.instantiate() as Sprite2D
	print("gui_block_create Error: invalid enum ",type)
	return null

# Adjust the currently displayed hoverblock to this string type
func gui_hoverblock_show(type : BlockType):
	if type != gui_hoverblock_type:
		# Build a new one:
		gui_hoverblock_type=type
		if gui_hoverblock:
			gui_hoverblock.queue_free() # remove the old block
		gui_hoverblock = gui_block_create(type)
		gui_hoverblock.modulate.a = 0.4 # semi-transparent
		gui_output.add_child(gui_hoverblock)

# Look up the current BlockType from the tool
func gui_tooltype() -> BlockType:
	# HACKY current tool check
	var tool = toolbar.get_pressed_button()
	var toolname = tool.name if tool else ""
	if toolname == "ToolDelete":
		return BlockType.DELETE
	if toolname == "ToolSnow":
		return BlockType.SNOW
	if toolname == "ToolFire":
		return BlockType.FIRE
	print("gui_tooltype Error: unknown toolname ",toolname)
	return BlockType.ERROR

# Handle user input
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		var screen_pos := get_global_mouse_position()
		var g := grid_from_screen(screen_pos)
		
		var type : BlockType = gui_tooltype()
		
		# Update mouse hover:
		gui_hoverblock_show(type)
		gui_hoverblock.global_position = screen_from_grid(g)
		
		# Handle mouse clicks:
		if event.button_mask != 0: # if event is InputEventMouseButton and event.pressed:
			# Build with left click
			if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
				if type == BlockType.DELETE:
					gui_delete(g)
				else:
					if grid_buildable(g):
						try_place_block(g,type)
			
			# Remove with right click (check for any corner)
			if event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
				gui_delete(g)

# Handle gui deletion at this grid cell (or nearby)
func gui_delete(g : Vector2i) -> void:
	for dx in [-1,0]:
		for dy in [-1,0]:
			grid_clear(g+Vector2i(dx,dy))

# Try to delete this exact grid cell
func grid_clear(g : Vector2i):
	if (grid.has(g)):
		var data = grid[g]
		data.gui.queue_free()
		grid.erase(g)

# Return if this anchor grid position is valid for building
func grid_buildable(g : Vector2i) -> bool:
	return g.x in range(0, MAXGRID_X-1) and g.y in range(0, MAXGRID_Y-1)

# Return true if anything in this grid box is already occupied (in any corner)
#  dxl to dxh and dyl to dyh are low-to-high inclusive ranges
func grid_occupied(g : Vector2i,
	dxl : int = -1, dxh : int = +1, 
	dyl : int = -1, dyh : int = +1) -> bool:
	for dx in range(dxl,dxh+1):
		for dy in range(dyl,dyh+1):
			if grid.has(g+Vector2i(dx,dy)):
				return true
	return false

# Given a screen position, in pixels, return our anchor grid coordinates
func grid_from_screen(screen_pos: Vector2) -> Vector2i:
	return grid_corner + Vector2i(
		floori((screen_pos.x) / GRID_SIZE),
		floori((screen_pos.y) / GRID_SIZE)
	)

# Given an anchor grid (x,y) position, return the screen coordinates pixels for corner
func screen_from_grid(grid_pos: Vector2i) -> Vector2:
	return Vector2((grid_pos-grid_corner) * GRID_SIZE)

# Add block at this grid position
func try_place_block(g: Vector2i, type: BlockType) -> void:
	#  We're the center point, anything nearby will overlap us.
	if grid_occupied(g):
		print("Rejecting block at ",type," at ",g)
		return # Area occupied already
	print("Making block ",type," at ",g)

	# Spawn visual node onscreen
	var gui := gui_block_create(type)
	gui.global_position = screen_from_grid(g)
	gui_output.add_child(gui)

	# Store in grid
	var data := BlockData.new()
	data.type = type
	data.gui = gui
	data.loc = g
	data.vel = Vector2(0,0)
	data.mass = 1.0
	data.temp = 200.0 if (type==BlockType.FIRE) else 0.0
	
	grid[g] = data


# Update the simulation in SimDisplay with our data
func update_sim():
	var sim : SimDisplay = $SimDisplay # Simulation output
	if sim == null:
		print("BlockControl can't find SimDisplay in update_texture?")
		return null
	
	# Might check if the boundaries image is unchanged here?
	var boundaries : Image = sim.boundaries
	boundaries.fill(Color.BLACK) # erase to all zeros
	for g in grid: # loop over occupied grid cells
		var data = grid[g] # fetch data at this cell
					   #         red                green         blue
		var color = Color(data.type==BlockType.FIRE, 0.0, data.type==BlockType.SNOW)
		for dx in [0,1]: for dy in [0,1]: if g.y+dy<MAXGRID_Y:
			boundaries.set_pixel(g.x+dx,g.y+dy,color)
	sim.boundaries_updated()
	
	# Take a sim timestep
	return sim.timestep()
	

# Stores updated dictionary used during physics_process.
# https://docs.godotengine.org/en/stable/classes/class_dictionary.html#class-dictionary-method-erase:
# "Do not erase entries while iterating over the dictionary. You can iterate over the keys() array instead."
# (In practice erasing while iterating causes weirdly laggy updates as later iterations get skipped!)
var grid_next: Dictionary = {}

const physics_grid_timestep : float = 1.0/30.0 # timestep we use for grid updates
var physics_time_saved : float = 0 # time saved up until next rate-limited physics

# Simulate grid-based physics 
func _physics_process(delta: float) -> void:
	physics_time_saved += delta # save up realtime
	if (physics_time_saved<physics_grid_timestep): 
		return # not ready yet
	# else we're ready to take a grid physics timestep
	physics_time_saved -= physics_grid_timestep 
	
	var _simstate : Image = update_sim()
	
	# "Ping-pong" double buffered grid:
	#  read from old grid, write to grid_next, then swap grids
	for g in grid:
		var data = grid[g]
		if g.y>=MAXGRID_Y-1 or grid_occupied(g,-1,+1,+1,+2):
			# Block is supported: retain unmodified
			grid_next[g] = data 
		else:
			# Block is unsupported below: shift it down
			g.y = g.y+1 
			data.loc = g
			grid_next[g]=data
			# Update GUI position
			data.gui.global_position=screen_from_grid(g)

	# Swap grid and grid_next (via temporary, python tuple doesn't seem to work?)
	var old_grid = grid 
	grid = grid_next
	grid_next = old_grid
	grid_next.clear() # prep for next frame
