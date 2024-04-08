extends Node

var terminal1 = false
var terminal2 = false
var terminal3 = false
var bomb_terminal = false

var in_terminal1 = false
var in_terminal2 = false
var in_terminal3 = false
var in_bomb_terminal

@onready var interact_1 = $Terminal1/Interact1
@onready var interact_2 = $Terminal2/Interact2
@onready var interact_3 = $Terminal3/Interact3
@onready var interact_4 = $Terminal4/Interact4
@onready var map_texture = $CanvasLayer/Control/MapTexture

	
func _input(event):
	if in_terminal1 && !terminal1:
		if Input.is_action_just_pressed("interact"):
			terminal1 = true
			interact_1.visible = false
			map_texture.frame += 1
			print("Terminal 1: ", terminal1)
	elif in_terminal2 && !terminal2:
		if Input.is_action_just_pressed("interact"):
			terminal2 = true
			interact_2.visible = false
			map_texture.frame += 1
			print("Terminal 2: ", terminal2)
	elif in_terminal3 && !terminal3: 
		if Input.is_action_just_pressed("interact"):
			terminal3 = true
			interact_3.visible = false
			map_texture.frame += 1
			print("Terminal 3: ", terminal3)
	elif in_bomb_terminal && !bomb_terminal:
		if(terminal1 && terminal2 && terminal3):
			if Input.is_action_just_pressed("interact"):
				bomb_terminal = true
				interact_4.visible = false
				print("gg")

func _on_terminal_1_body_entered(body):
	if body.is_in_group("player"):
		in_terminal1 = true
		if !terminal1:
			interact_1.visible = true
		print("in_terminal1: ",in_terminal1)


func _on_terminal_2_body_entered(body):
	if body.is_in_group("player"):
		in_terminal2 = true
		if !terminal2:
			interact_2.visible = true
		print("in_terminal2: ",in_terminal2)

func _on_terminal_3_body_entered(body):
	if body.is_in_group("player"):	
		in_terminal3 = true
		if !terminal3:
			interact_3.visible = true
		print("in_terminal3: ",in_terminal3)


func _on_terminal_1_body_exited(body):
	if body.is_in_group("player"):	
		in_terminal1 = false
		interact_1.visible = false
		print("in_terminal1: ",in_terminal1)


func _on_terminal_2_body_exited(body):
	if body.is_in_group("player"):
		in_terminal2 = false
		interact_2.visible = false
		print("in_terminal2: ",in_terminal2)


func _on_terminal_3_body_exited(body):
	if body.is_in_group("player"):
		in_terminal3 = false
		interact_3.visible = false
		print("in_terminal3: ",in_terminal3)


func _on_terminal_4_body_entered(body):
	if body.is_in_group("player"):
		in_bomb_terminal = true
		if !bomb_terminal:
			interact_4.visible = true
		print("in_bomb_terminal: ",in_bomb_terminal)


func _on_terminal_4_body_exited(body):
	if body.is_in_group("player"):
		in_bomb_terminal = false
		interact_4.visible = false
		print("in_bomb_terminal: ",in_bomb_terminal)
