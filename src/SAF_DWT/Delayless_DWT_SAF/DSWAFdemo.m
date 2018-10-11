% DSWAFdemo          Delayless Subband Wavelet-domain Adaptive Filter Demo
% 
% by A. Castellani & S. Cornell [Universit� Politecnica delle Marche]

addpath 'Common';             % Functions in Common folder
clear all;  close all;

% Adaptive filter parameters
mu = 0.03;                        % Step size
M = 256;                         % Length of unknown system response
level = 2;                       % Levels of Wavelet decomposition
wtype = 'db8';                   % Wavelet family
J = 4;
Q = 1;                           % Flag for QMF filter bank
% dwtmode('zpd')

% Run parameters
iter = 4.0*80000;                % Number of iterations
b = load('h1.dat');              % Unknown system (select h1 or h2)
b = b(1:M);                      % Truncate to length M

% b = rand(M,1)-0.5;
% b = sign(b);

% TESTING, a = delay.
% a = 1;
% b = zeros(M,1);
% b(a+1) = 1;

%% low pass filter system 
% norm_freq = 0.39;
% samples = M/2-1;
% 
% b = norm_freq*sinc(norm_freq*(-samples-1:samples));
%b = b + upsample(b(1:2:M).^4,2) + upsample(downsample(b,2).^6,2);
%b = horzcat(b, zeros(M-length(b)-1,1)');
% 
% %distort the low pass simple
% a = 0.5;
% k = 2*a/(1-a);
% b = (1+k)*(b)./(1+k*abs(b));

%  %% load reverb 
%  [y,Fs] = audioread('reverb_shimmer.wav');
%  y = resample(y, 1,100);
%  M = 1024;
%  b = y(500:M+500-1);

%%
tic;
% Adaptation process
fprintf('Wavelet type: %s, levels: %d, step size = %f \n', wtype, level, mu);
[un,dn,vn] = GenerateResponses(iter,b,sum(100*clock),6,40); %iter, b, seed, ARtype, SNR
S = DSWAFinit(M, mu, level, wtype, J, Q);   % Initialization
S.unknownsys = b; 
% [en, S] = DSWAFadapt(un, dn, S); 
[en, S] = DSWAFadapt_v2(un, dn, S); 
err_sqr = en.^2;
EML = S.eml.^2;                     % System error norm (normalized)
    
fprintf('Total time = %.3f mins \n',toc/60);

figure;         % Plot MSE
q = 0.99; MSE = filter((1-q),[1 -q],err_sqr);
hold on; plot((0:length(MSE)-1)/1024,10*log10(MSE));
axis([0 iter/1024 -60 10]);
xlabel('Number of iterations (\times 1024 input samples)'); 
ylabel('Mean-square error (with delay)'); grid on;
fprintf('MSE = %.2f dB\n', mean(10*log10(MSE(end-2048:end))))

figure;
hold on; plot((0:length(EML)-1)/1024,10*log10(EML));
xlabel('Number of iterations (\times 1024 input samples)'); 
ylabel('Misalignment (dB)');
grid on;

figure; 
stem([b, S.FULLcoeffs']); legend('Real', 'Estimated');

%% time domain parameters
fs = 512; % samples per sec
freq = 20; % frequency
dt = 1/fs; 

%% impulse response
delta = [1; zeros(fs-2-1,1)];
figure; 
subplot(2,1,1)
stem(delta);
title('Input Signal'); 
out_resp = filter(S.FULLcoeffs,1,delta);
subplot(2,1,2)
stem(out_resp);
title('Output Signal-Estimated System vs True');
hold on; 
real_resp = filter(b, 1, delta);
stem(real_resp); 

%% sine test signal 
amplitude = 1; 
leng = 1;
input_sine = amplitude*sin(2*pi*freq*(0:dt:leng-dt));

figure; 
subplot(2,2,1)
plot(input_sine);
title('Input Signal'); 
out_sine = filter(S.FULLcoeffs,1,input_sine);
subplot(2,2,2)
plot(out_sine);
title('Output Signal - Estimated System vs True');
hold on; 
real_sys = filter(b,1,input_sine);
plot(real_sys); legend('Estim', 'True');

%% FFT 
N = 2*fs;
faxis = linspace(-fs/2,fs/2,N);

subplot(2, 2, 3);
fft_true = abs(fft(input_sine, N)/N);
plot(faxis, fftshift(fft_true)); 
xlabel('Frequency');

subplot(2, 2, 4);
fft_out_est = abs(fft(out_sine, N)/N);
plot(faxis, fftshift(fft_out_est)); 
xlabel('Frequency');
hold on; 
fft_out_true = abs(fft(real_sys,N)/N);
plot(faxis, fftshift(fft_out_true));
