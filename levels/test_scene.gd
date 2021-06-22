extends Node2D

onready var level_manager = get_node("/root/LevelManager")
onready var hud_controller = $HudController
onready var map_manager = $MapManager
onready var army_manager = $MapManager/ArmyManager

func _ready():
	level_manager.current_level = self
	# TODO - this is not earlier than some calls to get level
	
	# test
	var army1 = army_manager.spawn_army(Vector2(100,100))
	var army2 = army_manager.spawn_army(Vector2(200,200))
	
	var unit1 = army_manager.spawn_unit(50, "Huscarls")
	var unit2 = army_manager.spawn_unit(100, "Peasants")
	var unit3 = army_manager.spawn_unit(60, "Archers")
	var unit4 = army_manager.spawn_unit(70, "Levy")
	
	army1.add_unit(unit1)
	army2.add_unit(unit2)
	army2.add_unit(unit3)
	army2.add_unit(unit4)


