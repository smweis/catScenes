
% Path data preprocessing parameters
THETA_BINS = 0 : 179;  % count data in 1-degree theta bins
nBins = length(THETA_BINS);
imageSize = [384,512];
outDir = 'C:\Users\stevenweisberg\Desktop\Splash\';

conditions = fieldnames(Trajs);
nConds = length(conditions);

%% Polar coordinates

% Polar coordinates
imgHeight = imageSize(1);
imgWidth = imageSize(2);
[x, y] = meshgrid(1:imgWidth, 1:imgHeight);
x = x - imgWidth/2;  % set origin to bottom middle of image
x = fliplr(x);  % flip so that the x-axis count up from the left
y = flipud(y);  % flip so that the y-axis counts up from the bottom
[theta, rho] = cart2pol(x, y);  % convert to polar coordinates
theta = rad2deg(theta);  % convert to degrees



%% Trajectory data binned by angle

binCounts = nan(nConds, nBins, 'single');
for iConds = 1 : nConds
    cond = conditions{iConds};
    
    % Raw data
    paths = Trajs.(cond);  

    % Sum across subjects
    paths = sum(paths, 3);

    % Histogram binned by angle
    binData = nan(1, nBins);
    for iBins = 1 : nBins
        binA = THETA_BINS(iBins);
        binB = binA + 1;  % bins of one degree
        binInds = (binA<=theta) & (theta<binB);  % indices within the theta bin
        pathData = paths(binInds);  % data in bin
        pathData = sum(pathData);  % count data in bin
        binData(iBins) = pathData;
    end  % for iBins = 1 : nBins
    
    % Add to data array
    binCounts(iConds, :) = binData;
 
    % Plot histogram
    colors = cool(nBins);
    nBars = length(binData);
%     figure('Visible', 'off')
%     for iBars = 1 : nBars
%         X=ones(1,nBars)*NaN;
%         Y=X;
%         X(iBars)=iBars;
%         Y(iBars)=binData(iBars);
%         bar(X,Y,'FaceColor',colors(iBars,:), 'EdgeColor',colors(iBars,:))
%         if iBars ==1; hold on; end
%     end  % for iBars = 1 : nBars
%     xlimLeft = 0;
%     xlimRight = nBars + 1;  % X-axis limits
%     set(gca,...
%         'Box', 'off',...
%         'FontSize', 14,...
%         'TickDir', 'out',...
%         'XLim', [xlimLeft, xlimRight],...
%         'XTick', 0:60:180,...
%         'YTick', [],...
%         'YTickLabel', {});
%     %set(gcf, 'Position', [1258 888 263 153]);
%     %file = fullfile(outDir, ['plot_histogram_' cond '.pdf']);
%     %saveas(gcf,file)
    
end   % for iConds = 1 : nConds

% Save model data
file = fullfile(outDir,'binCounts.mat');
save(file, 'binCounts');
