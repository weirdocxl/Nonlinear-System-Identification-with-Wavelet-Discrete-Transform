% SWAFdemo          Subband Wavelet-domain Adaptive Filter Demo
% 
% by A. Castellani & S. Cornell [Universit� Politecnica delle Marche]

addpath 'Common';             % Functions in Common folder
clear all;  close all;

% Adaptive filter parameters
mu = 0.1;                      % Step size
M = 256;                       % Length of unknown system response
level = 1;                     % Levels of Wavelet decomposition
filters = 'db2';               % Set wavelet type
Ovr = 1;                       % Oversampling factor

% Run parameters
iter = 1.0*80000;                % Number of iterations
b = load('h1.dat');              % Unknown system (select h1 or h2)
b = b(1:M);                      % Truncate to length M

%b = sign(b);

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
%  M = length(y);
%  b = y(1:M);

%%
tic;
% Adaptation process
fprintf('Wavpack petraglia \n');
fprintf('Wavelet type: %s, levels: %d, step size = %f \n', filters, level, mu);
[un,dn,vn] = GenerateResponses(iter,b,sum(100*clock),1,40); %iter, b, seed, ARtype, SNR
S = QMFInit(M,mu,level,filters);
% S = SWAFinit(M,mu,level,filters);
S.unknownsys = b; 
if level == 1
    [en, S] = Adapt_1layer_af(un, dn, S);                 % Perform WSAF Algorithm 
else
     [en, S] = Adapt_2layer_af(un, dn, S); 
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

