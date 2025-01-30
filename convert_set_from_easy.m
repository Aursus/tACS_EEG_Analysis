% Define input and output directories
input_dir = 'C:\Users\Yuji Han\Downloads\Pre Rest Eyes Open\Pre Rest Eyes Open\';
output_dir = 'C:\Users\Yuji Han\Downloads\Pre Rest Eyes Open\Pre Rest Eyes Open\';
addpath('D:\matlab\eeglab2023.0');  % replace with EEGLAB path
% Get a list of all .easy files in the input directory
file_list = dir(fullfile(input_dir, '*.easy'));

% Step through each file in the directory
for i = 1:length(file_list)
    % Get the current filename
    input_file = file_list(i).name;
    
    % Load the .easy file using EEGLAB
    easy_file_path = fullfile(input_dir, input_file);
    [EEG, command] = pop_easy(easy_file_path);
    
    % Extract information from the input filename to create the output filename
    [~, base_filename, ~] = fileparts(input_file);
    parts = strsplit(base_filename, '_');
    output_file = [strjoin(parts(2:end), '_') '.set'];
    
    % Add channel locations
    % Replace 'D:\matlab\eeglab2023.0\plugins\EEGLab-Plugin-master\Locations\Starstim32.locs' with the actual path to the .locs file
    chan_locs_file = 'D:\matlab\eeglab2023.0\plugins\EEGLab-Plugin-master\Locations\Starstim32.locs';
    EEG = pop_chanedit(EEG, 'lookup', chan_locs_file);
    
    % Save the EEG dataset in .set format
    output_file_path = fullfile(output_dir, output_file);
    EEG = pop_saveset(EEG, 'filename', output_file, 'filepath', output_dir);
    
    % Clean up and close EEGLAB
    eeglab redraw;
    close(gcf);
end
