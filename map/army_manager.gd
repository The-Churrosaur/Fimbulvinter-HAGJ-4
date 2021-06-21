class_name ArmyManager
extends Node

export var army_template : PackedScene = preload("res://armies/army_base.tscn")

export var army_spawn_path : NodePath = "../../" # path of parent

var army_counter = 0 # also for guid's, TODO set on load

func spawn_army(pos):
	var army = army_template.instance()
	var parent = get_node(army_spawn_path)
	parent.add_child(army)
	army.global_position = pos
	
	# set id
	army.army_id = army_counter
	army_counter += 1
