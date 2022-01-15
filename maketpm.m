function tpm = maketpm(morbidityIndex,hadScatter,hadFocal)
% maketpm creates a transition probability matrix
% morbidityindex ranges from 0 to 10 and indicates how likely the patient is
% to progress their retinopathy, with 1 being baseline, 0 being minimal pr, and 10 being maximal
% hadScatter is a boolean TRUE or FALSE and indicates whether there was scatter laser 
% hadFocal is a boolean TRUE or FALSE and indicates whether there was focal laser 

NSTAGES = 8;
%% Baseline tpm - from Cost-Utility Analysis of Screening Intervals for Diabetic Retinopathy in Patients
% With Type 2 Diabetes Mellitus and using recalculated data from DRS #8
tpmBaseline = [
    0.8690 0.1310 0.0000 0.0000 0.0000 0.0000 0.0000 0.0000;
    0.0000 0.8630 0.1310 0.0000 0.0000 0.0060 0.0000 0.0000;
    0.0000 0.0000 0.8630 0.1310 0.0000 0.0060 0.0000 0.0000;
    0.0000 0.0000 0.0000 0.8900 0.0800 0.0300 0.0000 0.0000;
    0.0000 0.0000 0.0000 0.0000 0.9250 0.0000 0.0750 0.0000;
    0.0000 0.0000 0.0000 0.0000 0.0000 0.9500 0.0500 0.0000;
    0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 1.0000 0.0000;
    0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 1.0000];

if (morbidityIndex < 0 || morbidityIndex > 10)
    error('Bad morbidity %f',morbidityIndex);
    stop
end

%The APPLYMORBIDITY matrix adjusts each of the transitions that go from one stage to a greater
%stage by a factor that depends on the morbidityIndex argument. At the
%end the diagonal has to be normalized so that the rows sum to 1
m = morbidityIndex; % Just to make the array easier to write out

APPLYMORBIDITY = [
    1 m 1 1 1 1 1 1;
    1 1 m 1 1 m 1 1;
    1 1 1 m 1 m 1 1;
    1 1 1 1 m m 1 1;
    1 1 1 1 1 1 m 1;
    1 1 1 1 1 1 m 1;
    1 1 1 1 1 1 1 1;
    1 1 1 1 1 1 1 1];


%The APPLYSCATTER matrix adjusts the tpm for the effects of scatter, by decreasing
%the likelihood of progression from PDR to blindness per year by a factor of 0.222
%(taken from same source as original tpm data. Like all of these functions,
%the diagonal must be subsequently adjusted so each row adds to 1.

APPLYSCATTER = [
1 1 1 1 1 1 1 1;
1 1 1 1 1 1 1 1;
1 1 1 1 1 1 1 1;
1 1 1 1 1 1 1 1;
1 1 1 1 1 1 0.4 1;
1 1 1 1 1 1 1 1;
1 1 1 1 1 1 1 1;
1 1 1 1 1 1 1 1];
% 
%The APPLYFOCAL matrix adjusts the tpm for the effects of scatter, by decreasing
%the likelihood of progression from ME to blindness by a factor of 0.6
%(taken from same source as original tpm data. Like all of these functions,
%the diagonal must be subsequently adjusted so each row adds to 1.

APPLYFOCAL = [
1 1 1 1 1 1 1 1;
1 1 1 1 1 1 1 1;
1 1 1 1 1 1 1 1;
1 1 1 1 1 1 1 1;
1 1 1 1 1 1 1 1;
1 1 1 1 1 1 0.6 1;
1 1 1 1 1 1 1 1;
1 1 1 1 1 1 1 1];

tpm = min(tpmBaseline .* APPLYMORBIDITY,ones(NSTAGES));
if (hadScatter)
    tpm = tpm .* APPLYSCATTER;
end
if (hadFocal)
    tpm = tpm .* APPLYFOCAL;
end
%Now normalize tpm
tpm = tpm - diag(sum(tpm,2)-1); % We add up each row, subtract 1, make a matrix with those values on the diagonal, and subtract
if size(tpm) ~= [8 8]
    'tpm error'
end
end

