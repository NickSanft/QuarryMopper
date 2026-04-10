extends Control

@onready var plank_title: Label = $PlankOverlay/PlankTitle


func _ready() -> void:
    _refresh_title()
    GameSettings.settings_changed.connect(_refresh_title)
    SfxPlayer.play_music("ambient")


func _refresh_title() -> void:
    plank_title.text = GameSettings.custom_title


func _on_quest_forth_pressed() -> void:
    SceneRouter.goto(SceneRouter.GAME_BOARD)


func _on_provisions_pressed() -> void:
    SceneRouter.goto(SceneRouter.SETTINGS_MENU)


func _on_flee_pressed() -> void:
    get_tree().quit()
