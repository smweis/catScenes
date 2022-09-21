dataDir = "\\exasmb.rc.ufl.edu\blue\stevenweisberg\share\catscenes\data";
drawingDir = "\\exasmb.rc.ufl.edu\blue\stevenweisberg\share\catscenes\data\participantDrawingData\";
drawingFiles = dir(strcat(drawingDir, '*drawingData_*'));
allButDrawingFiles = dir(strcat(drawingDir, '*allBut_*'));


allCorrelations = [];

%% Create all participant histograms
for i = 1:length(drawingFiles)
    
    pID = drawingFiles(i).name; pID = pID(13:17);
    
    % Import the data
    participantdrawingData = readtable(fullfile(drawingDir,drawingFiles(i).name),'PreserveVariableNames',true);
    participantdrawingData = participantdrawingData(:,2:end);
    participantdrawingData = participantdrawingData(:,sort(participantdrawingData.Properties.VariableNames));
    participantdrawingDataArray = table2array(participantdrawingData);

    % Names of variables = condition names
    analogConditions = participantdrawingData.Properties.VariableNames;
    nAnalogConds = length(analogConditions);


    % Import the all but that participant data
    allButDrawingData = readtable(fullfile(drawingDir,allButDrawingFiles(i).name),'PreserveVariableNames',true);
    allButDrawingData = allButDrawingData(:,sort(allButDrawingData.Properties.VariableNames));
    allButDrawingDataArray = table2array(allButDrawingData);

    
    allBins = [24];
    for bin = 1:length(allBins)
        binSizes(bin) = length(0:allBins(bin):180)-1;
    end
    
    
    % Preprocess analogData 
    for j = 1:length(allBins)  
        
        participantAnalogDataArray = [];
        
        participantAnalogDataArray = preprocessAnalogData(participantdrawingDataArray,analogConditions,...
            'savefig',false,'theta_bins',0:allBins(j):180,'outputDir',...,
            strcat(dataDir,'\individualAnalogData'),'pID',pID,'saveOutput',true);
        
        allButParticipantAnalogDataArray = [];
        
        allButParticipantAnalogDataArray = preprocessAnalogData(allButDrawingDataArray,analogConditions,...
            'savefig',false,'theta_bins',0:allBins(j):180);
        
        participantCorrelations = [];
        for image = 1:size(participantAnalogDataArray,1)
            if ~isnan(allButParticipantAnalogDataArray(image,1))
                participantCorrelations(image) = corr(allButParticipantAnalogDataArray(image,:)',participantAnalogDataArray(image,:)');
            end
        end
        
        
        
    end
    
    pID
    
    allCorrelations(i,1) = str2double(pID);
    allCorrelations(i,2) = nanmean(participantCorrelations);
    allCorrelations(i,3) = nnz(~isnan(participantCorrelations));
    nanmean(participantCorrelations);
    
end

writematrix(allCorrelations,strcat(drawingDir,'../','drawingCorrelations_',num2str(allBins),'.csv'));
