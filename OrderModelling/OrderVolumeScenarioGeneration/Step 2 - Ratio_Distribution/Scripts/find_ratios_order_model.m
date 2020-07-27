%% Script to find historic order ratios and those to be used for model - BF, 27/04/2020

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

% set flag to use old PCS allocations
use_old_allocations = 1;

% set historic year 
historic_year = 2019;

% input the focus stores
focus_stores = [122 213 215 226 227 457 494 513 531 605 656 663 690 721 753 828];

% specify input parameters
days_in_week = 7;
complete_weeks_in_year = 52;
final_day_of_year = 1;
include_partial_week = 1; % if including week 53, set to 1
friday_int = 6; % day of week corresponding to Friday
normal_weeks = [2:30, 32:43, 52];

%% Script begins

% % read in cleaned order data with post code segments included
% order_data_PCS = readtable(fullfile(user_path, 'Step 2 - Ratio_Distribution\Inputs\uniform_PC_order_data_ALL.csv'));

% load in MPO and HPO by PCS with store allocations
MPO_HPO_by_PCS = readtable(fullfile(user_path, 'Step 2 - Ratio_Distribution\Inputs\PCS_stats_scenario_generation.xlsx'), 'Sheet', 'Proportion_HPO_MPO_by_PCS');

% if using old store allocations, remove previously unserved postcodes
if use_old_allocations == 1
    try
        MPO_HPO_by_PCS(strcmp(MPO_HPO_by_PCS.OldStore, 'not yet covered'),:) = [];
        MPO_HPO_by_PCS.OldStore = str2double(MPO_HPO_by_PCS.OldStore); 
    catch
    end
    MPO_HPO_by_PCS(isnan(MPO_HPO_by_PCS.OldStore),:) = [];
end

% join the OldStore allocations to the order data, and filter out the required historic data 
order_data_PCS_joined = movevars(order_data_PCS,'Post_code_split','Before','Route_ID');
MPO_HPO_by_PCS_reduced = MPO_HPO_by_PCS(:,[2 4]);
MPO_HPO_by_PCS_reduced = unique(MPO_HPO_by_PCS_reduced, 'rows');
order_data_PCS_joined_2 = innerjoin(order_data_PCS_joined, MPO_HPO_by_PCS_reduced, 'Keys', 1);
order_data_PCS_historic = order_data_PCS_joined_2(year(order_data_PCS_joined_2.Order_Delivery_Date) == historic_year, :);


% total number of weeks to find ratios for
numb_weeks_this_year = complete_weeks_in_year+include_partial_week;
weeks_this_year = 1:complete_weeks_in_year;

% infer special weeks 
special_weeks = setdiff(weeks_this_year, normal_weeks);

% create empty arrays to store stats
std_day = zeros(length(focus_stores),days_in_week);
mean_day = zeros(length(focus_stores),days_in_week);
avg_weekly_by_store = zeros(length(focus_stores),1);

store_IDs = zeros(length(focus_stores)*numb_weeks_this_year,1);
store_week_num = zeros(length(focus_stores)*numb_weeks_this_year,1);
store_historic_orders = zeros(length(focus_stores)*numb_weeks_this_year,1);
store_historic_ratios = zeros(length(focus_stores)*numb_weeks_this_year,days_in_week);
store_model_ratios = zeros(length(focus_stores)*numb_weeks_this_year,days_in_week);
store_JLP_ratios = zeros(length(focus_stores)*numb_weeks_this_year,days_in_week);

% for each of the focus stores
for iStore = 1:length(focus_stores)
    % find this store ID and extract data
    this_store = focus_stores(iStore);
    if use_old_allocations == 1
        this_store_data = order_data_PCS_historic(order_data_PCS_historic.OldStore == this_store, :);
    else
        this_store_data = order_data_PCS_historic(order_data_PCS_historic.NewStore == this_store, :);
    end
    % create empty arrays to store stats
    weekly_ratios = zeros(numb_weeks_this_year, days_in_week);
    weekly_orders = zeros(numb_weeks_this_year, 1);
    % for each week
    for iWeek = 1:numb_weeks_this_year
        % set variable for code clarity and extract data
        this_week = iWeek;
%         this_week_data = this_store_data(ceil(day(this_store_data.Order_Delivery_Date, 'dayofyear')./days_in_week) == this_week, :);
        this_week_data = this_store_data(week(this_store_data.Order_Delivery_Date) == this_week, :);
        orders_by_day = zeros(days_in_week,1);
        % for each day in the week
        for iDay = 1:days_in_week
            % set variable for code clarity and extract data
            this_day = iDay;
            this_day_data = this_week_data(weekday(this_week_data.Order_Delivery_Date) == this_day, :);
            % find orders this day
            orders_this_day = height(this_day_data);
            orders_by_day(this_day,1) = orders_this_day;
        end
        % save stats
        orders_this_week = height(this_week_data);
        ratios_this_week = orders_by_day./orders_this_week;
        weekly_ratios(iWeek, :) = ratios_this_week;
        weekly_orders(iWeek,1) = orders_this_week;
    end
    % find the average daily ratios for the normal weeks
    normal_week_avg_ratios = mean(weekly_ratios(normal_weeks,:),1);
    % find the appropriate indexing for this loop 
    indexing = 1+(iStore-1)*numb_weeks_this_year:iStore*numb_weeks_this_year;
    % save stats
    store_IDs(indexing) = this_store;
    store_week_num(indexing) = 1:(complete_weeks_in_year + include_partial_week);
    store_historic_orders(indexing) = weekly_orders;
    store_historic_ratios(indexing, :) = weekly_ratios;
    store_model_ratios(indexing,:) = weekly_ratios;
    % set normal week ratios to be the same
    store_model_ratios(indexing(normal_weeks), :) = repmat(normal_week_avg_ratios,length(normal_weeks),1);
end

% find ratios as measured by JLP
store_JLP_ratios(:,friday_int) = 1./(days_in_week.*store_model_ratios(:,friday_int));
store_JLP_ratios(:,setdiff(1:days_in_week,6)) = (store_model_ratios(:,setdiff(1:days_in_week,6)).*store_historic_orders)./...
    sum(store_model_ratios(:,setdiff(1:days_in_week,6)).*store_historic_orders, 2);

% construct output table
output_ratios_table = array2table(store_week_num, 'VariableNames', {'Week'});
output_ratios_table.Store_ID = store_IDs;
output_ratios_table.store_historic_orders = store_historic_orders;
output_ratios_table.store_historic_ratios = store_historic_ratios;
output_ratios_table.store_model_ratios = store_model_ratios;
output_ratios_table.store_JLP_ratios = store_JLP_ratios;

% save the output table to the output folder for Step 2
writetable(output_ratios_table, fullfile(user_path, 'Step 2 - Ratio_Distribution\Outputs\scenario_generation_daily_ratios.csv'));

% save the output table to the input folder for Step 3
writetable(output_ratios_table, fullfile(user_path, 'Step 3 - Scenario_Generation\Inputs\scenario_generation_daily_ratios.csv'));
