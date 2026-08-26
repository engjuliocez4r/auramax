extends Resource
class_name Opponent
## Data-driven story-mode opponent (design points 16, 63).
##
## A story opponent never plays live — it is a stationary target with a
## name, a face and a number (design point 16). Difficulty is tuned by the
## INTERVAL between aura_threshold on consecutive opponents, never by the
## totals themselves: see the .tres instances under assets/data/opponents/.

@export var id: String = "" # Stable key: used for GameState.defeated_opponents and cosmetic bookkeeping.
@export var display_name: String = "" # Translation key, never literal text.
@export var aura_threshold: float = 0.0 # Story aura (design point 62) this opponent falls at.
@export var rank_reward: int = 0 # Flat rank granted on victory — never from farmed aura (point 62).
@export var coin_reward: int = 0
@export var cosmetic_id: String = "" # Transferred to the player on victory (points 16, 39).
@export var scene_id: String = "" # Which story location this fight belongs to (point 40).
@export var duel_duration: float = 90.0 # Seconds on the countdown for this fight (point 17); see CountdownTimer.default_duel_duration for the fallback when no opponent is set.
