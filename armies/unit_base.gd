class_name UnitBase
extends Node2D

export var manpower = 50

# unit ui exists to be plucked and replaced by armies, tooltips
onready var unit_ui = $UnitInfo
onready var unit_label = $UnitInfo/Label

var unit_id = 0

signal manpower_changed(new_manpower)

func _ready():
	# at end of tick update label with manager-assigned name
	call_deferred("update_label")

func add_men(men):
	manpower += men
	if manpower <= 0:
		manpower = 0
	emit_signal("manpower_changed", manpower)
	update_label()

func update_label():
	unit_label.text = name + ": " + String(manpower) + " men"
