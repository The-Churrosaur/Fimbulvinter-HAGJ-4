class_name Pickup
extends Area2D

func _ready():
	connect("body_entered", self, "on_body_entered")

func on_body_entered(body):
	if body.is_in_group("Army"):
		pick_up(body)

func pick_up(army):
	army.distribute_food(100)
	queue_free()
