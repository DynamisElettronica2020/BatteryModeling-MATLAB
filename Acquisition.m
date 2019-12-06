%INIZIALIZZAZIONE
global S1
global s

global stato
global current_setpoint
global temp_setpoint

global LEM
global CellV
global Temp1
global Temp2

global estT

if length(S1) == 1
 if length(S1.Status) == 4
     fclose(S1);
 end
end

clear all
close all
clc

%VARIABILI DA CONFIGURARE
filename = "file.csv"
Duration = 0.7;
DischgCurr = 50;
Tscarica = "00:04:00";
Trelax = "00:20:00";

%IMPOSTAZIONE E CONFIGURAZIONE PORTE
srl = 'COM8';
Vport = 'ai0';
Aport = 'ai4';
T1port = 'ai1';
T2port = 'ai5';
T3port = 'ai2';
PMW1port = 'Port0/Line0';
PMW2port = 'Port0/Line1';

S1 = serial(srl);
S1.BaudRate = 9600;
S1.Terminator = {'',''}; % azzera i terminator
S1.DataBits = 8; % 8 bit di dati
S1.Parity ='none'; 
S1.StopBits = 1;  
S1.InputBufferSize = 38; 
S1.Timeout = 1;
fopen(S1);

s = daq.createSession('ni');
Vch = addAnalogInputChannel(s,'Dev1',Vport,'Voltage');
T1ch = addAnalogInputChannel(s,'Dev1',T1port,'Voltage');
T2ch = addAnalogInputChannel(s,'Dev1',T2port,'Voltage');
T3ch = addAnalogInputChannel(s,'Dev1',T3port,'Voltage');
Ach = addAnalogOutputChannel(s, 'Dev1', Aport, 'Voltage');

Vch.TerminalConfig = 'SingleEnded';
T1ch.TeerminalConfig = 'SingleEnded';
T3ch.TerminalConfig = 'SingleEnded';

%PWMch1 = addDigitalChannel(s,'Dev1',PMW1port,'OutputOnly');
%PWMch2 = addDigitalChannel(s,'Dev1',PMW2port,'OutputOnly');
PWMch1 = addCounterOutputChannel(s,'Dev1',PMW1port,'PulseGeneration');
PWMch2 = addCounterOutputChannel(s,'Dev1',PMW2port,'PulseGeneration');

PWMch1.Frequency = 10;
PWMch1.InitialDelay = 0;
PWMch2.Frequency = 10;
PWMch2.InitialDelay = 0;

%VARIABILI UTILI
k = 0;
pc = [2.5,5;3.5,5;3.8,4.5;4,2.5;4.1,1.5;4.15,0.5;4.18,0.25;4.19,0.05;4.2,0;5,0];
estT = [2.34793023061828,-16.1889242034018;2.33471742346748,-14.3861360177809;2.32196339434276,-12.5833478321599;2.30746600871898,-10.7805596465390;2.28902313207100,-8.97777146091809;2.27241536752730,-7.17498327529717;2.25644989222009,-5.37219508967625;2.23718121512519,-3.56940690405533;2.21626093713644,-1.76661871843441;2.19680874883110,0.0361694671865180;2.17671427128928,1.83895765280744;2.15391300339364,3.55980092090014;2.13221280276057,5.28064418899284;2.11012009203853,6.91954253955731;2.08817011225793,8.55844089012179;2.06963548000474,10.1973392406863;2.04753155470873,11.7542926737225;2.02331928950625,13.3112461067588;2.00178730748274,14.7862546222668;1.97989849810562,16.4251529728313;1.95905978065484,18.0640513233957;1.93820067306956,19.5390598389038;1.91465006773134,21.0140683544118;1.89379096014607,22.4890768699198;1.87191132632947,24.0460303029561;1.85061485035934,25.7668735710488;1.82773711945936,27.4057719216132;1.80676586613438,28.8807804371213;1.78500959263145,30.4377338701575;1.76372229222185,32.1585771382502;1.74151743576010,33.9613653238711;1.71940433490357,35.7641535094921;1.69719947844182,37.5669416951130;1.67582042242700,39.3697298807339;1.65673525654253,41.1725180663548;1.63627375657984,42.9753062519757;1.61645454585366,44.7780944375967;1.59810342481089,46.5808826232176;1.58204619389847,48.3836708088385;1.56562194056520,50.1864589944594;1.54818837557457,51.9892471800804;1.53323221192472,53.7920353657013;1.52066169401042,55.5948235513222;1.50616430838664,57.3976117369431;1.49129990034200,59.2003999225640;1.47854587121728,61.0031881081850;1.46680115374991,62.8059762938059;1.45634101475553,64.6087644794268;1.44514683091944,66.4115526650477;1.43404440268857,68.2143408506687;1.42569464261411,70.0171290362896;1.41606030406666,71.8199172219105;1.40844458883391,73.6227054075314;1.39780093862911,75.4254935931523;1.38945117855465,77.2282817787733;1.38330355300533,79.0310699643942;1.37596310458822,80.8338581500151;1.36843914496069,82.6366463356360;1.36128220775401,84.4394345212570;1.35834602838716,86.2422227068779;1.35201489162741,88.0450108924988;1.34678482213022,89.8477990781197;1.34146299702782,91.6505872637406;1.33531537147849,93.4533754493616;1.33210392529601,95.2561636349825;1.32834194548224,97.0589518206034;1.32256134235377,98.8617400062243;1.31870760693479,100.664528191845;1.31577142756795,102.467316377466;1.31210120335940,104.270104563087;1.30815571233520,106.072892748708;1.30457724373186,107.875680934329;1.30365968767972,109.678469119950;1.29998946347117,111.481257305571;1.29650275047305,113.284045491192;1.29475939397398,115.086833676813;1.29246550384364,116.889621862434;1.29007985810808,118.692410048054];
start_timestamp = datetime("now");
c = clock;

%SETTO VARIABILI
LEM = 0;
CellV = -1;
Temp1 = -1;
Temp2 = -1;
current_setpoint = DischgCurr;
temp_setpoint = 60;
stato = 1;

%CICLO S/R/C
while stato
    lh = addlistener(s,'DataAvailable', @(src, event)saveData(src, event, fid1, c, LEM, CellV, Temp1, Temp2));
    
    c = clock;
    k = k+1;
    Temp = 10;
    BigTa = 0;
    
    if k>1
        s.startBackground();
    end
    
    %0 STOP
    %1 SCARICA
    %2 CARICA
    %3 RILASSAMENTO
    
      switch stato
          case 1 %SCARICA
              if datetime("now")-start_timestamp > Tscarica
                  stato = 3;
                  start_timestamp = datetime("now");
              else
                  current_setpoint = SetCurrent(DischgCurr);
              end
          case 3 %RILASSAMENTO
              if datetime("now")-start_timestamp > Trelax
                  stato = 1;
                  start_timestamp = datetime("now");
              else 
                  current_setpoint = SetCurrent(0);
              end
         case 2 %CARICA
             if CellV >= 4.2
                 stato = 1;%sicuro?
             else
                 current_setpoint = SetCurrent(-(interp1(pc(:,1), pc(:,2), CellV, 'linear')));
             end
      end
    
    RefCur = round(current_setpoint*10);
    RefTemp = round(Temp*10);
    buffer = ['set' sprintf('%+05d%04d%d',RefCur,RefTemp,BigTa)];
    %set00010

    clc
    fwrite(S1,buffer); % spedizione buffer
    pause(.05);
    Dato = double(fread(S1, 38)');
    OutVect = -1*ones(1,19);

    if size(Dato,2) == 38
        OutVect(01) = (bitshift(Dato(01),8)+Dato(02)); %1 CurrentL
        OutVect(02) = (bitshift(Dato(03),8)+Dato(04)); %2 CurrentH
        OutVect(03) = (bitshift(Dato(05),8)+Dato(06))/10000; %3 Voltage
        
        OutVect(04) = (bitshift(Dato(07),8)+Dato(08))/100; % 4 Temp Plate
        OutVect(05) = (bitshift(Dato(09),8)+Dato(10))/100; % 5 Temp 1
        OutVect(06) = (bitshift(Dato(11),8)+Dato(12))/100; % 6 Temp 2
        OutVect(07) = (bitshift(Dato(13),8)+Dato(14))/100; % 7 Temp 3
        OutVect(08) = (bitshift(Dato(15),8)+Dato(16))/100; % 8 Temp 4
        OutVect(09) = (bitshift(Dato(17),8)+Dato(18))/100; % 9 Temp 5
        OutVect(10) = (bitshift(Dato(19),8)+Dato(20))/100; %10 Temp 6
        OutVect(11) = (bitshift(Dato(21),8)+Dato(22))/100; %11 Temp 7
        OutVect(12) = (bitshift(Dato(23),8)+Dato(24))/100; %12 Temp 8

        OutVect(13) = (bitshift(Dato(25),8)+Dato(26))*100/2^16; %13 PWM gate
        OutVect(14) = (bitshift(Dato(27),8)+Dato(28))*100/2^16; %14 PWM CbI
        OutVect(15) = (bitshift(Dato(29),8)+Dato(30))*100/2^16; %15 PWM Pelt1
        OutVect(16) = (bitshift(Dato(31),8)+Dato(32))*100/2^16; %16 PWM Pelt2
        
        OutVect(17) = (bitshift(Dato(33),8)+Dato(34)); %17 Stato MacchinaCorrente
        OutVect(18) = (bitshift(Dato(35),8)+Dato(36)); %18 Stato MacchinaTemperatura      
        OutVect(19) = (bitshift(Dato(37),8)+Dato(38)); %19 stato allarmi
    end
    
    OutVect(05) = FixTemp(OutVect(05));
    OutVect(06) = FixTemp(OutVect(06));
    
    if OutVect(1) > 2^15
        OutVect(1) = OutVect(1)-2^16;
    end
    if OutVect(2) > 2^15
        OutVect(2) = OutVect(2)-2^16;
    end
    OutVect(1:2) = OutVect(1:2)/100;

    fprintf('%05d\n',k)
    fprintf('IL %06.2f IH %06.2f Ref %06.2f\n',OutVect(1),OutVect(2),current_setpoint)
    fprintf('V %06.4f\n',OutVect(3))
    fprintf('Tp %06.2f T1 %06.2f\n',OutVect(4), OutVect(5))
    fprintf('T2 %06.2f T3 %06.2f\n',OutVect(6), OutVect(7))
    fprintf('T4 %06.2f T5 %06.2f\n',OutVect(7), OutVect(8))
    fprintf('T6 %06.2f T7 %06.2f\n',OutVect(9), OutVect(10))
    fprintf('T8 %06.2f\n',OutVect(11))
    % if OutVect(3)<2.75&&k>3
    %     break
    % end
    if OutVect(19) > 0
    StBit = fliplr(dec2bin(OutVect(19),16));
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

    fprintf('Gatte %06.2f\n',OutVect(13))
    fprintf('CbI   %06.2f\n',OutVect(14))
    fprintf('Pelt1 %06.2f\n',OutVect(15))
    fprintf('Pelt2 %06.2f\n',OutVect(16))

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

    if k == 1
        figure
        subplot 211
        hold on
        grid on
        subplot 212
        hold on
        grid on
    end
    if k >= 1
        subplot 211,%ylim([45 50])
        if current_setpoint > 0
            plot(k,OutVect(13),'ob')
        else
            plot(k,OutVect(14),'ob')
        end
        subplot 212
        plot(k,current_setpoint,'or')
        if BigTa == 1
            plot(k,OutVect(2),'ob')
        else
            plot(k,OutVect(1),'ob')
        end
    end
    
    CellV = OutVect(03);
    LEM = OutVect(1);
    Temp1 = OutVect(05);
    Temp2 = OutVect(06);
    
    stato = CheckVoltage (CellV);
    CheckTemp (Temp1, PMWch1);
    CheckTemp (Temp2, PMWch2);
    current_setpoint = CheckLem (LEM ,stato);
    
    while s.IsRunning
        pause(0.0001)
    end
    delete(lh);
end

%FUNZIONE SALVATAGGIO
function saveData(src, event, fid, c, LEM, CellV, Temp1, Temp2)
         fprintf(fid,'%d; %d; %02.3f;%6.3f;%6.3f;%6.3f\n', c(4), c(5), c(6), LEM, event.TimeStamps(26), mean(event.Data(1:50,1)));
         fprintf(fid,'%d; %d; %02.3f;%6.3f;%6.3f;%6.3f\n', c(4), c(5), c(6), LEM, event.TimeStamps(76), mean(event.Data(51:100,1)));
end

%FUNZIONE SET CORRENTE
function [c] = SetCurrent (value)
    c = value;
end

%FUNZIONE CHECK TENSIONE
function [s] = CheckVoltage (volt)
    if volt <=2.5
        s = 0;
    elseif volt >= 4.2
        s = 3;
    end
end

%FUNZIONE CHECK TEMPERATURA
function CheckTemp (temp, ch)
    delta = temp_setpoint-temp;
    
    PWMvalue = ((delta^2)/1600);
    
    %writePWMVoltage(o,port,PWMvalue);
    
    ch.DutyCycle = PMWvalue;
end

%FIX TEMPERATURA
function [temp] = FixTemp (temp)
    temp = temp*100;
    temp = interp1(estT(:, 1), estT(:,2), temp, 'linear');
end

%FUNZIONE CHECK CORRENTE PER ANELLO CHIUSO
function [c] = CheckLem (measured, s)
    switch s
        case 1
            if measured < DischgCurr
            end
        case 2
        case 3
    end
end