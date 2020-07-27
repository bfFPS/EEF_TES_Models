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
% ONS_stats_PCS = table;
% 
% tic
% for iPCS = 1:length(unique_PCS)
%     clc
%     fprintf('PCS: %d/%d', iPCS, length(unique_PCS))
%     this_PCS = unique_PCS{iPCS};
%     this_PCS_rows = valid_postcodes_onehot_inuse(strcmp(valid_postcodes_onehot_inuse.PCS, this_PCS), :);
%     this_PCS_households = nansum(this_PCS_rows.Households);
%     unique_districts = unique(this_PCS_rows.District);
%     unique_countries = unique(this_PCS_rows.Country);
%     
%     this_district = strjoin(unique_districts, ', ');
%     this_country = strjoin(unique_countries, ', ');
%     
%     % quantitative variables
%     ONS_stats_PCS.PCS{iPCS} = this_PCS;
%     ONS_stats_PCS.n_Postcodes(iPCS) = height(this_PCS_rows);
%     ONS_stats_PCS.Latitude(iPCS) = nanmean(this_PCS_rows.Latitude);
%     ONS_stats_PCS.Longitude(iPCS) = nanmean(this_PCS_rows.Longitude);
%     ONS_stats_PCS.Country{iPCS} = this_country;
%     ONS_stats_PCS.District{iPCS} = this_district;
%     ONS_stats_PCS.Population(iPCS) = nansum(this_PCS_rows.Population);
%     ONS_stats_PCS.Households(iPCS) = this_PCS_households;
%     ONS_stats_PCS.IndexOfMultipleDeprivation(iPCS) = nansum(this_PCS_rows.IndexOfMultipleDeprivation.*this_PCS_rows.Households)/this_PCS_households;
%     ONS_stats_PCS.AverageIncome(iPCS) = nansum(this_PCS_rows.AverageIncome.*this_PCS_rows.Households)/this_PCS_households;
%     ONS_stats_PCS.DistanceToStation(iPCS) = nansum(this_PCS_rows.Households.*this_PCS_rows.DistanceToStation)/...
%         this_PCS_households;
%     
%     % encoded variables
%     for iSettlement = 1:length(unique_settlement)
%         this_settlement = unique_settlement{iSettlement};
%         ONS_stats_PCS{iPCS, genvarname(this_settlement)} = nansum(this_PCS_rows{:, genvarname(this_settlement)}.*this_PCS_rows.Households)/this_PCS_households;
%     end
% end
% toc
% 
% %%%%%%%%%%%%%%%%%%%%% TMP LINES TO BE DELETED %%%%%%%%%%%%%%%%%%%
% % remove country variable column
% ONS_stats_PCS = removevars(ONS_stats_PCS, 'Country');
% 
% % save table
% writetable(ONS_stats_PCS, 'C:\Users\FPSScripting2\Documents\Consolidated_Models\OrderModelling\NewPostcodeRegression\Outputs\ONS_stats_PCS_V3.csv');
% % read table saved on previous script run
% ONS_stats_PCS = readtable('C:\Users\FPSScripting2\Documents\Consolidated_Models\OrderModelling\NewPostcodeRegression\Outputs\ONS_stats_PCS_V3.csv');
% 
%% extract postcode sectors delivered to in 2018, from ONS_stats_PCS

% extract 2018 order PCS
unique_2018_PCS = unique(order_data_2018_PCS.Postcode);
ONS_2018_order_set = ONS_stats_PCS(ismember(ONS_stats_PCS.PCS, unique_2018_PCS), :);

% extract 2019 order PCS
unique_2019_PCS = unique(order_data_2019_PCS.Postcode);
ONS_2019_order_set = ONS_stats_PCS(ismember(ONS_stats_PCS.PCS, unique_2019_PCS), :);

%% find yearly orders at each postcode 
% for 2018
order_data_annual = table;
for iPCS = 1:length(unique_2018_PCS)
    this_PCS = unique_2018_PCS{iPCS};
    this_PCS_data = order_data_2018_PCS(strcmp(order_data_2018_PCS.Postcode, this_PCS), :);
    order_data_annual.Year(iPCS) = 2018;
    order_data_annual.PCS{iPCS} = this_PCS;
    order_data_annual.sqMi(iPCS) = unique(this_PCS_data.sqMi);
    order_data_annual.OldStore(iPCS) = str2double(unique(this_PCS_data.OldStore));
    order_data_annual.NewStore(iPCS) = unique(this_PCS_data.NewStore);
    order_data_annual.Orders(iPCS) = sum(this_PCS_data.HistroicOrders);
    order_data_annual.MPO(iPCS) = sum((this_PCS_data.HistoricMPO.*this_PCS_data.HistroicOrders))/sum(this_PCS_data.HistroicOrders);
    order_data_annual.HPO(iPCS) = sum((this_PCS_data.HistoricHPO.*this_PCS_data.HistroicOrders))/sum(this_PCS_data.HistroicOrders);
end

start_idx = height(order_data_annual);

% for 2019
for iPCS = 1:length(unique_2019_PCS)
    this_PCS = unique_2019_PCS{iPCS};
    this_PCS_data = order_data_2019_PCS(strcmp(order_data_2019_PCS.Postcode, this_PCS), :);
    order_data_annual.Year(iPCS + start_idx) = 2019;
    order_data_annual.PCS{iPCS + start_idx} = this_PCS;
    order_data_annual.sqMi(iPCS + start_idx) = unique(this_PCS_data.sqMi);
    order_data_annual.OldStore(iPCS + start_idx) = str2double(unique(this_PCS_data.OldStore));
    order_data_annual.NewStore(iPCS + start_idx) = unique(this_PCS_data.NewStore);
    order_data_annual.Orders(iPCS + start_idx) = sum(this_PCS_data.HistroicOrders);
    order_data_annual.MPO(iPCS + start_idx) = sum((this_PCS_data.HistoricMPO.*this_PCS_data.HistroicOrders))/sum(this_PCS_data.HistroicOrders);
    order_data_annual.HPO(iPCS + start_idx) = sum((this_PCS_data.HistoricHPO.*this_PCS_data.HistroicOrders))/sum(this_PCS_data.HistroicOrders);
end

% divide orders by number of 1000 orders which occured that year
% (normalise orders)
order_rate_unit = 1000;
total_2018_orders = sum(order_data_annual.Orders(order_data_annual.Year == 2018));
total_2019_orders = sum(order_data_annual.Orders(order_data_annual.Year == 2019));

order_data_annual.OrderRate = [order_data_annual.Orders(order_data_annual.Year == 2018)./(total_2018_orders/order_rate_unit); ...
    order_data_annual.Orders(order_data_annual.Year == 2019)./(total_2019_orders/order_rate_unit)];

%% train regression on 2018 data

% select X variables
% x_variables = 6:28;
x_variables = [7 8 10];

% remove NaNs from ONS_2018_order_set and corresponding lines from
% order_data_annual
Y_order_data_annual = order_data_annual.OrderRate(order_data_annual.Year == 2018);
Y_MPO_data_annual = order_data_annual.MPO(order_data_annual.Year == 2018);
Y_HPO_data_annual = order_data_annual.HPO(order_data_annual.Year == 2018);
X_ONS_2018_order_set = ONS_2018_order_set{:, x_variables};

rows_to_remove = isnan(sum(X_ONS_2018_order_set, 2));

Y_order_data_annual(rows_to_remove, :) = [];
Y_MPO_data_annual(rows_to_remove, :) = [];
Y_HPO_data_annual(rows_to_remove, :) = [];
X_ONS_2018_order_set(rows_to_remove, :) = [];

% train the regression
train_year = 2018;
regress_model_orders = regress(Y_order_data_annual, X_ONS_2018_order_set);
regress_model_MPO = regress(Y_MPO_data_annual, X_ONS_2018_order_set);
regress_model_HPO = regress(Y_HPO_data_annual, X_ONS_2018_order_set);

regress_model_old = regress(order_data_annual.OrderRate(order_data_annual.Year == 2018), ONS_2018_order_set{:, x_variables});%% Predict regression on 2019 data

% find order rates
ypred_orders = ONS_2019_order_set{:, x_variables} .* regress_model_orders';
pred_orders = sum(ypred_orders, 2).*(total_2019_orders/order_rate_unit);
% find MPO
pred_MPO = sum(ONS_2019_order_set{:, x_variables} .* regress_model_MPO', 2);
% find HPO
pred_HPO = sum(ONS_2019_order_set{:, x_variables} .* regress_model_HPO', 2);

pred_2019 = addvars(order_data_annual(order_data_annual.Year == 2019, :),...
    pred_orders, pred_MPO, pred_HPO, 'NewVariableNames', {'PredOrders', 'PredMPO', 'PredHPO'});
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
regress_model_orders = regress(order_data_2018_PCS.HistroicOrders, ONS_2018_weekly_order_set{:, x_variables});


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

ypred_orders = ONS_2019_weekly_order_set{:,x_variables} .* regress_model_orders';




% % create yearly orders, MPO, HPO per post code
% 
% order_data_2018_annual = table;
% for iPCS = 1:length(unique_2018_PCS)
%     this_PCS = unique_2018_PCS{iPCS};
%     this_PCS_data = order_data_2018_PCS(strcmp(order_data_2018_PCS.Postcode, this_PCS), :);
%     order_data_2018_annual.Year(iPCS) = 2018;
%     order_data_2018_annual.PCS{iPCS} = this_PCS;
%     order_data_2018_annual.sqMi(iPCS) = unique(this_PCS_data.sqMi);
%     order_data_2018_annual.OldStore(iPCS) = str2double(unique(this_PCS_data.OldStore));
%     order_data_2018_annual.NewStore(iPCS) = unique(this_PCS_data.NewStore);
%     order_data_2018_annual.Orders(iPCS) = sum(this_PCS_data.HistroicOrders);
%     order_data_2018_annual.MPO(iPCS) = sum((this_PCS_data.HistoricMPO.*this_PCS_data.HistroicOrders))/sum(this_PCS_data.HistroicOrders);
%     order_data_2018_annual.HPO(iPCS) = sum((this_PCS_data.HistoricHPO.*this_PCS_data.HistroicOrders))/sum(this_PCS_data.HistroicOrders);
% end
% 
% % find total 2018 orders
% total_orders_2018 = sum(order_data_2018_annual.Orders);




% find unique order data postcodes
unique_order_postcodes = unique(order_data.Post_Code);


% test with ismember to see which postcodes are contained in order_DATA but not
% in valid_postcodes
sample = unique_order_postcodes(:);
sample = strrep(sample, ' ', '');
fullset = strrep(valid_postcodes_inuse.Postcode, ' ', '');
tic
not_valid_raw = sample(~ismember(sample, fullset), :);
toc

sample = unique_order_postcodes(:);
sample = strrep(sample, ' ', '');
fullset = strrep(valid_postcodes.Postcode, ' ', '');
tic
not_valid_raw_all = sample(~ismember(sample, fullset), :);
toc

% % load order stats 2018
% order_stats_2018 = readtable('C:\Users\FPSScripting2\Downloads\Orderstats_ALL_2018.csv');

% for each postcode, find total orders
orders_by_postcode = zeros(length(unique_order_postcodes), 1);
tic
for iPost = 1:length(unique_order_postcodes)
    orders_by_postcode(iPost,1) = sum(strcmp(order_data.Post_Code, unique_order_postcodes(iPost)));
end
toc

% create table
orders_by_postcode_table = table(unique_order_postcodes, orders_by_postcode, 'VariableNames', {'Postcode', 'OrdersPlaced'});
orders_by_postcode_complete = orders_by_postcode_table(orders_by_postcode_table.OrdersPlaced > 0, :);
full_postcode_table = innerjoin(valid_postcodes, orders_by_postcode_complete);
full_postcode_table_no_nan = full_postcode_table( ~any( isnan( full_postcode_table.OrdersPlaced_per_Household ) | isinf( full_postcode_table.OrdersPlaced_per_Household )...
    | isnan( full_postcode_table.OrdersPlaced_per_Pop ) | isinf( full_postcode_table.OrdersPlaced_per_Pop ), 2 ),: );

figure
scatter(full_postcode_table_no_nan.OrdersPlaced_per_Household, full_postcode_table_no_nan.OrdersPlaced_per_Pop)
hold on
xlabel('Orders per Household')
ylabel('Orders per Resident')
% remove spaces and test with ismember to see which postcodes are contained in order_DATA but not
% in valid_postcodes

% fit regression
train_set = full_postcode_table_no_nan(1:3000,:);
test_set = full_postcode_table_no_nan(1:3000,:);
fitted_regression = regress(train_set.OrdersPlaced, train_set{:, [20 21 36 47]});

test_output_orders = fitted_regression(1).*test_set{:,20} + fitted_regression(2).*test_set{:,21} + fitted_regression(3).*test_set{:,36} + fitted_regression(4).*test_set{:,47};

figure
plot(test_output_orders)
hold on
plot(test_set.OrdersPlaced)
legend('Test Output', 'True Value')
ylabel('Orders Placed')

figure
plot((test_set.OrdersPlaced - test_output_orders)./test_set.OrdersPlaced)
legend('Error')
ylabel('Orders Placed')

% find orders per postcode
% perform regression