extends CharacterBody2D

@export var vida_max = 50
@export var dano = 2
@export var speed = 120.0

@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var barra_de_vida: ProgressBar = $ProgressBar
@onready var raycast: RayCast2D = $RayCast2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# VIDA
var vida = vida_max
var is_dead = false

# ESTADOS
var atacando = false
var levando_hit = false

# MOVIMENTO
var direction = -1
var pode_virar = true

# ATAQUE
var pode_atacar = true
var player_detectado = null

func _ready():

	add_to_group("inimigo")

	vida = vida_max

	barra_de_vida.max_value = vida_max
	barra_de_vida.value = vida

	# Raycast olhando para frente e para baixo
	raycast.target_position = Vector2(-40, 25)

func _physics_process(delta):

	if is_dead:
		return

	# gravidade
	if not is_on_floor():
		velocity.y += gravity * delta

	# detectar player
	check_player()

	# movimento
	if not atacando and not levando_hit:
		velocity.x = direction * speed
	else:
		velocity.x = 0

	# virar sprite
	sprite.flip_h = direction > 0

	move_and_slide()

	# virar ao bater em parede ou acabar chão
	if is_on_wall() or not raycast.is_colliding():
		change_direction()

	update_animation()

func check_player():

	if is_dead:
		return

	var bodies = attack_area.get_overlapping_bodies()

	player_detectado = null

	for body in bodies:

		if body.is_in_group("player"):

			player_detectado = body

			# distância do player
			var distancia = global_position.distance_to(body.global_position)

			# seguir player
			if body.global_position.x > global_position.x:
				direction = 1
			else:
				direction = -1

			# atacar somente perto
			if distancia < 70:

				if pode_atacar and not atacando:
					atacar(body)

			return

func atacar(player):

	if atacando or not pode_atacar:
		return

	atacando = true
	pode_atacar = false

	velocity.x = 0

	animation.play("attack")

	# espera um pouco antes do dano
	await get_tree().create_timer(0.3).timeout

	# verifica se player ainda está perto
	if player:

		var distancia = global_position.distance_to(player.global_position)

		if distancia < 80:

			if player.has_method("take_damage"):
				player.take_damage(dano)

	# cooldown ataque
	await get_tree().create_timer(1.0).timeout

	atacando = false
	pode_atacar = true

func update_animation():

	if is_dead:

		if animation.current_animation != "death":
			animation.play("death")

		return

	if levando_hit:

		if animation.current_animation != "hit":
			animation.play("hit")

		return

	if atacando:

		if animation.current_animation != "attack":
			animation.play("attack")

		return

	if velocity.x != 0:

		if animation.current_animation != "run":
			animation.play("run")

	else:

		if animation.current_animation != "idle":
			animation.play("idle")

func change_direction():

	if not pode_virar:
		return

	pode_virar = false

	direction *= -1

	# inverter raycast
	raycast.target_position.x *= -1

	await get_tree().create_timer(0.2).timeout

	pode_virar = true

func take_damage(amount):

	if is_dead:
		return

	vida -= amount

	barra_de_vida.value = vida

	if vida <= 0:
		die()

	else:

		levando_hit = true

		animation.play("hit")

		await get_tree().create_timer(0.4).timeout

		levando_hit = false

func die():

	is_dead = true

	velocity = Vector2.ZERO

	animation.play("death")

	$CollisionShape2D.set_deferred("disabled", true)
	$AttackArea/CollisionShape2D.set_deferred("disabled", true)

	await get_tree().create_timer(2.0).timeout

	queue_free()
