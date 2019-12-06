%dati = readmatrix (Acqfilename);

h = dati(:,1);
m = dati(:,2);
s = dati(:,3);
ts = dati(:,4);
curr = dati(:,5);
volt = dati(:,6);
Tener = dati(:,7);
Temp1 = dati(:,8);
Temp2 = dati(:,9);

i = 1;
sz = size(h);
time = [];
while(i <= sz(1))
    s(i) = s(i)+ts(i);
    
    if  s(i) >= 60
        s(i) = s(i)-60;
        m(i) = m(i)+1;
    end
    if m(i) >= 60
        m(i) = m(i)-60;
        h(i) = h(i)+1;
    end
    
    time(i, 1) = h(i);
    time(i, 2) = m(i);
    time(i, 3) = s(i);
    
    i = i+1;
end

dati = [time, curr, volt, Tener, Temp1, Temp2];

volt = dati(:,5);
curr = dati(:,4);

%TENSIONE
i = 1;
TF = isoutlier(volt,'movmedian',5);
sz = size(dati);
while i <= sz(1)
    j = i+1;
    if TF(i) == 0
        last = i;
    elseif i == sz(1)
        if TF(i) == 1
        volt(i) = volt(last);
        end
    elseif TF(i) == 1
        while TF(j)
            j = j+1;
        end
        volt(i) = mean ([volt(last), volt(j)]);
    end
    
    i = i+1;
end

%CORRENTE
i = 1;
TF = isoutlier(curr,'movmedian',75);
while i <= sz(1)
    j = i+1;
    if TF(i) == 0
        last = i;
    elseif i == sz(1)
        if TF(i) == 1
        curr(i) = curr(last);
        end
    elseif TF(i) == 1
        while TF(j)
            j = j+1;
        end
        curr(i) = mean ([curr(last), curr(j)]);
    end
    
    i = i+1;
end

dati = [time, curr, volt, Tener, Temp1, Temp2];

%writematrix(A, Modfilename, 'Delimiter', ';');