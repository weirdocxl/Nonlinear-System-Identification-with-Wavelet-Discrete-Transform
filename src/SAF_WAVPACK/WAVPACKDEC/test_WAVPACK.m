%% WAVELET PACKET DECOMPOSITION TEST FOR PERFECT RECONSTRUTION

addpath '../../Common';             % Functions in Common folder
clear all; close all

% Testing Signal
% 
d = 256;        %Total signal length
t=0:0.001:10;
un=20*(t.^2).*(1-t).^4.*cos(12*t.*pi)+sin(2*pi*t*5000)+sin(2*pi*t*150);
un = un(1:d)';


%% wavpack parameters

mu = 0.3;                      % ignored here 
M = 256;                        % Length of unknown system response also ignored here
level = 5;                     % Levels of Wavelet decomposition
filters = 'db2';               % Set wavelet type
Ovr = 1;                       % Oversampling factor

% S = QMFInit(M,mu,level,filters);
S = SWAFinit(M, mu, level, filters); 

M = S.length;                     % Unknown system length (Equivalent adpative filter lenght)

H = S.analysis;                   % Analysis filter bank
F = S.synthesis;                  % Synthesis filter bank

% analysis and synthesis are used in reverse to obtain in U.Z a column
% vector with cD in the first position


[len, ~] = size(H);               % Wavelet filter length
level = S.levels;                 % Wavelet Levels
L = S.L.*Ovr;                     % Wavelet decomposition Length, sufilter length [cAn cDn cDn-1 ... cD1 M]
%%
% Init Arrays
for i= 1:level     
       U.c{i} = zeros(L(end-i),2^(i));            
       eD{i} = zeros(L(end-i),2^(i-1));      % Error signa, transformed domain
       eDr{i} = zeros(len,2^(i-1));          % Error signal, time domain
       delays(i) = 2^i-1;                    % Level delay for synthesis
    
          
end 
w = zeros(L(end-i),2^i);           % Last level has 2 columns, cD and cA

w(1,1:end) = 1;                    % set filters to kronecker delta

eD{i} = zeros(1,2^i);              % Last level has 2 columns, cD and cA

pwr = w;
beta = 1./L(2:end-1);

u = zeros(len,1);                 % Tapped-delay line of input signal (Analysis FB)  

ITER = length(un);
en = zeros(1,ITER);               % Initialize error sequence to zero


for n = 1:ITER    
    u = [un(n); u(1:end-1)];        % Input signal vector contains [u(n),u(n-1),...,u(n-M+1)]'

    % Analysis Bank
    U.tmp = u;
    
    for i = 1:level
        if mod(n,2^i/(Ovr)) == 0
            if (i==1 && Ovr == 2)
                HH = H./sqrt(2);
            else
                HH = H;
            end
            
            U.Z = HH'*U.tmp; % column [cD ; cA] 
            
         
            [rows, cols] = size(U.Z);
            
            indx = 1;
            
            for col=1:cols
                for row=1:rows 
                    
                    U.c{i}(:,indx) = cat(1,U.Z(row,col), U.c{i}(1:end-1, indx)); %CA||CD
        
                indx=indx+1;
                end  
            end
            
            U.tmp = U.c{i}(1:len,:);    
             
            
            if i == level
                
                eD{i} = sum((U.c{i}).*w);        
        
            end   
            S.iter{i} = S.iter{i} + 1;                
        end
    end    


    % Synthesis Bank
    for i = level:-1:1
            if (i==1 && Ovr == 2)
                FF = F./sqrt(2);
            else
                FF = F;
            end
        if i == level
            if mod(n,2^i/(Ovr)) == 0
                indx = 1; 
               
                for col = 1:2:2^i-1 
                 
                    
                eDr{i}(:,indx) = FF*eD{i}(1,col:col+1)' + eDr{i}(:,indx);
                indx = indx +1;
                
                end
                
                
            end
        else
            if mod(n,2^i/(Ovr)) == 0     
                
                indx = 1; 
                
                for col = 1:2:2^i-1
                eDr{i}(:,indx) = FF*eDr{i+1}(1,col:col+1)' + eDr{i}(:,indx);
                indx = indx +1;
                
                end
                eDr{i+1} = [eDr{i+1}(2:end,:); zeros(1,size(eDr{i+1},2))];
            end            
        end
    end   
    en(n) = eDr{i}(1);
    eDr{i} = [eDr{i}(2:end); 0];           
end

en = en(1:ITER);


%% check for perfect reconstruction

tot_delay = (2^level - 1)*(len-1) +1 ;

stem(en(tot_delay:end));
hold on;
stem(un); 

%% GNA  
clear U en;
a = zeros(len,1); d = zeros(len,1); 

A{1} = zeros(len,2);    
z = zeros(len,1);
w = zeros(M,1);
w(1) = 1;

for i = 1:level
    A{i} = zeros(len,2);
    U{i} = zeros(M,2);
    D{i} = zeros(M,2);
    eDr{i} = zeros(len,1);
    delays(i) = 2^i-1; 
    eD{i} = zeros(L(end-i),1);
end
eD{i} = zeros(1,2);


 t=0:0.001:1;
 un=20*(t.^2).*(1-t).^4.*cos(12*t.*pi)+sin(2*pi*t*5000)+sin(2*pi*t*150);  
 dn = un;

ITER = length(un);
en = zeros(1,ITER);               % Initialize error sequence to zero

	
for n = 1:ITER
    
    d = [dn(n); d(1:end-1)];                       % Update tapped-delay line of d(n)
    a = [un(n); a(1:end-1)];                       % Update tapped-delay line of u(n)
    A{1} = [a, A{1}(:,1:end-1)];                         % Update buffer
    
    % Analysis
    Dtmp = d; 
    for i = 1:level
        if (mod(n,2^i) == 0)
            U1 = (H'*A{i})';                              % Partitioning u(n) 
            U2 = U{i}(1:end-2,:);
            U{i} = [U1', U2']';                           % Subband data matrix (cA || cD)            
            dD = (H'*Dtmp)';
            D{i} = [dD; D{i}(1:end-1,:)];   %cA ; cD
            Dtmp = D{i}(1:len,1);
            
            if i == level
                eD{i} = dD' - U{i}'*w;
            
            else
                A{i+1} = [U{i}(1:2:len*2,1), U{i}(3:2:len*2+1,1)];  %Update buffer for next level, filled with cA
                eD{i} = [eD{i}(2:end); dD(2) - U{i}(:,2)'*w];
            end
        end
    end

    % Synth
    for i = level:-1:1
        if (mod(n, 2^i) == 0)
            if i == level
                eDr{i} = F*eD{i} + eDr{i};
            else
                eDr{i} = F*[eDr{i+1}(1); eD{i}(end-(len-1)*delays(end-i))] + eDr{i};
                eDr{i+1} = [eDr{i+1}(2:end); 0];
            end
        end
    end
    en(n) = eDr{i}(1);
    eDr{i} = [eDr{i}(2:end); 0];  
end

%% check for perfect reconstruction

tot_delay = (2^level - 1)*(len-1) +1 ;

stem(en(tot_delay:end));
hold on;
stem(un); 

    





