% % load postcodes
% valid_postcodes = readtable('C:\Users\FPSScripting2\Downloads\postcodes\postcodes.csv');
% % load all order data
% order_data = readtable('C:\Users\FPSScripting2\Downloads\cleaned_order_data_all.csv');
% % load 2019 order data with PCS
% order_data_2019_PCS = readtable('C:\Users\FPSScripting2\Downloads\cleaned_order_data_all.csv');
% 
% % load 2018 order stats
% order_data_2018_PCS = readtable('C:\Users\FPSScripting2\Documents\Consolidated_Models\OrderModelling\NewPostcodeRegression\Outputs\2018_PCS_stats.xlsx');
% % load 2019 order stats
% order_data_2019_PCS = readtable('C:\Users\FPSScripting2\Documents\Consolidated_Models\OrderModelling\NewPostcodeRegression\Outputs\2019_PCS_stats.xlsx');
% 
% valid_postcodes_onehot = valid_postcodes;
% 
% % find the unique urban-rural types
% unique_settlement = unique(valid_postcodes_onehot.Rural_urban);
% unique_settlement = rmmissing(unique_settlement);
% 
% for iSettlement = 1:length(unique_settlement)
%     this_settlement = unique_settlement(iSettlement);
%     settlement_index = strcmp(valid_postcodes_onehot.Rural_urban, this_settlement);
%     valid_postcodes_onehot = addvars(valid_postcodes_onehot, settlement_index, 'NewVariableNames', genvarname(this_settlement));
% end
% 
% % filter out in use postcodes from valid_postcodes
% valid_postcodes_onehot_inuse = valid_postcodes_onehot(strcmp(valid_postcodes_onehot.InUse_, 'Yes'), :);
% 
% %% Create PCS dataset with averages weighted by n households
% 
% postcodes = valid_postcodes_onehot_inuse.Postcode;
% 
% valid_postcodes_onehot_inuse.PCS = cellfun(@(x) x(1:end-2), postcodes, 'UniformOutput', false);
% unique_PCS = unique(valid_postcodes_onehot_inuse.PCS);
% 
% 
% % For each unique PCS, extract the rows pertaining to this
% % 1. Find the weighted average of 
% %    - population
% %    - households
% %    - IndexOfMultipleDeprivation
% %    - AverageIncome
% % 2. Find average of
% %    - Distance to station
% %    - Latitude
% %    - Longitude
% 
ONS_stats_PCS = table;

tic
for iPCS = 1:length(unique_PCS)
    clc
    fprintf('PCS: %d/%d', iPCS, length(unique_PCS))
    this_PCS = unique_PCS{iPCS};
    this_PCS_rows = valid_postcodes_onehot_inuse(strcmp(valid_postcodes_onehot_inuse.PCS, this_PCS), :);
    this_PCS_households = nansum(this_PCS_rows.Households);
    unique_districts = unique(this_PCS_rows.District);
    unique_countries = unique(this_PCS_rows.Country);
    
    this_district = strjoin(unique_districts, ', ');
    this_country = strjoin(unique_countries, ', ');
    
    % quantitative variables
    ONS_stats_PCS.PCS{iPCS} = this_PCS;
    ONS_stats_PCS.n_Postcodes(iPCS) = height(this_PCS_rows);
    ONS_stats_PCS.Latitude(iPCS) = nanmean(this_PCS_rows.Latitude);
    ONS_stats_PCS.Longitude(iPCS) = nanmean(this_PCS_rows.Longitude);
    ONS_stats_PCS.District{iPCS} = this_district;
    ONS_stats_PCS.Country{iPCS} = this_country;
    ONS_stats_PCS.Population(iPCS) = nansum(this_PCS_rows.Population);
    ONS_stats_PCS.Households(iPCS) = nansum(this_PCS_rows.Households);
    ONS_stats_PCS.IndexOfMultipleDeprivation(iPCS) = nansum(this_PCS_rows.IndexOfMultipleDeprivation)/this_PCS_households;
    ONS_stats_PCS.AverageIncome(iPCS)= nansum(this_PCS_rows.AverageIncome)/this_PCS_households;
    
    % encoded variables
    for iSettlement = 1:length(unique_settlement)
        this_settlement = unique_settlement{iSettlement};
        ONS_stats_PCS{iPCS, genvarname(this_settlement)} = nansum(this_PCS_rows{:, genvarname(this_settlement)}.*this_PCS_rows.Households)/this_PCS_households;
    end
end
toc

%%%%%%%%%%%%%%%%%%%%% TMP LINES TO BE DELETED %%%%%%%%%%%%%%%%%%%
% remove country variable column
ONS_stats_PCS = removevars(ONS_stats_PCS, 'Country');

% save table
writetable(ONS_stats_PCS, 'C:\Users\FPSScripting2\Documents\Consolidated_Models\OrderModelling\NewPostcodeRegression\Outputs\ONS_stats_PCS_V3.csv');
% read table saved on previous script run
ONS_stats_PCS = readtable('C:\Users\FPSScripting2\Documents\Consolidated_Models\OrderModelling\NewPostcodeRegression\Outputs\ONS_stats_PCS_V2.csv');

%% extract postcode sectors delivered to in 2018, from ONS_stats_PCS

% extract 2018 order PCS
unique_2018_PCS = unique(order_data_2018_PCS.Postcode);
ONS_2018_order_set = ONS_stats_PCS(ismember(ONS_stats_PCS.PCS, unique_2018_PCS), :);


%% train regression on the number of orders going to a PCS in 2018 week 1
% (including weekly volume as a factor)

% find weekly orders for 2018
weekly_orders = zeros(max(order_data_2018_PCS.Week), 1); 
for iWeek = 1:max(order_data_2018_PCS.Week)
    this_week_data = order_data_2018_PCS(order_data_2018_PCS.Week == iWeek, :);
    weekly_network_orders = sum(this_week_data.HistroicOrders);
    weekly_orders(iWeek, 1) = weekly_network_orders;
end

% repeat ONS_2018_order_set for each week, appending weekly orders
ONS_2018_weekly_order_set = table;

for iWeek = 1:max(order_data_2018_PCS.Week)
    weekly_network_orders = weekly_orders(iWeek, 1);
    ONS_2018_weekly_order_set = [ONS_2018_weekly_order_set; addvars(ONS_2018_order_set,...
        transpose(repelem(weekly_network_orders, height(ONS_2018_order_set))), 'NewVariableNames', 'NetworkOrders')];
end

% select X variables
x_variables = 6:27;

% %%%%%%%%%%%%%%%%%%%%%% TMP LINES TO BE DELETED %%%%%%%%%%%%%%%%%%%
% % delete lines where population is not a number
% tmp = str2double(ONS_2018_weekly_order_set.Population);
% ONS_2018_weekly_order_set_tmp = ONS_2018_weekly_order_set;
% order_data_2018_PCS_tmp = order_data_2018_PCS;
% ONS_2018_weekly_order_set_tmp(isnan(tmp), :) =[];
% order_data_2018_PCS_tmp(isnan(tmp), :) =[];
% ONS_2018_weekly_order_set_tmp.Population = str2double(ONS_2018_weekly_order_set_tmp.Population);
% ONS_2018_weekly_order_set_tmp.Households = str2double(ONS_2018_weekly_order_set_tmp.Households);
% ONS_2018_weekly_order_set_tmp.IndexOfMultipleDeprivation = str2double(ONS_2018_weekly_order_set_tmp.IndexOfMultipleDeprivation);
% ONS_2018_weekly_order_set_tmp.AverageIncome = str2double(ONS_2018_weekly_order_set_tmp.AverageIncome);

% remove if AverageIncome isnan
ONS_2018_weekly_order_set(any(isnan(ONS_2018_weekly_order_set.AverageIncome), 2), :) = [];
order_data_2018_PCS(any(isnan(ONS_2018_weekly_order_set.AverageIncome), 2), :) = [];


% train the regression
regress_model = regress(order_data_2018_PCS.HistroicOrders, ONS_2018_weekly_order_set{:, x_variables});


%% see if this can predict number of orders going to postcodes (including
% unseen) in 2019

% find weekly orders for 2019
weekly_orders = zeros(max(order_data_2019_PCS.Week), 1); 
for iWeek = 1:max(order_data_2019_PCS.Week)
    this_week_data = order_data_2019_PCS(order_data_2019_PCS.Week == iWeek, :);
    weekly_network_orders = sum(this_week_data.HistroicOrders);
    weekly_orders(iWeek, 1) = weekly_network_orders;
end

% extract 2019 order PCS
unique_2019_PCS = unique(order_data_2019_PCS.Postcode);
ONS_2019_order_set = ONS_stats_PCS(ismember(ONS_stats_PCS.PCS, unique_2019_PCS), :);

% extract week for 2019
target_week = 10;
target_week_2019 = order_data_2019_PCS(order_data_2019_PCS.Week == target_week, :);

weekly_network_orders = weekly_orders(target_week, 1);

ONS_2019_weekly_order_set = addvars(ONS_2019_order_set,...
        transpose(repelem(weekly_network_orders, height(ONS_2019_order_set))), 'NewVariableNames', 'NetworkOrders');

ONS_2019_weekly_order_set(any(isnan(ONS_2019_weekly_order_set.AverageIncome), 2), :) = [];

ypred = ONS_2019_weekly_order_set{:,x_variables} .* regress_model';

