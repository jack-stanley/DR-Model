function costAndQaly = doMarkov4(npts,util,utilSD,costsPerProc,costsPerScreen,dmByAge,startAges,MortByAge,screenAcc,initScreenInt,morbidityIndex) % takes inputs number of patients,
%utility, standard deviation of utility, treatment type, cost per procedure or treatment,
%sense/spec, screening interval, and morbidity index (vector for each patient).
NSTAGES = 8; %total number of stages
STAGE_HEALTH = 1;
STAGE_NPDR1 = 2;
STAGE_NPDR2 = 3;
STAGE_NPDR3 = 4;
STAGE_PDR = 5;
STAGE_ME = 6;
STAGE_BLIND = 7;
STAGE_DEATH = 8; % labels each stage of disease
FUPSCREENINT = 1; %screening interval
MAXYEARS = 100; %We assume no more than 100 years from entry to death
NUMEYES = 2;
EYERIGHT = 1;
EYELEFT = 2;

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
cost_fa = costsPerProc(1); % cost of fluorescein angiogram testing
cost_focal = costsPerProc(2); % cost of focal laser treatment
cost_scatter = costsPerProc(3); % cost of scatter treatment

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

%% Initialize TPM (one for each patient, and each patient has one for each eye)
tpm = zeros(NSTAGES,NSTAGES,npts,2);
for i = 1:npts
    tpm(:,:,i,EYERIGHT) = maketpm(morbidityIndex(i),false,false); %No scatter or focal laser when we begin
    tpm(:,:,i,EYELEFT) = maketpm(morbidityIndex(i),false,false); %No scatter or focal laser when we begin
end

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

%% ADD MATRIX TO ASSIGN CORRECT PROPORTION OF POPULATION TO THESE STAGES
trueStage = zeros(NUMEYES,npts); %setting up matrix for actual stage for each eye
%trueStage(1,:) = (stage1(ages) > rand(1,npts)) * ;
trueStage = ones(NUMEYES,npts);% CHANGE later so that we start with different stages of disease in the population
%trueStage(2,:) = (stage2ByAge(ages) > rand(1,npts)) + 1;
%HERE TOO

%% MAIN LOOP
for year = 1:MAXYEARS
    %for every year
    for pt = 1:npts
        %for all patients
        if trueStage(EYERIGHT,pt) == STAGE_DEATH % XDon't do calculations on deceased patients X
            continue
        end
        if rand() < max(MortByAge(ages(pt)) * mortMult(trueStage(EYERIGHT,pt)),MortByAge(ages(pt)) * mortMult(trueStage(EYELEFT,pt)))
            trueStage(EYERIGHT,pt) = STAGE_DEATH; % XUse both eyes to figure out increased mortality X
            continue
        end
        for eye = 1:NUMEYES %XRight eye = 1, left eye = 2 X
            %repeat for each eye
            examStage(eye,pt) = randsample(NSTAGES,1,true,screenAcc(trueStage(eye,pt),:)); % XApparent vs true stage of disease X
            %What does this actually do?
            if year >= lastScreened(pt) + screeningInt(pt)
                %if they are due for a screening
                lastScreened(pt) = year;
                %if it's within the year they were screened
                costs(pt) = costs(pt) + costsPerScreen;
                %total cost is now including the cost of the screen because
                %they are getting a new screen
                if (examStage(eye,pt) == STAGE_PDR) && (hadScatter(eye,pt) == 0)
                    hadScatter(eye,pt) = 1;
                    tpm(:,:,pt,eye) = maketpm(morbidityIndex(pt),true,hadFocal(eye,pt));
                    %if p has PDR and has not had scatter for that eye,
                    %assign them to scatter
                    costs(pt) = costs(pt) + cost_scatter;
                    %cost of that p. now includes cost of scatter treatment
                elseif (examStage(eye,pt) == STAGE_ME) && (hadFocal(eye,pt) == 0)
                    hadFocal(eye,pt) = 1;
                    tpm(:,:,pt,eye) = maketpm(morbidityIndex(pt),hadScatter(eye,pt),true);
                    % if p has macular edema in that eye and has not had focal
                    % treatment, assign them to it
                    costs(pt) = costs(pt) + cost_focal + cost_fa;
                    % cost of p now includes cost of focal laser treatment
                end
            end
            %The following is where we do the actual Markov chain, going from stage to
            %stage. Now that we adjust the tpm by patient, we don't have code
            %to use different tpms for each type of laser.
            trueStage(eye,pt) = randsample(NSTAGES,1,true,tpm(trueStage(eye,pt),:,pt,eye)); 
        end %X Above is for each eye X
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
        if bestEye < STAGE_BLIND
            years_seeing(pt) = years_seeing(pt) + 1; %X Keep track of true non-blind years X
        end
        ptUtil_over_time(pt,year) = ptUtils(pt,bestEye);
        %utitity dependent on best eye only
        %Is being blind in one eye really equal in utility to perfect sight
        %in both eyes?
        qalys(pt) = qalys(pt) + ptUtils(pt,bestEye);
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
costAndQaly = [costs; qalys];
%X trueStage;X
end
