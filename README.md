# PEST Toolbox

[![CI](https://github.com/ZhenxianLi/PEST_Toolbox/actions/workflows/ci.yml/badge.svg)](https://github.com/ZhenxianLi/PEST_Toolbox/actions/workflows/ci.yml)

A MATLAB/GNU Octave implementation of **PEST** (Parameter Estimation by
Sequential Testing), the adaptive staircase of Taylor & Creelman (1967), for
fast psychophysical threshold estimation. A Python version is included as a
[PsychoPy plugin](#psychopy-plugin).

> Taylor, M. M., & Creelman, C. D. (1967). PEST: Efficient estimates on
> probability functions. *The Journal of the Acoustical Society of America*,
> 41(4A), 782–787. https://doi.org/10.1121/1.1910407

## The PEST procedure

**When to change level.** Trials stay at one level until a sequential
(Wald) test says the level is too easy or too hard. After `T` trials with
`Nc` correct responses at the current level, with target probability `Pt`
and deviation limit `W`:

- `Nc - Pt*T >= W`  → too easy, step **down**;
- `Nc - Pt*T <= -W` → too hard, step **up**;
- otherwise present another trial at the same level.

A simplified N-down/M-up rule is also available (`'DecisionRule', 'updown'`).

**How big a step.**

1. On every reversal of step direction, halve the step size.
2. The second step in a given direction is the same size as the first.
3. The fourth and subsequent steps in a given direction are each double
   their predecessor.
4. The third step in a given direction is doubled, unless the step just
   before the most recent reversal resulted from a doubling.
5. The step size never exceeds a maximum.

**When to stop.** The run ends when a reversal would halve the step below the
final (minimum) step size. The threshold estimate is the level the next trial
would have used.

## Installation

Clone the repository and add the `toolbox` folder to the path:

```matlab
addpath(fullfile(pwd, 'toolbox'))
```

Requires MATLAB R2016b or later, or GNU Octave 7 or later. No other toolboxes
are needed.

## Usage

```matlab
state = pestInit( ...
    'InitialLevel', -20, ...
    'InitialStepSize', 8, ...
    'MinStepSize', 1, ...
    'MaxStepSize', 16, ...
    'TargetProbability', 0.75, ...
    'WaldLimit', 1);

while ~state.isFinished
    isCorrect = presentTrial(state.level);   % your experiment code
    state = pestUpdate(state, isCorrect);
end

fprintf('Threshold: %.2f\n', state.threshold);
pestPlot(state);
```

A correct response makes the task harder, which PEST implements as a step
**down** in level. Define the level so that lower values are harder (for
example, sound level in dB); negate it otherwise.

Run `help pestInit` for all options. `state.history` records the level,
response, step and reversal of every trial.

## Examples

Both examples are in `toolbox/examples`:

- `demoSimulatedObserver` runs PEST against a simulated observer, with no
  hardware or responses needed.
- `demoLoudnessThreshold` measures the yes/no detection threshold of a 440 Hz
  tone in dB re full scale. Use headphones and fix the system volume first.

## PsychoPy plugin

The [`python`](python) folder contains `psychopy-pest`, a PsychoPy plugin that
adds the same procedure as `psychopy.data.PestHandler`, plus a
dependency-free `PEST` class. It gives identical results to the MATLAB
functions. Install it into the Python environment that runs PsychoPy:

```bash
pip install "psychopy-pest @ git+https://github.com/ZhenxianLi/PEST_Toolbox#subdirectory=python"
```

See [`python/README.md`](python/README.md) for usage, and
[`python/PUBLISHING.md`](python/PUBLISHING.md) for how it is released to PyPI
and submitted to the PsychoPy plugin registry.

## Tests

In MATLAB:

```matlab
addpath('toolbox'); runtests('tests')
```

In Octave:

```matlab
addpath(fullfile(pwd, 'toolbox')); run(fullfile(pwd, 'tests', 'testPest.m'))
```

Python (from the `python` folder):

```bash
pip install -e ".[test]" && pytest
```

## Citation

If you use this toolbox, please cite the original paper above. Citation
metadata for the toolbox itself is in [`CITATION.cff`](CITATION.cff).

## License

Released under a non-commercial license; see [`LICENSE`](LICENSE). Use is
permitted for non-commercial research and educational purposes only.
