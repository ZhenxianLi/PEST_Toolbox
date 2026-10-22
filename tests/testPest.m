% Tests for the PEST toolbox.
% Run with runtests('tests') in MATLAB, or run this script in Octave with
% the toolbox folder on the path.

%% Initial state uses the options
state = pestInit('InitialLevel', 10, 'InitialStepSize', 4);
assert(state.level == 10);
assert(state.stepSize == 4);
assert(~state.isFinished);
assert(isnan(state.threshold));
assert(state.nTrials == 0 && state.nReversals == 0);

%% Wald test leaves the level only when the deviation reaches W
% With Pt = 0.75 and W = 1, four correct responses in a row are needed to
% step down, and two incorrect responses to step up.
state = pestInit('InitialLevel', 0, 'TargetProbability', 0.75, 'WaldLimit', 1);
for k = 1:3
    state = pestUpdate(state, true);
    assert(state.level == 0);
end
state = pestUpdate(state, true);
assert(state.level == -8);
state = pestUpdate(state, false);
assert(state.level == -8);
state = pestUpdate(state, false);
assert(state.level == -4);   % reversal halves the step

%% Wald test with mixed responses at one level
% Pt = 0.75, W = 1: after C C C I the deviation is 0, so stay; one more
% C C C gives Nc = 6, T = 7, deviation 0.75, stay; the next C gives
% Nc = 7, T = 8, deviation 1, step down.
state = pestInit('InitialLevel', 0, 'TargetProbability', 0.75, 'WaldLimit', 1);
responses = logical([1 1 1 0 1 1 1]);
for r = responses
    state = pestUpdate(state, r);
end
assert(state.level == 0);
state = pestUpdate(state, true);
assert(state.level == -8);

%% Step-size rules 1 to 4 (doubling before the reversal)
% Up/down 1/1 makes every response a step, isolating the step-size rules.
state = pestInit('DecisionRule', 'updown', 'DownCriterion', 1, 'UpCriterion', 1, ...
    'InitialLevel', 0, 'InitialStepSize', 8, 'MinStepSize', 1, 'MaxStepSize', 64);
responses = logical([1 1 1 1 0 0 0 0]);
for r = responses
    state = pestUpdate(state, r);
end
% Down: 8, 8 (rule 2), 16 (third step doubled), 32 (rule 3).
% Up after reversal: 16 (rule 1), 16 (rule 2), 16 (third step NOT doubled,
% because the step before the reversal was a doubling, rule 4), 32 (rule 3).
assert(isequal(state.history.stepSize, [8 8 16 32 16 16 16 32]));
assert(isequal(state.history.level, [0 -8 -16 -32 -64 -48 -32 -16]));
assert(state.level == 16);
assert(isequal(state.history.isReversal, logical([0 0 0 0 1 0 0 0])));
assert(state.nReversals == 1);

%% Step-size rule 4 (no doubling before the reversal)
state = pestInit('DecisionRule', 'updown', 'DownCriterion', 1, 'UpCriterion', 1, ...
    'InitialLevel', 0, 'InitialStepSize', 8, 'MinStepSize', 1, 'MaxStepSize', 64);
responses = logical([1 1 0 0 0 0]);
for r = responses
    state = pestUpdate(state, r);
end
% Down 8, 8; up 4, 4, then the third step is doubled (8) and the fourth
% doubled again (16).
assert(isequal(state.history.stepSize, [8 8 4 4 8 16]));

%% Step size never exceeds MaxStepSize
state = pestInit('DecisionRule', 'updown', 'DownCriterion', 1, 'UpCriterion', 1, ...
    'InitialStepSize', 8, 'MaxStepSize', 20);
for k = 1:6
    state = pestUpdate(state, true);
end
assert(isequal(state.history.stepSize, [8 8 16 20 20 20]));

%% Run ends when a reversal would halve the step below MinStepSize
state = pestInit('DecisionRule', 'updown', 'DownCriterion', 1, 'UpCriterion', 1, ...
    'InitialLevel', 0, 'InitialStepSize', 2, 'MinStepSize', 1);
state = pestUpdate(state, true);    % down 2 -> -2
state = pestUpdate(state, false);   % reversal, up 1 -> -1
assert(~state.isFinished);
state = pestUpdate(state, true);    % reversal, 0.5 < MinStepSize
assert(state.isFinished);
assert(state.threshold == -1.5);    % level the next trial would have used
assert(state.nReversals == 2);
try
    pestUpdate(state, true);
    error('test:noError', 'Expected an error.');
catch err
    assert(strcmp(err.identifier, 'pest:runFinished'));
end

%% MaxTrials ends the run
state = pestInit('InitialLevel', 0, 'MaxTrials', 3);
for k = 1:3
    state = pestUpdate(state, true);
end
assert(state.isFinished);
assert(state.threshold == state.level);
assert(state.nTrials == 3);

%% Level stays within MinLevel and MaxLevel
state = pestInit('DecisionRule', 'updown', 'DownCriterion', 1, 'UpCriterion', 1, ...
    'InitialLevel', -5, 'InitialStepSize', 8, 'MaxLevel', 0);
state = pestUpdate(state, false);
assert(state.level == 0);
state = pestInit('DecisionRule', 'updown', 'DownCriterion', 1, 'UpCriterion', 1, ...
    'InitialLevel', 5, 'InitialStepSize', 8, 'MinLevel', 0);
state = pestUpdate(state, true);
assert(state.level == 0);

%% Up/down counters reset on the opposite response
% With 2-down/2-up, C I C I must never step.
state = pestInit('DecisionRule', 'updown', 'DownCriterion', 2, 'UpCriterion', 2, ...
    'InitialLevel', 0);
for r = logical([1 0 1 0 1 0])
    state = pestUpdate(state, r);
end
assert(state.level == 0);
assert(all(state.history.direction == 0));

%% History records the presented level, not the next one
state = pestInit('DecisionRule', 'updown', 'DownCriterion', 1, 'UpCriterion', 1, ...
    'InitialLevel', 0, 'InitialStepSize', 4);
state = pestUpdate(state, true);
assert(state.history.level(1) == 0);
assert(state.history.direction(1) == -1);
assert(state.level == -4);

%% Invalid input is rejected
state = pestInit();
try
    pestUpdate(state, 2);
    error('test:noError', 'Expected an error.');
catch err
    assert(strcmp(err.identifier, 'pest:invalidResponse'));
end
try
    pestInit('InitialStepSize', 0.5, 'MinStepSize', 1);
    error('test:noError', 'Expected an error.');
catch err
    assert(strcmp(err.identifier, 'pest:invalidStepSize'));
end
try
    pestInit('InitialLevel', 10, 'MaxLevel', 0);
    error('test:noError', 'Expected an error.');
catch err
    assert(strcmp(err.identifier, 'pest:invalidLevel'));
end

%% Converges to the target level of a simulated observer
rng(1);
trueThreshold = -30;
slope = 0.5;
offset = log((0.75 - 0.5) / (1 - 0.75));
pCorrect = @(x) 0.5 + 0.5 ./ (1 + exp(-(slope * (x - trueThreshold) + offset)));
nRuns = 200;
estimates = zeros(1, nRuns);
for run = 1:nRuns
    state = pestInit('InitialLevel', 0, 'InitialStepSize', 8, 'MinStepSize', 0.5, ...
        'MaxStepSize', 16, 'TargetProbability', 0.75, 'MaxTrials', 1000);
    while ~state.isFinished
        state = pestUpdate(state, rand() < pCorrect(state.level));
    end
    estimates(run) = state.threshold;
end
assert(abs(mean(estimates) - trueThreshold) < 1.5, ...
    'Mean estimate %.2f is far from %.2f.', mean(estimates), trueThreshold);
