extends RigidBody2D

@export var speed = 500
@export var damage = 5
var direction : Vector2
var is_rolling = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if is_rolling and body.is_in_group("inimigo"):
		body.take_damage(damage)
		
func roll():
	is_rolling = true
	linear_velocity = direction * speed
	$Timer.start(2)	
		
	


func _on_timer_timeout() -> void:
	queue_free()
