
function totalCostQALYBlind = screenSystemV2k(nregions,rnames,rcensuses,rpops,rcomps,rhealths,...
    rDMrisks,rscreens,rutils,rSDutils,rSDdemos,rSDscreens,rSDhealths,rResources)
%function screenSystem simulates the screening for an entire health system
%It is called by a function that compares different screening strategies and assignments 
%  ARGUMENTS
%   nregions - Number of regions within the health system
%   rnames - Vector of names of each regions e.g. Montreal, North Quebec
%   'MONTREAL', 'XXXX', 'STJAMES BAY' ***UNUSED
%   rcensuses - Vector of census of each region
%   rpops - Vector of population type of each regions e.g. POPURBAN = 1; POPRURAL = 2
%   rcomps - Vector of adherence/compliance type of each regions, e.g. POPCOMPLIANT, POPUNCOMPLIANT
%   rhealths - Vector of health type of each regions e.g. POPHEALTHY, POPUNHEALTHY
%   rDMrisks - Vector of overall diabetes risk of each regions, as proportion
%   rscreens - Vector of screening method to be used for each regions e.g. SCREENOPHTH SCREENOPTOM SCREENTELE SCREENNONE
%   NOTE that for now, if more than one screening method is used in each
%   regions, then create multiple regions, each with a different
%   screening method, and give names such as MontrealSC1, MontrealSC2, etc
%   rutils - Vector of which utilities should be used for each regions, e.g. POPFEARBLIND
%   rSDutils - Vector of standard deviations to be used for utilities
%   rSDdemos - Vector of standard deviations to be used for demographic variables
%   rSDscreens - Vector of standard deviations to be used for screening variables
%   rSDhealths - Vector of standard deviations to be used for health variables
%   rResources - Array of resources available for that region

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
%   initScreenInt - vector of the initial screening interval in years for each screening method
%   diabetesByAge - a vector of diabetes prevalence by age in a baseline population
%   startingAges - a vector of proportion of population at each age
%       THIS SHOULD EVENTUALLY BE RELATED TO POPHEALTH
%	stage2ByAge - a vector of proportion of patients at stage 2 at each age
%   mortByAge - a vector of risk of dying at each age
%   mortMult - Mortality multipliers, where DM alone is 1.8 x chance of dying at each stage, multiplied
%       by the chance of dying just from diabetes alone
%   tpm - transition probability matrix CHANGES BASED ON HEALTH STATUS
%       AND PRIOR LASER
%   utilSD - standard deviation of utilities
%   

%% First make sure each argument has the same number of regions
if ~all([size(rnames,1),size(rcensuses,1),size(rpops,1),size(rhealths,1),size(rcomps,1),size(rDMrisks,1),size(rscreens,1),size(rutils,1),size(rSDutils,1),size(rSDdemos,1),size(rSDscreens,1),size(rSDhealths,1)] == nregions)
    error('screenSystem called with arguments not equalling nregions %d\n',nregions);
end

%% Define population constants
POPURBAN = 1;
POPRURAL = 2;
POPCOMPLIANTHIGH = 1;
POPCOMPLIANTMED = 2;
POPCOMPLIANTLOW = 3;
COMPLIANCERATES = [.8 .65 .4]; % Likelihood that they will show up for a screen, etc.

%% Define screening constants
SCREENOPHTH = 1;
SCREENOPTOM = 2;
SCREENTELE = 3;
SCREENNONE = 4;
SCREENGP = 5;

%% Define utility values based on region type
UTILFEARBLIND = 1;
UTILNEUTRBLIND = 2;
UTILSTOICBLIND = 3;
UTILCURVE = [1 1 1 1 1 .68 .34 0; 1 1 1 1 1 .78 .54 0; 1 1 1 1 1 .88 .74 0]; % DME utility from Ann Intern Med. 2014 Jan 7; 160(1): 18?29, using VA 1-3

%% Define costs
% For now, assume only URBAN can do treatments and FA
% Each row in COSTSCREENBYPOP is a different population. Each column is the
% different screening methods.
% Later simply add base cost to travel cost
% Assume $805 travel cost for any procedure involving an ophthalmologist
% Evaluation of a mobile diabetes care telemedicine clinic serving Aboriginal communities in northern British Columbia, Canada PMID: 15736635
COSTTRANSPORT = 805;
COSTSCREENBYPOP = [107 75 102 0 0; 107+COSTTRANSPORT 75 102 0 0]; 

% Each row in COSTPROCBYPOP is a different population. Each column is a
% different procedure. Note that costs of screening is in COSTSCREENBYPOP
% First column is COST_FA
% Second column is COST_FOCAL
% Third column is COST_SCATTER
% From: The cost-effectiveness of grid laser photocoagulation for the treatment of diabetic macular edema:
% results of a patient-based cost-utility analysis
COSTPROCBYPOP = [138 733 733; 138+COSTTRANSPORT 733+COSTTRANSPORT 733+COSTTRANSPORT]; 

%% Define screening data
% Screening sensitivities/specificities as a matrix
% Given the screen type, the row is the true stage and the columns are the chance of each measured stage
% Sensitivity and specificity of photography and direct ophthalmoscopy in screening for sight threatening eye disease: 
% the Liverpool diabetic eye study
% Assume that sight threatening DR is PDR or ME. If STDR missed, assigned to
% stage 4 DOESN'T MAKE A DIFFERENCE NOW, BUT MIGHT LATER IF WE ASSIGN
% SCREENING INTERVALS BASED ON MEASUERD STAGE. The only thing we care about
% are stages PDR and ME

% Assume gold standard is ophthalmologists doing slit-lamp biomicroscopy,
% Actually only true for retina specialists, but will simplify for now.
screenAcc_screenOphth = [1 0 0 0 0 0 0 0;
    0 1 0 0 0 0 0 0;
    0 0 1 0 0 0 0 0;
    0 0 0 1 0 0 0 0;
    0 0 0 0 1 0 0 0;
    0 0 0 0 0 1 0 0;
    0 0 0 0 0 0 1 0;
    0 0 0 0 0 0 0 1];
%FOR OPTOMETRISTS AND TELE: A comparative evaluation of digital imaging, retinal photography and
% optometrist examination in screening for diabetic retinopathy.
% Note that these were specially trained optometrists, but will simplify
% for now
screenAcc_screenOptom =...
[0.804 0.06 0.06 0.06 0 0.016 0 0;
0.25 0.634 0.05 0.05 0 0.016 0 0;
0.25 0.05 0.584 0.05 0.05 0.016 0 0;
0.25 0.05 0.05 0.584 0.05 0.016 0 0;
0.25 0.05 0.05 0.05 0.584 0.016 0 0;
0.34 0.05 0.05 0.05 0.05 0.46 0 0;
0 0 0 0 0 0 1 0;
0 0 0 0 0 0 0 1];
screenAcc_screenTele = ...% Assume very good 2 field screening
[0.858 0.036666667 0.036666667 0.036666667 0 0.032 0 0;
0.11 0.818 0.02 0.02 0 0.032 0 0;
0.11 0.02 0.798 0.02 0.02 0.032 0 0;
0.11 0.02 0.02 0.798 0.02 0.032 0 0;
0.11 0.02 0.02 0.02 0.798 0.032 0 0;
0.09 0.02 0.02 0.02 0.02 0.83 0 0;
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
%Diagnostic accuracy of direct ophthalmoscopy for detection of diabetic retinopathy
    % using fundus photographs as a reference standard 
screenAcc_screenGP =... 
[0.5327 0.095766667 0.095766667 0.095766667 0 0.18 0 0;
0.4433 0.1767 0.1 0.1 0 0.18 0 0;
0.4433 0.1 0.0767 0.1 0.1 0.18 0 0;
0.4433 0.1 0.1 0.0767 0.1 0.18 0 0;
0.4433 0.1 0.1 0.1 0.0767 0.18 0 0;
0.5 0.1 0.1 0.1 0.1 0.1 0 0;
0 0 0 0 0 0 1 0;
0 0 0 0 0 0 0 1]; %always assume healthy until blind or dead with no screening

screenAcc(:,:,1) = screenAcc_screenOphth./sum(screenAcc_screenOphth,2); % Normalize to sum to 1
screenAcc(:,:,2) = screenAcc_screenOptom./sum(screenAcc_screenOptom,2);
screenAcc(:,:,3) = screenAcc_screenTele./sum(screenAcc_screenTele,2);
screenAcc(:,:,4) = screenAcc_screenNone./sum(screenAcc_screenNone,2);
screenAcc(:,:,5) = screenAcc_screenGP./sum(screenAcc_screenGP,2);

% Initial screening intervals for each screen type
initScreenInt = [1 1 2 1 5];

% Which screen types generate a referral to an ophthalmologist, based on
% stage. We will assume that macular edema and blindness are detectable
% without even being examined. 0 means no referral, 1 means refer.

screenRefer = [0 0 0 0 0 0 0 0; 0 0 1 1 1 1 1 0; 0 0 0 1 1 1 1 0; 0 0 0 0 0 1 1 0; 0 1 1 1 1 1 1 0];

%% Define epidemiology
% Probability that someone at a given age has diabetes
% From Rates of Diagnosed Diabetes per 100 Civilian, Non-Institutionalized Population, by Age, United States, 1980�2014 
% https://www.cdc.gov/diabetes/statistics/prev/national/figbyage.htm
DMByAge = [1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 ...
    1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 ...
    1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 1.6 12.2 12.2 12.2 12.2 12.2 12.2 ...
    12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 12.2 ...
    21.8 21.8 21.8 21.8 21.8 21.8 21.8 21.8 21.8 21.8 20 20 20 20 20 20 20 ...    
    20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 ...
    20 20 20 20 20 20 20 20 20 20 20 20 20 20 20]/100;

% Proportion of population at a given age (e.g. 0.013 of population between 0-1
% years old)
% From Institut de la statistique du Qu�bec, Direction des statistiques sociod�mographiques and Statistics Canada, 
% Demography Division 2015 http://www.stat.gouv.qc.ca/statistiques/profils/profil07/societe/demographie/demo_gen/pop_age07_an.htm

% Note that for the whole population, chance that someone is that age and has diabetes
% is the product of DMByAge and startAges
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
    0.000001 0.000001 0.000001 0.000001 0 0 0 0 0 0];
startAges = startAges / sum(startAges); % Normalize to add to 1


% Mortality by age - from Centers for Disease Control and Prevention, National Center for Health Statistics.
% Compressed Mortality File" 1999-2015 on CDC WONDER Online Database, released December 2016.
% Data are from the Compressed Mortality File 1999-2015 Series 20 No. 2U, 2016, as compiled from data 
% provided by the 57 vital statistics jurisdictions through the Vital Statistics Cooperative Program. 
% Accessed at http://wonder.cdc.gov/cmf-icd10.html on Mar 1, 2017 3:48:54 PM

MortByAge = [28.9 28.9 28.9 28.9 13.5 13.5 13.5 13.5 13.5 16.6 16.6 16.6 16.6 16.6 57.4 57.4 57.4 57.4 57.4 91.4 ...
    91.4 91.4 91.4 91.4 106 106 106 106 106 106 106 106 106 106 187.3 187.3 187.3 187.3 187.3 187.3 187.3 187.3 ...
    187.3 187.3 418.3 418.3 418.3 418.3 418.3 418.3 418.3 418.3 418.3 418.3 891.7 891.7 891.7 891.7 891.7 891.7 ...
    891.7 891.7 891.7 891.7 2018 2018 2018 2018 2018 2018 2018 2018 2018 2018 5070.3 5070.3 5070.3 5070.3 5070.3 ...
    5070.3 5070.3 5070.3 5070.3 5070.3 5070.3 5070.3 5070.3 5070.3 5070.3 5070.3 5070.3 5070.3 5070.3 5070.3 5070.3 ...
    5070.3 5070.3 5070.3 5070.3 5070.3 5070.3 5070.3 5070.3 5070.3 5070.3 5070.3 5070.3 5070.3 5070.3 5070.3 50000 ...
    50000 50000 50000 50000 50000 50000 60000 70000 100000]/100000;

%% Define morbidity based on health status (POPHEALTHY, ETC)- tied to HbA1c levels
POPHEALTHY = 1; % This corresponds to urban
POPMILDUNHEALTHY = 2; % This corresponds to rural
POPMODHEALTHY = 3; % No data
POPVERYUNHEALTHY = 4; % No data
HEALTHMORBIDITY = [1 1.25 1.5 2]; % Health status affects the transition probabilities used in doMarkov
                                    % Note that a value higher than 5
                                    % messes up the tpm based on how
                                    % maketpm works

%% Define resource parameters - this should match what is in other files
RESOURCESCREEN = 1;
RESOURCELASER = 2;
RESOURCEOPHTH = 3; % Detection of retinopathy by a non-ophthalmologist will need referral to ophthalmologist
    % Note that the ophthalmologist is probably going to be in a different
    % regions, yet we don't really keep track properly of that.
                                 
%% Initialize
totalCostQALYBlind = [0 0 0 0]; % Cost QALY Unilateral blind Bilateral blind
totalCensus = 0;

% Here we have code so that all regions have the same variability
% effects for this particular iteration of screenSystem. These are used in
% the call to randomize

randSDutil = randn();
randSDdemo = randn();
% randSDscreen = randn(); Note that the screening methods don't have the
% same variability
randSDhealth = randn();

 %% Perform simulations for each region and sum utilities and costs
parfor reg = 1:nregions % For each region we will perform a simulation
    regName = rnames{reg}; %Note that rnames is an array of cells. We do this because of how Matlab handles strings
    regCensus = rcensuses(reg);
    if regCensus == 0   % Don't analyze a region (subregion) that has no people in it
            continue;
    end
    regPop = rpops(reg); %makes it easier to read later on
    regUtil = UTILCURVE(rutils(reg),:);
    regScreen = rscreens(reg); % Who does the screening
    regHealth = rhealths(reg);
    regMorbidity = HEALTHMORBIDITY(regHealth);
    costsPerProc = COSTPROCBYPOP(regPop,:);
    costsPerScreen = COSTSCREENBYPOP(regPop,regScreen);
    regComp = rcomps(reg);
    regCompRate = COMPLIANCERATES(regComp);
    regDMrisk = rDMrisks(reg);
    regResources = rResources(reg,:);

%% Use SD variables to build in variability, but each region has the same change
    regSDutil = rSDutils(reg);
    regSDdemo = rSDdemos(reg);
    regSDscreen = rSDscreens(reg);
    regSDhealth = rSDhealths(reg);
    regUtilSD = [0 0 0 0 0 0 regSDutil 0]; 
    regDMByAge = DMByAge * (regDMrisk / sum(DMByAge .* startAges)); % We first adjust age-adjusted prevalence to target prevalence
    regDMByAge = randomizeV1b(regDMByAge,regSDdemo,0,1,-0.5,10,randSDdemo); % We then allow the age-adjusted prevalence to go down by 50%, up by any amount
    regMortByAge = randomizeV1b(MortByAge,regSDdemo,0,1,-0.75,3,randSDdemo);   
    regStartAges = randomizeV1b(startAges,regSDdemo,0,1,-0.75,3,randSDdemo);
    regStartAges = regStartAges / sum(regStartAges);
    regScreenAcc = randomizeV1b(screenAcc(:,:,regScreen),regSDscreen,0,10,-.75,10,false);
    regScreenAcc = regScreenAcc ./ sum(regScreenAcc,2);
    regMorbidity = randomizeV1b(regMorbidity,regSDhealth,.3,5,-1,10,randSDhealth);
    regCompRate = randomizeV1b(regCompRate,regSDhealth,.1,1,-.75,3,randSDhealth);
    
    npatients = ceil(regCensus * sum(regDMByAge .* regStartAges)); % We run the simulation on the calculated number of subjects with diabetes
    costQALYBlind = doMarkov5k(npatients,regUtil,regUtilSD,costsPerProc,costsPerScreen,regDMByAge.*regStartAges,...
        regMortByAge,regScreenAcc,initScreenInt(regScreen),screenRefer(regScreen,:),regMorbidity,regCompRate,regResources);
    % Note that eventually each region's health type should have its own
    % prevalence of DM by age and mortality by age
    totalCostQALYBlind = totalCostQALYBlind + [sum(costQALYBlind(1,:)) * npatients sum(costQALYBlind(2,:)) * npatients sum(costQALYBlind(3,:)) sum(costQALYBlind(4,:))]; 
        % Running sum of  cost, QALY, and number blind in the vector
    totalCensus = totalCensus + npatients; % Keep a running sum of all region censuses of diabetic patients
 end
 
 totalCostQALYBlind = [totalCostQALYBlind(1:2) / totalCensus totalCostQALYBlind(3:4) * 100000 / totalCensus]; 
 % Cost and QALY are per diabetic patient; number blind is per 100,000
 







