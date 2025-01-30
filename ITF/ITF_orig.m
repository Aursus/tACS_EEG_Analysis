% clear
% clc
% 
% % Load required packages
% addpath 'D:\matlab\eeglab2023.0'
% eeglab;
% close(gcf);
% 
% % Define file paths
% read_path = '20240226145847_tACS_WM-33 Visit 1_Rest Eyes Open Pre.edf';

% Load raw data
EEG = pop_biosig(read_path,'channels', [1:32]);
EEG = eeg_checkset(EEG);

% Define plot flags
plot_flags = struct('wavelet', false, ...
                    'montage', false, ...
                    'after_process', false, ...
                    'before_process', false, ...
                    'after_ica', true);

% Plot raw data
if plot_flags.before_process
    pop_eegplot(EEG, 1, 1, 1);
end

% Basic information
disp('-------------------------------------------------------------------------------')
disp('** Basic Checking Before Proprocessing **')

% Set montage
chan_locs_file = 'D:\matlab\eeglab2023.0\plugins\EEGLab-Plugin-master\Locations\Starstim32.locs';
EEG = pop_chanedit(EEG, 'lookup', chan_locs_file);

% Downsampling
disp('-------------------------------------------------------------------------------')
disp('** Downsampling **')
EEG = pop_resample(EEG, 200);

% Filtering
disp('-------------------------------------------------------------------------------')
disp('** Filtering **')
EEG = pop_eegfiltnew(EEG, 'locutoff', 3, 'hicutoff', 59);
EEG = pop_eegfiltnew(EEG, 'locutoff', 59, 'hicutoff', 61, 'revfilt', 1); % Notch filter at 60 Hz

% Run ICA
disp('-------------------------------------------------------------------------------')
disp('** Remove Artifacts - ICA **')
plugin_askinstall('picard', 'picard', 1);
EEG = pop_runica(EEG, 'icatype','picard');

% Label ICA components (Requires ICLabel plugin)
EEG = pop_iclabel(EEG, 'default');
% EEG = pop_icflag( EEG,[NaN NaN; 0.8 1; 0.8 1; 0.9 1; NaN NaN; 0.9 1; NaN NaN]);
% 

% Exclude non-brain ICs
brain_ICs = find(strcmp({EEG.etc.ic_classification.ICLabel.classes}, 'Brain'));
EEG = pop_subcomp(EEG, brain_ICs, 0);
EEG = eeg_checkset(EEG);

% Plot data after ICA
if plot_flags.after_ica
    pop_eegplot(EEG, 1, 1, 1);
    figure
    pop_spectopo(EEG, 1, [EEG.xmin EEG.xmax]*1000, 'EEG', 'freq', [6 10 22], 'freqrange', [2 50], 'electrodes', 'off');
end

% Re-reference to average
disp('-------------------------------------------------------------------------------')
disp('** Re-reference - Average **')
EEG = pop_reref(EEG, []);

% Interpolate bad channels
disp('-------------------------------------------------------------------------------')
disp('** Bad Channels Interpolation **')
input_channel = input('Please enter an integer array (separated by commas): \n', 's');
EEG = eeg_interp(EEG, str2num(input_channel), 'spherical');

% Check data after processing
disp('-------------------------------------------------------------------------------')
disp('** Check Data **')
if plot_flags.after_process
    pop_eegplot(EEG, 1, 1, 1);
    figure
    pop_spectopo(EEG, 1, [EEG.xmin EEG.xmax]*1000, 'EEG', 'freq', [6 10 22], 'freqrange', [2 50], 'electrodes', 'off');
end

% Plot PSD and check data again
figure
pop_spectopo(EEG, 1, [EEG.xmin EEG.xmax]*1000, 'EEG', 'freq', [6 10 22], 'freqrange', [2 50], 'electrodes', 'off');

% Frequency band range
alpha_lower_bound = 4; % Unit: Hz
alpha_upper_bound = 8; % Unit: Hz


% Crop the time range
crop_flag = false;
crop_tmin = 20; % 20 seconds
crop_tmax = 119; % 119 seconds

% Method for PSD
psd_method = 'mean'; % 'mean' or 'select'
channels_of_interest = {'F7', 'F3', 'FC5', 'T7', 'C3', 'FC1'};


% Calculate the PSD
[psd, freqs] = pop_spectopo(EEG, 1, [], 'EEG', 'srate', EEG.srate);

if strcmp(psd_method, 'mean')
    mean_psd = mean(psd, 2);
elseif strcmp(psd_method, 'select')
    chan_indices = find(ismember({EEG.chanlocs.labels}, channels_of_interest));
    mean_psd = mean(psd(chan_indices, :), 2);
else
    error('ERROR: psd method error');
end

% Find alpha peak
alpha_range = (freqs >= alpha_lower_bound) & (freqs <= alpha_upper_bound);
alpha_freqs = freqs(alpha_range);
alpha_psd = mean_psd(alpha_range);

[~, max_idx] = max(alpha_psd);
alpha_peak_freq = alpha_freqs(max_idx);
alpha_peak_psd = alpha_psd(max_idx);

disp(['The alpha peak is ', num2str(alpha_peak_freq, '%.2f'), ' Hz']);
figure;
plot(alpha_freqs, alpha_psd);
hold on;
plot(alpha_peak_freq, alpha_peak_psd, 'o');
xlabel('Frequency (Hz)');
ylabel('Power (dB)');
title(['The alpha peak is ', num2str(alpha_peak_freq, '%.2f'), ' Hz']);
hold off;
drawnow;
