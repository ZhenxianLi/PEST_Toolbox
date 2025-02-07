# PEST: Parameter Estimation by Sequential Testing (Non-Commercial)

This repository contains a MATLAB implementation of the PEST (Parameter Estimation by Sequential Testing) algorithm based on the paper:

> **PEST: Efficient Estimates on Probability Functions**  
> M. M. Taylor & C. D. Creelman, *Journal of the Acoustical Society of America*, 41, 782–787 (1967)  
> [DOI:10.1121/1.1910407](https://doi.org/10.1121/1.1910407)

The code is designed for rapid and efficient psychophysical threshold estimation. Although the original implementation was used for speed perception experiments, this version has been adapted to measure a loudness threshold using a 440 Hz sine tone. It uses an adaptive staircase procedure (N-down/M-up + PEST) to converge on a target threshold.

## Repository Contents

- **updateDiff_NdownMup.m**  
  The main PEST function that implements the adaptive algorithm. It updates the stimulus level (e.g., loudness level in dB) and the step size based on participant responses according to the PEST rules.

- **demo_loudness_threshold_and_plot.m**  
  A combined demonstration script that:
  1. Presents a 440 Hz tone with amplitude scaled according to the current stimulus level.
  2. Collects participant responses (e.g., “heard” or “not heard”).
  3. Updates the stimulus level using the PEST function.
  4. Saves and plots the staircase results.

- **LICENSE**  
  A non-commercial license under which this code is released (see below).

## How to Use

1. **Prerequisites:**  
   Ensure that MATLAB (or Octave) is installed and that `updateDiff_PEST.m` is on your MATLAB path.

2. **Running the Demo:**  
   Open MATLAB, navigate to the repository folder, and run:
   ```matlab
   demo_loudness_threshold_and_plot
The script will run an experiment where a 440 Hz tone is played repeatedly with adaptive amplitude scaling. After the experiment, a plot of the staircase (loudness level vs. trial index) is displayed, and the results are saved to a .mat file.
	3.	Customizing the Code:
You may modify parameters such as the down/up criteria, initial stimulus level, step sizes, and number of trials to suit your experimental design.

Citation

If you use this code in your research, please cite the original paper:

	Taylor, M. M., & Creelman, C. D. (1967). PEST: Efficient Estimates on Probability Functions. The Journal of the Acoustical Society of America, 41(3), 782–787. https://doi.org/10.1121/1.1910407

License

This software is released under the Non-Commercial License (see LICENSE). Use of this code is permitted only for non-commercial research and educational purposes. Commercial use is strictly prohibited without prior written consent from the copyright holder.
