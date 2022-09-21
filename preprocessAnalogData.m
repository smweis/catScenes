function binZscores = preprocessAnalogData(dataArray,conditions,varargin)

%% Parse input
p = inputParser;

% Required input
p.addRequired('dataArray',@ismatrix);
p.addRequired('conditions',@iscell);
% Optional params
p.addParameter('theta_bins',0:179, @isvector);
p.addParameter('savefig',false,@islogical);
p.addParameter('saveOutput',false,@islogical);
p.addParameter('pID','',@ischar);
p.addParameter('outputDir','.',@isstring);
p.addParameter('imgHeight',100,@isnumeric);
p.addParameter('imgWidth',100,@isnumeric);

% Parse and check the parameters
p.parse( dataArray, conditions, varargin{:});


% Get condition and bin info
nConds = length(conditions);
nBins = length(p.Results.theta_bins)-1;
binCounts = nan(nConds, nBins, 'single');


% Polar coordinates
[x, y] = meshgrid(1:p.Results.imgWidth, 1:p.Results.imgHeight);
x = x - p.Results.imgWidth/2;  % set origin to bottom middle of image
x = fliplr(x);  % flip so that the x-axis count up from the left
y = flipud(y);  % flip so that the y-axis counts up from the bottom
theta = cart2pol(x, y);  % convert to polar coordinates
theta = rad2deg(theta);  % convert to degrees

for iConds = 1 : nConds

    % Raw data

    paths = flip(rot90(reshape(dataArray(:,iConds),100,100))); 
    
    % Sum across subjects
    paths = sum(paths, 3);

    % Histogram binned by angle
    binData = nan(1, nBins);
    for iBins = 1 : nBins
        binA = p.Results.theta_bins(iBins);
        binB = p.Results.theta_bins(iBins+1);  % bins of one degree
        binInds = (binA<=theta) & (theta<binB);  % indices within the theta bin
        pathData = paths(binInds);  % data in bin
        pathData = sum(pathData);  % count data in bin
        binData(iBins) = pathData;
    end  % for iBins = 1 : nBins
    
    % Add to data array
    binCounts(iConds, :) = binData;
 
    % Plot histogram
    if p.Results.savefig
        colors = cool(nBins);
        nBars = length(binData);
        figure('Visible', 'off');
        for iBars = 1 : nBars
            X=ones(1,nBars)*NaN;
            Y=X;
            X(iBars)=iBars;
            Y(iBars)=binData(iBars);
            bar(X,Y,'FaceColor',colors(iBars,:), 'EdgeColor',colors(iBars,:))
            if iBars ==1; hold on; end
        end  % for iBars = 1 : nBars
        xlimLeft = 0;
        xlimRight = nBars + 1;  % X-axis limits
        set(gca,...
            'Box', 'off',...
            'FontSize', 14,...
            'TickDir', 'out',...
            'XLim', [xlimLeft, xlimRight],...
            'XTick', 0:60:180,...
            'YTick', [],...
            'YTickLabel', {});
        file = fullfile(p.Results.outputDir,[conditions{iConds} '.png']);
        saveas(gcf,file);
        close;
    end
    
end

binZscores = zscore(binCounts, [], 2);

if p.Results.saveOutput
    T = array2table(binZscores');
    T.Properties.VariableNames = conditions;
    writetable(T,strcat(p.Results.outputDir,'/',p.Results.pID,'_tuningCurves_',num2str(length(p.Results.theta_bins)),'.csv'));
end

end
