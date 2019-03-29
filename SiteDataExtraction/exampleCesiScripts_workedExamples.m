%% EXAMPLE 1

clc;clear;clear classes;clc; close all
fdh = CESI('query:D_Htot_A&_flo','ignore:Processed-');
% fdh.PlotSeries; % OPTIONAL
fdh = fdh.Clip('upper:100','lower:0');
% h = fdh.PlotSeries;
% h = fdh.ChangeScale(h,'from:2015/06/27','to:2015/06/31');
fdh = fdh.TimeWindow('from:2015/6/27','days:3');
h = fdh.PlotSeries;
fdh = fdh.FillGaps(1);
h = fdh.PlotSeries;

%% EXAMPLE 2

clc;clear;clear classes;clc; close all
fdh = CESI('query:D_Htot_A18_flo','ignore:Processed-');
fdh = fdh.Clip('upper:100','lower:0');
fdh = fdh.TimeWindow('from:2015/1/1','days:183');
[fdh,h] = fdh.FillGaps('len:1','compare:1');
fdh.PlotScroll(h)

%% EXAMPLE 3

clc;clear;clear classes;clc; close all
fdh = CESI('query:D_1Ph_&mf','ignore:Processed-');
fdh = fdh.Clip('upper:100','lower:0');
fdh = fdh.TimeWindow('from:2015/1/1','days:183');
fdh.MissingDataPlot('from:2015/01/01','to:2015/07/01','clrScale:10')
fdh = fdh.FillGaps(1);
fdh.MissingDataPlot('from:2015/01/01','to:2015/07/01','clrScale:10')
h = fdh.PlotSeries;