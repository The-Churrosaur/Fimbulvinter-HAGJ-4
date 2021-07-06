extends Node2D

onready var level_manager = get_node("/root/LevelManager")
onready var hud_controller = $HudController
onready var map_manager = $MapManager
onready var army_manager = $MapManager/ArmyManager

func _ready():
	level_manager.current_level = self
	# TODO - this is not earlier than some calls to get level
	
	# test
	var army1 = army_manager.spawn_player_army(Vector2(100,100))
	var army2 = army_manager.spawn_player_army(Vector2(200,200))
	
	var unit1 = army_manager.spawn_unit(50, "Huscarls")
	var unit2 = army_manager.spawn_unit(100, "Peasants")
	var unit3 = army_manager.spawn_unit(60, "Archers")
	var unit4 = army_manager.spawn_unit(70, "Levy")
	
	army1.add_unit(unit1)
	army2.add_unit(unit2)
	army2.add_unit(unit3)
	army2.add_unit(unit4)
	
	# enemies
	var enemy1 = army_manager.spawn_enemy_army(Vector2(400,400))
	var eunit4 = army_manager.spawn_unit(30, "Levy")
	enemy1.add_unit(eunit4)
	
	# wagons
	var wagon = army_manager.spawn_unit(10, "Wagons", "res://armies/units/unit_food_wagon.tscn")
	army2.add_unit(wagon)
	
	# test damage
#	unit2.deal_damage(540.3)
#	print("unit 2 remaining damage: ", unit2.current_damage)
	
	
