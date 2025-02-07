    % Author: Z.LI
    % Date:   2025-02-05

function [newDiff, newStepSize, directionThisStep, reversalFlag, ...
          consecutiveCorrect, consecutiveIncorrect, prevDirection, nReversals, nReversalsInMiniStep, stepSizeWanted, ...
          consecutiveSameDirSteps, skipDoubleNextTime] = ...
    updateDiff_PEST(isCorrect, oldDiff, oldStepSize, ...
                        downCriterion, upCriterion, ...
                        consecutiveCorrect, consecutiveIncorrect, ...
                        prevDirection, nReversals, nReversalsInMiniStep, stepSizeWanted, ...
                        minStepSize, maxStepSize, ...
                        consecutiveSameDirSteps, skipDoubleNextTime)
% updateDiff_NdownMup - Use "N-down / M-up" plus PEST rules to update stimulus difference and step size.
%
% PEST main rules:
% 1) Each time a reversal occurs, halve the step size (but not below minStepSize).
% 2) If this step is in the same direction as the previous one, keep the step size unchanged, unless rule 3 applies.
% 3) Starting from the 3rd consecutive step in the same direction, double the step size each time (until reversal), with an exception in rule 4.
% 4) If the step size was just doubled and a reversal happens immediately, skip one doubling next time you reach the 3rd consecutive step in the same direction.
% 5) The step size must not exceed maxStepSize.
%
% Inputs:
%   isCorrect                - Boolean indicating whether the participant's response was correct (or "detected").
%   oldDiff                  - The previous stimulus difference or current stimulus level (e.g. loudness, speed difference, etc.).
%   oldStepSize              - The previous step size.
%   downCriterion            - N for N-down criterion (e.g. 3-down).
%   upCriterion              - M for M-up criterion (e.g. 1-up).
%   consecutiveCorrect       - Count of consecutive correct responses so
%   far.w
%   consecutiveIncorrect     - Count of consecutive incorrect responses so far.
%   prevDirection            - The previous movement direction: 'up' | 'down' | 'none'.
%   nReversals               - The current number of reversals so far.
%   nReversalsInMiniStep     - The count of reversals that have occurred at or below the desired stepSizeWanted.
%   stepSizeWanted           - A reference step size threshold used to track nReversalsInMiniStep (not altering logic itself).
%   minStepSize              - The minimum allowed step size.
%   maxStepSize              - The maximum allowed step size.
%   consecutiveSameDirSteps  - How many consecutive steps have occurred in the same direction (up or down).
%   skipDoubleNextTime       - Whether to skip one doubling if a reversal occurred immediately after a doubling.
%
% Outputs:
%   newDiff                  - Updated stimulus difference/level for the next trial.
%   newStepSize              - Updated step size for the next trial.
%   directionThisStep        - 'up', 'down', or 'none' if no update occurred this time.
%   reversalFlag             - Boolean indicating whether a reversal happened this trial.
%   consecutiveCorrect       - Updated consecutive correct count.
%   consecutiveIncorrect     - Updated consecutive incorrect count.
%   prevDirection            - Updated direction for use on the next call.
%   nReversals               - Updated total reversal count.
%   nReversalsInMiniStep     - Updated count of reversals at or below stepSizeWanted.
%   stepSizeWanted           - Passed through unchanged, for continuity.
%   consecutiveSameDirSteps  - Updated consecutive same-direction step count.
%   skipDoubleNextTime       - Possibly updated skip flag for next doubling.
%
% No functional changes have been made; only comments are translated into English.
% ------------------------------------------------------------------------------

% ========== Initialization ==========
newDiff             = oldDiff;
newStepSize         = oldStepSize;
directionThisStep   = 'none';
reversalFlag        = false;

% ========== (1) Update counters of correct/incorrect ==========
if isCorrect
    consecutiveCorrect   = consecutiveCorrect + 1;
else
    consecutiveIncorrect = consecutiveIncorrect + 1;
    consecutiveCorrect   = 0;  % reset correct counter if response was incorrect
end

% ========== (2) Check if down/up trigger conditions are met ==========
stepMade = false;
if consecutiveCorrect >= downCriterion
    % Down
    newDiff           = oldDiff - oldStepSize; 
    directionThisStep = 'down';
    consecutiveCorrect = 0;
    stepMade = true;

elseif consecutiveIncorrect >= upCriterion
    % Up
    newDiff              = oldDiff + oldStepSize;
    directionThisStep    = 'up';
    consecutiveIncorrect = 0;
    stepMade = true;
end

% ========== (3) If a step was made, check reversals & adjust step size ==========
if stepMade
    % Check for reversal (opposite to previous direction)
    if ~strcmp(prevDirection, 'none') && ~strcmp(directionThisStep, prevDirection)
        % Reversal occurred
        reversalFlag = true;
        nReversals   = nReversals + 1;
        fprintf('   *** Reversal! Count=%d ***\n', nReversals);

        % Check if we are at or below stepSizeWanted
        if abs(oldStepSize) <= abs(stepSizeWanted)
            nReversalsInMiniStep = nReversalsInMiniStep + 1;
        end

        % Rule 1: Halve step size on reversal
        newStepSize = floor(oldStepSize * 0.5);
        if newStepSize < minStepSize
            newStepSize = minStepSize;
        end

        % Rule 4: If the old step was doubled (>=2x newStepSize), skip doubling next time
        if abs(oldStepSize) >= 2 * abs(newStepSize)
            skipDoubleNextTime = true;
        end

        % Reset same-direction step count to 1
        consecutiveSameDirSteps = 1;

    else
        % No reversal (same direction as previous, or prevDirection='none')
        reversalFlag = false;

        if strcmp(directionThisStep, prevDirection)
            % Continue counting same-direction steps
            consecutiveSameDirSteps = consecutiveSameDirSteps + 1;
        else
            consecutiveSameDirSteps = 1;
        end

        % Rule 2: same direction => keep old step size
        newStepSize = oldStepSize;

        % Rule 3: starting from the 3rd consecutive step in the same direction, double the step size
        % unless skipDoubleNextTime is true (then skip once)
        if consecutiveSameDirSteps >= 3
            if ~skipDoubleNextTime
                newStepSize = min(maxStepSize, oldStepSize * 2);
            else
                skipDoubleNextTime = false;
            end
        end
    end

    % Update prevDirection
    prevDirection = directionThisStep;

    % Ensure step size does not exceed maxStepSize
    if abs(newStepSize) > abs(maxStepSize)
        newStepSize = maxStepSize;
    end

    % Ensure step size is not zero
    if abs(newStepSize) ==0
        newStepSize = newStepSize+0.1*oldStepSize;
    end

else
    % No movement => directionThisStep = 'none'
    directionThisStep = 'none';
    % Do not update prevDirection
end

end