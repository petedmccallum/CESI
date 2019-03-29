# CESI.m class for site data extraction and processing

MATLAB class and worked examples to handle site data for the CESI project. 

ALL DATA (NO SUBFOLDERS) SHOULD BE PLACES ON A LOCAL DRIVE. CHANGE `mainPath` PROPERTY IN THIS FILE, UNDER `properties (Constant)`, TO MATCH THE LOCATION OF DATA ON YOUR SYSTEM. 
 
This class is used to extract and manipulate data. Example usage:

```
    >> fdh = CESI('query:D_1Ph');
```

Above will generate a large quantity of instances of classdef `CESI`, and assign to `fdh` (any valid variable name can be used). *** this large quantity of data series might slow machine down ***, but it should still be possible to plot all using the `PlotSeries` method:

```
    >> h = fdh.PlotSeries
```

` h = ` is optional, including this handle makes it easier to edit the plot once generated. An argument can be included to plot specific series only(` h = fdh.PlotSeries(1:10) ` will plot the first 10 series only). If you want to list the instance IDs, type:
` {fdh.dataId}' `. The corresponding index can then be viewed by double clicking `ans` in the workspace pane.


It is recommended to only create instances of the class for the data you are interested in. Unwanted instances can be deleted (` fdh(11:end) = [] ` would retain only 1 to 10), but it is best to avoid loading in the first place. `&` and `|` (pipe) can be used in query for 'and'/'or' (although not simultaneously). The following gives all single phase (`1Ph`) mains feeds (`mf`) in district C: 

```
    >> fdh = CESI('query:D_1Ph_C&mf');
```

The following gives all data for dwellings A18 to A23:

```
    >> fdh = CESI('query:A18|A19|A20|A21|A22|A23');
```

A second argument can be used to ignore certain strings, e.g. to 
limit to raw thermal data only:


```
    >> fdh = CESI('query:A18|A19|A20|A21|A22|A23','ignore:Processed&Q_&1Ph');
```

## Example 1
Outliers can be removed as follows:

```
    >> fdh = CESI('query:D_Htot_A&_flo','ignore:Processed-');
    >> fdh.PlotSeries; % OPTIONAL
    >> fdh = fdh.Clip('upper:100','lower:0');
    >> h = fdh.PlotSeries;
```

Plot limits can be changed:

```
    >> h = fdh.ChangeScale(h,'from:2015/06/27','to:2015/06/29')
```

or, the data can be cropped in time using:

```
    >> fdh = fdh.TimeWindow('from:2015/6/27','days:2');
    >> h = fdh.PlotSeries;
```

Gaps of single missing points can be linearly interpolated:

```
    >> fdh = fdh.FillGaps(1);
    >> h = fdh.PlotSeries;
```

## Example 2
Gaps can be filled and compared against original

```
    >> clc;clear;clear classes;clc; close all
    >> fdh = CESI('query:D_Htot_A18_flo','ignore:Processed-');
    >> fdh = fdh.Clip('upper:100','lower:0');
    >> fdh = fdh.TimeWindow('from:2015/1/1','days:183');
    >> [fdh,h] = fdh.FillGaps('len:1','compare:1');
    >> fdh.PlotScroll(h)
```

## Example 3
Missing data plots can be generated as follows:

```
    >> fdh = CESI('query:D_1Ph_&mf','ignore:Processed-');
    >> fdh = fdh.Clip('upper:100','lower:0');
    >> fdh = fdh.TimeWindow('from:2015/1/1','days:183');
    >> fdh.MissingDataPlot('from:2015/01/01','to:2015/07/01','clrScale:20')
    >> fdh = fdh.FillGaps(1);
    >> fdh.MissingDataPlot('from:2015/01/01','to:2015/07/01','clrScale:20')
```

