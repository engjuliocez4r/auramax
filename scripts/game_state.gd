extends Node
## Autoload: GameState
##
## Single source of truth for player-owned data. Identity fields (name, flag,
## avatar gender) are editable after creation, never write-once, because the
## options screen edits them directly through the setters below.

signal player_name_changed(new_name: String)
signal flag_changed(new_flag_id: String)
signal avatar_gender_changed(new_gender: AvatarGender)
signal ego_changed(new_ego: int)
signal ego_points_changed(new_ego_points: int)
signal coins_changed(new_coins: int)
signal cosmetics_changed
signal current_aura_changed(new_value: float) # Story progress (design point 62) — never resets between duels.
signal defeated_opponents_changed # Unused since the scenario/round rework (point 63) — kept alongside Opponent (scripts/opponent.gd) rather than deleted.
signal current_round_index_changed(new_value: int)
signal completed_scenarios_changed

# Stored now, ahead of the avatar feature, so adding it later doesn't require
# a save-data migration.
enum AvatarGender { MALE, FEMALE }

const SAVE_PATH := "user://save.cfg"

const SECTION_PLAYER := "player"
const SECTION_COSMETICS := "cosmetics"

const MAX_PLAYER_NAME_LENGTH := 16
const DEFAULT_PLAYER_NAME := "Player"
const DEFAULT_FLAG_ID := ""
const DEFAULT_AVATAR_GENDER := AvatarGender.MALE
const MAX_STORY_AURA := 1000000.0 # Design point 62: the story runs 0 to 1,000,000; reaching it is the ending.

var player_name: String = DEFAULT_PLAYER_NAME
var flag_id: String = DEFAULT_FLAG_ID
var avatar_gender: AvatarGender = DEFAULT_AVATAR_GENDER
var ego: int = 0 # Permanent player level (design point 62) — "sou ego 32". Distinct from story aura.
var ego_points: int = 0 # Progress toward the next ego level; see add_ego().
var coins: int = 0
var owned_cosmetics: Array = []
var equipped_cosmetics: Dictionary = {}
var current_aura: float = 0.0 # Story progress checkpoint (design point 62). Only advanced by a round/boss result-screen commit, never by mid-duel farming.
var defeated_opponents: Array = [] # Unused since the scenario/round rework (point 63) — kept alongside Opponent (scripts/opponent.gd) rather than deleted. See completed_scenarios below for the current bookkeeping.
var current_round_index: int = 0 # Which round (0-9) is next within the active scenario — see duel.gd's _setup_story_round().
var completed_scenarios: Array = [] # Scenario ids whose boss has been defeated, in order — drives which scenario comes next (design point 40), one level up from the old defeated_opponents pattern.

var _config := ConfigFile.new()


func _ready() -> void:
	_load()


func set_player_name(new_name: String) -> bool:
	var trimmed := new_name.strip_edges()
	if trimmed.is_empty():
		push_warning("GameState: rejected empty player name")
		return false
	if trimmed.length() > MAX_PLAYER_NAME_LENGTH:
		trimmed = trimmed.substr(0, MAX_PLAYER_NAME_LENGTH)
	player_name = trimmed
	_save()
	player_name_changed.emit(player_name)
	return true


func set_flag(new_flag_id: String) -> void:
	flag_id = new_flag_id
	_save()
	flag_changed.emit(flag_id)


func set_avatar_gender(gender: AvatarGender) -> void:
	avatar_gender = gender
	_save()
	avatar_gender_changed.emit(avatar_gender)


## Adds ego progress and rolls it over into ego level-ups. points_per_level
## is passed in by the caller (the result screens) rather than stored here,
## keeping the level-up curve a tunable of the presentation that reveals it,
## not a hardcoded constant in this autoload.
func add_ego(points: int, points_per_level: int) -> void:
	if points == 0:
		return
	ego_points += points
	var ego_before := ego
	while points_per_level > 0 and ego_points >= points_per_level:
		ego_points -= points_per_level
		ego += 1
	_save()
	ego_points_changed.emit(ego_points)
	if ego != ego_before:
		ego_changed.emit(ego)


func set_current_aura(value: float) -> void:
	current_aura = clampf(value, 0.0, MAX_STORY_AURA)
	_save()
	current_aura_changed.emit(current_aura)


func add_defeated_opponent(opponent_id: String) -> void:
	if defeated_opponents.has(opponent_id):
		return
	defeated_opponents.append(opponent_id)
	_save()
	defeated_opponents_changed.emit()


func set_current_round_index(value: int) -> void:
	current_round_index = value
	_save()
	current_round_index_changed.emit(current_round_index)


func add_completed_scenario(scenario_id: String) -> void:
	if completed_scenarios.has(scenario_id):
		return
	completed_scenarios.append(scenario_id)
	_save()
	completed_scenarios_changed.emit()


func add_coins(amount: int) -> void:
	coins = maxi(0, coins + amount)
	_save()
	coins_changed.emit(coins)


func add_cosmetic(cosmetic_id: String) -> void:
	if owned_cosmetics.has(cosmetic_id):
		return
	owned_cosmetics.append(cosmetic_id)
	_save()
	cosmetics_changed.emit()


func equip_cosmetic(slot: String, cosmetic_id: String) -> void:
	equipped_cosmetics[slot] = cosmetic_id
	_save()
	cosmetics_changed.emit()


func _load() -> void:
	var err := _config.load(SAVE_PATH)
	if err != OK:
		# First run, or no save yet: keep the defaults set above.
		return
	player_name = _config.get_value(SECTION_PLAYER, "player_name", DEFAULT_PLAYER_NAME)
	flag_id = _config.get_value(SECTION_PLAYER, "flag_id", DEFAULT_FLAG_ID)
	avatar_gender = _config.get_value(SECTION_PLAYER, "avatar_gender", DEFAULT_AVATAR_GENDER)
	ego = _config.get_value(SECTION_PLAYER, "ego", 0)
	ego_points = _config.get_value(SECTION_PLAYER, "ego_points", 0)
	coins = _config.get_value(SECTION_PLAYER, "coins", 0)
	owned_cosmetics = _config.get_value(SECTION_COSMETICS, "owned", [])
	equipped_cosmetics = _config.get_value(SECTION_COSMETICS, "equipped", {})
	current_aura = _config.get_value(SECTION_PLAYER, "current_aura", 0.0)
	defeated_opponents = _config.get_value(SECTION_PLAYER, "defeated_opponents", [])
	current_round_index = _config.get_value(SECTION_PLAYER, "current_round_index", 0)
	completed_scenarios = _config.get_value(SECTION_PLAYER, "completed_scenarios", [])


func _save() -> void:
	_config.set_value(SECTION_PLAYER, "player_name", player_name)
	_config.set_value(SECTION_PLAYER, "flag_id", flag_id)
	_config.set_value(SECTION_PLAYER, "avatar_gender", avatar_gender)
	_config.set_value(SECTION_PLAYER, "ego", ego)
	_config.set_value(SECTION_PLAYER, "ego_points", ego_points)
	_config.set_value(SECTION_PLAYER, "coins", coins)
	_config.set_value(SECTION_COSMETICS, "owned", owned_cosmetics)
	_config.set_value(SECTION_COSMETICS, "equipped", equipped_cosmetics)
	_config.set_value(SECTION_PLAYER, "current_aura", current_aura)
	_config.set_value(SECTION_PLAYER, "defeated_opponents", defeated_opponents)
	_config.set_value(SECTION_PLAYER, "current_round_index", current_round_index)
	_config.set_value(SECTION_PLAYER, "completed_scenarios", completed_scenarios)
	_config.save(SAVE_PATH)
