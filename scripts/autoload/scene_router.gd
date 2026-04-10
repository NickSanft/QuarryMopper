extends Node

## Simple scene transition helper. Autoloaded as "SceneRouter".

const TITLE_SCREEN := "res://scenes/title_screen.tscn"
const GAME_BOARD := "res://scenes/game_board.tscn"
const SETTINGS_MENU := "res://scenes/settings_menu.tscn"
const GAME_OVER := "res://scenes/game_over.tscn"


func goto(scene_path: String) -> void:
    get_tree().change_scene_to_file(scene_path)
