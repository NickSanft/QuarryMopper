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

var _overlay: TextureRect


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
                _overlay.texture = TEX_RUNES[adjacent_mines]
            else:
                _overlay.texture = null


func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        var mb := event as InputEventMouseButton
        if mb.button_index == MOUSE_BUTTON_LEFT and state == State.HIDDEN:
            reveal_requested.emit(self)
        elif mb.button_index == MOUSE_BUTTON_RIGHT and state != State.REVEALED:
            flag_requested.emit(self)
