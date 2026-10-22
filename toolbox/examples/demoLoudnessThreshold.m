%% Measure the detection threshold of a 440 Hz tone with PEST
% A 440 Hz tone is played on each trial and the listener reports whether
% it was heard. PEST adjusts the tone level (in dB re full scale) towards
% the level heard on 50% of the trials (a yes/no detection threshold).
%
% Use headphones and fix the system volume before running. The track is
% saved to a MAT-file in the current folder and plotted at the end.

%% Settings
fs = 44100;              % sampling rate (Hz)
toneFrequency = 440;     % Hz
toneDuration = 0.5;      % s
rampDuration = 0.01;     % raised-cosine on/off ramp (s), avoids clicks

state = pestInit( ...
    'InitialLevel', -30, ...      % dBFS
    'InitialStepSize', 8, ...     % dB
    'MinStepSize', 1, ...         % dB, ends the run
    'MaxStepSize', 16, ...        % dB
    'MinLevel', -100, ...         % dBFS
    'MaxLevel', 0, ...            % dBFS, full scale
    'TargetProbability', 0.5, ... % yes/no detection
    'WaldLimit', 1, ...
    'MaxTrials', 100);

%% Tone at full scale with on/off ramps
t = (0:round(toneDuration * fs) - 1) / fs;
tone = sin(2 * pi * toneFrequency * t);
nRamp = round(rampDuration * fs);
ramp = (1 - cos(pi * (0:nRamp - 1) / nRamp)) / 2;
tone(1:nRamp) = tone(1:nRamp) .* ramp;
tone(end - nRamp + 1:end) = tone(end - nRamp + 1:end) .* fliplr(ramp);

%% Trial loop
fprintf('Answer y (heard) or n (not heard) after each tone, q to quit.\n\n');
while ~state.isFinished
    amplitude = 10 ^ (state.level / 20);
    fprintf('Trial %d: %.1f dBFS\n', state.nTrials + 1, state.level);
    sound(amplitude * tone, fs);
    pause(toneDuration + 0.2);

    answer = '';
    while ~any(strcmpi(answer, {'y', 'n', 'q'}))
        answer = strtrim(input('  Did you hear the tone? [y/n/q]: ', 's'));
    end
    if strcmpi(answer, 'q')
        fprintf('Run stopped by the user.\n');
        break
    end
    state = pestUpdate(state, strcmpi(answer, 'y'));
end

%% Save and plot
if state.isFinished
    fprintf('\nThreshold estimate: %.1f dBFS after %d trials.\n', ...
        state.threshold, state.nTrials);
end
fileName = sprintf('pest_loudness_%s.mat', datestr(now, 'yyyymmdd_HHMMSS')); %#ok<TNOW1,DATST>
save(fileName, 'state');
fprintf('Saved to %s\n', fileName);

figure('Name', 'PEST loudness threshold');
pestPlot(state);
ylabel('Level (dBFS)');
