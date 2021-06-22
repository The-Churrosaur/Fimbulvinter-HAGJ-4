class_name UnitBase
extends Node2D

export var manpower = 50

# unit ui ==========

# unit ui exists to be plucked and replaced by armies, tooltips
onready var unit_ui = $UnitInfo
onready var unit_label = $UnitInfo/Button

var unit_id = 0

# triggered by ui, flag is read by army
var selected = false

signal manpower_changed(new_manpower)

func _ready():
	# at end of tick update label with manager-assigned name
	call_deferred("update_label")
	
	# connect press button to unit selection
	unit_label.connect("button_down", self, "on_pressed")

func add_men(men):
	manpower += men
	if manpower <= 0:
		manpower = 0
	emit_signal("manpower_changed", manpower)
	update_label()

# ui and selection ==========

func on_pressed():
	if selected: deselect()
	else: select()

func select():
	unit_label.flat = true
	selected = true

func deselect():
	unit_label.flat = false
	selected = false

func update_label():
	unit_label.text = name + ": " + String(manpower) + " men"
