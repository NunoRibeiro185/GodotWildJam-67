extends Control

@onready var new_game_btn = $MarginContainer/VBoxContainer/NewGameBtn
@export_file("*.tscn") var gameScenePath

func _on_new_game_btn_pressed():
	get_tree().change_scene_to_file(gameScenePath)
	
func _on_load_btn_pressed():
	pass # Replace with function body.
	
func _on_options_btn_pressed():
	pass # Replace with function body.
	
func _on_quit_pressed():
	get_tree().quit()
