
%   ageDistrib - a matrix of age distributions for different population types
%NECESSARY FOR AGE-STANDARDIZED RATES? LEAVE FOR NOW. 



%utilSD = [0 0 0 0 0 0 .17 0]; % The SD of the utility values by stage. Add
%utility variability in later
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
cost_nophotocoag = [0 0 0]; 
cost_scatter = [1163 2163 163];
cost_focal = [2490 3490 1490];
cost_scatterfocal = [2740 3740 1740];
% Use matrix costsPerProc as alternative to multiple vectors for cost? Eg:
%costsPerProc = [0 0 0; 1163 2163 163; 2740 3740 1740];
screencost_screenOpth = [100 200 400]
screencost_screenOptom = [75 150 200]
screencost_screenTele = [150 200 150]
screencost_screenNone = [0 0 0]
screencost = screencost_screenOpth
%screencost(:,:,2) = screencost_screenOptom 
%screencost(:,:,3) = screencost_screenTele
%screencost(:,:,4) = screencost_screenNone
%Define screening sensitivities/specificities as a matrix
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

STAGE_HEALTH = 1;
STAGE_NPDR1 = 2;
STAGE_NPDR2 = 3;
STAGE_NPDR3 = 4;
STAGE_PDR = 5;
STAGE_ME = 6;
STAGE_BLIND = 7;
STAGE_DEATH = 8;
FUPSCREENINT = 1;
NSTAGES = 8;
screeningInt = ones(1,npts) * initScreenInt; % screening interval in years ALL BELOW TO SIMSIZE COPIED FROM DOMARKOV
lastScreened = zeros(1,npts); % when patient was last screened 
dmByAge = [1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 21.8 21.8 21.8 21.8 21.8 21.8 21.8 21.8 21.8 21.8 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20]/100;
%if we use age-standardized rates, we don't need a matrix specifying age
%distributions in each population
startingAges = [0.013 0.013 0.013 0.013 0.0132 0.0132 0.0132 0.0132 0.0132 0.0134 0.0134 0.0134 0.0134 0.0134 0.0142 0.0142 0.0142 0.0142 0.0142 0.014 0.014 0.014 0.014 0.014 0.0136 0.0136 0.0136 0.0136 0.0136 0.013 0.013 0.013 0.013 0.013 0.013 0.013 0.013 0.013 0.013 0.0136 0.0136 0.0136 0.0136 0.0136 0.0148 0.0148 0.0148 0.0148 0.0148 0.0144 0.0144 0.0144 0.0144 0.0144 0.0128 0.0128 0.0128 0.0128 0.0128 0.0108 0.0108 0.0108 0.0108 0.0108 0.008 0.008 0.008 0.008 0.008 0.006 0.006 0.006 0.006 0.006 0.0048 0.0048 0.0048 0.0048 0.0048 0.0038 0.0038 0.0038 0.0038 0.0038 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005 0.0005]/100;
dmAgesInregionulation = dmByAge .* startingAges;
ages = (randsample(length(dmAgesInregionulation(40:120)),npts,true,dmAgesInregionulation(40:120))') + 39;
stage2ByAge = [0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.130 0.136 0.136 0.136 0.136 0.136 0.136 0.136 0.136 0.136 0.136 0.135 0.135 0.135 0.135 0.135 0.135 0.135 0.135 0.135 0.135 0.150 0.150 0.150 0.150 0.150 0.150 0.150 0.150 0.150 0.150  0.150 0.150 0.150 0.150 0.150 0.150 0.150 0.150 0.150 0.150  0.150 0.150 0.150 0.150 0.150 0.150 0.150 0.150 0.150 0.150  0.150 0.150 0.150 0.150 0.150 0.150 0.150 0.150 0.150 0.150  0.150 0.150 0.150 0.150 0.150 0.150 0.150 0.150 0.150 0.150 0.150];
trueStage = zeros(2,npts);
trueStage(1,:) = (stage2ByAge(ages) > rand(1,npts)) + 1;
trueStage(2,:) = (stage2ByAge(ages) > rand(1,npts)) + 1;
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
mortMult = [1 1.23 1.23 1.49 1.76 1.76 2.34 1000] * 1.8; %Mortality multipliers, where DM alone is 1.8
SIMSIZE = 100; % How many subjects within a simulation
totalCostQALY = [0 0];
totalCensus = 0; 
for region = 1:nregions % For each population we will perform a simulation
    regionLoc = plocs(region); %makes it easier to read later on
    regionHealth = phealths(region);
    regionComp = pcomps(region);
    regionDMrisk = pdmrisks(region);
    popScreen = pscreens(pop); 
    costsPerProc = [costTypeScreen(popLoc) costTypeFA(popLoc) costTypeFocal(popLoc) costTypeScatter(popLoc);
    screenAcc = [screenSens(popScreen) screenSpec(popScreen)];
    popUtil = putils(pop); %start with all the same utility
    %utilSD = zeros(NSTAGES);    % For now, we assume no variability in utilities TO CHANGE

    costQALY = doMarkov(SIMSIZE,popUtil,costsPerProc,diabetesByAge,startingAges,stage2ByAge,MortByAge,screenAcc,initScreenInt(popScreen)); %Is the "t" before screenAcc a mistake?
    totalCostQALY = totalCostQALY + costQALY; % Keep a running sum of the cost and QALY in the vector
    totalCensus = totalCensus + rcensus(pop); % Keep a running sum of the total population
end
