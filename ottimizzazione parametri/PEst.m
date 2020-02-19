open_system('VTC6_Sim')
p = sdo.getParameterFromModel('VTC6_Sim','R0_est');

load('parameterEstimation_VTC6_Sim_Data.mat')
Data.Exp_Sig_Output_Value = timeseries(Voltage(1:55810),time(1:55810));
save('parameterEstimation_VTC6_Sim_Data.mat', 'Data')

parpool('local')

save_system('VTC6_Sim')
pOpt = parameterEstimation_VTC6_Sim(p);
sdo.setValueInModel('VTC6_Sim',pOpt(:));
save_system('VTC6_Sim')
bdclose('VTC6_Sim');
delete(gcp)