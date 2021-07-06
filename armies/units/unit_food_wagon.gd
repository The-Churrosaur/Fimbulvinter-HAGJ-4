class_name UnitFoodWagon
extends UnitBase

var sharing_enabled = true

func resupply(unit):
#	print("wagon resupplying: ", name, unit.name)
	var leftover = unit.set_food(unit.food + food)
	set_food(leftover)
