global S1
global stato

if length(S1)==1
 if length(S1.Status)==4
     fclose(S1);
 end
end

clear all
close all
clc

filename="carica0612n5.csv";
Duration = 1.5;
start_timestamp=datetime("now");

S1=serial('COM4'); % assegnazione

S1.BaudRate = 9600;
S1.Terminator= {'',''}; % azzera i terminator
S1.DataBits = 8; % 8 bit di dati
S1.Parity='none'; % nessun bit di parità
S1.StopBits=1;  % uno stop bit
S1.InputBufferSize=38; % lunghezza pacchetto dati in ingresso
S1.Timeout=1; % 5 sec di time out in secondi se non riceve risposta

fopen(S1);

fid1 = fopen(filename, 'w');
temp=fopen(".filetemp","w");
fclose(temp);
k=0;
fprintf(fid1,'ore; minuti; secondi; corrente; tensione; lemcurr; lemref; temperatura;\n');

%IMPOSTO LE PORTE
Vport      = 'ai0';
LemSigport = 'ai4';
LemRefport = 'ai1';
T1peltport = 'ai5';
T2peltport = 'ai2';

%CONFIGURAZIONE
s = daq.createSession('ni');

s.DurationInSeconds = Duration;

Vch    = addAnalogInputChannel(s,'Dev1', Vport, 'Voltage');
LemSig = addAnalogInputChannel(s,'Dev1', LemSigport, 'Voltage');
LemRef = addAnalogInputChannel(s,'Dev1', LemRefport, 'Voltage');
T1pelt = addAnalogInputChannel(s,'Dev1', T1peltport, 'Voltage');
T2pelt = addAnalogInputChannel(s,'Dev1', T2peltport, 'Voltage');

Vch.TerminalConfig    = 'SingleEnded';
LemSig.TerminalConfig = 'SingleEnded';
LemRef.TerminalConfig = 'SingleEnded';
T1pelt.TerminalConfig = 'SingleEnded';
T2pelt.TerminalConfig = 'SingleEnded';

c=clock;

LEM=0;
CellV=3.0;
Temp1=20;
Temp2=20;
Temp=20;
current_setpoint=0;
temp_setpoint=60; %!!!!!!!!
stato=1;
temperatura=25;
while stato
    lh = addlistener(s,'DataAvailable', @(src, event)saveData(src, event, fid1, c, LEM));
    
    c=clock;
    k=k+1;
    
    BigTa=0;
    
    if k>1
        
        if abs(temperatura-temp_setpoint)>2
            if temperatura<temp_setpoint
                Temp=60;
            else
                Temp=10;
            end
        else
            if abs(temperatura-temp_setpoint)>0.7
               if temperatura<temp_setpoint
                    Temp=mean([Temp1 Temp2])+2;
                else
                    Temp=mean([Temp1 Temp2])-2;
               end
            else
                Temp=mean([Temp1 Temp2]);
            end
            
        end
        startBackground(s)
    end
       
        switch stato
            case 1 %scarica
                if datetime("now")-start_timestamp>"00:04:00";
                    stato=3;
                    start_timestamp=datetime("now");
                    if CellV<2.53
                        stato=4;
                    end
                else
                    current_setpoint=1;
                end
            case 2 %carica
                if datetime("now")-start_timestamp>"00:04:00";
                    stato=4;
                    start_timestamp=datetime("now");
                    if CellV>4.17
                        stato=4;
                    end
                else
                    current_setpoint=-1.5;
                end
            case 3 %rilassamento scarica
                if datetime("now")-start_timestamp>"00:20:00";
                    stato=1;
                    pause(15);
                    start_timestamp=datetime("now");
                else
                    current_setpoint=0;
                end
            case 4 %rilassamento carica
                if datetime("now")-start_timestamp>"00:20:00";
                    stato=2;
                    pause(15);
                    start_timestamp=datetime("now");
                else 
                    current_setpoint=0;
                end
         end
%             if fast
%                 current_setpoint = current_fast;
%             else
%                 current_setpoint = current_slow;
%             end
%         case 2
%             if fast
%                 current_setpoint = current_fast;
%             else
%                 current_setpoint = current_slow;
%             end
%         
    RefCur=round(current_setpoint*10);
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
    disp(sprintf('IL %06.2f IH %06.2f Ref %06.2f',OutVect(1),OutVect(2),current_setpoint))
    disp(sprintf('V %06.4f',OutVect(3)))
    disp(sprintf('Tp %06.2f T1 %06.2f',OutVect(4), OutVect(5)))
    disp(sprintf('T2 %06.2f T3 %06.2f',OutVect(6), OutVect(7)))
    disp(sprintf('T4 %06.2f T5 %06.2f',OutVect(7), OutVect(8)))
    disp(sprintf('T6 %06.2f T7 %06.2f',OutVect(9), OutVect(10)))
    disp(sprintf('T8 %06.2f %06.2f',OutVect(11), Temp))
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

    disp(sprintf('Gatte %06.2f',OutVect(13)))
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
        if current_setpoint>0
            plot(k,OutVect(13),'ob')
        else
            plot(k,OutVect(14),'ob')
        end
        subplot 212
        plot(k,current_setpoint,'or')
        if BigTa==1
            plot(k,OutVect(2),'ob')
        else
            plot(k,OutVect(1),'ob')
        end
    end
    
    CellV=OutVect(03);
    LEM=OutVect(BigTa+1);
    Temp1=OutVect(05);
    Temp2=OutVect(06);
    
    while s.IsRunning
        pause(0.0001)
    end
    temp=fopen(".filetemp","r");
    temperatura=fread(temp, 'double')*100;
    fclose(temp);
    delete(lh);
end

%lh = addlistener(s,'DataAvailable', @(src, event)saveData(src, event, fid1, c, LEM, CellV, Temp1, Temp2));

function saveData(src, event, fid, c, LEM)
         temp=fopen(".filetemp","w");
         fwrite(temp, mean(mean(event.Data(1:100,4:5))), 'double');
         fclose(temp);
         fprintf(fid,'%d; %d; %02.3f;%6.3f;%6.3f;%6.3f;%6.3f;%6.3f;\n', c(4), c(5), c(6)+event.TimeStamps(26),...
         LEM, mean(event.Data(1:50,1)), mean(event.Data(1:50,2)), mean(event.Data(1:50,3)), mean(mean(event.Data(1:50,4:5))));
         fprintf(fid,'%d; %d; %02.3f;%6.3f;%6.3f;%6.3f;%6.3f;%6.3f;\n', c(4), c(5), c(6)+event.TimeStamps(76),...
             LEM, mean(event.Data(51:100,1)), mean(event.Data(51:100,2)), mean(event.Data(51:100,3)), mean(mean(event.Data(51:100,4:5))));
end