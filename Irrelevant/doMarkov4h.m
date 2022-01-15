function costAndQaly = doMarkov4h(util,utilSD,costsPerProc,costsPerScreen,dmInPopByAge,MortByAge,screenAcc,initScreenInt,morbidityIndex) 
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

%% Simulation parameters
SIMSIZE = 1000; % How many subjects within a simulation

MINAGE = 18; % At the moment we are only doing adults. This should be extended to kids
MAXAGE = 120;
MAXYEARS = MAXAGE - MINAGE + 1; % Maximum years from entry into simulation to death

NUMEYES = 2;
EYERIGHT = 1;
EYELEFT = 2;
EYECORREL = 0.5; %Correlation between disease in the eyes in terms of disease. 
% So if one eye becomes worse, there is this much chance that the other eye
% will also become worse.

%% Initialize utilities
UTILUNILATBLIND = 0.85;  % Utility of unilateral blindness
ptUtils = zeros(SIMSIZE,NSTAGES); %sets up matrix of possible stages for each patient
for i = 1:NSTAGES %for 1 through 8 stages
    ptUtils(:,i) = randn(1,SIMSIZE) * utilSD(i) + util(i); %for each stage, the utility is a randomly generated
    % number for that stage centered around the mean for that stage with standard deviation assigned in DiabetesSim
end
ptUtils = max(min(ptUtils,1),0); %Utility cannot be less than 0 or greater than 1
ptUtil_over_time = zeros(SIMSIZE,MAXYEARS); %setting up matrix, each row is a vector of single patient's utility over time
meanUtil_over_time = zeros(1,MAXYEARS); %setting up mean of each all pateints' utility for that year

%% Initialize cost variables
cost_fa = costsPerProc(1); % cost of fluorescein angiogram testing
cost_focal = costsPerProc(2); % cost of focal laser treatment
cost_scatter = costsPerProc(3); % cost of scatter treatment
costs = zeros(1,SIMSIZE); %setting up vector n patients long for cost

%% Initialize morbidities
MORBIDITYSD = 0; %Amount of variability in the morbidity index
ptMorbidity = randn(SIMSIZE,NUMEYES) * MORBIDITYSD + morbidityIndex;

%% Initialize TPM - depends on morbidities
tpm = zeros(NSTAGES,NSTAGES,NUMEYES,SIMSIZE);
for i = 1:SIMSIZE
    tpm(:,:,EYERIGHT,i) = maketpm(ptMorbidity(i),false,false);
    tpm(:,:,EYELEFT,i) = maketpm(ptMorbidity(i),false,false);
end
    
%% Initialize epidemiology variables
ptAge = (randsample(length(dmInPopByAge(MINAGE:MAXAGE)),SIMSIZE,true,dmInPopByAge(MINAGE:MAXAGE))') + MINAGE - 1;
%vector SIMSIZE long giving random ages using probability established in
%previous line (only people 40 through 120 years old)
% chance of dying at each age is 1.8 x chance of dying at each stage, multiplied by the chance of dying just from diabetes alone
mortMult = [1 1.23 1.23 1.49 1.76 1.76 2.34 1000] * 1.8; %xMortality multipliers, where DM alone

%% Initialize screening variables
FUPSCREENINT = 1; %screening interval - NOTE THAT THIS MUST BE CHANGED TO A VARIABLE, TO ADAPT TO STAGE OF DISEASE
screeningInt = ones(1,SIMSIZE) * initScreenInt; % screening interval in years
lastScreened = zeros(1,SIMSIZE); % when patient was last screened

%% Initialize other variables
years_seeing = zeros(1,SIMSIZE); %setting up vector n patients long for "years seeing?"
qalys = zeros(1,SIMSIZE); %setting up vector n patients long for qalys
hadScatter = zeros(2,SIMSIZE); % 1 if had scatter photocoagulation in each eye 
hadFocal = zeros(2,SIMSIZE); % 1 if had focal photocoagulation in each eye 

%% TO USE EVENTUALLY
%stage1 = 0.498;
% ***CHANGE Correct to remove blind people from population, will be lower.
%stage2 = 0.141;
%stage3 = 0.141;
%stage4 = 0.141; 
%stage5 = 0.027;
%stage6 = 0.027;
%stage7= 0.027;
%stage8 = 0; %FILL THIS IN LATER
%ADD MATRIX TO ASSIGN CORRECT PROPORTION OF POPULATION TO THESE STAGES
%trueStage = zeros(NUMEYES,SIMSIZE); %setting up matrix for actual stage for each eye
%trueStage(1,:) = (stage1(ptAges) > rand(1,SIMSIZE)) * ;
trueStage = ones(NUMEYES,SIMSIZE);% CHANGE later so that we start with different stages of disease in the population
%trueStage(2,:) = (stage2ByAge(ptAges) > rand(1,SIMSIZE)) + 1;
prevStage = zeros(NUMEYES,SIMSIZE); %Keep track of the previous stage for each eye in the simulation
%HERE TOO
%XcostScreens = 0;
%XcostScatters = 0;
%XcostFocals = 0;
%XcostFAs = 0;

%% Debugging variables
ageWhenBlind = zeros(NUMEYES,SIMSIZE);

%% MAIN LOOP
for year = 1:MAXYEARS
    %for every year
    parfor pt = 1:SIMSIZE
        %for all patients
        if trueStage(EYERIGHT,pt) == STAGE_DEATH % Don't do calculations on deceased patients. Note we keep track of death in right eye stage
            continue
        end
        if rand() < max(MortByAge(ptAge(pt)) * mortMult(trueStage(EYERIGHT,pt)),MortByAge(ptAge(pt)) * mortMult(trueStage(EYELEFT,pt)))
            trueStage(EYERIGHT,pt) = STAGE_DEATH; % XUse both eyes to figure out increased mortality X
            continue
        end
%         if year >= lastScreened(pt) + screeningInt(pt) % if they are due for a screening
%                 lastScreened(pt) = year; % if it's within the year they were screened
%                 costs(pt) = costs(pt) + costsPerScreen;
% %XcostScreens = XcostScreens + costsPerScreen; %total cost is now including the cost of the screen because
%                                                                 %they are getting a new screen
%                 for eye = 1:NUMEYES % Repeat for each eye. Right eye = 1, left eye = 2
%                     examStage(eye,pt) = randsample(NSTAGES,1,true,screenAcc(trueStage(eye,pt),:)); % Apparent vs true stage of disease X
% %fprintf('%d-%d ', examStage(eye,pt), trueStage(eye,pt));
%                     if (examStage(eye,pt) == STAGE_PDR) && (hadScatter(eye,pt) == 0)
%                         hadScatter(eye,pt) = 1; %if p has PDR and has not had scatter for that eye, assign them to scatter
%                         tpm(:,:,eye,pt) = maketpm(ptMorbidity(pt),true,hadFocal(eye,pt)); % Change tpm to include scatter
%                         costs(pt) = costs(pt) + cost_scatter; % Cost of that pt now cost of scatter treatment
% %XcostScatters = XcostScatters + cost_scatter;
%                     elseif (examStage(eye,pt) == STAGE_ME) && (hadFocal(eye,pt) == 0)
%                         hadFocal(eye,pt) = 1; % if p has macular edema in that eye and has not had focal treatment, assign them to it
%                         tpm(:,:,eye,pt) = maketpm(ptMorbidity(pt),hadScatter(eye,pt),true);% Change tpm to include focal
%                         costs(pt) = costs(pt) + cost_focal + cost_fa; % cost of p now includes cost of focal laser treatment
%  %XcostFocals = XcostFocals + cost_focal;
%  %XcostFAs = XcostFAs + cost_fa;              
%                     end
% % Next lines are where the progression in the Markov chain occurs
%                     prevStage(eye,pt) = trueStage(eye,pt);
% %tpm(trueStage(eye,pt),:,eye,pt)
%                     trueStage(eye,pt) = randsample(NSTAGES,1,true,tpm(trueStage(eye,pt),:,eye,pt));
%                     if trueStage(eye,pt) == STAGE_BLIND && prevStage(eye,pt) ~= STAGE_BLIND %This year patient became blind
%                        ageWhenBlind(eye,pt) = year;
%                     end
%                 end
% % Above loop is performed for each eye
% %fprintf('|');
%         end 
% % Above is performed only if patient is screened
%         worstEye = max(examStage(EYERIGHT,pt),examStage(EYELEFT,pt)); 
%         bestEye = min(examStage(EYERIGHT,pt),examStage(EYELEFT,pt)); %Xestablish best and worst eyes X
%         if worstEye > STAGE_HEALTH
%             if bestEye < STAGE_BLIND
%                 screeningInt(pt) = FUPSCREENINT; %X When there is any retinopathy in either eye and not bilaterally blind, screen fixed basis X
%             else
%                 screeningInt(pt) = 999; %X Stop screening if bilaterally blindX
%                 %Sets interval to essentailly never screen again (999
%                 %years)
%             end
%         end
%         trueBestEye = min(trueStage(EYERIGHT,pt),trueStage(EYELEFT,pt)); %Xestablish true best eye X
%         trueWorstEye = max(trueStage(EYERIGHT,pt),trueStage(EYELEFT,pt)); %Xestablish true worst eye X
%         if trueBestEye < STAGE_BLIND
%             if trueWorstEye == STAGE_BLIND % If one blind eye, then utility is 0.85 (Clinical Ophthalmology 2014:8 1703?1709)
%                 years_seeing(pt) = years_seeing(pt) + UTILUNILATBLIND;
%             else
%                 years_seeing(pt) = years_seeing(pt) + 1; %X Keep track of true non-blind years X
%             end
%         ptUtil_over_time(pt,year) = ptUtils(pt,trueBestEye);
%         %utitity dependent on best eye only
%         %Is being blind in one eye really equal in utility to perfect sight
%         %in both eyes?
%         qalys(pt) = qalys(pt) + ptUtils(pt,trueBestEye); % qalys dependent on best eye only
%         ptAge(pt) = ptAge(pt) + 1; % X If not deceased, make one year older X
    end
%X Above done for each patient X
    util_over_time(year) = sum(ptUtil_over_time(:,year));
end
%X Above done every year X
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
