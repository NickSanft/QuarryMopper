extends Control

@onready var plank: TextureRect = $PlankOverlay
@onready var plank_title: Label = $PlankOverlay/PlankTitle
@onready var guilt_note: Label = $GuiltNote
@onready var flee_button: Button = $ButtonColumn/FleeButton

const SLIP_CHANCE := 0.35
const SLIP_DISTANCE := 14.0
const SLIP_DOWN_DURATION := 0.55
const SLIP_HOLD := 0.6
const SLIP_UP_DURATION := 0.35

const DOUBLE_CLICK_WINDOW := 0.4
const FALL_DISTANCE := 520.0
const FALL_ROTATION := 0.6
const FALL_DURATION := 0.7
const FALL_HOLD := 3.0
const FALL_RETURN_DURATION := 0.55

const PLANK_PADDING_X := 160.0
const PLANK_MIN_WIDTH := 360.0
const PLANK_MAX_WIDTH := 1400.0
const PLANK_HEIGHT := 200.0

var _plank_resting_position: Vector2
var _plank_resting_rotation: float
var _slip_in_progress: bool = false
var _fall_in_progress: bool = false
var _last_plank_click_time: float = -1000.0

var _flee_hover_count: int = 0
const FLEE_MESSAGES: Array[String] = [
	"please don't leave, it took me 6 months to make this",
	"I have a family. Well, a brother",
	"this room will be so empty without you",
	"I promise the next room has treasure",
	"the mines aren't even that dangerous",
	"ok fine, some of them are",
	"please? I'll reduce the mine count",
	"I won't actually. but please stay",
]
const FLEE_DODGE_DISTANCE := 120.0


func _ready() -> void:
	plank.mouse_filter = Control.MOUSE_FILTER_STOP
	plank.gui_input.connect(_on_plank_input)
	_plank_resting_rotation = plank.rotation
	_refresh_title()
	GameSettings.settings_changed.connect(_refresh_title)
	SfxPlayer.play_music("ambient")
	if randf() < SLIP_CHANCE:
		await get_tree().create_timer(randf_range(0.6, 1.4)).timeout
		_play_slip()


func _refresh_title() -> void:
	plank_title.text = GameSettings.custom_title
	_resize_plank_to_title()


func _resize_plank_to_title() -> void:
	var font: Font = plank_title.get_theme_font("font")
	var font_size: int = plank_title.get_theme_font_size("font_size")
	var text_width: float = font.get_string_size(
			plank_title.text,
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			font_size).x
	var w: float = clampf(text_width + PLANK_PADDING_X, PLANK_MIN_WIDTH, PLANK_MAX_WIDTH)
	plank.offset_left = -w / 2.0
	plank.offset_right = w / 2.0
	plank.pivot_offset = Vector2(w / 2.0, PLANK_HEIGHT / 2.0)
	_plank_resting_position = plank.position


func _on_plank_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var now := Time.get_ticks_msec() / 1000.0
		if now - _last_plank_click_time <= DOUBLE_CLICK_WINDOW:
			_last_plank_click_time = -1000.0
			_play_fall()
		else:
			_last_plank_click_time = now
			_play_slip()


func _play_slip() -> void:
	if _slip_in_progress or _fall_in_progress or not is_inside_tree():
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


func _play_fall() -> void:
	if _fall_in_progress or not is_inside_tree():
		return
	_fall_in_progress = true
	# Cancel any in-flight slip; the fall takes over.
	_slip_in_progress = false
	var fallen_pos := _plank_resting_position + Vector2(0, FALL_DISTANCE)
	var fallen_rot := _plank_resting_rotation + FALL_ROTATION
	var down := create_tween().set_parallel(true)
	down.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	down.tween_property(plank, "position", fallen_pos, FALL_DURATION)
	down.tween_property(plank, "rotation", fallen_rot, FALL_DURATION)
	SfxPlayer.play("creak")
	await down.finished
	await get_tree().create_timer(FALL_HOLD).timeout
	if not is_inside_tree():
		_fall_in_progress = false
		return
	var up := create_tween().set_parallel(true)
	up.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	up.tween_property(plank, "position", _plank_resting_position, FALL_RETURN_DURATION)
	up.tween_property(plank, "rotation", _plank_resting_rotation, FALL_RETURN_DURATION)
	SfxPlayer.play("creak")
	await up.finished
	_fall_in_progress = false


func _on_flee_mouse_entered() -> void:
	var msg_index := clampi(_flee_hover_count, 0, FLEE_MESSAGES.size() - 1)
	guilt_note.text = FLEE_MESSAGES[msg_index]
	var t := create_tween()
	t.tween_property(guilt_note, "modulate:a", 1.0, 0.6)
	if _flee_hover_count == 0:
		SfxPlayer.play("please_dont_leave")
	_flee_hover_count += 1
	# After exhausting all messages, the button starts dodging the cursor.
	if _flee_hover_count > FLEE_MESSAGES.size():
		_dodge_flee_button()


func _on_flee_mouse_exited() -> void:
	var t := create_tween()
	t.tween_property(guilt_note, "modulate:a", 0.0, 0.4)


func _dodge_flee_button() -> void:
	var viewport_size := get_viewport_rect().size
	var btn_size := flee_button.size
	# Pick a random horizontal offset, keeping the button on screen.
	var margin := 40.0
	var min_x := margin
	var max_x := viewport_size.x - btn_size.x - margin
	var target_x := randf_range(min_x, max_x)
	# Convert to an offset from the button's current resting position.
	# The button is inside a VBoxContainer, so we shift it with position offset.
	var global_rest_x := flee_button.global_position.x - flee_button.position.x
	var offset_x := target_x - global_rest_x
	var offset_y := randf_range(-30.0, 30.0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(flee_button, "position",
		Vector2(offset_x, flee_button.position.y + offset_y), 0.25)


func _on_quest_forth_pressed() -> void:
	SceneRouter.goto(SceneRouter.GAME_BOARD)


func _on_provisions_pressed() -> void:
	SceneRouter.goto(SceneRouter.SETTINGS_MENU)


func _on_flee_pressed() -> void:
	get_tree().quit()
