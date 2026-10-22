%% Run PEST against a simulated observer
% This example needs no audio hardware or responses. A simulated observer
% answers according to a logistic psychometric function, and PEST tracks
% the level at which the observer is correct 75% of the time.

%% Simulated observer
trueThreshold = -30;   % level at which p(correct) = 0.75
slope = 0.5;
guessRate = 0.5;       % two-alternative forced choice
% Shift the logistic so that it passes through 0.75 at trueThreshold.
offset = log((0.75 - guessRate) / (1 - 0.75));
pCorrect = @(level) guessRate + (1 - guessRate) ./ ...
    (1 + exp(-(slope * (level - trueThreshold) + offset)));

%% Run the staircase
state = pestInit( ...
    'InitialLevel', 0, ...
    'InitialStepSize', 8, ...
    'MinStepSize', 0.5, ...
    'MaxStepSize', 16, ...
    'TargetProbability', 0.75, ...
    'WaldLimit', 1, ...
    'MaxTrials', 500);

while ~state.isFinished
    isCorrect = rand() < pCorrect(state.level);
    state = pestUpdate(state, isCorrect);
end

fprintf('PEST estimate: %.2f (true threshold %.2f) after %d trials.\n', ...
    state.threshold, trueThreshold, state.nTrials);

%% Plot the track
figure('Name', 'PEST with a simulated observer');
pestPlot(state);
