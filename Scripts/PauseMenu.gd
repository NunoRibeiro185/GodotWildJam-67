extends Control

func _input(event):
	if event.is_action_pressed("escape"):
		if not self.is_visible_in_tree():
			# Pause the game when the pause menu is not visible
			self.show()
			get_tree().paused = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			# Unpause the game when the pause menu is already visible
			get_tree().paused = false
			self.hide()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_quit_pressed():
	get_tree().quit()
