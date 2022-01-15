function costAndQALY1129
total_DM_pop_urban = 240000;
total_DM_pop_MIZ1 = 40000;
total_DM_pop_MIZ2 = 25000;
total_DM_pop_MIZ3 = 21000;
total_DM_pop_MIZ4 = 9000;
%total number of people with DM in each area of Quebec
mean_annual_screen_prices = [100 75 150; 200 150 200; 400 300 250; 800 600 300; 1600 1200 350];
% 1st column is cost of 1 annual ophthalmologist screening, 2nd is optomotrist, 3rd is tele
% 1st row :,1 is urban. 2nd :,2 is MIZ1. 3rd :,3 is MIZ2, etc
SD_annual_screen_prices = [10 7.5 15; 30 17 20; 100 50 30; 300 150 35; 1000 450 45];
mean_annual_screen_QALY = [5 4 3; 5 4 3; 5 4 3; 4.5 3.5 2.5; 4.5 3.5 2.5];
SD_annual_screen_QALY = [1 1.5 2; 1 1.5 2; 1 1.5 2; 1 1.5 2; 1 1.5 2];
%apply estimated standard deviation to mean prices
npts = 100;
for i = 1:size(SD_annual_screen_prices,2)
 for j = 1:length(mean_annual_screen_prices);
    for k = 1:npts%repeat number of patients
        cost(i,j) = SD_annual_screen_prices.*randn(5,3)+mean_annual_screen_prices;
        QALY(i,j) = SD_annual_screen_QALY.*randn(5,3)+mean_annual_screen_QALY;
    end
        if j == 1
            fprintf('Ophthalmologist\n');
        elseif j == 2
            fprintf('Optomotrist\n');
        elseif j == 3
            fprintf('Tele\n');
        end
        mean_cost = mean(cost(j,:));
        mean_QALY = mean(QALY(j,:));
        mean_cost_per_QALY = mean_cost/mean_QALY
        SD_cost = std(cost(j,:));
        SD_QALY = std(QALY(j,:));
        SD_cost_per_QALY = SD_cost/SD_QALY
    end
end



