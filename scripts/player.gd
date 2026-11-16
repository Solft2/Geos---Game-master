
extends CharacterBody2D

signal scan_message(message: String)
signal material_collected(item_name: String)
signal lives_changed(lives: int)

@export var speed: float = 220.0
@export var jump_velocity: float = -380.0

const MAX_LIVES: int = 3

var gravity: float = 980.0
var nearby_items: Array[Area2D] = []
var inventory: Dictionary = {}
var lives: int = MAX_LIVES
var damage_cooldown: float = 0.0


func _ready() -> void:
	var interaction_area = $InteractionArea
	interaction_area.area_entered.connect(_on_area_entered)
	interaction_area.area_exited.connect(_on_area_exited)


func _physics_process(delta: float) -> void:
	damage_cooldown = maxf(damage_cooldown - delta, 0.0)

	# Aplica a gravidade quando o personagem está no ar.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Movimentação horizontal.
	var direction := Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * speed

	# Pulo.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()

	# Interação com materiais.
	if Input.is_action_just_pressed("interact"):
		scan_and_collect()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("materials"):
		if not nearby_items.has(area):
			nearby_items.append(area)


func _on_area_exited(area: Area2D) -> void:
	nearby_items.erase(area)


func scan_and_collect() -> void:
	nearby_items = nearby_items.filter(
		func(item): return is_instance_valid(item)
	)

	if nearby_items.is_empty():
		scan_message.emit(
            "SCAN: Nenhum material encontrado por perto."
		)
		return

	var nearest_item: Area2D = null
	var nearest_distance: float = INF

	for item in nearby_items:
		var distance = global_position.distance_to(
			item.global_position
		)

		if distance < nearest_distance:
			nearest_distance = distance
			nearest_item = item

	if nearest_item != null:
		nearest_item.request_pickup(self)


func add_material(item_name: String) -> void:
	inventory[item_name] = inventory.get(item_name, 0) + 1
	material_collected.emit(item_name)


func has_material(item_name: String) -> bool:
	return inventory.get(item_name, 0) > 0


func take_damage() -> void:
	if lives <= 0 or damage_cooldown > 0.0:
		return

	lives -= 1
	damage_cooldown = 1.0
	lives_changed.emit(lives)
