extends CharacterBody2D

# --- Configurações ---
@export var speed = 300.0
@export var jump_velocity = -400.0
@export var vida_max = 10
@export var dano_ataque = 2

# --- Nós ---
@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var collision_ataque: CollisionShape2D = $AttackArea/Collision
@onready var barra_de_vida: ProgressBar = $ProgressBar
@onready var invul_timer: Timer = $InvulTimer
@onready var collision_principal: CollisionShape2D = $CollisionShape2D
@onready var hud: Label = $"../Hud/Moeda"

# --- Estado ---
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var vida = vida_max
var atacando = false
var levando_hit = false
var is_dead = false
var contador_de_moeda: int = 0

# Impede dano repetido no mesmo ataque
var inimigos_atingidos := []

var attack_offset: float


func _ready():
	add_to_group("player")

	barra_de_vida.max_value = vida_max
	barra_de_vida.value = vida

	hud.text = "Moedas: 0"

	attack_offset = abs(collision_ataque.position.x)

	if attack_offset == 0:
		attack_offset = abs(attack_area.position.x)

	collision_ataque.position.x = attack_offset
	attack_area.position.x = 0

	collision_ataque.disabled = true

	if not invul_timer.timeout.is_connected(_on_invul_timer_timeout):
		invul_timer.timeout.connect(_on_invul_timer_timeout)


func _physics_process(delta):
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	if atacando:
		velocity.x = move_toward(velocity.x, 0, speed)
	else:
		var direction = Input.get_axis("esquerda", "direita")
		var current_speed = speed

		if levando_hit:
			current_speed *= 0.5

		velocity.x = direction * current_speed

		if direction != 0:
			sprite.flip_h = direction < 0
			collision_ataque.position.x = attack_offset * direction

		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = jump_velocity

		if Input.is_action_just_pressed("ataque"):
			atacar()

	atualizar_animacoes()
	move_and_slide()


func atacar():
	if atacando or is_dead:
		return

	atacando = true
	inimigos_atingidos.clear()

	animation.play("attack")

	collision_ataque.set_deferred("disabled", false)

	await get_tree().physics_frame
	await get_tree().physics_frame

	aplicar_dano_ataque()

	collision_ataque.set_deferred("disabled", true)

	await animation.animation_finished

	atacando = false


func aplicar_dano_ataque():
	var alvos := []

	for corpo in attack_area.get_overlapping_bodies():
		alvos.append(corpo)

	for area in attack_area.get_overlapping_areas():
		alvos.append(area)

	for alvo in alvos:
		if alvo == self:
			continue

		var alvo_real = encontrar_alvo_com_dano(alvo)

		if alvo_real == null:
			continue

		if alvo_real in inimigos_atingidos:
			continue

		if alvo_real.is_in_group("inimigo") or alvo_real.is_in_group("bau"):
			inimigos_atingidos.append(alvo_real)

			if alvo_real.has_method("take_damage"):
				alvo_real.take_damage(dano_ataque)
				print("ACERTOU:", alvo_real.name)


func encontrar_alvo_com_dano(no: Node) -> Node:
	if no.has_method("take_damage"):
		return no

	if no.get_parent() and no.get_parent().has_method("take_damage"):
		return no.get_parent()

	if no.owner and no.owner.has_method("take_damage"):
		return no.owner

	return null


func atualizar_animacoes():
	if is_dead:
		return

	if levando_hit:
		if animation.current_animation != "hit":
			animation.play("hit")
		return

	if atacando:
		if animation.current_animation != "attack":
			animation.play("attack")
		return

	if not is_on_floor():
		animation.play("jump" if velocity.y < 0 else "fall")
	elif velocity.x != 0:
		animation.play("run")
	else:
		animation.play("idle")


func take_damage(amount: int):
	if is_dead or invul_timer.time_left > 0:
		return

	vida -= amount
	barra_de_vida.value = vida

	if vida <= 0:
		die()
	else:
		levando_hit = true
		invul_timer.start(0.5)

		var knockback_dir = 1 if sprite.flip_h else -1

		velocity.x = knockback_dir * 250
		velocity.y = -150


func _on_invul_timer_timeout():
	levando_hit = false


func die():
	is_dead = true
	velocity = Vector2.ZERO

	collision_principal.set_deferred("disabled", true)

	animation.play("death")

	await get_tree().create_timer(2.0).timeout

	get_tree().reload_current_scene()


func coletaMoeda():
	contador_de_moeda += 1
	hud.text = "Moedas: " + str(contador_de_moeda)
