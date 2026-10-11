# Data used for simulating buildable blocks
#
class_name BlockData
extends RefCounted

enum BlockType { ERROR, DELETE, SNOW, FIRE }
var type: BlockType
var gui: Node2D                # Reference to the visible part of this block
var loc: Vector2i              # Anchor grid position
var vel: Vector2               # Velocity of block
var mass: float = 1.0          # Mass of block (kg)
var temp: float = 0.0          # Temperature of block (degrees C)
