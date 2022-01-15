function costAndQaly = doMarkov4g(npts,util,utilSD,costsPerProc,costsPerScreen,dmByAge,startAges,MortByAge,screenAcc,initScreenInt) % takes inputs number of patients,
%utility, standard deviation of utility, treatment type, cost per procedure or treatment,
%sense/spec, screening interval.
NSTAGES = 8; %total number of stages
STAGE_HEALTH = 1;
STAGE_NPDR1 = 2;
STAGE_NPDR2 = 3;
STAGE_NPDR3 = 4;
STAGE_PDR = 5;
STAGE_ME = 6;
STAGE_BLIND = 7;
STAGE_DEATH = 8; % labels each stage of disease
%******

FUPSCREENINT = 1; %screening interval - NOTE THAT THIS MUST BE CHANGED TO A VARIABLE, TO ADAPT TO STAGE OF DISEASE

%******
TPM_NOPHOTOCOAG = 1; %assign number values for each treatment
TPM_SCATTER = 2;
TPM_FOCAL = 3;
TPM_SCATTERFOCAL = 4;
MAXYEARS = 20; %We assume no more than 20 years from entry to death
NUMEYES = 2;
EYERIGHT = 1;
EYELEFT = 2;
EYECORREL = 0.5; %Correlation between disease in the eyes in terms of disease. 
%So if one eye becomes worse, there is this much chance that the other eye
%will also become worse.
util
%% Initialize utilities
ptUtils = zeros(npts,NSTAGES); %sets up matrix of possible stages for each patient
for i = 1:NSTAGES %for 1 through 8 stages
    ptUtils(:,i) = randn(1,npts) * utilSD(i) + util(i); %for each stage, the utility is a randomly generated
    % number for that stage centered around the mean for that stage with standard deviation assigned in DiabetesSim
end
ptUtils = max(min(ptUtils,1),0); %Utility cannot be less than 0 or greater than 1
ptUtil_over_time = zeros(npts,MAXYEARS); %setting up matrix, each row is a vector of single patient's utility over time
meanUtil_over_time = zeros(1,MAXYEARS); %setting up mean of each all pateints' utility for that year

%% Define costs
cost_na = costsPerProc(1); %cost of no action 
cost_fa = costsPerProc(2); % cost of fluorescein angiogram testing
cost_focal = costsPerProc(3); % cost of focal laser treatment
cost_scatter = costsPerProc(4); % cost of scatter treatment

%% Initialize variables
ages = (randsample(length(startAges(40:120)),npts,true,startAges(40:120))') + 39;
% chance of dying at each age is 1.8 x chance of dying at each stage, multiplied by the chance of dying just from diabetes alone
mortMult = [1 1.23 1.23 1.49 1.76 1.76 2.34 1000] * 1.8; %xMortality multipliers, where DM alone

costs = zeros(1,npts); %setting up vector n pateints long for cost
years_seeing = zeros(1,npts); %setting up vector n patients long for "years seeing?"
qalys = zeros(1,npts); %setting up vector n patients long for qalys
hadScatter = zeros(2,npts); % 1 if had scatter photocoagulation in each eye (tell if patient had scatter)
hadFocal = zeros(2,npts); % 1 if had focal photocoagulation in each eye (tell if patient had focal)
screeningInt = ones(1,npts) * initScreenInt; % screening interval in years
lastScreened = zeros(1,npts); % when patient was last screened

%% Initialize TPM
tpm_nophotocoag = [
    0.869	0.131         0         0         0         0         0 0;
    0       0.863	0.1310         0         0    0.0060         0  0;
    0       0       0.8630    0.1310         0    0.0060         0  0;
    0         0         0    0.8900    0.0800    0.0300         0   0;
    0         0         0         0    0.9100         0    0.0900   0;
    0         0         0         0         0    0.0500    0.9500   0;
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
%trueStage = zeros(NUMEYES,npts); %setting up matrix for actual stage for each eye
%trueStage(1,:) = (stage1(ages) > rand(1,npts)) * ;
trueStage = ones(NUMEYES,npts);% CHANGE later so that we start with different stages of disease in the population
%trueStage(2,:) = (stage2ByAge(ages) > rand(1,npts)) + 1;
prevStage = zeros(NUMEYES); %Keep track of the previous stage for each eye in the simulation
%HERE TOO
%XcostScreens = 0;
%XcostScatters = 0;
%XcostFocals = 0;
%XcostFAs = 0;
for year = 1:MAXYEARS
    %for every year
    for pt = 1:npts
        %for all patients
        if trueStage(EYERIGHT,pt) == STAGE_DEATH % XDon't do calculations on deceased patients. Note we keep track of death in right eye stage
            continue
        end
        if rand() < max(MortByAge(ages(pt)) * mortMult(trueStage(EYERIGHT,pt)),MortByAge(ages(pt)) * mortMult(trueStage(EYELEFT,pt)))
            trueStage(EYERIGHT,pt) = STAGE_DEATH; % XUse both eyes to figure out increased mortality X
            continue
        end
        for eye = 1:NUMEYES %Right eye = 1, left eye = 2 X
            %repeat for each eye
            examStage(eye,pt) = randsample(NSTAGES,1,true,screenAcc(trueStage(eye,pt),:)); % XApparent vs true stage of disease X
fprintf('%d-%d ', examStage(eye,pt), trueStage(eye,pt));
            %What does this actually do?
            if year >= lastScreened(pt) + screeningInt(pt)
                %if they are due for a screening
                lastScreened(pt) = year;
                %if it's within the year they were screened
                costs(pt) = costs(pt) + costsPerScreen;
%                XcostScreens = XcostScreens + costsPerScreen;
                %total cost is now including the cost of the screen because
                %they are getting a new screen
                if (examStage(eye,pt) == STAGE_PDR) && (hadScatter(eye,pt) == 0)
                    hadScatter(eye,pt) = 1;
                    %if p has PDR and has not had scatter for that eye,
                    %assign them to scatter
                    costs(pt) = costs(pt) + cost_scatter;
%                    XcostScatters = XcostScatters + cost_scatter;
                    %cost of that p. now includes cost of scatter treatment
                elseif (examStage(eye,pt) == STAGE_ME) && (hadFocal(eye,pt) == 0)
                    hadFocal(eye,pt) = 1;
                    % if p has macular edema in that eye and has not had focal
                    % treatment, assign them to it
                    costs(pt) = costs(pt) + cost_focal + cost_fa;
 %                   XcostFocals = XcostFocals + cost_focal;
 %                   XcostFAs = XcostFAs + cost_fa;
                    % cost of p now includes cost of focal laser treatment
                end
            end
            if hadScatter(eye,pt) == 0
                if hadFocal(eye,pt) == 0
                    % If eye has not had focal or scatter in past screen
                    prevStage(eye) = trueStage(eye,pt); %Keep track of what the stage was previously
                    trueStage(eye,pt) = randsample(NSTAGES,1,true,tpm(trueStage(eye,pt),:,TPM_NOPHOTOCOAG));
                    %then their true stage will change to that predicited
                    %in DiabetesSim for NOPHOTO
                else
                    prevStage(eye) = trueStage(eye,pt);
                    trueStage(eye,pt) = randsample(NSTAGES,1,true,tpm(trueStage(eye,pt),:,TPM_FOCAL));
                    % If they have had not had scatter but have had focal
                    % then their true stage will change to that predicted
                    % by DiabetesSim for FOCAL treatment
                end
            else %X Eye has had scatter photocoagulation X
                if hadFocal(eye,pt) == 0
                    prevStage(eye) = trueStage(eye,pt);
                    trueStage(eye,pt) = randsample(NSTAGES,1,true,tpm(trueStage(eye,pt),:,TPM_SCATTER));
                    %if they have had focal then true stage will change to
                    %that predicted by DS for Scatter
                else
                    prevStage(eye) = trueStage(eye,pt);
                    trueStage(eye,pt) = randsample(NSTAGES,1,true,tpm(trueStage(eye,pt),:,TPM_SCATTERFOCAL));
                    %If they have had scatterfocal then true stage will
                    %change to that predicted by scatterfocal
                end
            end
        end %X Above loop is performed for each eye X
%Need to account for correlation in disease between eyes
%We will assume that if one eye changes by 1 stage and the other by 0 stages, then there is a
%EYECORREL chance that the other eye will change by 1 stage. If the eye
%changes by 2 stages, then there is a 1-(1-EYECORREL)^2 chance of changing 
%the other eye by 1 stage and a (1-(1-EYECORREL)^1 chance of changing by 2 stages. And so
%on. 
%The only problem is with macular edema, which is not really worse than
%PDR, but different. 
%If both change (e.g. by m and n), then we will base our changes on the
%difference between the two eyes.
%The above is no good -- it doesn't take into account laser treatment.
%Will think about it...
        changeRight = trueStage(EYERIGHT,pt) - prevStage(EYERIGHT);
        changeLeft = trueStage(EYELEFT,pt) - prevStage(EYELEFT);
        if changeRight > changeLeft
           changedEye = EYERIGHT;
           toChangeEye = EYELEFT;
           changeAmount = changeRight - changeLeft;
        else
            if changeRight < changeLeft
              changedEye = EYELEFT;
              toChangeEye = EYERIGHT;
              changedAmount = changedLeft - changedRight;
            else
                changedAmount = 0;
            end
        end
        for i = 1:changedAmount %If there is no change in either eye, then we do nothing because changedAmount is 0
            if rand() < EYECORREL %In other words, do the following EYECORREL percent of the time
                trueStage(toChangeEye,pt) = trueStage(toChangeEye,pt) + 1;
            end
        end
        worstEye = max(examStage(EYERIGHT,pt),examStage(EYELEFT,pt)); 
        bestEye = min(examStage(EYERIGHT,pt),examStage(EYELEFT,pt)); %Xestablish best and worst eyes X
        if worstEye > STAGE_HEALTH
            if bestEye < STAGE_BLIND
                screeningInt(pt) = FUPSCREENINT; %X When there is any retinopathy in either eye and not bilaterally blind, screen fixed basis X
            else
                screeningInt(pt) = 999; %X Stop screening if bilaterally blindX
                %Sets interval to essentailly never screen again (999
                %years)
            end
        end
        trueBestEye = min(trueStage(EYERIGHT,pt),trueStage(EYELEFT,pt)); %Xestablish true best and worst eyes X
        if trueBestEye < STAGE_BLIND
            years_seeing(pt) = years_seeing(pt) + 1; %X Keep track of true non-blind years X
        end
        ptUtil_over_time(pt,year) = ptUtils(pt,trueBestEye);
        %utitity dependent on best eye only
        %Is being blind in one eye really equal in utility to perfect sight
        %in both eyes?
        qalys(pt) = qalys(pt) + ptUtils(pt,trueBestEye);
        % qalys depenedent on best eye only
        ages(pt) = ages(pt) + 1; % X If not deceased, make one year older X
    end %X Above done for each patient X
    util_over_time(year) = sum(ptUtil_over_time(:,year));
end %X Above done every year X
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
ptUtil_over_time
costAndQaly = [costs; qalys];
%X trueStage;X
end
