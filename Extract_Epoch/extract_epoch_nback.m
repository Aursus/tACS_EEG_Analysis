clear
clc

% Define input and output directories
input_dir = 'Dir_To_Folder_After_Preprocess';
input_dir2 = 'Dir_To_Folder_Before_Preprocess';
output_dir = 'Dir_Output';


% add path from EEGLAB to MATLAB ]
addpath('EEGLAB_Dir');  
eeglab;
close(gcf);

% Get a list of all .easy files in the input directory
file_list = dir(fullfile(input_dir, '*.set'));

% Step through each file in the directory
for r = 1:length(file_list)
    % Get the current filename
    input_file = file_list(r).name;
    newFile = strrep(input_file, '_afterpro_ln.set', '.set');

    % Load the .easy file using EEGLAB
    EEG = pop_loadset('filename', input_file, 'filepath', input_dir);
    EEG_ref = pop_loadset('filename', newFile, 'filepath', input_dir2);


    %% 输出event数据
%     % Step 1: export event file
%     [~, filename, ~] = fileparts(newFile);
%     excel_filename = fullfile(['i' filename '.xlsx']);
%     writetable(struct2table(EEG_ref.event),excel_filename);
%     % Step 2: manually adjust event file
%     % Step 3: Read_Xlsx_File_and_Set_EEG_Event
%     EEG_ref.event = table2struct(readtable(excel_filename));


    %% Add missing '7' and '8' marker
    for i = 1:length(EEG_ref.event)
        if strcmp(EEG_ref.event(i).type, '7') || strcmp(EEG_ref.event(i).type, '8')
            % 查找EEG.event中是否有对应的事件
            found = false;
            for j = 1:length(EEG.event)
                if EEG_ref.event(i).latency_ms == EEG.event(j).latency_ms
                    found = true;
                    break;
                end
            end
            
            % if not find, adding the event
            if ~found
                EEG.event(end + 1).type = EEG_ref.event(i).type;
                EEG.event(end).latency = EEG_ref.event(i).latency;
                EEG.event(end).latency_ms = EEG_ref.event(i).latency_ms;
                EEG.event(end).duration = 0;
                disp('LOL')
            end
        end
    end
    
    % rank event based on latency_ms
%     [~, idx] = sort([EEG.event.latency_ms]);
%     EEG.event = EEG.event(idx);
    EEG.event = EEG.event(~strcmp({EEG.event.type}, 'boundary'));
    EEG = pop_editeventvals(EEG, 'sort', {'latency_ms', 'ascend'});

    %% Rewrite the Event Type
    for i = 1: length(EEG.event)
        % if current is in task 7 or task 8
        if EEG.event(i).type == '7'
            type_marker = 'marker 7';
            EEG.event(i).type = '7';
            if EEG.event(i+1).latency < EEG.event(i).latency
                EEG.event(i).latency = EEG.event(i+1).latency - 500;
            end
        elseif EEG.event(i).type == '8'
            type_marker = 'marker 8';
            EEG.event(i).type = '8';
            if EEG.event(i+1).latency < EEG.event(i).latency
                EEG.event(i).latency = EEG.event(i+1).latency - 500;
            end
        elseif strcmp(EEG.event(i).type,'1') ||  strcmp(EEG.event(i).type,'2') ||  strcmp(EEG.event(i).type,'3') ||  strcmp(EEG.event(i).type,'4')
            if strcmp(type_marker, 'marker 7')
                EEG.event(i).type = strcat(EEG.event(i).type, '7');
            elseif strcmp(type_marker, 'marker 8')
                EEG.event(i).type = strcat(EEG.event(i).type, '8');
            end
        else
            EEG.event(i).type = EEG.event(i).type;
        end
    end


    %% rename the output file
    file_name = strrep(input_file, 'N-back', 'N-Back');
    [~, name, ext] = fileparts(input_file); 
    output_file7 = [name, '_Epoch_3back', ext];  
    output_file8 = [name, '_Epoch_xtarget', ext]; 
    
    %% extract epoch
    type_num8 = {'48','38'};
    type_num7 = {'47','37'};
    EEG8 = pop_epoch(EEG, type_num8, [-2 3]);
    EEG7 = pop_epoch(EEG, type_num7, [-2 3]);

%     %% remove EEG without reponse
%     EEG7 = filter_epoch_events(EEG7);
%     EEG8 = filter_epoch_events(EEG8);
% 
%     EEG7.trials = length(EEG7.epoch);
%     EEG8.trials = length(EEG8.epoch);

    disp(name)
    disp(length(EEG7.epoch))
    disp(length(EEG8.epoch))


    %% Save the EEG dataset in .set format
    pop_saveset(EEG7, 'filename', output_file7, 'filepath', output_dir);
    pop_saveset(EEG8, 'filename', output_file8, 'filepath', output_dir);

    disp('finish')
   
end

%% find epoch with response
function EEG = filter_epoch_events(EEG)
    idx_to_keep = [];
    % find stimulation with response
    for i = 1:length(EEG.epoch)
        if length(EEG.epoch(i).event) == 2
            idx_to_keep = [idx_to_keep, i];
        end
    end
    EEG.epoch = EEG.epoch(idx_to_keep);    % keep event 
end