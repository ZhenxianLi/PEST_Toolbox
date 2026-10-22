function ax = pestPlot(state, ax)
%PESTPLOT Plot the track of a PEST staircase.
%   PESTPLOT(STATE) plots the level presented on each trial of STATE in the
%   current axes. Filled markers are correct responses, open markers are
%   incorrect ones, and squares mark the trials after which the step
%   direction reversed. When the run has finished, the threshold estimate
%   is drawn as a dashed line.
%
%   PESTPLOT(STATE, AX) plots into the axes AX.
%
%   AX = PESTPLOT(...) returns the axes.
%
%   See also PESTINIT, PESTUPDATE.

%   Copyright (c) 2025 Zhenxian Li

if nargin < 2 || isempty(ax)
    ax = gca;
end
h = state.history;
trials = 1:numel(h.level);
wasHeld = ishold(ax);

stairs(ax, trials, h.level, 'Color', [0.5 0.5 0.5]);
hold(ax, 'on');
plot(ax, trials(h.isCorrect), h.level(h.isCorrect), 'o', ...
    'MarkerFaceColor', [0 0.45 0.74], 'MarkerEdgeColor', [0 0.45 0.74]);
plot(ax, trials(~h.isCorrect), h.level(~h.isCorrect), 'o', ...
    'MarkerFaceColor', 'w', 'MarkerEdgeColor', [0 0.45 0.74]);
plot(ax, trials(h.isReversal), h.level(h.isReversal), 's', ...
    'MarkerSize', 10, 'MarkerEdgeColor', [0.85 0.33 0.1]);
if state.isFinished && ~isempty(trials)
    plot(ax, [trials(1), trials(end) + 1], state.threshold * [1 1], '--', ...
        'Color', [0.85 0.33 0.1]);
end
if ~wasHeld
    hold(ax, 'off');
end

grid(ax, 'on');
xlabel(ax, 'Trial');
ylabel(ax, 'Level');
if state.isFinished
    title(ax, sprintf('PEST track (threshold = %.2f)', state.threshold));
else
    title(ax, 'PEST track');
end
end
