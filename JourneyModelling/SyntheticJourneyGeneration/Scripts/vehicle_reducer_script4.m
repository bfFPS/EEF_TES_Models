%% vehicle_reducer_script4 - BF, 08/04/2020
% This script calculates the number of vehicles per store required for
% various vehicle cases and years, based on historical and forecast/predicted 
% weekly order volumes, mileage and time.

% start timer for script
tic

% load in required data:
% weekly orders, mileages and time
data = readtable('C:\Users\FPSScripting2\Downloads\20200317VehicleReducer2.xlsx', 'Sheet', 'Weekly Journeys');
% future vehicle numbers forecast by data provider
forecast_vehicle_numbers = readtable('C:\Users\FPSScripting2\Downloads\future_vehicles.xlsx');
% non-vehicle parameters by year and store
non_vehicle_parameters = readtable('C:\Users\FPSScripting2\Documents\Updated_Scripts\input_non_vehicle_parameters_vehicle_reducer.xlsx');
% daily ratios by year and store
ratios_matrix = readtable('C:\Users\FPSScripting2\Documents\Updated_Scripts\input_ratios_vehicle_reducer.xlsx');
% vehicle parameters and charger ratings
vehicle_parameters = readtable('C:\Users\FPSScripting2\Documents\Updated_Scripts\202001VehicleAssumptions_MATLAB_formatV3.xlsx');

% create arrays for storing the outputs to be saved:
% vehicle case
output_vehicle = cell(1,1);
% stated charger rating
output_charger_rating = zeros(1,1);
% store IDs
output_store_ID = zeros(1,1);
% year
output_year = zeros(1,1);
% final loop iteration maximum daily time per vehicle
yearly_revised_total_time = zeros(1,1);
% final loop iteration required number of vehicles
yearly_revised_vehicles = zeros(1,1);
% forecast future vehicles
yearly_forecast_vehicles = zeros(1,1);
% percentage increase of solution on forecast
increase_from_forecast = zeros(1,1);

% set scenario index for saving each output
scenario_index = 1;

% find the unique years from the input data
unique_years = unique(data.Year);

% for each vehicle case
for iVehicle = 1:height(vehicle_parameters)
    % find the vehicle name
    this_vehicle = vehicle_parameters.Model{iVehicle};

    % find the vehicle parameters
    this_vehicle_range = vehicle_parameters.Range_neg20pct_miles(iVehicle);
    fridge_power = 0.5;
    this_vehicle_energy = vehicle_parameters.Range_kWh_per_miles(iVehicle);
    this_vehicle_payload = vehicle_parameters.Max_payload_kg(iVehicle);
    this_vehicle_crates = vehicle_parameters.Max_crates(iVehicle);
    this_vehicle_chargers_str = vehicle_parameters.Charger_rating_neg10pct{iVehicle};
    this_vehicle_chargers_split = split(this_vehicle_chargers_str, ",");
    this_vehicle_chargers_stated_str = vehicle_parameters.Charger_rating{iVehicle};
    this_vehicle_chargers_stated_split = split(this_vehicle_chargers_stated_str, ",");
    
    % for each charger
    for iCharger = 1:length(this_vehicle_chargers_split)
        % find the stated and effective charger rating
        this_charger_rating = str2double(this_vehicle_chargers_split{iCharger});
        this_charger_stated_rating = str2double(this_vehicle_chargers_stated_split{iCharger});
        
        % display progress on command window
        clc
        fprintf('vehicle: %s, %d/%d\n',this_vehicle,iVehicle,height(vehicle_parameters))
        fprintf('charger: %dkW, %d/%d',this_charger_stated_rating,iCharger,length(this_vehicle_chargers_split))

        % for each year
        for iYear = 1:length(unique_years)
            % find this year and extract relevant year data
            this_year = unique_years(iYear);
            data_this_year = data(data.Year == this_year, :);

            % find unique stores with data in this year
            unique_store_IDs = unique(data_this_year.BranchID);
    
            % array for iterating revised vehicles for this year
            forecast_vehicles = [forecast_vehicle_numbers.StoreID forecast_vehicle_numbers.ForecastVehicles];
            revised_num_vehicles =  forecast_vehicle_numbers.ForecastVehicles;
    
            %%%%%%%%%%%%%%%%%%% LOOP FOR MAX MILES %%%%%%%%%%%%%%%%%%%%%%

            % create array for check of if total daily vehicle time is less than
            % max, initialise with 1s to enter while loop
            check_total_hours = ones(length(unique_store_IDs),1);

            % re-initialise while loop counter
            loop_num = 1;

            % while at least one store has a total_daily_vehicle_hours_3 value
            % exceeding the max allowed
            while sum(check_total_hours) > 0

                % create empty array to store the following vealues for each store
                max_weekly_miles = zeros(length(unique_store_IDs),1);
                associated_weekly_time = zeros(length(unique_store_IDs),1);
                associated_weekly_orders = zeros(length(unique_store_IDs),1);
                associated_weekly_peak_ratio = zeros(length(unique_store_IDs),1);
                % for each store 
                for iStore = 1:length(unique_store_IDs)
                    % find store ID and extract relevant data
                    this_store = unique_store_IDs(iStore);
                    data_this_store = data_this_year(data_this_year.BranchID == this_store,:);
                    % find the row number with the maximum weekly mileage and
                    % save the mileage in relevant array
                    max_miles_row = find(data_this_store.TotalMiles_inc_InboundStem_ == max(data_this_store.TotalMiles_inc_InboundStem_));
                    max_miles = data_this_store.TotalMiles_inc_InboundStem_(max_miles_row);
                    max_weekly_miles(iStore) = max_miles;

                    % save weekly time, orders, and implied peak day ratio
                    % associated with max mileage week to relevant arrays
                    associated_time = data_this_store.TotalTime_inc_InboundStem_(max_miles_row);
                    associated_weekly_time(iStore) = associated_time;
                    associated_orders = data_this_store.TotalOrders(max_miles_row);
                    associated_weekly_orders(iStore) = associated_orders;
                    associated_peak_ratio = max([data_this_store.Friday_Orders(max_miles_row) data_this_store.Saturday_Orders(max_miles_row)...
                        data_this_store.Sunday_Orders(max_miles_row) data_this_store.Monday_Orders(max_miles_row) data_this_store.Tuesday_Orders(max_miles_row)...
                        data_this_store.Wednesday_Orders(max_miles_row) data_this_store.Thursday_Orders(max_miles_row)])./associated_orders;
                    associated_weekly_peak_ratio(iStore) = associated_peak_ratio;

                end

                % enter non-vehicle parameters for this year with vals for each store
                order_mass = non_vehicle_parameters.order_mass(non_vehicle_parameters.Year == this_year);
                order_crates = non_vehicle_parameters.order_crates(non_vehicle_parameters.Year == this_year);
                earliest_start = non_vehicle_parameters.earliest_start(non_vehicle_parameters.Year == this_year);
                latest_end = non_vehicle_parameters.latest_end(non_vehicle_parameters.Year == this_year);
                charge_time = non_vehicle_parameters.charge_time(non_vehicle_parameters.Year == this_year);
                shift_length = non_vehicle_parameters.shift_length(non_vehicle_parameters.Year == this_year);

                % create arrays for this year with vals for each store, with: max order capacity, max individual shift
                % length, and max allowed time
                this_vehicle_max_orders = zeros(length(unique_store_IDs),1);
                this_vehicle_max_orders(:,:) = min([this_vehicle_payload./order_mass this_vehicle_crates./order_crates], [], 2);
                this_vehicle_max_shifts = zeros(length(unique_store_IDs),1);
                this_vehicle_max_shifts(:,:) = shift_length;
                this_vehicle_max_times = zeros(length(unique_store_IDs),1);
                this_vehicle_max_times(:,:) = latest_end - earliest_start;

        % 1. Adjust weekly miles to account for energy use of fridge

                fridge_miles_weekly = associated_weekly_time.*fridge_power./this_vehicle_energy;
                max_weekly_miles_inc_fridge = fridge_miles_weekly + max_weekly_miles;

        % 2. Calculate minimum number of weekly journeys by dividing adjusted
        % mileage by vehicle range

                min_num_weekly_journeys_2 = max_weekly_miles_inc_fridge./this_vehicle_range;

        % 3. Find the minimum number of weekly journeys per vehicle by dividing
        % the minimum weekly journeys by the revised vehicle number

                min_num_weekly_journeys_per_vehicle_1 = min_num_weekly_journeys_2./revised_num_vehicles;

        % 4. Find the maximum daily journeys per vehicle by multiplying minimum
        % weekly journeys by friday ratio and dividing by the revised number of
        % vehicles

                max_num_daily_journeys_per_vehicle_1 = min_num_weekly_journeys_2.*associated_weekly_peak_ratio./revised_num_vehicles;

        % 5. Find the hours per journey by dividing the weekly hours by the
        % minimum number of weekly journeys

                hours_per_journey_1 = associated_weekly_time./min_num_weekly_journeys_2;

        % 6. Miles per journey = Weekly miles / Min number of weekly journeys

                miles_per_journey_1 = max_weekly_miles_inc_fridge./min_num_weekly_journeys_2;

        % 7. Find the total energy required to complete a journey

                total_energy_per_journey_1 = miles_per_journey_1.*this_vehicle_energy;

        % 8. Find the minimum charge time per journey by dividing the energy
        % required by the charger rating

                charge_time_1 = total_energy_per_journey_1./this_charger_rating;

        % 9. Round charge time up to the next half an hour to estimate impact of
        % exponential charge time

                charge_time_1 = floor(charge_time_1) + ceil((charge_time_1-floor(charge_time_1))./0.5) .* 0.5;

        % 10. Find daily vehicle hours = (roundup(max daily vehicle journeys)- 1)*charge time
        % + max daily vehicle journeys * hours per journey

                total_daily_vehicle_hours_1 = (ceil(max_num_daily_journeys_per_vehicle_1)-1).*charge_time_1 + max_num_daily_journeys_per_vehicle_1.*hours_per_journey_1;

        % 11. Orders per journey = associated orders / min number weekly journeys

                orders_per_journey_1 = associated_weekly_orders./min_num_weekly_journeys_2;

        % 12. Min number of weekly journeys = associated orders/minimum(max
        % orders or orders_per_journey)

                min_num_weekly_journeys_3 = associated_weekly_orders./min([this_vehicle_max_orders orders_per_journey_1],[],2);

        % 13. Miles per journey = Weekly miles / Min number of weekly journeys 

                miles_per_journey_2 = max_weekly_miles_inc_fridge./min_num_weekly_journeys_3;

        % 14. Hours per journey = Acssociated weekly hours / Min number of weekly journeys

                hours_per_journey_2 = associated_weekly_time./min_num_weekly_journeys_3;

        % 15. Max daily journeys per vehicle = Min number of weekly journeys
        % * Friday peak ratio / revised number of vehicles

                max_num_daily_journeys_per_vehicle_2 = min_num_weekly_journeys_3.*associated_weekly_peak_ratio./revised_num_vehicles;

        % 16. Find the total energy required to complete a journey

                total_energy_per_journey_2 = miles_per_journey_2.*this_vehicle_energy;

        % 17. Find the minimum charge time per journey by dividing the energy
        % required by the charger rating

                charge_time_2 = total_energy_per_journey_2./this_charger_rating;

        % 18. Round charge time up to the next half an hour to estimate impact of
        % exponential charge time

                charge_time_2 = floor(charge_time_2) + ceil((charge_time_2-floor(charge_time_2))./0.5) .* 0.5;

        % 19. Total daily journey time per vehicle = Hours per journey * Max
        % daily journeys per vehicle + (roundup(max daily journeys per vehicle
        % )-1) * charge time

                total_daily_vehicle_hours_2 = (ceil(max_num_daily_journeys_per_vehicle_2)-1).*charge_time_2 + hours_per_journey_2.*max_num_daily_journeys_per_vehicle_2;

        % 20. min number of weekly journeys = associated weekly hours /
        % min(hours per journey, max journey length)

                min_num_weekly_journeys_4 = associated_weekly_time./min([this_vehicle_max_shifts hours_per_journey_2],[],2);

        % 21. Miles per journey = max weekly miles / min number of weekly journeys

                miles_per_journey_3 = max_weekly_miles_inc_fridge./min_num_weekly_journeys_4;

        % 22. Hours per journey = associated weekly hours / min number of
        % weekly journeys

                hours_per_journey_3 = associated_weekly_time./min_num_weekly_journeys_4;

        % 23. Max daily journeys per vehicle = Friday peak ratio * Min number
        % of weekly journeys / revised number of vehicles

                max_num_daily_journeys_per_vehicle_3 = associated_weekly_peak_ratio.*min_num_weekly_journeys_4./revised_num_vehicles;

        % 24. Find the total energy required to complete a journey

                total_energy_per_journey_3 = miles_per_journey_3.*this_vehicle_energy;

        % 25. Find the minimum charge time per journey by dividing the energy
        % required by the charger rating

                charge_time_3 = total_energy_per_journey_3./this_charger_rating;

        % 26. Round charge time up to the next half an hour to estimate impact of
        % exponential charge time

                charge_time_3 = floor(charge_time_3) + ceil((charge_time_3-floor(charge_time_3))./0.5) .* 0.5;

        % 27. Total daily journey time per vehicle = Hours per journey *
        % roundup(max daily journeys per vehicle) + (roundup(max daily journeys
        % per vehicle)-1) * charge time

                total_daily_vehicle_hours_3 = hours_per_journey_3.*ceil(max_num_daily_journeys_per_vehicle_3) + charge_time_3.*ceil(max_num_daily_journeys_per_vehicle_3-1);

        % 28. check that the  total daily vehicle hours for each store do not
        % exceed allowed max
                check_total_hours = total_daily_vehicle_hours_3 > this_vehicle_max_times;

        % 29. for stores where this check was failed, add 1 (output of logical
        % check) to revised vehicle number
                revised_num_vehicles = revised_num_vehicles + check_total_hours;

        % 30. iterate while loop counter
                loop_num = loop_num+1;

            end


            %%%%%%%%%%%%%%%%%%%%%%%%%%% LOOP FOR MAX TIME %%%%%%%%%%%%%%%%%%%%%%%%%

            % create array for check of if total daily vehicle time is less than
            % max, initialise with 1s to enter while loop
            check_total_hours = ones(length(unique_store_IDs),1);

            % re-initialise while loop counter
            loop_num = 1;

            % while at least one store has a total_daily_vehicle_hours_3 value
            % exceeding the max allowed
            while sum(check_total_hours) > 0

                % create empty array to store the following values for each store
                max_weekly_time = zeros(length(unique_store_IDs),1);
                associated_weekly_miles = zeros(length(unique_store_IDs),1);
                associated_weekly_orders = zeros(length(unique_store_IDs),1);
                associated_weekly_peak_ratio = zeros(length(unique_store_IDs),1);
                % for each store 
                for iStore = 1:length(unique_store_IDs)
                    % find store ID and extract relevant data
                    this_store = unique_store_IDs(iStore);
                    data_this_store = data_this_year(data_this_year.BranchID == this_store,:);

                    % find the row number with the maximum weekly time and
                    % save the time in relevant array
                    max_time_row = find(data_this_store.TotalTime_inc_InboundStem_ == max(data_this_store.TotalTime_inc_InboundStem_));
                    max_time = data_this_store.TotalTime_inc_InboundStem_(max_time_row);
                    max_weekly_time(iStore) = max_time;

                    % save weekly time, orders, and implied peak day ratio
                    % associated with max mileage week to relevant arrays
                    associated_miles = data_this_store.TotalMiles_inc_InboundStem_(max_time_row);
                    associated_weekly_miles(iStore) = associated_miles;
                    associated_orders = data_this_store.TotalOrders(max_time_row);
                    associated_weekly_orders(iStore) = associated_orders;
                    associated_peak_ratio = max([data_this_store.Friday_Orders(max_time_row) data_this_store.Saturday_Orders(max_time_row)...
                        data_this_store.Sunday_Orders(max_time_row) data_this_store.Monday_Orders(max_time_row) data_this_store.Tuesday_Orders(max_time_row)...
                        data_this_store.Wednesday_Orders(max_time_row) data_this_store.Thursday_Orders(max_time_row)])./associated_orders;
                    associated_weekly_peak_ratio(iStore) = associated_peak_ratio;

                end

                % enter non-vehicle parameters for this year with vals for each store
                order_mass = non_vehicle_parameters.order_mass(non_vehicle_parameters.Year == this_year);
                order_crates = non_vehicle_parameters.order_crates(non_vehicle_parameters.Year == this_year);
                earliest_start = non_vehicle_parameters.earliest_start(non_vehicle_parameters.Year == this_year);
                latest_end = non_vehicle_parameters.latest_end(non_vehicle_parameters.Year == this_year);
                charge_time = non_vehicle_parameters.charge_time(non_vehicle_parameters.Year == this_year);
                shift_length = non_vehicle_parameters.shift_length(non_vehicle_parameters.Year == this_year);

                % create arrays for this year with vals for each store, with: max order capacity, max individual shift
                % length, and max allowed time
                this_vehicle_max_orders = zeros(length(unique_store_IDs),1);
                this_vehicle_max_orders(:,:) = min([this_vehicle_payload./order_mass this_vehicle_crates./order_crates], [], 2);
                this_vehicle_max_shifts = zeros(length(unique_store_IDs),1);
                this_vehicle_max_shifts(:,:) = shift_length;
                this_vehicle_max_times = zeros(length(unique_store_IDs),1);
                this_vehicle_max_times(:,:) = latest_end - earliest_start;

        % 1. Adjust weekly miles to account for energy use of fridge

                fridge_miles_weekly = max_weekly_time.*fridge_power./this_vehicle_energy;
                associated_weekly_miles_inc_fridge = fridge_miles_weekly + associated_weekly_miles;

        % 2. Calculate minimum number of weekly journeys by dividing adjusted
        % mileage by vehicle range

                min_num_weekly_journeys_2 = associated_weekly_miles_inc_fridge./this_vehicle_range;

        % 3. Find the minimum number of weekly journeys per vehicle by dividing
        % the minimum weekly journeys by the revised vehicle number

                min_num_weekly_journeys_per_vehicle_1 = min_num_weekly_journeys_2./revised_num_vehicles;

        % 4. Find the maximum daily journeys per vehicle by multiplying minimum
        % weekly journeys by friday ratio and dividing by the revised number of
        % vehicles

                max_num_daily_journeys_per_vehicle_1 = min_num_weekly_journeys_2.*associated_weekly_peak_ratio./revised_num_vehicles;

        % 5. Find the hours per journey by dividing the weekly hours by the
        % minimum number of weekly journeys

                hours_per_journey_1 = max_weekly_time./min_num_weekly_journeys_2;

        % 6. Miles per journey = Weekly miles / Min number of weekly journeys

                miles_per_journey_1 = associated_weekly_miles_inc_fridge./min_num_weekly_journeys_2;

        % 7. Find the total energy required to complete a journey

                total_energy_per_journey_1 = miles_per_journey_1.*this_vehicle_energy;

        % 8. Find the minimum charge time per journey by dividing the energy
        % required by the charger rating

                charge_time_1 = total_energy_per_journey_1./this_charger_rating;

        % 9. Round charge time up to the next half an hour to estimate impact of
        % exponential charge time

                charge_time_1 = floor(charge_time_1) + ceil((charge_time_1-floor(charge_time_1))./0.5) .* 0.5;

        % 10. Find daily vehicle hours = (roundup(max daily vehicle journeys)- 1)*charge time
        % + max daily vehicle journeys * hours per journey

                total_daily_vehicle_hours_1 = (ceil(max_num_daily_journeys_per_vehicle_1)-1).*charge_time_1 + max_num_daily_journeys_per_vehicle_1.*hours_per_journey_1;

        % 11. Orders per journey = associated orders / min number weekly journeys

                orders_per_journey_1 = associated_weekly_orders./min_num_weekly_journeys_2;

        % 12. Min number of weekly journeys = associated orders/minimum(max
        % orders or orders_per_journey)

                min_num_weekly_journeys_3 = associated_weekly_orders./min([this_vehicle_max_orders orders_per_journey_1],[],2);

        % 13. Miles per journey = Weekly miles / Min number of weekly journeys 

                miles_per_journey_2 = associated_weekly_miles_inc_fridge./min_num_weekly_journeys_3;

        % 14. Hours per journey = Acssociated weekly hours / Min number of weekly journeys

                hours_per_journey_2 = associated_weekly_time./min_num_weekly_journeys_3;

        % 15. Max daily journeys per vehicle = Min number of weekly journeys
        % * Friday peak ratio / revised number of vehicles

                max_num_daily_journeys_per_vehicle_2 = min_num_weekly_journeys_3.*associated_weekly_peak_ratio./revised_num_vehicles;

        % 16. Find the total energy required to complete a journey

                total_energy_per_journey_2 = miles_per_journey_2.*this_vehicle_energy;

        % 17. Find the minimum charge time per journey by dividing the energy
        % required by the charger rating

                charge_time_2 = total_energy_per_journey_2./this_charger_rating;

        % 18. Round charge time up to the next half an hour to estimate impact of
        % exponential charge time

                charge_time_2 = floor(charge_time_2) + ceil((charge_time_2-floor(charge_time_2))./0.5) .* 0.5;

        % 19. Total daily journey time per vehicle = Hours per journey * Max
        % daily journeys per vehicle + (roundup(max daily journeys per vehicle
        % )-1) * charge time

                total_daily_vehicle_hours_2 = (ceil(max_num_daily_journeys_per_vehicle_2)-1).*charge_time_2 + hours_per_journey_2.*max_num_daily_journeys_per_vehicle_2;

        % 20. min number of weekly journeys = weekly hours /
        % min(hours per journey, max journey length)

                min_num_weekly_journeys_4 = max_weekly_time./min([this_vehicle_max_shifts hours_per_journey_2],[],2);

        % 21. Miles per journey = weekly miles / min number of weekly journeys

                miles_per_journey_3 = associated_weekly_miles_inc_fridge./min_num_weekly_journeys_4;

        % 22. Hours per journey = associated weekly hours / min number of
        % weekly journeys

                hours_per_journey_3 = max_weekly_time./min_num_weekly_journeys_4;

        % 23. Max daily journeys per vehicle = Friday peak ratio * Min number
        % of weekly journeys / revised number of vehicles

                max_num_daily_journeys_per_vehicle_3 = associated_weekly_peak_ratio.*min_num_weekly_journeys_4./revised_num_vehicles;

        % 24. Find the total energy required to complete a journey

                total_energy_per_journey_3 = miles_per_journey_3.*this_vehicle_energy;

        % 25. Find the minimum charge time per journey by dividing the energy
        % required by the charger rating

                charge_time_3 = total_energy_per_journey_3./this_charger_rating;

        % 26. Round charge time up to the next half an hour to estimate impact of
        % exponential charge time

                charge_time_3 = floor(charge_time_3) + ceil((charge_time_3-floor(charge_time_3))./0.5) .* 0.5;

        % 27. Total daily journey time per vehicle = Hours per journey *
        % roundup(max daily journeys per vehicle) + (roundup(max daily journeys
        % per vehicle)-1) * charge time

                total_daily_vehicle_hours_3 = hours_per_journey_3.*ceil(max_num_daily_journeys_per_vehicle_3) + charge_time_3.*ceil(max_num_daily_journeys_per_vehicle_3-1);

        % 28. Check that the total daily vehicle hours for each store do not
        % exceed allowed max
                check_total_hours = total_daily_vehicle_hours_3 > this_vehicle_max_times;

        % 29. For stores where this check was failed, add 1 (output of logical
        % check) to revised vehicle number
                revised_num_vehicles = revised_num_vehicles + check_total_hours;

        % 30. Iterate while loop counter
                loop_num = loop_num+1;

            end

            %%%%%%%%%%%%%%%%%%%%% LOOP FOR MAX ORDERS %%%%%%%%%%%%%%%%%%

            % create array for check of if total daily vehicle time is less than
            % max, initialise with 1s to enter while loop
            check_total_hours = ones(length(unique_store_IDs),1);

            % re-initialise while loop counter
            loop_num = 1;

            % while at least one store has a total_daily_vehicle_hours_3 value
            % exceeding the max allowed
            while sum(check_total_hours) > 0

                % create empty array to store the following vealues for each store
                max_daily_orders = zeros(length(unique_store_IDs),1);
                associated_weekly_orders = zeros(length(unique_store_IDs),1);
                associated_weekly_miles = zeros(length(unique_store_IDs),1);
                associated_weekly_time = zeros(length(unique_store_IDs),1);
                associated_weekly_peak_ratio = zeros(length(unique_store_IDs),1);
                % for each store 
                for iStore = 1:length(unique_store_IDs)
                    % find store ID and extract relevant data
                    this_store = unique_store_IDs(iStore);
                    data_this_store = data_this_year(data_this_year.BranchID == this_store,:);
                    % find the row number with the maximum weekly time and
                    % save the time in relevant array

                    % find the maximum order for each day of the week, and the
                    % weeks they occured in
                    [max_daily_order_by_week, max_day_row_weeks] = max([data_this_store.Friday_Orders data_this_store.Saturday_Orders data_this_store.Sunday_Orders...
                        data_this_store.Monday_Orders data_this_store.Tuesday_Orders data_this_store.Wednesday_Orders data_this_store.Thursday_Orders]);

                    % find the maximum daily orders for the entire year, and which
                    % of the days of the week it occurs on
                    [max_daily_order_for_year, max_day_col_indx] = max(max_daily_order_by_week);

                    % get the row (week) the max daily orders occur on by using the
                    % indexes of the max orders by day and the max of those
                    max_daily_order_row = max_day_row_weeks(max_day_col_indx);

                    % save the maximum daily orders for this store
                    max_daily_orders(iStore) = max_daily_order_for_year;

                    % find the associated mileage
                    associated_weekly_orders(iStore) = data_this_store.TotalOrders(max_daily_order_row);

                    % save weekly time, orders, and implied peak day ratio
                    % associated with max mileage week to relevant arrays
                    associated_miles = data_this_store.TotalMiles_inc_InboundStem_(max_daily_order_row);
                    associated_weekly_miles(iStore) = associated_miles;
                    associated_time = data_this_store.TotalTime_inc_InboundStem_(max_daily_order_row);
                    associated_weekly_time(iStore) = associated_time;
                    associated_orders = data_this_store.TotalOrders(max_daily_order_row);
                    associated_weekly_orders(iStore) = associated_orders;
                    associated_peak_ratio = max_daily_order_for_year./associated_orders;
                    associated_weekly_peak_ratio(iStore) = associated_peak_ratio;

                end

                % enter non-vehicle parameters for this year with vals for each store
                order_mass = non_vehicle_parameters.order_mass(non_vehicle_parameters.Year == this_year);
                order_crates = non_vehicle_parameters.order_crates(non_vehicle_parameters.Year == this_year);
                earliest_start = non_vehicle_parameters.earliest_start(non_vehicle_parameters.Year == this_year);
                latest_end = non_vehicle_parameters.latest_end(non_vehicle_parameters.Year == this_year);
                charge_time = non_vehicle_parameters.charge_time(non_vehicle_parameters.Year == this_year);
                shift_length = non_vehicle_parameters.shift_length(non_vehicle_parameters.Year == this_year);

                % create arrays for this year with vals for each store, with: max order capacity, max individual shift
                % length, and max allowed time
                this_vehicle_max_orders = zeros(length(unique_store_IDs),1);
                this_vehicle_max_orders(:,:) = min([this_vehicle_payload./order_mass this_vehicle_crates./order_crates], [], 2);
                this_vehicle_max_shifts = zeros(length(unique_store_IDs),1);
                this_vehicle_max_shifts(:,:) = shift_length;
                this_vehicle_max_times = zeros(length(unique_store_IDs),1);
                this_vehicle_max_times(:,:) = latest_end - earliest_start;

        % 1. Adjust weekly miles to account for energy use of fridge

                fridge_miles_weekly = associated_weekly_time.*fridge_power./this_vehicle_energy;
                associated_weekly_miles_inc_fridge = fridge_miles_weekly + associated_weekly_miles;

        % 2. Calculate minimum number of weekly journeys by dividing adjusted
        % mileage by vehicle range

                min_num_weekly_journeys_2 = associated_weekly_miles_inc_fridge./this_vehicle_range;

        % 3. Find the minimum number of weekly journeys per vehicle by dividing
        % the minimum weekly journeys by the revised vehicle number

                min_num_weekly_journeys_per_vehicle_1 = min_num_weekly_journeys_2./revised_num_vehicles;

        % 4. Find the maximum daily journeys per vehicle by multiplying minimum
        % weekly journeys by friday ratio and dividing by the revised number of
        % vehicles

                max_num_daily_journeys_per_vehicle_1 = min_num_weekly_journeys_2.*associated_weekly_peak_ratio./revised_num_vehicles;

        % 5. Find the hours per journey by dividing the weekly hours by the
        % minimum number of weekly journeys

                hours_per_journey_1 = associated_weekly_time./min_num_weekly_journeys_2;

        % 6. Miles per journey = Weekly miles / Min number of weekly journeys

                miles_per_journey_1 = associated_weekly_miles_inc_fridge./min_num_weekly_journeys_2;

        % 7. Find the total energy required to complete a journey

                total_energy_per_journey_1 = miles_per_journey_1.*this_vehicle_energy;

        % 8. Find the minimum charge time per journey by dividing the energy
        % required by the charger rating

                charge_time_1 = total_energy_per_journey_1./this_charger_rating;

        % 9. Round charge time up to the next half an hour to estimate impact of
        % exponential charge time

                charge_time_1 = floor(charge_time_1) + ceil((charge_time_1-floor(charge_time_1))./0.5) * 0.5;

        % 10. Find daily vehicle hours = (roundup(max daily vehicle journeys)- 1)*charge time
        % + max daily vehicle journeys * hours per journey

                total_daily_vehicle_hours_1 = (ceil(max_num_daily_journeys_per_vehicle_1)-1).*charge_time_1 + max_num_daily_journeys_per_vehicle_1.*hours_per_journey_1;

        % 11. Orders per journey = associated orders / min number weekly journeys

                orders_per_journey_1 = associated_weekly_orders./min_num_weekly_journeys_2;

        % 12. Min number of weekly journeys = associated orders/minimum(max
        % orders or orders_per_journey)

                min_num_weekly_journeys_3 = associated_weekly_orders./min([this_vehicle_max_orders orders_per_journey_1],[],2);

        % 13. Miles per journey = Weekly miles / Min number of weekly journeys 

                miles_per_journey_2 = associated_weekly_miles_inc_fridge./min_num_weekly_journeys_3;

        % 14. Hours per journey = Acssociated weekly hours / Min number of weekly journeys

                hours_per_journey_2 = associated_weekly_time./min_num_weekly_journeys_3;

        % 15. Max daily journeys per vehicle = Min number of weekly journeys
        % * Friday peak ratio / revised number of vehicles

                max_num_daily_journeys_per_vehicle_2 = min_num_weekly_journeys_3.*associated_weekly_peak_ratio./revised_num_vehicles;

        % 16. Find the total energy required to complete a journey

                total_energy_per_journey_2 = miles_per_journey_2.*this_vehicle_energy;

        % 17. Find the minimum charge time per journey by dividing the energy
        % required by the charger rating

                charge_time_2 = total_energy_per_journey_2./this_charger_rating;

        % 18. Round charge time up to the next half an hour to estimate impact of
        % exponential charge time

                charge_time_2 = floor(charge_time_2) + ceil((charge_time_2-floor(charge_time_2))./0.5) .* 0.5;

        % 19. Total daily journey time per vehicle = Hours per journey * Max
        % daily journeys per vehicle + (roundup(max daily journeys per vehicle
        % )-1) * charge time

                total_daily_vehicle_hours_2 = (ceil(max_num_daily_journeys_per_vehicle_2)-1).*charge_time_2 + hours_per_journey_2.*max_num_daily_journeys_per_vehicle_2;

        % 20. min number of weekly journeys = weekly hours /
        % min(hours per journey, max journey length)

                min_num_weekly_journeys_4 = associated_weekly_time./min([this_vehicle_max_shifts hours_per_journey_2],[],2);

        % 21. Miles per journey = weekly miles / min number of weekly journeys

                miles_per_journey_3 = associated_weekly_miles_inc_fridge./min_num_weekly_journeys_4;

        % 22. Hours per journey = associated weekly hours / min number of
        % weekly journeys

                hours_per_journey_3 = associated_weekly_time./min_num_weekly_journeys_4;

        % 23. Max daily journeys per vehicle = Friday peak ratio * Min number
        % of weekly journeys / revised number of vehicles

                max_num_daily_journeys_per_vehicle_3 = associated_weekly_peak_ratio.*min_num_weekly_journeys_4./revised_num_vehicles;

        % 24. Total daily journey time per vehicle = Hours per journey *
        % roundup(max daily journeys per vehicle) + (roundup(max daily journeys
        % per vehicle)-1) * charge time

                total_energy_per_journey_3 = miles_per_journey_3.*this_vehicle_energy;

        % 25. Find the total energy required to complete a journey

                charge_time_3 = total_energy_per_journey_3./this_charger_rating;

        % 26. Find the minimum charge time per journey by dividing the energy
        % required by the charger rating

                charge_time_3 = floor(charge_time_3) + ceil((charge_time_3-floor(charge_time_3))./0.5) .* 0.5;

        % 27. Round charge time up to the next half an hour to estimate impact of
        % exponential charge time

                total_daily_vehicle_hours_3 = hours_per_journey_3.*ceil(max_num_daily_journeys_per_vehicle_3) + charge_time_3.*ceil(max_num_daily_journeys_per_vehicle_3-1);

        % 28. Check that the  total daily vehicle hours for each store do not
        % exceed allowed max
                check_total_hours = total_daily_vehicle_hours_3 > this_vehicle_max_times;

        % 29. For stores where this check was failed, add 1 (output of logical
        % check) to revised vehicle number
                revised_num_vehicles = revised_num_vehicles + check_total_hours;

        % 30. Iterate while loop counter
                loop_num = loop_num+1;

            end

            % save outputs for this vehicle-charger-year combination
            output_vehicle(1+(scenario_index-1)*length(revised_num_vehicles):scenario_index*length(revised_num_vehicles),1) = {this_vehicle};
            output_charger_rating(1+(scenario_index-1)*length(revised_num_vehicles):scenario_index*length(revised_num_vehicles),1) = this_charger_stated_rating;
            output_store_ID(1+(scenario_index-1)*length(revised_num_vehicles):scenario_index*length(revised_num_vehicles),1) = unique_store_IDs;
            output_year(1+(scenario_index-1)*length(revised_num_vehicles):scenario_index*length(revised_num_vehicles),1) = this_year;
            yearly_revised_total_time(1+(scenario_index-1)*length(revised_num_vehicles):scenario_index*length(revised_num_vehicles),1) = total_daily_vehicle_hours_3;
            yearly_revised_vehicles(1+(scenario_index-1)*length(revised_num_vehicles):scenario_index*length(revised_num_vehicles),1) = revised_num_vehicles;
            yearly_forecast_vehicles(1+(scenario_index-1)*length(revised_num_vehicles):scenario_index*length(revised_num_vehicles),1) = forecast_vehicle_numbers.ForecastVehicles;
            increase_from_forecast(1+(scenario_index-1)*length(revised_num_vehicles):scenario_index*length(revised_num_vehicles),1) = (revised_num_vehicles - forecast_vehicle_numbers.ForecastVehicles)./forecast_vehicle_numbers.ForecastVehicles;
            
            scenario_index = scenario_index + 1;
        end
    end
end

% create table from separate output arrays

output_table = array2table([output_vehicle num2cell(output_charger_rating) num2cell(output_store_ID)...
    num2cell(output_year) num2cell(yearly_revised_total_time) num2cell(yearly_revised_vehicles) num2cell(yearly_forecast_vehicles) num2cell(increase_from_forecast)]);
output_table.Properties.VariableNames = {'Vehicle', 'Stated_charger_rating', 'Store_ID', 'Year',...
    'Max_daily_time_per_vehicle', 'Number_of_vehicles', 'Forecast_of_vehicles', 'Pct_increase_from_forecast'};

% save output table to an Excel spreadsheet
writetable(output_table, 'output_vehicle_numbers.xlsx');
 
% finish timing script
toc
    