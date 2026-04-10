extends Node

## Centralized SFX + music playback. Autoloaded as "SfxPlayer".

const SOUNDS := {
    "reveal": preload("res://resources/audio/reveal.ogg"),
    "flag": preload("res://resources/audio/flag.ogg"),
    "explosion": preload("res://resources/audio/explosion.ogg"),
    "victory": preload("res://resources/audio/victory.ogg"),
    "creak": preload("res://resources/audio/creak.ogg"),
}

const MUSIC := {
    "ambient": preload("res://resources/audio/ambient_dungeon.ogg"),
}

const POOL_SIZE := 6

var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _music: AudioStreamPlayer
var _current_music: String = ""


func _ready() -> void:
    for i in range(POOL_SIZE):
        var p := AudioStreamPlayer.new()
        add_child(p)
        _players.append(p)
    _music = AudioStreamPlayer.new()
    _music.bus = "Master"
    add_child(_music)
    GameSettings.settings_changed.connect(_apply_music_volume)


func play(sound_name: String) -> void:
    if not SOUNDS.has(sound_name):
        return
    var p := _players[_next]
    _next = (_next + 1) % POOL_SIZE
    p.stream = SOUNDS[sound_name]
    p.volume_db = linear_to_db(max(GameSettings.sfx_volume, 0.0001))
    p.play()


func play_music(music_name: String) -> void:
    if not MUSIC.has(music_name):
        return
    if _current_music == music_name and _music.playing:
        return
    var stream: AudioStream = MUSIC[music_name]
    # Force the OGG stream to loop if it supports it.
    if stream is AudioStreamOggVorbis:
        (stream as AudioStreamOggVorbis).loop = true
    _music.stream = stream
    _apply_music_volume()
    _music.play()
    _current_music = music_name


func stop_music() -> void:
    _music.stop()
    _current_music = ""


func _apply_music_volume() -> void:
    _music.volume_db = linear_to_db(max(GameSettings.music_volume, 0.0001))
