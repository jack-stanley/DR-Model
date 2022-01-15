function rvect = randomize(vect,SD,lowerlim,upperlim,lowerSD,upperSD,singlerand)
% Takes a vector and a SD, and returns a vector where each element is
% randomized based on the amount of the SD. 
% Elements are constrained between lowerlim and upperlim.
% The amount of change is constrained by lowerSD and upperSD.
% If singlerand is true, then a single random number is used for the whole
% vector. If false, then each element is independently randomized.

if singlerand
    rvect = min(upperlim,max(lowerlim,vect + vect * min(upperSD,max(lowerSD,randn() * SD)))); 
else
    rvect = min(upperlim,max(lowerlim,vect + vect .* (min(upperSD,max(lowerSD,randn(size(vect)) * SD))))); 
end

