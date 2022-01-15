util = [1 1 1 1 1 1 .54 0]; % The mean utility values associated with each of the 8 stages
%All stages except blindness have no effect on utility
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
%probability of changing to next category with no treatment
%eg for line 4, people with stage 1 have 86.9% of staying at stage 1 and a
%13.1% chance of progressing to stage 2
tpm_scatter = [
    0.869	0.131         0         0         0         0         0 0;
    0       0.863	0.1310         0         0    0.0060         0  0;
    0       0       0.8630    0.1310         0    0.0060         0  0;
    0         0         0    0.8900    0.0800    0.0300         0   0;
    0         0         0         0    0.9800         0    0.0200   0;
    0         0         0         0         0    0.9500    0.0500   0;
    0         0         0         0         0         0    1.0000   0;
    0   0   0   0   0   0   0   1]; % chance of change with scatter laser?
tpm_focal = [
    0.869	0.131         0         0         0         0         0 0;
    0       0.863	0.1310         0         0    0.0060         0  0;
    0       0       0.8630    0.1310         0    0.0060         0  0;
    0         0         0    0.8900    0.0800    0.0300         0   0;
    0         0         0         0    0.9100         0    0.0900   0;
    0         0         0         0         0    0.9700    0.0300   0;
    0         0         0         0         0         0    1.0000   0;
    0   0   0   0   0   0   0   1]; % chance of change with focal laser
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
costsPerProc = [53 163 1490 1740]; %Costs of nothing, scatter, focal, scatterfocal
sensSpec =[0.905 0.05 0 0 0.003 0.21/5 0 0; % sensitivity for each stage
    0.22 0.731 0 0 0.02/3 0.21/5 0 0; %someone actually at stage 2, 22% chance they'll be diagnosed as stage 1, 73% for stage 2 etc.
    0.22 0 0.731 0 0.02/3 0.21/5 0 0;
    0.22 0 0 0.731 0.02/3 0.21/5 0 0;
    0.02 0.01 0.1 0.1 0.1 0.21/5 0 0;
    0.18/5 0.18/5 0.18/5 0.18/5 0.18/5 0.82 0 0;
    0 0 0 0 0 0 1 0;
    0 0 0 0 0 0 0 1]; %can definitely tell if someone is blind or dead
screenChoices = [1 2]; %2 screening choices, will change
nptChoices = [1000]; %assume 1000 patients?
for i = 1:length(screenChoices)
    %repeat for all screening options
    for j = 1:length(nptChoices)
        %repeat for all patients?
        for k = 1:3
            %repeat three times for accuracy?
            fprintf(1,'Screen=%d',screenChoices(i))
            fprintf(1,' npts=%d',nptChoices(j))
            costAndQaly = doMarkov(nptChoices(j),util,utilSD,tpm,costsPerProc,sensSpec,screenChoices(i));
            costs = costAndQaly(1,:);
            qalys = costAndQaly(2,:);
            fprintf(1, ' Cost QALY %.2f %.3f\n',sum(costs)/nptChoices(j),sum(qalys)/nptChoices(j))
        end
    end
end
