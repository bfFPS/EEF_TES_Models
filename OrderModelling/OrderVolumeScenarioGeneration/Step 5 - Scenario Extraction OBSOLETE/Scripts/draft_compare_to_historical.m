dir = 'C:\Users\FPSScripting2\Downloads\';
% PCS_stats_2018 = readtable([dir,'Orderstats_ALL_2018.csv']);

PCS_stats_2019 = readtable([dir,'uniform_PC_order_data_ALL.csv']);

% set user input file path
user_path = 'C:\Users\FPSScripting2\Documents\Consolidated_Models\Vehicle_Modelling\Order_Volume_Scenario_Generation';

% % read in cleaned order data with post code segments included
% order_data_PCS = readtable(fullfile(user_path, 'Step 2 - Ratio_Distribution\Inputs\uniform_PC_order_data_ALL.csv'));

% load in MPO and HPO by PCS with store allocations
MPO_HPO_by_PCS = readtable(fullfile(user_path, 'Step 2 - Ratio_Distribution\Inputs\PCS_stats_scenario_generation.xlsx'), 'Sheet', 'Proportion_HPO_MPO_by_PCS');

PCS_allocation = MPO_HPO_by_PCS(:, [2 4 5]);
PCS_allocation = unique(PCS_allocation);
PCS_allocation.OldStore = str2double(PCS_allocation.OldStore); 

PCS_stats_with_store = movevars(PCS_stats_2018,'Postcode','Before','Week');
PCS_stats_with_store = outerjoin(PCS_stats_with_store, PCS_allocation, 'Keys', 1,'MergeKeys',true);
PCS_stats_with_store = PCS_stats_with_store(~any(ismissing(PCS_stats_with_store),2),:);
% 
% 
% daily_scenarios = readtable(fullfile(user_path, 'Step 3 - Scenario_Generation\Outputs\scenarios_daily_values_13-May-2020.csv'));
daily_scenarios = central_all;
% 
% load in BI orders by store analysis
BI_historical_orders = readtable(fullfile(user_path, 'Step 5 - Scenario Extraction\Inputs\20200505OldStoreBoundaryStatsALLYEARS.xlsx'));
BI_historical_orders = sortrows(BI_historical_orders, 2);

unique_stores = unique(daily_scenarios.Store_ID);

BI_historical_PCS = readtable(fullfile(user_path, 'Step 5 - Scenario Extraction\Inputs\Post_code_segment_export.csv'));
BI_historical_PCS.Year = str2double(BI_historical_PCS.Year);
BI_historical_PCS.Week = str2double(BI_historical_PCS.Week);
BI_historical_PCS.NEWSTORE = str2double(BI_historical_PCS.NEWSTORE);
BI_historical_PCS(strcmp(BI_historical_PCS.OLDSTORE, 'not yet covered'), :) = [];
BI_historical_PCS.OLDSTORE = str2double(BI_historical_PCS.OLDSTORE);
BI_historical_PCS_2018 = BI_historical_PCS(BI_historical_PCS.Year == 2018,:);

% compare: PCS MATLAB - Scenario - MA Store Level
for iStore = 1:length(unique_stores)
    this_store = unique_stores(iStore);
    historical_orders = zeros(53, 1);
    for iWeek = 1:53
        historical_orders(iWeek,1) = sum(PCS_stats_with_store.Orders(PCS_stats_with_store.OldStore == this_store & PCS_stats_with_store.Week == iWeek));
    end
    figure
    plot(daily_scenarios.Orders(daily_scenarios.Store_ID == this_store & daily_scenarios.Scenario == 1))
    hold on
    plot(historical_orders)
    plot(BI_historical_orders.WeeklyOrders(BI_historical_orders.Year == 2018 & BI_historical_orders.SiteCode == this_store))
    legend('Scenario', 'Historical PCS', 'Historical BI')
    title(num2str(this_store))
    pause(6)
    close
end


% % compare: PCS MATLAB - Scenario - MA PCS Level
% for iStore = 1:length(unique_stores)
%     this_store = unique_stores(iStore);
%     historical_orders = zeros(53, 1);
%     historical_orders_BI = zeros(53, 1);
%     for iWeek = 1:53
%         historical_orders(iWeek,1) = sum(PCS_stats_with_store.Orders(PCS_stats_with_store.OldStore == this_store & PCS_stats_with_store.Week == iWeek));
%         historical_orders_BI(iWeek, 1) = nansum(BI_historical_PCS_2018.WeeklyOrders(BI_historical_PCS_2018.OLDSTORE == this_store & BI_historical_PCS_2018.Week == iWeek));
%     end
%     figure
% %     plot(daily_scenarios.Orders(daily_scenarios.Store_ID == this_store & daily_scenarios.Scenario == 1))
%     plot(historical_orders_BI)
%     hold on
%     plot(historical_orders)
%     plot(BI_historical_orders.WeeklyOrders(BI_historical_orders.Year == 2018 & BI_historical_orders.SiteCode == this_store))
% %     legend('Scenario', 'Historical PCS', 'Historical BI')
%     legend('BI PCS', 'PCS MATLAB', 'BI Store')
%     title(num2str(this_store))
% %     pause(6)
%     close
% end
% 
% 
% sum_BI_513 = nansum(BI_historical_PCS_2018.WeeklyOrders(BI_historical_PCS_2018.OLDSTORE == 513))
% sum_MATLAB_513 = nansum(PCS_stats_with_store.Orders(PCS_stats_with_store.OldStore == 513))