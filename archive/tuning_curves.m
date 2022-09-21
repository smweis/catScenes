% Run angular_bins.m first
% From here: https://gru.stanford.edu/doku.php/tutorials/channel

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

% figure;
% plot(orientations,channelBasis);
% xlabel('Preferred orientation (deg)');
% ylabel('Ideal channel response (normalized to 1)');

nTrials = 173;

estimatedWeights =  pinv(channelBasis) * binCounts';