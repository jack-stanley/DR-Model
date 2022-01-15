function costAndQaly = doMarkov(npts,util,utilSD,tpm,costsPerProc,sensSpec,initScreenInt) % takes inputs number of patients,
%utility, standard deviation of utility, treatment type, cost per treatment,
%sense/spec, screening interval. All specified from DiabetesSIM?
STAGE_HEALTH = 1;
STAGE_NPDR1 = 2;
STAGE_NPDR2 = 3;
STAGE_NPDR3 = 4;
STAGE_PDR = 5;
STAGE_ME = 6;
STAGE_BLIND = 7;
STAGE_DEATH = 8; % labels each stage of disease
FUPSCREENINT = 1; %screening interval
NSTAGES = 8; %total number of stages
COST_SCREEN = costsPerProc(1); % cost per screen
COST_FA = costsPerProc(2); % cost of fa(?) treatment (FA = no treatment? scatterfocal)
COST_FOCAL = costsPerProc(3); % cost of focal laser treatment
COST_SCATTER = costsPerProc(4); % cost of scatter treatment
TPM_NOPHOTOCOAG = 1; %assign number values for each treatment
TPM_SCATTER = 2;
TPM_FOCAL = 3;
TPM_SCATTERFOCAL = 4;
MAXYEARS = 100; %We assume no more than 100 years from entry to death
ptUtils = zeros(npts,NSTAGES); %sets up matrix of possible stages for each patient
for i = 1:NSTAGES %for 1 trough 8 stages
    ptUtils(:,i) = randn(1,npts) * utilSD(i) + util(i); %for each stage, the utility is a randomly generated
    %number for that stage centered around the mean for that
    %stage with standard deviation assigned in DiabetesSim
end
ptUtils = max(min(ptUtils,1),0); %Utility cannot be less than 0 or greater than 1
ptUtil_over_time = zeros(npts,MAXYEARS); %setting up matrix, each row is a vector of single patient's utility over time
meanUtil_over_time = zeros(1,MAXYEARS); %setting up mean of each all pateints' utility for that year
costs = zeros(1,npts); %setting up vector n pateints long for cost
years_seeing = zeros(1,npts); %setting up vector n patients long for "years seeing?"
qalys = zeros(1,npts); %setting up vector n patients long for qalys
hadScatter = zeros(2,npts); % 1 if had scatter photocoagulation in each eye (tell if patient had scatter)
hadFocal = zeros(2,npts); % 1 if had focal photocoagulation in each eye (tell if patient had focal)
screeningInt = ones(1,npts) * initScreenInt; % screening interval in years
lastScreened = zeros(1,npts); % when patient was last screened
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
stage1 = 0.498;
%Correct to remove blind people from population, will be lower.
stage2 = 0.141;
stage3 = 0.141;
stage4 = 0.141; 
stage5 = 0.027;
stage6 = 0.027;
stage7= 0.027;
stage8 = %FILL THIS IN LATER
%ADD MATRIX TO ASSIGN CORRECT PROPORTION OF POPULATION TO THESE STAGES
trueStage = zeros(2,npts); %setting up matrix for actual stage for each eye
trueStage(1,:) = (stage1(ages) > rand(1,npts)) * ;
%THIS IS WHAT NEEDS TO CHANGE
trueStage(2,:) = (stage2ByAge(ages) > rand(1,npts)) + 1;
%HERE TOO
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
%chance of dying at each age
mortMult = [1 1.23 1.23 1.49 1.76 1.76 2.34 1000] * 1.8; %xMortality multipliers, where DM alone is 1.8 x
%chance of dying at each stage, multiplied by the chance of dying just from
%diabetes alone
for year = 1:MAXYEARS
    %for every year
    for pt = 1:npts
        %for all patients
        if trueStage(1,pt) == STAGE_DEATH % XDon't do calculations on deceased patients X
            continue
        end
        if rand() < max(MortByAge(ages(pt)) * mortMult(trueStage(1,pt)),MortByAge(ages(pt)) * mortMult(trueStage(2,pt)))
            trueStage(1,pt) = STAGE_DEATH; % XUse both eyes to figure out increased mortality X
            continue
        end
        for eye = 1:2 %XRight eye = 1, left eye = 2 X
            %repeat for each eye
            examStage(eye,pt) = randsample(NSTAGES,1,true,sensSpec(trueStage(eye,pt),:)); % XApparent vs true stage of disease X
            %What does this actually do?
            if year >= lastScreened(pt) + screeningInt(pt)
                %if they are due for a screening
                lastScreened(pt) = year;
                %if it's within the year they were screened
                costs(pt) = costs(pt) + COST_SCREEN;
                %total cost is now including the cost of the screen because
                %they are getting a new screen
                if (examStage(eye,pt) == STAGE_PDR) && (hadScatter(eye,pt) == 0)
                    hadScatter(eye,pt) = 1;
                    %if p has PDR and has not had scatter for that eye,
                    %assign them to scatter
                    costs(pt) = costs(pt) + COST_SCATTER;
                    %cost of that p. now includes cost of scatter treatment
                elseif (examStage(eye,pt) == STAGE_ME) && (hadFocal(eye,pt) == 0)
                    hadFocal(eye,pt) = 1;
                    % if p has macular edema in that eye and has not had focal
                    % treatment, assign them to it
                    costs(pt) = costs(pt) + COST_FOCAL + COST_FA;
                    % cost of p now includes cost of focal laser treatment
                end
            end
            if hadScatter(eye,pt) == 0
                if hadFocal(eye,pt) == 0
                    % If eye has not had focal or scatter in past screen
                    trueStage(eye,pt) = randsample(NSTAGES,1,true,tpm(trueStage(eye,pt),:,TPM_NOPHOTOCOAG));
                    %then their true stage will change to that predicited
                    %in DiabetesSim for NOPHOTO
                else
                    trueStage(eye,pt) = randsample(NSTAGES,1,true,tpm(trueStage(eye,pt),:,TPM_FOCAL));
                    % If they have had not had scatter but have had focal
                    % then their true stage will change to that predicted
                    % by DiabetesSim for FOCAL treatment
                end
            else %X Eye has had scatter photocoagulation X
                if hadFocal(eye,pt) == 0
                    trueStage(eye,pt) = randsample(NSTAGES,1,true,tpm(trueStage(eye,pt),:,TPM_SCATTER));
                    %if they have had focal then true stage will change to
                    %that predicted by DS for Scatter
                else
                    trueStage(eye,pt) = randsample(NSTAGES,1,true,tpm(trueStage(eye,pt),:,TPM_SCATTERFOCAL));
                    %If they have had scatterfocal then true stage will
                    %change to that predicted by scatterfocal
                end
            end
        end %X Above is for each eye X
        worstEye = max(examStage(1,pt),examStage(2,pt)); 
        bestEye = min(examStage(1,pt),examStage(2,pt)); %Xestablish best and worst eyes X
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
