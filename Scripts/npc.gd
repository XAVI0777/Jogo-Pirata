extends Node2D

@export var item_const = 10
@export var item_name = "Espada"

var player: CharacterBody2D = null

func _ready():
	$Label.visible = false
	$TextureButton.visible = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		$Label.text = "%s: %d Moedas" % [item_name, item_const]
		$Label.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = null
		$TextureButton.visible = false
		$Label.visible = false

func _process(delta):
	if player and Input.is_action_just_pressed("interacao"):
		$TextureButton.visible = true

func _on_texture_button_pressed() -> void:
	if player and player.contador_de_moeda >= item_const:
		player.contador_de_moeda -= item_const
		player.get_sword()
		$TextureButton.visible = false
		$Label.text = "Comprado!"
	else:
		$TextureButton.visible = false
		$Label.text = "Moedas insuficientes"
		
		
