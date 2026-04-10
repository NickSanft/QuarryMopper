extends Control

@onready var title_edit: LineEdit = $Panel/VBox/TitleRow/TitleEdit
@onready var difficulty_option: OptionButton = $Panel/VBox/DifficultyRow/DifficultyOption
@onready var width_spin: SpinBox = $Panel/VBox/CustomRow/WidthSpin
@onready var height_spin: SpinBox = $Panel/VBox/CustomRow/HeightSpin
@onready var mines_spin: SpinBox = $Panel/VBox/CustomRow/MinesSpin
@onready var custom_row: HBoxContainer = $Panel/VBox/CustomRow
@onready var music_slider: HSlider = $Panel/VBox/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $Panel/VBox/SfxRow/SfxSlider
@onready var fullscreen_check: CheckButton = $Panel/VBox/FullscreenRow/FullscreenCheck


func _ready() -> void:
    difficulty_option.clear()
    difficulty_option.add_item("Apprentice (9x9, 10)", GameSettings.DIFFICULTY_APPRENTICE)
    difficulty_option.add_item("Adventurer (16x16, 40)", GameSettings.DIFFICULTY_ADVENTURER)
    difficulty_option.add_item("Dungeon Master (30x16, 99)", GameSettings.DIFFICULTY_DUNGEON_MASTER)
    difficulty_option.add_item("Custom", GameSettings.DIFFICULTY_CUSTOM)

    title_edit.text = GameSettings.custom_title
    title_edit.max_length = 24
    difficulty_option.select(GameSettings.difficulty)
    width_spin.value = GameSettings.custom_width
    height_spin.value = GameSettings.custom_height
    mines_spin.value = GameSettings.custom_mines
    music_slider.value = GameSettings.music_volume
    sfx_slider.value = GameSettings.sfx_volume
    fullscreen_check.button_pressed = GameSettings.fullscreen
    _update_custom_visibility()

    difficulty_option.item_selected.connect(_on_difficulty_changed)


func _on_difficulty_changed(_index: int) -> void:
    _update_custom_visibility()


func _update_custom_visibility() -> void:
    custom_row.visible = difficulty_option.get_selected_id() == GameSettings.DIFFICULTY_CUSTOM


func _on_save_pressed() -> void:
    GameSettings.custom_title = title_edit.text if title_edit.text.strip_edges() != "" else "Minesweeper"
    GameSettings.difficulty = difficulty_option.get_selected_id()
    GameSettings.custom_width = int(width_spin.value)
    GameSettings.custom_height = int(height_spin.value)
    GameSettings.custom_mines = int(mines_spin.value)
    GameSettings.music_volume = music_slider.value
    GameSettings.sfx_volume = sfx_slider.value
    GameSettings.fullscreen = fullscreen_check.button_pressed
    GameSettings.save()
    SceneRouter.goto(SceneRouter.TITLE_SCREEN)


func _on_cancel_pressed() -> void:
    SceneRouter.goto(SceneRouter.TITLE_SCREEN)
