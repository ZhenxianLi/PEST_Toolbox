# psychopy-pest

A [PsychoPy](https://www.psychopy.org) plugin that adds **PEST** (Parameter
Estimation by Sequential Testing; Taylor & Creelman, 1967) as
`psychopy.data.PestHandler`, alongside PsychoPy's own `StairHandler` and
`QuestHandler`.

> Taylor, M. M., & Creelman, C. D. (1967). PEST: Efficient estimates on
> probability functions. *The Journal of the Acoustical Society of America*,
> 41(4A), 782–787. https://doi.org/10.1121/1.1910407

It implements the same procedure as the MATLAB toolbox in this repository
and gives identical results: the Wald sequential test (or an optional
N-down/M-up rule), the five step-size rules, and termination when a reversal
would halve the step below the minimum. See the
[main README](https://github.com/ZhenxianLi/PEST_Toolbox#the-pest-procedure)
for the rules.

## Installation

In the Python environment that runs PsychoPy:

```bash
pip install "psychopy-pest @ git+https://github.com/ZhenxianLi/PEST_Toolbox#subdirectory=python"
```

In the PsychoPy app, open **Tools → Plugins/packages manager → Packages**
and install the same address, or run the command above in the app's
terminal.

## Usage with PsychoPy

```python
from psychopy import plugins
plugins.scanPlugins()             # find newly installed plugins
plugins.loadPlugin('psychopy-pest')
from psychopy import data

staircase = data.PestHandler(
    startVal=-20,         # intensity of the first trial
    startStepSize=8,
    minStepSize=1,        # run ends when a reversal halves the step below this
    maxStepSize=16,
    pThreshold=0.75,      # Wald test target
    waldLimit=1)

for intensity in staircase:          # stops when the PEST run ends
    isCorrect = runTrial(intensity)  # your trial code
    staircase.addResponse(isCorrect)

print(staircase.threshold)
staircase.saveAsExcel('pest_run.xlsx')
```

`PestHandler` is a subclass of `StairHandler`, so `addOtherData`, the
`saveAs*` methods and `ExperimentHandler.addLoop` work as usual. A correct
response steps the intensity **down**, and steps are linear: express the
intensity in the unit PEST should step in (for example, dB).

In Builder, enable the plugin in the plugin manager and create the handler in
a Code component.

## Usage without PsychoPy

The algorithm itself has no dependencies:

```python
from psychopy_pest import PEST

pest = PEST(initial_level=-20, initial_step_size=8, min_step_size=1)
while not pest.finished:
    pest.update(run_trial(pest.level))
print(pest.threshold, pest.history)
```

## Development

```bash
pip install -e ".[test]"
pytest
```

The handler tests run when PsychoPy is installed and are skipped otherwise.
[`examples/simulated_observer.py`](https://github.com/ZhenxianLi/PEST_Toolbox/blob/main/python/examples/simulated_observer.py) runs both classes against a simulated
observer.

Releasing new versions to PyPI and the listing in the PsychoPy plugin
manager are described in
[PUBLISHING.md](https://github.com/ZhenxianLi/PEST_Toolbox/blob/main/python/PUBLISHING.md).

## License

Non-commercial research and educational use only; see [LICENSE](https://github.com/ZhenxianLi/PEST_Toolbox/blob/main/LICENSE).
