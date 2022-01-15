function cost = totalcost1(screen_urban, screen_MIZ1, screen_MIZ2, screen_MIZ3, screen_MIZ4)
total_DM_pop_urban = 240000;
total_DM_pop_MIZ1 = 40000;
total_DM_pop_MIZ2 = 25000;
total_DM_pop_MIZ3 = 21000;
total_DM_pop_MIZ4 = 9000;
%total number of people with DM in each area of Quebec
mean_annual_screen_prices = [100 200 400 800 1600; 75 150 300 600 1200; 150 200 250 300 350];
% 1st row is cost of 1 annual ophthalmologist screening, 2nd is optomotrist, 3rd is tele
% 1st column :,1 is urban. 2nd :,2 is MIZ1. 3rd :,3 is MIZ2, etc
SD_annual_screen_prices = [10 30 100 300 1000; 7.5 17 50 150 450; 15 20 30 35 45];
%apply estimated standard deviation to mean prices
actual_annual_screen_prices = SD_annual_screen_prices.*randn(3,5)+mean_annual_screen_prices;
actual_biannual_screen_prices = actual_annual_screen_prices.*.75;
%Cost of screening every other year. Same for every pop/screen type for now. 
mean_annual_screen_adherence = [0.5 0.45 0.4 0.35 0.25; 0.6 0.55 0.5 .45 .4; 0.6 0.6 0.55 0.55 0.5];
% 1st row is adherence of 1 annual ophthalmologist screening, 2nd is optomotrist, 3rd is tele
% 1st column :,1 is urban. 2nd :,2 is MIZ1. 3rd :,3 is MIZ2 etc etc
SD_annual_screen_adherence = [0.05 0.08 0.1 0.2 0.25; 0.05 0.05 0.1 0.15 0.25; 0.05 0.05 0.1 0.1 0.1];
%apply standard deviation to mean adherences
actual_annual_screen_adherence = SD_annual_screen_adherence.*randn(3,5)+mean_annual_screen_adherence;
actual_biannual_screen_adherence = actual_annual_screen_adherence.*1.25;
%adherence of screening every other year. Same for every pop/screen type for now. 
per_captial_annual_screen_cost_per_year = actual_annual_screen_adherence.*actual_annual_screen_prices;
%Some DM positive people don't always screen, don't count them towards cost
per_captial_annual_screen_cost_per_year = max(min(per_captial_annual_screen_cost_per_year,1000000),0);
%negative costs not possible
dataset({per_captial_annual_screen_cost_per_year 'urban','MIZ1','MIZ2','MIZ3','MIZ4'}, ...
              'obsnames', {'an_ophthalmologist','an_optomitrist','an_tele'})
%Name columns and rows so that MATLAB can spit out the names of the chosen
per_capita_biannual_screen_cost_per_year = actual_biannual_screen_adherence.*actual_biannual_screen_prices;
per_capita_biannual_screen_cost_per_year = max(min(per_capita_biannual_screen_cost_per_year,1000000),0);
dataset({per_capita_biannual_screen_cost_per_year 'urban','MIZ1','MIZ2','MIZ3','MIZ4'}, ...
              'obsnames', {'bi_ophthalmologist','bi_optomitrist','bi_tele'})
screen_urban = 1:1:3;
%give three options
options_annual_cost_urban = per_captial_annual_screen_cost_per_year(screen_urban,1);
options_biannual_cost_urban = per_capita_biannual_screen_cost_per_year(screen_urban,1);
%",1" specifices first column of matrix for urban-specific data
cost_urban = min([options_annual_cost_urban(:);options_biannual_cost_urban(:)]).*total_DM_pop_urban;
%choose the lowest cost screen option among both annual and biannual screens, multiply by population
screen_MIZ1 = 1:1:3; 
options_annual_cost_MIZ1 = per_captial_annual_screen_cost_per_year(screen_MIZ1,2);
options_biannual_cost_MIZ1 = per_capita_biannual_screen_cost_per_year(screen_MIZ1,2);
cost_MIZ1 = min([options_annual_cost_MIZ1(:);options_biannual_cost_MIZ1(:)]).*total_DM_pop_MIZ1;
screen_MIZ2 = 1:1:3;
options_annual_cost_MIZ2 = per_captial_annual_screen_cost_per_year(screen_MIZ2,3);
options_biannual_cost_MIZ2 = per_capita_biannual_screen_cost_per_year(screen_MIZ2,3);
cost_MIZ2 = min([options_annual_cost_MIZ2(:);options_biannual_cost_MIZ2(:)]).*total_DM_pop_MIZ2;
screen_MIZ3 = 1:1:3;
options_annual_cost_MIZ3 = per_captial_annual_screen_cost_per_year(screen_MIZ3,4);
options_biannual_cost_MIZ3 = per_capita_biannual_screen_cost_per_year(screen_MIZ3,4);
cost_MIZ3 = min([options_annual_cost_MIZ3(:);options_biannual_cost_MIZ3(:)]).*total_DM_pop_MIZ3;
screen_MIZ4 = 1:1:3;
options_annual_cost_MIZ4 = per_captial_annual_screen_cost_per_year(screen_MIZ4,5);
options_biannual_cost_MIZ4 = per_capita_biannual_screen_cost_per_year(screen_MIZ4,5);
cost_MIZ4 = min([options_annual_cost_MIZ4(:);options_biannual_cost_MIZ4(:)]).*total_DM_pop_MIZ4;
cost = cost_urban+cost_MIZ1+cost_MIZ2+cost_MIZ3+cost_MIZ4




