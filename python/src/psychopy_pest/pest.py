"""PEST adaptive staircase (Taylor & Creelman, 1967).

This module has no dependencies and mirrors the MATLAB functions
``pestInit`` and ``pestUpdate`` in the ``toolbox`` folder of this repository.

Reference:
    Taylor, M. M., & Creelman, C. D. (1967). PEST: Efficient estimates on
    probability functions. J. Acoust. Soc. Am., 41(4A), 782-787.
    https://doi.org/10.1121/1.1910407
"""

import math

__all__ = ["PEST"]

_TOL = 1e-10


class PEST:
    """State of a PEST adaptive staircase.

    Read :attr:`level` to get the level of the next trial, pass the response
    to :meth:`update`, and stop when :attr:`finished` is true. :attr:`threshold`
    then holds the PEST estimate.

    The decision rule decides when to leave the current level. The size of
    each step follows the rules of Taylor and Creelman (1967):

    1. On every reversal of step direction, halve the step size.
    2. The second step in a given direction is the same size as the first.
    3. The fourth and subsequent steps in a given direction are each double
       their predecessor.
    4. The third step in a given direction is doubled, unless the step just
       before the most recent reversal resulted from a doubling.
    5. The step size never exceeds ``max_step_size``.

    The run ends when a reversal would halve the step below
    ``min_step_size``. The threshold estimate is the level the next trial
    would have used.

    A correct response makes the task harder, which PEST implements as a step
    *down* in level. Define the level so that lower values are harder (e.g.
    sound level in dB); negate it otherwise.

    Parameters
    ----------
    initial_level : float
        Stimulus level of the first trial.
    initial_step_size : float
        Size of the first step.
    min_step_size : float
        Final step size; ends the run (see above).
    max_step_size : float
        Upper limit on the step size.
    min_level, max_level : float
        Bounds of the stimulus level.
    max_trials : int or None
        Safety limit on the number of trials. ``None`` means no limit.
    decision_rule : {'wald', 'updown'}
        ``'wald'`` uses the sequential test of the original PEST. ``'updown'``
        uses a simplified N-down/M-up rule instead.
    target_probability : float
        Probability of a correct response the run converges to ('wald' only).
    wald_limit : float
        Deviation limit W of the sequential test ('wald' only).
    down_criterion : int
        N consecutive correct responses for a step down ('updown' only).
    up_criterion : int
        M consecutive incorrect responses for a step up ('updown' only).

    Examples
    --------
    >>> pest = PEST(initial_level=-20, initial_step_size=8)
    >>> while not pest.finished:
    ...     is_correct = present_trial(pest.level)  # doctest: +SKIP
    ...     pest.update(is_correct)                 # doctest: +SKIP
    """

    def __init__(self, initial_level=0.0, initial_step_size=8.0,
                 min_step_size=1.0, max_step_size=32.0,
                 min_level=-math.inf, max_level=math.inf, max_trials=None,
                 decision_rule="wald", target_probability=0.75,
                 wald_limit=1.0, down_criterion=2, up_criterion=1):
        if decision_rule not in ("wald", "updown"):
            raise ValueError("decision_rule must be 'wald' or 'updown'.")
        for name, value in (("initial_step_size", initial_step_size),
                            ("min_step_size", min_step_size),
                            ("max_step_size", max_step_size),
                            ("wald_limit", wald_limit)):
            if not value > 0:
                raise ValueError(f"{name} must be positive.")
        if min_step_size > max_step_size:
            raise ValueError("min_step_size must not exceed max_step_size.")
        if not min_step_size <= initial_step_size <= max_step_size:
            raise ValueError(
                "initial_step_size must lie between min_step_size and "
                "max_step_size.")
        if not min_level < max_level:
            raise ValueError("min_level must be smaller than max_level.")
        if not (math.isfinite(initial_level)
                and min_level <= initial_level <= max_level):
            raise ValueError(
                "initial_level must be finite and lie between min_level and "
                "max_level.")
        if not 0 < target_probability < 1:
            raise ValueError("target_probability must lie in (0, 1).")
        if max_trials is not None and not (
                int(max_trials) == max_trials and max_trials >= 1):
            raise ValueError("max_trials must be a positive integer or None.")
        for name, value in (("down_criterion", down_criterion),
                            ("up_criterion", up_criterion)):
            if not (int(value) == value and value >= 1):
                raise ValueError(f"{name} must be a positive integer.")

        self.min_step_size = min_step_size
        self.max_step_size = max_step_size
        self.min_level = min_level
        self.max_level = max_level
        self.max_trials = max_trials
        self.decision_rule = decision_rule
        self.target_probability = target_probability
        self.wald_limit = wald_limit
        self.down_criterion = int(down_criterion)
        self.up_criterion = int(up_criterion)

        self.level = float(initial_level)  # level of the next trial
        self.step_size = float(initial_step_size)
        self.finished = False
        self.threshold = math.nan          # set when the run ends
        self.n_trials = 0
        self.n_reversals = 0

        # Sequential test at the current level
        self._n_trials_at_level = 0
        self._n_correct_at_level = 0
        self._n_consecutive_correct = 0
        self._n_consecutive_incorrect = 0

        # Step-size rules
        self._last_direction = 0           # +1 up, -1 down, 0 no step yet
        self._n_steps_same_direction = 0
        self._last_step_was_doubled = False
        self._skip_third_doubling = False

        # One entry per trial
        self.history = {
            "level": [],        # level presented
            "is_correct": [],
            "direction": [],    # step taken after the trial: +1, -1 or 0
            "step_size": [],    # size of that step (0 if none)
            "is_reversal": [],
        }

    def update(self, is_correct):
        """Record the response to the trial presented at :attr:`level`.

        Parameters
        ----------
        is_correct : bool or {0, 1}
            ``True`` for a correct (or "detected") response.

        Returns
        -------
        PEST
            ``self``, so that calls can be chained.
        """
        if self.finished:
            raise RuntimeError(
                "The run has finished; create a new PEST to start another.")
        if is_correct not in (0, 1):  # also accepts True/False
            raise ValueError("is_correct must be a bool or 0/1.")
        is_correct = bool(is_correct)
        presented_level = self.level

        self.n_trials += 1
        direction = self._decide_direction(is_correct)

        step_size = 0.0
        is_reversal = False
        if direction != 0:
            is_reversal = (self._last_direction != 0
                           and direction != self._last_direction)
            if is_reversal:
                self.n_reversals += 1
                step_size = self.step_size / 2                      # rule 1
                self._skip_third_doubling = self._last_step_was_doubled  # rule 4
                self._n_steps_same_direction = 1
                is_doubled = False
                if step_size < self.min_step_size:
                    self.finished = True
            else:
                self._n_steps_same_direction += 1
                n = self._n_steps_same_direction
                is_doubled = n >= 4 or (                              # rule 3
                    n == 3 and not self._skip_third_doubling)
                if is_doubled:
                    step_size = min(2 * self.step_size,
                                    self.max_step_size)               # rule 5
                else:
                    step_size = self.step_size                        # rule 2
                is_doubled = step_size > self.step_size

            self.level = min(max(presented_level + direction * step_size,
                                 self.min_level), self.max_level)
            self.step_size = step_size
            self._last_direction = direction
            self._last_step_was_doubled = is_doubled

        if self.max_trials is not None and self.n_trials >= self.max_trials:
            self.finished = True
        if self.finished:
            self.threshold = self.level

        self.history["level"].append(presented_level)
        self.history["is_correct"].append(is_correct)
        self.history["direction"].append(direction)
        self.history["step_size"].append(step_size)
        self.history["is_reversal"].append(is_reversal)
        return self

    def _decide_direction(self, is_correct):
        """Return -1 (step down), +1 (step up) or 0 (stay at this level)."""
        direction = 0
        if self.decision_rule == "wald":
            # Sequential test: leave the level once the number of correct
            # responses deviates from the expected number by at least W.
            self._n_trials_at_level += 1
            self._n_correct_at_level += is_correct
            deviation = (self._n_correct_at_level
                         - self.target_probability * self._n_trials_at_level)
            if deviation >= self.wald_limit - _TOL:
                direction = -1
            elif deviation <= -self.wald_limit + _TOL:
                direction = 1
            if direction != 0:
                self._n_trials_at_level = 0
                self._n_correct_at_level = 0
        else:
            if is_correct:
                self._n_consecutive_correct += 1
                self._n_consecutive_incorrect = 0
            else:
                self._n_consecutive_incorrect += 1
                self._n_consecutive_correct = 0
            if self._n_consecutive_correct >= self.down_criterion:
                direction = -1
            elif self._n_consecutive_incorrect >= self.up_criterion:
                direction = 1
            if direction != 0:
                self._n_consecutive_correct = 0
                self._n_consecutive_incorrect = 0
        return direction
