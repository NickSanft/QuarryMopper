extends CanvasLayer

## Overlay shown when the game ends. Set `won` before adding to the tree.

signal retry_requested
signal title_requested

@export var won: bool = false

@onready var heading: Label = $Center/Panel/VBox/Heading
@onready var subheading: Label = $Center/Panel/VBox/Subheading


func _ready() -> void:
    if won:
        heading.text = "Victory!"
        subheading.text = "The dungeon is cleared."
        heading.add_theme_color_override("font_color", Color(0.95, 0.82, 0.32))
    else:
        heading.text = "You have perished..."
        subheading.text = "The depths claim another adventurer."
        heading.add_theme_color_override("font_color", Color(0.78, 0.18, 0.14))
    # Fade in.
    var root: Control = $Center
    root.modulate = Color(1, 1, 1, 0)
    var tween := create_tween()
    tween.tween_property(root, "modulate", Color(1, 1, 1, 1), 0.4)


func _on_retry_pressed() -> void:
    retry_requested.emit()
    queue_free()


func _on_title_pressed() -> void:
    title_requested.emit()
    queue_free()
