extends Node2D

onready var level_manager = get_node("/root/LevelManager")
onready var hud_controller = $HudController
onready var map_manager = $MapManager
onready var army_manager = $MapManager/ArmyManager

func _ready():
	level_manager.current_level = self
	# TODO - this is not earlier than some calls to get level
	
	# test
	army_manager.spawn_army(Vector2(100,100))
	army_manager.spawn_army(Vector2(200,200))
