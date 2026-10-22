"""Tests for the PEST algorithm; mirror tests/testPest.m of the MATLAB toolbox."""

import math
import random

import pytest

from psychopy_pest import PEST


def run(pest, responses):
    for r in responses:
        pest.update(r)
    return pest


def updown(**kwargs):
    """Up/down 1/1 makes every response a step, isolating the step rules."""
    return PEST(decision_rule="updown", down_criterion=1, up_criterion=1,
                **kwargs)


def test_initial_state_uses_the_options():
    pest = PEST(initial_level=10, initial_step_size=4)
    assert pest.level == 10
    assert pest.step_size == 4
    assert not pest.finished
    assert math.isnan(pest.threshold)
    assert pest.n_trials == 0 and pest.n_reversals == 0


def test_wald_leaves_level_only_when_deviation_reaches_w():
    # With Pt = 0.75 and W = 1, four correct responses in a row are needed
    # to step down, and two incorrect responses to step up.
    pest = PEST(initial_level=0, target_probability=0.75, wald_limit=1)
    for _ in range(3):
        pest.update(True)
        assert pest.level == 0
    pest.update(True)
    assert pest.level == -8
    pest.update(False)
    assert pest.level == -8
    pest.update(False)
    assert pest.level == -4  # reversal halves the step


def test_wald_with_mixed_responses_at_one_level():
    # C C C I C C C: deviation stays below 1; the next C gives Nc = 7,
    # T = 8, deviation 1, step down.
    pest = run(PEST(initial_level=0), [1, 1, 1, 0, 1, 1, 1])
    assert pest.level == 0
    pest.update(True)
    assert pest.level == -8


def test_step_rules_with_doubling_before_reversal():
    pest = run(updown(initial_level=0, initial_step_size=8, max_step_size=64),
               [1, 1, 1, 1, 0, 0, 0, 0])
    # Down: 8, 8 (rule 2), 16 (third step doubled), 32 (rule 3).
    # Up after reversal: 16 (rule 1), 16 (rule 2), 16 (third step NOT
    # doubled, because the step before the reversal was a doubling,
    # rule 4), 32 (rule 3).
    assert pest.history["step_size"] == [8, 8, 16, 32, 16, 16, 16, 32]
    assert pest.history["level"] == [0, -8, -16, -32, -64, -48, -32, -16]
    assert pest.level == 16
    assert pest.history["is_reversal"] == [False] * 4 + [True] + [False] * 3
    assert pest.n_reversals == 1


def test_step_rule_4_without_doubling_before_reversal():
    pest = run(updown(initial_level=0, initial_step_size=8, max_step_size=64),
               [1, 1, 0, 0, 0, 0])
    assert pest.history["step_size"] == [8, 8, 4, 4, 8, 16]


def test_step_size_never_exceeds_max():
    pest = run(updown(initial_step_size=8, max_step_size=20), [1] * 6)
    assert pest.history["step_size"] == [8, 8, 16, 20, 20, 20]


def test_run_ends_when_step_would_fall_below_min():
    pest = updown(initial_level=0, initial_step_size=2, min_step_size=1)
    pest.update(True)    # down 2 -> -2
    pest.update(False)   # reversal, up 1 -> -1
    assert not pest.finished
    pest.update(True)    # reversal, 0.5 < min_step_size
    assert pest.finished
    assert pest.threshold == -1.5  # level the next trial would have used
    assert pest.n_reversals == 2
    with pytest.raises(RuntimeError):
        pest.update(True)


def test_max_trials_ends_the_run():
    pest = run(PEST(initial_level=0, max_trials=3), [1, 1, 1])
    assert pest.finished
    assert pest.threshold == pest.level
    assert pest.n_trials == 3


def test_level_stays_within_bounds():
    pest = updown(initial_level=-5, initial_step_size=8, max_level=0)
    pest.update(False)
    assert pest.level == 0
    pest = updown(initial_level=5, initial_step_size=8, min_level=0)
    pest.update(True)
    assert pest.level == 0


def test_updown_counters_reset_on_opposite_response():
    pest = run(PEST(decision_rule="updown", down_criterion=2, up_criterion=2,
                    initial_level=0), [1, 0, 1, 0, 1, 0])
    assert pest.level == 0
    assert all(d == 0 for d in pest.history["direction"])


def test_history_records_presented_level():
    pest = updown(initial_level=0, initial_step_size=4)
    pest.update(True)
    assert pest.history["level"][0] == 0
    assert pest.history["direction"][0] == -1
    assert pest.level == -4


@pytest.mark.parametrize("kwargs", [
    {"initial_step_size": 0.5, "min_step_size": 1},
    {"initial_level": 10, "max_level": 0},
    {"decision_rule": "quest"},
    {"target_probability": 1},
    {"max_trials": 0},
])
def test_invalid_options_are_rejected(kwargs):
    with pytest.raises(ValueError):
        PEST(**kwargs)


def test_invalid_response_is_rejected():
    with pytest.raises(ValueError):
        PEST().update(2)


def test_converges_to_target_of_simulated_observer():
    rng = random.Random(1)
    true_threshold, slope = -30, 0.5
    offset = math.log((0.75 - 0.5) / (1 - 0.75))

    def p_correct(x):
        return 0.5 + 0.5 / (1 + math.exp(-(slope * (x - true_threshold)
                                           + offset)))

    estimates = []
    for _ in range(200):
        pest = PEST(initial_level=0, initial_step_size=8, min_step_size=0.5,
                    max_step_size=16, target_probability=0.75,
                    max_trials=1000)
        while not pest.finished:
            pest.update(rng.random() < p_correct(pest.level))
        estimates.append(pest.threshold)
    mean = sum(estimates) / len(estimates)
    assert abs(mean - true_threshold) < 1.5
