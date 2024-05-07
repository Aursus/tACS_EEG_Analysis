%% compile digit span data
clear
clc

% Define input and output directories
input_dir = 'Data_Dir_With_rsEEG';
output_dir = 'Dir_For_Save_rsEEG_Epoch';

% add path from EEGLAB to MATLAB ]
addpath('Path_To_EEGLAB');  
eeglab;
close(gcf);

% Get a list of all .easy files in the input directory
file_list = dir(fullfile(input_dir, '*.set'));

EEG_rs = struct('subject', [], 'visit', [], 'session', [], 'task', [], 'EEG', [], 'Avg_EEG', [], 'event', [], 'epoch', []);

% Read all the file
for r = 1:length(file_list)
    % Get the current filename
    input_file = file_list(r).name;
    EEG = pop_loadset('filename', input_file, 'filepath', input_dir);
    EEG = eeg_regepochs(EEG, 'recurrence', 3, 'limits',[0 3], 'rmbase',NaN); % extract epoch into 3-s length
    EEG = pop_rmbase(EEG, [1,1000]); % unit ms
    
    numb = regexp(input_file, '\d+', 'match');
    new_entry.subject = str2double(numb{1}); 
    clear numb
    new_entry.visit = regexp(input_file, 'Visit\d+', 'match');       
    new_entry.session = regexp(input_file, 'Post|Pre', 'match');       
    new_entry.task = regexp(input_file, 'Eyes Open|Eyes Close', 'match');   
    new_entry.EEG = EEG;
    new_entry.Avg_EEG = mean(EEG.data, 3);
    new_entry.event = EEG.event;
    new_entry.epoch = EEG.epoch;
    
    EEG_rs(end + 1) = new_entry;
    clear new_entry;
    disp('stop')
end

EEG_rs(1)=[];

stimulation = table2struct( readtable('Stimulation.xlsx') );
[stimulation.visit] = stimulation.Visit; stimulation = orderfields(stimulation,[1:1,5,2:4]); stimulation = rmfield(stimulation,'Visit');
[stimulation.subject] = stimulation.Experiment; stimulation = orderfields(stimulation,[1:0,5,1:4]); stimulation = rmfield(stimulation,'Experiment');

EEG_rs_join = join(struct2table(EEG_rs),struct2table(stimulation));

% save as .mat file
save('rsEEG_compile.mat', 'EEG_rs_join');