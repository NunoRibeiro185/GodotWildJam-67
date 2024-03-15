extends Node3D

var ammo = 3
var chamber_size = 100
var in_the_chamber = 100

@export var bullet : PackedScene
@onready var gun_barrel = $RayCast3D

func shoot():
	if in_the_chamber > 0:
		print("FIRE")
		in_the_chamber -= 1
		var b = bullet.instantiate()
		b.position = gun_barrel.global_position
		b.transform.basis = gun_barrel.global_transform.basis
		get_tree().current_scene.add_child(b)

func reload():
	pass
