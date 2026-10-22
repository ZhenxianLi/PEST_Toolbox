function state = pestInit(varargin)
%PESTINIT Create the state of a PEST adaptive staircase.
%   STATE = PESTINIT() returns a staircase state with default settings.
%
%   STATE = PESTINIT(Name, Value, ...) overrides the defaults with the
%   following options:
%
%   Staircase
%     'InitialLevel'      - Stimulus level of the first trial. Default 0.
%     'InitialStepSize'   - Size of the first step. Default 8.
%     'MinStepSize'       - Final step size. The run ends when a reversal
%                           would halve the step below this value
%                           (Taylor & Creelman, 1967). Default 1.
%     'MaxStepSize'       - Upper limit on the step size. Default 32.
%     'MinLevel'          - Lower bound of the stimulus level. Default -Inf.
%     'MaxLevel'          - Upper bound of the stimulus level. Default Inf.
%     'MaxTrials'         - Safety limit on the number of trials. Default Inf.
%
%   Decision rule (when to leave the current level)
%     'DecisionRule'      - 'wald' (default) uses the sequential test of the
%                           original PEST. 'updown' uses a simplified
%                           N-down/M-up rule instead.
%     'TargetProbability' - Probability of a correct response the run
%                           converges to ('wald' only). Default 0.75.
%     'WaldLimit'         - Deviation limit W of the sequential test
%                           ('wald' only). Default 1.
%     'DownCriterion'     - N consecutive correct responses for a step
%                           down ('updown' only). Default 2.
%     'UpCriterion'       - M consecutive incorrect responses for a step
%                           up ('updown' only). Default 1.
%
%   A correct response makes the task harder, which PEST implements as a
%   step DOWN in level. Define the level so that lower values are harder
%   (e.g. sound level in dB); negate it otherwise.
%
%   STATE is a struct. Read STATE.level to get the level of the next trial,
%   pass the response to PESTUPDATE, and stop when STATE.isFinished is
%   true. STATE.threshold then holds the PEST estimate.
%
%   Example:
%     state = pestInit('InitialLevel', -20, 'InitialStepSize', 8);
%     while ~state.isFinished
%         isCorrect = presentTrial(state.level);
%         state = pestUpdate(state, isCorrect);
%     end
%     fprintf('Threshold: %.2f\n', state.threshold);
%
%   Reference:
%     Taylor, M. M., & Creelman, C. D. (1967). PEST: Efficient estimates on
%     probability functions. J. Acoust. Soc. Am., 41(4), 782-787.
%     https://doi.org/10.1121/1.1910407
%
%   See also PESTUPDATE, PESTPLOT.

%   Copyright (c) 2025 Zhenxian Li

p = inputParser;
p.FunctionName = 'pestInit';
isScalarNum = @(x) isnumeric(x) && isscalar(x) && isreal(x) && ~isnan(x);
isPositive = @(x) isScalarNum(x) && x > 0;
isCount = @(x) isScalarNum(x) && x >= 1 && x == fix(x);

p.addParameter('InitialLevel', 0, @(x) isScalarNum(x) && isfinite(x));
p.addParameter('InitialStepSize', 8, isPositive);
p.addParameter('MinStepSize', 1, isPositive);
p.addParameter('MaxStepSize', 32, isPositive);
p.addParameter('MinLevel', -Inf, isScalarNum);
p.addParameter('MaxLevel', Inf, isScalarNum);
p.addParameter('MaxTrials', Inf, @(x) isPositive(x) && (isinf(x) || x == fix(x)));
p.addParameter('DecisionRule', 'wald', @(x) ischar(x) || (isstring(x) && isscalar(x)));
p.addParameter('TargetProbability', 0.75, @(x) isScalarNum(x) && x > 0 && x < 1);
p.addParameter('WaldLimit', 1, isPositive);
p.addParameter('DownCriterion', 2, isCount);
p.addParameter('UpCriterion', 1, isCount);
p.parse(varargin{:});
opts = p.Results;

opts.DecisionRule = validatestring(char(opts.DecisionRule), {'wald', 'updown'}, ...
    'pestInit', 'DecisionRule');
if opts.MinStepSize > opts.MaxStepSize
    error('pest:invalidStepSize', 'MinStepSize must not exceed MaxStepSize.');
end
if opts.InitialStepSize < opts.MinStepSize || opts.InitialStepSize > opts.MaxStepSize
    error('pest:invalidStepSize', ...
        'InitialStepSize must lie between MinStepSize and MaxStepSize.');
end
if opts.MinLevel >= opts.MaxLevel
    error('pest:invalidLevel', 'MinLevel must be smaller than MaxLevel.');
end
if opts.InitialLevel < opts.MinLevel || opts.InitialLevel > opts.MaxLevel
    error('pest:invalidLevel', 'InitialLevel must lie between MinLevel and MaxLevel.');
end

state.options = opts;

% Public read-only fields
state.level = opts.InitialLevel;   % level of the next trial
state.stepSize = opts.InitialStepSize;
state.isFinished = false;
state.threshold = NaN;             % PEST estimate, set when the run ends
state.nTrials = 0;
state.nReversals = 0;

% Sequential test at the current level
state.nTrialsAtLevel = 0;
state.nCorrectAtLevel = 0;
state.nConsecutiveCorrect = 0;
state.nConsecutiveIncorrect = 0;

% Step-size rules
state.lastDirection = 0;           % +1 up, -1 down, 0 no step yet
state.nStepsSameDirection = 0;
state.lastStepWasDoubled = false;
state.skipThirdDoubling = false;

% One entry per trial
state.history = struct( ...
    'level', zeros(1, 0), ...      % level presented
    'isCorrect', false(1, 0), ...
    'direction', zeros(1, 0), ...  % step taken after the trial: +1, -1 or 0
    'stepSize', zeros(1, 0), ...   % size of that step (0 if none)
    'isReversal', false(1, 0));
end
