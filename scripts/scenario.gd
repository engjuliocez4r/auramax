extends Resource
class_name Scenario
## Data-driven story-mode scenario (design points 16, 40, 63): one
## continuous duel across ROUND_COUNT rounds within a single location,
## ending in a boss fight. Rounds 1-9 are progress checkpoints inside the
## SAME confrontation, not individual named opponents — only the boss
## (round 10) has a name, a cosmetic and its own defeat ceremony.
## Difficulty is tuned by the INTERVAL between consecutive round_thresholds,
## never by the totals themselves — see the .tres instances under
## assets/data/scenarios/.

const ROUND_COUNT := 10

@export var id: String = "" # Stable key: used for GameState.completed_scenarios and cosmetic bookkeeping.
@export var display_name: String = "" # Translation key, never literal text.
@export var scene_id: String = "" # Which story location this scenario belongs to (point 40).

@export var boss_name: String = "" # Translation key for the round-10 boss.
@export var boss_cosmetic_id: String = "" # Transferred to the player on the boss defeat (points 16, 39).

## Story aura (point 62) at which each of the 10 rounds falls; index 9
## (round 10) is the boss. This default spacing is illustrative only — real
## scenarios set their own via the .tres instance.
@export var round_thresholds: Array[float] = [10000.0, 20000.0, 30000.0, 40000.0, 50000.0, 60000.0, 70000.0, 80000.0, 90000.0, 100000.0]

@export var round_taunts: Array[String] = [] # Translation keys, one per round 1-9 (indices 0-8) — spoken by the boss/announcer at that round's result screen. Round 10 uses the boss-defeat ceremony instead, never a taunt.

@export var ego_per_round: int = 0 # Flat ego granted at EVERY round, boss included (design point 62's anti-cheat rule: farmed aura never converts to ego).
@export var coin_per_round: int = 0 # Coins granted at EVERY round, not just the boss.

@export var round_duration: float = 90.0 # Seconds on the countdown for EACH round (point 17); resets every round, never shared across the scenario.
