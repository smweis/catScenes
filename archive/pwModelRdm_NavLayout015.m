%% pwModelRdm_NavLayout015
%
% Model RDM of navigational-layout data from pwNavLayout001 using half-wave
% rectified, squared sinusoidal basis functions
%
%% Syntax
%
% pwModelRdm_NavLayout015
%
%% Description
%
% Create a model RDM from the navigational layout data using a set of basis
% functions created by taking the sinusoid of the polar-angles. This is
% based on approach used in the following paper:
%
% Brouwer (2009) Decoding and Reconstructing Color from Responses in Human Visual Cortex
%
%% Example
%
%   pwModelRdm_NavLayout015;
%
%% See also
%
% * <file:pwNavLayout001.html pwNavLayout001>
% * <file:pwModelRdm_NavLayout013.html pwModelRdm_NavLayout013>
%
% Michael F. Bonner | University of Pennsylvania | <https://urldefense.proofpoint.com/v2/url?u=http-3A__www.michaelfbonner.com&d=DwIGAg&c=sJ6xIWYx-zLMB3EPkvcnVg&r=DHktf-DMom2RVqSKuMPVz5d7B7wQ5sMSm0Z8cjn1Utk&m=VlgafRVWS1aTzr6B0xjUCmcSb3pm_VDAesuyCs7kHww&s=XbTaV8vwjIncRXEjsQSuMmQs5zeBFIxOVYbaxzFvmK8&e= >


%% Assign variables

% Directories
outputDir = fullfile('/Users/michaelbonner/iMac_Projects/Pathways/Stimuli/analyses/', mfilename);
mkdirIF(outputDir);

% Conditions
file = '/Users/michaelbonner/iMac_Projects/Pathways/fMRI_ExperimentB/analyses/variables/conditions.mat';
load(file);
% Loads:
% * conditions
nConds = length(conditions);

% Nav layout norming data
load('/Users/michaelbonner/iMac_Projects/Pathways/Stimuli/analyses/pwNavLayout001/Data.mat');
% Loads:
% * Data
nSubjects = size(Data.(conditions{1}), 3);

% Stimulus images for tSNE plot
imgDir = '/Users/michaelbonner/Code/PathwaysExperimentA/stimuli/scanning/pathways/';
imgs = fullfile(imgDir, strcat(conditions,'.jpg'));

% tSNE parameters
MAX_ITER = 5000;
FINAL_DIMS = 2;
PERPLEXITY = 30;

% Path data preprocessing parameters
DILATION = 2;  % amount to dilate mouse-tracking data

% Sinusoidal basis set parameters 
N_FUNCS = 6;  % note that these functions span the full theta range and will be truncated using the model theta range
POWER_TRANSFORM = 2;  % power-transform to apply to the sinusoid (the Brouwer paper uses 2, but in later papers that group has used higher values)
FULL_THETA = 0 : 359;  % create sinusoids based on the full range of polar angles
nTheta = length(FULL_THETA);
MODEL_THETA = 0 : 179;  % use the subset of basis functions that fall within the range of the model theta
nBins = length(MODEL_THETA);
thetaInds = ismember(FULL_THETA, MODEL_THETA);
nThetaInds = sum(thetaInds);
MIN_PEAK = 0.95;  % only use basis functions whose max value within the range of the model theta is at least MIN_PEAK



%% Sinusoidal basis functions

% Polar coordinates
[imgHeight, imgWidth] = size(Data.(conditions{1})(:,:,1));
[x, y] = meshgrid(1:imgWidth, 1:imgHeight);
x = x - imgWidth/2;  % set origin to bottom middle of image
x = fliplr(x);  % flip so that the x-axis count up from the left
y = flipud(y);  % flip so that the y-axis counts up from the bottom
[theta, rho] = cart2pol(x, y);  % convert to polar coordinates
theta = rad2deg(theta);  % convert to degrees

% Plot theta
figure('Visible', 'on');
imagesc(theta)
colormap('cool')
hCbar = colorbar('southoutside', 'Ticks', 0:30:180, 'FontSize', 12);
hCbar.Box = 'off';
axis off
file = fullfile(outputDir, 'plot_thetaValues.png');
export_fig(file, '-transparent', '-r300');
close all

% Sinusoidal basis functions
basisFuncs = nan(N_FUNCS, nThetaInds);
for iFuncs = 1 : N_FUNCS
    basisFunc = sin(FULL_THETA.*(2*pi/nTheta) - ((iFuncs-1)*(2*pi/N_FUNCS)));
    basisFunc(basisFunc<0) = 0;  % half-wave rectify    
    basisFunc = basisFunc.^POWER_TRANSFORM;
    basisFunc = basisFunc(thetaInds);
    basisFuncs(iFuncs, :) = basisFunc;
end  % for iFuncs = 1 : N_FUNCS

% Remove basis without peaks in the range of MODEL_THETA
basisPeaks = max(basisFuncs, [], 2);
basisInds = basisPeaks >= MIN_PEAK;
basisFuncs = basisFuncs(basisInds, :);
nBases = size(basisFuncs, 1);

% Sort by peak theta
[~, peakInds] = max(basisFuncs, [], 2);
[~, sortInds] = sort(peakInds, 'ascend');
basisFuncs = basisFuncs(sortInds, :);

% Plot basis functions
figure('Visible', 'on');
colors = cool(nBases);
for iBases = 1 : nBases
    basisFunc = basisFuncs(iBases, :);
    plot(MODEL_THETA, basisFunc, 'LineWidth', 2, 'Color', colors(iBases,:))
    hold on
end  % for iBases = 1 : nBases
set(gca,...
    'Box', 'off',...
    'FontSize', 14,...
    'TickDir', 'out',...
    'YTick', [],...
    'XTick', 1:60:181,...
    'XTickLabel', 0:60:180);
% ylabel('Relative response')
set(gcf, 'Position', [1258 888 263 153]);

% Write to file
file = fullfile(outputDir, 'plot_BasisFuncs.pdf');
export_fig(file, '-transparent');
close all



%% Compute response of basis functions from nav layout histograms

% Data in theta bins
modelVectors = nan(nConds, nBases);
fullHists = nan(nConds, nBins, 'single');
allPaths = nan(imgHeight, imgWidth, nConds, 'single');
icons = cell(nConds, 1);
for iConds = 1 : nConds
    cond = conditions{iConds};
    
    % Raw data
    paths = Data.(cond);  
    
    % Dilate
    nSubj = size(paths, 3);
    for iSubj = 1 : nSubj
        pathData = paths(:, :, iSubj);
        pathData = imdilate(pathData, strel('disk',DILATION));
        paths(:, :, iSubj) = pathData;
    end  % for iSubj = 1 : nSubj
    
    % Sum across subjects
    paths = sum(paths, 3);
    allPaths(:, :, iConds) = paths;

    % Histogram binned by angle
    condData = nan(1, nBins);
    for iBins = 1 : nBins
        binA = MODEL_THETA(iBins);
        binB = binA + 1;  % bins of one degree
        binInds = (binA<=theta) & (theta<binB);  % indices within the theta bin
        pathData = paths(binInds);  % data in bin
        pathData = sum(pathData);  % count data in bin
        condData(iBins) = pathData;
    end  % for iBins = 1 : nBins
    fullHists(iConds, :) = condData;
    
    % Basis-function responses
    modelVector = basisFuncs * condData';
    modelVectors(iConds, :) = modelVector;

    % Color map
    angleColors = cool(nBases);  % polar angle colormap
    [~, maxInd] = max(modelVector);
    angleColor = angleColors(maxInd, :);
    
    % Plot histogram
    colors = cool(nThetaInds);
    nBars = length(condData);
    figure('Visible', 'off')
    for iBars = 1 : nBars
        X=ones(1,nBars)*NaN;
        Y=X;
        X(iBars)=iBars;
        Y(iBars)=condData(iBars);
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
        'XTick', 1:60:181,...
        'XTickLabel', 0:60:180,...
        'YTick', [],...
        'YTickLabel', {});
    set(gcf, 'Position', [1258 888 263 153]);
    file = fullfile(outputDir, ['plot_histogram_' cond '.pdf']);
    export_fig(file, '-transparent');
    
    % Plot channel responses
    Inputs.means = modelVector;
    Inputs.colors = angleColors;
    Inputs.visible = 'off';
    mfbBars(Inputs)
    set(gca,...
        'Box', 'off',...
        'FontSize', 14,...
        'TickDir', 'out',...
        'XTick', 1:nBases,...
        'XTickLabel', {'L', 'C', 'R'},...
        'YTick', [],...
        'YTickLabel', {});
    set(gcf, 'Position', [1258 888 83 153]);
    file = fullfile(outputDir, ['plot_channelResponses_' cond '.pdf']);
    export_fig(file, '-transparent');
    
    % Image icon PDF
    figure('Visible', 'off');
    imagesc(paths)
    %     axis off
    set(gca, 'TickLength', [0 0], 'XTick', [], 'YTick', [])
    colormap(flipud(gray));
    file = fullfile(outputDir, [cond '.pdf']);  % pdf version
    export_fig(file, '-transparent');
    
    % Image icon with color-coded box
    set(gca, 'LineWidth', 12, 'YColor', angleColor, 'XColor', angleColor)
    colormap(colorScale([angleColor; 0 0 0], 64));  % colormap with colored background
    file = fullfile(outputDir, [cond '.jpg']);  % jpg version
    export_fig(file, '-transparent');
    icons{iConds} = file;  % add to icons array
    close all
    
end   % for iConds = 1 : nConds

% % Z-score across conditions
% modelVectors = zscore(modelVectors);

% Save model data
file = fullfile(outputDir, 'modelVectors.mat');
save(file, 'modelVectors');

% Save histogram data
file = fullfile(outputDir, 'fullHists.mat');
save(file, 'fullHists');

% Save path data
file = fullfile(outputDir, 'allPaths.mat');
save(file, 'allPaths');



%% Model RDM

% Model RDM
modelRdm = pdist(modelVectors, 'correlation'); 

% Save RDM
file = fullfile(outputDir, 'modelRdm.mat');
save(file, 'modelRdm');

% RDM figure
figure('Visible', 'off');
thisRdm = modelRdm;
thisRdm = rankTransform(thisRdm, 1);
thisRdm = squareform(thisRdm);
imagesc(thisRdm)
colormap('JET');
set(gca, ...
    'FontSize', 12,...
    'Ticklength', [0 0],...
    'TickLabelInterpreter', 'none',...
    'XTick', 1:nConds,...
    'XTickLabel', conditions,...
    'XTickLabelRotation', 45,...
    'YTick', 1:nConds,...
    'YTickLabel', conditions);
colorbar('FontSize', 12, 'Ticks', [0.01 0.99], 'TickLabels', {'similar', 'dissimilar'}, 'TickLength', 0);
set(gcf, 'Position', [1000 420 1065 918]);
file = fullfile(outputDir, 'plot_modelRdm.png');
export_fig(file, '-transparent', '-r300');
close all

% tSNE
thisRdm = squareform(modelRdm);
D = thisRdm;
D = D / max(D(:)); % normalize distances
P = d2p(D, PERPLEXITY, 1e-5);
lowDimEmbedding = mfb_tsne_p(P, [], FINAL_DIMS, MAX_ITER);
lowDimRdm = pdist(lowDimEmbedding);
close all

% JSON icons file for tSNE
jsonFile = fullfile(outputDir, 'icons.json');
Inputs.nodeNames = conditions;
% Inputs.nodeIcons = icons;  % use icon images
Inputs.nodeIcons = imgs;  % use stimulus images
Inputs.distances = lowDimRdm;
Inputs.jsonFile = jsonFile;
rdm2json_Icons(Inputs);

% HTML file for tSNE
Inputs.jsonLink = jsonFile;
Inputs.htmlFile = fullfile(outputDir, 'tSNE_plot.html');
Inputs.htmlTitle = 'Model RDM';
Inputs.linkColor = '#FFFFFF';
Inputs.displaySize = [2400, 1100];
Inputs.iconSize = [80, 80];
Inputs.jsonInlcudesNodeHyperLinks = false;
makeHtml_ForceLayout_Icons(Inputs);



%% Plot RDM sorted by first PC

% PCA
[loadings, components, ~, ~, explained] = pca(modelVectors);

% Model RDM sorted by first PC
[~, iSort] = sort(components(:, 1));
modelRdm = pdist(modelVectors(iSort, :), 'correlation');

% Save sorting indices for sorting other RDMs in the same order
thisFile = fullfile(outputDir, 'iSort.mat');
save(thisFile, 'iSort');

% RDM figure
figure('Visible', 'off');
thisRdm = modelRdm;
thisRdm = rankTransform(thisRdm, 1);
thisRdm = squareform(thisRdm);
imagesc(thisRdm)
colormap(RDMcolormap);
% colormap(brewermap([],'RdBu'));
set(gca, ...
    'FontSize', 12,...
    'Ticklength', [0 0],...
    'TickLabelInterpreter', 'none',...
    'XTick', 1:nConds,...
    'XTickLabel', conditions(iSort),...
    'XTickLabelRotation', 45,...
    'YTick', 1:nConds,...
    'YTickLabel', conditions(iSort));
colorbar('FontSize', 12, 'Ticks', [0.01 0.99], 'TickLabels', {'similar', 'dissimilar'}, 'TickLength', 0);
set(gcf, 'Position', [1000 420 1065 918]);
file = fullfile(outputDir, 'plot_modelRdm_sorted.png');
export_fig(file, '-transparent', '-r300');

% PDF version
file = fullfile(outputDir, 'plot_modelRdm_sorted.pdf');
export_fig(file, '-transparent');
close all
