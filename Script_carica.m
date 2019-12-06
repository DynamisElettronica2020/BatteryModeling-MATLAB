global S1
global dati
% if length(S1)==1
%     if length(S1.Status)==4
%         fclose(S1);
%     end
% end

clear all
close all
clc

%Duration = 10;

%IL #lem piccolo
%IH #lem grande
%V #tensione cella
%Tp #temperatura piatto dissipaz
%En
Tset = 40;

S1=serial('COM5'); % assegnazione

S1.BaudRate =9600;
S1.Terminator={'',''}; % azzera i terminator
S1.DataBits=8; % 8 bit di dati
S1.Parity='none'; % nessun bit di parità
S1.StopBits=1;  % uno stop bit
S1.InputBufferSize=38; % lunghezza pacchetto dati in ingresso

S1.Timeout=1; % 5 sec di time out in secondi se non riceve risposta
dati=[];
fopen(S1);
k=0;

while 1
c=clock;
k=k+1;
%     Cur=y(k);
Cur=-4;
Temp=40;
BigTa=0;

%  if mod(k, 80)<40
%      Cur=2;
%  else
%      Cur=-2;
%  end

RefCur=round(Cur*10);
RefTemp=round(Temp*10);
buffer=['set' sprintf('%+05d%04d%d',RefCur,RefTemp,BigTa)];
%set00010

clc
fwrite(S1,buffer);% spedizione buffer
pause(.05);
Dato = double(fread(S1, 38)');
OutVect=-1*ones(1,19);
if size(Dato,2)==38
    OutVect(01)=(bitshift(Dato(01),8) +Dato(02)); %1 CurrentL
    OutVect(02)=(bitshift(Dato(03),8) +Dato(04)); %2 CurrentH
    OutVect(03)=(bitshift(Dato(05),8) +Dato(06))/10000; %3Voltage
    OutVect(04)=(bitshift(Dato(07),8) +Dato(08))/100; % 4 Temp Plate
    OutVect(05)=(bitshift(Dato(09),8) +Dato(10))/100; % 5 Temp 1
    OutVect(06)=(bitshift(Dato(11),8) +Dato(12))/100; % 6 Temp 2
    OutVect(07)=(bitshift(Dato(13),8) +Dato(14))/100; % 7 Temp 3
    OutVect(08)=(bitshift(Dato(15),8) +Dato(16))/100; % 8 Temp 4
    OutVect(09)=(bitshift(Dato(17),8) +Dato(18))/100; % 9 Temp 5
    OutVect(10)=(bitshift(Dato(19),8) +Dato(20))/100; %10 Temp 6
    OutVect(11)=(bitshift(Dato(21),8) +Dato(22))/100; %11 Temp 7
    OutVect(12)=(bitshift(Dato(23),8) +Dato(24))/100; %12 Temp 8

    OutVect(13)=(bitshift(Dato(25),8) +Dato(26))*100/2^16; %13PWM gate
    OutVect(14)=(bitshift(Dato(27),8) +Dato(28))*100/2^16; %14PWM CbI
    OutVect(15)=(bitshift(Dato(29),8) +Dato(30))*100/2^16; %15PWM Pelt1
    OutVect(16)=(bitshift(Dato(31),8) +Dato(32))*100/2^16; %16PWM Pelt2
    OutVect(17)=(bitshift(Dato(33),8) +Dato(34)); %17 Stato MacchinaCorrente
    OutVect(18)=(bitshift(Dato(35),8) +Dato(36)); %18 Stato MacchinaTemperatura      
    OutVect(19)=(bitshift(Dato(37),8) +Dato(38)); %19 stato allarmi
end
if OutVect(1)>2^15
    OutVect(1)=OutVect(1)-2^16;
end
if OutVect(2)>2^15
    OutVect(2)=OutVect(2)-2^16;
end
OutVect(1:2)=OutVect(1:2)/100;


disp(sprintf('%05d',k))
disp(sprintf('IL %06.2f IH %06.2f Ref %06.2f',OutVect(1),OutVect(2),Cur))
disp(sprintf('V %06.4f',OutVect(3)))
disp(sprintf('Tp %06.2f T1 %06.2f',OutVect(4), OutVect(5)))
disp(sprintf('T2 %06.2f T3 %06.2f',OutVect(6), OutVect(7)))
disp(sprintf('T4 %06.2f T5 %06.2f',OutVect(7), OutVect(8)))
disp(sprintf('T6 %06.2f T7 %06.2f',OutVect(9), OutVect(10)))
disp(sprintf('T8 %06.2f',OutVect(11)))
% if OutVect(3)<2.75&&k>3
%     break
% end
if OutVect(19)>0
StBit=fliplr(dec2bin(OutVect(19),16));
disp(['EnDataRxBuff     ' num2str(StBit(1))]);
disp(['EmergencySet     ' num2str(StBit(2))]);
disp(['TempPlateAllarm  ' num2str(StBit(3))]);
disp(['TempPeltAllarm   ' num2str(StBit(4))]);
disp(['TempCellaAllarm  ' num2str(StBit(5))]);
disp(['AllarmVmin       ' num2str(StBit(6))]);
disp(['AllarmVmax       ' num2str(StBit(7))]);
disp(['PastPeltier      ' num2str(StBit(8))]);
disp(['AllarmConnection ' num2str(StBit(9))]);
disp(['AllarmTempPolo   ' num2str(StBit(10))]);
disp(['AllarmCharger    ' num2str(StBit(11))]);
disp(['BigTA            ' num2str(StBit(16))]);
end

disp(sprintf('Gate %06.2f',OutVect(13)))
disp(sprintf('CbI   %06.2f',OutVect(14)))
disp(sprintf('Pelt1 %06.2f',OutVect(15)))
disp(sprintf('Pelt2 %06.2f',OutVect(16)))



% disp(Dato(33))
% disp(OutVect(17))
switch OutVect(17)
    case 0, disp('CurNOREF');
    case 1, disp('CurWAITTELE1');
    case 2, disp('CurZEROCUR');
    case 3, disp('CurREGMOS');
    case 4, disp('CurWAITTELE2');
    case 5, disp('CurREGCB');
    case 6, disp('CurWaitForShutDown');
    case 7, disp('CurEMERGENCY');
    otherwise, disp('CurNP');
end

switch OutVect(18)
    case 0, disp('TempNEUTRAL');
    case 1, disp('TempSCALDATANTO');
    case 2, disp('TempSCALDAPOCO');
    case 5, disp('TempRAFFREDDA');
    case 6, disp('TempEMERGENCY');
    otherwise, disp('TempNP');
end



if k==1
    figure
    subplot 211
    hold on
    grid on
    subplot 212
    hold on
    grid on
end
if k>=1
    subplot 211,%ylim([45 50])
    % plot(k,mean(OutVect(5:6)),'o',k,max([OutVect(7:8),OutVect(11:12)]),'o')
    if Cur>0
    plot(k,OutVect(13),'ob')
    else
        plot(k,OutVect(14),'ob')
    end
    subplot 212
    % plot(k,OutVect(16)-OutVect(15),'o')
    plot(k,Cur,'or')
    if BigTa==1
        plot(k,OutVect(2),'ob')
    else
        plot(k,OutVect(1),'ob')
    end
end
pause(0.4)
OutVectOld=OutVect;
end