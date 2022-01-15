function doPortfolioAnalysis
% doPortfolionAnalysis attempts different strategies to optimize value (outcomes/cost) in a screening system
% It calls screenSystem with the various strategies

%% Randomize the same way each time for testing
rng(1)

%% Obtain strategy list
filename = 'Capstone excel V2j14.xlsx'
[~,sheets] = xlsfinfo(filename);
nstrategies = size(sheets,2) - 1; % The last sheet is ignored. Assume strategy 1 is the base strategy
if nstrategies < 1
    error('No strategies in file %s\n',filename);
end

%% Define ICER calculation parameters
NREPEATS = 100;       % How many times we repeat the calculations to ensure low variability
cost = zeros(nstrategies,NREPEATS);
qaly = zeros(nstrategies,NREPEATS);
nUniBlind = zeros(nstrategies,NREPEATS);
nBlind = zeros(nstrategies,NREPEATS);
costMean = zeros(nstrategies);
qalyMean = zeros(nstrategies);
results = zeros(nstrategies * NREPEATS,5);
resultLine = 0; % The line of the array that will eventually go to Excel


for i = 1:nstrategies % Note that we never read the last sheet, which allows us to use it for producing the other sheets
    [num,txt,raw] = xlsread(filename,i);
    nregions = size(num,1); % How many regions we have.
    for j = 1:NREPEATS
        costQaly = screenSystemV2k(nregions,txt(2:nregions+1,1),num(:,1),num(:,2),num(:,3),num(:,4),num(:,5),...
            num(:,6),num(:,7),num(:,8),num(:,9),num(:,10),num(:,11),[num(:,12) num(:,13) num(:,14)]);
%        fprintf('Strategy %d Cost: %.0f  QALY: %.3f  Unilat blind/100,000: %.1f  Bilat blind/100,000: %.1f \n',i,costQaly);
        resultLine = resultLine + 1;
        results(resultLine,1) = i;
        cost(i,j) = costQaly(1);
        results(resultLine,2) = costQaly(1);
        qaly(i,j) = costQaly(2);
        results(resultLine,3) = costQaly(2);
        nUniBlind(i,j) = costQaly(3);
        results(resultLine,4) = costQaly(3);
        nBlind(i,j) = costQaly(4);
        results(resultLine,5) = costQaly(4);
    end
end
xlswrite(strcat('Portfolio results ',filename,' ',strrep(datestr(clock),':','-'),'.xlsx'),results)
% meanCost = mean(cost,2);
% meanQaly = mean(qaly,2);
% meanUniBlind = mean(nUniBlind,2);
% meanBlind = mean(nBlind,2);
% stdCost = std(cost,2);
% stdQaly = std(qaly,2);
% stdUniBlind = std(nUniBlind,2);
% stdBlind = std(nBlind,2);

for basestrat = 1:nstrategies
    for i = basestrat:nstrategies % Compare each strategy to the others
        if i == basestrat
            continue % No need to check a strategy to itself
        end
        for j = 1:NREPEATS
            icer(j) = (cost(i,j) - mean(cost(basestrat,:))) / (qaly(i,j) - mean(qaly(basestrat,:)));
            changeUniBlind(j) = nUniBlind(i,j) - nUniBlind(basestrat,j);
            changeBlind(j) = nBlind(i,j) - nBlind(basestrat,j);
        end
        fprintf('ICERs: ');
        fprintf('%.0f ',icer);
        fprintf('\n');
        fprintf('ICER Strategy %d vs %d: ICER: %.0f ± %.0f (SEM %.0f)  Unilat blind: %.1f ± %.1f (SEM %.1f) Bilat blind: %.1f ± %.1f  (SEM %.1f)\n',...
            i,basestrat,mean(icer),std(icer),std(icer)/sqrt(NREPEATS),mean(changeUniBlind),...
            std(changeUniBlind),std(changeUniBlind)/sqrt(NREPEATS),mean(changeBlind),std(changeBlind),std(changeBlind)/sqrt(NREPEATS));
    end
end
evalICER(mean(cost,2)',mean(qaly,2)');

