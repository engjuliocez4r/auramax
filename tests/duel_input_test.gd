extends Node
## Permanent regression suite for the duel's tap/streak/aura/burst/orb rules
## (CLAUDE.md Rule 12). Every test instantiates a fresh scenes/duel.tscn,
## adds it to the tree, and waits at least one real frame before asserting
## anything — instantiating a scene and calling into it immediately does NOT
## run _ready(), so signal connections aren't live yet and a test could pass
## for the wrong reason (see CLAUDE.md Rule 12's technical pitfall).
##
## Taps are simulated by emitting the zone's real gui_input signal — the same
## signal a genuine touch or click reaches — never by calling _handle_tap()
## or _is_tap_press() directly, so these tests exercise the path a player
## actually takes.
##
## Run headlessly:
##   "<godot binary>" --headless --path "<project root>" res://tests/duel_input_test.tscn
## (see CLAUDE.md Rule 12 for the exact command used in this project).

const DUEL_SCENE := preload("res://scenes/duel.tscn")

var _fail_count := 0
var _total_count := 0


func _ready() -> void:
	await _run_all_tests()
	print("")
	print("%d/%d tests passed" % [_total_count - _fail_count, _total_count])
	get_tree().quit(1 if _fail_count > 0 else 0)


func _run_all_tests() -> void:
	await _test_every_valid_tap_grants_aura_immediately()
	await _test_hammering_one_side_grants_aura_only_once()
	await _test_completed_pair_increments_streak_by_one()
	await _test_lone_tap_does_not_increment_streak()
	await _test_timeout_reset_clears_last_side()
	await _test_same_side_reset_preserves_last_side()
	await _test_streak_resets_on_clock_without_input()
	await _test_orbs_begin_at_tap_threshold_not_pair_threshold()
	await _test_streak_reset_never_reduces_burst_meter()
	await _test_burst_multiplies_aura_while_active()
	await _test_streak_67_reward_adds_bonus_time_once()
	await _test_streak_67_reward_fires_only_once_per_round()
	await _test_streak_67_reward_available_again_next_round()
	await _test_streak_67_reward_not_granted_on_early_reset()


# ─── Harness ────────────────────────────────────────────────────────────

func _make_duel() -> Node:
	var duel := DUEL_SCENE.instantiate()
	add_child(duel)
	await get_tree().process_frame
	return duel


func _free_duel(duel: Node) -> void:
	duel.queue_free()


func _simulate_tap(zone: Control) -> void:
	var event := InputEventScreenTouch.new()
	event.pressed = true
	zone.gui_input.emit(event)


func _check(condition: bool, description: String) -> void:
	_total_count += 1
	if condition:
		print("PASS - %s" % description)
	else:
		_fail_count += 1
		print("FAIL - %s" % description)


# ─── Tests ──────────────────────────────────────────────────────────────

func _test_every_valid_tap_grants_aura_immediately() -> void:
	var duel := await _make_duel()
	var left: Control = duel.get_node("LeftZone")
	var right: Control = duel.get_node("RightZone")

	var before_left: float = duel._current_aura
	_simulate_tap(left)
	var after_left: float = duel._current_aura
	_check(after_left > before_left, "[Every tap grants aura] tap 1 (left) increases aura immediately, before any pair completes")

	_simulate_tap(right)
	var after_right: float = duel._current_aura
	_check(after_right > after_left, "[Every tap grants aura] tap 2 (right) increases aura again, on top of tap 1")

	_free_duel(duel)


func _test_hammering_one_side_grants_aura_only_once() -> void:
	var duel := await _make_duel()
	var left: Control = duel.get_node("LeftZone")

	var increases := 0
	var previous: float = duel._current_aura
	for i in range(5):
		_simulate_tap(left)
		var current: float = duel._current_aura
		if current > previous:
			increases += 1
		previous = current

	_check(increases == 1, "[Hammer one side] aura increased exactly once across 5 same-side taps (got %d increases) — regression guard for the timeout/same-side reset collision" % increases)

	_free_duel(duel)


func _test_completed_pair_increments_streak_by_one() -> void:
	var duel := await _make_duel()
	var left: Control = duel.get_node("LeftZone")
	var right: Control = duel.get_node("RightZone")

	_check(duel._streak == 0, "[Pair -> streak] streak starts at 0")
	_simulate_tap(left)
	_simulate_tap(right)
	_check(duel._streak == 1, "[Pair -> streak] one completed alternating pair sets streak to exactly 1 (got %d)" % duel._streak)

	_free_duel(duel)


func _test_lone_tap_does_not_increment_streak() -> void:
	var duel := await _make_duel()
	var left: Control = duel.get_node("LeftZone")

	_simulate_tap(left)
	_check(duel._streak == 0, "[Lone tap] streak stays 0 after a single unpaired tap (got %d)" % duel._streak)
	_check(duel._pair_pending, "[Lone tap] a pair is left pending after the first tap")

	_free_duel(duel)


func _test_timeout_reset_clears_last_side() -> void:
	var duel := await _make_duel()
	var left: Control = duel.get_node("LeftZone")

	_simulate_tap(left)
	_check(duel._current_aura > 0.0, "[Timeout reset] first tap grants aura")

	await get_tree().create_timer(duel.streak_timeout + 0.25).timeout

	var before: float = duel._current_aura
	_simulate_tap(left)
	_check(duel._current_aura > before, "[Timeout reset] the SAME side tapped again after streak_timeout still grants aura — a fresh start on any side, per DESIGN.md point 60")

	_free_duel(duel)


func _test_same_side_reset_preserves_last_side() -> void:
	var duel := await _make_duel()
	var left: Control = duel.get_node("LeftZone")

	_simulate_tap(left)
	_check(duel._last_side == "left", "[Same-side reset] last side recorded as 'left' after the first tap")

	_simulate_tap(left) # rejected: same side twice in a row
	_check(duel._last_side == "left", "[Same-side reset] last side is still 'left' after a rejected same-side repeat — must NOT be cleared, or hammering would grant aura on every other tap")

	_free_duel(duel)


func _test_streak_resets_on_clock_without_input() -> void:
	var duel := await _make_duel()
	var left: Control = duel.get_node("LeftZone")
	var right: Control = duel.get_node("RightZone")

	_simulate_tap(left)
	_simulate_tap(right)
	_check(duel._streak == 1, "[Clock reset] streak built to 1 before waiting")

	await get_tree().create_timer(duel.streak_timeout + 0.25).timeout
	# No tap here — _process()'s _check_streak_timeout() must reset on its own.

	_check(duel._streak == 0, "[Clock reset] streak reset to 0 purely from elapsed time, with no further input")

	_free_duel(duel)


func _test_orbs_begin_at_tap_threshold_not_pair_threshold() -> void:
	var duel := await _make_duel()
	var left: Control = duel.get_node("LeftZone")
	var right: Control = duel.get_node("RightZone")

	var threshold: int = duel.orb_tap_threshold
	for i in range(threshold):
		_simulate_tap(left if i % 2 == 0 else right)

	_check(duel._tap_count >= threshold, "[Orb threshold] tap count reached orb_tap_threshold (%d taps)" % threshold)
	_check(duel._streak < threshold, "[Orb threshold] completed pairs (%d) are still BELOW the threshold value — proves the gate counts taps, not pairs" % duel._streak)

	# Confirm the gate is actually live through the real _process() loop, not
	# just by reading the counters: once past threshold, _update_orb_spawning()
	# stops zeroing _orb_spawn_accumulator every frame and lets it grow.
	await get_tree().process_frame
	await get_tree().process_frame
	_check(duel._orb_spawn_accumulator > 0.0, "[Orb threshold] the orb spawn accumulator is actively growing once the tap threshold is reached")

	_free_duel(duel)


func _test_streak_reset_never_reduces_burst_meter() -> void:
	var duel := await _make_duel()
	var left: Control = duel.get_node("LeftZone")
	var right: Control = duel.get_node("RightZone")

	var pairs_for_first_milestone: int = duel.milestone_schedule.threshold_for_index(0)
	for i in range(pairs_for_first_milestone):
		_simulate_tap(left)
		_simulate_tap(right)

	var burst_before: float = duel.burst_meter
	_check(burst_before > 0.0, "[Burst is savings] the first milestone banked burst progress (%.2f)" % burst_before)

	# Break the streak via a same-side repeat.
	_simulate_tap(left)
	_simulate_tap(left)
	_check(duel._streak == 0, "[Burst is savings] streak actually reset to 0")
	_check(is_equal_approx(duel.burst_meter, burst_before), "[Burst is savings] burst meter is unchanged by the streak reset (still %.2f)" % duel.burst_meter)

	_free_duel(duel)


func _test_burst_multiplies_aura_while_active() -> void:
	var duel := await _make_duel()
	var left: Control = duel.get_node("LeftZone")
	var right: Control = duel.get_node("RightZone")

	# Milestones land every milestone_size pairs and bank burst_per_milestone
	# each time; enough milestones fill burst_meter to 1.0 and flip
	# is_bursting on. Derived from the duel's own exports (mirroring
	# _check_milestones()'s own accumulation), not hardcoded, so this stays
	# correct if those values are ever retuned.
	var milestones_needed := 0
	var meter := 0.0
	while meter < 1.0:
		meter += duel.burst_per_milestone
		milestones_needed += 1
	var pairs_needed: int = duel.milestone_schedule.threshold_for_index(milestones_needed - 1)

	for i in range(pairs_needed - 1):
		_simulate_tap(left)
		_simulate_tap(right)
	_check(not duel.is_bursting, "[Burst multiplier] burst not yet active before the final milestone pair")

	# Final pair: its second tap crosses the milestone and flips is_bursting,
	# but _grant_aura() for that same tap already ran with is_bursting still
	# false (duel.gd _handle_tap grants aura before completing the pair), so
	# this delta is still a valid "burst inactive" baseline. By this point
	# streak is well past 20, so the streak_bonus_step*max_bonus cap is
	# already saturated identically for this tap and the next one — isolating
	# burst_multiplier as the only remaining difference between them.
	_simulate_tap(left)
	var before_b: float = duel._current_aura
	_simulate_tap(right)
	var delta_non_burst: float = duel._current_aura - before_b
	_check(duel.is_bursting, "[Burst multiplier] burst becomes active exactly as the meter fills")

	var before_c: float = duel._current_aura
	_simulate_tap(left)
	var delta_burst: float = duel._current_aura - before_c

	_check(is_equal_approx(delta_burst, delta_non_burst * duel.burst_multiplier), "[Burst multiplier] aura from a tap during burst (%.2f) equals a non-burst tap's aura (%.2f) times burst_multiplier (%.1f)" % [delta_burst, delta_non_burst, duel.burst_multiplier])

	_free_duel(duel)


# ─── 67-streak signature reward (CLAUDE.md task: bonus time + rising labels
# + animated clock absorption) ────────────────────────────────────────────
# The actual bonus lands at the clock animation's MERGE beat, not the instant
# the streak hits 67 (see duel.gd _on_streak_67_clock_fusion()) — so every
# test here waits out hold_duration + merge_duration (plus a small buffer)
# before reading the countdown, per CLAUDE.md Rule 12's real-frame/real-timer
# requirement.

const STREAK_67_TARGET_PAIRS := 67 # Mirrors duel.gd's own STREAK_67_TARGET, kept as a literal here since that const is deliberately not an @export (see duel.gd).


func _reach_streak_67(left: Control, right: Control) -> void:
	for i in range(STREAK_67_TARGET_PAIRS):
		_simulate_tap(left)
		_simulate_tap(right)


func _await_clock_fusion(duel: Node) -> void:
	await get_tree().create_timer(duel.clock_bonus_hold_duration + duel.clock_bonus_merge_duration + 0.3).timeout


func _test_streak_67_reward_adds_bonus_time_once() -> void:
	var duel := await _make_duel()
	var left: Control = duel.get_node("LeftZone")
	var right: Control = duel.get_node("RightZone")
	var timer_node := duel.get_node("CountdownTimer")

	var before: float = timer_node.seconds_left
	_reach_streak_67(left, right)
	_check(duel._streak == STREAK_67_TARGET_PAIRS, "[67 streak] streak reached exactly %d after %d completed pairs" % [STREAK_67_TARGET_PAIRS, STREAK_67_TARGET_PAIRS])

	await _await_clock_fusion(duel)
	var after: float = timer_node.seconds_left
	var delta := after - before

	# The countdown only ever ticks DOWN on its own (a fraction of a second
	# of natural decay across this wait), so a net increase this large can
	# only be the bonus landing, and it can never exceed the bonus itself.
	_check(delta > 30.0 and delta <= duel.streak_67_bonus_seconds + 0.1, "[67 streak] countdown increased by streak_67_bonus_seconds (%.2f) once the clock animation fuses — net change was %.2f (before %.2f, after %.2f)" % [duel.streak_67_bonus_seconds, delta, before, after])

	_free_duel(duel)


func _test_streak_67_reward_fires_only_once_per_round() -> void:
	var duel := await _make_duel()
	var left: Control = duel.get_node("LeftZone")
	var right: Control = duel.get_node("RightZone")
	var timer_node := duel.get_node("CountdownTimer")

	_reach_streak_67(left, right)
	await _await_clock_fusion(duel)
	var after_first_bonus: float = timer_node.seconds_left

	# Keep going well past 67 in the SAME round — just far enough to prove
	# the event doesn't repeat as the streak keeps climbing.
	for i in range(50):
		_simulate_tap(left)
		_simulate_tap(right)
	await _await_clock_fusion(duel)
	var after_continuing: float = timer_node.seconds_left

	_check(after_continuing <= after_first_bonus + 0.05, "[67 streak] continuing the streak past 67 (now %d) in the same round must not add another bonus — countdown only decreased (%.2f -> %.2f)" % [duel._streak, after_first_bonus, after_continuing])
	_check(duel._streak_67_fired_this_round, "[67 streak] the fired-this-round flag stays true after continuing past 67")

	_free_duel(duel)


func _test_streak_67_reward_available_again_next_round() -> void:
	# A real round change reloads the whole scene (see result_screen.gd's
	# _on_continue_pressed) — a fresh duel.gd instance whose
	# _streak_67_fired_this_round starts false again. Using two separate
	# instances here is the faithful equivalent of that, and avoids calling
	# _setup_story_round() a second time on one instance, which would
	# re-run its (pre-existing, unrelated to this feature) CountdownTimer
	# signal wiring a second time.
	var duel_round_1 := await _make_duel()
	var left_1: Control = duel_round_1.get_node("LeftZone")
	var right_1: Control = duel_round_1.get_node("RightZone")
	var timer_1 := duel_round_1.get_node("CountdownTimer")

	var before_1: float = timer_1.seconds_left
	_reach_streak_67(left_1, right_1)
	await _await_clock_fusion(duel_round_1)
	var after_1: float = timer_1.seconds_left
	_check(after_1 - before_1 > 30.0, "[67 streak] round 1: the bonus lands on a fresh duel instance (%.2f -> %.2f)" % [before_1, after_1])
	_free_duel(duel_round_1)

	var duel_round_2 := await _make_duel()
	var left_2: Control = duel_round_2.get_node("LeftZone")
	var right_2: Control = duel_round_2.get_node("RightZone")
	var timer_2 := duel_round_2.get_node("CountdownTimer")

	_check(not duel_round_2._streak_67_fired_this_round, "[67 streak] round 2: a new duel instance starts with the reward available again")
	var before_2: float = timer_2.seconds_left
	_reach_streak_67(left_2, right_2)
	await _await_clock_fusion(duel_round_2)
	var after_2: float = timer_2.seconds_left
	_check(after_2 - before_2 > 30.0, "[67 streak] round 2: the bonus fires again on the new instance, proving the reward is available on a new round (%.2f -> %.2f)" % [before_2, after_2])

	_free_duel(duel_round_2)


func _test_streak_67_reward_not_granted_on_early_reset() -> void:
	var duel := await _make_duel()
	var left: Control = duel.get_node("LeftZone")
	var right: Control = duel.get_node("RightZone")

	for i in range(30):
		_simulate_tap(left)
		_simulate_tap(right)
	_check(duel._streak == 30, "[67 streak] streak built partway to 30 before the reset, well short of 67")

	# Same-side repeat reset, well short of the target.
	_simulate_tap(left)
	_simulate_tap(left)
	_check(duel._streak == 0, "[67 streak] streak actually reset to 0 before reaching 67")

	await _await_clock_fusion(duel)
	_check(not duel._streak_67_fired_this_round, "[67 streak] the fired-this-round flag never gets set from a streak that reset before reaching 67")

	_free_duel(duel)
