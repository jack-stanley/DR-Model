function costAndQaly = doMarkov5c(npatients,util,utilSD,costsPerProc,costsPerScreen,dmInPopByAge,MortByAge,screenAcc,initScreenInt,morbidityIndex,complianceRate) 
% takes following inputs
% npatients - note that if the npatients is very high, we do the simulation on
%     MAXSIMSIZE and scale everything
% utility by stage, 
% standard deviation of utility by stage, 
% cost per procedure or treatment,
% cost per screen
% proportion of each age with diabetes in the population
% mortality by age
% screening accuracy matrix
% initial screening interval
% morbidity index, which drives the transitions between retinopathy stages
% compliance rate - likelihood of being at appointments

%% Simulation parameters
MAXSIMSIZE = 100000; % How many subject within a simulation
simsize = min(npatients,MAXSIMSIZE);
% simsize = 1000;

%% Stage of disease parameters
NSTAGES = 8; %total number of stages
STAGE_HEALTH = 1;
STAGE_NPDR1 = 2;
STAGE_NPDR2 = 3;
STAGE_NPDR3 = 4;
STAGE_PDR = 5;
STAGE_ME = 6;
STAGE_BLIND = 7;
STAGE_DEATH = 8; % labels each stage of disease

MINAGE = 18; % At the moment we are only doing adults. This could be extended to kids
MAXAGE = 120;
%MAXYEARS = MAXAGE - MINAGE + 1; % Maximum years from entry into simulation to death
SIMYEARS = 30; %Length of the simulation

%% Initialize utilities
unilatVsBilatBlind = 0.25;  % Disutility of unilateral blindness as a percentage of the disutility of bilateral blindness

%% Initialize cost variables
cost_fa = costsPerProc(1); % cost of fluorescein angiogram testing
cost_focal = costsPerProc(2); % cost of focal laser treatment
cost_scatter = costsPerProc(3); % cost of scatter treatment

%% Initialize morbidities
MORBIDITYSD = 0; %Amount of variability in the morbidity index

    
%% Initialize epidemiology variables
mortMult = [1 1.23 1.23 1.49 1.76 1.76 2.34 1000] * 1.8; %xMortality multipliers by stage (reference: xxx)

%% Initialize screening variables
FUPSCREENINT = 1; %screening interval - NOTE THAT THIS MUST BE CHANGED TO A VARIABLE, TO ADAPT TO STAGE OF DISEASE

%% Initial stages of disease (reference: xxx)
startStages = [0.498 0.141 0.141 0.141 0.027 0.027 0 0];
    % Stage 7 is 0.27 in literature, but we will only study people who start out seeing and alive
startStages = startStages / sum(startStages); % Normalize to add to 1

qalys = 0;
costs = 0;
nUniBlind = 0;
nBlind = 0;

%% Debugging variables
%ageWhenBlind = zeros(NUMEYES,simsize);

%% MAIN LOOP
for pt = 1:simsize  % For all patients
    ptAge = (randsample(length(dmInPopByAge(MINAGE:MAXAGE)),1,true,dmInPopByAge(MINAGE:MAXAGE))') + MINAGE - 1;
        % Age chosen based on prevalence of diabetes in the population
    ptMorbidity = rand() * MORBIDITYSD + morbidityIndex;
    tpmR = maketpm(ptMorbidity,false,false);
    tpmL = maketpm(ptMorbidity,false,false);
    trueStageR = randsample8(STAGE_HEALTH,startStages);
    trueStageL = randsample8(STAGE_HEALTH,startStages);
    hadScatterR = 0; % 1 if had scatter photocoagulation in each eye 
    hadFocalR = 0; % 1 if had focal photocoagulation in each eye 
    hadScatterL = 0; % 1 if had scatter photocoagulation in each eye 
    hadFocalL = 0; % 1 if had focal photocoagulation in each eye 
    years_seeing = 0;
    ptUtils = util + randn(1,8) .* utilSD; %sets up matrix of utilities of each stage
    ptUtils = max(min(ptUtils,1),0); %Utility cannot be less than 0 or greater than 1
    utilUnilatBlind = 1 - ptUtils(STAGE_BLIND) * unilatVsBilatBlind; 
    screeningInt = initScreenInt; % screening interval in years 
        %NOTE THAT ONCE RETINOPATHY IS DETECTED, THIS BECOMES FUPSCREENINT,
        %WHICH SHOULD BE STAGE-DEPENDENT
    lastScreened = -999; % year that patient was last screened -999 means not screened yet

    for year = 1:SIMYEARS   %for every year
        if trueStageR == STAGE_DEATH % Don't do calculations on deceased patients. Note we keep track of death in right eye stage
            error('Reached STAGE_DEATH AT TOP OF LOOP')
            break
        end
        if rand() < max(MortByAge(ptAge) * mortMult(trueStageR),MortByAge(ptAge) * mortMult(trueStageL))
            trueStageR = STAGE_DEATH; % Use stage of both eyes to figure out increased mortality
            break % Exit the for loop for each year and drop down to processing of blindness
        end
        if (year >= lastScreened + screeningInt) && (rand() < complianceRate)
                % if they are due for a screening and likely to show up
            lastScreened = year; % keep track that they were screened this year
            costs = costs + costsPerScreen;
            % All of the following is if this is a screening year
            % RIGHT EYE
            examStageR = randsample8(trueStageR,screenAcc(trueStageR,:)); % Apparent vs true stage of disease X
            if (examStageR == STAGE_PDR) && (hadScatterR == 0)
                hadScatterR = 1; %if p has PDR and has not had scatter for that eye, assign them to scatter
                tpmR = maketpm(ptMorbidity,true,hadFocalR); % Change tpm to include scatter
                costs = costs + cost_scatter; % Cost of that pt now cost of scatter treatment
            elseif (examStageR == STAGE_ME) && (hadFocalR == 0)
                hadFocalR = 1; % if p has macular edema in that eye and has not had focal treatment, assign them to it
                tpmR = maketpm(ptMorbidity,hadScatterR,true);% Change tpm to include focal
                costs = costs + cost_focal + cost_fa; % cost of p now includes cost of focal laser treatment
            end

            % LEFT EYE
            examStageL = randsample8(trueStageL,screenAcc(trueStageL,:)); % Apparent vs true stage of disease X
            if (examStageL == STAGE_PDR) && (hadScatterL == 0)
                hadScatterL = 1; %if p has PDR and has not had scatter for that eye, assign them to scatter
                tpmL = maketpm(ptMorbidity,true,hadFocalL); % Change tpm to include scatter
                costs = costs + cost_scatter; % Cost of that pt now cost of scatter treatment
            elseif (examStageL == STAGE_ME) && (hadFocalL == 0)
                hadFocalL = 1; % if p has macular edema in that eye and has not had focal treatment, assign them to it
                tpmL = maketpm(ptMorbidity,hadScatterL,true);% Change tpm to include focal
                costs = costs + cost_focal + cost_fa; % cost of p now includes cost of focal laser treatment
            end
            
            worstEye = max(examStageR,examStageL);
            bestEye = min(examStageR,examStageL); % Establish best and worst eyes
            if worstEye > STAGE_HEALTH
                if bestEye < STAGE_BLIND
                    screeningInt = FUPSCREENINT; % When there is perceived retinopathy in either eye and not bilaterally blind, screen fixed basis X
                else
                    screeningInt = 999; % Stop screening if bilaterally blindX
                                        %Sets interval to essentailly never screen again (999 years)
                end
            end
        end
% Above is performed only if patient is screened

% Below is performed every year, even if not screened
% Next lines are where the progression in the Markov chain occurs
%         prevStageR = trueStageR; % Only needed for figuring out when patient went blind
        trueStageR = randsample8(trueStageR,tpmR(trueStageR,:));
%             if trueStageR == STAGE_BLIND && prevStageR ~= STAGE_BLIND %This year patient became blind in R eye
%                 blindR = year;
%             end
%            prevStageL = trueStageL; % Needed for figuring out when patient went blind
         trueStageL = randsample8(trueStageL,tpmL(trueStageL,:));
%             if trueStageL == STAGE_BLIND && prevStageL ~= STAGE_BLIND %This year patient became blind
%                 ageWhenBlind = year;
%             end
        trueBestEye = min(trueStageR,trueStageL); % Establish stage of true best eye X
        trueWorstEye = max(trueStageR,trueStageL); % Establish stage of true worst eye X
        if trueBestEye < STAGE_BLIND
            if trueWorstEye == STAGE_BLIND % If one blind eye, then utility is 0.85 (Clinical Ophthalmology 2014:8 1703?1709)
                years_seeing = years_seeing + utilUnilatBlind;
             else
                years_seeing = years_seeing + 1; %X Keep track of true non-blind years
            end
        end
%        ptUtil_over_time(pt,year) = ptUtils(pt,trueBestEye);
% Utitity dependent mostly on best eye, but with a weighting of the worst eye
        qalys = qalys + (1 - unilatVsBilatBlind) * ptUtils(trueBestEye) + unilatVsBilatBlind * ptUtils(trueWorstEye); % qalys dependent mostly on best eye only
        ptAge = ptAge + 1; % If not deceased, make one year older X
    end
% Above done every year.
% The "break" statement when the patient dies in the code above will drop
% down to here by exiting the for loop for each year

% At the end of the simulation for the patient, decide whether they are
% unilaterally or bilaterally blind.
    if trueStageR == STAGE_BLIND
        if trueStageL == STAGE_BLIND
            nBlind = nBlind + 1;
        else
            nUniBlind = nUniBlind + 1;
        end
    else
        if trueStageL == STAGE_BLIND
            nUniBlind = nUniBlind + 1;
        end
    end
end
% Above done for each patient X

% fprintf('Uni %d Blind %d simsize %d\n',nUniBlind, nBlind, simsize);

costAndQaly = [costs / simsize; qalys / simsize; nUniBlind * 100000 / simsize / SIMYEARS; nBlind * 100000 / simsize / SIMYEARS];
% Blindness is per 100,000 per year
end
