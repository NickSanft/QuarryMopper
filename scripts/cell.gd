class_name Cell
extends TextureButton

## A single Minesweeper cell.

signal reveal_requested(cell: Cell)
signal flag_requested(cell: Cell)

enum State { HIDDEN, REVEALED, FLAGGED }

const TEX_STONE := preload("res://assets/textures/cell_stone.svg")
const TEX_REVEALED := preload("res://assets/textures/cell_revealed.svg")
const TEX_SKULL := preload("res://assets/textures/mine_skull.svg")
const TEX_SWORD := preload("res://assets/textures/flag_sword.svg")
const TEX_RUNES := [
    null,
    preload("res://assets/textures/numbers/rune_1.svg"),
    preload("res://assets/textures/numbers/rune_2.svg"),
    preload("res://assets/textures/numbers/rune_3.svg"),
    preload("res://assets/textures/numbers/rune_4.svg"),
    preload("res://assets/textures/numbers/rune_5.svg"),
    preload("res://assets/textures/numbers/rune_6.svg"),
    preload("res://assets/textures/numbers/rune_7.svg"),
    preload("res://assets/textures/numbers/rune_8.svg"),
]

var grid_pos: Vector2i
var is_mine: bool = false
var adjacent_mines: int = 0
var state: int = State.HIDDEN

## If > 0 and != adjacent_mines, the cell will display this rune crossed out
## next to the corrected one — as if the creator miscounted by hand.
var correction_wrong: int = 0

var _overlay: TextureRect
var _wrong_rune: TextureRect = null
var _strike: ColorRect = null
var _correct_rune: TextureRect = null


func _init() -> void:
    texture_normal = TEX_STONE
    ignore_texture_size = true
    stretch_mode = TextureButton.STRETCH_SCALE


func _ready() -> void:
    _overlay = TextureRect.new()
    _overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _overlay.stretch_mode = TextureRect.STRETCH_SCALE
    _overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(_overlay)


func refresh_visual() -> void:
    _hide_correction()
    match state:
        State.HIDDEN:
            texture_normal = TEX_STONE
            _overlay.texture = null
        State.FLAGGED:
            texture_normal = TEX_STONE
            _overlay.texture = TEX_SWORD
        State.REVEALED:
            texture_normal = TEX_REVEALED
            if is_mine:
                _overlay.texture = TEX_SKULL
            elif adjacent_mines > 0:
                if correction_wrong > 0 and correction_wrong != adjacent_mines:
                    _show_correction()
                else:
                    _overlay.texture = TEX_RUNES[adjacent_mines]
            else:
                _overlay.texture = null


func _show_correction() -> void:
    # Hide the main rune; we draw two smaller ones plus a strike-through.
    _overlay.texture = null
    if _wrong_rune == null:
        _wrong_rune = TextureRect.new()
        _wrong_rune.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        _wrong_rune.stretch_mode = TextureRect.STRETCH_SCALE
        _wrong_rune.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _wrong_rune.modulate = Color(1, 1, 1, 0.65)
        add_child(_wrong_rune)
    if _strike == null:
        _strike = ColorRect.new()
        _strike.color = Color(0.85, 0.1, 0.05, 0.85)
        _strike.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _strike.rotation = deg_to_rad(-22)
        add_child(_strike)
    if _correct_rune == null:
        _correct_rune = TextureRect.new()
        _correct_rune.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        _correct_rune.stretch_mode = TextureRect.STRETCH_SCALE
        _correct_rune.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(_correct_rune)

    var w := size.x if size.x > 0 else custom_minimum_size.x
    var h := size.y if size.y > 0 else custom_minimum_size.y
    var small := Vector2(w * 0.55, h * 0.55)
    _wrong_rune.position = Vector2(-w * 0.05, -h * 0.05)
    _wrong_rune.size = small
    _wrong_rune.texture = TEX_RUNES[correction_wrong]
    _strike.position = Vector2(w * 0.02, h * 0.22)
    _strike.size = Vector2(w * 0.55, max(2.0, h * 0.06))
    _strike.pivot_offset = _strike.size * 0.5
    _correct_rune.position = Vector2(w * 0.42, h * 0.42)
    _correct_rune.size = small
    _correct_rune.texture = TEX_RUNES[adjacent_mines]
    _wrong_rune.visible = true
    _strike.visible = true
    _correct_rune.visible = true


func _hide_correction() -> void:
    if _wrong_rune: _wrong_rune.visible = false
    if _strike: _strike.visible = false
    if _correct_rune: _correct_rune.visible = false


func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        var mb := event as InputEventMouseButton
        if mb.button_index == MOUSE_BUTTON_LEFT and state == State.HIDDEN:
            reveal_requested.emit(self)
        elif mb.button_index == MOUSE_BUTTON_RIGHT and state != State.REVEALED:
            flag_requested.emit(self)
