class_name ArmyBase
extends KinematicBody2D

export var grain : float = 10
export var consumption_rate : float = 0.1 # grain per person per second
export var starve_chance : float = 0.01 # chance of starvation death per tick

onready var select_area = $SelectionArea
onready var level = get_node("/root/LevelManager").current_level
onready var hud_controller = level.hud_controller
onready var map_manager = level.map_manager
onready var army_manager = map_manager.army_manager

# temp hud elements
onready var food_label = $UI/VBoxContainer/FoodLabel
onready var pop_label = $UI/VBoxContainer/PopLabel
onready var starve_label = $UI/VBoxContainer/StarveLabel
onready var units_vbox = $UI/VBoxContainer/Units

# assigned on birth by army manager
var army_id : int

# dictionary of embedded units
var units = {}

# map movement

var velocity = 100 # sec
var target : Vector2 = global_position
var position_error = 5 # pixels from target

# hunger

var starving = false

func _ready():
	select_area.connect("input_event", self, "on_select_input_event")

func _physics_process(delta):
	if !map_manager.is_paused:
		move(delta)
		consume_grain(delta)
		if starving: starve(delta)

func move(delta):
	var facing = target - global_position
	# anti-jitter
	if facing.length_squared() < position_error * position_error: return
	var movement = facing.normalized() * velocity * delta
	move_and_collide(movement)

func consume_grain(delta):
	var amount = get_manpower() * consumption_rate * delta
	grain -= amount
	if grain <= 0: 
		grain = 0
		starving = true
		starve_label.visible = true
	else: 
		starve_label.visible = false
	food_label.text = "Food: " + String(int(grain))
	pop_label.text = "Men: " + String(get_manpower())

func starve(delta):
	if randf() <= starve_chance:
		var unit = units.values()[randi() % units.size()]
		unit.add_men(-1)

# creation deletion ==========

func remove_army() -> bool:
	
	if !units.empty() : return false
	
	army_manager.delist_army(self)
	queue_free() 
	return true

# input ==========

func on_select_input_event(viewport, event, shape_idx):
	if event.is_action_pressed("ui_lmb"):
		hud_controller.on_army_selected(self)

# selection ==========

# called by controller

func on_selected():
	$SelectionSprite.visible = true

func on_deselected():
	$SelectionSprite.visible = false

# movement ===========

func set_target(target):
	self.target = target
	print(name, " target set: ", self.target)

# unit management ==========

func get_manpower() -> int:
	var men = 0
	for unit in units.values():
		men += unit.manpower
	return men

func add_unit(unit):
	print("unit: ", unit, ", ", unit.unit_id, " added to army: ", name)
	units[unit.unit_id] = unit
	
	# reparent unit ui
	var ui = unit.unit_ui
	if ui.get_parent():
		ui.get_parent().remove_child(ui)
	units_vbox.add_child(ui)

func remove_unit(unit):
	units.erase(unit.unit_id)
	# remove unit_ui from army ui
	var ui = unit.unit_ui
	if ui.get_parent():
		ui.get_parent().remove_child(ui)
	print("unit removed: ", unit, " id: ", unit.unit_id)

func move_unit_to(unit, army):
	remove_unit(unit)
	army.add_unit(unit)

func split_unit(unit) -> Node2D:
	var army = army_manager.spawn_army(global_position + Vector2(100,0))
	move_unit_to(unit, army)
	return army

func split_army(leaving_units) -> Node2D: # takes array of units
	var army = army_manager.spawn_army(global_position + Vector2(100,0))
	for unit in leaving_units:
		move_unit_to(unit, army)
	return army

func join_army(army):
	for unit in units.values():
		move_unit_to(unit, army)
	remove_army()
	
