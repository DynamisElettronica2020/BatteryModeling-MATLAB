step = 1800;
it = round(size(time,1)/step);

% out = zeros([it 2]);
%%
for i = 3:1:it
    p = (i-1)*step;
    
    t = time((i+p):(step+p));
    v = Voltage((i+p):(step+p));
    SOC = SimOut.SOC.Data(i+p);
    R0_est = 0;
    Test_Current = timeseries(Current((i+p):(step+p)), t);
    %%
    pa = sdo.getParameterFromModel('Prova',{'R0_est'});
    
    if i == 1
        V1 = 0;
        V2 = 0;
    else
        V1 = Sim.V1.Data(end);
        V2 = Sim.V2.Data(end);
    end    
    
    parpool('local')
    save_system('Prova')
    pOpt = parameterEstimationProva(pa, v, t, V1, V2);
    delete(gcp)
    
    sdo.setValueInModel('Prova',{'R0_est'}, {pOpt(4,1).Value})
    Sim = sim('Prova');
    
    out(i,1) = R0_est;
    out(i,2) = Sim.SOC.Data(1);
    
    save('Parameters_5.mat', 'out')
end

out = vertcat(['R0', 'SOC'], out);