classdef CESI
    %==========================================================
    % CESI : classdef for data used in CESI project.
    %   -   PM:     15/12/2017      TESTED ON MATLAB 2016b
    %==========================================================
    %
    %   *******************************************************************
    %   *   ALL DATA (NO SUBFOLDERS) SHOULD BE PLACES ON A LOCAL DRIVE.   *
    %   *   CHANGE "mainPath" PROPERTY IN THIS FILE, UNDER "properties    *
    %   *   (Constant)", TO MATCH THE LOCATION OF DATA ON YOUR SYSTEM.    *
    %   *******************************************************************
    %
    %   This class is used to extract and manipulate data. Example usage:
    %
    %       >> fdh = CESI('query:D_1Ph');
    %
    %   ABOVE WILL GENERATE A LARGE QUANTITY OF INSTANCES OF CLASSDEF
    %   "CESI", AND ASSIGN TO "fdh" (ANY VALID VARIABLE NAME CAN BE USED).
    %   *** THIS LARGE QUANTITY OF DATA SERIES MIGHT SLOW MACHINE DOWN ***,
    %   BUT IT SHOULD STILL BE POSSIBLE TO PLOT ALL USING THE "PlotSeries"
    %   METHOD:
    %
    %       >> h = fdh.PlotSeries.
    %
    %   " h = " IS OPTIONAL, INCLUDING THIS HANDLE MAKES IT EASIER TO EDIT
    %   THE PLOT ONCE GENERATED. AN ARGUMENT CAN BE INCLUDED TO PLOT
    %   SPECIFIC SERIES ONLY (" h = fdh.PlotSeries(1:10) " WILL PLOT THE
    %   FIRST 10 SERIES ONLY). IF YOU WANT TO LIST THE INSTANCE IDs, TYPE:
    %   " {fdh.dataId}' ". THE CORRESPONDING INDEX CAN THEN BE VIEWED BY 
    %   DOUBLE CLICKING "ans" IN THE WORKSPACE PANE.
    %
    %   IT IS RECOMMENDED TO ONLY CREATE INSTANCES OF THE CLASS FOR THE
    %   DATA YOU ARE INTERESTED IN. UNWANTED INSTANCES CAN BE DELETED
    %   (" fdh(11:end) = [] " WOULD RETAIN ONLY 1 TO 10), BUT IT IS BEST TO
    %   AVOID LOADING IN THE FIRST PLACE. "&" AND "|" (PIPE) CAN BE USED IN
    %   QUERY FOR 'AND'/'OR' (ALTHOUGH NOT SIMULTANEOUSLY). THE FOLLOWING 
    %   GIVES ALL SINGLE PHASE ("1Ph") MAINS FEEDS ("mf") IN DISTRICT C: 
    %
    %       >> fdh = CESI('query:D_1Ph_C&mf');
    %
    %   THE FOLLOWING GIVES ALL DATA FOR DWELLINGS A18 TO A23:
    %
    %       >> fdh = CESI('query:A18|A19|A20|A21|A22|A23');
    %
    %   A SECOND ARGUMENT CAN BE USED TO IGNORE CERTAIN STRINGS, e.g. TO 
    %   LIMIT TO RAW THERMAL DATA ONLY:
    %
    %       >> fdh = CESI('query:A18|A19|A20|A21|A22|A23','ignore:Processed&Q_&1Ph');
    %   ___________________________________________________________________
    %
    %   EXAMPLE 1: OUTLIERS CAN BE REMOVED AS FOLLOWS:
    %       >> fdh = CESI('query:D_Htot_A&_flo','ignore:Processed-');
    %       >> fdh.PlotSeries; % OPTIONAL
    %       >> fdh = fdh.Clip('upper:100','lower:0');
    %       >> h = fdh.PlotSeries;
    %   PLOT LIMITS CAN BE CHANGED:
    %       >> h = fdh.ChangeScale(h,'from:2015/06/27','to:2015/06/29')
    %   OR, THE DATA CAN BE CROPPED IN TIME USING: 
    %       >> fdh = fdh.TimeWindow('from:2015/6/27','days:2');
    %       >> h = fdh.PlotSeries;
    %   GAPS OF SINGLE MISSING POINTS CAN BE LINEARLY INTERPOLATED:
    %       >> fdh = fdh.FillGaps(1);
    %       >> h = fdh.PlotSeries;
    %   ___________________________________________________________________
    %   
    %   EXAMPLE 2: GAPS CAN BE FILLED AND COMPARED AGAINST ORIGINAL
    %       >> clc;clear;clear classes;clc; close all
    %       >> fdh = CESI('query:D_Htot_A18_flo','ignore:Processed-');
    %       >> fdh = fdh.Clip('upper:100','lower:0');
    %       >> fdh = fdh.TimeWindow('from:2015/1/1','days:183');
    %       >> [fdh,h] = fdh.FillGaps('len:1','compare:1');
    %       >> fdh.PlotScroll(h)
    %   ___________________________________________________________________
    %   
    %   EXAMPLE 3: MISSING DATA PLOTS CAN BE GENERATED AS FOLLOWS:
    %       >> fdh = CESI('query:D_1Ph_&mf','ignore:Processed-');
    %       >> fdh = fdh.Clip('upper:100','lower:0');
    %       >> fdh = fdh.TimeWindow('from:2015/1/1','days:183');
    %       >> fdh.MissingDataPlot('from:2015/01/01','to:2015/07/01','clrScale:20')
    %       >> fdh = fdh.FillGaps(1);
    %       >> fdh.MissingDataPlot('from:2015/01/01','to:2015/07/01','clrScale:20')
    %   ___________________________________________________________________
       
    
    
    properties
        dataId
        dataName
        t
        y
        temporalRes
        stats
        infoMissingData
        infoGaps
        help
    end
    
    properties (Constant)
        dateNumML2XL = 736910-42950 % THIS CONVERTS EXCEL BASED DATE NUMBER (BASE: 1-Jan-1900) TO MATLAB DATE NUMBER (BASE: 1-Jan-0000)
        mainPath    = 'C:/{include full of path of directory used to store data}''')
    end
    
    methods
        function obj = CESI(varargin) % CONSTRUCTOR METHOD
            
            
            % FIND AVAIABLE SENSOR DATA FILES            
            DIR = dir(obj.mainPath);
            if isempty(DIR)
                disp('Complete relevant path details in the "mainPath" property, specific to this computer...')
                disp('_____________________________')
                disp(' ')
                disp('    properties (Constant)')
                disp('        dateNumML2XL = 736910-42950 % THIS CONVERTS EXCEL BASED DATE NUMBER (BASE: 1-Jan-1900) TO MATLAB DATE NUMBER (BASE: 1-Jan-0000)')
                disp('        mainPath     = ''C:/{include full of path of directory used to store data}''')
                disp('    end')
                disp('_____________________________')
    
                error('PATH DOES NOT EXIST ON THIS COMPUTER, FOLLOW THE ABOVE INSTRUCTIONS')
            else
                id = {DIR.name}';
            end
                     
            
            if nargin ~= 0 % POPULATE INSTANCE (OTHERWISE BLANK INSTANCE, SEE "elseif")
                % FIND ARGUMENTS (DEFAULTS LEFT BLANK)
                optn = obj.Options(varargin,'query:','ignore:','add:');
                                
                if isempty(optn.add) % POPULATE WITH EXISTING DATA (UNLESS THE ADD ARGUMENT HAS BEEN USED)
                                        
                    % INTERPRET QUERIES
                    andCase = ~isempty(strfind(optn.query,'&'));
                    orCase = ~isempty(strfind(optn.query,'|'));
                    if andCase && orCase
                        error('CANNOT PROCESS BOTH "&" AND "|" IN SAME QUERY (MULTIPLE "&"s AND "|"s ARE ACCEPTED)')
                    end
                    if ~orCase % "AND" CASE (AS WELL AS SINGULAR QUERY)
                        queries = strsplit(optn.query,'&');
                        L = length(queries);
                        for k = 1:L
                            fnd = regexp(id,queries{k});
                            pos = find(cellfun(@sum,fnd)==0);
                            id(pos) = [];
                        end
                    elseif orCase % "OR" CASE
                        queries = strsplit(optn.query,'|');
                        L = length(queries);
                        pos = [];
                        for k = 1:L
                            fnd = regexp(id,queries{k});
                            pos = [pos;find(cellfun(@sum,fnd)>0)];
                        end
                        id = id(pos);
                    end
                    % REMOVE ALL STATEMENTS FROM THE "ignore:" ARGUMENT
                    exceptions = strsplit(optn.ignore,'&');
                    L = length(exceptions);
                    for k = 1:L
                        fnd = regexp(id,exceptions{k});
                        pos = find(cellfun(@sum,fnd)>0);
                        id(pos) = [];
                    end
                    if isempty(id)
                        error('NO FILES MATCHING QUERY. CHECK USE OF "&" AND "|", \n ALSO CHECK FILE PATH IS CORRECT (IN CESI "properties (constant)")')
                    end
                    id = strrep(id,'.csv','');
                    
                    
                    % CONSTRUCT MULTI-DIM OBJECT ARRAY
                    L = length(id);
                    obj(L,1) = CESI;
                    
                    
                    % ASIGN DATA TO OBJECT (LOAD FROM CSVs)
                    for k = 1:L % FOR ALL INSTANCES...
                        obj(k).dataId = id{k};
                        obj(k).dataName = strrep(obj(k).dataId,'_','\_');
                        % LOAD DATA FROM CSV
                        start = now();
                        obj(k) = obj(k).ReadCleanCsv(id{k});
                        fin = now();
                        fprintf('INSTANCE: [%i]\t (%s)\t: %1.2f sec\n',k,obj(k).dataId,(fin-start)*24*60*60)                        
                    end
                    
                    
                else % CREATE NEW BLANK INSTANCE (USED TO STORE PROCESSED DATA, E.G. APPARENT POWER, DERIVED FROM ACT/REACT POWER)
                    obj.dataId = optn.add;
                    obj.dataName = strrep(obj.dataId,'_','\_');                    
                end
                
            end
            
        end %%%%%%%%%%
        function obj = ReadCleanCsv(varargin) 
            
            % INITIALISE
            obj = varargin{1};
            idName = varargin{2};
            
            % READ CSV FROM DIRECTORY
            fname = sprintf('%s/%s.csv',obj.mainPath,idName);
            fromCsv = dlmread(fname);
            
            % ASSIGN TO INSTANCE
            obj.t = fromCsv(:,1) + obj.dateNumML2XL;
            obj.y = fromCsv(:,2);
            
            % INTERPRET TEMPORAL SCALE
            minDt = min(diff(obj.t))*60*24;
            maxDt = max(diff(obj.t))*60*24;
            if maxDt-minDt<1e-2
                obj.temporalRes.dt = round(maxDt);
            else
                error('sample rate not consistent')
            end
            obj.temporalRes.unit = 'minutes';
            
        end %%%%%%%%%%
        function h   = PlotSeries(varargin)
            
            % INITIALISE
            obj = varargin{1};
            
            % SELECT PARTICIULAR RUNS (IF ARGUMENT IS SPECIFIED: LIST OF INTEGERS)
            if nargin > 1
                inst = varargin{2};
            else
                inst = 1:length(obj);
            end
            
            % PLOT
            figure; hold on
            for k = 1:length(inst)
                plot(obj(inst(k)).t,obj(inst(k)).y)
                leg{k} = strrep(obj(inst(k)).dataId,'_','\_');                               
            end
            h = gca;
            legend(leg)
            datetick('x','dd-mmm-yy','keeplimits')
            grid on
            h.FontSize = 8;
            h.Parent.Position = [50 300 1200 500];
            h.Position = [0.06 0.1 0.9 0.85];
            series = h.Children;
            rng = series(1).XData([1 end]);
            start = sprintf('from:%s',datestr(rng(1),'yyyy/mm/dd'));
            fin = sprintf('to:%s',datestr(rng(2),'yyyy/mm/dd'));

            % UPDATE PLOT LIMITS
            obj.ChangeScale(h,start,fin);
            
        end %%%%%%%%%%
        function h   = ChangeScale(varargin)
            % ASSIGN ARGUMENTS AND OPTIONS
            obj = varargin{1};
            h = varargin{2};
            % SET OPTIONS (DEFAULT IF REQUIRED)
            optn = obj.Options(varargin);
            rng = [datenum(optn.from) datenum(optn.to)+1];
            if diff(rng) > 365/2
                glOptn = 1;
            elseif diff(rng) > 62
                glOptn = 2;
            elseif diff(rng) > 2
                glOptn = 3;
            else
                glOptn = 4;
            end
            
            % CHANGE PLOT LIMITS
            h.XLim = [datenum(sprintf('%s 00:00:00',optn.from)) datenum(sprintf('%s 00:00:00',optn.to))];
            xlim = h.XLim;
            yRng = [h.YLim NaN]';
            
            % SET OUTRIGHT LIMITS FOR PLOT (BEYOND ALL PLOTTED DATA)
            for k = 1:length(obj)
                mins(k) = obj(k).t(1);
                maxs(k) = obj(k).t(end);
            end
            st = datestr(min(mins));
            fi = datestr(max(maxs));
            
            % CHANGE XTICK LABELS            
            if glOptn == 1 
                
                % INCLUDE X-TICKMARKS FOR MONTHS
                yrs = repmat(year(st):year(fi),12,1);
                yrs = yrs(:);
                mths = repmat((1:12)',(year(fi)-year(st)+1),1);
                posA = find(mths==month(st));
                posB = find(mths==month(fi));
                yrs = yrs(posA(1):min(posB(end)+1,length(yrs)),:);
                mths = mths(posA(1):min(posB(end)+1,length(mths)),:);
                dateList = datenum(yrs,mths,1);
                h.XTick = dateList+15; % OFFSET BY 15 DAYS TO APPEAR AT MIDPOINT
                h.XTickLabel = datestr(h.XTick,'mmm-yy');
                if length(unique(yrs)) > 1
                    % PLOT GRIDLINES FOR YEARS
                    yearArray = datenum((year(xlim(1))):year(xlim(2)),1,1);
                    % CREATE PLOT SERIES
                    x = repmat(yearArray,3,1);
                    y1 = repmat([yRng(1);yRng(2);NaN],length(yearArray),1);
                    hTemp = plot(x(:),y1,'color',0.2*[1 1 1]);
                    uistack(hTemp,'bottom')
                end
                % PLOT GRIDLINES FOR MONTHS
                x = repmat(dateList',3,1);
                y1 = repmat(yRng,length(dateList),1);
                hTemp = plot(x(:),y1,'color',0.8*[1 1 1]);
                uistack(hTemp,'bottom')
                if length(unique(yrs)) == 1
                    hTemp.Color = 0.2*[1 1 1];
                end                                
            elseif glOptn == 2
                wk = floor(datenum(st)-weekday(datenum(st))+2):7:(ceil(datenum(fi)-1));
                h.XTick = 0.5 + wk;
                h.XTickLabel = datestr(h.XTick-0.5,'dd-mmm');
                x = repmat(wk,3,1);
                y1 = repmat(yRng,length(wk),1);
                hTemp = plot(x(:),y1,'color',0.2*[1 1 1]);
                uistack(hTemp,'bottom')
            elseif glOptn == 3
                wkend = floor(datenum(st)-weekday(datenum(st))+2):7:(ceil(datenum(fi)-1));
                wkend = [wkend-2;wkend];
                wkend = wkend(:);
                dys = floor(datenum(st)):(ceil(datenum(fi)-1));
                h.XTick = dys+0.5;
                h.XTickLabel = datestr(h.XTick,'dd-mmm');
                x = repmat(wkend',3,1);
                y1 = repmat(yRng,length(wkend),1);
                hTemp = plot(x(:),y1,'color',0.2*[1 1 1]);
                uistack(hTemp,'bottom')
                x = repmat(dys,3,1);
                y1 = repmat(yRng,length(dys),1);
                hTemp = plot(x(:),y1,'color',0.8*[1 1 1]);
                uistack(hTemp,'bottom')
                if diff(rng) < 7
                    hrs = floor(datenum(st)):(1/24):(ceil(datenum(fi)));
                    x = repmat(hrs,3,1);
                    y1 = repmat(yRng,length(hrs),1);
                    hTemp = plot(x(:),y1,'color',0.8*[1 1 1],'linestyle',':');
                    uistack(hTemp,'bottom')
                end
            elseif glOptn == 4
                dys = floor(datenum(st)):(ceil(datenum(fi)-1));
                hrs = floor(datenum(st)):(1/24):(ceil(datenum(fi)));
                h.XTick = hrs%+(0.5/24);
                h.XTickLabel = datestr(h.XTick,'HH:MM');
                x = repmat(dys,3,1);
                y1 = repmat(yRng,length(dys),1);
                hTemp = plot(x(:),y1,'color',0.2*[1 1 1]);
                uistack(hTemp,'bottom')
                x = repmat(hrs,3,1);
                y1 = repmat(yRng,length(hrs),1);
                hTemp = plot(x(:),y1,'color',0.8*[1 1 1]);
                uistack(hTemp,'bottom')            
            end
                        
            % REMOVE ACTUAL GRIDLINES AND X-TICKMARKS
            h.XGrid = 'off';
            h.TickLength = [0 0.025];
            % FORMAT TEXT
            h.XTickLabelRotation = 90;
            h.FontSize = 8;
            
        end %%%%%%%%%%
        function h = PlotScroll(varargin)
            
            % INITIALISE
            clc
            obj = varargin{1};
            if nargin < 2
                h = obj.PlotSeries;
                optn.days = 2;
            else
                h = varargin{2};                
                optn = obj.Options(varargin,'days:2');
            end
                        
            % OPEN FULL PLOT, SET NAME AND SET LIMITS
            h.YLimMode = 'manual';
            series = h.Children;
            rng = series(1).XData([1 end]);
            start = sprintf('from:%s',datestr(rng(1),'yyyy/mm/dd'));
            fin = sprintf('to:%s',datestr(rng(2),'yyyy/mm/dd'));
            
            % USER SET WINDOW
            okay = 0;
            while okay ==0
                hTxt(1) = annotation('textbox','string','Click for start time',...
                    'position',[0.2 0.8 0.12 0.05],'BackgroundColor','w');
                xlims(1,:) = ginput(1);  hTmp(1) = plot(xlims(1,1)*[1 1],h.YLim,'m');
                hTxt(1).Color = 0.7*[1 1 1];
                hTxt(2) = annotation('textbox','string','Click for end time',...
                    'position',[0.2 0.75 0.12 0.05],'BackgroundColor','w');
                xlims(2,:) = ginput(1);  hTmp(2) = plot(xlims(2,1)*[1 1],h.YLim,'m');
                hTxt(2).Color = 0.7*[1 1 1];
                hTxt(3) = annotation('textbox','string','Click for upper limit',...
                    'position',[0.2 0.7 0.12 0.05],'BackgroundColor','w');
                ylims(1,:) = ginput(1);  hTmp(3) = plot(h.XLim,ylims(1,2)*[1 1],'m');
                hTxt(3).Color = 0.7*[1 1 1];
                hTxt(4) = annotation('textbox','string','Click for lower limit',...
                    'position',[0.2 0.65 0.12 0.05],'BackgroundColor','w');
                ylims(2,:) = ginput(1);  hTmp(4) = plot(h.XLim,ylims(2,2)*[1 1],'m');
                delete(hTxt);
                response = input('continue (enter) / redo (anykey+enter)','s');
                if isempty(response)
                    okay = 1;
                end
            end
            
            % REVERT TO ACTIVE FIGURE, CHANGE GRID, LOOP MOVING WINDOW
            figure(h.Parent)
            delete(hTmp);
            h.YLim = flipud(ylims(:,2))';
            h.XLim = floor(xlims(1,1)) + [0 optn.days];
            incr = 0.1;
            dys = floor(rng(1)):(ceil(rng(2)));
            hrs = floor(rng(1)):(1/24):(ceil(rng(2)));
            h.XTick = dys;
            h.XTickLabel = datestr(h.XTick,'dd-mmm');
            x = repmat(dys,3,1);
            y1 = repmat([ylims(:,2);NaN],length(dys),1);
            hTemp = plot(x(:),y1,'color',0.2*[1 1 1]);
            uistack(hTemp,'bottom')
            x = repmat(hrs,3,1);
            y1 = repmat([ylims(:,2);NaN],length(hrs),1);
            hTemp = plot(x(:),y1,'color',0.8*[1 1 1]);
            uistack(hTemp,'bottom')
            
            while h.XLim(2) < xlims(2,1)
                h.XLim = h.XLim + incr;                
                if regexp(get(h.Parent,'CurrentCharacter'),'a')
                    incr = incr+0.02;
                    set(h.Parent,'CurrentCharacter','@')
                    figure(h.Parent)
                elseif regexp(get(h.Parent,'CurrentCharacter'),'z')
                    incr = incr-0.02;
                    set(h.Parent,'CurrentCharacter','@')
                    figure(h.Parent)
                elseif regexp(get(h.Parent,'CurrentCharacter'),'s')
                    incr = 0;
                    set(h.Parent,'CurrentCharacter','@')
                    figure(h.Parent)
                end
                pause(0.15)
                figure(h.Parent)
            end
            
        end %%%%%%%%%%
        function obj = TimeWindow(varargin)
            
            % INITIALISE MULTIPLE INSTANCE METHOD
            obj = varargin{1};
            t1 = {obj.t};
            if nargin == 1
                start = min(cellfun(@(x) x(1,1),t1));
                fin = max(cellfun(@(x) x(end,1),t1));
            else
                optn = obj.Options(varargin,'to:','days:');
                start = datenum(optn.from);
                if isempty(optn.days)
                    fin = datenum(optn.to) + 1;
                else
                    fin = start + optn.days - 1;
                end                
            end
            dateRng = (round((start:(5/24/60):fin)*288)/288)';
            L1 = size(obj,1);
            L2 = size(obj,2);
            L3 = length(dateRng);
            
            % TRIM STORED DATA ("t" AND "y" VECTORS)
            for k = 1:L2
                for j = 1:L1
                    
                    % CREATE NEW "y" VECTOR
                    y1 = nan(L3,1);
                    pos.fnd = find(ismember(round(obj(j,k).t*288)/288,dateRng)==1);
                    pos.trg = find(ismember(dateRng,round(obj(j,k).t*288)/288)==1);                    
                    y1(pos.trg) = obj(j,k).y(pos.fnd);
                    
                    if ~isempty(y1)
                        % CLEAR OLD DATA
                        obj(j,k).t = [];
                        obj(j,k).y = [];
                        
                        obj(j,k).t = dateRng;
                        obj(j,k).y = nan(length(dateRng),1);
                        obj(j,k).y(1:L3,1) = y1;
                    else
                        disp('specified time window out of range - method ignored')
                    end
                end
            end
            
        end %%%%%%%%%%
        function obj = Clip(varargin)
            
            % INITIALISE
            obj = varargin{1};
            optn = obj.Options(varargin);
            L1 = size(obj,2);
            L2 = size(obj,1);
            
            % SET EMPTY LIMITS (REMAIN EMPTY IF NO LIMIT SPECIFIED)
            lower = [];
            upper = [];
            if isfield(optn,'lower')
                lower = (optn.lower);
            end
            if isfield(optn,'upper')
                upper = (optn.upper);
            end
            
            % FIND OUTLIERS AND REPLACE WITH "NaNs"
            for k = 1:L1
                for j = 1:L2
                    if isfield(optn,'stDev')
                        obj.stats.median = median(obj(j,k).y(~isnan(obj(j,k).y())));
                        obj.stats.stDev = std(obj(j,k).y(~isnan(obj(j,k).y())));
                        obj.stats.nStDev = (optn.stDev);
                        obj.stats.clip = obj.stats.nStDev*(obj.stats.stDev-obj.stats.median)*[-1 1]+obj.stats.median;
                        lower = min(obj.stats.clip);
                        upper = max(obj.stats.clip);
                    end
                    if ~isempty(upper)
                        pos = find(obj(j,k).y>upper);
                        obj(j,k).y(pos) = NaN;
                    end
                    if ~isempty(lower)
                        pos = find(obj(j,k).y<lower);
                        obj(j,k).y(pos) = NaN;
                    end
                end
            end
            
        end %%%%%%%%%%
        function obj = FindGaps(varargin)
            
            % INITIALISE
            obj = varargin{1};
            L1 = size(obj,1);
            L2 = size(obj,2);
            
            % LOOP THROUGH ALL INSTANCES, LOCATE MISSING DATA
            for k = 1:L2
                for j = 1:L1
                    tmp0 = find(isnan(obj(j,k).y)==1);
                    if ~isempty(tmp0) % IF ANY NaNs ARE FOUND...
                        
                        % GENERATE TWO-COLUMN ARRAY, GIVING START-TIME
                        % (COL1) AND LENGTH OF GAP (COL2)
                        tmp1 = tmp0(2:end)-tmp0(1:end-1);
                        tmp1(tmp1==1) = 0;
                        tmp1(tmp1>1) = 1;
                        tmp1 = [1;tmp1];                        
                        tmp2 = num2str(tmp1');
                        tmp2 = strrep(tmp2,' 1',';1');
                        tmp2 = strrep(tmp2,' ','');
                        tmp2 = strsplit(tmp2,';');
                        tmp3 = cellfun(@(x) length(x),tmp2)';
                        tmp1(tmp1==1)=tmp3;
                        pos = find(tmp1~=0);
                        obj(j,k).infoGaps.pos = [tmp0(pos) tmp1(pos)];
                        
                    else % IF NO NaNs, INCLUDE EMPTY ARRAY
                        obj(j,k).infoGaps.pos = [];
                    end
                    
                end
            end
            
        end %%%%%%%%%%
        function obj = CutPeaks(varargin) % [TESTING]
            
            % INITIALISE
            obj = varargin{1};
            optn = obj.Options(varargin);
            L1 = size(obj,2);
            L2 = size(obj,1);
            
            % IDENTIFY LOCALISED SPIKE (BASED ON WINDOW 't-2' TO 't+2')
            for k = 1:L1
                for j = 1:L2
                    t1 = obj(j,k).t;
                    y1 = obj(j,k).y;
                    L = length(y1);
                    posNum = find(isnan(y1)==0);
                    posNan = find(isnan(y1)==1);
                    t1(posNan) = [];
                    y1(posNan) = [];
                    q = [y1(1:end-4) y1(2:end-3) y1(3:end-2) y1(4:end-1) y1(5:end)];
                    w = mean(q(:,[1 2 4 5]),2);
                    q = q - w;
                    denom = max(abs(q(:,[1 2 4 5]))')';
                    numer = q(:,3);
                    ratio = nan(L,1);
                    ratio(posNum(3:end-2)) = numer./denom;
                    %plot(obj.t,ratio,'r.') % FOR CHECKING
                    
                    posRm = abs(ratio)>optn.ratio;
                    
                    obj(j,k).y(posRm) = NaN;
                end
            end
            
        end %%%%%%%%%%
        function [obj,h] = FillGaps(varargin)
            
            % INITIALISE
            obj = varargin{1};
            obj = obj.FindGaps;
            optn = obj.Options(varargin,'len:1','compare:');
            L1 = size(obj,1);
            L2 = size(obj,2);
            
            % IF COMPARE ARGUMENT IS NON-BLANK, GENERATE SINGLE SERIES PLOT
            if ~isempty(optn.compare)
                h = obj.PlotSeries(optn.compare);
                h.Children(1).LineWidth = 1.5;
                h.Children(1).Color = 'c';
                tmpY = obj(optn.compare).y;
            end
            
            
            for k = 1:L2
                for j = 1:L1
                    if ~isempty(obj(j,k).infoGaps.pos)
                        
                        % AVOID OPEN-ENDED NaNs AT START AND END OF DATA SERIES
                        if obj(j,k).infoGaps.pos(1,1) == 1
                            obj(j,k).infoGaps.pos(1,2) = 0;
                        end
                        if obj(j,k).infoGaps.pos(end,1) == length(obj(j,k).y)
                            obj(j,k).infoGaps.pos(end,2) = 0;
                        end
                        
                        % LINEAR INTERPOLATION (INTENDED FOR SINGLE POINT GAPS ONLY)
                        pos = obj(j,k).infoGaps.pos(find(obj(j,k).infoGaps.pos(:,2)==optn.len),1);
                        pos(pos==1) = [];
                        obj(j,k).infoGaps.newT = obj(j,k).t(pos);
                        obj(j,k).infoGaps.newPts = (obj(j,k).y(pos+1)+obj(j,k).y(pos-1))/2;
                        obj(j,k).y(pos) = obj(j,k).infoGaps.newPts;
                                                
                    end
                end
            end
            
            % IF COMPARE ARGUMENT IS NON-BLANK, PLOT NEW SERIES COMPARISON
            if ~isempty(optn.compare)
                a = isnan(tmpY);
                b = isnan(obj(optn.compare).y);
                h1 = plot(obj(optn.compare).t,obj(optn.compare).y,'Color','m');
                plot(obj(optn.compare).t(a~=b),obj(optn.compare).y(a~=b),...
                    'Color','r','Marker','.','MarkerSize',6,'LineStyle','n','DisplayName','Linearly interpolated');
                uistack(h1,'bottom');
                legend(h.Children([2 1]))
            end
            
        end %%%%%%%%%%
        function obj = MissingDataCheck(varargin)
            
            % INITIALISE
            obj = varargin{1};
            L0 = length(obj);
            for k = 1:L0
                start(k) = floor(min(obj(k).t));
                fin(k) = ceil(max(obj(k).t));
            end
            start = min(start);
            fin = max(fin);
            
            % COUNT MISSING VALUES PER DAY
            for k = 1:L0
                
                if isempty(obj(k).temporalRes)
                    minDt = min(diff(obj(k).t))*60*24;
                    maxDt = max(diff(obj(k).t))*60*24;
                    if maxDt-minDt<1e-2
                        obj(k).temporalRes.dt = round(maxDt);
                    else
                        error('sample rate not consistent')
                    end
                    obj(k).temporalRes.unit = 'minutes';
                end
                dt = obj(k).temporalRes.dt;
                
                
                tVector = (round(start*(24*60)):dt:(round(fin*(24*60)-dt)))';
                tVectorRef = round(obj(k).t*(24*60));
                posSrc = find(ismember(tVectorRef,tVector));
                posTrg = find(ismember(tVector,tVectorRef));
                
                yVector = NaN(length(tVector),1);
                yVector(posTrg) = obj(k).y(posSrc);
                
               
                ptsPerDay = (24*60/dt);
                yMatrix = vec2mat(yVector,ptsPerDay);
                obj(k).infoMissingData(:,1) = tVector(1:ptsPerDay:end)/(24*60);
                obj(k).infoMissingData(:,2) = sum(isnan(yMatrix'))'/(ptsPerDay);
            end
            
        end %%%%%%%%%%
        function [obj,h] = MissingDataPlot(varargin)
            
            % INITIALISE
            obj = varargin{1};
            to = sprintf('to:%s',datestr(today,'yyyy/mm/dd'));
            optn = obj.Options(varargin,'from:2014/02/01',to,'clrScale:288');
            L0 = length(obj);
            obj = obj.MissingDataCheck;
            
            % TRIM COLOUR SCALE
            clip = (optn.clrScale+0.9)/288;
            % INCREASE SPACE FOR RIGHT HAND AXIS
            vTrim = -0.02;
            
            % PLOT
            figure; hold on
            for k = 1:L0
                L1 = length(obj(k).infoMissingData);
                rng = obj(k).infoMissingData(1,1) : ...
                     (obj(k).infoMissingData(end,1)+1);
                tVector = repmat(rng,2,1);
                cVector = repmat(obj(k).infoMissingData(:,2)',1,1);
                S.Vertices = [tVector(:) repmat([L0;L0-1],L1+1,1)-k+1];
                S.Faces = repmat([1 3 4 2],L1,1)+repmat(((1:(L1))*2-2)',1,4);
                S.FaceVertexCData = min(cVector(:),clip);
                S.FaceColor = 'flat';
                S.EdgeColor = 'n';
                patch(S)                
            end            
            h = gca;
            colormap jet
            obj.ChangeScale(h ...
                , sprintf('from:%s',optn.from) ...
                , sprintf('to:%s',optn.to) ...
                );            
            h.Parent.Position = [50 150 1200 750];
            h.YTick = (1:L0) - 0.5;
            h.YLim = [0 L0];
            
            % CREATE LEGEND AS RIGHT HAND AXIS
            for k = 1:L0
                str = obj(k).dataName;
                leg{k} = str;
            end
            h.YTickLabel = fliplr(leg);
            h.YAxisLocation = 'right';
            h.Position = h.Position + [0 0 vTrim 0];
            
            % PULL GRIDLINES TO FRONT
            c = 0;
            for k=1:length(h.Children)
                if regexp(h.Children(k).Type,'line')
                    c = c + 1;
                    hGrdLn(c) = h.Children(k);
                end
            end            
            uistack(hGrdLn(1),'top');
            hGrdLn(1).LineStyle = '--';
            hGrdLn(1).Color = 0.5*[1 1 1];
            hGrdLn(1).Color = [1 1 1];
            try
                uistack(hGrdLn(2),'top');
                hGrdLn(2).LineStyle = ':';
            catch
            end
            
            % HORIZONTAL GRIDLINES
            xVect = repmat([h.XLim NaN]',L0,1);
            yVect = repmat(1:L0,3,1);
            plot(xVect(:),yVect(:),'w')
            
            
            % COLORBAR
            hCbar = axes;
            hCbar.Position = h.Position + [-0.05 0 0 0];
            hCbar.Position(3) = 0.02;
            hCbar.Box = 'on';            
            L3 = 288;
            yVector = repmat((0:L3),2,1);
            S2.Faces = repmat([1 3 4 2],L3-1,1)+repmat(((1:(L3-1))*2-2)',1,4);
            S2.Vertices = [repmat([0;1],L3+1,1) yVector(:)];
            S2.FaceVertexCData = min(yVector(:),clip*288);
            S2.FaceColor = 'flat';            
            patch(S2);
            hCbar.YLim = [0 clip*288];
            set(hCbar,'FontSize',10,'FontName','times new roman')
            set(hCbar,'XTick',[])
            yCBLim = floor(hCbar.YLim(2));
            if yCBLim == 288
                noteStr = sprintf('%i missing',floor(hCbar.YLim(2)));
            else
                noteStr = sprintf('>%i missing',floor(hCbar.YLim(2)));
            end
            
            % FONT APPEARANCE
            h.FontSize = 9;
            h.FontAngle = 'normal';            
            hTitle = title(noteStr,'Fontweight','normal','Fontsize',9);
            hYLab = ylabel('Number of data points missing during one 24h period (out of 288 pts)','fontsize',14);
            
            % FORMAT PLOT FOR PORTRAIT PAGE (REPORT)
            if isfield(optn,'format') && regexp(optn.format,'A4')                
                h.Parent.Position = [50 50 720 900];
                h.Position = [0.12 0.05 0.74 0.9];
                hCbar.Position = [0.065 0.05 0.02 0.9];
                if (h.XTick(2)-h.XTick(1)==1) && diff(h.XLim)>31
                    h.XTick = 0.5+(h.XTick(1)+weekday(h.XTick(1))-1):7:h.XTick(end);
                    h.XTickLabel = datestr(h.XTick-0.5,'dd-mmm');
                end
            end
            
            h.Box = 'on';
            
        end %%%%%%%%%%
        function obj = Convert3Phase(varargin)
            
            % INITIALISE
            obj = varargin{1};
            L1 = length(obj);
            
            % CREATE LIST OF POWER MEASUREMENTS
            lst0 = {obj.dataId}';            
            
            % GROUP INTO ACTIVE AND REACTIVE            
            lst0 = strrep(lst0,'act','app');
            lst0 = strrep(lst0,'rct','app');
            ids = unique(lst0);
            
            % REMOVE IRRELEVANT SERIES (i.e. NOT ACTIVE/REACTIVE POWER)
            posRm = cellfun(@(x) isempty(regexp(x,'app')),ids);
            ids(posRm) = [];
            
            % FIND PAIRS
            pos = cellfun(@(x) find((ismember(lst0,x))==1),ids,'UniformOutput',0);
            posRm = find(cellfun(@(x) length(x),pos) ~= 2);
            pos(posRm) = [];
            ids(posRm) = [];
            
            % CONVERT TO APPARENT 
            L2 = length(pos);
            y1 = zeros(length(obj(1).t),L2);
            for k = 1:L2
                y1(:,k) = (obj(pos{k}(1)).y.^2 + obj(pos{k}(2)).y.^2).^0.5;                
            end
            
            % POPULATE NEW (ADDED) INSTANCE(S)
            for k = 1:L2
                str = sprintf('add:%s%s','Processed-',ids{k});
                obj(L1+k) = CESI(str);
                obj(L1+k).t = obj(1).t;
                obj(L1+k).y = y1(:,k);
                obj(L1+k).temporalRes = obj(1).temporalRes;
            end
            
            
        end %%%%%%%%%%
        function CreateNewCsv(varargin)
            obj = varargin{1};
            optn = obj.Options(varargin,'sensor:','multiplier:','save:');
            L = length(obj);
            
            if strcmp(optn.save,'auto')
                rspns = 'y'; % BYPASS USER INPUT (WRITE FILES AUTOMATICALLY)
            else
                {obj.dataId}'
                fprintf('(include ''save:auto'' argument to skip this step)')
                rspns = input('save new CSV? (y/n)','s');
            end
            
            % SAVE TO CSV (*** USING PRECISION=16 ***)
            if strcmp(rspns,'y') || strcmp(rspns,'Y')
                
                % EITHER SAVE SELECTION, OR SAVE ALL
                if ~isempty(optn.sensor)
                    inst = optn.sensor;
                else
                    inst = 1:L;
                end
                
                % INCLUDE FIELD IN FILENAME FOR MULTIPLIER (OPTIONAL)
                if ~isempty(optn.multiplier)
                    mult = sprintf('_x%i',optn.multiplier);
                else
                    mult = '';
                end
                
                for k = inst
                    % ENSURE NEW FILE HAS 'Processed' TAG
                    if isempty(regexp(obj(k).dataId,'Processed-'))
                        tag = 'Processed-';
                    else
                        tag = '';
                    end
                    % INCLUDE TIME-WINDOW IN FILENAME
                    numDays = round(obj(k).t(end) - obj(k).t(1));
                    strtDate = datestr(obj(k).t(1),'yyyy-mm-dd');
                    fName = sprintf('%s%s%s_(%s,%idays).csv' , tag , obj(k).dataId , mult , strtDate , numDays);
                    % SAVE FILE (*** USING PRECISION=16 ***)
                    toCsv = [obj(k).t - obj(k).dateNumML2XL  obj(k).y];
                    fPath = sprintf('%s/%s',obj(k).mainPath , fName);
                    dlmwrite(fPath , toCsv , 'precision' , 16);
                end
                
            end
            
        end %%%%%%%%%%
        
        function optn = Options(varargin) % GENERAL UTILITY
            
            % INITIALISE
            input = varargin{2};
            defaults = {varargin{3:end}};
            
            % EXTRACT ARGUMENTS FROM USER INPUT AND ASSIGN TO MATRIX (WHERE ":" IS USED)
            if ischar(('obj'))
                strt = 1;
            else
                strt = 2;
            end
            for k = strt:length(input)
                try
                    if ~isempty(strfind(input{k},':'))
                        temp = strsplit(input{k},':');
                        name = temp{1};
                        % CONVERT NUMERICAL ARGUMENTS TO DOUBLES IF NECESSARY
                        if ~isnan(str2double(temp{2}))
                            optn.(name) = str2double(temp{2});
                        else
                            optn.(name) = temp{2};
                        end                        
                    end
                catch
                end
            end
            
            % EXAMINE DEFAULTS, AND ASIGN IF REQUIRED (OR INCLUDE BLANK FIELDS)
            for k = 1:length(defaults)
                try
                    if ~isempty(strfind(defaults{k},':'))
                        temp = strsplit(defaults{k},':');
                        name = temp{1};
                        if ~exist('optn') || sum(cell2mat(regexp(name,fields(optn)))) == 0
                            % CONVERT NUMERICAL ARGUMENTS TO DOUBLES IF NECESSARY
                            if ~isnan(str2double(temp{2}))
                                optn.(name) = str2double(temp{2});
                            else
                                optn.(name) = temp{2};
                            end
                        end
                    end
                catch
                end
            end
            
            % INCULDE BLANK STRUCTURE IF NECESSARY (LAST RESORT)
            try
                optn;
            catch
                optn = [];
            end
            
        end %%%%%%%%%%
        
    end
    
end

