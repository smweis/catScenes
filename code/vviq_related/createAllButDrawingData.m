%% ANALOG DATA

dataDir = "\\exasmb.rc.ufl.edu\blue\stevenweisberg\share\catscenes\data";
drawingDir = "\\exasmb.rc.ufl.edu\blue\stevenweisberg\share\catscenes\data\participantDrawingData\";
drawingFiles = dir(strcat(drawingDir, '*drawingData_*'));

%% Load in everybody's drawing data EXCEPT one participant; average it; then save it out. 
allAnalogData = nan(10000,500,length(drawingFiles));
% Loop through all participant files
for i = 1:length(drawingFiles)    
    analogData = readtable(fullfile(drawingDir,drawingFiles(i).name),'PreserveVariableNames',true);
    analogData = analogData(:,2:end);
    analogData = analogData(:,sort(analogData.Properties.VariableNames));
    allAnalogData(:,:,i) = table2array(analogData);
end

% Loop through everyone else's drawing data, and save out the mean.
for i = 1:length(drawingFiles)
    
    pID = drawingFiles(i).name; pID = pID(13:17);

    allButParticipantData = allAnalogData;
    allButParticipantData(:,:,i) = [];
    
    allButParticipantData = nanmean(allButParticipantData,3);
    writematrix(single(allButParticipantData),strcat(drawingDir,'allBut_',pID,'.csv'));
end
