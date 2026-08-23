extends Node
## Autoload: GameState
##
## Single source of truth for player-owned data. Identity fields (name, flag,
## avatar gender) are editable after creation, never write-once, because the
## options screen edits them directly through the setters below.

signal player_name_changed(new_name: String)
signal flag_changed(new_flag_id: String)
signal avatar_gender_changed(new_gender: AvatarGender)
signal aura_level_changed(new_level: int)
signal coins_changed(new_coins: int)
signal cosmetics_changed

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

var player_name: String = DEFAULT_PLAYER_NAME
var flag_id: String = DEFAULT_FLAG_ID
var avatar_gender: AvatarGender = DEFAULT_AVATAR_GENDER
var aura_level: int = 0
var coins: int = 0
var owned_cosmetics: Array = []
var equipped_cosmetics: Dictionary = {}

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


func set_aura_level(level: int) -> void:
	aura_level = level
	_save()
	aura_level_changed.emit(aura_level)


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
	aura_level = _config.get_value(SECTION_PLAYER, "aura_level", 0)
	coins = _config.get_value(SECTION_PLAYER, "coins", 0)
	owned_cosmetics = _config.get_value(SECTION_COSMETICS, "owned", [])
	equipped_cosmetics = _config.get_value(SECTION_COSMETICS, "equipped", {})


func _save() -> void:
	_config.set_value(SECTION_PLAYER, "player_name", player_name)
	_config.set_value(SECTION_PLAYER, "flag_id", flag_id)
	_config.set_value(SECTION_PLAYER, "avatar_gender", avatar_gender)
	_config.set_value(SECTION_PLAYER, "aura_level", aura_level)
	_config.set_value(SECTION_PLAYER, "coins", coins)
	_config.set_value(SECTION_COSMETICS, "owned", owned_cosmetics)
	_config.set_value(SECTION_COSMETICS, "equipped", equipped_cosmetics)
	_config.save(SAVE_PATH)
