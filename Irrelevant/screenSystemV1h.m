
% ScreenSystem(1,['Montreal'],[1000],[1],[1],[1],[1],[1],[1]) 

function totalCostQALY = screenSystemV1i(nregions,rnames,rcensuses,rpops,rhealths,rcomps,rDMrisks,rscreens,rutils)
%function screenSystem simulates the screening for an entire health system
%It is called by a function that compares different screening strategies and assignments 
%  ARGUMENTS
%   nregions - Number of regions within the health system
%   rnames - Vector of names of each regions e.g. Montreal, North Quebec
%   'MONTREAL', 'XXXX', 'STJAMES BAY' ***UNUSED
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
%   tpm - transition probability matrix CHANGES BASED ON HEALTH STATUS
%   AND PRIOR LASER
%   utilSD - standard deviation of utilities
%   

%% First make sure each argument has the same number of regions
if ~all([size(rnames,2),size(rcensuses,2),size(rpops,2),size(rhealths,2),size(rcomps,2),size(rDMrisks,2),size(rscreens,2),size(rutils,2)] == nregions)
    error('screenSystem called with arguments not equalling nregions %d\n',nregions);
end
%% Define population constants
POPMIZ1 = 1;
POPMIZ2 = 2;
POPMIZ3 = 3;
POPMIZ4 = 4;
POPURBAN = 5;
POPCOMPLIANT = 1;
POPUNCOMPLIANT = 2;
%% Define screening constants
SCREENOPHTH = 1;
SCREENOPTOM = 2;
SCREENTELE = 3;
SCREENNONE = 4;

%% Define utility values based on region type
UTILFEARBLIND = 1;
UTILNEUTRBLIND = 2;
UTILSTOICBLIND = 3;
UTILCURVE = [1 1 1 1 1 1 .44 0; 1 1 1 1 1 1 .54 0; 1 1 1 1 1 1 .64 0];

%% Define costs
% For now, assume only URBAN, MIZ1, MIZ2, and MIZ3 can do treatments and FA
% Each row in COSTSCREENBYPOP is a different population. Each column is the
% different screening methods.
% Later simply add base cost to travel cost
COSTSCREENBYPOP = [100 75 75 0; 100 75 75 0; 100 75 75 0; 2100 1075 75 0; 100 75 75 0]; 

% Each row in COSTPROCBYPOP is a different population. Each column is a
% different procedure. Note that costs of screening is in COSTSCREENBYPOP
% First column is COST_FA
% Second column is COST_FOCAL
% Third column is COST_SCATTER
COSTPROCBYPOP = [200 500 500; 200 500 500; 200 500 500; 2200 2500 2500; 200 500 500]; 

%% Define screening sensitivities/specificities as a matrix
%Given the screen type, the row is the true stage and the columns are the chance of each measured stage
screenAcc_screenOphth = ...% Assume perfect screening
    [1 0 0 0 0 0 0 0;
    0 1 0 0 0 0 0 0;
    0 0 1 0 0 0 0 0;
    0 0 0 1 0 0 0 0;
    0 0 0 0 1 0 0 0;
    0 0 0 0 0 1 0 0;
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
DMByAge = [1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 ...
    1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 ...
    1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 12.2 12.2 12.2 12.2 12.2 12.2 ...
    12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 ...
    21.8 21.8 21.8 21.8 21.8 21.8 21.8 21.8 21.8 21.8 20 20 20 20 20 20 20 ...    
    20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 ...
    20 20 20 20 20 20 20 20 20 20 20 20 20 20 20]/100;
%chance that someone at that age has diabetes
startAges = [0.013 0.013 0.013 0.013 0.0132 0.0132 0.0132 0.0132 0.0132 ...
    0.0134 0.0134 0.0134 0.0134 0.0134 0.0142 0.0142 0.0142 0.0142 0.0142 ...
    0.014 0.014 0.014 0.014 0.014 0.0136 0.0136 0.0136 0.0136 0.0136 0.013 ...
    0.013 0.013 0.013 0.013 0.013 0.013 0.013 0.013 0.013 0.0136 0.0136 ...
    0.0136 0.0136 0.0136 0.0148 0.0148 0.0148 0.0148 0.0148 0.0144 0.0144 ...
    0.0144 0.0144 0.0144 0.0128 0.0128 0.0128 0.0128 0.0128 0.0108 0.0108 ...
    0.0108 0.0108 0.0108 0.008 0.008 0.008 0.008 0.008 0.006 0.006 0.006 ...
    0.006 0.006 0.0048 0.0048 0.0048 0.0048 0.0048 0.0038 0.0038 0.0038 ...
    0.0038 0.0038 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 ...
    0.0001 0.0001 0.0001 0.0001 0.0001 0.0001 0.00005 0.00005 0.00005 0.00005 ...
    0.00001 0.00001 0.00001 0.00001 0.00001 0.00001 0.00001 0.000005 0.000005 0.000001 ...
    0.000001 0.000001 0.000001 0.000001 0 0 0 0 0 0]/100;
% proportion of population at that age (e.g. 0.013 of population between 0-1
% years old)
%For the whole population, chance that someone is that age and has diabetes
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

%% Define morbidity based on health status (POPHEALTHY, ETC)
POPHEALTHY = 1;
POPUNHEALTHY = 2;
POPVERYHEALTHY = 3;
POPVERYUNHEALTHY = 4;
HEALTHMORBIDITY = [1 3 0.333 5]; % Health status affects the transition probabilities used in doMarkov
                                    % Note that a value higher than 5
                                    % messes up the tpm based on how
                                    % maketpm works

%% Initialize
totalCostQALY = [0 0];
totalCensus = 0;

 %% Perform simulations for each region and sum utilities and costs
 for reg = 1:nregions % For each region we will perform a simulation
    regName = rnames{reg}; %Note that rnames is an array of cells. We do this because of how Matlab handles strings
    regPop = rpops(reg); %makes it easier to read later on
    regUtil = UTILCURVE(rutils(reg),:);
    regUtilSD = [0 0 0 0 0 0 .17 0]; % For now, we assume the same SD of the utility values by stage
    regScreen = rscreens(reg);
    regHealth = rhealths(reg);
    regMorbidity = HEALTHMORBIDITY(regHealth);
    costsPerProc = COSTPROCBYPOP(regPop,:);
    costsPerScreen = COSTSCREENBYPOP(regPop,regScreen);
    regComp = rcomps(reg); % ***Not currently used***
    regDMrisk = rDMrisks(reg);
 
    costQALY = doMarkov4h(regUtil,regUtilSD,costsPerProc,costsPerScreen,DMByAge.*startAges,...
        MortByAge,screenAcc(:,:,regScreen),initScreenInt(regScreen),regMorbidity);
    totalCostQALY = totalCostQALY + [sum(costQALY(1,:)) sum(costQALY(2,:))] * rcensuses(reg); % Keep a running sum of the cost and QALY in the vector
    totalCensus = totalCensus + rcensuses(reg); % Keep a running sum of all region censuses
 end
totalCostQALY = totalCostQALY / totalCensus;
% Need to factor in DMrisks - prevalence of DM in the population





