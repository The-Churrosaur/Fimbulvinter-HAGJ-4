class_name ArmyBase
extends KinematicBody2D

onready var select_area = $SelectionArea
onready var level = get_node("/root/LevelManager").current_level
#onready var hud_controller = level.hud_controller
#onready var map_manager = level.map_manager
#onready var army_manager = map_manager.army_manager

# temp hud elements
onready var ui = $UI
onready var food_label = $UI/VBoxContainer/FoodLabel
onready var pop_label = $UI/VBoxContainer/PopLabel
onready var starve_label = $UI/VBoxContainer/StarveLabel
onready var units_vbox = $UI/VBoxContainer/Units
onready var split_button = $UI/VBoxContainer/Units/SplitButton
onready var join_button = $UI/VBoxContainer/Units/JoinButton

# assigned on birth by army manager
var army_id : int

# also assigned by army manager on load
var hud_controller
var map_manager
var army_manager

# dictionary of embedded units
var units = {}

# map movement

var velocity = 100 # sec
var target : Vector2 = global_position
var position_error = 5 # pixels from target

# hunger

var starving = false

func _ready():
	# might not actually be necessary
	call_deferred("after_ready")

func after_ready():
	select_area.connect("input_event", self, "on_select_input_event")
	split_button.connect("button_down", self, "on_split_button")
	join_button.connect("button_down", self ,"on_join_button")
	
	map_manager.connect("pause", self, "on_pause")
	map_manager.connect("play", self, "on_play")

func _physics_process(delta):
	if map_manager != null and !map_manager.is_paused:
		move(delta)
		food_label.text = "Food: " + String(int(get_total_food()))
		pop_label.text = "Men: " + String(get_manpower())
		check_starving()

func move(delta):
	var facing = target - global_position
	# anti-jitter
	if facing.length_squared() < position_error * position_error: return
	var movement = facing.normalized() * velocity * delta
	move_and_collide(movement)

func check_starving():
	for unit in units.values():
		if unit.starving: 
			starve_label.visible = true
			return
	starve_label.visible = false

# creation deletion ==========

func remove_army() -> bool:
	
	if !units.empty() : return false
	
	army_manager.delist_army(self)
	queue_free() 
	return true

# map pause ==========

func on_pause():
	pass

func on_play():
	pass

# ui / input ==========

func on_select_input_event(viewport, event, shape_idx):
	if event.is_action_pressed("ui_lmb"):
		hud_controller.on_army_selected(self)

func on_split_button():
	var leaving_units = []
	for unit in units.values():
		if unit.selected == true:
			leaving_units.append(unit)
	deselect_units()
	split_army(leaving_units)

func on_join_button():
	
	# yield until next selection
	var army = yield(hud_controller, "army_selected")
	
	join_army(army)

# unit selection

func deselect_units():
	for unit in units.values():
		unit.deselect()

# selection ==========

# called by controller

func on_selected():
	$SelectionSprite.visible = true
	units_vbox.visible = true
	deselect_units()

func on_deselected():
	$SelectionSprite.visible = false
	units_vbox.visible = false
	deselect_units()

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

func get_total_food() -> int:
	var food = 0
	for unit in units.values():
		food += unit.food
	return food

func add_unit(unit):
	print("unit: ", unit, ", ", unit.unit_id, " added to army: ", name)
	units[unit.unit_id] = unit
	
	# reparent unit ui
	var ui = unit.unit_ui
	if ui.get_parent():
		ui.get_parent().remove_child(ui)
	units_vbox.add_child(ui)
	
	unit.army = self

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
	
	# fails to split no unit
	if unit == null: return self
	
	var army = army_manager.spawn_army(global_position + Vector2(100,0))
	move_unit_to(unit, army)
	return army

func split_army(leaving_units) -> Node2D: # takes array of units
	
	# fails to split whole army
	if leaving_units.size() >= units.size(): return self
	# fails to split no units
	if leaving_units.size() == 0: return self
	
	var army = army_manager.spawn_army(global_position + Vector2(100,0))
	for unit in leaving_units:
		move_unit_to(unit, army)
	return army

func join_army(army):
	for unit in units.values():
		move_unit_to(unit, army)
	remove_army()
	
