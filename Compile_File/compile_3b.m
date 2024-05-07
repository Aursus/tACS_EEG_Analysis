%% compile 3-back data
clear
clc

% Define input and output directories
input_dir = 'Data_Dir_With_All_Epoch_Data_For_NBack_Or_XTarget';

% add path from EEGLAB to MATLAB ]
addpath('Path_To_EEGLAB');  
% Get a list of all .easy files in the input directory
file_list = dir(fullfile(input_dir, '*.set'));

eeglab;
close(gcf);

EEG_xtarget = struct('subject', [], 'visit', [], 'session', [], 'task', [], 'EEG', [], 'Avg_EEG', [], 'event', [], 'epoch', []);
EEG_3back = struct('subject', [], 'visit', [], 'session', [], 'task', [], 'EEG', [], 'Avg_EEG', [], 'event', [], 'epoch', []);
EEG_error_save = {};
EEG_length_not_match = struct('ID',[],'pre_numb',[],'after_num',[]);

% Read all the file
for r = 1:length(file_list)
    % Get the current filename
    input_file = file_list(r).name;
    EEG = pop_loadset('filename', input_file, 'filepath', input_dir);
    EEG_save = EEG;

    numb = regexp(input_file, '\d+', 'match');
    new_entry.subject = str2double(numb{1}); 
    clear numb
    if (new_entry.subject==11)||(new_entry.subject==13)||(new_entry.subject==14)
        continue
    end
    new_entry.visit = regexp(input_file, 'Visit\d+', 'match');       
    new_entry.session = regexp(input_file, 'Post|Pre', 'match');     
    new_entry.task = regexp(input_file, 'xtarget|3back', 'match');   
    if strcmp(new_entry.task, 'xtarget')
        EEG = pop_epoch(EEG, {'48','38'}, [-1 2]);
        idx_to_keep = arrayfun(@(x) length(x.event) == 2, EEG.epoch);
        EEG.epoch = EEG.epoch(idx_to_keep);
        EEG = pop_rmbase(EEG, [-1000 -300]);
    elseif strcmp(new_entry.task, '3back')
        EEG = pop_epoch(EEG, {'47','37'}, [-1 2]);
        idx_to_keep = arrayfun(@(x) length(x.event) == 2, EEG.epoch);
        EEG.epoch = EEG.epoch(idx_to_keep);
        EEG = pop_rmbase(EEG, [-1000 -300]);
    else
        EEG_error_save{end + 1} = input_file;
    end

    if length(EEG_save.epoch) ~= length(EEG.epoch)
        aaa.ID = input_file;
        aaa.pre_numb = length(EEG_save.epoch);
        aaa.after_num = length(EEG.epoch);
        EEG_length_not_match(end+1) = aaa;
    end
    
    new_entry.EEG = EEG;
    new_entry.Avg_EEG = mean(EEG.data, 3);
    new_entry.event = EEG.event;
    new_entry.epoch = EEG.epoch;
    
    task_match = regexp(input_file, 'xtarget|3back', 'match');   
    if strcmp(task_match, 'xtarget')
        EEG_xtarget(end + 1) = new_entry;
    elseif strcmp(task_match, '3back')
        EEG_3back(end + 1) = new_entry;
    end
    clear new_entry;
    disp('stop')
end

EEG_xtarget(1)=[];
EEG_3back(1)=[];

stimulation = table2struct( readtable('Stimulation.xlsx') );
[stimulation.visit] = stimulation.Visit; stimulation = orderfields(stimulation,[1:1,5,2:4]); stimulation = rmfield(stimulation,'Visit');
[stimulation.subject] = stimulation.Experiment; stimulation = orderfields(stimulation,[1:0,5,1:4]); stimulation = rmfield(stimulation,'Experiment');

EEG_3back_join = join(struct2table(EEG_3back),struct2table(stimulation));
EEG_xtarget_join = join(struct2table(EEG_xtarget),struct2table(stimulation));


% save as .mat file
save('three_back_compile.mat', 'EEG_3back_join');
save('x_target_compile.mat', 'EEG_xtarget_join');