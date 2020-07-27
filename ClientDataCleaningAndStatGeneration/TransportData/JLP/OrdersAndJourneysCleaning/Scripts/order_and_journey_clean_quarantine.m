%% Script to clean Waitrose route and order data - BF 09/04/2020
% Based on user input thresholds and other checks, finds rows for orders and
% routes which should be quarantined, then saves cleaned data and
% quarantined data as separate csvs

%% Set user run parameters and date

% user set version of run
run_version = '01';

% user set client
client = 'JLP';

% user set initials 
user_initials = 'BF';

% set user input file path
user_path = 'C:\Users\FPSScripting2\Documents\Consolidated_Models\ClientDataCleaningAndStatGeneration\TransportData\JLP\OrdersAndJourneysCleaning';

% extract year and month of run
run_year = num2str(year(datetime(now, 'ConvertFrom','datenum')));
run_year = run_year(3:4);
run_month = num2str(month(datetime(now, 'ConvertFrom','datenum')));
if length(run_month) == 1
    run_month = strcat('0', run_month);
end
run_date = strcat(run_year, '-', run_month);

%% Script begins

% load in the collated route data and order data
route_data = readtable(fullfile(user_path, 'Inputs\collated_route_data_all.csv')); 
order_data = readtable(fullfile(user_path, 'Inputs\collated_order_data_all.csv'));

% start timer 
tic

% try deleting an unnecessary Var1 from the input datasets
try
    route_data.Var1 = [];
catch
end

try
    order_data.Var1 = [];
catch 
end

% set the default values for the cleaning thresholds
max_route_duration_def = 12;
min_route_mileage_def = 0;
max_speed_def = 50;
max_mileage_percentile_def = 99.75;

% prompt users for alternative values for cleaning thresholds if desired
input('Please enter input values as requested. Press return key to use default.\n(Press enter when you have finished reading this message)')

max_route_duration = input('Quarantine threshold for maximum route time in hours: default = 12 hrs.\nUser input = ')
if isempty(max_route_duration)
    max_route_duration = max_route_duration_def
end

min_route_mileage = input('Quarantine threshold for minimum route mileage in miles: default = 0 miles.\nUser input = ')
if isempty(min_route_mileage)
    min_route_mileage = min_route_mileage_def
end

max_speed = input('Quarantine threshold for maximum speed in mph: default = 50 mph.\nUser input = ')
if isempty(max_speed)
    max_speed = max_speed_def
end

max_mileage_percentile = input('Quarantine threshold for planned route mileage as percentile: default = 99.75th percentile.\nUser input = ')
if isempty(max_mileage_percentile)
    max_mileage_percentile = max_mileage_percentile_def
end


%% remove all non-duplicate quarantine routes 

% 1. Date range completeness check - assess how many dates exist between the data date range
% take first and last dates of whole file, check to see which days exist.
start_date = min(route_data.Start_Date_of_Route);
end_date = max(route_data.Start_Date_of_Route);
[h,m,s] = hms(floor(end_date - start_date));
possible_dates = linspace(start_date, end_date, floor((h+(m+s/60)/60))/24+1);
unique_dates = unique(route_data.Start_Date_of_Route);
missing_dates = setdiff(possible_dates,unique_dates);
perc_missing = numel(missing_dates)/numel(possible_dates);


% 2. Storage level date range completeness checks - for each branch ID,
% check the range of dates, the percentage of dates out of the possible
% total, and any missing dates

% generate stat for first and last day in date range for each store, and
% any missing days for each store
unique_Branch_IDs = unique(route_data.Branch_ID);
n_branch_data_stats = 5;
branch_date_stats = cell(length(unique_Branch_IDs), n_branch_data_stats);
for i = 1:length(unique_Branch_IDs)
    branch_date_stats{i, 1} = unique_Branch_IDs(i);
    branch_data = route_data(route_data.Branch_ID == unique_Branch_IDs(i),:);
    branch_start_date = min(branch_data.Start_Date_of_Route);
    branch_date_stats{i, 2} = branch_start_date;
    branch_end_date = max(branch_data.Start_Date_of_Route);
    branch_date_stats{i, 3} = branch_end_date;
    branch_unique_dates = unique(branch_data.Start_Date_of_Route);
    branch_missing_dates = setdiff(possible_dates,branch_unique_dates);
    branch_perc_missing = numel(branch_missing_dates)/numel(possible_dates);
    branch_date_stats{i, 4} = branch_perc_missing;
    branch_date_stats{i, 5} = branch_missing_dates;
end

branch_date_stats = branch_date_stats';

% 3. Route start/end time feasible values check - removes any rows with a
% route start time after the end time
start_times = route_data.Start_Time_of_Route;
end_times = route_data.End_Time_of_Route;
minutes_start = start_times.Hour*60 + start_times.Minute;
minutes_end = end_times.Hour*60 + end_times.Minute;
times_rows = find(minutes_start<minutes_end);
route_cleaned_data_4 = route_data(times_rows,:);
quarantine_route_unfeasible = route_data(setdiff(1:height(route_data), times_rows),:);

% 4. Route duration < shift length checks - removes rows where implied
% shift length is greater than a user input threshold
% shouldn't go over e.g. 12 hrs, user input

max_route_duration = duration(max_route_duration,00,00);
feasible_rows = find(route_cleaned_data_4.End_Time_of_Route - route_cleaned_data_4.Start_Time_of_Route < max_route_duration);
route_cleaned_data_5 = route_cleaned_data_4(feasible_rows,:);
quarantine_route_shift_length = route_cleaned_data_4(setdiff(1:height(route_cleaned_data_4), feasible_rows),:);

% 5. Crate volumes within specification limits check - removes rows ehere

over_weight = find(route_cleaned_data_5.Percentage_Van_Weight_used>1);
quarantine_route_over_weight = route_cleaned_data_5(over_weight,:);

weight_rows = setdiff(1:height(route_cleaned_data_5), over_weight);
route_cleaned_data_6 = route_cleaned_data_5(weight_rows,:);


% 6. Route mileage > 0 check - removes rows which have a planned route
% mileage of 0
% check Planned_route_Mileage

mileage_rows = find(route_cleaned_data_6.Planned_total_Mileage>min_route_mileage);
route_cleaned_data_7 = route_cleaned_data_6(mileage_rows,:);
quarantine_route_mileage = route_cleaned_data_6(setdiff(1:height(route_cleaned_data_6), mileage_rows),:);

% 7. Route mileage implied avg speed < 50mph check - removes rows where the
% implied route mileage was above a user threshold

start_times = route_cleaned_data_7.Start_Time_of_Route;
end_times = route_cleaned_data_7.End_Time_of_Route;
minutes_start = start_times.Hour*60 + start_times.Minute;
minutes_end = end_times.Hour*60 + end_times.Minute;

speed_rows = find(route_cleaned_data_7.Planned_total_Mileage./((minutes_end - minutes_start)/60)<max_speed);
route_cleaned_data_8 = route_cleaned_data_7(speed_rows,:);
quarantine_route_speed = route_cleaned_data_7(setdiff(1:height(route_cleaned_data_7), speed_rows),:);

% 8. Percentile filtering based on high mileages - filters journeys above a
% certain mileage percentile based on a user threshold

perc_val = prctile(route_cleaned_data_8.Planned_total_Mileage, max_mileage_percentile);
perc_rows = find(route_cleaned_data_8.Planned_total_Mileage < perc_val);
route_cleaned_data_9 = route_cleaned_data_8(perc_rows,:);
quarantine_route_mileage_percentile = route_cleaned_data_8(setdiff(1:height(route_cleaned_data_8), perc_rows),:);

% 9. Create clean data file and quarantine data file


quarantined_route_data = [quarantine_route_unfeasible; quarantine_route_shift_length;...
    quarantine_route_mileage; quarantine_route_over_weight; quarantine_route_speed; quarantine_route_mileage_percentile];


% remove clean orders based on quarantined routes
unique_removedroutes_routes = unique(quarantined_route_data.Route_ID);
rows_route_ID = [];
order_routes_IDs = order_data.Route_ID;

parfor i = 1:length(unique_removedroutes_routes)
    quarantine_route_rows = find(order_routes_IDs==unique_removedroutes_routes(i));
    rows_route_ID = [rows_route_ID; quarantine_route_rows];
end

quarantine_order_removed_route_0 = order_data(rows_route_ID,:);
order_cleaned_data_0 = order_data(setdiff(1:height(order_data),rows_route_ID),:);


% 10. Remove duplicates - removes any repeated Route_IDs and associated rows
[unique_Route_ID, rows_Route_ID] = unique(route_cleaned_data_9.Route_ID,'rows', 'stable');
route_cleaned_data_0 = route_cleaned_data_9(rows_Route_ID,:);
quarantine_route_duplicate_rows = route_cleaned_data_9(setdiff(1:height(route_cleaned_data_9),rows_Route_ID),:);

quarantined_route_data = [quarantine_route_duplicate_rows; quarantined_route_data];

% remove associated (duplicate) orders - change: find unique orders removed and add back in after

% remove clean orders based on duplicated routes
unique_removedroutes_routes = unique(quarantine_route_duplicate_rows.Route_ID);
rows_route_ID = [];
order_routes_IDs = order_cleaned_data_0.Route_ID;

for i = 1:length(unique_removedroutes_routes)
    quarantine_route_rows = find(order_routes_IDs==unique_removedroutes_routes(i));
    rows_route_ID = [rows_route_ID; quarantine_route_rows];
end

quarantine_order_removed_route_1 = order_cleaned_data_0(rows_route_ID,:);

[to_add_back_quarantine_order_removed_route_1, ia, ic] = unique(quarantine_order_removed_route_1, 'rows', 'stable'); % unique orders which are associated with duplicate journeys
to_remove_quarantine_order_removed_route_1 = quarantine_order_removed_route_1(setdiff(1:height(quarantine_order_removed_route_1),ia),:); % orders which are duplicated and are 
% associated with duplicate journeys -> require adding back to clean data

quarantine_order_removed_route_1 = to_remove_quarantine_order_removed_route_1; 
order_cleaned_data_1 = order_cleaned_data_0(setdiff(1:height(order_cleaned_data_0),rows_route_ID),:);
order_cleaned_data_1 = [order_cleaned_data_1; to_add_back_quarantine_order_removed_route_1]; % add back in one instance of each removed duplicate orders

% 10. Remove duplicates - removes any repeated Order_IDs and associated rows
[unique_Order_ID, rows_Order_ID] = unique(order_cleaned_data_1.Order_ID, 'rows', 'stable');
order_cleaned_data_check_dup = order_cleaned_data_1(rows_Order_ID,:);
quarantine_order_duplicate_rows = order_cleaned_data_1(setdiff(1:height(order_cleaned_data_1),rows_Order_ID),:);

quarantined_order_data = [quarantine_order_duplicate_rows; quarantine_order_removed_route_0; to_remove_quarantine_order_removed_route_1];

% 11. save files

quarantine_route_reason = cell(height(quarantined_route_data), 1);
quarantine_route_reason(1:height(quarantine_route_duplicate_rows), 1) = {'duplicate'};
tmp = height(quarantine_route_duplicate_rows);
quarantine_route_reason(1+tmp:tmp+height(quarantine_route_unfeasible), 1) = {'unfeasible_start_end'};
tmp = tmp+height(quarantine_route_unfeasible);
quarantine_route_reason(1+tmp:tmp+height(quarantine_route_shift_length), 1) = {'unfeasible_shift_length'};
tmp = tmp+height(quarantine_route_shift_length);
quarantine_route_reason(1+tmp:tmp+height(quarantine_route_mileage), 1) = {'zero_mileage'};
tmp = tmp+height(quarantine_route_mileage);
quarantine_route_reason(1+tmp:tmp+height(quarantine_route_over_weight), 1) = {'over_weight'};
tmp = tmp+height(quarantine_route_over_weight);
quarantine_route_reason(1+tmp:tmp+height(quarantine_route_speed), 1) = {'speed'};
tmp = tmp+height(quarantine_route_speed);
quarantine_route_reason(1+tmp:tmp+height(quarantine_route_mileage_percentile), 1) = {'unfeasible_mileage'};
quarantined_route_data = addvars(quarantined_route_data, quarantine_route_reason);


% create order table with reason quarantined and save as csv
quarantine_order_reason = cell(height(quarantined_order_data), 1);
quarantine_order_reason(1:height(quarantine_order_duplicate_rows), 1) = {'duplicate'};
tmp = height(quarantine_order_duplicate_rows);
quarantine_order_reason(1+tmp:tmp+height(quarantine_order_removed_route_0), 1) = {'removed_route_threshold'};
tmp = tmp + height(quarantine_order_removed_route_0);
quarantine_order_reason(1+tmp:tmp+height(quarantine_order_removed_route_1), 1) = {'removed_route_duplicate'};
quarantined_order_data = addvars(quarantined_order_data, quarantine_order_reason);


% clearvars -except route_cleaned_data_0 order_cleaned_data_1 quarantined_route_data quarantined_order_data

writetable(route_cleaned_data_0, fullfile(user_path, 'Outputs', strcat(run_date, '.', client, '.', 'cleaned_route_data', '.', run_version, '.', user_initials, '.csv')));
% clearvars route_cleaned_data_0

writetable(order_cleaned_data_check_dup, fullfile(user_path, 'Outputs', strcat(run_date, '.', client, '.', 'cleaned_order_data', '.', run_version, '.', user_initials, '.csv')));
% clearvars order_cleaned_data_check_dup

writetable(quarantined_route_data, fullfile(user_path, 'Outputs', strcat(run_date, '.', client, '.', 'quarantined_route_data', '.', run_version, '.', user_initials, '.csv')));
% clearvars quarantined_route_data

writetable(quarantined_order_data, fullfile(user_path, 'Outputs', strcat(run_date, '.', client, '.', 'quarantined_order_data', '.', run_version, '.', user_initials, '.csv')));
% clearvars quarantined_order_data

% end timer
toc

%% check all stores present in both data sets

% note: run on 2019 cleaned data took 18 minutes to generate stats outputs

% start timer
tic

% rename output cleaned datasets for clarity
cleaned_route_data_all = route_cleaned_data_0;
cleaned_order_data_all = order_cleaned_data_check_dup;

% extract route ID and store ID from route data set
route_store_ID_table = route_cleaned_data_0(:,[1 2]);

% match store ID by route ID in order dataset
cleaned_order_data_all = innerjoin(cleaned_order_data_all, route_store_ID_table, 'Keys', 1);

% create a table showing for which stores data is present in route data
Store_ID = unique(cleaned_route_data_all.Branch_ID);
ExistsInJourneyData = cell(length(Store_ID),1);
ExistsInJourneyData(:,:) = {'Present'};
Tleft = table(Store_ID, ExistsInJourneyData);

% create a table showing for which stores data is present in order data
Store_ID = unique(cleaned_order_data_all.Branch_ID);
ExistsInOrderData =  cell(length(Store_ID),1);
ExistsInOrderData(:,:) = {'Present'};
Tright = table(Store_ID, ExistsInOrderData);

% perform outerjoin to show for which stores data is not present in one
% dataset
store_ID_check_table = outerjoin(Tleft,Tright,'MergeKeys',true);

% save table to worksheet
writetable(store_ID_check_table, fullfile(user_path, 'Outputs', strcat(run_date, '.', client, '.', 'output_postclean_stats', '.', run_version, '.', user_initials, '.xlsx')), 'Sheet', 'store_ID_check');

%% produce output worksheet for checking orders (order data vs journey data) match by store and year

% find only the common stores between the datasets
store_ID_intersection = innerjoin(Tleft,Tright, 'Keys', 1);
common_stores = unique(store_ID_intersection.Store_ID);

% create empty arrays to store stats
order_number_comparison_store =  zeros(1,1);
order_number_comparison_year = zeros(1,1);
order_number_comparison_values = zeros(1,3);

% initialise index for loop iterations
indx = 1;

% on a yearly basis:
% for each of the common stores
for iStore = 1:length(common_stores)
    % find the store ID and relevant route and order data
    this_store = common_stores(iStore);
    this_store_route = cleaned_route_data_all(cleaned_route_data_all.Branch_ID == this_store,:);
    this_store_orders = cleaned_order_data_all(cleaned_order_data_all.Branch_ID == this_store,:);
    % find the unique years in the route data for this store
    unique_years = unique(year(this_store_route.Start_Date_of_Route));
    % for each of those years
    for iYear = 1:length(unique_years)
        % find the year and relevant route and order data
        this_year = unique_years(iYear);
        this_year_route = this_store_route(year(this_store_route.Start_Date_of_Route) == this_year,:);
        this_year_orders = this_store_orders(year(this_store_orders.Order_Delivery_Date) == this_year,:);
%         find the number of orders in the relevant order data
        orderset_orders = height(this_year_orders);
%         sum the number of orders in the relevant journey data
        journeyset_orders = sum(this_year_route.Number_Orders);
%         find the percentage difference in number of orders relative to
%         journeyset orders
        percentagediff_orders = ((journeyset_orders - orderset_orders)/journeyset_orders)*100;
%         save store to cell
        order_number_comparison_store(indx,1) = this_store;
%         save year to cell
        order_number_comparison_year(indx,1) = this_year;
%         save order nuymber stats to cells
        order_number_comparison_values(indx,1) = journeyset_orders;
        order_number_comparison_values(indx,2) = orderset_orders;
        order_number_comparison_values(indx,3) = percentagediff_orders;
        % iterate loop counter
        indx = indx + 1;
    end
end

% create table with order number stats
annual_order_check_table = table(order_number_comparison_store, order_number_comparison_year, order_number_comparison_values(:,1), ...
    order_number_comparison_values(:,2), order_number_comparison_values(:,3));
annual_order_check_table.Properties.VariableNames = {'Store_ID', 'Year', 'Orders_in_Journeyset', 'Orders_in_OrderSet', 'Percentage_Difference_relative_to_JourneySet'};

% write table to spreadsheet
writetable(store_ID_check_table, fullfile(user_path, 'Outputs', strcat(run_date, '.', client, '.', 'output_postclean_stats', '.', run_version, '.', user_initials, '.xlsx')), 'Sheet', 'annual_order_check');


% create empty arrays to store stats
order_number_comparison_store =  zeros(1,1);
order_number_comparison_year = zeros(1,1);
order_number_comparison_week = zeros(1,1);
order_number_comparison_values = zeros(1,3);

cleaned_route_data_all = sortrows(cleaned_route_data_all, 4);
cleaned_order_data_all = sortrows(cleaned_order_data_all, 5);

% initialise index for loop iterations
indx = 1;

% on a weekly basis:
% for each of the common stores
for iStore = 1:length(common_stores)
    % find the store ID and relevant route and order data
    this_store = common_stores(iStore);
    this_store_route = cleaned_route_data_all(cleaned_route_data_all.Branch_ID == this_store,:);
    this_store_orders = cleaned_order_data_all(cleaned_order_data_all.Branch_ID == this_store,:);
    % find the unique years in the route data for this store
    unique_years = unique(year(this_store_route.Start_Date_of_Route));
    % for each of those years
    for iYear = 1:length(unique_years)
        % find the year and relevant route and order data
        this_year = unique_years(iYear);
        this_year_route = this_store_route(year(this_store_route.Start_Date_of_Route) == this_year,:);
        this_year_orders = this_store_orders(year(this_store_orders.Order_Delivery_Date) == this_year,:);
        % find the unique weeks in the route data for this store-year
        unique_weeks = unique(week(this_year_route.Start_Date_of_Route));
        for iWeek = 1:length(unique_weeks)
            % find the week and relevant route and order data
            this_week = unique_weeks(iWeek);
            this_week_route = this_year_route(week(this_year_route.Start_Date_of_Route) == this_week,:);
            this_week_orders = this_year_orders(week(this_year_orders.Order_Delivery_Date) == this_week,:);
%           find the number of orders in the order data set
            orderset_orders = height(this_week_orders);
%           sum the number of orders in the journey data set
            journeyset_orders = sum(this_week_route.Number_Orders);
%           find the percentage difference
            percentagediff_orders = ((journeyset_orders - orderset_orders)/journeyset_orders)*100;
%           write store to cell
            order_number_comparison_store(indx,1) = this_store;
%           write year to cell
            order_number_comparison_year(indx,1) = this_year;
%           write week to cell
            order_number_comparison_week(indx,1) = this_week;
%           write order number stats to cells
            order_number_comparison_values(indx,1) = journeyset_orders;
            order_number_comparison_values(indx,2) = orderset_orders;
            order_number_comparison_values(indx,3) = percentagediff_orders;
            % iterate loop counter
            indx = indx + 1;
        end
    end
end

% create table with order number stats
weekly_order_check_table = table(order_number_comparison_store, order_number_comparison_year, order_number_comparison_week, order_number_comparison_values(:,1), ...
    order_number_comparison_values(:,2), order_number_comparison_values(:,3));
weekly_order_check_table.Properties.VariableNames = {'Store_ID', 'Year', 'Week', 'Orders_in_Journeyset', 'Orders_in_OrderSet', 'Percentage_Difference_relative_to_JourneySet'};

% write table to spreadsheet
writetable(store_ID_check_table, fullfile(user_path, 'Outputs', strcat(run_date, '.', client, '.', 'output_postclean_stats', '.', run_version, '.', user_initials, '.xlsx')), 'Sheet', 'weekly_order_check');


%% produce output worksheet for checking order and journey numbers are unique, and save those to output which aren't

% find list of non unique order IDs
[~, ind] = unique(cleaned_order_data_all.Order_ID, 'rows');
duplicate_ind = setdiff(1:size(cleaned_order_data_all.Order_ID, 1), ind);
duplicate_value = cleaned_order_data_all.Order_ID(duplicate_ind);

% create empty arrays to store stats
non_unique_order_store = zeros(1,1);
non_unique_order_Order_ID = zeros(1,1);

% initialise index for loop iterations
indx = 1;

% for each of the non-unique order IDs
for iOrder = 1:length(duplicate_value)
    % find the order ID
    this_Order_ID = duplicate_value(iOrder);
%     find the data for this order ID
    duplicate_rows = find(cleaned_order_data_all.Order_ID == this_Order_ID);
%     find the first row of the duplicate rows, and the associated store
    row = duplicate_rows(1);
    this_store = cleaned_order_data_all.Branch_ID(row);
    % save the store and order ID
    non_unique_order_store(indx,1) = this_store;
    non_unique_order_Order_ID(indx,1) = this_Order_ID;
    % iterate the loop counter
    indx = indx + 1;
end

% create table with the duplicate order stats
non_unique_order_table = table(non_unique_order_store, non_unique_order_Order_ID);
non_unique_order_table.Properties.VariableNames = {'Store_ID', 'Order_ID'};

% write table to spreadsheet
writetable(store_ID_check_table, fullfile(user_path, 'Outputs', strcat(run_date, '.', client, '.', 'output_postclean_stats', '.', run_version, '.', user_initials, '.xlsx')), 'Sheet', 'non_unique_order');


% find list of non unique journey IDs
[~, ind] = unique(cleaned_route_data_all.Route_ID, 'rows');
duplicate_ind = setdiff(1:size(cleaned_route_data_all.Route_ID, 1), ind);
duplicate_value = cleaned_route_data_all.Route_ID(duplicate_ind);

% create empty arrays to store stats
non_unique_route_store = zeros(1,1);
non_unique_route_Route_ID = zeros(1,1);

% initialise index for loop iterations
indx = 1;

% for each of the non-unique order IDs
for iRoute = 1:length(duplicate_value)
    % find the route ID
    this_Route_ID = duplicate_value(iRoute);
%     find the rows for this route ID
    duplicate_rows = find(cleaned_route_data_all.Route_ID == this_Route_ID);
%     find the first row of the duplicate rows, and the associated store
    row = duplicate_rows(1);
    this_store = cleaned_route_data_all.Branch_ID(row);
    % save the store and route ID
    non_unique_route_store(indx,1) = this_store;
    % iterate the loop counter
    indx = indx + 1;
end

% create table with the duplicate route stats
non_unique_route_table = table(non_unique_route_store, non_unique_route_Route_ID);
non_unique_route_table.Properties.VariableNames = {'Store_ID', 'Route_ID'};

% write table to spreadsheet
writetable(store_ID_check_table, fullfile(user_path, 'Outputs', strcat(run_date, '.', client, '.', 'output_postclean_stats', '.', run_version, '.', user_initials, '.xlsx')), 'Sheet', 'non_unique_route');


%% check some orders exist for each day other than that 25th and 26th of December, across the data set and across all stores

% find the unique days in the route and order data sets
unique_route_days = sortrows(unique(cleaned_route_data_all.Start_Date_of_Route));
unique_order_days = sortrows(unique(cleaned_order_data_all.Order_Delivery_Date));

% find the start and end dates for the orderset
start_day_route = unique_route_days(1);
end_day_route = unique_route_days(end);

% find the start and end dates for the journeyset
start_day_order = unique_order_days(1);
end_day_order = unique_order_days(end);

% ensure that the earliest/latest days of both data sets are used to find
% if orders/routes occured. Required if one data set begins/ends after the
% other
if start_day_route < start_day_order
    start_day = start_day_route;
else
    start_day = start_day_order;
end
if end_day_route > end_day_order
    end_day = end_day_route;
else
    end_day = end_day_order;
end

% create a datetime array from the earliest date to the latest date
fullset_days = start_day:end_day;

% create empty arrays to store stats
date_check = NaT(1,1);
number_routes_check = zeros(1,1);
number_orders_routeset = zeros(1,1);
number_orders_orderset = zeros(1,1);

% initialise index for loop iterations
indx = 1;

% loop through each of the possible dates with data
for iDay = 1:length(fullset_days)
%     save date to array
    date_check(indx,1) = start_day + caldays(iDay-1);
    % find route and order data from this day
    this_day_routes = cleaned_route_data_all(cleaned_route_data_all.Start_Date_of_Route == fullset_days(iDay),:);
    this_day_orders = cleaned_order_data_all(cleaned_order_data_all.Order_Delivery_Date == fullset_days(iDay),:);
%     save number of journeys
    number_routes_check(indx,1) = height(this_day_routes);
%     save number of orders (journeyset)
    number_orders_routeset(indx,1) = sum(this_day_routes.Number_Orders);
%     save number of orders (orderset)
    number_orders_orderset(indx,1) = height(this_day_orders);
    % iterate loop counter
    indx = indx + 1;
end

% create table with the daily orders stats
all_stores_day_check = table(date_check, number_routes_check, number_orders_routeset, number_orders_orderset);
all_stores_day_check.Properties.VariableNames = {'Date', 'Number_of_Journeys', 'Number_of_Orders_RouteSet', 'Number_of_Orders_OrderSet'};

% write table to spreadsheet
writetable(store_ID_check_table, fullfile(user_path, 'Outputs', strcat(run_date, '.', client, '.', 'output_postclean_stats', '.', run_version, '.', user_initials, '.xlsx')), 'Sheet', 'all_stores_day_check');


% create empty arrays to store stats
date_check = NaT(1,1);
store_check = zeros(1,1);
number_routes_check = zeros(1,1);
number_orders_routeset = zeros(1,1);
number_orders_orderset = zeros(1,1);

% initialise index for loop iterations
indx = 1;

% find the unique store IDs from both data sets
unique_stores = store_ID_check_table.Store_ID;

% for each store
for iStore = 1:length(unique_stores)
    % find the store ID and route and order data associated with that store
    this_store = unique_stores(iStore);
    this_store_routes = cleaned_route_data_all(cleaned_route_data_all.Branch_ID == this_store, :);
    this_store_orders = cleaned_order_data_all(cleaned_order_data_all.Branch_ID == this_store, :);
    % for each of the possible dates with data
    for iDay = 1:length(fullset_days)
%     save store id
        store_check(indx,1) = this_store;
%     save date
        date_check(indx,1) = start_day + caldays(iDay-1);
        % find the route and order data from that date
        this_day_routes = this_store_routes(this_store_routes.Start_Date_of_Route == fullset_days(iDay),:);
        this_day_orders = this_store_orders(this_store_orders.Order_Delivery_Date == fullset_days(iDay),:);
%     save number of journeys
        number_routes_check(indx,1) = height(this_day_routes);
%     save number of orders (journeys)
        number_orders_routeset(indx,1) = sum(this_day_routes.Number_Orders);
%     save number of orders (orders)
        number_orders_orderset(indx,1) = height(this_day_orders);
        % iterate loop counter
        indx = indx + 1;
    end
end

% create table with the daily orders by store stats
by_store_day_check = table(store_check, date_check, number_routes_check, number_orders_routeset, number_orders_orderset);
by_store_day_check.Properties.VariableNames = {'Store_ID', 'Date', 'Number_of_Journeys', 'Number_of_Orders_RouteSet', 'Number_of_Orders_OrderSet'};

% write table to spreadsheet
writetable(store_ID_check_table, fullfile(user_path, 'Outputs', strcat(run_date, '.', client, '.', 'output_postclean_stats', '.', run_version, '.', user_initials, '.xlsx')), 'Sheet', 'by_store_day_check');


% end timer
toc

%% perform post code split on order data

% start timer
tic

% original_data_merge = innerjoin(original_data, original_data_journeys(:, [1 2]),'LeftKeys', 1, 'RightKeys', 1);
data = cleaned_order_data_all;


% Load in other data sets:
% load in known incorrect postcodes from the order and route data and their
% respective corrections
post_codes_correction = readtable(fullfile(user_path, 'Inputs\post_codes_correction.xlsx'));
% load  in the cucrent allocation of postcodes by store
post_codes_current = readtable(fullfile(user_path, 'Inputs\Postcodes_route.xlsx'), 'Sheet', 'current shops and postcodes');
% load in the future allocation of postcodes by store
post_codes_future = readtable(fullfile(user_path, 'Inputs\20200224FocusPostcodes.xlsx'), 'Sheet', 'future shops and postcodes');
% load in the postcodes for the relevant focus stores
focus_stores = readtable(fullfile(user_path, 'Inputs\20200224FocusPostcodes.xlsx'), 'Sheet', 'Focus Stores');

% 3. Extract data for all focus stores

% idx_focus_store = zeros(height(data), 1);
% extract the store IDs for the WHAT IS THIS COLUMN???
focus_stores = focus_stores.OLDSTORE_2;
% delet any rows where the store ID is NaN
focus_stores(any(isnan(focus_stores), 2), :) = [];
% find the unique store IDs
focus_stores = unique(focus_stores);

% extract the order data for only the focus year(s)
focus_years = [2019];

for iYear = 1:length(focus_years)
    this_year = focus_years(iYear);
    if iYear == 1
        order_data = data(year(data.Order_Delivery_Date) == this_year,:);
    else
        order_data = [order_data; data(year(data.Order_Delivery_Date) == this_year,:)];
    end
end

data = order_data;

% For each postcode to correct:
% Find rows in original order data set
% Replace with correct postcode (e.g. equivalent to add '0' at second whitespace)

for iPost_Code = 1:height(post_codes_correction)
    data.Post_code(strcmp(data.Post_Code, post_codes_correction.Old(iPost_Code))) = post_codes_correction.New(iPost_Code);
end

% find the unique postcodes from the order data
post_ = unique(sort(data.Post_Code));
post_all = data.Post_Code;

% free up variable names for script run
clear split1 split3 idx split4

% split postcodes at any whitespace
split1 = regexp(post_, ' ', 'split');

 j = 1;
 % for each of the split postcodes
 for iPostcode = 1:size(split1,1)
     clc
     fprintf('status: %d/%d',iPostcode,size(split1,1))
     % extract the first half od the split
     split3 = split1{iPostcode,1};
     % if there are no blanks in the postcode
     if size(split3,2) == 1
         % save the index of this postcode in idx
         idx(j,1) = iPostcode;
         % save the first part of the split
         split4(iPostcode,1) = split3;
         % increment the index for this event
         j = j+1;
     else
         % save the first and second charaters of the first part of the
         % split
         split4(iPostcode,1) = split3(1,1);
         split4(iPostcode,2) = split3(1,2);
     end
 end
 
% Finding the postcodes with no blanks 
no_whitespace_postcodes = split4(idx,:); 
 
% taking the second part of the split post codes
second_half = split4(:,2);

% Taking out the first letter in the second part of the post codes:
% for each of the second parts of the split postcodes
for iPostcode = 1:size(second_half,1)
    % take the first letter of the second part of the split postcode
    m = second_half{iPostcode,1};
    % if there are more than zero characters
    if size(m,2) > 0 
        % convert this from a cell to a character and save it 
        split4(iPostcode,3) = cellstr(m(1));
    end
end


% Concatenate the post code regions (first letter of the first half and
% first letter of the second half of the postcode split)
split5 = strcat(split4(:,1), {' '}, split4(:,3));

% save the these values for future reference
save('Post_code_split5.mat','split5'); 

% Dealing with the postcodes with not whitespace:
% for each of the postcodes with no whitespace
for iPostcode = 1:size(no_whitespace_postcodes,1) 
	% extract this postcode
    m = no_whitespace_postcodes{iPostcode,1}; 
    % find the number of characters in the postcode
    len = size(m,2); 
    % if there are 6 characters in the postcode
    if len == 6
        % take the first 3 characters and the fourth character
        t = m(1:3); 
        b = m(4); 
    % else if there are 7 characters in the postcode
    elseif len == 7 
        % take the first 4 characters and the fifth character
        t = m(1:4); 
        b = m(5); 
    % else if there are 5 characters in the postcode
    elseif len ==5
        % take the first 2 and the third character
        t = m(1:2); 
        b = m(3); 
    end 
    % concatenate these characters together with a string in between to
    % generate the post code segemtn
    d = strcat(t, {' '}, b); 
    % save this postcode segment at the required index
    split5(idx(iPostcode),1) = d; 
end 

% create a new column in the order data for the post code segments,
% using the original postcodes
data.Post_code_split = post_all;

% for each of the unique postcodes
for iPostCode = 1:length(post_)
    % display the loop progress
    clc
    fprintf('iPostCode: %d/%d',iPostCode,length(post_))
    % for the rows with postcodes matching this unique postcode, replace
    % the values in the post code split column with the corresponding post
    % code segment
    data.Post_code_split(strcmp(post_all, post_(iPostCode)),:) = split5(iPostCode); 
end

% end the timer 
toc

% save the output
writetable(data, fullfile(user_path, 'Outputs', strcat(run_date, '.', client, '.', 'uniform_PC_order_data', '.', run_version, '.', user_initials, '.csv')));



