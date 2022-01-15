
% ScreenSystem(1,['Montreal'],[1000],[1],[1],[1],[1],[1],[1]) % This is what you would input in the command window before running?

function totalCostQALY = screenSystemv1d(nregions,rnames,rcensuses,rpops,rhealths,rcomps,rDMrisks,rscreens,rutils)
%function screenSystem simulates the screening for an entire health system
%It is called by a function that compares different screening strategies and assignments 
%  ARGUMENTS
%   nregions - Number of regions within the health system
%   rnames - Vector of names of each regions e.g. Montreal, North Quebec
%   'MONTREAL', 'XXXX', 'STJAMES BAY'
%   rcensuses - Vector of census of each region
%   rpops - Vector of population type of each regions e.g. MIZ1 = 1; POPURBAN = 5; POPRURAL, POPDISP
%   rhealths - Vector of health type of each regions e.g. POPHEALTHY, POPUNHEALTHY
%   rcomps - Vector of adherence/compliance type of each regions, e.g. POPCOMPLIANT, POPUNCOMPLIANT
%   rDMrisks - Vector of overall diabetes risk of each regions, as prevalence per 100,000
%   rscreens - Vector of screening method to be used for each regions e.g. SCREENOPHTH SCREENOPTOM SCREENTELE SCREENNONE
%   NOTE that for now, if more than one screening method is used in each
%   regions, then create multiple regions, each with a different
%   screening method, and give names such as MontrealSC1, MontrealSC2, etc
%   rutils - Vector of which utilities should be used for each regions, e.g. POPFEARBLIND

% %% RETURNS
%  2-part vector of costs and QALYs, both per person

% USES FOLLOWING DEFINED VARIABLES a lot of these are already in diabetes
% or doMarkov
%   NSTAGES - number of stages in diabetic retinopathy
%   utilPercept - a matrix of the perception of utilities for each stage, for each population
%   ageDistrib - a matrix of age distributions for different population types
%   costTypeScreen - a vector of costs per screen for different population
%   locations 
%   costTypeFA - a vector of costs per fluorescein angiogram for different population locations
%   costTypeFocal - a vector of costs per focal laser for different population locations
%   costTypeScatter - a vector of costs per scatter laser for different population locations
%   utilPercept - a vector of utilities for different population healths, for each stage of disease
%NOT USED   screenSens - a vector of the sensitivity for each of the different  screening methods
%NOT USED   screenSpec - a vector of the speficity for each of the different screening methods
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

%% Define global variables (MAKE GLOBAL)
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

%% Define utility values based on region type
UTILCURVE = [1 1 1 1 1 1 .44 0; 1 1 1 1 1 1 .54 0; 1 1 1 1 1 1 .64 0];

%% Define transition probabilities, depending on previous treatment(s)
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

%% Define costs
% For now, assume only URBAN, MIZ1, MIZ2, and MIZ3 can do treatments and FA

% Each row in COSTSCREENBYPOP is a different population. Each column is the
% different screening methods.
% Later simply add base cost to travel cost
COSTSCREENBYPOP = [100 75 75 0; 100 75 75 0; 100 75 75 0; 2100 1075 75 0]; 

% Each row in COSTPROCBYPOP is a different population. Each column is a
% different procedure. Note that costs of screening is in COSTSCREENBYPOP
% First column is COST_FA
% Second column is COST_FOCAL
% Third column is COST_SCATTER

COSTPROCBYPOP = [0 200 500 500; 0 200 500 500; 0 200 500 500; 0 2200 2500 2500; 0 200 500 500]; 

%% Define screening sensitivities/specificities as a matrix
%Given the screen type, the column is the true stage and the row is the measured stage
screenAcc_screenOpth = [0.905 0.05 0 0 0.003 0.21/5 0 0;
    0.22 0.731 0 0 0.02/3 0.21/5 0 0;
    0.22 0 0.731 0 0.02/3 0.21/5 0 0;
    0.22 0 0 0.731 0.02/3 0.21/5 0 0;
    0.02 0.01 0.1 0.1 0.1 0.21/5 0 0;
    0.18/5 0.18/5 0.18/5 0.18/5 0.18/5 0.82 0 0;
    0 0 0 0 0 0 1 0;
    0 0 0 0 0 0 0 1];
screenAcc_screenOptom = [0.90 0.055 0 0 0.003 0.21/5 0 0;
    0.25 0.681 0 0 0.02/3 0.21/5 0 0;
    0.25 0 0.681 0 0.02/3 0.21/5 0 0;
    0.25 0 0 0.681 0.02/3 0.21/5 0 0;
    0.02 0.01 0.1 0.1 0.1 0.21/5 0 0;
    0.18/5 0.18/5 0.18/5 0.18/5 0.18/5 0.82 0 0;
    0 0 0 0 0 0 1 0;
    0 0 0 0 0 0 0 1];
screenAcc_screenTele = [0.85 0.06 0 0 0.003 0.21/5 0 0;
    0.30 0.631 0 0 0.02/3 0.21/5 0 0;
    0.30 0 0.631 0 0.02/3 0.21/5 0 0;
    0.30 0 0 0.631 0.02/3 0.21/5 0 0;
    0.02 0.01 0.1 0.1 0.1 0.21/5 0 0;
    0.18/5 0.18/5 0.18/5 0.18/5 0.18/5 0.82 0 0;
    0 0 0 0 0 0 1 0;
    0 0 0 0 0 0 0 1];
screenAcc_screenNone = [1 0 0 0 0 0 0 0; 
    1 0 0 0 0 0 0 0;
    1 0 0 0 0 0 0 0;
    1 0 0 0 0 0 0 0;
    1 0 0 0 0 0 0 0;
    1 0 0 0 0 0 0 0;
    0 0 0 0 0 0 1 0;
    0 0 0 0 0 0 0 1]; %always assume healthy until blind or dead with no screening
screenAcc(:,:,1) = screenAcc_screenOphth;
screenAcc(:,:,2) = screenAcc_screenOptom;
screenAcc(:,:,3) = screenAcc_screenTele;
screenAcc(:,:,4) = screenAcc_screenNone;

%Initial screening intervals
initScreenInt = [1 1 2 1];

%% Define epidemiology
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
%*** mortMult not used!!!
% is 1.8 x chance of dying at each stage, multiplied by the chance of dying just from diabetes alone

%% Define other simulation parameters
SIMSIZE = 100; % How many subjects within a simulation

%% Initialize
totalCostQALY = [0 0];
totalRegions = 0;

 %% Perform simulations for each region and sum utilities and costs
 for reg = 1:nregions % For each regions we will perform a simulation
    regPop = rpops(reg); %makes it easier to read later on
    regUtil = UTILCURVE(rutils(reg));
    regUtilSD = [0 0 0 0 0 0 .17 0]; % For now, we assume the same SD of the utility values by stage
    regScreen = rscreens(reg);
    costsPerProc = COSTPROCBYPOP(regPop);
    costsPerScreen = COSTSCREENBYPOP(regPop,regScreen);
    regComp = rcomps(reg); % ***Not currently used***
    regDMrisk = rDMrisks(reg);
 
    costQALY = doMarkov(SIMSIZE,regUtil,regUtilSD,costsPerProc,costsPerScreen,diabetesByAge(regHealth),
        startingAges(regHealth),stage2ByAge(regHealth),MortByAge(regHealth),
        screenAcc(:,:,regScreen),initScreenInt(regScreen));
    totalCostQALY = totalCostQALY + costQALY; % Keep a running sum of the cost and QALY in the vector
    totalRegions = totalRegions + rcensuses(reg); % Keep a running sum of all regions
end





