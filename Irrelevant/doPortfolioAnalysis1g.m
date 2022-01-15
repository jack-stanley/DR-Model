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
for i = 1:3;
    fprintf('OPHTH %.1f %.1f \n',screenSystemV1g(1,['Montreal'],[1000000],[POPMIZ1],[POPHEALTHY],[POPCOMPLIANT],[5000],[SCREENOPHTH],[UTILNEUTRBLIND])/1000);
end
for i = 1:3;
    fprintf('OPTOM %.1f %.1f \n',screenSystemV1g(1,['Montreal'],[1000000],[POPMIZ1],[POPHEALTHY],[POPCOMPLIANT],[5000],[SCREENOPTOM],[UTILNEUTRBLIND])/1000);
end


