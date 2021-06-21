class_name ArmyBase
extends KinematicBody2D

export var population : int = 100

onready var select_area = $SelectionArea
onready var level = get_node("/root/LevelManager").current_level
onready var hud_controller = level.hud_controller
onready var map_manager = level.map_manager

# assigned on birth by army manager
var army_id : int

# map movement

var velocity = 100 # sec
var target : Vector2 = global_position
var position_error = 5 # pixels from target

func _ready():
	select_area.connect("input_event", self, "on_select_input_event")

func _physics_process(delta):
	if !map_manager.is_paused:
		move(delta)

func move(delta):
	var facing = target - global_position
	# anti-jitter
	if facing.length_squared() < position_error * position_error: return
	var movement = facing.normalized() * velocity * delta
	move_and_collide(movement)

func on_select_input_event(viewport, event, shape_idx):
	if event.is_action_pressed("ui_lmb"):
		hud_controller.on_army_selected(self)

func set_target(target):
	self.target = target
	print(name, " target set: ", self.target)
