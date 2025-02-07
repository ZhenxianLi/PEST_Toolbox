function demo_loudness_threshold_and_plot()
    % demo_loudness_threshold_and_plot - A combined demo that runs a loudness
    % threshold experiment using a 440 Hz tone with an N-down/M-up + PEST procedure,
    % saves the staircase results, and then plots the loudness levels across trials.
    %
    % The stimulus level (interpreted in dB) is adjusted based on participant responses.
    % After the experiment, the staircase result is plotted.
    %
    % Author: Z.LI
    % Date:   2025-02-05

    clc; clear; close all;

    %% Experiment Parameters
    downCriterion     = 2;   % e.g., 2-down
    upCriterion       = 1;   % e.g., 1-up
    initialDiff       = 40;  % initial loudness level (dB-like)
    initialStepSize   = 4;   % initial step size (dB)
    minStepSize       = 1;   % minimum allowed step size
    maxStepSize       = 32;  % maximum allowed step size
    stepSizeWanted    = 2;   % reference for counting reversals at or below a given step size

    maxTrials         = 30;  % maximum number of trials
    maxReversals      = 6;   % stop experiment after this many reversals

    %% Initialize staircase variables
    currentDiff             = initialDiff;     % current stimulus level (dB-like)
    currentStepSize         = initialStepSize;
    consecutiveCorrect      = 0;
    consecutiveIncorrect    = 0;
    prevDirection           = 'none';
    nReversals              = 0;
    nReversalsInMiniStep    = 0;
    consecutiveSameDirSteps = 1;
    skipDoubleNextTime      = false;

    % Prepare a structure array to store trial results
    resultsArray = struct('trialIndex', {}, 'loudnessLevel', {}, 'stepSize', {}, ...
                          'response', {}, 'direction', {}, 'reversalFlag', {});

    %% Tone Generation (Outside the Loop)
    fs       = 44100;           % Sampling frequency (Hz)
    duration = 0.5;             % Tone duration in seconds
    t        = 0:1/fs:duration;  % Time vector
    baseTone = sin(2*pi*440*t);  % Generate a 440 Hz sine wave
    refLevel_dB = 40;           % Reference dB level for amplitude scaling

    %% Main Trial Loop
    for trialIndex = 1:maxTrials
        if nReversals >= maxReversals
            fprintf('Reached maximum reversals (%d). Stopping experiment early.\n', maxReversals);
            break;
        end

        % Compute amplitude scaling based on currentDiff (interpreted as dB relative to refLevel_dB)
        amplitude = 10^((currentDiff - refLevel_dB)/20);
        amplitude = min(amplitude, 1.0);  % Clamp amplitude to 1.0 to prevent clipping
        soundData = amplitude * baseTone;

        fprintf('Trial %d: Playing 440 Hz tone, "level" = %.1f dB (amplitude = %.3f)\n', ...
            trialIndex, currentDiff, amplitude);

        % Play the tone and pause for its duration
        sound(soundData, fs);
        pause(duration);

        % Collect user response via keyboard input
        userResp = input('  Did you hear it? (1 = yes, 0 = no, ENTER = no): ', 's');
        if isempty(userResp)
            userResp = '0';
        end
        isCorrect = (userResp == '1');  % '1' indicates a positive (heard) response

        % Backup current values
        oldDiff = currentDiff;
        oldStepSize = currentStepSize;

        % Call the PEST update function (updateDiff_NdownMup must be in your path)
        [currentDiff, currentStepSize, dirStep, revFlag, ...
         consecutiveCorrect, consecutiveIncorrect, prevDirection, nReversals, ...
         nReversalsInMiniStep, stepSizeWanted, consecutiveSameDirSteps, skipDoubleNextTime] = ...
            updateDiff_PEST(isCorrect, oldDiff, oldStepSize, ...
                                downCriterion, upCriterion, ...
                                consecutiveCorrect, consecutiveIncorrect, ...
                                prevDirection, nReversals, nReversalsInMiniStep, stepSizeWanted, ...
                                minStepSize, maxStepSize, ...
                                consecutiveSameDirSteps, skipDoubleNextTime);

        % Store the trial result
        resultsArray(trialIndex).trialIndex    = trialIndex;
        resultsArray(trialIndex).loudnessLevel = currentDiff;
        resultsArray(trialIndex).stepSize      = currentStepSize;
        resultsArray(trialIndex).response      = userResp;
        resultsArray(trialIndex).direction     = dirStep;
        resultsArray(trialIndex).reversalFlag  = revFlag;

        % Print trial feedback
        fprintf('  Response = %s, direction = %s, new level = %.1f dB, step size = %.1f\n', ...
                userResp, dirStep, currentDiff, currentStepSize);
        if revFlag
            fprintf('  (Reversal #%d)\n', nReversals);
        end
        fprintf('\n');
    end

    %% Save the Results (Optional)
    resultsFileName = sprintf('StaircaseResult_%s_Loudness.mat', datestr(now, 'yyyy_mm_dd__HH_MM_SS'));
    save(resultsFileName, 'resultsArray');
    fprintf('Results saved to %s\n', resultsFileName);

    %% Plot the Staircase Results
    figure('Name','Staircase Loudness Threshold','Color','w');
    hold on; grid on;

    nTrials = numel(resultsArray);
    loudnessLevels = [resultsArray.loudnessLevel];

    % Plot the staircase data
    plot(1:nTrials, loudnessLevels, '-o', 'LineWidth', 1.5, 'DisplayName', 'Loudness Level');

    % Plot a reference line at 40 dB
    yline(40, '--r', 'LineWidth', 1.5, 'DisplayName', 'Reference = 40 dB');

    xlabel('Trial Index', 'FontSize', 12);
    ylabel('Loudness Level (dB)', 'FontSize', 12);
    title('Staircase Loudness Threshold', 'FontSize', 14);
    xlim([1, nTrials]);
    legend('Location','best','Interpreter','none');
    hold off;

    fprintf('Experiment finished. Estimated threshold ~ %.1f dB (last level)\n', currentDiff);
end