function costAndQaly = doMarkov5k(npatients,util,utilSD,costsPerProc,costsPerScreen,dmInPopByAge,MortByAge,...
    screenAcc,initScreenInt,screenRefer,morbidityIndex,complianceRate,resourcesPerYear) 
% takes following inputs
% npatients - note that if the npatients is very high, we do the simulation on
%     MAXSIMSIZE and scale everything down
% utility by stage, 
% standard deviation of utility by stage, 
% cost per procedure or treatment,
% cost per screen
% proportion of each age with diabetes in the population
% mortality by age
% screening accuracy matrix
% initial screening interval
% when to refer to ophthalmologist based on stage
% morbidity index, which drives the transitions between retinopathy stages
% compliance rate - likelihood of being at appointments
% resources provided each year

%% Simulation parameters
MAXSIMSIZE = 1000; % Maximum subjects within a simulation. Below that we use the actual number of subjects
simsize = min(npatients,MAXSIMSIZE);

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
SIMYEARS = 20; %Length of the simulation. NOTE WE ADD NEW PATIENTS AS OTHERS DIE

%% Initialize utilities
unilatVsBilatBlind = 0.25;  % Disutility of unilateral blindness as a percentage of the disutility of bilateral blindness

%% Initialize cost variables
cost_fa = costsPerProc(1); % cost of fluorescein angiogram testing
cost_focal = costsPerProc(2); % cost of focal laser treatment
cost_scatter = costsPerProc(3); % cost of scatter treatment

%% Initialize morbidities
MORBIDITYSD = 0; %Amount of variability in the morbidity index

    
%% Initialize epidemiology variables
mortMult = [1 1.23 1.23 1.49 1.76 1.76 2.34 1000] * 1.8; %xMortality multipliers by stage (reference: Cost-Utility Analysis 
% of Screening Intervals for Diabetic Retinopathy in Patients With Type 2 Diabetes Mellitus)

%% Initialize screening variables
FUPSCREENINT = 1; %screening interval - NOTE THAT THIS MUST BE CHANGED TO A VARIABLE, TO ADAPT TO STAGE OF DISEASE

%% Initialize resources
% Note that the resources provided need to be scaled down if we limit our simulation to MAXSIMSIZE
resources = repmat(resourcesPerYear * simsize / npatients,SIMYEARS,1); % There will be a new set of resources each year
RESOURCESCREEN = 1; % Number of screens possible
RESOURCELASER = 2; % Not used because it is essentially the same as use of the ophthalmology resource
RESOURCEOPHTH = 3; % Detection of retinopathy by a non-ophthalmologist will need referral to ophthalmologist
    % Note that the ophthalmologist is probably going to be in a different
    % regions, yet we don't really keep track properly of that.

%% Initial stages of disease (reference: xxx)
startStages = [0.498 0.141 0.141 0.141 0.027 0.027 0 0];
    % Stage 7 is 0.27 in literature, but we will only study people who start out seeing and alive
startStages = startStages / sum(startStages); % Normalize to add to 1

qalys = 0;
costs = 0;
nUniBlind = 0;
nBlind = 0;

%% Initialize arrays for speed
ptAge = zeros(1,simsize);
ptMorbidity = zeros(1,simsize);
tpmR = zeros(8,8,simsize);
tpmL = zeros(8,8,simsize);
trueStageR = zeros(1,simsize);
trueStageL = zeros(1,simsize);
hadScatterR = zeros(1,simsize); % 1 if had scatter photocoagulation in each eye 
hadFocalR = zeros(1,simsize); % 1 if had focal photocoagulation in each eye 
hadScatterL = zeros(1,simsize); % 1 if had scatter photocoagulation in each eye 
hadFocalL = zeros(1,simsize); % 1 if had focal photocoagulation in each eye 
years_seeing = zeros(1,simsize);
ptUtils = zeros(simsize,8); %sets up matrix of utilities of each stage
ptUtils = zeros(simsize,8); %Utility cannot be less than 0 or greater than 1
utilUnilatBlind = zeros(1,simsize); 
screeningInt = zeros(1,simsize); % screening interval in years 
lastScreened = -999 * ones(1,simsize); % year that patient was last screened -999 means not screened yet



%% Debugging variables
%ageWhenBlind = zeros(NUMEYES,simsize);

%% MAIN LOOP
for year = 1:SIMYEARS   %for every year
	for pt = 1:simsize  % For all patients
        if year == 1 || trueStageR(pt) == STAGE_DEATH; % Initialize patient at beginning or year after they die.
            ptAge(pt) = (randsample(length(dmInPopByAge(MINAGE:MAXAGE)),1,true,dmInPopByAge(MINAGE:MAXAGE))') + MINAGE - 1;
% Age chosen based on prevalence of diabetes in the population
            ptMorbidity(pt) = rand() * MORBIDITYSD + morbidityIndex;
            tpmR(:,:,pt) = maketpm(ptMorbidity(pt),false,false);
            tpmL(:,:,pt) = maketpm(ptMorbidity(pt),false,false);
            trueStageR(pt) = randsample8(STAGE_HEALTH,startStages);
            trueStageL(pt) = randsample8(STAGE_HEALTH,startStages);
            hadScatterR(pt) = 0; % 1 if had scatter photocoagulation in each eye 
            hadFocalR(pt) = 0; % 1 if had focal photocoagulation in each eye 
            hadScatterL(pt) = 0; % 1 if had scatter photocoagulation in each eye 
            hadFocalL(pt) = 0; % 1 if had focal photocoagulation in each eye 
            years_seeing(pt) = 0;
            ptUtils(pt,:) = util + randn(1,8) .* utilSD; %sets up matrix of utilities of each stage
            ptUtils(pt,:) = max(min(ptUtils(pt,:),1),0); %Utility cannot be less than 0 or greater than 1
            utilUnilatBlind(pt) = 1 - ptUtils(pt,STAGE_BLIND) * unilatVsBilatBlind; 
            screeningInt(pt) = initScreenInt; % screening interval in years 
                %NOTE THAT ONCE RETINOPATHY IS DETECTED, THIS BECOMES FUPSCREENINT,
                %WHICH SHOULD BE STAGE-DEPENDENT
            lastScreened(pt) = -999; % year that patient was last screened -999 means not screened yet
        end
%           if trueStageR == STAGE_DEATH % Don't do calculations on deceased patients. Note we keep track of death in right eye stage
%               error('Reached STAGE_DEATH AT TOP OF LOOP')
%               break
%           end
        if (ptAge(pt) > MAXAGE) || (rand() < max(MortByAge(ptAge(pt)) * mortMult(trueStageR(pt)),MortByAge(ptAge(pt)) * mortMult(trueStageL(pt))))
            trueStageR(pt) = STAGE_DEATH; % Use stage of both eyes to figure out increased mortality
            continue % Continue in the for loop to the next patient
        end
        if (year >= lastScreened(pt) + screeningInt(pt)) && (rand() < complianceRate) % if they are due for a screening and likely to show up
            resources(year,RESOURCESCREEN) = resources(year,RESOURCESCREEN) - 1; % Use up a screen resource -- right now 1 per screen
                % Note that if we have no resources, we go negative to keep track of how much we overused the resources
            if resources(year,RESOURCESCREEN) >= 0 % We have the resources to screen the patient (0 is OK because we subtracted 1 already)
% All of the following is done if patient is screened
                lastScreened(pt) = year; % keep track that they were screened this year
                costs = costs + costsPerScreen; % Charge the system for the cost of screening
                examStageR(pt) = randsample8(trueStageR(pt),screenAcc(trueStageR(pt),:)); % Apparent vs true stage of disease R eye
                examStageL(pt) = randsample8(trueStageL(pt),screenAcc(trueStageL(pt),:)); % Apparent vs true stage of disease L eye
                canSeeOphth(pt) = true;
                if (screenRefer(examStageR(pt)) == 1) || (screenRefer(examStageL(pt)) == 1) % One or both eyes requires referral to an ophthalmologist
                    % Note that ophthalmologists don't refer to ophthalmologists
                    resources(year,RESOURCEOPHTH) = resources(year,RESOURCEOPHTH) - 1; % Use up a ophth referral resource -- 1 per screen
                        % If we have no resources, we go negative to keep track of how much we overused the resources
                    if resources(year,RESOURCEOPHTH) < 0 % We don't have the resources to send patient to ophthalmologist
                        canSeeOphth(pt) = false;
                    end
                end

% RIGHT EYE
                if canSeeOphth(pt)
                    if (examStageR(pt) == STAGE_PDR) && (hadScatterR(pt) == 0)
                        hadScatterR(pt) = 1; %if p has PDR and has not had scatter for that eye, assign them to scatter
                        tpmR(:,:,pt) = maketpm(ptMorbidity(pt),true,hadFocalR(pt)); % Change tpm to include scatter
                        costs = costs + cost_scatter; % Cost of that pt now cost of scatter treatment
                    elseif (examStageR(pt) == STAGE_ME) && (hadFocalR(pt) == 0)
                        hadFocalR(pt) = 1; % if p has macular edema in that eye and has not had focal treatment, assign them to it
                        tpmR(:,:,pt) = maketpm(ptMorbidity(pt),hadScatterR(pt),true);% Change tpm to include focal
                        costs = costs + cost_focal + cost_fa; % cost of p now includes cost of focal laser treatment
                    end
% LEFT EYE
                    if (examStageL(pt) == STAGE_PDR) && (hadScatterL(pt) == 0)
                        hadScatterL(pt) = 1; %if p has PDR and has not had scatter for that eye, assign them to scatter
                        tpmL(:,:,pt) = maketpm(ptMorbidity(pt),true,hadFocalL(pt)); % Change tpm to include scatter
                        costs = costs + cost_scatter; % Cost of that pt now cost of scatter treatment
                    elseif (examStageL(pt) == STAGE_ME) && (hadFocalL(pt) == 0)
                        hadFocalL(pt) = 1; % if p has macular edema in that eye and has not had focal treatment, assign them to it
                        tpmL(:,:,pt) = maketpm(ptMorbidity(pt),hadScatterL(pt),true);% Change tpm to include focal
                        costs = costs + cost_focal + cost_fa; % cost of p now includes cost of focal laser treatment
                    end
                end

                worstEye = max(examStageR(pt),examStageL(pt));
                bestEye = min(examStageR(pt),examStageL(pt)); % Establish best and worst eyes
                if worstEye > STAGE_HEALTH
                    if bestEye < STAGE_BLIND
                        screeningInt(pt) = FUPSCREENINT; % When there is perceived retinopathy in either eye and not bilaterally blind, screen fixed basis X
                    else
                        screeningInt(pt) = 999; % Stop screening if bilaterally blindX
                                            %Sets interval to essentailly never screen again (999 years)
                    end
                end
            end
        end
    % Above is performed only if patient is screened

    % Below is performed every year, even if not screened
    % Next lines are where the progression in the Markov chain occurs
            prevStageR = trueStageR(pt); % Only needed for figuring out when patient went blind
            trueStageR(pt) = randsample8(trueStageR(pt),tpmR(trueStageR(pt),:,pt)); % MARKOV!
            prevStageL = trueStageL(pt); % Needed for figuring out when patient went blind
            trueStageL(pt) = randsample8(trueStageL(pt),tpmL(trueStageL(pt),:,pt)); % MARKOV!
            if (trueStageR(pt) == STAGE_BLIND) && (prevStageR ~= STAGE_BLIND) % This year patient became blind in R eye
                if (trueStageL(pt) == STAGE_BLIND) && (prevStageL ~= STAGE_BLIND) % This year patient became blind in both eyes
                    nBlind = nBlind + 1;
                else                                                          % This year patient became blind in R eye only
                    nUniBlind = nUniBlind + 1;
                end
            else
                if (trueStageL(pt) == STAGE_BLIND) && (prevStageL ~= STAGE_BLIND) %This year patient became blind in L eye only
                    nUniBlind = nUniBlind + 1;
                end
            end

            trueBestEye = min(trueStageR(pt),trueStageL(pt)); % Establish stage of true best eye X
            trueWorstEye = max(trueStageR(pt),trueStageL(pt)); % Establish stage of true worst eye X
            if trueBestEye < STAGE_BLIND
                if trueWorstEye == STAGE_BLIND % If one blind eye, then utility is 0.85 (Clinical Ophthalmology 2014:8 1703?1709)
                    years_seeing(pt) = years_seeing(pt) + utilUnilatBlind(pt);
                 else
                    years_seeing(pt) = years_seeing(pt) + 1; %X Keep track of true non-blind years
                end
            end
    %        ptUtil_over_time(pt,year) = ptUtils(pt,trueBestEye);
    % Utitity dependent mostly on best eye, but with a weighting of the worst eye
            qalys = qalys + (1 - unilatVsBilatBlind) * ptUtils(pt,trueBestEye) + unilatVsBilatBlind * ptUtils(pt,trueWorstEye); % qalys dependent mostly on best eye only
            ptAge(pt) = ptAge(pt) + 1; % If not deceased, make one year older X
    end

% Above is done for each patient
% fprintf('Uni %d Blind %d simsize %d\n',nUniBlind, nBlind, simsize);
end
% Above is done for each year
if any(sum(resources,1) < 0)
    fprintf('Resource utilization %.1f%% %.1f%% %.1f%%\n',(SIMYEARS * resourcesPerYear * simsize / npatients - sum(resources,1)) * 100 ./ (SIMYEARS * resourcesPerYear * simsize / npatients));
end
costAndQaly = [costs / simsize; qalys / simsize; nUniBlind * npatients / (simsize * SIMYEARS); nBlind * npatients / (simsize * SIMYEARS)];
% We need to adjust for the fact that the simsize is lower than the
% npatients when the latter is more than MAXSIMSIZE
% Costs and QALYs are per patient over the entire simulation
% Blindness is total number across regions, per year.

