extends Node

var menu_open = false
@onready var pause_menu = $PauseMenu


# Called when the node enters the scene tree for the first time.
func _ready():
	pause_menu.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
