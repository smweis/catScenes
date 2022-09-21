function preprocessLingData(dataArray,conditions,varargin)

%% Parse input
p = inputParser;

% Required input
p.addRequired('dataArray',@ismatrix);
p.addRequired('conditions',@iscell);
% Optional params
p.addParameter('nBins',7, @isvector);
p.addParameter('savefig',false,@islogical);
p.addParameter('outputDir','.',@ischar);

% Parse and check the parameters
p.parse( dataArray, conditions, varargin{:});


% Get condition and bin info
nConds = length(conditions);
nBins = 7;



for iConds = 1 : nConds
    
    condData = dataArray(iConds,:);
    % Plot histogram
    if p.Results.savefig
        colors = cool(nBins);
        nBars = nBins;
        figure('Visible', 'off')
        for iBars = 1 : nBars
            X=ones(1,nBars)*NaN;
            Y=X;
            X(iBars)=iBars;
            Y(iBars)=condData(iBars);
            bar(X,Y,1,'FaceColor',colors(iBars,:), 'EdgeColor',colors(iBars,:))
            if iBars ==1; hold on; end
        end  % for iBars = 1 : nBars
        xlimLeft = 0;
        xlimRight = nBars + 1;  % X-axis limits
        set(gca,...
            'Box', 'off',...
            'FontSize', 14,...
            'TickDir', 'out',...
            'XLim', [xlimLeft, xlimRight],...
            'XTick', 1:nBins,...
            'XTickLabel', {'sharp left','left','slight left','ahead','slight right','right','sharp right'},...
            'XTickLabelRotation',45,...
            'YLim', [0 1]);
        
        set(gcf,'Position',[100 100 800 400]);
           
        file = fullfile(p.Results.outputDir,[conditions{iConds} '.png']);
        saveas(gcf,file);
        close;
    end
    
end


end
