extends CanvasLayer

## Overlay shown when the game ends. Set `won` before adding to the tree.

signal retry_requested
signal title_requested

const SHREK_TEX := preload("res://resources/pics/ShrekWazowski.jpeg")
const LOSS_TEXT := "You take 1 damage"
const G_INDEX := 15  # index of 'g' in "You take 1 damage"
const SHREK_SIZE := Vector2(220, 220)

@export var won: bool = false

@onready var heading: Label = $Center/Panel/VBox/Heading
@onready var subheading: Label = $Center/Panel/VBox/Subheading

var _g_hit_area: Control
var _shrek_image: TextureRect


func _ready() -> void:
    if won:
        heading.text = "Victory!"
        subheading.text = "The dungeon is cleared."
        heading.add_theme_color_override("font_color", Color(0.95, 0.82, 0.32))
    else:
        heading.text = LOSS_TEXT
        subheading.text = "Spikes come out of the ground and the room resets"
        heading.add_theme_color_override("font_color", Color(0.78, 0.18, 0.14))
        call_deferred("_setup_g_hover")
    # Fade in.
    var root: Control = $Center
    root.modulate = Color(1, 1, 1, 0)
    var tween := create_tween()
    tween.tween_property(root, "modulate", Color(1, 1, 1, 1), 0.4)


func _setup_g_hover() -> void:
    # Defer one more frame so the label has been laid out and has a real size.
    await get_tree().process_frame
    if not is_inside_tree():
        return
    var font: Font = heading.get_theme_font("font")
    var font_size: int = heading.get_theme_font_size("font_size")
    var prefix: String = LOSS_TEXT.substr(0, G_INDEX)
    var prefix_with_g: String = LOSS_TEXT.substr(0, G_INDEX + 1)
    var prefix_w: float = font.get_string_size(prefix, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
    var with_g_w: float = font.get_string_size(prefix_with_g, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
    var full_w: float = font.get_string_size(LOSS_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
    var g_width: float = with_g_w - prefix_w
    var label_w: float = heading.size.x
    var text_left: float = (label_w - full_w) * 0.5
    var g_left: float = text_left + prefix_w

    _g_hit_area = Control.new()
    _g_hit_area.mouse_filter = Control.MOUSE_FILTER_STOP
    _g_hit_area.position = Vector2(g_left, 0)
    _g_hit_area.size = Vector2(g_width, heading.size.y)
    heading.add_child(_g_hit_area)

    _shrek_image = TextureRect.new()
    _shrek_image.texture = SHREK_TEX
    _shrek_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _shrek_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _shrek_image.size = SHREK_SIZE
    _shrek_image.position = Vector2(
            g_left + g_width * 0.5 - SHREK_SIZE.x * 0.5,
            -SHREK_SIZE.y - 12.0)
    _shrek_image.visible = false
    _shrek_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
    heading.add_child(_shrek_image)

    _g_hit_area.mouse_entered.connect(_on_g_mouse_entered)
    _g_hit_area.mouse_exited.connect(_on_g_mouse_exited)


func _on_g_mouse_entered() -> void:
    if _shrek_image:
        _shrek_image.visible = true


func _on_g_mouse_exited() -> void:
    if _shrek_image:
        _shrek_image.visible = false


func _on_retry_pressed() -> void:
    retry_requested.emit()
    queue_free()


func _on_title_pressed() -> void:
    title_requested.emit()
    queue_free()
