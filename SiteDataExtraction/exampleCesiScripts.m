clc;clear;clear classes;clc; close all

%%%%% SELECT ONE OF THE FOLLOWING (ONLY) 
% fdh = CESI('query:D_TFMR&_act','ignore:Processed-');   fdh = fdh.Clip('upper:150','lower:-30');
% fdh = CESI('query:D_TFMR&_rct','ignore:Processed-');   fdh = fdh.Clip('upper:30','lower:-30');
% fdh = CESI('query:D_TFMR&_cur','ignore:Processed-');   fdh = fdh.Clip('upper:500','lower:0');
% fdh = CESI('query:D_TFMR&_rms','ignore:Processed-');   fdh = fdh.Clip('upper:260','lower:220');
fdh = CESI('query:D_TFMR&_pf','ignore:Processed-');    fdh = fdh.Clip('upper:1','lower:0');
% fdh = CESI('query:D_1Ph','ignore:Processed-');         fdh = fdh.Clip('upper:100','lower:0');
% fdh = CESI('query:D_3Ph','ignore:Processed-');         fdh = fdh.Clip('upper:150','lower:0');
% fdh = CESI('query:_CO2_','ignore:Processed-');         fdh = fdh.Clip('upper:5000','lower:0');
% fdh = CESI('query:_RH','ignore:Processed-');           fdh = fdh.Clip('upper:100','lower:0');
% fdh = CESI('query:_T_','ignore:Processed-');           fdh = fdh.Clip('upper:35','lower:2');
% fdh = CESI('query:_ene','ignore:Processed-');          fdh = fdh.Clip('upper:10000','lower:0');
% fdh = CESI('query:_flo','ignore:Processed-');          fdh = fdh.Clip('upper:200','lower:-100');          fdh = fdh.CutPeaks('ratio:10');
% fdh = CESI('query:_ret','ignore:Processed-');          fdh = fdh.Clip('upper:110','lower:-100');
% fdh = CESI('query:_vol','ignore:Processed-');          fdh = fdh.Clip('upper:1000','lower:0');

fdh = fdh.TimeWindow('from:2014/6/1','days:1188');
fdh = fdh.FillGaps(1);
h = fdh.PlotSeries;
h1 = fdh(1:end).MissingDataPlot('from:2015/01/01','to:2015/04/01','clrScale:20');