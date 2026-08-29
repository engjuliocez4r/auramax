extends Resource
class_name Scenario
## Data-driven story-mode scenario: one continuous 10-round sequence within
## the same location against the same boss (design point 63), not a single
## duel against a stationary opponent (that's Opponent — scripts/opponent.gd,
## still the model actually driving the game right now).
##
## NOT YET WIRED UP. Nothing references this class yet — no other script may
## type against it (`: Scenario`, `-> Scenario`, `Array[Scenario]`) until
## Godot's editor has scanned it into global_script_class_cache.cfg, or the
## whole scene holding that reference fails to load (CLAUDE.md Rule 1). This
## step only creates the data.

@export var id: String = "" # Stable key, same role as Opponent.id.
@export var display_name: String = "" # Translation key, never literal text.
@export var scene_id: String = "" # Which story location this scenario belongs to (design point 40).
@export var boss_name: String = "" # Translation key. The boss is visible and commenting from round 1, not just at round 10 (design point 63).
@export var boss_cosmetic_id: String = "" # Transferred to the player only on round 10 — the scenario's one fixed art cost (design point 63).
@export var round_thresholds: Array[float] = [] # 10 entries, cumulative story aura per round within this scenario (design point 63). Built-in element type, not a custom class_name — safe under Rule 1.
@export var round_taunts: Array[String] = [] # 9 translation keys, one per round 1-9; round 10 gets its own boss-defeat ceremony instead of a taunt (design points 39, 63).
@export var ego_per_round: int = 0 # Flat permanent-progress reward for rounds 1-9. Does NOT escalate round by round — the payoff is deliberately concentrated in the boss instead (design points 62-63).
@export var coin_per_round: int = 0
@export var boss_ego_reward: int = 0 # Round 10 only: separate, larger than ego_per_round, alongside the cosmetic (design points 39, 62-63).
@export var boss_coin_reward: int = 0 # Round 10 only: separate, larger than coin_per_round (design point 63).
@export var round_duration: float = 90.0 # Seconds on the countdown per round (design point 17 — Super Mario World model, now per-ROUND, not per-scenario). Defaults to the current single-duel duration until this is wired up.
