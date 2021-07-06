extends Pickup

export var food = 100

onready var label = $CenterContainer/Label
onready var particles = $Particles

func _ready():
	call_deferred("update_label")

func pick_up(army):
	food = army.distribute_food(food)
	update_label()
	particles.emitting = true

func update_label():
	label.text = "Food: " + String(int(food))
