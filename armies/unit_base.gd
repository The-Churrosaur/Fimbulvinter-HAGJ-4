class_name UnitBase
extends Node2D

export var manpower = 50

export var max_food = 100
export var starting_food = 50
export var consumption_rate : float = 0.1 # food per man per second
export var starve_chance : float = 0.001 # chance of death per man per second 

export var man_hp : float = 10 # damage needed to kill a soldier
export var man_dps : float = 1 # damage output by each soldier # sec

export var morale_stat : float = 10 # unit routs at zero
export var morale_death_shock : float = 5
export var morale_regen : float = 1 # seconds
export var morale_regen_starve : float = 0.5
export var morale_rout_chance : float = 0.25 # chance of rout when morale < 0

# unit ui ==========

# unit ui exists to be plucked and replaced by armies, tooltips
onready var unit_ui = $UnitInfo
onready var unit_label = $UnitInfo/Button

# injected by army manager on load

var map_manager
var army_manager
var hud_controller

var unit_id = 0

# set by army on add
var army

# triggered by ui, flag is read by army
var selected = false

# food

onready var food = starting_food
onready var starving = false

# morale

var morale = morale_stat
var routing = false

# war

var current_damage : float = 0

signal manpower_changed(new_manpower)

func _ready():
	# at end of tick update label with manager-assigned name
	call_deferred("update_label")
	
	# connect press button to unit selection
	unit_label.connect("button_down", self, "on_pressed")

func _physics_process(delta):
	if map_manager != null and !map_manager.is_paused:
		consume_food(delta)
		if starving : starve(delta)
		morale_regen(delta)

# manpower ==========

func set_manpower(men):
	
	# deaths
	if men < manpower:
		on_deaths(manpower - men)
	
	manpower = men
	
	if manpower <= 0:
		manpower = 0
		unit_depleted()
		
	emit_signal("manpower_changed", manpower)
	update_label()

func on_deaths(deaths):
	death_morale(deaths)

func unit_depleted():
	# temp
	print("unit is depleted, deleting: ", self, self.name)
	army.remove_unit(self)
	army_manager.delete_unit(self)

# food ==========

func consume_food(delta):
	var amount = consumption_rate * manpower * delta
	set_food(food - amount)

func set_food(amount) -> int: # returns leftovers from max
	
	var leftover = 0
	
	if amount > max_food:
		food = max_food
		leftover = amount - max_food
	elif amount < 0:
		food = 0
		leftover = 0
		starving = true
	else:
		food = amount
		leftover = 0
	
	return leftover

func starve(delta):
	var chance = manpower * starve_chance * delta
	if randf() <= chance:
		set_manpower(manpower - 1)

# combat ==========

func deal_damage(damage):
	# deaths
	var deaths = int(damage / man_hp)
	set_manpower(manpower - deaths)
	# add remainder
	current_damage += damage / man_hp - deaths
	# change
	if current_damage >= man_hp:
		current_damage = current_damage - man_hp
		set_manpower(manpower - 1)

func get_dps() -> float:
	return man_dps * manpower

# morale ==========

func set_morale(value):
	morale = value
	# set routing
	if morale <= 0 && routing == false: 
		# chance of rout each hit below morale
		if randf() < morale_rout_chance:
			routing = true
			on_rout()
	# cap
	elif morale > morale_stat:
		morale = morale_stat
	
	update_label()

# deaths decrease morale
func death_morale(dead):
	set_morale(morale - dead * morale_death_shock)

func morale_regen(delta):
	var change
	if !starving: change = morale_regen * delta
	else: change = morale_regen_starve * delta
	set_morale(morale + change)

func on_rout():
	print("unit: ", name, " id: ", unit_id, " is routing!")
	var new_army = army.split_unit(self)

	# flee randomly
	new_army.set_target(new_army.global_position + Vector2(100,0).rotated(randf()))

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
	var string = name + ": " + String(manpower) + " men"
	string += " morale: " + String(int(morale))
	string += " food: " + String(int(food))
	unit_label.text = string
