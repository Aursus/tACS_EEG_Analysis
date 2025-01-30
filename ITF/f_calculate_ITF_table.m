function ITF_compile = f_calculate_ITF_table(ITF_compile,EEG_rs_join,selec_flag,times,select_channel_idx,theta_range,fs)

    for i = 1:height(EEG_rs_join)
        data = EEG_rs_join.Avg_EEG{i};
        if size(data,2)==2500
            data = data(:,751:2250);
        end

        % get average
        if strcmp(selec_flag,'yes')
            data = mean(data(select_channel_idx,:),1);
        elseif strcmp(selec_flag,'no')
            data = mean(data,1);      
        end

        % calculate spectrum
%         [spectra,freqs_spec] = spectopo(data, 0, fs,'nfft',5000,'freqrange',[0,60],'plot','off');
%         [spectra,freqs_spec] = pwelch(data',[],[],[],fs);
        [spectra,freqs_spec] = pspectrum(data,times);
%         figure
%         plot(freqs_spec,spectra)
%         xlim([4,8])
%         spectra = pow2db(spectra);

        % get spectrum within theta band
        idx_theta = find(freqs_spec >= theta_range(1) & freqs_spec <= theta_range(2));
        spectra = double(spectra');
        spec_theta = spectra(:,idx_theta);
        freq_theta = freqs_spec(idx_theta);     % get frequency within theta band
        [spec_peak,idx_peak] = max(spec_theta);   % extract spectrum peak and peak index
        freq_peak = freq_theta(idx_peak);       % extract frequency peak
    
        % calculated match row
        matched_rows = ismember(ITF_compile.subject, EEG_rs_join.subject(i)) & ...
                   ismember(ITF_compile.session, EEG_rs_join.session{i}) & ...
                   ismember(ITF_compile.Stimulation, EEG_rs_join.Stimulation{i});
    
        % save peak freq and peak psd
        switch EEG_rs_join.task{i}
            case 'Backward'
                ITF_compile.Backward_freq(matched_rows) = freq_peak;
                ITF_compile.Backward_psd(matched_rows) = spec_peak;
            case 'Forward'
                ITF_compile.Forward_freq(matched_rows) = freq_peak;
                ITF_compile.Forward_psd(matched_rows) = spec_peak;
            case '3back'
                ITF_compile.Nback_freq(matched_rows) = freq_peak;
                ITF_compile.Nback_psd(matched_rows) = spec_peak;
            case 'xtarget'
                ITF_compile.Xtarg_freq(matched_rows) = freq_peak;
                ITF_compile.Xtarg_psd(matched_rows) = spec_peak;
            case 'Eyes Open'
                ITF_compile.EyesOpen_freq(matched_rows) = freq_peak;
                ITF_compile.EyesOpen_psd(matched_rows) = spec_peak;
            case 'Eyes Close'
                ITF_compile.EyesClose_freq(matched_rows) = freq_peak;
                ITF_compile.EyesClose_psd(matched_rows) = spec_peak;
            otherwise
                disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!')
                disp('ERROR !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!')
                disp(i)
                disp(EEG_rs_join.task{i})
                disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!')
        end
        disp(i)
        disp(freq_theta(2)-freq_theta(1))
    end
    
    

end