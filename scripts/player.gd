
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
-------------------------------------------------- +++++++++++++++++=----------------------------

extends CharacterBody2D

signal red_box_opened(message: String)
signal blue_box_opened(message: String)
signal material_collected(item_name: String)

@export var speed: float = 220.0
@export var jump_velocity: float = -380.0

var gravity: float = 980.0

var nearby_items: Array[Area2D] = []
var current_item: Area2D = null

var red_analyzed: bool = false
var blue_analyzed: bool = false

var inventory: Dictionary = {}


func _ready() -> void:
    $InteractionArea.area_entered.connect(_on_area_entered)
    $InteractionArea.area_exited.connect(_on_area_exited)


func _physics_process(delta: float) -> void:

    # Gravidade
    if not is_on_floor():
        velocity.y += gravity * delta

    # Movimento
    var direction := Input.get_axis("ui_left", "ui_right")
    velocity.x = direction * speed

    # Pulo
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity

    move_and_slide()

    # Ações de investigação
    if Input.is_action_just_pressed("interact"):
        scan_material()

    if Input.is_action_just_pressed("analyze"):
        analyze_material()

    if Input.is_action_just_pressed("collect"):
        collect_material()


func _on_area_entered(area: Area2D) -> void:
    if area.is_in_group("materials"):
        if not nearby_items.has(area):
            nearby_items.append(area)


func _on_area_exited(area: Area2D) -> void:
    nearby_items.erase(area)

    if current_item == area:
        current_item = null
        red_analyzed = false
        blue_analyzed = false


func get_nearest_material() -> Area2D:
    nearby_items = nearby_items.filter(
        func(item): return is_instance_valid(item)
    )

    var nearest: Area2D = null
    var nearest_distance: float = INF

    for item in nearby_items:
        var distance = global_position.distance_to(
            item.global_position
        )

        if distance < nearest_distance:
            nearest_distance = distance
            nearest = item

    return nearest


# Z - Abre a caixa vermelha
func scan_material() -> void:

    if current_item == null:
        current_item = get_nearest_material()

    if current_item == null:
        red_box_opened.emit(
            "Nenhuma amostra encontrada por perto."
        )
        return

    red_analyzed = true
    blue_analyzed = false

    blue_box_opened.emit("")

    red_box_opened.emit(current_item.red_info)


# X - Abre a caixa azul
func analyze_material() -> void:

    if current_item == null:
        red_box_opened.emit(
            "Encontre uma amostra antes de utilizar o Analyzer."
        )
        return

    if not red_analyzed:
        red_box_opened.emit(
            "Faça primeiro a análise inicial pressionando Z."
        )
        return

    blue_analyzed = true
    blue_box_opened.emit(current_item.blue_info)


# C - Coleta a amostra
func collect_material() -> void:

    if current_item == null:
        return

    if not red_analyzed or not blue_analyzed:
        red_box_opened.emit(
            "Você precisa realizar as duas análises antes de coletar!"
        )
        return

    var item_name: String = current_item.item_name

    inventory[item_name] = inventory.get(item_name, 0) + 1

    material_collected.emit(item_name)

    current_item.collect()

    current_item = null
    red_analyzed = false
    blue_analyzed = false


func has_material(item_name: String) -> bool:
    return inventory.get(item_name, 0) > 0

