class_name UnitBase
extends Node2D

export var manpower = 50
export var max_food = 100
export var consumption_rate : float = 0.1 # food per man per second
export var starve_chance : float = 0.001 # chance of death per man per second 

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

func _physics_process(delta):
	if !map_manager.is_paused:
		move(delta)
		consume_grain(delta)
		if starving: starve(delta)

func move(delta):
	var facing = target - global_position
	# anti-jitter
	if facing.length_squared() < position_error * position_error: return
	var movement = facing.normalized() * velocity * delta
	move_and_collide(movement)

func consume_grain(delta):
	var amount = get_manpower() * consumption_rate * delta
	grain -= amount
	if grain <= 0: 
		grain = 0
		starving = true
		starve_label.visible = true
	else: 
		starve_label.visible = false
	food_label.text = "Food: " + String(int(grain))
	pop_label.text = "Men: " + String(get_manpower())

func starve(delta):
	if randf() <= starve_chance:
		var unit = units.values()[randi() % units.size()]
		unit.add_men(-1)

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
