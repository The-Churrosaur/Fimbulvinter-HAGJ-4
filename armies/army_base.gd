class_name ArmyBase
extends KinematicBody2D

onready var select_area = $SelectionArea
onready var contact_area = $ContactArea
onready var detection_area = $DetectionArea

onready var level = get_node("/root/LevelManager").current_level
#onready var hud_controller = level.hud_controller
#onready var map_manager = level.map_manager
#onready var army_manager = map_manager.army_manager

onready var enemy = false
onready var faction = army_manager.FACTIONS.PLAYER

# temp hud elements
onready var ui = $UI
onready var food_label = $UI/VBoxContainer/FoodLabel
onready var pop_label = $UI/VBoxContainer/PopLabel
onready var starve_label = $UI/VBoxContainer/StarveLabel
onready var units_vbox = $UI/VBoxContainer/Units
onready var split_button = $UI/VBoxContainer/Units/SplitButton
onready var join_button = $UI/VBoxContainer/Units/JoinButton
onready var info_label = $UI/VBoxContainer/InfoLabel
onready var rout_ui = $UI/RoutUI

onready var nav_line = $NavLine

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
var target = global_position
var position_error = 5 # pixels from target

# hunger

var starving = false

# war

var engaged = false
var combat
var routing = false

func _ready():
	# might not actually be necessary
	call_deferred("after_ready")
	
	nav_line.add_point(nav_line.position)
	nav_line.add_point(nav_line.position)

func after_ready():
	select_area.connect("input_event", self, "on_select_input_event")
	split_button.connect("button_down", self, "on_split_button")
	join_button.connect("button_down", self ,"on_join_button")
	
	map_manager.connect("pause", self, "on_pause")
	map_manager.connect("play", self, "on_play")
	
	contact_area.connect("area_entered", self, "on_contact_area")

func _physics_process(delta):
	if map_manager != null and !map_manager.is_paused:

		food_label.text = "Food: " + String(int(get_total_food()))
		pop_label.text = "Men: " + String(get_manpower())
		check_starving()

		# not in combat:
		if !engaged:
			velocity = get_speed()
			move(delta)
			distribute_wagons()
		
		# in combat
		else:
			deal_damage(delta)
		
		handle_routing()

func get_speed() -> float:
	return 50 * 100 / max(get_manpower(), 30)

func move(delta):
	
	if target == null : return
	
	var facing = target - global_position
	# anti-jitter
	if facing.length_squared() < position_error * position_error: 
		target = null
		reached_target()
		return
	var movement = facing.normalized() * velocity * delta
	move_and_collide(movement)
	
	nav_line.set_point_position(1, nav_line.to_local(target))

func reached_target():
#	print(self, "reached target")
	if routing:
		panic_move()

func panic_move():
	set_target(global_position + Vector2(100,0).rotated(rand_range(0, 2*PI)))

# global
func move_away(pos):
	var away = global_position - pos
	set_target(global_position + away)

func check_starving():
	for unit in units.values():
		if unit.starving: 
			starve_label.visible = true
			return
	starve_label.visible = false

# creation deletion ==========

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
	nav_line.set_point_position(1, nav_line.to_local(target))
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

func get_routing() -> bool:
	for unit in units.values():
		if unit.routing: return true
	return false

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

	# if no units, break contact, disband army
	
	if units.size() <= 0: 
		print("disbanding army: ", name)
		if engaged: army_manager.leave_combat(self, combat)
		army_manager.remove_army(self)

func move_unit_to(unit, army):
	remove_unit(unit)
	army.add_unit(unit)

func split_unit(unit) -> Node2D:
	
	# fails to split no unit
	if unit == null: return self
	
	var army
	if enemy == true: 
		army = army_manager.spawn_enemy_army(global_position + Vector2(100,0))
	else:
		army = army_manager.spawn_player_army(global_position + Vector2(100,0))
	
	move_unit_to(unit, army)
	return army

func split_army(leaving_units) -> Node2D: # takes array of units
	
	# fails to split whole army
	if leaving_units.size() >= units.size(): return self
	# fails to split no units
	if leaving_units.size() == 0: return self
	
	var army
	if enemy == true: 
		army = army_manager.spawn_enemy_army(global_position + Vector2(100,0))
	else:
		army = army_manager.spawn_player_army(global_position + Vector2(100,0))
	
	for unit in leaving_units:
		move_unit_to(unit, army)
	return army

func join_army(army):
	for unit in units.values():
		move_unit_to(unit, army)
	army_manager.remove_army(self)

# food management ==========

func distribute_wagons():

	# todo ew
	var wagons = []
	for unit in units.values():
		if unit.is_in_group("Wagon") && unit.sharing_enabled:
			wagons.append(unit)
	
	if wagons.size() <= 0 : return
	
	for unit in units.values():
		if !unit.is_in_group("Wagon"):
			var rand_wagon = wagons[randi() % wagons.size()]
			rand_wagon.resupply(unit)

# returns leftover
func distribute_food(food) -> int:
	for unit in units.values():
		food = unit.set_food(unit.food + food)
	return food

# contact and combat ==========

# calls manager
func on_contact_area(area):
	if area.is_in_group("ArmyArea"):
		print("contact area hit: ", area, contact_area)
		var army = area.army
		if !engaged and army.faction != faction:
			print("combat starting")
			army_manager.start_combat(self, army)

#todo
func on_contact_area_exited(area):
	if area.is_in_group("ArmyArea") and engaged == true:
		for army in combat.belligerents:
			if area.army == army:
				pass

# called by manager
func start_combat(combat):
	info_label.text = "Engaged in combat"
	self.combat = combat
	engaged = true

func end_combat(combat):
	self.combat = null
	engaged = false
	print("ending combat: ", self)
	info_label.text = " "

# fight
func deal_damage(delta):

	if engaged == false or combat == null: return

	# get enemy units
	var enemy_units = []
	for army in combat.belligerents:
		if army != null && army.faction != faction:
			for unit in army.units.values():
				enemy_units.append(unit)
	
	if enemy_units.size() <= 0: return

	# each unit damages a random enemy unnit
	for unit in units.values():
		var rand_enemy = enemy_units[randi() % enemy_units.size()]
		rand_enemy.deal_damage(unit.get_dps() * delta)
		if !engaged : return 

func handle_routing():
	routing = get_routing()
	if routing: 
		rout_ui.visible = true
	else:
		rout_ui.visible = false

# detection ==========


