class_name ArmyManager
extends Node

enum FACTIONS {PLAYER, ENEMY1, ENEMY2}
signal unit_deleted(unit)

export var army_template : PackedScene = preload("res://armies/army_base.tscn")
export var unit_template : PackedScene = preload("res://armies/unit_base.tscn")
export var enemy_army_template : PackedScene = preload("res://armies/army_enemy.tscn")
export var army_spawn_path : NodePath = "../../" # path of parent
export var hud_controller_path : NodePath = "../../HudController"
export var map_manager_path : NodePath = "../"

onready var spawn_parent = get_node(army_spawn_path)
onready var hud_controller = get_node(hud_controller_path)
onready var map_manager = get_node(map_manager_path)

# TODO - dependency injection of map nodes to stuff from here

# keeps track of all armies and units for global effects and save/load

var army_counter = 0 # also for guid's, TODO set on load
var armies = {}

# keeps track of but does not directly manage units
var unit_counter = 0 # same
var units = {}

# keeps track of and manages combats
# combats are organized as an array of combat objects
var combats = []

# army management ==========

func spawn_player_army(pos):
	return setup_army(army_template.instance(), pos)

func spawn_enemy_army(pos):
	return setup_army(enemy_army_template.instance(), pos)

func setup_army(army, pos):
	
	# set id
	army.army_id = army_counter
	army_counter += 1
	
	# dependency injection
	army.hud_controller = hud_controller
	army.map_manager = map_manager
	army.army_manager = self
	
	# add to dict
	armies[army.army_id] = army
	
	spawn_parent.add_child(army)
	army.global_position = pos
	army.set_target(army.global_position)
	
	return army

func remove_army(army):

	if army.units.size() > 0: return false
	if army.engaged : leave_combat(army, army.combat)

	if armies.has(army.army_id):
		print("removing army: ", army, " id: ", army.army_id)
		armies.erase(army.army_id)
	else:
		print("army manager: army: ", army.name, " id: ", army.army_id)
		print("could not be deleted")
		return false
	
	army.queue_free()
	return true

# unit management ==========
func spawn_unit(unit_manpower, unit_name, path = null):
	
	var unit
	if path != null:
		unit = load(path).instance()
	else:
		unit = unit_template.instance()
	
	unit.unit_id = unit_counter
	unit_counter += 1
	units[unit.unit_id] = unit
	
	unit.manpower = unit_manpower
	unit.name = unit_name
	
	# dependency injection
	unit.hud_controller = hud_controller
	unit.map_manager = map_manager
	unit.army_manager = self
	
	spawn_parent.add_child(unit)
	
	return unit

# just in case
func add_unit_to_army(unit_id, army_id):
	var army = armies[army_id]
	var unit = units[unit_id]
	army.add_unit(unit)

func delete_unit(unit):
	emit_signal("unit_deleted", unit)
	units.erase(unit)
	if unit.get_parent():
		unit.get_parent().remove_child(unit)

# combat supervisor ==========

func start_combat(army1, army2):

	if army1.engaged:
		enter_combat(army2, army1.combat)
	elif army2.engaged:
		enter_combat(army1, army2.combat)
	else:
		var combat = Combat.new()
		combats.append(combat)
		combat.belligerents.append(army1)
		combat.belligerents.append(army2)
		print("new combat: ", combat.belligerents)

		army1.start_combat(combat)
		army2.start_combat(combat)

func enter_combat(army, combat):
	combat.belligerents.append(army)
	army.start_combat(combat)
	print("army entered combat: ", combat.belligerents)

# disengages given army
func leave_combat(army, combat):
	print("leaving combat: ", army)
	combat.belligerents.erase(army)
	army.end_combat(combat)
	
	if !combat_valid(combat):
		end_combat(combat)

	# check if combat is still valid
func combat_valid(combat) -> bool:
	var faction = null
	for army in combat.belligerents:
		if faction != null and faction != army.faction: 
			print("combat valid: ", combat.belligerents)
			return true
		faction = army.faction
	
	# fallthrough
	print("combat invalid: ", combat.belligerents)
	return false

# ends combat
func end_combat(combat):
	
	print("manager ending combat: ", combat.belligerents)
	
	# to avoid mid-loop deletion
	var armies = combat.belligerents.duplicate()
	for army in armies:
		print(army)
		leave_combat(army, combat)
		
	combats.erase(combat)

