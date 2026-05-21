extends Area2D

@export var dano: int = 5

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(dano) # Esta linha precisa de um TAB (identação)
