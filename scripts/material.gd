
extends Area2D

@export var item_name: String = "Ferro"
@export var useful_for_repair: bool = true
@export var makes_sense_in_core: bool = true
@export_multiline var scientific_info: String = ""
@export_multiline var repair_info: String = ""


func _ready() -> void:
    add_to_group("materials")


func request_pickup(player: Node) -> void:
    var main_scene = player.get_tree().current_scene
    if main_scene != null and main_scene.has_method("show_pickup_dialog"):
        main_scene.show_pickup_dialog(self)
    else:
        confirm_pickup(player)


func confirm_pickup(player: Node) -> void:
    var utility_text: String
    var location_text: String

    if useful_for_repair:
        utility_text = "SIM - " + repair_info
    else:
        utility_text = "NAO - Nao e necessario para o reparo."

    if makes_sense_in_core:
        location_text = "SIM - compativel com o ambiente."
    else:
        location_text = "NAO - material inesperado neste ambiente."

    var report := (
        "=== SCAN GEOS ===\n"
        + "Material: " + item_name + "\n"
        + "Reparo da capsula: " + utility_text + "\n"
        + "Presenca no nucleo: " + location_text + "\n"
        + "Informacao cientifica: " + scientific_info
    )
-------------------------------------- +++++++ -------------------------------------

extends Area2D

@export var item_name: String = "Ferro"

@export_multiline var red_info: String = """
AMOSTRA ENCONTRADA!

Foi identificado um material metálico.
Ele pode estar relacionado à composição
do núcleo terrestre.

Faça a análise inicial!
"""

@export_multiline var blue_info: String = """
ANÁLISE AVANÇADA!

O material apresenta propriedades
magnéticas e pode participar da
produção de ligas metálicas.

Consulte o manual para descobrir
qual é o material!
"""

func _ready() -> void:
    add_to_group("materials")


func interact(player: Node) -> void:
    player.start_investigation(self)


func collect() -> void:
    queue_free()
    player.scan_message.emit(report)
    player.add_material(item_name)
    queue_free()

