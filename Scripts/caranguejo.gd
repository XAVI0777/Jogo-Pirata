extends CharacterBody2D

const SPEED = 120.0 
const DANO_INIMIGO = 3

@onready var animation: AnimationPlayer = $Animation
@onready var ray: RayCast2D = $Ray
@onready var attack_area: Area2D = $AttackArea 
@onready var sprite: Sprite2D = $Sprite2D
@onready var barra_de_vida = get_node_or_null("ProgressBar")

@export var direction := -1
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var atacando = false
var is_dead = false
var levando_hit = false
var vida = 20

func _ready():
	add_to_group("inimigo")
	if barra_de_vida:
		barra_de_vida.max_value = vida
		barra_de_vida.value = vida

func _physics_process(delta):
	if is_dead: return 
	
	# Aplica Gravidade
	if not is_on_floor():
		velocity.y += gravity * delta
		
	if levando_hit or atacando:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	else:
		# --- LÓGICA DE PATRULHA MELHORADA ---
		
		# 1. Detecta Parede (Usando a colisão do próprio corpo)
		# 2. Detecta Buraco (Usando o RayCast2D)
		if is_on_wall() or not ray.is_colliding():
			virar_personagem()
			
		velocity.x = direction * SPEED
		animation.play("run")
		
	move_and_slide()

func virar_personagem():
	direction *= -1
	# Inverte o RayCast para ele olhar o chão do outro lado
	ray.position.x *= -1 
	# Inverte o Sprite
	sprite.flip_h = (direction > 0)

# --- Sistema de Dano (Chamado pelo Player) ---
func take_damage(amount: int):
	if is_dead: return
	vida -= amount
	if barra_de_vida:
		barra_de_vida.value = vida
	
	if vida <= 0:
		die()
	else:
		levando_hit = true
		animation.play("hit")
		await get_tree().create_timer(0.4).timeout
		if not is_dead:
			levando_hit = false

func die():
	if is_dead: return
	is_dead = true
	velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", true)
	if has_node("AttackArea"):
		$AttackArea.set_deferred("monitoring", false)
	animation.play("death")
	await get_tree().create_timer(1.5).timeout
	queue_free()

# --- Lógica de Ataque ---
func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_dead:
		atacando = true
		tocar_ataque()

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		atacando = false

func tocar_ataque():
	if is_dead or levando_hit or not atacando: return
	animation.play("attack")
	await get_tree().create_timer(0.4).timeout 
	if atacando and not is_dead and not levando_hit:
		var corpos = attack_area.get_overlapping_bodies()
		for corpo in corpos:
			if corpo.is_in_group("player") and corpo.has_method("take_damage"):
				corpo.take_damage(DANO_INIMIGO)
