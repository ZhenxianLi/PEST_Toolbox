"""Tests for the PsychoPy plugin; skipped when PsychoPy is not installed."""

import math

import pytest

pytest.importorskip("psychopy.data")

from psychopy import data, plugins  # noqa: E402

from psychopy_pest import PEST, PESTHandler  # noqa: E402


def test_plugin_registers_handler_in_psychopy_data():
    plugins.scanPlugins()
    assert plugins.loadPlugin("psychopy-pest")
    assert data.PESTHandler is PESTHandler


def test_handler_is_a_stair_handler():
    assert issubclass(PESTHandler, data.StairHandler)


def test_handler_follows_the_pest_algorithm():
    responses = [1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 1, 0]
    kwargs = dict(startVal=0, startStepSize=8, minStepSize=1, maxStepSize=32)
    handler = PESTHandler(**kwargs, autoLog=False)
    pest = PEST(initial_level=0, initial_step_size=8, min_step_size=1,
                max_step_size=32)

    presented = []
    # zip pulls the response first, so no extra trial is started at the end.
    for response, intensity in zip(responses, handler):
        presented.append(intensity)
        handler.addResponse(response)
        pest.update(response)

    assert presented == pest.history["level"]
    assert handler.intensities == pest.history["level"]
    assert handler.data == responses
    assert handler.stepSizeCurrent == pest.step_size
    reversal_trials = [i for i, r in enumerate(pest.history["is_reversal"]) if r]
    assert handler.reversalPoints == reversal_trials
    assert handler.reversalIntensities == [pest.history["level"][i]
                                           for i in reversal_trials]


def test_iteration_stops_when_run_finishes():
    handler = PESTHandler(startVal=0, startStepSize=2, minStepSize=1,
                          decisionRule="updown", nDown=1, nUp=1,
                          autoLog=False)
    responses = iter([1, 0, 1])
    n = 0
    for _ in handler:
        handler.addResponse(next(responses))
        n += 1
    assert n == 3
    assert handler.finished
    assert handler.threshold == -1.5


def test_threshold_is_nan_until_finished():
    handler = PESTHandler(startVal=0, autoLog=False)
    next(handler)
    handler.addResponse(1)
    assert math.isnan(handler.threshold)


def test_custom_intensity_replaces_presented_level():
    handler = PESTHandler(startVal=0, startStepSize=4, decisionRule="updown",
                          nDown=1, nUp=1, autoLog=False)
    next(handler)
    handler.addResponse(1, intensity=10)
    assert handler.intensities == [10]
    assert handler.intensity == 6


def test_saves_like_a_stair_handler(tmp_path):
    handler = PESTHandler(startVal=0, maxTrials=5, autoLog=False)
    for _ in handler:
        handler.addResponse(1)
    handler.saveAsText(str(tmp_path / "run.tsv"))
    handler.saveAsPickle(str(tmp_path / "run"))
    assert (tmp_path / "run.tsv").exists()
    assert (tmp_path / "run.psydat").exists()
