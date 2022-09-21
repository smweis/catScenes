%% pwNavLayout005
%
% Smoothed angular histograms and a model RDM using the data from pwNavLayout004
%
%% Syntax
%
% pwNavLayout005
%
%% Description
%
% Create a model RDM from the navigational layout data
%
%% Example
%
%   pwNavLayout005;
%
%% See also
%
% * <file:pwNavLayout004.html pwNavLayout004>
%
% Michael F. Bonner | University of Pennsylvania | <https://urldefense.proofpoint.com/v2/url?u=http-3A__www.michaelfbonner.com&d=DwIGAg&c=sJ6xIWYx-zLMB3EPkvcnVg&r=DHktf-DMom2RVqSKuMPVz5d7B7wQ5sMSm0Z8cjn1Utk&m=VlgafRVWS1aTzr6B0xjUCmcSb3pm_VDAesuyCs7kHww&s=XbTaV8vwjIncRXEjsQSuMmQs5zeBFIxOVYbaxzFvmK8&e= >


%% Assign variables

% Directories
outDir = fullfile('/Users/michaelbonner/iMac_Projects/Pathways/Stimuli/analyses/', mfilename);
mkdirIF(outDir);

% Nav layout norming data
load('/Users/michaelbonner/iMac_Projects/Pathways/Stimuli/analyses/pwNavLayout004/binCounts.mat');
% Loads:
% * binCounts
nChans = size(binCounts, 2);

% Conditions
conditionsFile = '/Users/michaelbonner/iMac_Projects/Pathways/fMRI_ExperimentB/analyses/variables/conditions.mat';
load(conditionsFile);
% Loads:
% * conditions
nConds = length(conditions);
nRdmComps = nchoosek(nConds,2);

% Runs
runsFile = '/Users/michaelbonner/iMac_Projects/Pathways/ExperimentA/analyses/variables/runs.mat';
load(runsFile);
% Loads:
% * runs
nRuns = length(runs);

% Stimulus images for tSNE plot
imgDir = '/Users/michaelbonner/Code/PathwaysExperimentA/stimuli/scanning/pathways/';



%% RDM from smoothed histograms

% Affordance RDM
histDir = fullfile(outDir, 'histogram_plots');
mkdirIF(histDir);
modVecs = nan(nConds, nChans);
for iConds = 1 : nConds
    cond = conditions{iConds};

    % Trajectory histogram
    binData = binCounts(iConds, :);
    
    % Automated robust smoothing
    modVec = smoothn(binData, 'robust');
    modVec(modVec<0) = 0;  % set hard lower bound at 0 (in case the smoothing introduces some small negative values)

    % Add to data matrix
    modVecs(iConds, :) = modVec;

    % Plot histogram
    figure('Visible', 'off')
    bar(binData, 'FaceColor', [.8 .8 .8], 'EdgeColor', [.8 .8 .8])
    hold on

    % Overlay smoothed data    
    x = 1:length(modVec);
    y = modVec;
    z = zeros(size(x));
    c = x;
    cline(x,y,z,c,'cool');
    ylimVals = ylim(gca);

    % Format and write to file
    set(gca,...
        'Box', 'off',...
        'FontSize', 8,...
        'TickDir', 'out',...
        'XLim', [0, 180],...
        'YLim', [0, ylimVals(2)],...
        'XTick', 0:60:180,...
        'XTickLabelRotation', 45,...
        'YTick', [],...
        'YTickLabel', {});
    ylabel('a.u.')
    xlabel('Angle')
    set(gcf, 'units', 'centimeters', 'pos', [0 1000 6 4])
    file = fullfile(histDir, [cond '.pdf']);
    export_fig(file, '-transparent');
    close all
    
    % Plot histogram
    colors = cool(nChans);
    nBars = length(binData);
    figure('Visible', 'off')
    for iBars = 1 : nBars
        X=ones(1,nBars)*NaN;
        Y=X;
        X(iBars)=iBars;
        Y(iBars)=modVec(iBars);
        bar(X,Y,'FaceColor',colors(iBars,:), 'EdgeColor',colors(iBars,:))
        if iBars ==1; hold on; end
    end  % for iBars = 1 : nBars
    axis off
    set(gcf, 'Color', 'w');
    file = fullfile(histDir, ['smoothed_' cond '.png']);
    export_fig(file);
    close all
    
    %     % Plot smoothed data only
    %     figure('Visible', 'off')
    %     x = 1:length(modVec);
    %     y = modVec;
    %     z = zeros(size(x));
    %     c = x;
    %     h = cline(x,y,z,c,'cool',6);
    %     ylimVals = ylim(gca);
    %     set(gca, 'YLim', [0, ylimVals(2)]);
    %
    %     % Format and write to file
    %     axis off
    %     set(gcf, 'Color', 'w');
    %     file = fullfile(histDir, ['smoothed_' cond '.png']);
    %     export_fig(file);
    %     close all
    
end   % for iConds = 1 : nConds

% Model RDM
modVecs = zscore(modVecs, [], 2);
modRdm = pdist(modVecs, 'euclidean') .^ 2;  % squared Euclidean distance

% Write to file
file = fullfile(outDir, 'modData.mat');
save(file, 'modVecs', 'modRdm');



%% Plot RDMs

% PCA
[loadings, components, ~, ~, explained] = pca(modVecs);

% Model RDM sorted by first PC
[~, sortInds] = sort(components(:, 1));
rdm = pdist(modVecs(sortInds, :), 'euclidean') .^ 2;  % squared Euclidean distance

% Save sorting indices for sorting other RDMs in the same order
file = fullfile(outDir, 'sortInds.mat');
save(file, 'sortInds');

% Rank transform and square the RDM
rdm = rankTransform(rdm, 1);
rdm = squareform(rdm);

% Plot RDM
figure('Visible', 'off');
clf;
p = panel();  % create panel figure
p.pack(1, 1);  % panel packing
p.fontsize = 8;  % fonts
%     p(1, 1).select();
hMat = imagesc(rdm);
colormap(RDMcolormap);
set(gca, ...
    'Ticklength', [0 0],...
    'XTick', [],...
    'XTickLabel', {},...
    'YTick', [],...
    'YTickLabel', []);

% Write image to file
file = fullfile(outDir, 'rdm.pdf');
p.export(file, '-w35', '-h30');
close all



%% tSNE

% tSNE parameters
MAX_ITER = 5000;
FINAL_DIMS = 2;
PERPLEXITY = 30;

% tSNE
sqRdm = squareform(modRdm);
D = sqRdm;
D = D / max(D(:)); % normalize distances
P = d2p(D, PERPLEXITY, 1e-5);
embedding = mfb_tsne_p(P, [], FINAL_DIMS, MAX_ITER);

% Images for plot
imgs = cell(nConds, 1);  % load icon images
for iConds = 1 : nConds
    cond = conditions{iConds};
    filename = [cond '.jpg'];
    file = fullfile(imgDir, filename);
    img = imread(file);
    imgs{iConds} = img;    
end  % for iConds = 1 : nConds

% Plot tSNE
figure('Visible', 'on');
PLOT_SCALE = 2000;
x = zscore(embedding(:,1));
y = zscore(embedding(:,2));
a = plot(x, y, 'ow');
hold on
for iConds = 1 : nConds
    image(PLOT_SCALE*x(iConds), PLOT_SCALE*y(iConds), flip(imgs{iConds}))
end
hold off
axis off
set(gcf, 'Position', [0 0 1533 1294]);
file = fullfile(outDir, 'tSNE.pdf');
export_fig(file, '-transparent');
close all



%% tSNE plot of channel responses

% Images for plot
chanImgs = cell(nConds, 1);  % load icon images
for iConds = 1 : nConds
    cond = conditions{iConds};
    file = fullfile(histDir, ['smoothed_' cond '.png']);
    img = imread(file);
    chanImgs{iConds} = img;    
end  % for iConds = 1 : nConds

% Plot navigational heatmaps
figure('Visible', 'on');
PLOT_SCALE = 1300;
x = zscore(embedding(:,1));
y = zscore(embedding(:,2));
a = plot(x, y, 'ow');
hold on
for iConds = 1 : nConds
    image(PLOT_SCALE*x(iConds), PLOT_SCALE*y(iConds), flip(chanImgs{iConds}))
end
hold off
axis off
set(gcf, 'Position', [1000         486        1051         852]);
file = fullfile(outDir, 'tSNE_channels.pdf');
export_fig(file, '-transparent');
close all
