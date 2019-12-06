Vindex = 5;
Aindex = 4;
tindex = 2;

%ACQUISIZIONE
dati = readmatrix ('scarica2711n1senzacurr.csv');

%FIX E PULIZIA
FixTime
i = 15;
z = i+1;
while z < last
    j = i;
    %TROVO IL RILASSAMENTO
    while dati(i,Aindex)~= 0
        i = i+1;
    end
    z = i+1;
    while dati (z, Aindex) < 15 && z ~= last
        z = z+1;
    end

    %DOPPIA MODALITA' PER IL TEMPO IN BASE AL SET DI DATI
    %time = dati(i:z,tindex);
    time = dati(i:z, tindex-1)*3600+dati(i:z, tindex)*60+dati(i:z, tindex+1);
    time = time - time(1);

    sz = size(time);
    ls = sz(1);
    AvgCurrent = 0; %CORRENTE MEDIA INSISTITA PRIMA
    while j <= i
        AvgCurrent = AvgCurrent + dati(j,Aindex);
        j = j+1;
    end
    AvgCurrent = AvgCurrent/i;
    
    Voltage = dati(i:z,Vindex);

    %CREAZIONE CURVA FITTATA
    FittedCurve = fit(time, Voltage, 'exp2');
    Dv = diff(FittedCurve.a*exp(FittedCurve.b*time)+FittedCurve.c*exp(FittedCurve.d*time));

    %ELABORAZIONE DEI PARAMETRI
    tau1 = abs(1/(FittedCurve.b));
    tau2 = abs(1/(FittedCurve.d));

    tinf1 = fix(5*tau1);
    tinf2 = fix(5*tau2);

    R0_cf = (Voltage(21)-Voltage(1))/dati(i-1,Aindex);
    
    if tinf1 < tinf2 && tinf1 < time(ls)
        R2_cf = (R0_cf*Voltage(tinf1)*((FittedCurve.a+FittedCurve.c)/Dv(1)+tau2-(FittedCurve.a+FittedCurve.c)/Dv(tinf1)))/-(tau1*tau2*Dv(tinf1)-(tau1+tau2)*Voltage(tinf1)-(FittedCurve.a+FittedCurve.c)*tau2);
        R1_cf = -(R2_cf*tau1*Dv(tinf1)-R0_cf*Voltage(tinf1))/Voltage(tinf1)+R2_cf;
    end
    if tinf1 > tinf2 && tinf2 < time(ls)
        R1_cf = (R0_cf*Voltage(tinf2)*((FittedCurve.a+FittedCurve.c)/Dv(1)+tau1-(FittedCurve.a+FittedCurve.c)/Dv(tinf2)))/-(tau1*tau2*Dv(tinf2)-(tau1+tau2)*Voltage(tinf2)-(FittedCurve.a+FittedCurve.c)*tau1);
        R2_cf = -(R1_cf*tau2*Dv(tinf2)-R0_cf*Voltage(tinf2))/Voltage(tinf2)+R1_cf;
    end
    if tinf1 > time(ls) && tinf2 > time(ls)
        R1_cf = 0;
        R2_cf = 0;
    end

    C1_cf = tau1/(R0_cf+R1_cf+R2_cf);
    C2_cf = tau2/(R0_cf+R1_cf+R2_cf);
    
    disp(['R0_cf       ' num2str(R0_cf)]);
    disp(['R1_cf       ' num2str(R1_cf)]);
    disp(['R2_cf       ' num2str(R2_cf)]);
    disp(['C1_cf       ' num2str(C1_cf)]);
    disp(['C2_cf       ' num2str(C2_cf)]);
    disp(['tau1       ' num2str(tau1)]);
    disp(['tau2       ' num2str(tau2)]);
end