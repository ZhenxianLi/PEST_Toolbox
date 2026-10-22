"""Run PEST against a simulated observer, with and without PsychoPy.

A simulated observer answers according to a logistic psychometric function,
and PEST tracks the level at which the observer is correct 75% of the time.
"""

import math
import random

from psychopy_pest import PEST

TRUE_THRESHOLD = -30.0  # level at which p(correct) = 0.75
SLOPE = 0.5
GUESS_RATE = 0.5        # two-alternative forced choice
_OFFSET = math.log((0.75 - GUESS_RATE) / (1 - 0.75))


def p_correct(level):
    return GUESS_RATE + (1 - GUESS_RATE) / (
        1 + math.exp(-(SLOPE * (level - TRUE_THRESHOLD) + _OFFSET)))


def run_plain():
    """The PEST class needs nothing but Python."""
    pest = PEST(initial_level=0, initial_step_size=8, min_step_size=0.5,
                max_step_size=16, target_probability=0.75, max_trials=500)
    while not pest.finished:
        pest.update(random.random() < p_correct(pest.level))
    print(f"PEST:        {pest.threshold:6.2f} after {pest.n_trials} trials")


def run_psychopy():
    """The same run through the PsychoPy plugin."""
    try:
        from psychopy import plugins
    except ImportError:
        print("PsychoPy is not installed; skipping PESTHandler.")
        return
    plugins.scanPlugins()  # find plugins installed since PsychoPy started
    plugins.loadPlugin("psychopy-pest")
    from psychopy import data

    staircase = data.PESTHandler(startVal=0, startStepSize=8, minStepSize=0.5,
                                 maxStepSize=16, targetProb=0.75,
                                 maxTrials=500, autoLog=False)
    for intensity in staircase:
        staircase.addResponse(int(random.random() < p_correct(intensity)))
    print(f"PESTHandler: {staircase.threshold:6.2f} after "
          f"{len(staircase.data)} trials")


if __name__ == "__main__":
    print(f"True threshold: {TRUE_THRESHOLD:.2f}")
    run_plain()
    run_psychopy()
