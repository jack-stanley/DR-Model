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
POPCOMPLIANT = 1;
POPUNCOMPLIANT = 2;
SCREENOPHTH = 1;
SCREENOPTOM = 2;
SCREENTELE = 3;
SCREENNONE = 4;
UTILFEARBLIND = 1;
UTILNEUTRBLIND = 2;
UTILSTOICBLIND = 3;
for i=1:10
    screenSystemV1e(1,['Montreal'],[1000000],[POPMIZ1],[POPHEALTHY],[POPCOMPLIANT],[5000],[SCREENOPHTH],[UTILNEUTRBLIND])
end