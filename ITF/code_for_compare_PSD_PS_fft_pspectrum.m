% Define parameters
Fs = 1000;            % Sampling frequency (Hz)
T = 1/Fs;             % Sampling period (s)
L = 1000;             % Signal length
t = (0:L-1)*T;        % Time vector

% Generate a sample signal (sum of two sine waves)
f1 = 50;              % Frequency of the first sine wave (Hz)
f2 = 120;             % Frequency of the second sine wave (Hz)
signal = 0.7*sin(2*pi*f1*t) + sin(2*pi*f2*t);

figure
subplot(311)
plot(t,signal)
title('Signal in Time Domain')
grid on
xlabel('Time (s)')
ylabel('Amplitude')

% Compute FFT
Y = fft(signal);

% Compute double-sided and single-sided spectrum
P2 = abs(Y*(1/L));        % Double-sided spectrum
P1 = P2(1:L/2+1);     % Single-sided spectrum
P1(2:end-1) = 2*P1(2:end-1); % Amplitude correction for single-sided spectrum

% Compute frequency vector
f = Fs*(0:(L/2))/L;

% Plot power spectrum
subplot(312)
plot(f,pow2db(P1))
hold on
grid on
xlabel('Frequency (Hz)')
ylabel('Power Spectrum (dB)')

[pxx_ps,f_ps] = pspectrum(signal,Fs);
plot(f_ps,pow2db(pxx_ps))
title('Power Spectrum')
grid on
xlabel('Frequency (Hz)')
ylabel('Power Spectrum (dB)')
legend('FFT','pspectrum')

% Compute power spectrum (power density)
powerSpectrum = abs(Y).^2 * (1/L)*(1/Fs);
powerSpectrum = powerSpectrum(1:L/2+1);

% Plot power spectrum density
subplot(313)
plot(f,powerSpectrum)
hold on
xlabel('Frequency (Hz)')
ylabel('PSD in dB')

[pxx_ps,f_ps] = pspectrum(signal,Fs);
plot(f_ps,pxx_ps.^2)
title('Power Spectrum Density')
grid on
xlabel('Frequency (Hz)')
ylabel('Power Spectrum Density (dB)')
legend('FFT','pspectrum')
