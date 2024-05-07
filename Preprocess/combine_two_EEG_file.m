%% combine two files
dir = 'Dir_Folder';
EEG1 = pop_loadset('filename', 'Set_File_Name_1', 'filepath', dir);
EEG2 = pop_loadset('filename', 'Set_File_Name_2', 'filepath', dir);
EEG =  pop_mergeset(EEG1, EEG2);
pop_saveset(EEG, 'filename', 'Set_File_Name_Output', 'filepath', dir);