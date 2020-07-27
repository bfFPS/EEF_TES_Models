%% Script to generate a specified of plausible scenarios for JLP data - BF, 27/04/2020

%%%%%%%%%%%%%%%%% CODE BEGINS %%%%%%%%%%%%%%%%%

% set flag to use old PCS allocations
use_old_allocations = 1;

%% load in required data

% set user input file path
user_path = 'C:\Users\FPSScripting2\Documents\Consolidated_Models\Vehicle_Modelling\Order_Volume_Scenario_Generation';

% load in historical weekly order volumes
volumes_by_week = readtable(fullfile(user_path, 'Step 2 - Ratio_Distribution\Inputs\HPO_MPO_input_scenario_generator.xlsx'),...
    'Sheet', 'Annual_Weekly_Volumes');

% load in MPO and HPO by PCS with store allocations
MPO_HPO_by_PCS = readtable(fullfile(user_path, 'Step 2 - Ratio_Distribution\Inputs\HPO_MPO_input_scenario_generator.xlsx'),...
    'Sheet', 'Proportion_HPO_MPO_by_PCS');

% load in MPO and HPO ratios by postcode
output_ratios_table = readtable(fullfile(user_path, 'Step 3 - Scenario_Generation\Inputs\scenario_generation_daily_ratios_input.csv'));


%% require constants, initialisations

% set special weeks, including Christmas period
special_weeks = [1, 31, 44, 45:51, 53];

% set special week ratios, Christmas weeks are handled separately so
% assigned ratio values for these make no difference but are given to maintain indexing
% order
special_week_ratios = [5/7, 5/7, 5/7, 0, 0, 0, 0, 0, 0, 0, 1/7];

% set the (minimum) number of scenarios to generate (log base 3 should return an
% integer)
desired_scenarios = 3375;

% from this find the number of loops to run at each step
numb_scenarios = ceil(nthroot(desired_scenarios,3));

% set the number of weeks for this year
weeks_this_year = 53;

% set Christmas period start, mid and end weeks
christmas_period_start_week = 45;
christmas_period_mid_week = 50;
christmas_period_end_week = 51;

% create array to store simulated weekly orders for this year
weekly_order_scenarios_this_year = zeros(weeks_this_year, numb_scenarios);

% set the number of average weekly orders targeted for this year
target_weekly_orders_this_year = 52506;

% set the expected Christmas period order volume
christmas_period_order_volume_this_year = 452352;

% Christmas period weekly increase
christmas_period_weekly_increase = 2239;

% set the max weekly volume
max_weekly_volume_this_year = 81798;

% from this, find the targeted number of annual orders for this year
target_annual_orders_this_year = target_weekly_orders_this_year*weeks_this_year;

%% find the parameters for the normal distribution of orders in the non-special weeks

% remove special weeks
weekly_historic = volumes_by_week.Historic_Orders(setdiff(1:weeks_this_year, special_weeks));  

% find mean of vector
mean_weekly_historic = mean(weekly_historic);

% subtract mean to get residuals
residuals_historic = weekly_historic - mean_weekly_historic;

% get mean and std of these residuals
mean_residuals_historic = mean(residuals_historic);
std_residuals_historic = std(residuals_historic);




%% handle special weeks (Christmas)

% set the number of orders for Christmas week
weekly_order_scenarios_this_year(christmas_period_end_week,:) = max_weekly_volume_this_year;

% find the number of orders for the non-Christmas period
rest_of_year_demand_this_year = target_annual_orders_this_year - christmas_period_order_volume_this_year;

% find the average weekly order volume of non-Christmas period
weekly_average_non_christmas_this_year = rest_of_year_demand_this_year/(weeks_this_year-(christmas_period_end_week - christmas_period_start_week));

% find the difference between the start weekly order volume of the
% Christmas period and the average weekly order volume of non-Christmas period
diff_to_average_start_Christmas_this_year = target_weekly_orders_this_year - weekly_average_non_christmas_this_year;

% find the expected weekly order volumes for the week before the Christmas period
% and each week across the Christmas period (NON INCLUSIVE OF CHRISTMAS WEEK)
for iWeek = christmas_period_start_week:christmas_period_mid_week
    expected_value_this_week = weekly_average_non_christmas_this_year + (iWeek - (christmas_period_start_week-1))*christmas_period_weekly_increase;
    weekly_order_scenarios_this_year(iWeek,:) = normrnd(expected_value_this_week, std_residuals_historic, 1, numb_scenarios);
end


%% handle special weeks (non-Christmas)

% for each of the special weeks
for iWeek = 1:length(special_weeks)
    this_week = special_weeks(iWeek);
    % if the week does not occur in the Christmas period
    if this_week < christmas_period_start_week || this_week > christmas_period_end_week
        % find the order ratio, expected orders and generate required
        % scenarios
        this_week_order_ratio = special_week_ratios(iWeek);
        this_week_expected_orders_this_year = this_week_order_ratio*target_weekly_orders_this_year;
        weekly_order_scenarios_this_year(this_week,:) = normrnd(this_week_expected_orders_this_year, std_residuals_historic, 1, numb_scenarios);
    end
end



%% find the weekly order volumes for the non-special weeks

% find the non-special week indexes
non_special_weeks_this_year = find(weekly_order_scenarios_this_year(:,1) == 0);

% find the expected order volumes in these weeks
non_special_weeks_expected_orders_this_year = (target_annual_orders_this_year - sum(weekly_order_scenarios_this_year(:,:)))/length(non_special_weeks_this_year);

% for each of these weeks, generate a residual (noise) from a normal
% distribution, then to this residual add the mean
for iWeek = 1:length(non_special_weeks_this_year)
    this_week = non_special_weeks_this_year(iWeek);
    weekly_order_scenarios_this_year(this_week,:) = normrnd(mean_residuals_historic, std_residuals_historic, 1, numb_scenarios) + non_special_weeks_expected_orders_this_year;
end

%% plotting
% 
% % plot 2019 predictions
% for iFig = 1:10
%     figure
%     plot(volumes_by_week.Historic_Orders,'LineWidth',1)
%     hold on
%     plot(weekly_order_scenarios_this_year(:,iFig), 'k','LineWidth', 1)
%     xlabel('Week')
%     ylabel('Number of Orders')
%     legend('2019 Historical', 'Simulation 2018', 'location', 'southoutside');
%     title(['2018 Simulation', ' ' , num2str(iFig)])
%     saveas(gcf,strcat('C:\Users\FPSScripting2\Documents\JLPEVloads_project\Post_Project_Scenario_Generation\Outputs_6\2018 Simulations\2018_simulation_', num2str(iFig), '.png'))
%     close
% end
% 
% figure
% plot(volumes_by_week.Historic_Orders,'LineWidth',2)
% hold on
% plot(weekly_order_scenarios_this_year(:,1:3))
% xlabel('Week')
% ylabel('Number of Orders')
% legend('2019 Historical', 'Simulation 2018', 'location', 'southoutside');
% title('2018 Plot of X Simulations')
% saveas(gcf,strcat('C:\Users\FPSScripting2\Documents\JLPEVloads_project\Post_Project_Scenario_Generation\Outputs_6\2018 Simulations\2018_10_simulations.png'))
% close
%     
% figure
% plot(volumes_by_week.Historic_Orders,'LineWidth',2)
% hold on
% plot(mean(weekly_order_scenarios_this_year(:,:),2))
% xlabel('Week')
% ylabel('Number of Orders')
% legend('2019 Historical', 'Simulation Mean 2018', 'location', 'southoutside');
% title('2018 Mean of X Simulations')
% saveas(gcf,strcat('C:\Users\FPSScripting2\Documents\JLPEVloads_project\Post_Project_Scenario_Generation\Outputs_6\2018 Simulations\2018_simulation_mean_of_', num2str(numb_scenarios), '_simulations.png'))
% close


%% randomly select weeks by order proportions (non-special weeks)

if use_old_allocations == 1
    try
        MPO_HPO_by_PCS(strcmp(MPO_HPO_by_PCS.OldStore, 'not yet covered'),:) = [];
        MPO_HPO_by_PCS.OldStore = str2double(MPO_HPO_by_PCS.OldStore); 
    catch
    end
    MPO_HPO_by_PCS(isnan(MPO_HPO_by_PCS.OldStore),:) = [];
end

% create vector containing week indexes of normal weeks
normal_weeks = [2:30, 32:42, 44, 52];

% create vector to store week indexing of post code allocation rows, and
% find indexing
row_indexing = zeros(height(MPO_HPO_by_PCS),1);
for iWeek = 1:length(normal_weeks)
    row_indexing = or(row_indexing, MPO_HPO_by_PCS.Week == normal_weeks(iWeek));
end

% extract out the normal week allocations
MPO_HPO_by_PCS_normal = MPO_HPO_by_PCS(row_indexing, :);

% extract out the special weeks
MPO_HPO_by_PCS_special = MPO_HPO_by_PCS(~row_indexing, :);

% create vector to store random weekly allocations of orders by postcode
post_code_scenario_allocations = zeros(length(normal_weeks), numb_scenarios);

% create empty table and variable to store week allocation permutations
MPO_HPO_by_PCS_scenarios = table();
MPO_HPO_by_PCS.Corresponding_Week = MPO_HPO_by_PCS.Week;
simulation_numb = double.empty;

% for each simulation
for iSim = 1:numb_scenarios
    % create a copy of MPO HPO by PCS
    MPO_HPO_by_PCS_this_scenario = MPO_HPO_by_PCS;
    % randomly shuffle the normal weeks
    shuffled_weeks = normal_weeks(randperm(length(normal_weeks)));
    post_code_scenario_allocations(:,iSim) = shuffled_weeks;
    % save the scenario number
    this_sim = zeros(height(MPO_HPO_by_PCS), 1);
    this_sim(:,:) = iSim;
    week_perm = double.empty;
    % for each of the normal weeks
    for iWeek = 1:length(normal_weeks)
        % replace the data from the orinal week with that of the shuffled
        % week
        MPO_HPO_by_PCS_this_scenario(MPO_HPO_by_PCS_this_scenario.Week == normal_weeks(iWeek), 2:end) =...
            MPO_HPO_by_PCS(MPO_HPO_by_PCS.Week == shuffled_weeks(iWeek), 2:end);
        % update the 'corresponding week' with that of the shuffled week
        % for traceability
        MPO_HPO_by_PCS_this_scenario.Corresponding_Week(MPO_HPO_by_PCS_this_scenario.Week == normal_weeks(iWeek)) =...
            shuffled_weeks(iWeek);
    end
    % append this scenario to the all scenarios table
    MPO_HPO_by_PCS_scenarios = [MPO_HPO_by_PCS_scenarios; MPO_HPO_by_PCS_this_scenario];
    % append this simulation number to the all smulation number vector
    simulation_numb = [simulation_numb; this_sim];
end

% add the simulation numbers as a new variable to the scenario data table
MPO_HPO_by_PCS_scenarios.Simulation = simulation_numb;



%% plotting
% 
% figure
% histogram(MPO_HPO_by_PCS_scenarios.ProportionOfTotalNetworkVolume(MPO_HPO_by_PCS_scenarios.Week == 35))
% hold on
% xlabel('Percentage of Weekly Network Volume')
% ylabel('Frequency')
% xlim([0 0.0018])
% ylim([0 8000])
% % legend('', 'location', 'southoutside');
% title('2019 Percentage of Weekly Network Volume by Post Code Segment: Week 35')
% saveas(gcf,strcat('C:\Users\FPSScripting2\Documents\JLPEVloads_project\Post_Project_Scenario_Generation\Outputs_6\2019 Simulations\2019 Percentage of Annual Weekly Volume by Post Code Segment Week 35.png'))
% close
% 
% figure
% histogram(MPO_HPO_by_PCS_scenarios.ProportionOfTotalNetworkVolume(MPO_HPO_by_PCS_scenarios.Week == 51))
% hold on
% xlabel('Percentage of Weekly Network Volume')
% ylabel('Frequency')
% xlim([0 0.0018])
% ylim([0 8000])
% % legend('', 'location', 'southoutside');
% title('2019 Percentage of Weekly Network Volume by Post Code Segment: Week 51')
% saveas(gcf,strcat('C:\Users\FPSScripting2\Documents\JLPEVloads_project\Post_Project_Scenario_Generation\Outputs_6\2019 Simulations\2019 Percentage of Annual Weekly Volume by Post Code Segment Week 51.png'))
% close

%% allocate orders to stores by postcode

% for each post code segment, find the average hours per order and miles
% per order (for non-zero values)

% find the unique post code segments
unique_postcodes = unique(MPO_HPO_by_PCS.Postcode);

% create arrays to store orders, miles and hours aggregated by store
simulation_vector = double.empty;
week_vector = double.empty;
store_vector = double.empty;
output_values_vector = double.empty(0,3);

tic
% for each scenario of weekly volume
for iSim_volume = 1:numb_scenarios
    % extract the number of orders per week for this simulation
    weekly_orders_this_sim = weekly_order_scenarios_this_year(:,iSim_volume);
    % create table with corresponding week number
    orders_by_week = array2table(weekly_orders_this_sim, 'VariableNames', {'Network_Order_Volume'});
    Week = 1:weeks_this_year;
    orders_by_week = addvars(orders_by_week, Week', 'Before', 'Network_Order_Volume');
    % for each scenario of PCS allocation randomisation
    for iSim_weekly_PCS = 1:numb_scenarios
        clc
        fprintf('%d / %d\n', iSim_volume, numb_scenarios)
        fprintf('%d / %d\n', iSim_weekly_PCS, numb_scenarios)
        % extract the PCO weekly allocations for this simulation
        MPO_HPO_by_PCS_this_sim = MPO_HPO_by_PCS_scenarios(MPO_HPO_by_PCS_scenarios.Simulation == iSim_weekly_PCS, :);
        
        % find the perc of annual network volume by postcode
        pct_orders_by_postcode = MPO_HPO_by_PCS_this_sim.ProportionOfTotalNetworkVolume;
        
        % match weekly orders to percentages by post code
        MPO_HPO_by_PCS_this_sim = innerjoin(MPO_HPO_by_PCS_this_sim, orders_by_week, 'Keys' , 1);

        % find the expected orders by postcode, multiplying percentages
        % with annual volume
        expected_orders_by_postcode = MPO_HPO_by_PCS_this_sim.ProportionOfTotalNetworkVolume.*MPO_HPO_by_PCS_this_sim.Network_Order_Volume;
        
        % create array to store generated order volumes
        scenario_volumes = zeros(length(unique_postcodes)*weeks_this_year, numb_scenarios);

        % for each scenario
        for iSim = 1:numb_scenarios
            % generate the required number of random order volumes for this
            % scenario
            scenario_volumes(:,iSim) = poissrnd(expected_orders_by_postcode,length(expected_orders_by_postcode),1);
%             scenario_volumes(:,iSim) = expected_orders_by_postcode;
        end
            
        % construct an output table with expected volumes by post code for each store 
        output_table = cell2table(repmat(unique_postcodes, weeks_this_year, 1), 'VariableNames', {'Post_Code_Split'});
        output_table.Probability = pct_orders_by_postcode;
        output_table.Expected_Volume = expected_orders_by_postcode;
        output_table.Scenario_Order_Volumes = scenario_volumes;
        output_table.Mean_Scenario_Order_Volumes = mean(scenario_volumes,2);
        output_table.Week = MPO_HPO_by_PCS_this_sim.Week;
        output_table = movevars(output_table, 'Week', 'Before', 'Post_Code_Split');
        output_table = innerjoin(output_table, MPO_HPO_by_PCS_this_sim, 'Keys', [1, 2]);
          
        % find the store IDs and remove any NaN values
        unique_stores = unique(output_table.NewStore);
        unique_stores(any(isnan(unique_stores), 2), :) = [];

        % for each store 
        for iStore = 1:length(unique_stores)
            % extract the scenarios for that store
            this_store_data = output_table(output_table.NewStore == unique_stores(iStore),:);
            % create arrays to store weeks, store ID, and scenario values
            weeks = unique(output_table.Week);
            store_ids = zeros(length(unique(output_table.Week)),1);
            store_ids(:,:) = unique_stores(iStore);
            this_store_weekly_data = zeros(length(unique(output_table.Week)), 3);
            % for each week
            for iWeek = 1:length(unique(output_table.Week))
                % extract the data for this week
                this_week_data = this_store_data(this_store_data.Week == iWeek,:);
                % sum the values for each post code (if required)
                if height(this_week_data) > 1
                    this_week_orders = sum(this_week_data.Scenario_Order_Volumes);
                    this_week_mileage = sum(this_week_orders.*this_week_data.HistoricMPO);
                    this_week_hours = sum(this_week_orders.*this_week_data.HistoricHPO);
                else
                    this_week_orders = this_week_data.Scenario_Order_Volumes;
                    this_week_mileage = this_week_orders.*this_week_data.HistoricMPO;
                    this_week_hours = this_week_orders.*this_week_data.HistoricHPO;
                end
                % store these scenario values in the output array
                this_store_weekly_data(1+(iWeek-1)*numb_scenarios:iWeek*numb_scenarios, :) = [this_week_orders; this_week_mileage; this_week_hours]';
                
            % repeat weeks and append to weekly vector
            week_vector = [week_vector; repmat(iWeek, numb_scenarios, 1)];
            
            end
              
            % repeat store ID vector 
            store_vector = [store_vector; repmat(store_ids, numb_scenarios, 1)];

            % store the simulation numbers in the order they are stored in
            % output_values_vector
            simulation_numb = zeros(numb_scenarios,1);
            simulation_numb(:,:) = (1:numb_scenarios) + (numb_scenarios*(iSim_weekly_PCS-1)+numb_scenarios*numb_scenarios*(iSim_volume-1));
            simulation_vector = [simulation_vector; repmat(simulation_numb, length(unique(output_table.Week)),1) ];

            % for the number of run simulations, append each scenario to
            % the output vector, and generate an array with the
            % corresponding simulation numbers
            for iSim = 1:numb_scenarios
                tmp = this_store_weekly_data(1+(iSim-1)*length(unique(output_table.Week)):iSim*length(unique(output_table.Week)),:);
                output_values_vector = [output_values_vector; tmp];
            end
        end
    end
    toc
end
toc

% create the final output table containing all generated scenarios
final_scenarios_table = array2table(simulation_vector, 'VariableNames', {'Scenario'});
final_scenarios_table.Week = week_vector;
final_scenarios_table.Store_ID = store_vector;
final_scenarios_table.Orders = output_values_vector(:,1);
final_scenarios_table.Mileage = output_values_vector(:,2);
final_scenarios_table.Hours = output_values_vector(:,3);
% save scenarios to desired path
% writetable(final_scenarios_table, fullfile(user_path, 'Step 3 - Scenario_Generation\Outputs\scenario_generation_output_best_worst_orders_mileage_hours.csv'));


%% plotting

% scenarios_to_plot = 5;

% figure
% plot(historic_orders.TotalOrders(historic_orders.BranchID == 828 & historic_orders.Year == 2018), 'k', 'LineWidth', 1)
% hold on
% for iSim = 1:scenarios_to_plot
%     plot(final_scenarios_table.Orders(final_scenarios_table.Scenario == iSim & final_scenarios_table.Store_ID == 828))
% end
% title('2018 Scenario Examples: 5 Poisson Permutations, Store 828')
% xlabel('Week')
% ylabel('Order Volume')
% legend('2018 Historic', '2018 Simulation', 'location', 'southoutside')
% saveas(gcf,strcat('C:\Users\FPSScripting2\Documents\JLPEVloads_project\Post_Project_Scenario_Generation\Outputs_6\2018 Simulations\2018 Historical Allocations Prediction 1 Store 828.png'))
% close
% 
% scenarios_to_plot = 5;
% 
% figure
% plot(historic_orders.TotalOrders(historic_orders.BranchID == 828 & historic_orders.Year == 2018), 'k', 'LineWidth', 1)
% hold on
% for iSim = 1:scenarios_to_plot
%     plot(final_scenarios_table.Orders(final_scenarios_table.Scenario == iSim+10*10 + 10 & final_scenarios_table.Store_ID == 828))
% end
% title('2018 Scenario Examples: 5 Poisson Permutations, Store 828')
% xlabel('Week')
% ylabel('Order Volume')
% legend('2018 Historic', '2018 Simulation', 'location', 'southoutside')
% saveas(gcf,strcat('C:\Users\FPSScripting2\Documents\JLPEVloads_project\Post_Project_Scenario_Generation\Outputs_6\2018 Simulations\2018 Historical Allocations Prediction 2 Store 828.png'))
% close


%% find daily order volumes

% sort rows as pre-join step
final_scenarios_table = sortrows(final_scenarios_table, [1 3]);

% create vector containing scenario numbs for join func
scenarios_vector = [];
for iSim = 1:max(final_scenarios_table.Scenario)
    scenarios_vector = [scenarios_vector; repmat(iSim, height(output_ratios_table), 1)];
end

% repeat ratio table and add sceanrio numbs for join func
output_ratios_table_repeated = repmat(output_ratios_table, max(final_scenarios_table.Scenario), 1);
output_ratios_table_repeated = addvars(output_ratios_table_repeated, scenarios_vector, 'Before', 'Week', 'NewVariableNames', {'Scenario'});

% join the scenario values with the relevant daily ratios by scenario and
% week and store
joined_scenarios_table = innerjoin(final_scenarios_table, output_ratios_table_repeated, 'Keys', [1 2 3]);

% create new table
daily_scenarios_table = joined_scenarios_table;

% find variable names contining 'store_model_ratios'
string_to_find = 'store_model_ratios'; 
contains_string = contains(joined_scenarios_table.Properties.VariableNames, string_to_find);

% to this able, add variables for the daily orders, mileage and hours
daily_scenarios_table.Daily_Orders = joined_scenarios_table.Orders.*joined_scenarios_table{:,contains_string};
daily_scenarios_table.Daily_Mileage = joined_scenarios_table.Mileage.*joined_scenarios_table{:,contains_string};
daily_scenarios_table.Daily_Hours = joined_scenarios_table.Hours.*joined_scenarios_table{:,contains_string};

% save final output table with datestamp to the output folder for Step 3
format longG
run_date = char(datetime(floor(now),'ConvertFrom','datenum'));
split_run_date = split(run_date);
writetable(daily_scenarios_table, fullfile(user_path, 'Step 3 - Scenario_Generation\Outputs', strcat('scenarios_daily_values_', num2str(desired_scenarios), '_scenarios_', split_run_date{1}, '.csv')));

% % save final output to the output folder for Step 4
% writetable(daily_scenarios_table,fullfile(user_path, 'Step 4 - Scenario_Management\Inputs', strcat('scenarios_daily_values_', num2str(desired_scenarios), '_scenarios_', split_run_date{1}, '.csv')));

% save final output to the output folder for Step 5
writetable(daily_scenarios_table,fullfile(user_path, 'Step 5 - Scenario Extraction\Inputs', strcat('scenarios_daily_values_', num2str(desired_scenarios), '_scenarios_', split_run_date{1}, '.csv')));

%%%%%%%%%%%%%%%%% CODE ENDS %%%%%%%%%%%%%%%%%