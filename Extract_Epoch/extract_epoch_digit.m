clear
clc

% Define input and output directories
input_dir = 'Dir_To_Folder_After_Preprocess';
input_dir2 = 'Dir_To_Folder_Before_Preprocess';
output_dir = 'Dir_Output';
output_dir2 = 'Dir_Need_Extra_Screen';


% add path from EEGLAB to MATLAB ]
addpath('EEGLAB_Dir');  
eeglab;
close(gcf);

% Get a list of all .easy files in the input directory
file_list = dir(fullfile(input_dir, '*.set'));
save_epoch_num = cell(length(file_list), 3);




% Step through each file in the directory
for r = 1:length(file_list)
    % Get the current filename
    input_file = file_list(r).name;
    newFile = strrep(input_file, '_afterpro_ln.set', '.set');
    
    % Load the .easy file using EEGLAB
    EEG = pop_loadset('filename', input_file, 'filepath', input_dir);
    EEG_ref = pop_loadset('filename', newFile, 'filepath', input_dir2);


    %% Export event file, used for correction
%     % Step 1: export event file
%     [~, filename, ~] = fileparts(newFile);
%     excel_filename = fullfile(['i' filename '.xlsx']);
%     writetable(struct2table(EEG_ref.event),excel_filename);
%     % Step 2: manually adjust event file
%     % Step 3: Read_Xlsx_File_and_Set_EEG_Event
%     EEG_ref.event = table2struct(readtable(excel_filename));

    
   %% if not match length, remove
    EEG_ref.event = EEG_ref.event(~strcmp({EEG_ref.event.type}, 'boundary'));
%     if length(EEG_ref.event)~=64 % please choose the length you want
%         pop_saveset(EEG, 'filename', input_file, 'filepath', output_dir2);
%         continue;
%     end
    disp(length(EEG_ref.event))
    

    %% Add Digit Number Length
    mylabel = struct('label', {});
    labels = {'f', 'b'};
    alphas = {'a', 'b'};
    states = {'s', 'r'};
    nums = 2:11;

    % creat structure contains all the labels
    for label = labels
        for num = nums
            for alpha = alphas
                for state = states
                    mylabel(end + 1).label = sprintf('%s-%d-%s-%s', label{1}, num, alpha{1}, state{1});
                end
            end
        end
    end

    % assign the label to EEG_Ref
    for i = 1:length(EEG_ref.event)
%         EEG_ref.event(i).mylabel = mylabel(i + (length(mylabel) - length(EEG_ref.event))).label;
        EEG_ref.event(i).mylabel = mylabel(i).label;
    end


    %% add label in EEG
    for i = 1:length(EEG.event)
        for j = 1:length(EEG_ref.event)
            if EEG_ref.event(j).latency_ms == EEG.event(i).latency_ms
                EEG.event(i).mylabel = EEG_ref.event(j).mylabel;
                break;
            end
        end
    end

%     % rerank the order
    EEG.event = EEG.event(~strcmp({EEG.event.type}, 'boundary'));
%     EEG = pop_editeventvals(EEG, 'sort', {'latency_ms', 'ascend'});


    %% remove single epoch
    i = 1;
    while i <= length(EEG.event)
        % Check if the type of the current event is 1 or 2
        if (strcmp(EEG.event(i).type,'1') || strcmp(EEG.event(i).type,'2')) && (i+1<=length(EEG.event))
            current_label = EEG.event(i).mylabel(1:5);
            next_label = EEG.event(i+1).mylabel(1:5);
            
            if ~strcmp(current_label, next_label)
                EEG.event(i) = [];
                i = i - 1;
            end
        end
        
        % Move to the next event
        i = i + 1;
    end

    for i = 1:length(EEG.event)
        EEG.event(i).type = strcat(EEG.event(i).type, EEG.event(i).mylabel(1));
    end

    %% rename the output file
    [~, name, ext] = fileparts(input_file);  
    output_filef = [name, '_Epoch_DS_Forward', ext];  
    output_fileb = [name, '_Epoch_DS_Backward', ext];  
    
    %% extract epoch
    type_num_f = {'1f','2f'};
    EEG_forward = pop_epoch(EEG, type_num_f, [-1 2]);
    type_num_b = {'1b','2b'};
    EEG_backward = pop_epoch(EEG, type_num_b, [-1 2]);

    disp(length(EEG_backward.epoch))
    disp(length(EEG_forward.epoch))
    save_epoch_num{r, 1} = input_file;
    save_epoch_num{r, 2} = length(EEG_backward.epoch);
    save_epoch_num{r, 3} = length(EEG_forward.epoch);

    %% Save the EEG dataset in .set format
    pop_saveset(EEG_forward, 'filename', output_filef, 'filepath', output_dir);
    pop_saveset(EEG_backward, 'filename', output_fileb, 'filepath', output_dir);

    disp('finish')
    
end
