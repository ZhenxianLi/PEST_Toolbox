"""PsychoPy trial handler for the PEST staircase."""

import math

from psychopy.data import StairHandler

from .pest import PEST

__all__ = ["PestHandler"]


class PestHandler(StairHandler):
    """PEST staircase (Taylor & Creelman, 1967) as a PsychoPy trial handler.

    Use it like :class:`psychopy.data.StairHandler`: iterate over it to get
    the intensity of each trial, and call :meth:`addResponse` after each
    trial. Iteration stops when the PEST run ends; :attr:`threshold` then
    holds the estimate. Saving (``saveAsText``, ``saveAsExcel``,
    ``saveAsPickle``) and :class:`~psychopy.data.ExperimentHandler`
    integration are inherited from ``StairHandler``.

    Steps are linear: express the intensity in the unit you want PEST to
    step in (e.g. dB). A correct response steps the intensity *down*.

    Parameters
    ----------
    startVal : float
        Intensity of the first trial.
    startStepSize : float
        Size of the first step.
    minStepSize : float
        Final step size. The run ends when a reversal would halve the step
        below this value.
    maxStepSize : float
        Upper limit on the step size.
    decisionRule : {'wald', 'updown'}
        ``'wald'`` (default) uses the sequential test of the original PEST;
        ``'updown'`` uses an N-down/M-up rule.
    pThreshold : float
        Probability of a correct response the run converges to ('wald').
    waldLimit : float
        Deviation limit W of the sequential test ('wald').
    nDown, nUp : int
        Consecutive correct / incorrect responses for a step ('updown').
    maxTrials : int or None
        Safety limit on the number of trials.
    minVal, maxVal : float or None
        Bounds of the intensity.
    extraInfo, originPath, name, autoLog :
        As for :class:`psychopy.data.StairHandler`.

    Examples
    --------
    ::

        from psychopy import plugins
        plugins.scanPlugins()
        plugins.loadPlugin('psychopy-pest')
        from psychopy import data

        staircase = data.PestHandler(startVal=-20, startStepSize=8,
                                     minStepSize=1, maxStepSize=16)
        for intensity in staircase:
            isCorrect = runTrial(intensity)
            staircase.addResponse(isCorrect)
        print(staircase.threshold)
    """

    def __init__(self, startVal, startStepSize=8, minStepSize=1,
                 maxStepSize=32, decisionRule="wald", pThreshold=0.75,
                 waldLimit=1, nDown=2, nUp=1, maxTrials=None,
                 minVal=None, maxVal=None, extraInfo=None, originPath=None,
                 name="", autoLog=True, **kwargs):
        self._pest = PEST(
            initial_level=startVal,
            initial_step_size=startStepSize,
            min_step_size=minStepSize,
            max_step_size=maxStepSize,
            min_level=-math.inf if minVal is None else minVal,
            max_level=math.inf if maxVal is None else maxVal,
            max_trials=maxTrials,
            decision_rule=decisionRule,
            target_probability=pThreshold,
            wald_limit=waldLimit,
            down_criterion=nDown,
            up_criterion=nUp)
        super().__init__(
            startVal, stepSizes=startStepSize, nUp=nUp, nDown=nDown,
            applyInitialRule=False, extraInfo=extraInfo, stepType="lin",
            minVal=minVal, maxVal=maxVal, originPath=originPath, name=name,
            autoLog=autoLog, **kwargs)
        self._nextIntensity = self._pest.level
        self.decisionRule = decisionRule
        self.pThreshold = pThreshold
        self.waldLimit = waldLimit
        self.minStepSize = minStepSize
        self.maxStepSize = maxStepSize
        self.maxTrials = maxTrials

    @property
    def threshold(self):
        """PEST threshold estimate; NaN until the run has finished."""
        return self._pest.threshold

    @property
    def pest(self):
        """The underlying :class:`~psychopy_pest.PEST` state."""
        return self._pest

    def addResponse(self, result, intensity=None):
        """Add a 1 or 0 to signify a correct / detected or incorrect / missed
        trial.

        Supplying an `intensity` value here indicates that you did not use
        the recommended intensity in your last trial; PEST then continues
        from the intensity you supplied.
        """
        self.data.append(result)
        if intensity is not None:
            self.intensities[-1] = intensity
            self._pest.level = float(intensity)
        if self.getExp() is not None:
            self.getExp().addData(self.name + ".response", result)
        self.calculateNextIntensity()

    def calculateNextIntensity(self):
        """Update PEST with the last response and set the next intensity."""
        pest = self._pest
        pest.update(self.data[-1])
        history = pest.history
        if history["is_reversal"][-1]:
            self.reversalPoints.append(self.thisTrialN)
            self.reversalIntensities.append(self.intensities[-1])
        if history["direction"][-1] != 0:
            self.currentDirection = "down" if history["direction"][-1] < 0 else "up"
        self.stepSizeCurrent = pest.step_size
        self._nextIntensity = pest.level
        self.finished = pest.finished
