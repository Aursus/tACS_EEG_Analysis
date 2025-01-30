clear
clc

% addpath 'D:\matlab\eeglab2023.0'
% eeglab;
% close(gcf);
% % 
load("D:\Lab_Proj_1\Python_EEG_Code\final_\Basic Power Analysis\data_save\ds_backward_compile.mat")
EEG_backward = ds_backward;

load("D:\Lab_Proj_1\Python_EEG_Code\final_\Basic Power Analysis\data_save\ds_forward_compile.mat")
EEG_forward = ds_forward;

load("D:\Lab_Proj_1\Python_EEG_Code\final_\Basic Power Analysis\data_save\nback_corr_compile.mat");
EEG_3back = EEG_3back_join;

load('D:\Lab_Proj_1\Python_EEG_Code\final_\Basic Power Analysis\data_save\xtarg_corr_compile.mat');
EEG_xtarget = EEG_xtarget_join;

load("D:\Lab_Proj_1\Python_EEG_Code\final_\Basic Power Analysis\data_save\rsEEG_compile.mat");
EEG_rs = EEG_rs_join;

close all
% % mytitle = 'XTarg' || 'NBack' || 'rsEEG'
% basic parameter setting
EEG = EEG_rs_join.EEG(1);
fs = EEG_rs_join.EEG(1).srate;
times = EEG_rs_join.EEG(1).times;
times_sec = times/fs;
n_channel = length(EEG.chanlocs);
n_time = length(times);
cond_name = {'PreSham','PostSham','PreActive','PostActive'};

%%
selec_flag = 'yes'; % 'yes'=use select channel; 'no'=use average of all channel
select_channel = {'F3','F7','T7','FC5'};
select_channel_idx = find(ismember({EEG.chanlocs.labels}, select_channel));
select_channel_name = {EEG.chanlocs(select_channel_idx).labels};

ITF_compile = ds_backward;
ITF_compile = removevars(ITF_compile, {'task','Avg_EEG','EEG','epoch','event','visit'});

theta_range = [4,8];
ITF_compile = f_calculate_ITF_table(ITF_compile, EEG_backward, selec_flag,times_sec,select_channel_idx,theta_range,fs);
ITF_compile = f_calculate_ITF_table(ITF_compile, EEG_forward, selec_flag,times_sec,select_channel_idx,theta_range,fs);
ITF_compile = f_calculate_ITF_table(ITF_compile, EEG_xtarget, selec_flag,times_sec,select_channel_idx,theta_range,fs);
ITF_compile = f_calculate_ITF_table(ITF_compile, EEG_3back, selec_flag,times_sec,select_channel_idx,theta_range,fs);
ITF_compile = f_calculate_ITF_table(ITF_compile, EEG_rs, selec_flag,times_sec,select_channel_idx,theta_range,fs);

writetable(ITF_compile, 'ITF_compile_4channel_theta.xlsx');