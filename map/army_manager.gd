class_name ArmyManager
extends Node

export var army_template : PackedScene = preload("res://armies/army_base.tscn")
export var unit_template : PackedScene = preload("res://armies/unit_base.tscn")

export var army_spawn_path : NodePath = "../../" # path of parent

onready var spawn_parent = get_node(army_spawn_path)

# keeps track of all armies and units for global effects and save/load

var army_counter = 0 # also for guid's, TODO set on load
var armies = {}

# keeps track of but does not directly manage units
var unit_counter = 0 # same
var units = {}

# army management ==========

func spawn_army(pos):
	var army = army_template.instance()
	spawn_parent.add_child(army)
	army.global_position = pos
	
	# set id
	army.army_id = army_counter
	army_counter += 1
	
	# add to dict
	armies[army.army_id] = army
	
	return army

func remove_army(army):
	army.remove_army()

# only call if you're sure, preferred call delete on army
func delist_army(army):
	if armies.has(army.army_id):
		print("removing army: ", army.name, " id: ", army.army_id)
		armies.erase(army.army_id)
	else:
		print("army manager: army: ", army.name, " id: ", army.army_id)
		print("could not be deleted")

# unit management ==========

func spawn_unit(pop, unit_name):
	var unit = unit_template.instance()
	spawn_parent.add_child(unit)
	
	unit.unit_id = unit_counter
	unit_counter += 1
	units[unit.unit_id] = unit
	
	unit.manpower = pop
	unit.name = unit_name
	
	return unit

# just in case
func add_unit_to_army(unit_id, army_id):
	var army = armies[army_id]
	var unit = units[unit_id]
	army.add_unit(unit)

