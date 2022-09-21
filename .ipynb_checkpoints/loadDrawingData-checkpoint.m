%% Adapted from Bonner & Epstein
baseDir = '\\exasmb.rc.ufl.edu\blue\stevenweisberg\share\catscenes\';
dataDir = "\\exasmb.rc.ufl.edu\blue\stevenweisberg\share\catscenes\data\";
imgDir = '\\exasmb.rc.ufl.edu\blue\stevenweisberg\share\catscenes\BOLD5000_Stimuli_Hist';
brainDir = '\\exasmb.rc.ufl.edu\blue\stevenweisberg\share\catscenes\BOLD5000_ROIs\ROIs\';
figureDir = fullfile(baseDir,'figures');
%% Import data and directories

% ANALOG DATA

% Import the data
analogData = readtable(fullfile(dataDir,'drawingData.csv'),'PreserveVariableNames',true);
analogData = analogData(:,2:end);
analogData = removevars(analogData,{'hedgemaze1.jpg'});
analogData = analogData(:,sort(analogData.Properties.VariableNames));
analogDataArrayOriginal = table2array(analogData);

% Names of variables = condition names
analogConditions = analogData.Properties.VariableNames;
nAnalogConds = length(analogConditions);

% LINGUISTIC DATA
% Import the linguistic data
lingData = readtable(fullfile(dataDir,'lingDirections.csv'),'PreserveVariableNames',true);
lingData = sortrows(lingData,'presentedImage');

directionOrder = {'sharp_left','left','slight_left','ahead','slight_right','right','sharp_right'};

lingData = lingData(:,{'presentedImage','sharp_left','left','slight_left','ahead','slight_right','right','sharp_right'});
% Convert to output type
lingDataArray = table2array(lingData(:,2:end));

% Names of variables = condition names
lingConditions = lingData.presentedImage';
nLingConds = length(lingConditions);


lingDataArray_3bins(:,1) = sum(lingDataArray(:,1:3),2);
lingDataArray_3bins(:,2) = sum(lingDataArray(:,4),2);
lingDataArray_3bins(:,3) = sum(lingDataArray(:,5:7),2);

% LINGUISTIC

[~,iSort] = sortrows(lingDataArray,[4 1 2 3 5 6 7]);
[lingRdm, lingRdmVec, lingSort] = convertVectorsToModelRDM(lingDataArray,lingConditions,'iSort',iSort,'showfig',true,'savefig',false,'fileName','ling7');

[lingRdm_3bins, lingRdmVec_3bins] = convertVectorsToModelRDM(lingDataArray_3bins,lingConditions,'showfig',true,'savefig',true,'fileName','ling3');


allBins = [1,2,5,20,30,45,60];
for i = 1:length(allBins)
    binSizes(i) = length(0:allBins(i):180)-1;
end

%allBins = 60;
% Preprocess analogData
for i = 1:length(allBins)
    allBins(i)
    outputDir = fullfile(baseDir,horzcat('BOLD5000_Stimuli_Hist_',num2str(allBins(i)),'degree'));
    
    %mkdir(outputDir);
    
    analogDataArray = preprocessAnalogData(analogDataArrayOriginal,analogConditions,...
        'savefig',false,'outputDir',outputDir,'theta_bins',0:allBins(i):180);


    % Create RDMs
    
    % ANALOG
    [analogRdm, analogRdmVec, analogSort] = convertVectorsToModelRDM(analogDataArray,...
        analogConditions,'iSort',iSort,'outputDir',figureDir,'showfig',true,'savefig',false,'fileName',num2str(length(0:allBins(i):180)-1));


    for j = 1:200
        n=numel(analogDataArray(:,1));
        ii=randperm(n);
        ii2=randperm(n);
        fakeAnalogDataArray=analogDataArray(ii,:);
        fakeLingDataArray=lingDataArray(ii2,:);

        % RDMs
        [~, fakeAnalogRdmVec, ~] = convertVectorsToModelRDM(fakeAnalogDataArray,analogConditions);
        [~, fakeLingRdmVec, ~] = convertVectorsToModelRDM(fakeLingDataArray,lingConditions);
        
        randBehavior(j,i) = corr(fakeLingRdmVec',fakeAnalogRdmVec');
    end
    
    
    % Correlation between the two behavioral measures
    behaviorCorr(i) = corr(lingRdmVec',analogRdmVec');
    fprintf('%d bins: Analog-Ling_7: %0.4f',allBins(i),behaviorCorr);
    behaviorCorr_3bins_Ling(i) = corr(lingRdmVec_3bins',analogRdmVec');
    % Initial correlation and plot
    fprintf('%d bins: Analog-Ling_3: %0.3f, p = %0.3f\n',allBins(i),k,p);
    

    
%     
%     % Plot scatter
%     figure('Visible','on'); 
%     PLOT_SCALE = 2000;
%     x = zscore(lingRdmVec);
%     y = zscore(analogRdmVec);
%     a = plot(x, y, 'ow');
%     hold on
%     for iConds = 1 : nAnalogConds
%         image(PLOT_SCALE*x(iConds), PLOT_SCALE*y(iConds), flip(imgs{iConds}))
%     end
%     hold off


end
%convertVectorsToModelRDM(lingDataArray,conditions,'iSort',analogSort);
%convertVectorsToModelRDM(analogDataArray,conditions,'iSort',lingSort);
%% Get images loaded in for plotting
% 
% % Images for plot
% imgs = cell(nLingConds, 1);  % load icon images
% for iConds = 1 : nLingConds
%     file = fullfile(imgDir, strcat(lingConditions{iConds},'.png'));
%     img = imread(file);
%     imgs{iConds} = img;    
% end  % for iConds = 1 : nConds

%%
%pathsTsne(lingRdm,imgs,'maxIter',3000,'final_dims',2,'perplexity',50);
%pathsTsne(analogRdm,imgs,'maxIter',3000,'final_dims',2,'perplexity',50);
% 
% tree = linkage(lingRdm,'centroid');
% 
% [maxes,ind] = max(lingDataArray,[],2);
% 
% dirs = repmat(directionOrder,499);
% %labels = cellstr(num2str(mean(lingDataArray,2)));
% 
% for i = 1:length(ind)
%     labels(i) = dirs(ind(i),i);
% end
% 
% 
% leafOrder = optimalleaforder(tree,lingRdm);
% figure; 
% [H,T] = dendrogram(tree,100,'Reorder',leafOrder,'Orientation','left','ColorThreshold','default');
% 

% 
% tree = linkage(analogRdm,'average');
% 
% leafOrder = optimalleaforder(tree,analogRdm);
% figure; 
% H = dendrogram(tree,0,'Reorder',leafOrder,'Orientation','left','ColorThreshold','default','labels',labels);
% 


%%
% For loop - loop through brain data

%rois = {'LHEarlyVis','LHLOC','LHOPA','LHPPA','LHRSC','RHEarlyVis','RHLOC','RHOPA','RHPPA','RHRSC'};
rois = {'EarlyVis','LOC','OPA','PPA','RSC'};

subjs = {'CSI1','CSI2','CSI3'};
%trs = {'TR1','TR2','TR3','TR4','TR5','TR34'};
trs = {'TR2'};

analogCorr = zeros(length(subjs),length(rois));
lingCorr = zeros(length(subjs),length(rois));

perms = 1;

randAnalogCorr = zeros(length(subjs),length(rois),length(perms));
randLingCorr = zeros(length(subjs),length(rois),perms);


for subj = 1:length(subjs)
    % Create slightly different subjID
    stimId = [subjs{subj}(1:3) '0' subjs{subj}(4:end)];
    bold5000stims = readtable(fullfile(brainDir,"stim_lists",strcat(stimId,"_stim_lists.txt")),"ReadVariableNames",false,"Delimiter","");
    % Get the list of conditions from bold5000stims that are in our study
    stimIndex = ismember(bold5000stims,cell2table(analogConditions'));
    brainConditions = table2cell(bold5000stims(stimIndex,'Var1'));
    
    
    
    
    for tr = 1:length(trs)
        % Load in brain data
        subjFmri = load(fullfile(brainDir,subjs{subj},'mat',horzcat(subjs{subj},'_ROIs_',trs{tr},'.mat')));
        % Calculate ROI-specific RDMs
        for roi = 1:length(rois)
            Lroi = ['LH' rois{roi}];
            Rroi = ['RH' rois{roi}];
            brainDataArrayL = subjFmri.(Lroi)(stimIndex,:);
            brainDataArrayL = brainDataArrayL - mean(brainDataArrayL);
            brainDataArrayR = subjFmri.(Rroi)(stimIndex,:);
            brainDataArrayR = brainDataArrayR - mean(brainDataArrayR);
            brainDataArray = [brainDataArrayL brainDataArrayR];

            [brainRdm, brainRdmVec, brainSort] = convertVectorsToModelRDM(brainDataArray,brainConditions);
            
            analogCorr(subj,roi) = corr(brainRdmVec',analogRdmVec');
            lingCorr(subj,roi) = corr(brainRdmVec',lingRdmVec');
            tempPartial = partialcorr([lingRdmVec' brainRdmVec' analogRdmVec']);
            analogPartial(subj,roi) = tempPartial(3,2);
            lingPartial(subj,roi) = tempPartial(1,2);
            for perm = 1:perms
                n=numel(stimIndex);
                ii=randperm(n);
                fakeStimIndex=stimIndex(ii);

                fakeBrainConditions = table2cell(bold5000stims(fakeStimIndex,'Var1'));

                brainDataArrayL = subjFmri.(Lroi)(fakeStimIndex,:);
                brainDataArrayL = brainDataArrayL - mean(brainDataArrayL);
                brainDataArrayR = subjFmri.(Rroi)(fakeStimIndex,:);
                brainDataArrayR = brainDataArrayR - mean(brainDataArrayR);
                brainDataArray = [brainDataArrayL brainDataArrayR];

                [brainRdm, brainRdmVec, brainSort] = convertVectorsToModelRDM(brainDataArray,brainConditions);
            
                randAnalogCorr(subj,roi,perm) = corr(brainRdmVec',analogRdmVec');
                randLingCorr(subj,roi,perm) = corr(brainRdmVec',lingRdmVec');
            
            end
            
            fprintf('%s: Brain-Analog: %0.3f\n',rois{roi},analogCorr(subj,roi));
            fprintf('%s: Brain-Ling: %0.3f\n',rois{roi},lingCorr(subj,roi));

        end
    end
    
end


    close all;

    roiNames = {'EVC','LOC','OPA','PPA','RSC'};

    fakeLing = mean(randLingCorr,3);
    fakeLingStd = std(randLingCorr,[],3);

    fakeAnalog = mean(randAnalogCorr,3);
    fakeAnalogStd = std(randAnalogCorr,[],3);


    f = figure; 
    set(gcf,'Color','w','Position',[560,42,2200,1200]);

    % PATHS PLOT
    subplot(1,2,1);

    % Plot the mean of the paths data
    b = bar(mean(analogCorr),'FaceColor','#4472C4','EdgeColor','k','LineWidth',1.5,'FaceAlpha',.8);
    hold on; 

    % Plot the error bars for the paths data
    e1 = errorbar(mean(analogCorr),std(analogCorr)/sqrt(3),'.k','LineWidth',1.5);

    % Individual points on the plot
    x = repmat(1:5,size(analogCorr,1),1);
    s = scatter(x(:),analogCorr(:)','filled','MarkerFaceColor','#4472C4','jitter','on','jitterAmount',0.15);
    e2 = errorbar(mean(fakeAnalog),mean(fakeAnalogStd)/sqrt(perms*length(subjs)),'.r','LineWidth',1.5);

    % Formatting
    set(gca,'FontSize',32);
    ylim([-.05 .075]);
    yticks(-.05:.025:.075);
    set(gca,'XTickLabel',roiNames,'FontSize',24);
    title(sprintf('Paths, %d bins',length(0:allBins(i):180)-1),'Fontsize',32);
    set(gca,'box','off');
    s.Annotation.LegendInformation.IconDisplayStyle = 'off';
    e1.Annotation.LegendInformation.IconDisplayStyle = 'off';
    legend({'Subject-level data',sprintf('%d Permutations per subject',perms)},'Location','south','EdgeColor','w');
    hold off;

    % CATEGORICAL PLOT
    subplot(1,2,2);

    % Plot the mean of the categorical data
    bar(mean(lingCorr),'FaceColor','#00B050','EdgeColor','k','LineWidth',1.5,'FaceAlpha',.8);
    hold on; 

    % Plot the error bars at the subject level
    errorbar(mean(lingCorr),std(lingCorr)/sqrt(3),'.k','LineWidth',1.5);

    % Plot each point
    x=repmat(1:5,size(lingCorr,1),1);
    scatter(x(:),lingCorr(:)','filled','MarkerFaceColor','#00B050','jitter','on','jitterAmount',0.15);

    % Plot the permutation data as error bars in red
    errorbar(mean(fakeLing),mean(fakeLingStd)/sqrt(perms*length(subjs)),'.r','LineWidth',1.5);

    % Formatting
    set(gca,'FontSize',32);
    ylim([-.05 .075]);
    yticks(-.05:.025:.075);
    set(gca,'XTickLabel',roiNames,'FontSize',24);
    title('Categorical','Fontsize',32);
    set(gca,'box','off');
    hold off;


    % PDF version
    %file = fullfile(figureDir, sprintf('%s_trs_paths_%s_bins.pdf',trs{1},num2str(length(0:allBins(i):180)-1)));
    %exportgraphics(f,file);
%%

f2 = figure; 
set(gcf, 'Color','w'); 
allBehData = [behaviorCorr' behaviorCorr_3bins_Ling'];
b = bar(allBehData,'FaceColor','Flat');

hold on; 
colors = [0 0 0; .5 .5 .5];
for k = 1:size(allBehData,2)
    b(k).CData = colors(k,:);
end

%e2 = errorbar(mean(randBehavior),std(randBehavior),'.r','LineWidth',1.5);
legend({'Categorical bins: 7','Categorical bins: 3'},'Location','south','EdgeColor','w');

% Formatting
set(gca,'FontSize',32);
ylim([-.1 .4]);
yticks(-.1:.05:.4);
ylabel('Correlation');
xlabel('Path bins');
set(gca,'XTickLabel',cellstr(num2str(binSizes(:))),'FontSize',24);
set(gca,'box','off');
hold off;

%%
f = figure; 
set(gcf,'Color','w','Position',[560,42,2200,1200]);

% PATHS PLOT
subplot(1,2,1);

% Plot the mean of the paths data
b = bar(mean(analogPartial),'FaceColor','#4472C4','EdgeColor','k','LineWidth',1.5,'FaceAlpha',.8);
% Formatting
set(gca,'FontSize',32);
ylim([-.05 .075]);
yticks(-.05:.025:.075);
set(gca,'XTickLabel',roiNames,'FontSize',24);
title(sprintf('Paths, %d bins',length(0:allBins(i):180)-1),'Fontsize',32);
set(gca,'box','off');