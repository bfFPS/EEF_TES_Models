extreme_operational_percentile = 0.99;

weeks_this_year = 53;

for iStore = 1:1
    this_store = 513;
    this_store_scenarios = central_all(central_all.Store_ID == this_store, :);
    max_scenarios_orders = zeros(weeks_this_year, 6);
    max_scenarios_mileages = zeros(weeks_this_year, 6);
    max_scenarios_hours = zeros(weeks_this_year, 6);
    for iWeek = 1:53
        % extract scenario data for that week
        this_week_daily_scenarios = this_store_scenarios(this_store_scenarios.Week == iWeek, :);
        % find number of scenarios
        numb_scenarios = length(unique(this_week_daily_scenarios.Scenario));
        % sort the orders based on volume magnitude (descending)
        sorted_orders = sort(this_week_daily_scenarios.Orders);
        sorted_mileages = sort(this_week_daily_scenarios.Mileage);
        sorted_hours = sort(this_week_daily_scenarios.Hours);
        % if desired max prctile * number of scenarios returns 0 when
        % rounded, round down, else round as normal
        if round(extreme_operational_percentile*numb_scenarios) == length(sorted_orders)
            high_scenario_orders = sorted_orders(floor(extreme_operational_percentile*numb_scenarios));
            high_scenario_mileage = sorted_mileages(floor(extreme_operational_percentile*numb_scenarios));
            high_scenario_hours = sorted_hours(floor(extreme_operational_percentile*numb_scenarios));
        else
            high_scenario_orders = sorted_orders(round(extreme_operational_percentile*numb_scenarios));
            high_scenario_mileage = sorted_mileages(round(extreme_operational_percentile*numb_scenarios));
            high_scenario_hours = sorted_hours(round(extreme_operational_percentile*numb_scenarios));
        end

        % find the scenario numbers corresponding to the high order
        % volume, and ensure unique
        high_scenario_orders_orders = find(this_week_daily_scenarios.Orders == high_scenario_orders);
        if size(high_scenario_orders_orders,1) > 1
        	high_scenario_orders_orders = high_scenario_orders_orders(1);
        end
        
        high_scenario_mileages_mileages = find(this_week_daily_scenarios.Mileage == high_scenario_mileage);
        if size(high_scenario_mileages_mileages,1) > 1
        	high_scenario_mileages_mileages = high_scenario_mileages_mileages(1);
        end
        
        
        high_scenario_hours_hours = find(this_week_daily_scenarios.Hours == high_scenario_hours);
        if size(high_scenario_hours_hours,1) > 1
        	high_scenario_hours_hours = high_scenario_hours_hours(1);
        end

        % save values to order array
        max_scenarios_orders(iWeek + (iStore-1)*weeks_this_year, 1) = high_scenario_orders_orders;
        max_scenarios_orders(iWeek + (iStore-1)*weeks_this_year, 2) = iWeek;
        max_scenarios_orders(iWeek + (iStore-1)*weeks_this_year, 3) = this_store;
        max_scenarios_orders(iWeek + (iStore-1)*weeks_this_year, 4) = high_scenario_orders;
        max_scenarios_orders(iWeek + (iStore-1)*weeks_this_year, 5) = this_week_daily_scenarios.Mileage(this_week_daily_scenarios.Scenario == high_scenario_orders_orders);
        max_scenarios_orders(iWeek + (iStore-1)*weeks_this_year, 6) = this_week_daily_scenarios.Hours(this_week_daily_scenarios.Scenario == high_scenario_orders_orders);
        table_max_scenarios_orders = array2table(max_scenarios_orders, 'VariableNames', {'Scenario', 'Week', 'Store_ID', 'Orders', 'Mileage', 'Hours'});
        
        % save values to mileages array
        max_scenarios_mileages(iWeek + (iStore-1)*weeks_this_year, 1) = high_scenario_mileages_mileages;
        max_scenarios_mileages(iWeek + (iStore-1)*weeks_this_year, 2) = iWeek;
        max_scenarios_mileages(iWeek + (iStore-1)*weeks_this_year, 3) = this_store;
        max_scenarios_mileages(iWeek + (iStore-1)*weeks_this_year, 4) = this_week_daily_scenarios.Orders(this_week_daily_scenarios.Scenario == high_scenario_mileages_mileages);
        max_scenarios_mileages(iWeek + (iStore-1)*weeks_this_year, 5) = high_scenario_mileage;
        max_scenarios_mileages(iWeek + (iStore-1)*weeks_this_year, 6) = this_week_daily_scenarios.Hours(this_week_daily_scenarios.Scenario == high_scenario_mileages_mileages);
        table_max_scenarios_mileages = array2table(max_scenarios_mileages, 'VariableNames', {'Scenario', 'Week', 'Store_ID', 'Orders', 'Mileage', 'Hours'});
        
        % save values to hours array
        max_scenarios_hours(iWeek + (iStore-1)*weeks_this_year, 1) = high_scenario_hours_hours;
        max_scenarios_hours(iWeek + (iStore-1)*weeks_this_year, 2) = iWeek;
        max_scenarios_hours(iWeek + (iStore-1)*weeks_this_year, 3) = this_store;
        max_scenarios_hours(iWeek + (iStore-1)*weeks_this_year, 4) = this_week_daily_scenarios.Orders(this_week_daily_scenarios.Scenario == high_scenario_hours_hours);
        max_scenarios_hours(iWeek + (iStore-1)*weeks_this_year, 5) = this_week_daily_scenarios.Mileage(this_week_daily_scenarios.Scenario == high_scenario_hours_hours);
        max_scenarios_hours(iWeek + (iStore-1)*weeks_this_year, 6) = high_scenario_hours;
        table_max_scenarios_hours = array2table(max_scenarios_hours, 'VariableNames', {'Scenario', 'Week', 'Store_ID', 'Orders', 'Mileage', 'Hours'});
        
    end
end