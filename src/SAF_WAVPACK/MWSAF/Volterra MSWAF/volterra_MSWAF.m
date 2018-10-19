% Volterra MWSAF       Multi Structured Wavelet-domain Adaptive Filter Demo
% 
% by A. Castellani & S. Cornell [Universit� Politecnica delle Marche]

addpath '../../Common';             % Functions in Common folder
clear all;  
% close all;

%% Unidentified System parameters

order = 2; 
M1 = 256; % length of first order volterra kernel
M2 = 128; % length of second order volterra kernel

M = [M1, M2];

NL_system = create_volterra_sys(order, M, 'nlsys1'); 


% Adaptive filter parameters

mu = [0.3, 0.3];                 % Step sizes for different kernels 

level = [2, 1];                  % Levels of Wavelet decomposition for different kernels
filters = ['db2'];               % Set wavelet type for different kernels
DWT_flag = 0; 

% Run parameters
iter = 1.0*80000;                % Number of iterations



%%
tic;
% Adaptation process
fprintf('Wavelet type: %s, levels: %d, step size = %f \n', filters, level, mu);
[un,dn,vn] = GenerateResponses_Volterra(iter, NL_system ,sum(100*clock),1,40); %iter, b, seed, ARtype, SNR
% [un,dn,vn] = GenerateResponses_speech_Volterra(NL_system,'SpeechSample.mat');

S = SWAFinit(M, mu, level, filters); 
% S = MWSAFinit(M,mu,level,filters,Q);
S.unknownsys = b; 

if DWT_flag == 1
    [en, S] = MWSAFadapt_DWT(un, dn, S); 
else
    [en, S] = MWSAFadapt(un, dn, S);                
end
    

err_sqr = en.^2;
    
fprintf('Total time = %.3f mins \n',toc/60);

figure;         % Plot MSE
q = 0.99; MSE = filter((1-q),[1 -q],err_sqr);
hold on; plot((0:length(MSE)-1)/1024,10*log10(MSE));
axis([0 iter/1024 -60 10]);
xlabel('Number of iterations (\times 1024 input samples)'); 
ylabel('Mean-square error (with delay)'); grid on;
fprintf('MSE = %.2f dB\n', mean(10*log10(MSE(end-2048:end))))

% figure;                          % Plot misalignment
% hold on; plot((0:length(EML)-1)/1024,10*log10(EML));
% xlabel('Number of iterations (\times 1024 input samples)'); 
% ylabel('Misalignment (dB)');
% grid on;


% %% time domain parameters
% fs = 512; % samples per sec
% freq = 100; % frequency
% dt = 1/fs; 
% 
% %% impulse response
% delta = [1; zeros(fs-2-1,1)];
% figure; 
% subplot(2,1,1)
% stem(delta);
% title('Input Signal'); 
% % axis([0 10 -1.5 1.5])
% out_resp = SWAFtest_WAVPACK_v2(delta, S, Ovr); 
% subplot(2,1,2)
% stem(out_resp);
% title('Output Signal-Estimated System vs True');
% hold on; 
% real_resp = filter(b, 1, delta);
% stem(real_resp); 
% % axis([0 2*M -1.5 1.5])
% 
% %% sine test signal 
% amplitude = 1; 
% leng = 1;
% input_sine = amplitude*sin(2*pi*freq*(0:dt:leng-dt));
% 
% figure; 
% subplot(2,2,1)
% plot(input_sine);
% title('Input Signal'); 
% out_sine = SWAFtest_WAVPACK_v2(input_sine, S, Ovr); 
% subplot(2,2,2)
% plot(out_sine);
% title('Output Signal - Estimated System vs True');
% hold on; 
% real_sys = filter(b,1,input_sine);
% plot(real_sys); legend('Estim', 'True');
% 
% %% FFT 
% N = 2*fs;
% faxis = linspace(-fs/2,fs/2,N);
% 
% subplot(2, 2, 3);
% fft_true = abs(fft(input_sine, N)/N);
% plot(faxis, fftshift(fft_true)); 
% xlabel('Frequency');
% 
% subplot(2, 2, 4);
% fft_out_est = abs(fft(out_sine, N)/N);
% plot(faxis, fftshift(fft_out_est)); 
% xlabel('Frequency');
% hold on; 
% fft_out_true = abs(fft(real_sys,N)/N);
% plot(faxis, fftshift(fft_out_true));
