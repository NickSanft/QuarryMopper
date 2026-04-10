class_name Cell
extends TextureButton

## A single Minesweeper cell.

signal reveal_requested(cell: Cell)
signal flag_requested(cell: Cell)

enum State { HIDDEN, REVEALED, FLAGGED }

var grid_pos: Vector2i
var is_mine: bool = false
var adjacent_mines: int = 0
var state: int = State.HIDDEN


func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        var mb := event as InputEventMouseButton
        if mb.button_index == MOUSE_BUTTON_LEFT and state == State.HIDDEN:
            reveal_requested.emit(self)
        elif mb.button_index == MOUSE_BUTTON_RIGHT and state != State.REVEALED:
            flag_requested.emit(self)
