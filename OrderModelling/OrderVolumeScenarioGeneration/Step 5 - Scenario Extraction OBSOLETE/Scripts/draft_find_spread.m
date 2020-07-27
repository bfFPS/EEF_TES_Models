%% Extract and plot scenario spread at store level - BF, 05/05/2020

% set user input file path
user_path = 'C:\Users\FPSScripting2\Documents\Consolidated_Models\Vehicle_Modelling\Order_Volume_Scenario_Generation';

% read in scenarios
daily_scenarios_table = readtable(fullfile(user_path, 'Step 5 - Scenario Extraction\Inputs\scenarios_daily_values_14-May-2020.csv'));

% find the unique store IDs for which scenarios were generated
unique_stores = unique(daily_scenarios_table.Store_ID);

% find number of weeks in the 
numb_weeks = max(unique(daily_scenarios_table.Week));

% set the desired min and max percentiles
min_prctile = 0.01;
max_prctile = 0.99;

% create arrays to store weekly results for min and max for each store
min_max_scenarios = zeros(length(unique_stores)*numb_weeks, 6);

% for each store
for iStore = 1:length(unique(daily_scenarios_table.Store_ID))
    % find site ID
    this_store = unique_stores(iStore);
    % extract scenario data for this store
    this_store_daily_scenarios_table = daily_scenarios_table(daily_scenarios_table.Store_ID == this_store, :);
    % for each week
    for iWeek = 1:numb_weeks
        % extract scenario data for that week
        this_week_daily_scenarios = this_store_daily_scenarios_table(this_store_daily_scenarios_table.Week == iWeek, :);
        % find number of scenarios
        numb_scenarios = length(unique(this_week_daily_scenarios.Scenario));
        % print script status
        fprintf('%d / %d\n', iStore, length(unique(daily_scenarios_table.Store_ID)))
        fprintf('%d / %d\n', iWeek, 53)
        % sort the orders based on volume magnitude (descending)
        sorted_orders = sort(this_week_daily_scenarios.Orders);
        % if desired min prctile * number of scenarios returns 0 when
        % rounded, round up, else round as normal
        if round(min_prctile*numb_scenarios) == 0
            low_scenario_orders = sorted_orders(ceil(min_prctile*numb_scenarios));
        else
            low_scenario_orders = sorted_orders(round(min_prctile*numb_scenarios));
        end
        % if desired max prctile * number of scenarios returns 0 when
        % rounded, round down, else round as normal
        if round(max_prctile*numb_scenarios) == length(sorted_orders)
            high_scenario_orders = sorted_orders(floor(max_prctile*numb_scenarios));
        else
            high_scenario_orders = sorted_orders(round(max_prctile*numb_scenarios));
        end
        
        % find the scenario numbers corresponding to the low and high order
        % volumes, and ensure unique
        low_scenario = find(this_week_daily_scenarios.Orders == low_scenario_orders);
        if size(low_scenario,1) > 1
            low_scenario = low_scenario(1);
        end
        high_scenario = find(this_week_daily_scenarios.Orders == high_scenario_orders);
        if size(high_scenario,1) > 1
            high_scenario = high_scenario(1);
        end
        
        % save values to array
        min_max_scenarios(iWeek + (iStore-1)*numb_weeks, 1) = this_store;
        min_max_scenarios(iWeek + (iStore-1)*numb_weeks, 2) = iWeek;
        min_max_scenarios(iWeek + (iStore-1)*numb_weeks, 3) = low_scenario;
        min_max_scenarios(iWeek + (iStore-1)*numb_weeks, 4) = low_scenario_orders;
        min_max_scenarios(iWeek + (iStore-1)*numb_weeks, 5) = high_scenario;
        min_max_scenarios(iWeek + (iStore-1)*numb_weeks, 6) = high_scenario_orders;

    end
end

% convert array to table and save as csv
min_max_scenarios_output = array2table(min_max_scenarios,...
    'VariableNames',{'Store_ID','Week','Min_Sim','Min_Weekly_Orders','Max_Sim','Max_Weekly_Orders'});

min_max_scenarios_output = innerjoin(min_max_scenarios_output, daily_scenarios_table);


writetable(min_max_scenarios_output, fullfile(user_path, strcat('Step 5 - Scenario Extraction\Outputs\scenario_spread_by_store.csv')));

% plot and save spread as png for each store
for iStore = 1:length(unique(daily_scenarios_table.Store_ID))
    this_store = unique_stores(iStore); 
    f = figure;
    plot(1:numb_weeks, min_max_scenarios_output.Min_Weekly_Orders(min_max_scenarios_output.Store_ID == this_store)', '.-b')
    hold on
    plot(1:numb_weeks, min_max_scenarios_output.Max_Weekly_Orders(min_max_scenarios_output.Store_ID == this_store)', '.-r')
    x2 = [1:numb_weeks, fliplr(1:numb_weeks)];
    inBetween = [min_max_scenarios_output.Min_Weekly_Orders(min_max_scenarios_output.Store_ID == this_store)',...
        fliplr(min_max_scenarios_output.Max_Weekly_Orders(min_max_scenarios_output.Store_ID == this_store)')];
    fill(x2, inBetween, 'y');
    legend('min scenario', 'max scenario', 'location', 'southoutside')
    xlabel('Week')
    ylabel('Weekly Order Volume')
    title(['Plausible Spread of Order Volumes: Store' ' ' num2str(this_store)])
    print(f, '-dpng', '-r0', fullfile(user_path, strcat('Step 5 - Scenario Extraction\Outputs\Store_', num2str(this_store), '_scenario_order_spread_99th.png')));
    close
end