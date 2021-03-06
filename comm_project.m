clear all;clc;
% read the input sound file
[message1,fs]=audioread('Short_QuranPalestine.wav');
[message2,fs]=audioread('Short_FM9090.wav');

if(length(message1)>length(message2))
    message2=wextend('ar','zpd',message2,(length(message1)-length(message2)),'d');
elseif (length(message2)>length(message1))
    message1=wextend('ar','zpd',message1,(length(message2)-length(message1)),'d');
end

%length(message1)=length(message2)=N
N=length(message1);
%converting 2 channel signals to 1 channel signals
message1(:,1)=message1(:,1)+message1(:,2);
message1(:,2) = [];
message2(:,1)=message2(:,1)+message2(:,2);
message2(:,2) = [];
%Upsampling(interpolation) 
message1 = interp(message1,10);
message2 = interp(message2,10);
fs=10*fs;

N=length(message1);
dt = 1/fs; % seconds per sample
StopTime = N/fs; % seconds
t = (0:dt:StopTime-dt)';
F1 = 100000; % cosine wave frequency (hertz)
carrier1 = cos(2*pi*F1*t);
carrier2 = cos(2*pi*(F1+50000)*t);

MESSAGE1=fft(message1);
MESSAGE2=fft(message2);
k=-N/2:N/2-1;
%figure
%plot(k*fs/N,fftshift(abs(MESSAGE1)));
%xlabel('frequency (Hz)');
%ylabel('1st message');

figure('units','normalized','outerposition',[0 0 1 1]);
myPlot(1,{'1st message (m_1)'},MESSAGE1,k,fs,N);
 
%figure
%plot(k*fs/N,fftshift(abs(MESSAGE2)));
%xlabel('frequency (Hz)');
%ylabel('2nd message');
myPlot(2,'2nd message (m_2)',MESSAGE2,k,fs,N);

transmitter_output1= message1.*carrier1;
transmitter_output2= message2.*carrier2;
clear message1 MESSAGE1 message2 MESSAGE2;
TRANSMITTER_OUTPUT1=fft(transmitter_output1);
TRANSMITTER_OUTPUT2=fft(transmitter_output2);
%FDM
TRANSMITTER_OUTPUT=TRANSMITTER_OUTPUT1+TRANSMITTER_OUTPUT2;
transmitter_output=ifft(TRANSMITTER_OUTPUT);
 
%figure
%plot(k*fs/N,fftshift(abs(TRANSMITTER_OUTPUT)));
%xlabel('frequency (Hz)');
%ylabel('FDM for the 2 messages');
myPlot(3,'FDM for the 2 messages',TRANSMITTER_OUTPUT,k,fs,N);

clear transmitter_output1 TRANSMITTER_OUTPUT1...
    transmitter_output2 TRANSMITTER_OUTPUT2; 

%RF_BPF1 specs
Fstop1=0.65e+05; Fpass1=0.75e+05; Astop1=100;
Fpass2=1.25e+05;Fstop2=1.35e+05; Astop2=100;
Apass=1; Fs=fs;
BPF_specs=fdesign.bandpass('Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2', ...
    Fstop1, Fpass1, Fpass2, Fstop2, Astop1, Apass,Astop2,Fs);

BPF = design(BPF_specs);
RF_output1= filter(BPF,transmitter_output);
RF_OUTPUT1=fft(RF_output1);
 
%figure
%plot(k*fs/N,fftshift(abs(RF_OUTPUT2)));
%xlabel('frequency (Hz)');
%ylabel('RF stage: BPF is tuned to select the first station');
myPlot(4,{'RF stage: BPF_1'},RF_OUTPUT1,k,fs,N);

%RF_BPF2 specs
BPF_specs.Fstop1=1.15e+05;
BPF_specs.Fpass1=1.25e+05;
BPF_specs.Fpass2=1.75e+05;
BPF_specs.Fstop2=1.85e+05;
BPF = design(BPF_specs);
RF_output2= filter(BPF,transmitter_output);
RF_OUTPUT2=fft(RF_output2);
 
%figure
%plot(k*fs/N,fftshift(abs(RF_OUTPUT2)));
%xlabel('frequency (Hz)');
%ylabel('RF stage: BPF is tuned to select the second station');
myPlot(5,'RF stage: BPF_2',RF_OUTPUT2,k,fs,N);

clear transmitter_output TRANSMITTER_OUTPUT;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%discussion (absence of RF stage)
%%%%%%%%%%%%%%
%RF_output1=a;
%RF_output2=a;
%RF_OUTPUT2=fft(RF_output1);
%RF_OUTPUT2=fft(RF_output2);
%message1 is corrupted as at C(figure4) there are only 6 signals resulting
%from multiplying 4 signals by cos 
%%%%%%%%%%%%%%

F1_IF = 125000; % cosine wave frequency (hertz)
carrier1_IF = cos(2*pi*F1_IF*t);
mixer_output1=RF_output1.*carrier1_IF;
MIXER_OUTPUT1=fft(mixer_output1);
% 
%figure
%plot(k*fs/N,fftshift(abs(MIXER_OUTPUT1)));
%xlabel('frequency (Hz)');
%ylabel('Mixing message1 with carrier frequency = F1+IF');
myPlot(6,'Mixer: mixing m_1, cos(F_C_1+F_I_F)',MIXER_OUTPUT1,k,fs,N);

F2_IF = 175000; % cosine wave frequency (hertz)
carrier2_IF = cos(2*pi*F2_IF*t);
mixer_output2=RF_output2.*carrier2_IF;
MIXER_OUTPUT2=fft(mixer_output2);
% 
%figure
%plot(k*fs/N,fftshift(abs(MIXER_OUTPUT2)));
%xlabel('frequency (Hz)');
%ylabel('Mixing message2 with carrier frequency = F2+IF');
myPlot(7,'Mixer: mixing m_2, cos(F_C_2+F_I_F)',MIXER_OUTPUT2,k,fs,N);

clear RF_output1 RF_OUTPUT2 RF_output2 RF_OUTPUT2;

%IF_BPF design
BPF_specs.Fstop1=0.001e+05;
BPF_specs.Fpass1=0.05e+05;
BPF_specs.Fpass2=0.45e+05;
BPF_specs.Fstop2=0.499e+05;
BPF = design(BPF_specs);
IF_output1= filter(BPF,mixer_output1);
IF_OUTPUT1=fft(IF_output1);
 
%figure
%plot(k*fs/N,fftshift(abs(IF_OUTPUT1)));
%xlabel('frequency (Hz)');
%ylabel('IF stage: BPF of centre frequency =IF selects message1');
myPlot(8,'IF stage: BPF_1 of W_c_e_n_t_e_r=F_I_F',IF_OUTPUT1,k,fs,N);

IF_output2= filter(BPF,mixer_output2);
IF_OUTPUT2=fft(IF_output2);
 
%figure
%plot(k*fs/N,fftshift(abs(IF_OUTPUT2)));
%xlabel('frequency (Hz)');
%ylabel('IF stage: BPF of centre frequency =IF selects message2');
myPlot(9,'IF stage: BPF_2 of W_c_e_n_t_e_r=F_I_F',IF_OUTPUT2,k,fs,N);
clear mixer_output1 MIXER_OUTPUT1 mixer_output2 MIXER_OUTPUT2;

F_BaseBand = 25000; % cosine wave frequency (hertz)
carrier_BaseBand = cos(2*pi*F_BaseBand*t);

BB_mixer_output1 = IF_output1.*carrier_BaseBand;
BB_MIXER_OUTPUT1 = fft(BB_mixer_output1);

%figure
%plot(k*fs/N,fftshift(abs(BB_MIXER_OUTPUT1)));
%xlabel('frequency (Hz)');
%ylabel('Baseband detection: mixing message1 with IF carrier');
myPlot(10,'BB detector: mixing m_1, cos(F_I_F)',BB_MIXER_OUTPUT1,k,fs,N);

BB_mixer_output2 = IF_output2.*carrier_BaseBand;
BB_MIXER_OUTPUT2 = fft(BB_mixer_output2);

%figure
%plot(k*fs/N,fftshift(abs(BB_MIXER_OUTPUT2)));
%xlabel('frequency (Hz)');
%ylabel('Baseband detection: mixing message2 with IF carrier');
myPlot(11,'BB detector: mixing m_2, cos(F_I_F)',BB_MIXER_OUTPUT2,k,fs,N);
clear IF_output1 IF_OUTPUT1 IF_output2 IF_OUTPUT2;

%LPF design
Fpass=0.2e+05;
Fstop=0.3e+05;
Apass=1;
Astop=100;
Fs=fs;
LPF_specs=fdesign.lowpass('Fp,Fst,Ap,Ast', ...
    Fpass, Fstop, Apass, Astop, Fs);
LPF = design(LPF_specs);
LPF_output1= filter(LPF,BB_mixer_output1);
LPF_OUTPUT1= fft(LPF_output1);
 
%figure
%plot(k*fs/N,fftshift(abs(LPF_OUTPUT1)));
%xlabel('frequency (Hz)');
%ylabel('Baseband detection: selecting message1 by LPF');
myPlot(12,'BB detector: select m_1 by LPF',LPF_OUTPUT1,k,fs,N);

LPF_output2= filter(LPF,BB_mixer_output2);
clear BB_mixer_output1 BB_MIXER_OUTPUT1 BB_mixer_output2 BB_MIXER_OUTPUT2;
LPF_OUTPUT2= fft(LPF_output2);
 
%figure
%plot(k*fs/N,fftshift(abs(LPF_OUTPUT2)));
%xlabel('frequency (Hz)');
%ylabel('Baseband detection: selecting message2 by LPF');
myPlot(13,'BB detector: select m_2 by LPF',LPF_OUTPUT2,k,fs,N);
xlabel('frequency (kHz)');

audiowrite('message1.wav',LPF_output1,fs);
audiowrite('message2.wav',LPF_output2,fs);

%function for plotting
function [] = myPlot(plot_number,title,signal,k,fs,N)
subplot(13,1,plot_number)
plot(k*fs/(N*10e3),fftshift(abs(signal)));
set(gca,'FontSize',6)
%xlabel('frequency (Hz)');
y=ylabel(title, 'FontSize', 8);
set(get(gca,'YLabel'),'Rotation',0)
set(y, 'position', get(y,'position')-[3,0,0]);
set(gca,'YTick',[])
end