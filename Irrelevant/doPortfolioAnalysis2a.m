function doPortfolioAnalysis
% doPortfolionAnalysis attempts different strategies to optimize value (outcomes/cost) in a screening system
% It calls screenSystem with the various strategies

POPMIZ1 = 1;
POPMIZ2 = 2;
POPMIZ3 = 3;
POPMIZ4 = 4;
POPURBAN = 5;
POPHEALTHY = 1;
POPUNHEALTHY = 2;
POPVERYHEALTHY = 3;
POPVERYUNHEALTHY = 4;
POPCOMPLIANT = 1;
POPUNCOMPLIANT = 2;
SCREENOPHTH = 1;
SCREENOPTOM = 2;
SCREENTELE = 3;
SCREENNONE = 4;
UTILFEARBLIND = 1;
UTILNEUTRBLIND = 2;
UTILSTOICBLIND = 3;

%% Obtain strategy list
[~,sheets] = xlsfinfo('Capstone excel V1.xlsx');
nstrategies = size(sheets,2); %Assume strategy 1 is the base strategy


%% Define ICER calculation parameters
NREPEATS = 3; % How many times we repeat the calculations to ensure low variability
cost = zeros(nstrategies,NREPEATS);
qaly = zeros(nstrategies,NREPEATS);
costMean = zeros(nstrategies);
qalyMean = zeros(nstrategies);

for i = 1:nstrategies
    [num,txt,raw] = xlsread('Capstone excel V1.xlsx');
    nregions = size(num,1); % How many regions we have.
    for j = 1:NREPEATS
        costQaly = screenSystemV2a(nregions,txt(2:nregions+1,1),num(:,1),num(:,2),num(:,3),num(:,4),num(:,5),num(:,6),num(:,7));
        fprintf('Strategy %d %.1f %g %g %g \n',i,costQaly);
        cost(i,j) = costQaly(1);
        qaly(i,j) = costQaly(2);
        nUniBlind(i,j) = costQaly(3);
        nBlind(i,j) = costQaly(4);
    end
end

meanCost = mean(cost,2);
meanQaly = mean(qaly,2);
meanUniBlind = mean(nUniBlind,2);
meanBlind = mean(nBlind,2);

for i = 2:nstrategies % Compare each strategy to strategy 1
    icer = (meanCost(i) - meanCost(1)) / (meanQaly(i) - meanQaly(1));
    changeUniBlind = meanUniBlind(i) - meanUniBlind(1);
    changeBlind = meanBlind(i) - meanBlind(1);
    fprintf('ICER Strategy %d vs Strategy 1 %.2f %.2f %.2f\n',i,icer,changeUniBlind,changeBlind);
end

%
