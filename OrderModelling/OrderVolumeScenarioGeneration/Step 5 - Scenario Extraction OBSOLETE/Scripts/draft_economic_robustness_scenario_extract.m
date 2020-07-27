%% Extract scenarios based on annual volume for economic robustness test of solution - BF, 05/05/2020

% set user input file path
user_path = 'C:\Users\FPSScripting2\Documents\Consolidated_Models\Vehicle_Modelling\Order_Volume_Scenario_Generation';

% read in scenarios
% daily_scenarios_table = readtable(fullfile(user_path, 'Step 5 - Scenario Extraction\Inputs\scenarios_daily_values_13-May-2020.csv'));
daily_scenarios_table = readtable(fullfile(user_path, 'Step 5 - Scenario Extraction\Inputs\scenarios_daily_values_1728_scenarios_15-May-2020.csv'));


% find the unique store IDs for which scenarios were generated
unique_stores = unique(daily_scenarios_table.Store_ID);

% find number of weeks in the 
numb_weeks = max(unique(daily_scenarios_table.Week));

% set the desired min and max percentiles
min_prctile = 0.01;
max_prctile = 0.99;

% find number of scenarios
numb_scenarios = length(unique(daily_scenarios_table.Scenario));

% array for annual order by scenario
annual_volume_by_sim = zeros(numb_scenarios, 2);

% for each scenario
for iSim = 1:numb_scenarios
    clc
    disp(iSim)
    this_scenario_daily = daily_scenarios_table(daily_scenarios_table.Scenario == iSim, :);
    annual_volume_by_sim(iSim, 1) = iSim;
    % find total yearly orders
    annual_volume_by_sim(iSim, 2) = sum(this_scenario_daily.Orders);
end

% sort in order 
annual_volume_by_sim = sortrows(annual_volume_by_sim, 2);

% if desired min prctile * number of scenarios returns 0 when
% rounded, round up, else round as normal
if round(min_prctile*numb_scenarios) == 0
    low_scenario_orders = annual_volume_by_sim(ceil(min_prctile*numb_scenarios), :);
else
    low_scenario_orders = annual_volume_by_sim(round(min_prctile*numb_scenarios), :);
end
% if desired max prctile * number of scenarios returns 0 when
% rounded, round down, else round as normal
if round(max_prctile*numb_scenarios) == length(annual_volume_by_sim)
    high_scenario_orders = annual_volume_by_sim(floor(max_prctile*numb_scenarios), :);
else
    high_scenario_orders = annual_volume_by_sim(round(max_prctile*numb_scenarios), :);
end

histogram(annual_volume_by_sim(:,2))