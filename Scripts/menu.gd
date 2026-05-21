extends Label

func _on_escolher_fase_pressed() -> void:
	pass

func _on_iniciar_pressed() -> void:
	get_tree().change_scene_to_file("res://Cenas/fase.tscn")

func _on_sair_pressed() -> void:
	get_tree().quit()
