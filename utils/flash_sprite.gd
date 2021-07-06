extends Sprite

export var duration = 0.5

func _ready():
	while true:
		yield(get_tree().create_timer(duration),"timeout")
		if visible : visible = false
		else: visible = true
