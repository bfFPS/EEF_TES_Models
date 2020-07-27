%% Script to generate descriptive statistics micro-dashboard for each generated scenario - BF, 05/05/2020

% set user input file path
user_path = 'C:\Users\FPSScripting2\Documents\Consolidated_Models\Vehicle_Modelling\Order_Volume_Scenario_Generation';

% load in historic orders and scenario orders
% order_data_PCS_historic = readtable(fullfile(user_path, 'Step 4 - Scenario_Management\Inputs\...xlsx));
daily_scenarios_table = readtable(fullfile(user_path, 'Step 4 - Scenario_Management\Inputs\scenarios_daily_values_29-Apr-2020.csv'));


% specify days in week
days_in_week = 7;

% find the number of scenarios
numb_scenarios = length(unique(daily_scenarios_table.Scenario));

% set normal weeks
normal_weeks = [2:30, 32:43, 52];

% set special weeks, including Christmas period
special_weeks = [1, 31, 44, 45:51, 53];

% specify focus stores
focus_stores = [122 213 215 226 227 457 494 513 531 605 656 663 690 721 753 828];

% find the data for the focus stores
focus_stores_data = order_data_PCS_historic(ismember(order_data_PCS_historic.OldStore, focus_stores),:);

% create empty arrays
historical_orders_daily = zeros(365,1);
historical_mileage_daily = zeros(365,1);
historical_hours_daily = zeros(365,1);
historical_orders_weekly = zeros(53,1);
historical_mileage_weekly = zeros(53,1);
historical_hours_weekly = zeros(53,1);

% find the daily and weekly orders of the historical data:
% order_data_PCS_historic
for iDay = 1:365
%     extract data from this day for the relevant stores
    this_day_data = focus_stores_data(day(focus_stores_data.Order_Delivery_Date, 'dayofyear') == iDay,:);
    % if there is any data for this day
    if height(this_day_data) > 0
        % find datevactor
        this_day_datevec = datevec(this_day_data.Planned_Departure_Time) - datevec(this_day_data.Planned_Arrival_Time);
%         find sum of data
        orders_this_day = height(this_day_data);
        historical_orders_daily(iDay, 1) = orders_this_day;
%         find sum of MPO
        mileage_this_day = sum(this_day_data.MPO);
        historical_mileage_daily(iDay, 1) = mileage_this_day;
    %     find sum of HPO
        hours_this_day = sum(this_day_datevec(:,4) + this_day_datevec(:,5)./60);
        historical_hours_daily(iDay, 1) = hours_this_day;

    end
%     add to daily array
    if mod(iDay,7) == 0
%         add sum of previous 7 days to weekly array
        historical_orders_weekly(iDay/7, 1) = sum(historical_orders_daily(iDay-6:iDay,1));
        historical_mileage_weekly(iDay/7, 1) = sum(historical_mileage_daily(iDay-6:iDay,1));
        historical_hours_weekly(iDay/7, 1) = sum(historical_hours_daily(iDay-6:iDay,1));
    end
    % special case for partial week
    if iDay == 365
        historical_orders_weekly(53, 1) = historical_orders_daily(iDay,1);
        historical_mileage_weekly(53, 1) = historical_mileage_daily(iDay,1);
        historical_hours_weekly(53, 1) = historical_hours_daily(iDay,1);
    end
end

% generate descriptive statistics dashboards
for iSim = 1:numb_scenarios
    this_scenario_data = daily_scenarios_table(daily_scenarios_table.Scenario == iSim,:);
    numb_weeks = length(unique(this_scenario_data.Week));
%     numb_stores = length(unique(this_scenario_data.Store_ID));
    network_volumes_weekly = zeros(numb_weeks,1);
    network_mileages_weekly = zeros(numb_weeks,1);
    network_hours_weekly = zeros(numb_weeks,1);
    network_volumes_daily = zeros(numb_weeks*days_in_week,1);
    network_mileages_daily = zeros(numb_weeks*days_in_week,1);
    network_hours_daily = zeros(numb_weeks*days_in_week,1);
    for iWeek = 1:max(unique(this_scenario_data.Week))
        this_week_data = this_scenario_data(this_scenario_data.Week == iWeek,:);
        this_week_network_volume = sum(this_week_data.Daily_Orders, 'all');
        this_week_network_mileage = sum(this_week_data.Daily_Mileage, 'all');
        this_week_network_hours = sum(this_week_data.Daily_Hours, 'all');
        network_volumes_weekly(iWeek,1) = this_week_network_volume;
        network_mileages_weekly(iWeek,1) = this_week_network_mileage;
        network_hours_weekly(iWeek,1) = this_week_network_hours;
        network_volumes_daily(1+(iWeek-1)*days_in_week:iWeek*days_in_week,1) = sum(this_week_data.Daily_Orders, 1)';
        network_mileages_daily(1+(iWeek-1)*days_in_week:iWeek*days_in_week,1) = sum(this_week_data.Daily_Mileage, 1)';
        network_hours_daily(1+(iWeek-1)*days_in_week:iWeek*days_in_week,1) = sum(this_week_data.Daily_Hours, 1)';
    end

    % MAGNITUDE HISTOGRAM DASHBOARD (SCENARIO ONLY)

    % create stats table
    normal_week_std = std(network_volumes_weekly(normal_weeks,1));
    max_normal_week = max(network_volumes_weekly(normal_weeks,1));
    min_normal_week = max(network_volumes_weekly(normal_weeks,1));
    % ignore partial week
    max_all_weeks = max(network_volumes_weekly(1:52,1));
    min_all_weeks = min(network_volumes_weekly(1:52,1));
    total_year_volume = sum(network_volumes_weekly);
    stats = table(normal_week_std, max_normal_week, min_normal_week, max_all_weeks, min_all_weeks, total_year_volume);
    vars = {'Normal_Weeks_Std', 'Max_Orders_Normal_Weeks', 'Min_Orders_Normal_Weeks', 'Max_Orders_All_Weeks', 'Min_Orders_All_Weeks', 'Total_Year_Volume'};
    stats.Properties.VariableNames = vars;
    
    f = figure;
    set(gcf,'Position',[1 41 1920 964.8000000000001])

    uit = uitable(f,'Data', stats{1:end,1:end},...
            'ColumnName',vars,...
            'ColumnWidth',{200});

    subplot(3,3,1)
    histogram(network_volumes_weekly, 10)
    hold on 
    ylabel('Frequency');
    xlabel('Network Orders');
    title('Weekly Network Orders Frequency Plot')
    
    subplot(3,3,2)
    histogram(network_mileages_weekly, 10)
    hold on 
    ylabel('Frequency');
    xlabel('Network Mileage');
    title('Weekly Network Mileage Frequency Plot')
    
    subplot(3,3,3)
    histogram(network_hours_weekly, 10)
    hold on 
    ylabel('Frequency');
    xlabel('Network Mileage');
    title('Weekly Network Hours Frequency Plot')
    
    subplot(3,3,4)
    histogram(network_volumes_daily)
    hold on 
    ylabel('Frequency');
    xlabel('Network Orders');
    title('Daily Network Orders Frequency Plot')
    
    subplot(3,3,5)
    histogram(network_mileages_daily)
    hold on 
    ylabel('Frequency');
    xlabel('Network Mileage');
    title('Daily Network Mileage Frequency Plot')
    
    subplot(3,3,6)
    histogram(network_hours_daily)
    hold on 
    ylabel('Frequency');
    xlabel('Network Hours');
    title('Daily Network Hours Frequency Plot')
    
    pos = get(subplot(3,3,7),'position');
    delete(subplot(3,3,7))
    set(uit,'units','normalized')
    pos(3) = 0.777;
    set(uit,'position',pos)
    
    print(f,'-dpng','-r0',fullfile(user_path, strcat('Step 4 - Scenario_Management\Outputs\scenario_', num2str(iSim), '_magnitude_desc_stats_.png')));
    close
    
    
    % NORMALISED CUMULATIVE DASHBOARD (HISTROICAL VS SCENARIO)
    
    f = figure;
    set(gcf,'Position',[1 41 1920 964.8000000000001])
    
    
    subplot(3,3,1)
    cdfplot(normalize(network_volumes_weekly))
    hold on 
    cdfplot(normalize(historical_orders_weekly))
    ylabel('Probability');
    xlabel('Normalised Network Orders');
%     legend('Scenario', 'Historical');
    title('Weekly Network Orders Cumulative')
    
    subplot(3,3,2)
    cdfplot(normalize(network_mileages_weekly))
    hold on 
    cdfplot(normalize(historical_mileage_weekly))
    ylabel('Probability');
    xlabel('Normalised Network Mileage');
%     legend('Scenario', 'Historical');
    title('Weekly Network Mileage Cumulative')
    
    subplot(3,3,3)
    cdfplot(normalize(network_hours_weekly))
    hold on 
    cdfplot(normalize(historical_hours_weekly))
    ylabel('Probability');
    xlabel('Normalised Network Mileage');
%     legend('Scenario', 'Historical');
    title('Weekly Network Hours Cumulative')
    
    subplot(3,3,4)
    cdfplot(normalize(network_volumes_daily))
    hold on 
    cdfplot(normalize(historical_orders_daily))
    ylabel('Probability');
    xlabel('Normalised Network Orders');
%     legend('Scenario', 'Historical');
    title('Daily Network Orders Cumulative')
    
    subplot(3,3,5)
    cdfplot(normalize(network_mileages_daily))
    hold on 
    cdfplot(normalize(historical_mileage_daily))
    ylabel('Probability');
    xlabel('Normalised Network Mileage');
%     legend('Scenario', 'Historical');
    title('Daily Network Mileage Cumulative')
    
    subplot(3,3,6)
    cdfplot(normalize(network_hours_daily))
    hold on 
    cdfplot(normalize(historical_hours_daily))
    ylabel('Probability');
    xlabel('Normalised Network Hours');
%     legend('Scenario', 'Historical');
    title('Daily Network Hours Cumulative')
    
    pos = [0.13, 0.11, 0.775, 0.215735294117647];
    subplot('Position',pos)
    plot(network_volumes_weekly)
    hold on 
    plot(historical_orders_weekly)
    ylabel('Volume');
    xlabel('Week');
    legend('Scenario', 'Historical');
    title('Weekly Order Volumes')
    
    print(f,'-dpng','-r0',fullfile(user_path, strcat('Step 4 - Scenario_Management\Outputs\scenario_', num2str(iSim), '_normalise_desc_stats_.png')));
    close
    
    
 
end

