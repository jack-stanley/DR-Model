function doPortfolioAnalysis
% doPortfolionAnalysis attempts different strategies to optimize value (outcomes/cost) in a screening system
% It calls screenSystem with the various strategies

%% Obtain strategy list
filename = 'Capstone excel V2c.xlsx'
[~,sheets] = xlsfinfo(filename);
nstrategies = size(sheets,2); %Assume strategy 1 is the base strategy


%% Define ICER calculation parameters
NREPEATS = 3; % How many times we repeat the calculations to ensure low variability
cost = zeros(nstrategies,NREPEATS);
qaly = zeros(nstrategies,NREPEATS);
costMean = zeros(nstrategies);
qalyMean = zeros(nstrategies);

for i = 1:nstrategies
    [num,txt,raw] = xlsread(filename,i);
    nregions = size(num,1); % How many regions we have.
    for j = 1:NREPEATS
        costQaly = screenSystemV2e(nregions,txt(2:nregions+1,1),num(:,1),num(:,2),num(:,3),num(:,4),num(:,5),...
            num(:,6),num(:,7),num(:,8),num(:,9),num(:,10),num(:,11),[num(:,12) num(:,13) num(:,14)]);
        fprintf('Strategy %d Cost: %.0f  QALY: %.3f  Unilat blind: %.1f  Bilat blind: %.1f \n',i,costQaly);
        cost(i,j) = costQaly(1);
        qaly(i,j) = costQaly(2);
        nUniBlind(i,j) = costQaly(3);
        nBlind(i,j) = costQaly(4);
    end
end

% meanCost = mean(cost,2);
% meanQaly = mean(qaly,2);
% meanUniBlind = mean(nUniBlind,2);
% meanBlind = mean(nBlind,2);
% stdCost = std(cost,2);
% stdQaly = std(qaly,2);
% stdUniBlind = std(nUniBlind,2);
% stdBlind = std(nBlind,2);

for i = 2:nstrategies % Compare each strategy to strategy 1
    for j = 1:NREPEATS
        icer(j) = (cost(i,j) - mean(cost(1,:))) / (qaly(i,j) - mean(qaly(1,:)));
        changeUniBlind(j) = nUniBlind(i,j) - nUniBlind(1,j);
        changeBlind(j) = nBlind(i,j) - nBlind(1,j);
    end
    fprintf('ICERs: ');
    fprintf('%.0f ',icer);
    fprintf('\n');
    fprintf('ICER Strategy %d vs Strategy 1:    ICER: %.0f ± %.0f  Unilat blind: %.1f ± %.1f Bilat blind: %.1f ± %.1f\n',i,mean(icer),std(icer),mean(changeUniBlind),std(changeUniBlind),mean(changeBlind),std(changeBlind));
end

%
