function pathsTsne(modelRdm,imgs,varargin)

%% Parse input
p = inputParser;

% Required input
p.addRequired('modelRdm',@ismatrix);
p.addRequired('imgs',@iscell);
% Optional params
p.addParameter('maxIter',1000,@isnumeric);
p.addParameter('final_dims',2,@isnumeric);
p.addParameter('perplexity',30,@isnumeric);
p.addParameter('savefig',false,@islogical);
p.addParameter('outputDir','.',@ischar);
p.addParameter('fileName','test',@ischar);

% Parse and check the parameters
p.parse( modelRdm, imgs, varargin{:});

nConds = length(modelRdm);

% tSNE parameters
options = statset('MaxIter',p.Results.maxIter);


% tSNE
D = modelRdm;
D = D / max(D(:)); % normalize distances
embedding = tsne(D, 'Perplexity',p.Results.perplexity, 'NumDimensions', p.Results.final_dims,'Options',options);

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

if p.Results.savefig
    fileName = strcat('tSNE_',p.Results.fileName,'.pdf');
    file = fullfile(outputDir, fileName);
    export_fig(file, '-transparent');
end
