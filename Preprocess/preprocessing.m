clear
clc

% set the seed for random generater
rng default

% Define input and output directories
input_dir = 'Dir_To_Set_Folder';
output_dir = 'Output_Dir_Folder';

% add path from EEGLAB to MATLAB
addpath('D:\matlab\eeglab2023.0');  
eeglab;
close(gcf);

% display beep as reminder
t_beep = 0:1/44100:0.3;

% Get a list of all .easy files in the input directory
file_list = dir(fullfile(input_dir, '*.set'));

% Save Rej Record
xlsx_file = 'Dir_To_Rej_Component_Xlsx_File\rej_save.xlsx';

n_i = 1;

% Step through each file in the directory
while n_i <= length(file_list)
    %% 0. Load Data
    % Get the current filename
    input_file = file_list(n_i).name;
    disp('*************************************************************')
    disp(input_file)
    disp('*************************************************************')
    
    % Load the .set file using EEGLAB
    set_file_path = fullfile(input_dir, input_file);
    EEG = pop_loadset(set_file_path);

    % WM18 Visit2 has wrong channel location, need correct
%     EEGsave = EEG.data(1:8,:);
%     EEG.data(1:8,:) = EEG.data(9:16,:);
%     EEG.data(9:16,:) = EEGsave;

    % save Current EEG
    EEG_orig = EEG;

    % Marker 9 means Stop. Delete signal after 9
    if ~isempty(EEG_orig.event)
        event_indices = find([EEG.event.type] == '9');
    else
        event_indices = [];
    end

    % Check if event is empty (Fail to record marker)
    if ~isempty(event_indices)
        disp(event_indices)
        first_event_index = event_indices(1);
        EEG = pop_select(EEG, 'nopoint', [EEG.event(first_event_index).latency EEG.pnts]);
    end
        

    %% 1. High pass filter to 1Hz
    EEG = pop_eegfiltnew(EEG, 1, 0); 

    % 2. select bad channel and select window of time with huge noise and manually removed it (notice the continuous) 
    % 2.1 visualize check bad channels
    % 2.1.1 select Plot → Channel data (scroll)
    % by dragging the left mouse button to mark stretches. click on marked stretches to unmark
    % when done, press 'REJECT' to excise marked strtches
    pop_eegplot(EEG, 1, 'winlength', 20);
%     eegplot(EEG.data, 'winlength', 20, 'eloc_file', EEG.chanlocs, 'events', EEG.event)
    eeglab_handle = gcf;
    uiwait(eeglab_handle);
    
    % 2.1.2 select Plot → Channel spectra and maps
    % click on individual channel traces, the channel index is shown on the MATLAB command line
    % To adjust the time range displayed (i.e., the horizontal scale), 
    % select the eegplot.m menu item Settings → Time range to display, 
    % and set the desired window length to “10” seconds as shown below,
    pop_spectopo(EEG, 1);
    eeglab_handle = gcf;
    uiwait(eeglab_handle);

    % 2.2 select bad channel: Edit → Select data
    % put the bad channel on 'Channel(s)'
    input_channel = input('Please enter an integer array (separated by commas): \n', 's');
    EEG = pop_select(EEG, 'rmchannel', str2num(input_channel));
    
    % 3. low pass filter and notch filter, 60Hz
    signal      = struct('data', EEG.data, 'srate', EEG.srate);
    lineNoiseIn = struct('lineNoiseMethod', 'clean', ...
                         'lineNoiseChannels', 1:EEG.nbchan,...
                         'Fs', EEG.srate, ...
                         'lineFrequencies', [60 120],...
                         'p', 0.01, ...
                         'fScanBandWidth', 2, ...
                         'taperBandWidth', 2, ...
                         'taperWindowSize', 4, ...
                         'taperWindowStep', 4, ...
                         'tau', 100, ...
                         'pad', 0, ...
                         'fPassBand', [0 EEG.srate/2], ...
                         'maximumIterations', 10);
    [clnOutput, lineNoiseOut] = cleanLineNoise(signal, lineNoiseIn);
    EEG.data = clnOutput.data;
    EEG = pop_eegfiltnew(EEG, 0, 60); 

%     pop_spectopo(EEG, 1, [],  'EEG', 'percent', 100, 'freqs', [6 10 22 50], 'freqrange', [0 100], 'electrodes','on');
%     eeglab_handle = gcf;
%     uiwait(eeglab_handle);

    % 4. re-reference(average)
    EEG = pop_reref(EEG, []);
    EEG_beforeica = EEG;

%     eeglab redraw
%     eeglab_handle = gcf;
%     uiwait(eeglab_handle);

    %% 5. ica
%     EEG = pop_runica(EEG, 'extended', 1);
    plugin_askinstall('picard', 'picard', 1);
    EEG = pop_runica(EEG, 'icatype','picard');
    EEG = pop_iclabel(EEG, 'default');
    EEG = pop_icflag( EEG,[NaN NaN; 0.8 1; 0.8 1; 0.9 1; NaN NaN; 0.9 1; NaN NaN]);
    %  Brain, Muscle, Eye, Heart, Line Noise, Channel Noise, Other.
    rejected_comps = find(EEG.reject.gcompreject > 0);
    disp(rejected_comps)
    sound(sin(2*pi*1000*t_beep), 44100); % beep
%     pop_viewprops(EEG, 0)      % vis all components
    pop_viewprops( EEG, 0, [1:size(EEG.icawinv,2)], {'freqrange', [2 80]}, {}, 1, 'ICLabel' )    
    eeglab_handle = gcf;
    uiwait(eeglab_handle);

    result_str = ['Default Components is: ' num2str(rejected_comps') '\n Please put the bad components you want to remove: \n'];
    input_ica = rejected_comps;
    input_ica = input(result_str, 's');

    rej_save(n_i).ica  = str2num(input_ica);
    EEG = pop_subcomp(EEG, str2num(input_ica));
    EEG = eeg_checkset(EEG);
%     EEG_ica = EEG;

    %% 6. ASR (ref: https://github.com/sccn/clean_rawdata/blob/master/clean_rawdata.m)
    EEG = clean_rawdata(EEG, -1, -1, -1, -1, 20, 0.25, 'BurstCriterionRefMaxBadChns', 0.2);
    if ~isempty(EEG_orig.event)
        disp(['origianl has marker number: ', num2str(size({EEG_beforeica.event.type}, 2) - sum(strcmp({EEG_beforeica.event.type}, 'boundary')))])
        disp(['now has marker number: ', num2str(size({EEG.event.type}, 2) - sum(strcmp({EEG.event.type}, 'boundary')))]);
    end

    %% 7. interpolate bad channel
    % 7.1 interpolate channel
    EEG = eeg_interp(EEG, EEG_orig.chanlocs, 'spherical');
    sound(sin(2*pi*1000*t_beep), 44100);

    % 7.2 double-check the signal
    pop_eegplot(EEG, 1, 'winlength', 20);
    eeglab_handle = gcf;
    uiwait(eeglab_handle);
    pop_spectopo(EEG, 1);
    eeglab_handle = gcf;
    uiwait(eeglab_handle);

    % 7.3 select more channels and interpolate it
    disp('The bad channels interpolated is: \n')
    disp(input_channel)
    input_channel2 = input('Please enter an integer array (separated by commas): \n', 's');
    EEG = eeg_interp(EEG, str2num(input_channel2), 'spherical');

    %% 8. if Pass or Not
    % 8.1 check the data to decide if pass or not
    eeglab redraw;
    eeglab_handle = gcf;
    uiwait(eeglab_handle);

    % 8.2 if pass or repeat
    user_input = input('【GOOD OR NOT】Enter P for pass or N for not pass: ', 's');
    if strcmpi(user_input, 'P')     % if 'P', pass and go to next subject
        
        disp('*****************************************************************')
        disp('*************Save file and Go to next subjects*************');
        disp('*****************************************************************')

        % 8.2.1 save the file
        [~, filename, ~] = fileparts(input_file);
        saveFileName = [filename '_afterpro.set'];
        output_path = fullfile(output_dir, saveFileName);
        EEG = pop_saveset(EEG, 'filename', output_path);

        % 8.2.2 save reject component
        df = readtable(xlsx_file);
        file_row_index = find(strcmp(df.name, input_file));
        input_chan_all = num2str([str2num(input_channel) str2num(input_channel2)]);
        if isempty(file_row_index) % if no such row, then creat it
            newRow = {input_file, input_ica, input_chan_all};
            df = [df; newRow]; % add new row
        else % if there is such row, replace the data
            df.name(file_row_index(1)) = {input_file};
            df.channel(file_row_index(1)) = {input_chan_all};
            df.ica(file_row_index(1)) = {input_ica};
        end
        writetable(df, xlsx_file);

        n_i = n_i +1; % go to next subject

    elseif strcmpi(user_input, 'N') % if 'N', not pass and repeat
        disp('*****************************************************************')
        disp('*************Repeating the current loop*******************');
        disp('*****************************************************************')
    else
        disp('*************Invalid input. Please enter P for pass or N for not pass*************');
    end

    % 10. Clean up and close EEGLAB
    close(gcf);
end
