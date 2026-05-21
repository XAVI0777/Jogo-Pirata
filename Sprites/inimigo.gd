extends CharacterBody2D

const SPEED = 120.0
const DANO_INIMIGO = 3

@onready var animation: AnimationPlayer = $Animation
@onready var ray: RayCast2D = $Ray
@onready var attack_area: Area2D = $AttackArea
@onready var barra_de_vida: ProgressBar = $ProgressBar

@export var direction := -1

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var player_na_area = false
var atacando = false
var is_dead = false
var levando_hit = false
var vida = 10

var hit_id := 0


func _ready():
	add_to_group("inimigo")

	barra_de_vida.max_value = vida
	barra_de_vida.value = vida

	if not animation.animation_finished.is_connected(_on_animation_animation_finished):
		animation.animation_finished.connect(_on_animation_animation_finished)


func _physics_process(delta):
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	if levando_hit or atacando:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	else:
		if ray.is_colliding():
			direction *= -1
			ray.target_position.x *= -1
			$Sprite2D.flip_h = direction > 0

		velocity.x = direction * SPEED

		if animation.current_animation != "run":
			animation.play("run")

	move_and_slide()


func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_dead:
		player_na_area = true
		tentar_atacar()


func _on_attack_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_na_area = false


func tentar_atacar():
	if is_dead:
		return

	if levando_hit:
		return

	if atacando:
		return

	if not player_na_area:
		return

	atacando = true
	animation.play("attack")

	await get_tree().create_timer(0.4).timeout

	if player_na_area and not is_dead and not levando_hit:
		var corpos = attack_area.get_overlapping_bodies()

		for corpo in corpos:
			if corpo.is_in_group("player") and corpo.has_method("take_damage"):
				corpo.take_damage(DANO_INIMIGO)

	await get_tree().create_timer(0.4).timeout

	atacando = false

	if player_na_area and not is_dead and not levando_hit:
		tentar_atacar()


func take_damage(amount: int):
	if is_dead:
		return

	vida -= amount
	barra_de_vida.value = vida

	if vida <= 0:
		die()
		return

	hit_id += 1
	var meu_hit = hit_id

	levando_hit = true
	atacando = false
	velocity.x = 0

	animation.play("hit")

	# Segurança: mesmo se animation_finished falhar ou a animação estiver em loop,
	# o inimigo sai do estado de hit.
	await get_tree().create_timer(0.35).timeout

	if meu_hit == hit_id and not is_dead:
		levando_hit = false

		if player_na_area:
			tentar_atacar()


func die():
	if is_dead:
		return

	is_dead = true
	levando_hit = false
	atacando = false
	player_na_area = false

	velocity = Vector2.ZERO

	$CollisionShape2D.set_deferred("disabled", true)
	attack_area.set_deferred("monitoring", false)

	animation.play("death")

	await get_tree().create_timer(2.0).timeout

	if is_inside_tree():
		queue_free()


func _on_animation_animation_finished(anim_name: StringName) -> void:
	if anim_name == "death":
		queue_free()

	elif anim_name == "hit":
		levando_hit = false

		if player_na_area and not is_dead:
			tentar_atacar()
