extends Node

const SAVE_PATH: String = "user://savegame.cfg"

var unlocked_levels: int = 1
var max_levels: int = 3

var level_paths: Dictionary = {
	1: "res://scenes/level/level_1.tscn",
	2: "res://scenes/level/level_2.tscn",
	3: "res://scenes/level/level_3.tscn"
}

func _ready() -> void:
	load_progress()

func unlock_next_level(current_lvl_index: int) -> void:
	var next_lvl = current_lvl_index + 1
	if next_lvl > unlocked_levels and next_lvl <= max_levels:
		unlocked_levels = next_lvl
		save_progress()

func load_level(level_index: int) -> void:
	if level_paths.has(level_index):
		var path = level_paths[level_index]
		MenuNavigation.go_to_scene(path)
	else:
		MenuNavigation.open_level_select()

func complete_level(current_lvl_index: int) -> void:
	unlock_next_level(current_lvl_index)
	var next_lvl = current_lvl_index + 1
	if level_paths.has(next_lvl) and next_lvl <= unlocked_levels:
		load_level(next_lvl)
	else:
		MenuNavigation.open_level_select()

func save_progress() -> void:
	var config = ConfigFile.new()
	config.set_value("progress", "unlocked_levels", unlocked_levels)
	config.save(SAVE_PATH)

func load_progress() -> void:
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err == OK:
		unlocked_levels = config.get_value("progress", "unlocked_levels", 1)
	else:
		unlocked_levels = 1
