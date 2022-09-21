iNeuron = 1;
orientations = 0:179;
k = 10;
% loop over each neuron tuning function
for orientPreference = 0:2:179  
  % compute the neural response as a Von Mises function
  %Note the 2 here which makes it so that our 0 - 180 orientation
  % space gets mapped to all 360 degrees
  neuralResponse(iNeuron,:) = exp(k*cos(2*pi*(orientations-orientPreference)/180));
  % normalize to a height of 1
  neuralResponse(iNeuron,:) = neuralResponse(iNeuron,:) / max(neuralResponse(iNeuron,:));
  % update counter
  iNeuron = iNeuron + 1;
end

nNeurons = size(neuralResponse,1);
nVoxels = 250;
neuronToVoxelWeights = rand(nNeurons,nVoxels);

nStimuli = 8;
% evenly space stimuli
stimuli = 0:180/(nStimuli):179;
% number of repeats
nRepeats = 20;
stimuli = repmat(stimuli,1,nRepeats);

stimuli = round(stimuli(:))+1;


nTrials = nStimuli * nRepeats;
for iTrial = 1:nTrials
  % get the neural response to this stimulus, by indexing the correct column of the neuralResponse matrix
  thisNeuralResponse = neuralResponse(:,stimuli(iTrial));
  % multiply this by the neuronToVoxelWeights to get the voxel response on this trial. Note that you need
  % to get the matrix dimensions right, so transpose is needed on thisNeuralResponse
  voxelResponse(iTrial,:) = thisNeuralResponse' * neuronToVoxelWeights;
end

noiseStandardDeviation = 0.05;
% normalize response 
voxelResponse = voxelResponse / mean(voxelResponse(:));
% add gaussian noise
voxelResponse = voxelResponse + noiseStandardDeviation*randn(size(voxelResponse));

nChannels = 8;
exponent = 7;
orientations = 0:179;
prefOrientation = 0:180/nChannels:179;
% loop over each channel
for iChannel = 1:nChannels
  % get sinusoid. Note the 2 here which makes it so that our 0 - 180 orientation
  % space gets mapped to all 360 degrees
  thisChannelBasis =  cos(2*pi*(orientations-prefOrientation(iChannel))/180);
  % rectify
  thisChannelBasis(thisChannelBasis<0) = 0;
  % raise to exponent
  thisChannelBasis = thisChannelBasis.^exponent;
  % keep in matrix
  channelBasis(:,iChannel) = thisChannelBasis;
end

for iTrial = 1:nTrials
  channelResponse(iTrial,:) = channelBasis(stimuli(iTrial),:);
end

estimatedWeights =  pinv(channelResponse) * voxelResponse;

















































































































































































































