function state = pestUpdate(state, isCorrect)
%PESTUPDATE Update a PEST staircase with the response to one trial.
%   STATE = PESTUPDATE(STATE, ISCORRECT) records the response to the trial
%   presented at STATE.level and returns the updated state. ISCORRECT is
%   true for a correct (or "detected") response.
%
%   The decision rule (see PESTINIT) decides whether the level changes.
%   When it does, the size of the step follows the rules of Taylor and
%   Creelman (1967):
%     1. On every reversal of step direction, halve the step size.
%     2. The second step in a given direction is the same size as the first.
%     3. The fourth and subsequent steps in a given direction are each
%        double their predecessor.
%     4. The third step in a given direction is doubled, unless the step
%        just before the most recent reversal resulted from a doubling.
%     5. The step size never exceeds MaxStepSize.
%   The run ends when a reversal would halve the step below MinStepSize.
%   The threshold estimate is the level the next trial would have used.
%
%   Example:
%     state = pestInit('InitialLevel', 10);
%     state = pestUpdate(state, true);
%
%   See also PESTINIT, PESTPLOT.

%   Copyright (c) 2025 Zhenxian Li

if state.isFinished
    error('pest:runFinished', 'The run has finished; call pestInit to start a new one.');
end
if ~(isscalar(isCorrect) && (islogical(isCorrect) || isnumeric(isCorrect)) ...
        && (isCorrect == 0 || isCorrect == 1))
    error('pest:invalidResponse', 'isCorrect must be a logical scalar or 0/1.');
end
isCorrect = logical(isCorrect);
opts = state.options;
presentedLevel = state.level;

state.nTrials = state.nTrials + 1;
[direction, state] = decideDirection(state, isCorrect);

stepSize = 0;
isReversal = false;
if direction ~= 0
    isReversal = state.lastDirection ~= 0 && direction ~= state.lastDirection;
    if isReversal
        state.nReversals = state.nReversals + 1;
        stepSize = state.stepSize / 2;                                   % rule 1
        state.skipThirdDoubling = state.lastStepWasDoubled;              % rule 4
        state.nStepsSameDirection = 1;
        isDoubled = false;
        if stepSize < opts.MinStepSize
            state.isFinished = true;
        end
    else
        state.nStepsSameDirection = state.nStepsSameDirection + 1;
        isDoubled = state.nStepsSameDirection >= 4 ...                   % rule 3
            || (state.nStepsSameDirection == 3 && ~state.skipThirdDoubling);
        if isDoubled
            stepSize = min(2 * state.stepSize, opts.MaxStepSize);        % rule 5
        else
            stepSize = state.stepSize;                                   % rule 2
        end
        isDoubled = stepSize > state.stepSize;
    end

    state.level = min(max(presentedLevel + direction * stepSize, opts.MinLevel), ...
        opts.MaxLevel);
    state.stepSize = stepSize;
    state.lastDirection = direction;
    state.lastStepWasDoubled = isDoubled;
end

if state.nTrials >= opts.MaxTrials
    state.isFinished = true;
end
if state.isFinished
    state.threshold = state.level;
end

state.history.level(end + 1) = presentedLevel;
state.history.isCorrect(end + 1) = isCorrect;
state.history.direction(end + 1) = direction;
state.history.stepSize(end + 1) = stepSize;
state.history.isReversal(end + 1) = isReversal;
end

function [direction, state] = decideDirection(state, isCorrect)
% Return -1 (step down), +1 (step up) or 0 (stay at this level).
opts = state.options;
direction = 0;
switch opts.DecisionRule
    case 'wald'
        % Sequential test: leave the level once the number of correct
        % responses deviates from the expected number by at least W.
        state.nTrialsAtLevel = state.nTrialsAtLevel + 1;
        state.nCorrectAtLevel = state.nCorrectAtLevel + isCorrect;
        deviation = state.nCorrectAtLevel ...
            - opts.TargetProbability * state.nTrialsAtLevel;
        tol = 1e-10;
        if deviation >= opts.WaldLimit - tol
            direction = -1;
        elseif deviation <= -opts.WaldLimit + tol
            direction = 1;
        end
        if direction ~= 0
            state.nTrialsAtLevel = 0;
            state.nCorrectAtLevel = 0;
        end
    case 'updown'
        if isCorrect
            state.nConsecutiveCorrect = state.nConsecutiveCorrect + 1;
            state.nConsecutiveIncorrect = 0;
        else
            state.nConsecutiveIncorrect = state.nConsecutiveIncorrect + 1;
            state.nConsecutiveCorrect = 0;
        end
        if state.nConsecutiveCorrect >= opts.DownCriterion
            direction = -1;
        elseif state.nConsecutiveIncorrect >= opts.UpCriterion
            direction = 1;
        end
        if direction ~= 0
            state.nConsecutiveCorrect = 0;
            state.nConsecutiveIncorrect = 0;
        end
end
end
