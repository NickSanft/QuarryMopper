extends Control

@onready var plank: TextureRect = $PlankOverlay
@onready var plank_title: Label = $PlankOverlay/PlankTitle
@onready var guilt_note: Label = $GuiltNote

const SLIP_CHANCE := 0.35
const SLIP_DISTANCE := 14.0
const SLIP_DOWN_DURATION := 0.55
const SLIP_HOLD := 0.6
const SLIP_UP_DURATION := 0.35

var _plank_resting_position: Vector2
var _slip_in_progress: bool = false


func _ready() -> void:
    _refresh_title()
    GameSettings.settings_changed.connect(_refresh_title)
    SfxPlayer.play_music("ambient")
    _plank_resting_position = plank.position
    plank.mouse_filter = Control.MOUSE_FILTER_STOP
    plank.gui_input.connect(_on_plank_input)
    if randf() < SLIP_CHANCE:
        await get_tree().create_timer(randf_range(0.6, 1.4)).timeout
        _play_slip()


func _refresh_title() -> void:
    plank_title.text = GameSettings.custom_title


func _on_plank_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed \
            and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
        _play_slip()


func _play_slip() -> void:
    if _slip_in_progress or not is_inside_tree():
        return
    _slip_in_progress = true
    var slipped_pos := _plank_resting_position + Vector2(2, SLIP_DISTANCE)
    var down := create_tween()
    down.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
    down.tween_property(plank, "position", slipped_pos, SLIP_DOWN_DURATION)
    SfxPlayer.play("creak")
    await down.finished
    await get_tree().create_timer(SLIP_HOLD).timeout
    if not is_inside_tree():
        _slip_in_progress = false
        return
    var up := create_tween()
    up.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    up.tween_property(plank, "position", _plank_resting_position, SLIP_UP_DURATION)
    SfxPlayer.play("creak")
    await up.finished
    _slip_in_progress = false


func _on_flee_mouse_entered() -> void:
    var t := create_tween()
    t.tween_property(guilt_note, "modulate:a", 1.0, 0.6)
    SfxPlayer.play("please_dont_leave")


func _on_flee_mouse_exited() -> void:
    var t := create_tween()
    t.tween_property(guilt_note, "modulate:a", 0.0, 0.4)


func _on_quest_forth_pressed() -> void:
    SceneRouter.goto(SceneRouter.GAME_BOARD)


func _on_provisions_pressed() -> void:
    SceneRouter.goto(SceneRouter.SETTINGS_MENU)


func _on_flee_pressed() -> void:
    get_tree().quit()
