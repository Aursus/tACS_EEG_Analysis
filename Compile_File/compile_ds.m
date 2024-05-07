%% compile digit span data
clear
clc

% Define input and output directories
input_dir = 'Data_Dir_With_All_Epoch_Data_For_Digit_Span';

% add path from EEGLAB to MATLAB ]
addpath('Path_To_EEGLAB');  
% Get a list of all .easy files in the input directory
file_list = dir(fullfile(input_dir, '*.set'));

eeglab;
close(gcf);

EEG_forward = struct('subject', [], 'visit', [], 'session', [], 'task', [], 'EEG', [], 'Avg_EEG', [], 'event', [], 'epoch', []);
EEG_backward = struct('subject', [], 'visit', [], 'session', [], 'task', [], 'EEG', [], 'Avg_EEG', [], 'event', [], 'epoch', []);
EEG_error_save = {};

% Read all the file
for r = 1:length(file_list)
    % Get the current filename
    input_file = file_list(r).name;
    EEG = pop_loadset('filename', input_file, 'filepath', input_dir);

    numb = regexp(input_file, '\d+', 'match');
    new_entry.subject = str2double(numb{1}); 
    clear numb
    new_entry.visit = regexp(input_file, 'Visit\d+', 'match');       
    new_entry.session = regexp(input_file, 'Post|Pre', 'match');       
    new_entry.task = regexp(input_file, 'Forward|Backward', 'match');  

    if strcmp(new_entry.task, 'Forward')
        EEG = pop_epoch(EEG, {'1f','2f'}, [-1 2]);
        EEG = pop_rmbase(EEG, [-1000 -300]);
    elseif strcmp(new_entry.task, 'Backward')
        EEG = pop_epoch(EEG, {'1b','2b'}, [-1 2]);
        EEG = pop_rmbase(EEG, [-1000 -300]);
    else
        EEG_error_save{end + 1} = input_file;
    end

    new_entry.EEG = EEG;
    new_entry.Avg_EEG = mean(EEG.data, 3);
    new_entry.event = EEG.event;
    new_entry.epoch = EEG.epoch;
    
    task_match = regexp(input_file, 'Forward|Backward', 'match');  
    if strcmp(task_match, 'Forward')
        EEG_forward(end + 1) = new_entry;
    elseif strcmp(task_match, 'Backward')
        EEG_backward(end + 1) = new_entry;
    end
    clear new_entry;
    disp('stop')
end

EEG_forward(1)=[];
EEG_backward(1)=[];

stimulation = table2struct( readtable('Stimulation.xlsx') );
[stimulation.visit] = stimulation.Visit; stimulation = orderfields(stimulation,[1:1,5,2:4]); stimulation = rmfield(stimulation,'Visit');
[stimulation.subject] = stimulation.Experiment; stimulation = orderfields(stimulation,[1:0,5,1:4]); stimulation = rmfield(stimulation,'Experiment');

ds_forward = join(struct2table(EEG_forward),struct2table(stimulation));
ds_backward = join(struct2table(EEG_backward),struct2table(stimulation));

% save as .mat file
save( "ds_forward_compile.mat", 'ds_forward');
save( "ds_backward_compile.mat", 'ds_backward');