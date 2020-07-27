%% Script to find the weekly proportion of orders, MPO and HPO by PCS - BF, 27/04/2020

%% Set user run parameters and date
% not included in file naming convention for ease of running full order
% scenario model

% user set version of run
run_version = '01';

% user set client
client = 'JLP';

% user set initials 
user_initials = 'BF';

% set user input file path
user_path = 'C:\Users\FPSScripting2\Documents\Consolidated_Models\OrderModelling\OrderVolumeScenarioGeneration';

% extract year and month of run
run_year = num2str(year(datetime(now, 'ConvertFrom','datenum')));
run_year = run_year(3:4);
run_month = num2str(month(datetime(now, 'ConvertFrom','datenum')));
if length(run_month) == 1
    run_month = strcat('0', run_month);
end
run_date = strcat(run_year, '-', run_month);

%% Set parameters

% specify input parameters
days_in_week = 7;

% the column number of variable "Postcode" in processed_order_data_required_PCS
post_code_column = 8;


%% Script begins

% read in the PCS with old and new store allocations 
PCS_store_allocations = readtable(fullfile(user_path, 'Step 1 - MPO_HPO_by_PCS\Inputs\catchment_areas_old_new.xlsx'));

% read cleaned order data with post code segments included
order_data_PCS = readtable(fullfile(user_path, 'Step 1 - MPO_HPO_by_PCS\Inputs\uniform_PC_order_data_ALL.csv'));

% read in the output of the data processing script
processed_order_data = readtable(fullfile(user_path, 'Step 1 - MPO_HPO_by_PCS\Inputs\historic_weekly_orders_MPO_HPO_by_PCS.csv'));

% find the unique weeks in the data
weeks_this_year = unique(week(order_data_PCS.Order_Delivery_Date));

% create empty array to store weekly network orders
weekly_network_orders = zeros(max(weeks_this_year),1);

% for each week
for iWeek = 1:max(weeks_this_year)
    this_week = weeks_this_year(iWeek);
    % find the total network orders which occured
%     this_week_data = order_data_PCS(ceil(day(order_data_PCS.Order_Delivery_Date, 'dayofyear')./days_in_week) == this_week,:);
    this_week_data = order_data_PCS(week(order_data_PCS.Order_Delivery_Date) == this_week,:);
    this_week_network_orders = height(this_week_data);
    % save to array
    weekly_network_orders(this_week,1) = this_week_network_orders;
end

% create table containing weekly network orders (weeks - rows, years - cols)
annual_weekly_volumes = array2table([1:max(weeks_this_year)]', 'VariableNames', {'Week'});
annual_weekly_volumes.Historic_Orders = weekly_network_orders;


% create output table to store stats
proportion_MPO_HPO_by_PCS = array2table(processed_order_data.Postcode, 'VariableNames', {'Postcode'});
proportion_MPO_HPO_by_PCS = innerjoin(proportion_MPO_HPO_by_PCS, PCS_store_allocations, 'Keys', 1);

% find the unique post code segments in the order data
unique_post_codes = unique(proportion_MPO_HPO_by_PCS.Postcode);

% create empty arrays 
repeated_weeks = [];
repeated_weekly_orders = [];

% replicate the weeks and weekly network orders as in annual_weekly_volumes
% to match height of proportion_MPO_HPO_by_PCS:
% for each postcode
for iPostcode = 1:length(unique_post_codes)
    % repeat the weeks and weekly network orders
    repeated_weeks = [repeated_weeks; ...
        annual_weekly_volumes.Week];
    repeated_weekly_orders = [repeated_weekly_orders; ...
        annual_weekly_volumes.Historic_Orders,];
end

% add the repeated week vector to the output table
proportion_MPO_HPO_by_PCS = addvars(proportion_MPO_HPO_by_PCS, repeated_weeks, 'Before', 'Postcode', 'NewVariableNames', {'Week'});

% remove not included post code sectors from processed_order_data
processed_order_data_required_PCS = processed_order_data(ismember(processed_order_data.Postcode, proportion_MPO_HPO_by_PCS.Postcode),:);

% sort rows by postcode to ensure same indexing of weeks
% (1,2,3,...53,1,2,3,...53,...) as in repeated_weekly_orders
processed_order_data_required_PCS = sortrows(processed_order_data_required_PCS, post_code_column);

% divide processed_order_data.Order by orders that week
proportion_MPO_HPO_by_PCS.ProportionOfTotalNetworkVolume = processed_order_data_required_PCS.Orders./repeated_weekly_orders;

% divide processed_order_data.MPO by processed_order_data.Order
proportion_MPO_HPO_by_PCS.HistoricMPO = processed_order_data_required_PCS.MPO./processed_order_data_required_PCS.Orders;

% divide processed_order_data.HPO by processed_order_data.Order
proportion_MPO_HPO_by_PCS.HistoricHPO = processed_order_data_required_PCS.HPO./processed_order_data_required_PCS.Orders;

% replace NaN values with 0s
proportion_MPO_HPO_by_PCS.HistoricMPO(isnan(proportion_MPO_HPO_by_PCS.HistoricMPO)) = 0;
proportion_MPO_HPO_by_PCS.HistoricHPO(isnan(proportion_MPO_HPO_by_PCS.HistoricHPO)) = 0;

% save the output tables to the output folder for this Step 1
writetable(proportion_MPO_HPO_by_PCS, fullfile(user_path, 'Step 1 - MPO_HPO_by_PCS\Outputs', 'PCS_stats_scenario_generation.xlsx'), 'Sheet', 'Proportion_HPO_MPO_by_PCS');
writetable(annual_weekly_volumes, fullfile(user_path, 'Step 1 - MPO_HPO_by_PCS\Outputs', 'PCS_stats_scenario_generation.xlsx'), 'Sheet', 'Annual_Weekly_Volumes');
writetable(PCS_store_allocations, fullfile(user_path, 'Step 1 - MPO_HPO_by_PCS\Outputs', 'PCS_stats_scenario_generation.xlsx'), 'Sheet', 'PCS_Store_Allocations');

% save the output tables to the input folder for Step 2
writetable(proportion_MPO_HPO_by_PCS, fullfile(user_path, 'Step 2 - Ratio_Distribution\Inputs', 'PCS_stats_scenario_generation.xlsx'), 'Sheet', 'Proportion_HPO_MPO_by_PCS');
writetable(annual_weekly_volumes, fullfile(user_path, 'Step 2 - Ratio_Distribution\Inputs', 'PCS_stats_scenario_generation.xlsx'), 'Sheet', 'Annual_Weekly_Volumes');
writetable(PCS_store_allocations, fullfile(user_path, 'Step 2 - Ratio_Distribution\Inputs', 'PCS_stats_scenario_generation.xlsx'), 'Sheet', 'PCS_Store_Allocations');


% save the output tables to the input folder for Step 3
writetable(proportion_MPO_HPO_by_PCS, fullfile(user_path, 'Step 3 - Scenario_Generation\Inputs', 'PCS_stats_scenario_generation.xlsx'), 'Sheet', 'Proportion_HPO_MPO_by_PCS');
writetable(annual_weekly_volumes, fullfile(user_path, 'Step 3 - Scenario_Generation\Inputs', 'PCS_stats_scenario_generation.xlsx'), 'Sheet', 'Annual_Weekly_Volumes');
writetable(PCS_store_allocations, fullfile(user_path, 'Step 3 - Scenario_Generation\Inputs', 'PCS_stats_scenario_generation.xlsx'), 'Sheet', 'PCS_Store_Allocations');

%%%%%%%%%%%%%%%%%% CODE ENDS %%%%%%%%%%%%%%%%%%%