class_name MapManager
extends Node2D

onready var army_manager = $ArmyManager

# Map pause/play

var is_paused = true
signal pause()
signal play()

# Map pause/play

func map_pause():
	is_paused = true
	emit_signal("pause")
	print("map is pausing")

func map_play():
	is_paused = false
	emit_signal("play")
	print("map is playing")

func map_toggle_pause():
	if is_paused == true:
		map_play()
	else:
		map_pause()
