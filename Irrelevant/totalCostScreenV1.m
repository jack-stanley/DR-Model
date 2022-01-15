
ScreenSystem(1,['Montreal'],[1000],[1],[1],[1],[1],[1],[1])

function totalCostQALY = ScreenSystem(npops,pnames,psizes,plocs,phealths,pcomps,pdmrisks,pscreens,putils)
%function screenSystem simulates the screening for an entire health system
%  ARGUMENTS
%   npops - Number of populations within the health system
%   pnames - Vector of names of each population e.g. Montreal, North Quebec
%   psizes - Vector of size of each population
%   plocs - Vector of location type of each population e.g. POPURBAN, POPRURAL, POPDISP
%   phealths - Vector of health type of each population e.g. POPHEALTHY POPUNHEALTHY
%   pcomps - Vector of adherence/compliance type of each population, e.g. POPCOMPLIANT, POPUNCOMPLIANT
%   pdmrisks - Vector of overall diabetes risk of each population, as prevalence per 100,000
%   pscreens - Vector of screening method to be used for each population e.g. SCREENOPHTH SCREENOPTOM SCREENTELE SCREENNONE
%   NOTE that for now, if more than one screening method is used in each
%   population, then create multiple populations, each with a different
%   screening method, and give names such as MontrealSC1, MontrealSC2, etc
%   putils - Vector of which utilities should be used for each population, e.g. POPFEARBLIND

% RETURNS
%  2-part vector of costs and QALYs, both per person

% USES FOLLOWING DEFINED VARIABLES 
%   NSTAGES - number of stages in diabetic retinopathy
%   utilPercept - a matrix of the perception of utilities for each stage, for each population
%   ageDistrib - a matrix of age distributions for different population types
%   costTypeScreen - a vector of costs per screen for different population locations
%   costTypeFA - a vector of costs per fluorescein angiogram for different population locations
%   costTypeFocal - a vector of costs per focal laser for different population locations
%   costTypeScatter - a vector of costs per scatter laser for different population locations
%   utilPercept - a vector of utilities for different population healths, for each stage of disease
%   screenSens - a vector of the sensitivity for each of the different  screening methods
%   screenSpec - a vector of the speficity for each of the different screening methods
%   initScreenInt - vector of the initial screening interval in years for each screening method
%   diabetesByAge - a vector of diabetes prevalence by age in a baseline population
%   startingAges - a vector of proportion of population at each age
%       THIS SHOULD EVENTUALLY BE RELATED TO POPHEALTH
%	stage2ByAge - a vector of proportion of patients at stage 2 at each age
%   mortByAge - a vector of risk of dying at each age
%   mortMult - Mortality multipliers, where DM alone is 1.8 x chance of dying at each stage, multiplied
%   by the chance of dying just from diabetes alone
%   tpm - transition probability matrix (4 vectors, for no laser, focal, scatter, or both)
%       NOTE THAT EVENTUALLY WE MAY CHANGE THE TRANSITIONS BASED ON HEALTH STATUS
%   utilSD - standard deviation of utilities
%   

util = [1 1 1 1 1 1 .54 0]; % The mean utility values associated with each of the 8 stages
utilSD = [0 0 0 0 0 0 .17 0]; % The SD of the utility values by stage
tpm_nophotocoag = [
    0.869	0.131         0         0         0         0         0 0;
    0       0.863	0.1310         0         0    0.0060         0  0;
    0       0       0.8630    0.1310         0    0.0060         0  0;
    0         0         0    0.8900    0.0800    0.0300         0   0;
    0         0         0         0    0.9100         0    0.0900   0;
    0         0         0         0         0    0.9500    0.0500   0;
    0         0         0         0         0         0    1.0000   0;
    0   0   0   0   0   0   0   1];
tpm_scatter = [
    0.869	0.131         0         0         0         0         0 0;
    0       0.863	0.1310         0         0    0.0060         0  0;
    0       0       0.8630    0.1310         0    0.0060         0  0;
    0         0         0    0.8900    0.0800    0.0300         0   0;
    0         0         0         0    0.9800         0    0.0200   0;
    0         0         0         0         0    0.9500    0.0500   0;
    0         0         0         0         0         0    1.0000   0;
    0   0   0   0   0   0   0   1];
tpm_focal = [
    0.869	0.131         0         0         0         0         0 0;
    0       0.863	0.1310         0         0    0.0060         0  0;
    0       0       0.8630    0.1310         0    0.0060         0  0;
    0         0         0    0.8900    0.0800    0.0300         0   0;
    0         0         0         0    0.9100         0    0.0900   0;
    0         0         0         0         0    0.9700    0.0300   0;
    0         0         0         0         0         0    1.0000   0;
    0   0   0   0   0   0   0   1];
tpm_scatterfocal = [
    0.869	0.131         0         0         0         0         0 0;
    0       0.863	0.1310         0         0    0.0060         0  0;
    0       0       0.8630    0.1310         0    0.0060         0  0;
    0         0         0    0.8900    0.0800    0.0300         0   0;
    0         0         0         0    0.9800         0    0.0200   0;
    0         0         0         0         0    0.9700    0.0300   0;
    0         0         0         0         0         0    1.0000   0;
    0   0   0   0   0   0   0   1];
tpm = tpm_nophotocoag; 
tpm(:,:,2) = tpm_scatter;
tpm(:,:,3) = tpm_focal;
tpm(:,:,4) = tpm_scatterfocal;
costsPerProc = [53 163 1490 1740]; %Costs of screen, FA, focal laser, scatter laser
sensSpec =[0.905 0.05 0 0 0.003 0.21/5 0 0;
    0.22 0.731 0 0 0.02/3 0.21/5 0 0;
    0.22 0 0.731 0 0.02/3 0.21/5 0 0;
    0.22 0 0 0.731 0.02/3 0.21/5 0 0;
    0.02 0.01 0.1 0.1 0.1 0.21/5 0 0;
    0.18/5 0.18/5 0.18/5 0.18/5 0.18/5 0.82 0 0;
    0 0 0 0 0 0 1 0;
    0 0 0 0 0 0 0 1];
dmByAge = [1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 21.8 21.8 21.8 21.8 21.8 21.8 21.8 21.8 21.8 21.8 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20]/100;
%chance that someone at that age has diabetes
startingAges = [0.013 0.013 0.013 0.013 0.0132 0.0132 0.0132 0.0132 0.0132 0.0134 0.0134 0.0134 0.0134 0.0134 0.0142 0.0142 0.0142 0.0142 0.0142 0.014 0.014 0.014 0.014 0.014 0.0136 0.0136 0.0136 0.0136 0.0136 0.013 0.013 0.013 0.013 0.013 0.013 0.013 0.013 0.013 0.013 0.0136 0.0136 0.0136 0.0136 0.0136 0.0148 0.0148 0.0148 0.0148 0.0148 0.0144 0.0144 0.0144 0.0144 0.0144 0.0128 0.0128 0.0128 0.0128 0.0128 0.0108 0.0108 0.0108 0.0108 0.0108 0.008 0.008 0.008 0.008 0.008 0.006 0.006 0.006 0.006 0.006 0.0048 0.0048 0.0048 0.0048 0.0048 0.0038 0.0038 0.0038 0.0038 0.0038 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005]/100;
% portion of population at that age (e.g. 0.013 of population between 0-1
% years old)
dmAgesInPopulation = dmByAge .* startingAges;
%For the whole population, chance that someone is that age and has diabetes
ages = (randsample(length(dmAgesInPopulation(40:120)),npts,true,dmAgesInPopulation(40:120))') + 39;
%vector npts long giving random ages using probability established in
%previous line (only people 40 through 120 years old?)
MortByAge = [26.5 26.5 26.5 26.5 ...
12.9 12.9 12.9 12.9 12.9 12.9 12.9 12.9 12.9 12.9 ...
67.7 67.7 67.7 67.7 67.7 67.7 67.7 67.7 67.7 67.7 ...
102.9 102.9 102.9 102.9 102.9 102.9 102.9 102.9 102.9 102.9 ...
170.5 170.5 170.5 170.5 170.5 170.5 170.5 170.5 170.5 170.5 ...
407.1 407.1 407.1 407.1 407.1 407.1 407.1 407.1 407.1 407.1 ...
851.9 851.9 851.9 851.9 851.9 851.9 851.9 851.9 851.9 851.9 ...
1875.1 1875.1 1875.1 1875.1 1875.1 1875.1 1875.1 1875.1 1875.1 1875.1 ...
4790.2 4790.2 4790.2 4790.2 4790.2 4790.2 4790.2 4790.2 4790.2 4790.2 ...
13934.3 13934.3 13934.3 13934.3 13934.3 13934.3 13934.3 13934.3 13934.3 13934.3 ...
13934.3 13934.3 13934.3 13934.3 13934.3 13934.3 13934.3 13934.3 13934.3 13934.3 ...
13934.3 13934.3 13934.3 13934.3 13934.3 13934.3 13934.3 13934.3 13934.3 13934.3 ...
100000 100000 100000 100000 100000 100000 100000 100000 100000 100000]/100000;
% chance of dying at each age
mortMult = [1 1.23 1.23 1.49 1.76 1.76 2.34 1000] * 1.8; %xMortality multipliers, where DM alone
% is 1.8 x chance of dying at each stage, multiplied by the chance of dying just from diabetes alone

SIMSIZE = 1000; % How many subjects within a simulation
totalCostQALY = [0 0];
totalPop = 0;
for pop = 1:npops % For each population we will perform a simulation
    popLoc = plocs(pop);
    popHealth = phealths(pop);
    popComp = pcomps(pop);
    popDMrisk = pdmrisks(pop);
    popScreen = pscreens(pop);
    costsPerProc = [costTypeScreen(popLoc) costTypeFA(popLoc) costTypeFocal(popLoc) costTypeScatter(popLoc);
    sensSpec = [screenSens(popScreen) screenSpec(popScreen)];
    popUtil = putils(pop);
    utilSD = zeros(NSTAGES);    % For now, we assume no variability in utilities TO BE CHANGED

    costQALY = doMarkov4(SIMSIZE,utilPercept(popUtil),utilSD,costsPerProc,diabetesByAge(popHealth),startingAges(popHealth),stage2ByAge(popHealth),MortByAge(popHealth),tsensSpec,initScreenInt(popScreen));
    totalCostQALY = totalCostQALY + costQALY; % Keep a running sum of the cost and QALY in the vector
    totalPop = totalPop + psizes(pop); % Keep a running sum of the total population
end





