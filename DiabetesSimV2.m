util = [1 1 1 1 1 1 .54 0]; % The mean utility values associated with each of the 8 stages
utilSD = [0 0 0 0 0 0 .17 0]; % The SD of the utility values by stage
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
costsPerProc = [53 163 1490 1740]; %Costs of screen, FA, focal laser, scatter laser
sensSpec =[0.905 0.05 0 0 0.003 0.21/5 0 0;
    0.22 0.731 0 0 0.02/3 0.21/5 0 0;
    0.22 0 0.731 0 0.02/3 0.21/5 0 0;
    0.22 0 0 0.731 0.02/3 0.21/5 0 0;
    0.02 0.01 0.1 0.1 0.1 0.21/5 0 0;
    0.18/5 0.18/5 0.18/5 0.18/5 0.18/5 0.82 0 0;
    0 0 0 0 0 0 1 0;
    0 0 0 0 0 0 0 1];
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
% chance of dying at each age
mortMult = [1 1.23 1.23 1.49 1.76 1.76 2.34 1000] * 1.8; %xMortality multipliers, where DM alone
% is 1.8 x chance of dying at each stage, multiplied by the chance of dying just from diabetes alone
screenChoices = [1 2];
nptChoices = [10000];
for i = 1:length(screenChoices)
    for j = 1:length(nptChoices)
        for k = 1:3
            fprintf(1,'Screen=%d',screenChoices(i))
            fprintf(1,' npts=%d',nptChoices(j))
            costAndQaly = doMarkov(nptChoices(j),util,utilSD,tpm,costsPerProc,sensSpec,screenChoices(i));
            costs = costAndQaly(1,:);
            qalys = costAndQaly(2,:);
            fprintf(1, ' Cost QALY %.2f %.3f\n',sum(costs)/nptChoices(j),sum(qalys)/nptChoices(j))
        end
    end
end
