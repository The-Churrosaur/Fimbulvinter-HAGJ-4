class_name HudController
extends Control

export var map_manager_path : NodePath

onready var map_manager = get_node(map_manager_path)
onready var army_manager = map_manager.army_manager

# hud elements

onready var paused_label = $HUD/MarginContainer/VBoxContainer/CenterContainer/PausedLabel

var selected_army : Node2D

func _ready():
	map_manager.connect("pause", self, "on_pause")
	map_manager.connect("play", self, "on_play")

func _input(event):
	
	# pause/play
	if event.is_action_pressed("ui_accept"):
		map_manager.map_toggle_pause()
	
	# move order
	if event.is_action_pressed("ui_rmb"):
		if selected_army != null:
			selected_army.set_target(get_global_mouse_position())

func on_army_selected(army):
	print("controller: ", army.name, " selected")
	
	# deselect
	if selected_army != null: selected_army.on_deselected()
	
	# select
	selected_army = army
	army.on_selected()

func on_pause():
	paused_label.visible = true

func on_play():
	paused_label.visible = false
