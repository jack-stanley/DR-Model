function costAndQaly = doMarkov4k(util,utilSD,costsPerProc,costsPerScreen,dmInPopByAge,MortByAge,screenAcc,initScreenInt,morbidityIndex) 
% takes following inputs
% utility by stage, 
% standard deviation of utility by stage, 
% cost per procedure or treatment,
% cost per screen
% proportion of each age with diabetes in the population
% mortality by age
% screening accuracy matrix
% initial screening interval
% morbidity index, which drives the transitions between retinopathy stages

%% Simulation parameters
SIMSIZE = 100000; % How many subject within a simulation

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

MINAGE = 18; % At the moment we are only doing adults. This should be extended to kids
MAXAGE = 120;
MAXYEARS = MAXAGE - MINAGE + 1; % Maximum years from entry into simulation to death

NUMEYES = 2;

%% Initialize utilities
UTILUNILATBLIND = 0.85;  % Utility of unilateral blindness

%% Initialize cost variables
cost_fa = costsPerProc(1); % cost of fluorescein angiogram testing
cost_focal = costsPerProc(2); % cost of focal laser treatment
cost_scatter = costsPerProc(3); % cost of scatter treatment

%% Initialize morbidities
MORBIDITYSD = 0; %Amount of variability in the morbidity index
% ptMorbidity = randn(SIMSIZE,NUMEYES) * MORBIDITYSD + morbidityIndex;

    
%% Initialize epidemiology variables
% ptAge = (randsample(length(dmInPopByAge(MINAGE:MAXAGE)),SIMSIZE,true,dmInPopByAge(MINAGE:MAXAGE))') + MINAGE - 1;
%vector SIMSIZE long giving random ages using probability established in
%previous line (only people 40 through 120 years old)
% chance of dying at each age is 1.8 x chance of dying at each stage, multiplied by the chance of dying just from diabetes alone
mortMult = [1 1.23 1.23 1.49 1.76 1.76 2.34 1000] * 1.8; %xMortality multipliers, where DM alone

%% Initialize screening variables
FUPSCREENINT = 1; %screening interval - NOTE THAT THIS MUST BE CHANGED TO A VARIABLE, TO ADAPT TO STAGE OF DISEASE
% 
%% Initial stages of disease (reference: xxx)
startStage1 = 0.498;
startStage2 = 0.141;
startStage3 = 0.141;
startStage4 = 0.141; 
startStage5 = 0.027;
startStage6 = 0.027;
startStage7= 0; %This is 0.27 in literature, but we will only study people who start out seeing and alive
startStage8 = 0;
startStages = [startStage1 startStage2 startStage3 startStage4 startStage5 startStage6 startStage7 startStage8];
startStages = startStages / sum(startStages); % Normalize to add to 1

qalys = 0;
costs = 0;

%% Debugging variables
ageWhenBlind = zeros(NUMEYES,SIMSIZE);

%% MAIN LOOP
for pt = 1:SIMSIZE
    ptAge = (randsample(length(dmInPopByAge(MINAGE:MAXAGE)),1,true,dmInPopByAge(MINAGE:MAXAGE))') + MINAGE - 1;
    ptMorbidity = rand() * MORBIDITYSD + morbidityIndex;
    tpmR = maketpm(ptMorbidity,false,false);
    tpmL = maketpm(ptMorbidity,false,false);
    trueStageR = randsample8(STAGE_HEALTH,startStages);
    trueStageL = randsample8(STAGE_HEALTH,startStages);
%     prevStageR = STAGE_HEALTH;
%     prevStageR = STAGE_HEALTH;
    hadScatterR = 0; % 1 if had scatter photocoagulation in each eye 
    hadFocalR = 0; % 1 if had focal photocoagulation in each eye 
    hadScatterL = 0; % 1 if had scatter photocoagulation in each eye 
    hadFocalL = 0; % 1 if had focal photocoagulation in each eye 
    years_seeing = 0;
    ptUtils = randn(1,8) .* utilSD + util; %sets up matrix of utilities of each stage
    ptUtils = max(min(ptUtils,1),0); %Utility cannot be less than 0 or greater than 1
    screeningInt = initScreenInt; % screening interval in years NOTE THAT THIS MUST BE CHANGED TO A VARIABLE, TO ADAPT TO STAGE OF DISEASE
    lastScreened = 0; % when patient was last screened


%for all patients
    for year = 1:MAXYEARS
%for every year
        if trueStageR == STAGE_DEATH % Don't do calculations on deceased patients. Note we keep track of death in right eye stage
            break
        end
        if rand() < max(MortByAge(ptAge) * mortMult(trueStageR),MortByAge(ptAge) * mortMult(trueStageL))
            trueStageR = STAGE_DEATH; % XUse both eyes to figure out increased mortality X
            break
        end
        if year >= lastScreened + screeningInt % if they are due for a screening
            lastScreened = year; % if it's within the year they were screened
            costs = costs + costsPerScreen;
            %XcostScreens = XcostScreens + costsPerScreen; %total cost is now including the cost of the screen because
            %they are getting a new screen
            % We unroll the loop for NUMEYES because we can't do a parfor loop with two
            % dimensional indexing. Previously was for eye = 1:NUMEYES % Repeat for each eye. Right eye = 1, left eye = 2
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
            % Next lines are where the progression in the Markov chain occurs
            prevStageR = trueStageR;
            temp1 = tpmR;  % Doing this to make parfor work
            trueStageR = randsample8(trueStageR,temp1(trueStageR,:));
            if trueStageR == STAGE_BLIND && prevStageR ~= STAGE_BLIND %This year patient became blind
                ageWhenBlind = year;
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
            % Next lines are where the progression in the Markov chain occurs
            prevStageL = trueStageL;
            temp1 = tpmL;  % Doing this to make parfor work
            trueStageL = randsample8(trueStageL,temp1(trueStageL,:));
            %                    tpmL(trueStageL(pt),:,pt));
            if trueStageL == STAGE_BLIND && prevStageL ~= STAGE_BLIND %This year patient became blind
                ageWhenBlind = year;
            end
        end
        % Above is performed only if patient is screened
        worstEye = max(examStageR,examStageL);
        bestEye = min(examStageR,examStageL); %Xestablish best and worst eyes X
        if worstEye > STAGE_HEALTH
            if bestEye < STAGE_BLIND
                screeningInt = FUPSCREENINT; %X When there is any retinopathy in either eye and not bilaterally blind, screen fixed basis X
            else
                screeningInt = 999; %X Stop screening if bilaterally blindX
                %Sets interval to essentailly never screen again (999
                %years)
            end
        end
        trueBestEye = min(trueStageR,trueStageL); %Xestablish true best eye X
        trueWorstEye = max(trueStageR,trueStageL); %Xestablish true worst eye X
        if trueBestEye < STAGE_BLIND
            if trueWorstEye == STAGE_BLIND % If one blind eye, then utility is 0.85 (Clinical Ophthalmology 2014:8 1703?1709)
                years_seeing = years_seeing + UTILUNILATBLIND;
            else
                years_seeing = years_seeing + 1; %X Keep track of true non-blind years X
            end
        end
%        ptUtil_over_time(pt,year) = ptUtils(pt,trueBestEye);
        %utitity dependent on best eye only
        %Is being blind in one eye really equal in utility to perfect sight
        %in both eyes?
        qalys = qalys + ptUtils(trueBestEye); % qalys dependent on best eye only
        ptAge = ptAge + 1; % X If not deceased, make one year older X
    end
%X Above done every year X
end
%X Above done for each patient X
%    util_over_time(year) = sum(ptUtil_over_time(:,year));
%end
%fprintf('\n');
% for i = 1:SIMSIZE
%     fprintf('Pt %d ScOD %d ScOS %d FOD %d F OS %d StOD %d StOS %d BlOD %d BlOS %d\n',...
%         i,hadScatter(1,i),hadScatter(2,i),hadFocal(1,i),hadFocal(2,i),trueStage(1,i),trueStage(2,i),ageWhenBlind(1,i),ageWhenBlind(2,i));
% end
%X mean(years_seeing)X
%X histogram(years_seeing)X
%X figure X
%X histogram(costs) X
%X figure X
%X sum(costs) X
%X figure(1)X
%X plot(util_over_time) X
% Are these things that still need to be done?
%fprintf('Screen Scatter Focal FA %.2f %.2f %.2f %.2f\n',XcostScreens,XcostScatters,XcostFocals,XcostFAs);
%ptUtil_over_time
costAndQaly = [costs; qalys] / SIMSIZE;
%X trueStage;X
end
