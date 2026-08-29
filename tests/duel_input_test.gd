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
