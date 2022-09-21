function [modelRdm, modelRdmVec, iSort] = convertVectorsToModelRDM(matrix,conditions,varargin)

%% Parse input
p = inputParser;

% Required input
p.addRequired('matrix',@ismatrix);
p.addRequired('conditions',@iscell);
% Optional params
p.addParameter('distanceMetric','euclidean',@ischar);
p.addParameter('iSort',[],@isvector);
p.addParameter('savefig',false,@islogical);
p.addParameter('outputDir','.',@ischar);
p.addParameter('fileName','test',@ischar);
p.addParameter('showfig',false,@islogical);

% Parse and check the parameters
p.parse( matrix, conditions, varargin{:});


nConds = length(conditions);

% Sort conditions alphabetically
[~,sortedConditions] = sort(conditions);

% Calculate modelRdm on sorted conditions (alphabetically)
modelRdmVec = pdist(matrix(sortedConditions, :), p.Results.distanceMetric);
modelRdm = squareform(modelRdmVec);


% RDM figure
if isempty(p.Results.iSort)
    % Model RDM sorted by first PC
    % PCA
    [~, components, ~, ~, ~] = pca(matrix);
    [~, iSort] = sort(components(:, 1));
else
    iSort = p.Results.iSort; 
end

modelRdmVecPlot = pdist(matrix(iSort, :), p.Results.distanceMetric);

modelRdmPlot = squareform(modelRdmVecPlot);

% RDM figure
if p.Results.showfig

    figure('Visible', 'on');
    set(gcf,'Position',[10,10,1200,1200]);
    set(gca,'FontSize',24);
    imagesc(modelRdmPlot);

    % Print text on figure
    minText = num2str(min(modelRdmVecPlot));
    try minText = minText(1:4); catch; end % If the min or max is zero, catch the error and keep it one digit.
    minText = horzcat('similar: ',minText);
    maxText = num2str(max(modelRdmVecPlot));
    try maxText = maxText(1:4); catch; end
    maxText = horzcat('dissimilar: ',maxText);

    colormap('jet');
    
    tickLabels = conditions(iSort);
    tickInterval = 1:50:nConds;
    tickLabels = tickLabels(tickInterval);
    set(gcf, 'color', 'w');
    set(gca, ...
        'FontSize', 10,...
        'Ticklength', [0 0],...
        'TickLabelInterpreter', 'none',...
        'XTick', tickInterval,...
        'XTickLabel', tickLabels,...
        'XTickLabelRotation', 45,...
        'YTick', tickInterval,...
        'YTickLabel', tickLabels);
    
    colorbar('FontSize', 12, 'Ticks', [min(modelRdmVecPlot) max(modelRdmVecPlot)],...,
        'TickLabels', {minText, maxText}, 'TickLength', 0);

    if p.Results.savefig
        fileName = strcat('plot_modelRdm_sorted_',p.Results.fileName,'.png');
        file = fullfile(p.Results.outputDir, fileName);
        export_fig(file, '-transparent', '-r300');
    end
end

end
