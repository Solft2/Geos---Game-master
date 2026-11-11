
extends Node2D

const MAX_LIVES: int = 3

var collected_items: Dictionary = {}
var required_items: Dictionary = {
    "Ferro": 1,
    "Níquel": 1
}
var pending_pickup: Area2D = null


func _ready() -> void:
    $Player.scan_message.connect(_on_scan_message)
    $Player.material_collected.connect(_on_material_collected)
    $Player.lives_changed.connect(_on_player_lives_changed)

    $Exit.body_entered.connect(_on_exit_body_entered)
    $Hazard.body_entered.connect(_on_hazard_body_entered)
    $HUD/PickupDialog/ConfirmButton.pressed.connect(_on_pickup_confirmed)
    $HUD/PickupDialog/CancelButton.pressed.connect(_on_pickup_canceled)

    _on_player_lives_changed($Player.lives)
    $HUD/ScanPanel/ScanLabel.text = (
        "GEOS SCAN\nAproxime-se de um material e pressione E."
    )

    hide_pickup_dialog()
    update_inventory()


func _on_scan_message(message: String) -> void:
    $HUD/ScanPanel/ScanLabel.text = message


func _on_player_lives_changed(lives: int) -> void:
    var hearts := ""

    for index in range(MAX_LIVES):
        hearts += "♥ " if index < lives else "♡ "

    $HUD/HeartsLabel.text = hearts.strip_edges()


func _on_hazard_body_entered(body: Node2D) -> void:
    if body == $Player:
        $Player.take_damage()


func _on_material_collected(item_name: String) -> void:
    collected_items[item_name] = (
        collected_items.get(item_name, 0) + 1
    )

    update_inventory()


func show_pickup_dialog(item: Area2D) -> void:
    pending_pickup = item
    $HUD/PickupDialog.visible = true
    $HUD/PickupDialog/TitleLabel.text = "Coletar " + item.item_name + "?"
    $HUD/PickupDialog/DetailsLabel.text = (
        "Material: " + item.item_name + "\n\n"
        + "Informacao cientifica: " + item.scientific_info + "\n\n"
        + "Uso na capsula: " + item.repair_info
    )
    $HUD/ScanPanel/ScanLabel.text = (
        "GEOS: Material identificado. Confirme a coleta."
    )


func hide_pickup_dialog() -> void:
    pending_pickup = null
    $HUD/PickupDialog.visible = false


func _on_pickup_confirmed() -> void:
    if pending_pickup != null:
        pending_pickup.confirm_pickup($Player)
        hide_pickup_dialog()


func _on_pickup_canceled() -> void:
    $HUD/ScanPanel/ScanLabel.text = (
        "Coleta cancelada. Continue explorando."
    )
    hide_pickup_dialog()


func update_inventory() -> void:
    var inventory_text := "MATERIAIS COLETADOS\n"

    for item_name in collected_items:
        inventory_text += (
            item_name + ": "
            + str(collected_items[item_name]) + "\n"
        )

    $HUD/InventoryLabel.text = inventory_text

    var objective_complete := true

    for item_name in required_items:
        if collected_items.get(item_name, 0) < required_items[item_name]:
            objective_complete = false

    if objective_complete:
        $HUD/ObjectiveLabel.text = (
            "OBJETIVO: Ferro e niquel coletados! "
            + "Encontre a saida."
        )
    else:
        $HUD/ObjectiveLabel.text = (
            "OBJETIVO: Colete 1 ferro e 1 niquel."
        )


func _on_exit_body_entered(body: Node2D) -> void:
    if body != $Player:
        return

    var objective_complete := true

    for item_name in required_items:
        if collected_items.get(item_name, 0) < required_items[item_name]:
            objective_complete = false

    if objective_complete:
        $HUD/ObjectiveLabel.text = (
            "FASE CONCLUIDA! Capsula pronta para o reparo."
        )
        $HUD/ScanPanel/ScanLabel.text = (
            "GEOS: Amostras registradas. "
            + "Prepare-se para explorar o manto!"
        )
    else:
        $HUD/ScanPanel/ScanLabel.text = (
            "Ainda faltam materiais para completar a missao."
        )
