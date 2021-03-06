function [en,S] = SWAFadapt_crossfilt_v2(un,dn,S)
% SWAFadapt         Wavelet-transformed Subband Adaptive Filter (WAF)                 
%
% Arguments:
% un                Input signal
% dn                Desired signal
% S                 Adptive filter parameters as defined in WSAFinit.m
% en                History of error signal

M = S.length;                     % Unknown system length (Equivalent adpative filter lenght)
mu = S.step;                      % Step Size
AdaptStart = S.AdaptStart;        % Transient
alpha = S.alpha;                  % Small constant (1e-6)
H = S.analysis;                   % Analysis filter bank
F = S.synthesis;                  % Synthesis filter bank

if flag
    Hi = upsample(H,2);
    Hi = conv2(Hi,H);
    Hi = Hi(1:end-1,:);
    H = Hi;
    F = flip(Hi);
end
    

[len, ~] = size(H);               % Wavelet filter length
level = S.levels;                 % Wavelet Levels
L =  S.L./2;                          % Wavelet decomposition Length, sufilter length [cAn cDn cDn-1 ... cD1 M]

% Init Arrays
for i= 1:level
    U.cD{i} = zeros(L(end-i),1);    
    U.cA{i} = zeros(L(end-i),1);    
    
    Y.cD{i} = zeros(L(end-i),1);
    Y.cA{i} = zeros(L(end-i),1);
    
    eD{i} = zeros(L(end-i),1);      % Error signa, transformed domain
    eDr{i} = zeros(len,1);          % Error signal, time domain
    delays(i) = 2^i-1;              % Level delay for synthesis
    w{i} = zeros(L(end-i),1);       % Subband adaptive filter coefficient, initialize to zeros 
    w_cross{i} = zeros(L(end-i),1);
    
end 
w{i} = zeros(L(end-i),2);           % Last level has 3 columns, cD and cA and cross filter
w_cross{i} = zeros(L(end-i),2); 
eD{i} = zeros(L(end-i),2);
x_cross = zeros(L(end-i),1);
x_cross_filt = 0;
w_cross_filt = 0;

U.tmp = zeros(len,1);
Y.tmp = zeros(len,1);
U.Z = zeros(2,1);
Y.Z = zeros(2,1);

% pwr = w;
% beta = 1./L(2:end-1);

u = zeros(len,1);                 % Tapped-delay line of input signal (Analysis FB)  
y = zeros(len,1);                 % Tapped-delay line of desired response (Analysis FB)

ITER = length(un);
en = zeros(1,ITER);               % Initialize error sequence to zero


for n = 1:ITER    
    u = [un(n); u(1:end-1)];        % Input signal vector contains [u(n),u(n-1),...,u(n-M+1)]'
    y = [dn(n); y(1:end-1)];        % Desired response vector        

    % Analysis Bank
    U.tmp = u;
    Y.tmp = y;
    for i = 1:level
        if mod(n,2^i) == 0
            U.Z = H'*U.tmp;
            U.cD{i} = [U.Z(2); U.cD{i}(1:end-1)]; 
            U.cA{i} = [U.Z(1); U.cA{i}(1:end-1)];
            U.tmp = U.cA{i}(1:len);
            
            Y.Z = H'*Y.tmp;
            Y.cD{i} = [Y.Z(2); Y.cD{i}(1:end-1)]; 
            Y.cA{i} = [Y.Z(1); Y.cA{i}(1:end-1)];
            Y.tmp = Y.cA{i}(1:len);
            
            if i == level  
                               
                x1 = sum(U.cA{i}.*w{i}(:,1));
                x2 = sum(U.cD{i}.*w{i}(:,2)); 
                
                cross_x1 = sum(U.cD{i}.*w_cross{i}(:,1));
                cross_x2 = sum(U.cA{i}.*w_cross{i}(:,2));
                
                eD{i} = [Y.Z' - [x1+cross_x1, x2+cross_x2]; eD{i}(1:end-1,:)]; %[E0, E1]; %Z = cA || cD;
                
                if n >= AdaptStart(i)
%                     pwr{i} = beta(i)*pwr{i}+ (1-beta(i))*([U.cA{i},U.cD{i}].*[U.cA{i},U.cD{i}]);
%                     w{i} = w{i} + mu*[U.cA{i},U.cD{i}].*eD{i}./((sum(pwr{i})+alpha)); 
                    w{i} = w{i} + mu*[U.cA{i},U.cD{i}].*eD{i}(1,:)./(sum([U.cA{i},U.cD{i}].*[U.cA{i},U.cD{i}])+alpha);                     
                    w_cross{i} = w_cross{i} + mu*[U.cD{i},U.cA{i}].*eD{i}(1,:)./(sum([U.cD{i},U.cA{i}].*[U.cD{i},U.cA{i}])+alpha); 
%                     x_cross = x_cross + (mu*eD{i-1}(end-1)/(U.cD{i}'*U.cD{i} + alpha))*U.cD{i};  
%                     w_cross{i-1} = w_cross{i-1} + (mu*eD{i}(1,2)/(U.cD{i-1}'*U.cD{i-1} + alpha))*U.cD{i-1}; 
                end                 
%                 x_cross_filt = sum(U.cD{i}.*x_cross);
%                 w_cross_filt = sum(U.cD{i-1}.*w_cross{i-1});
            else
                eD{i} = [eD{i}(2:end); Y.cD{i}(1) - (U.cD{i}'*w{i})];    
%                 U.tmp(1) = U.tmp(1) + sum(U.cD{i}.*(-1*w_cross{i}));
                U.tmp(1) = U.tmp(1) + sum(U.cD{i}.*-w_cross{i});
                
                if n >= AdaptStart(i)
%                     pwr{i} = beta(i)*pwr{i}+ (1-beta(i))*(U.cD{i}.*U.cD{i});
%                     w{i} = w{i} + (mu*eD{i}(end)/((sum(pwr{i}) + alpha)))*U.cD{i};
                    w{i} = w{i} + (mu*eD{i}(end)/(U.cD{i}'*U.cD{i} + alpha))*U.cD{i};  
                     
                end                                
            end           
            S.iter{i} = S.iter{i} + 1;                
        end
    end    


    % Synthesis Bank
    for i = level:-1:1
        if i == level
            if mod(n,2^i) == 0
                eDr{i} = F*eD{i}(1,:)' + eDr{i};
            end
        else
            if mod(n,2^i) == 0                
                eDr{i} = F*[eDr{i+1}(1); eD{i}(end-(len-1)*delays(end-i))] + eDr{i};
                eDr{i+1} = [eDr{i+1}(2:end); 0];
            end            
        end
    end   
    en(n) = eDr{i}(1);
    eDr{i} = [eDr{i}(2:end); 0];           
end

en = en(1:ITER);
S.coeffs = [w, w_cross];
end



