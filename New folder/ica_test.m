%% Test Data For ICA
EEG_before = pop_loadset('filename', '3014-2 ICA.set');
EEG_after= pop_loadset('filename', '3014-2 ICA 2.set');
subplot(211)
plot (EEG_before.times', EEG_before.data(:,:,1)');
subplot(212)
plot (EEG_after.times', EEG_after.data(:,:,1)');
