%% Script to generate synthetic journeys for each vehicle case/store/year - BF, 02/2020

%% Set user run parameters and date

% user set version of run
run_version = '01';

% user set client
client = 'JLP';

% user set initials 
user_initials = 'BF';

% set user input file path
user_path = 'C:\Users\FPSScripting2\Documents\Consolidated_Models\JourneyModelling\SyntheticJourneyGeneration';

% extract year and month of run
run_year = num2str(year(datetime(now, 'ConvertFrom','datenum')));
run_year = run_year(3:4);
run_month = num2str(month(datetime(now, 'ConvertFrom','datenum')));
if length(run_month) == 1
    run_month = strcat('0', run_month);
end
run_date = strcat(run_year, '-', run_month);

%% Set parameters

% set the maximum allowed journey duration (8 hours default)
max_shift = 8;

% sets a spacer to ensure consertive shift end/start times are at least
% this many hours apart (2 hours default)
journey_spacing = 2;

% initialise journey ID, ensure no overlap with historic ID
journey_ID = 10000000;

% set the mass per order and crates per order (calculated from historic
% data)
set_kgs = 41;
avg_crates_to_order = 5; 

% set base date, used to align future year days of the week with 2019 dates
base_year = [2019,1,1,0,0,0];

% set fridge power draw
fridge_power_kW = 0.5;

% years to generate journeys for
unique_years = [2020, 2021]; % when not including 2019
% unique_years = [2019, 2020, 2021]; % when including 2019

year_offset = 0; % when not including 2019
% year_offset = 1; % when including 2019

%% Script begins

% load file containing the weekly orders and daily orders by store/year
input_matrix = readtable(fullfile(user_path, 'Inputs\20-06.JLP.central_scenario_10.01.BF.csv'));
% load file containing the number of vehicles by vehicles case/store/year
future_vans = readtable(fullfile(user_path, 'Inputs\Future_vans_allv2.xlsx'));
% load file containing average departure times for each store synthetic
% journeys
average_departure_times = readtable(fullfile(user_path, 'Inputs\avg_departure_timev2.xlsx')); 
% load file with vehicle assumptions (parameters) for each vehicle case
vehicle_assumptions = readtable(fullfile(user_path, 'Inputs\202001VehicleAssumptions_MATLAB_formatv2.xlsx'));

% stop warnings displaying in command windows
warning('off','all')
warning

% store IDs and weeks to generate journeys for
unique_stores = average_departure_times.Branch_ID;
unique_weeks = unique(input_matrix.Week);

% for counting instances when doubling the vehicles could not satisfy the
% journeys required
couldnt_fulfill_orders = cell(height(vehicle_assumptions)*length(unique_stores)*length(unique_years), 4);
couldnt_fulfill_orders(:,4) = {0};


tic
% for each vehicle case in the input vehicle assumptions file
for iVehicle = 1:height(vehicle_assumptions) 
    % save vehicle assumption parameters as variables
    EV_range = vehicle_assumptions.Range_neg20pct_miles(iVehicle);
    EV_payload = vehicle_assumptions.Max_payload_kg(iVehicle);
    EV_crate = vehicle_assumptions.Max_crates(iVehicle);
    EV_power = vehicle_assumptions.Range_pos25pct_kWh_per_miles(iVehicle);
    % save name of vehicle case as a variable
    vehicle_case = vehicle_assumptions.Model(iVehicle);

    % for each year given in user input
    for iYear = 1:length(unique_years)
        % create table to store this vehicle case/year journeys, and reset index
        generated_journeys = table; 
        indx = 1;
        
        % set the year
        this_year = unique_years(iYear);


           
        % for each store assigned a departure time in the average departure times files
        for iStore = 1:length(unique_stores)
            % set the store ID
            this_branch_ID = unique_stores(iStore); 
            % set the first departure time for each shift pattern
            departure_time_single_shift = average_departure_times.Hours_single_shift(average_departure_times.Branch_ID == this_branch_ID);
            departure_time_double_shift_morning = average_departure_times.Hours_double_shift_morning(average_departure_times.Branch_ID == this_branch_ID);
            departure_time_triple_shift_first = average_departure_times.Hours_triple_shift_first(average_departure_times.Branch_ID == this_branch_ID);

            % create an array to indicate if days occured where offers couldnt
            % be satisfied
            couldnt_fulfill_orders{(iVehicle-1)*length(unique_stores)+(iStore-1)*length(unique_years) + iYear, 1} = vehicle_case; 
            couldnt_fulfill_orders{(iVehicle-1)*length(unique_stores)+(iStore-1)*length(unique_years) + iYear, 2} = this_branch_ID;
            couldnt_fulfill_orders{(iVehicle-1)*length(unique_stores)+(iStore-1)*length(unique_years) + iYear, 3} = this_year;
            
            % for each week
            for iWeek = 1:length(unique_weeks)
                % set the week number
                this_week = unique_weeks(iWeek);
                % clear command window and display script progress
                clc
                fprintf('vehicle %s : %d/%d\n', vehicle_case{:}, iVehicle, height(vehicle_assumptions))
                fprintf('year %d: %d/%d\n', this_year, iYear, length(unique_years))
                fprintf('branch %d : %d/%d\n', this_branch_ID, iStore, length(unique_stores))
                fprintf('week %d: %d/%d\n', this_week, iWeek, length(unique_weeks))
                
                % set EV range to modified
                EV_ranges = EV_range;
            
                % find minimum of journeys this week from input data (range constrained) 
                number_of_journeys = (1/EV_ranges)*input_matrix.TotalMiles_inc_InboundStem_(input_matrix.BranchID == this_branch_ID & input_matrix.Week == this_week & input_matrix.Year == this_year); % USE WHEN RECALCULATED MODEL
                
                % find the time per journey
                journey_times = input_matrix.TotalTime_inc_InboundStem_(input_matrix.BranchID == this_branch_ID & input_matrix.Week == this_week & input_matrix.Year == this_year)/number_of_journeys;
                
                % calculate equivalent of fridge energy consumption in
                % miles and adjust range
                energy_use_fridge = journey_times*fridge_power_kW;
                fridge_miles = energy_use_fridge/EV_power;
                EV_ranges = EV_ranges - fridge_miles;

                % recalculate number of journeys required (adjusted range
                % constrained)
                number_of_journeys = (1/EV_ranges)*input_matrix.TotalMiles_inc_InboundStem_(input_matrix.BranchID == this_branch_ID & input_matrix.Week == this_week & input_matrix.Year == this_year);

                % find orders per journey
                orders_per_journey = (1/number_of_journeys)*input_matrix.Orders(input_matrix.Store_ID == this_branch_ID & input_matrix.Week == this_week & input_matrix.Year == this_year);
                
                % set EV payload and crate capacities to modified
                EV_payloads = EV_payload;
                EV_crates = EV_crate;
                
                % check EV payload >= orders per journey * kgs per order
                payloads = orders_per_journey * set_kgs;
                payload_check = payloads > EV_payloads;
                
                % if payload is exceeded, find ratio of required to actual
                % payload,and update number of journeys, orders per
                % journey, and payload and range constraints accordingly
                if payload_check > 0
                    payload_reduction = EV_payloads/payloads;
                    orders_per_journey = orders_per_journey*number_of_journeys;
                    number_of_journeys = number_of_journeys/payload_reduction;
                    orders_per_journey = orders_per_journey/number_of_journeys;
                    EV_payloads = EV_payloads*payload_reduction;
                    EV_ranges = EV_ranges*payload_reduction;
                end
                
                % check EV crate capacity >= orders per journey * crates
                % per order
                crates = orders_per_journey * avg_crates_to_order;
                crate_check = crates > EV_crates;
                % if capacity is exceeded, find ratio of required to actual
                % crates, and update number of journeys, orders per
                % journey, and crate capacity and range constraints accordingly
                if crate_check > 0
                    crate_reduction = EV_crates/crates;
                    orders_per_journey = orders_per_journey*number_of_journeys;
                    number_of_journeys = number_of_journeys/crate_reduction;
                    orders_per_journey = orders_per_journey/number_of_journeys;
                    EV_crates = EV_crates*crate_reduction;
                    EV_ranges = EV_ranges*crate_reduction;
                end
                
                % check new journey times does not exceed maximum journey
                % length
                journey_times = input_matrix.Hours(input_matrix.Store_ID == this_branch_ID & input_matrix.Week == this_week & input_matrix.Year == this_year)/number_of_journeys;
                journey_times_check = journey_times > max_shift;
                % if journey length is exceeded, find ratio of required to actual
                % journey length, and update number of journeys, orders per
                % journey, range constraint and journey time accordingly
                if journey_times_check > 0
                    shift_reduction = max_shift/journey_times;
                    orders_per_journey = orders_per_journey*number_of_journeys;
                    number_of_journeys = number_of_journeys/shift_reduction;
                    orders_per_journey = orders_per_journey/number_of_journeys;
                    journey_times = journey_times*shift_reduction;
                    EV_ranges = EV_ranges*shift_reduction;
                end
                
                % update crate capacity and payload constraints
                
                crates = orders_per_journey * avg_crates_to_order;
                payloads = orders_per_journey * set_kgs;
            

                % Extract journeys to store by day of the week, using daily
                % ratio allocation from input matrix

                daily_journeys = [input_matrix.Tuesday_Orders(input_matrix.BranchID == this_branch_ID & input_matrix.Week == this_week & input_matrix.Year == this_year);...
                    input_matrix.Wednesday_Orders(input_matrix.BranchID == this_branch_ID & input_matrix.Week == this_week & input_matrix.Year == this_year);...
                    input_matrix.Thursday_Orders(input_matrix.BranchID == this_branch_ID & input_matrix.Week == this_week & input_matrix.Year == this_year);...
                    input_matrix.Friday_Orders(input_matrix.BranchID == this_branch_ID & input_matrix.Week == this_week & input_matrix.Year == this_year);...
                    input_matrix.Saturday_Orders(input_matrix.BranchID == this_branch_ID & input_matrix.Week == this_week & input_matrix.Year == this_year);...
                    input_matrix.Sunday_Orders(input_matrix.BranchID == this_branch_ID & input_matrix.Week == this_week & input_matrix.Year == this_year);...
                    input_matrix.Monday_Orders(input_matrix.BranchID == this_branch_ID & input_matrix.Week == this_week & input_matrix.Year == this_year)]/orders_per_journey; % indexed with Tuesday as start date
            
                % Find the number of vans assigned to this vehicle case/year/store
                % in future vans file
                vans_this_store = future_vans.FutureVans(future_vans.StoreNo_ == this_branch_ID & strcmp(future_vans.Vehicle_Case, vehicle_case)  & future_vans.Year == this_year);
                 % Divide daily journeys by no. of vans to get no. of journeys per van per day
                daily_journeys_per_van = daily_journeys/vans_this_store;

                % For each day of the week
                for iDay = 1:length(daily_journeys_per_van)
                    
                    % reset the number of vans required
                    vans_this_store = future_vans.FutureVans(future_vans.StoreNo_ == this_branch_ID & strcmp(future_vans.Vehicle_Case, vehicle_case)  & future_vans.Year == this_year); % recalculate if changed later
                    
                    % don't excced 365 days of journeys (as week 53 is partial)
                    if (this_week-1)*7 + iDay - 1 < 365 
                
                        % find number of journey required, time per
                        % journey, and EV range
                        this_day_journeys_per_van = daily_journeys_per_van(iDay);
                        this_day_journey_times = journey_times;
                        this_day_EV_range = EV_ranges; 
                        
                        % if the number of journeys per vehcile is less
                        % than one, only one shift is required
                        if this_day_journeys_per_van <= 1
                            n_journeys_single_shift = vans_this_store*this_day_journeys_per_van;
                            n_journeys_double_shift_AM = 0;
                            n_journeys_double_shift_PM = 0;
                            n_journeys_triple_shift_first = 0;
                            n_journeys_triple_shift_second = 0;
                            n_journeys_triple_shift_third = 0;
                            
                        % else if the number of journeys per vehicle is less
                        % than two, two shifts are required
                        elseif this_day_journeys_per_van <= 2
                            n_journeys_single_shift = 0;
                            n_journeys_double_shift_AM = vans_this_store;
                            n_journeys_double_shift_PM = daily_journeys(iDay) - vans_this_store;
                            n_journeys_triple_shift_first = 0;
                            n_journeys_triple_shift_second = 0;
                            n_journeys_triple_shift_third = 0;
                            
                        % else if the number of journeys per vehicle is less
                        % than three, three shifts are required
                        elseif this_day_journeys_per_van <= 3
                            n_journeys_single_shift = 0;
                            n_journeys_double_shift_AM = 0;
                            n_journeys_double_shift_PM = 0;
                            n_journeys_triple_shift_first = vans_this_store;
                            n_journeys_triple_shift_second = vans_this_store;
                            n_journeys_triple_shift_third = daily_journeys(iDay) - vans_this_store*2;
                        
                        % else then double the number of vehicles at this
                        % store, and perform same steps
                        else
                            
                            vans_this_store = vans_this_store*2;
                            
                            daily_journeys_per_van(iDay) = daily_journeys(iDay)/vans_this_store;
                            
                            this_day_journeys_per_van = daily_journeys_per_van(iDay);
                            this_day_journey_times = journey_times;
                            this_day_EV_range = EV_ranges; 
                        
                
                            if this_day_journeys_per_van <= 1
                                n_journeys_single_shift = vans_this_store*this_day_journeys_per_van;
                                n_journeys_double_shift_AM = 0;
                                n_journeys_double_shift_PM = 0;
                                n_journeys_triple_shift_first = 0;
                                n_journeys_triple_shift_second = 0;
                                n_journeys_triple_shift_third = 0;
                            
                            elseif this_day_journeys_per_van <= 2
                                n_journeys_single_shift = 0;
                                n_journeys_double_shift_AM = vans_this_store;
                                n_journeys_double_shift_PM = daily_journeys(iDay) - vans_this_store;
                                n_journeys_triple_shift_first = 0;
                                n_journeys_triple_shift_second = 0;
                                n_journeys_triple_shift_third = 0;
                            
                            elseif this_day_journeys_per_van <= 3
                                n_journeys_single_shift = 0;
                                n_journeys_double_shift_AM = 0;
                                n_journeys_double_shift_PM = 0;
                                n_journeys_triple_shift_first = vans_this_store;
                                n_journeys_triple_shift_second = vans_this_store;
                                n_journeys_triple_shift_third = daily_journeys(iDay) - vans_this_store*2;
                            
                                % if after doubling the number vehicles,
                                % the required joruensy for that day still
                                % cannot be completed in three shifts, then
                                % add to counter to indicate this
                            else
                                n_journeys_single_shift = 0;
                                n_journeys_double_shift_AM = 0;
                                n_journeys_double_shift_PM = 0;
                                n_journeys_triple_shift_first = 0;
                                n_journeys_triple_shift_second = 0;
                                n_journeys_triple_shift_third = 0;
                                couldnt_fulfill_orders{(iVehicle-1)*length(unique_stores)+(iStore-1)*length(unique_years) + iYear, 4} =...
                                    couldnt_fulfill_orders{(iVehicle-1)*length(unique_stores)+(iStore-1)*length(unique_years) + iYear, 4} + 1;
                            end

                            
                            
                        end
                
                        % single shift:
                        % assign journey ID, store ID, start date, start
                        % time (using avg departure time for this shift),
                        % end time, planned mileage, mass, crates, number
                        % of orders, and shift pattern indicator
                        
                        for iJourney = 1:n_journeys_single_shift
                            generated_journeys.Route_ID(indx) = journey_ID;
                            generated_journeys.Branch_ID(indx) = this_branch_ID;
                            generated_journeys.Start_Date_of_Route(indx) = datetime(base_year) + days((this_week-1)*7 + iDay - 1) + calyears(iYear-year_offset);  %    dd/MM/yyyy hh:mm:ss;
                            generated_journeys.Start_Time_of_Route(indx) = datetime(base_year) + days((this_week-1)*7 + iDay - 1) + hours(departure_time_single_shift) + calyears(iYear-year_offset);
                            generated_journeys.End_Time_of_Route(indx) = datetime(base_year) + days((this_week-1)*7 + iDay - 1) + hours(departure_time_single_shift + this_day_journey_times) + calyears(iYear-year_offset); % TBC dd-MM-yyyy hh:mm:ss
                            generated_journeys.Planned_total_Mileage(indx) = this_day_EV_range;
                            generated_journeys.Loaded_Kgs(indx) = set_kgs*orders_per_journey;
                            generated_journeys.Loaded_Total_Crates(indx) = avg_crates_to_order*orders_per_journey;
                            generated_journeys.Orders(indx) = orders_per_journey;
                            generated_journeys.Shift(indx) = 1;
                            journey_ID = journey_ID +1;
                            indx = indx + 1;
                        end
                        
                
                        % double shift:
                        % assign journey ID, store ID, start date, start
                        % time (using avg departure time for this shift),
                        % end time, planned mileage, mass, crates, number
                        % of orders, and shift pattern indicator
                        
                        for iJourney = 1:n_journeys_double_shift_AM
                            generated_journeys.Route_ID(indx) = journey_ID;
                            generated_journeys.Branch_ID(indx) = this_branch_ID;
                            generated_journeys.Start_Date_of_Route(indx) = datetime(base_year) + days((this_week-1)*7 + iDay - 1) + calyears(iYear-year_offset);
                            generated_journeys.Start_Time_of_Route(indx) = datetime(base_year) + days((this_week-1)*7 + iDay - 1) + hours(departure_time_double_shift_morning) + calyears(iYear-year_offset);
                            generated_journeys.End_Time_of_Route(indx) = datetime(base_year) + days((this_week-1)*7 + iDay - 1) + hours(departure_time_double_shift_morning + this_day_journey_times) + calyears(iYear-year_offset);
                            generated_journeys.Planned_total_Mileage(indx) = this_day_EV_range;
                            generated_journeys.Loaded_Kgs(indx) = set_kgs*orders_per_journey;
                            generated_journeys.Loaded_Total_Crates(indx) = avg_crates_to_order*orders_per_journey;
                            generated_journeys.Orders(indx) = orders_per_journey;
                            generated_journeys.Shift(indx) = 2.1;
                            journey_ID = journey_ID +1;
                            indx = indx + 1;
                        end
                        
                        % update departure time for second shift
                        departure_time_double_shift_afternoon = datetime(base_year) + days((this_week-1)*7 + iDay - 1) + hours(departure_time_double_shift_morning + this_day_journey_times + journey_spacing) + calyears(iYear-year_offset);
                
                        for iJourney = 1:n_journeys_double_shift_PM      
                            generated_journeys.Route_ID(indx) = journey_ID;
                            generated_journeys.Branch_ID(indx) = this_branch_ID;
                            generated_journeys.Start_Date_of_Route(indx) = datetime(base_year) + days((this_week-1)*7 + iDay - 1) + calyears(iYear-year_offset);
                            generated_journeys.Start_Time_of_Route(indx) = departure_time_double_shift_afternoon;
                            generated_journeys.End_Time_of_Route(indx) = departure_time_double_shift_afternoon + hours(this_day_journey_times);
                            generated_journeys.Planned_total_Mileage(indx) = this_day_EV_range;
                            generated_journeys.Loaded_Kgs(indx) = set_kgs*orders_per_journey;
                            generated_journeys.Loaded_Total_Crates(indx) = avg_crates_to_order*orders_per_journey;
                            generated_journeys.Orders(indx) = orders_per_journey;
                            generated_journeys.Shift(indx) = 2.2;
                            journey_ID = journey_ID +1;
                            indx = indx + 1;
                        end
                        

                        % triple shift
                        % assign journey ID, store ID, start date, start
                        % time (using avg departure time for this shift),
                        % end time, planned mileage, mass, crates, number
                        % of orders, and shift pattern indicator
                        
                       for iJourney = 1:n_journeys_triple_shift_first
                            generated_journeys.Route_ID(indx) = journey_ID;
                            generated_journeys.Branch_ID(indx) = this_branch_ID;
                            generated_journeys.Start_Date_of_Route(indx) = datetime(base_year) + days((this_week-1)*7 + iDay - 1) + calyears(iYear-year_offset);
                            generated_journeys.Start_Time_of_Route(indx) = datetime(base_year) + days((this_week-1)*7 + iDay - 1) + hours(departure_time_triple_shift_first) + calyears(iYear-year_offset);
                            generated_journeys.End_Time_of_Route(indx) = datetime(base_year) + days((this_week-1)*7 + iDay - 1) + hours(departure_time_triple_shift_first + this_day_journey_times) + calyears(iYear-year_offset);
                            generated_journeys.Planned_total_Mileage(indx) = this_day_EV_range;
                            generated_journeys.Loaded_Kgs(indx) = set_kgs*orders_per_journey;
                            generated_journeys.Loaded_Total_Crates(indx) = avg_crates_to_order*orders_per_journey;
                            generated_journeys.Orders(indx) = orders_per_journey;
                            generated_journeys.Shift(indx) = 3.1;
                            journey_ID = journey_ID +1;
                            indx = indx + 1;
                       end

                       % update departure time for second shift
                       departure_time_triple_shift_second = datetime(base_year) + days((this_week-1)*7 + iDay - 1) + hours(departure_time_triple_shift_first + this_day_journey_times + journey_spacing) + calyears(iYear-year_offset);
                
                        for iJourney = 1:n_journeys_triple_shift_second      
                            generated_journeys.Route_ID(indx) = journey_ID;
                            generated_journeys.Branch_ID(indx) = this_branch_ID;
                            generated_journeys.Start_Date_of_Route(indx) = datetime(base_year) + days((this_week-1)*7 + iDay - 1) + calyears(iYear-year_offset);
                            generated_journeys.Start_Time_of_Route(indx) = departure_time_triple_shift_second;
                            generated_journeys.End_Time_of_Route(indx) = departure_time_triple_shift_second + hours(this_day_journey_times);
                            generated_journeys.Planned_total_Mileage(indx) = this_day_EV_range;
                            generated_journeys.Loaded_Kgs(indx) = set_kgs*orders_per_journey;
                            generated_journeys.Loaded_Total_Crates(indx) = avg_crates_to_order*orders_per_journey;
                            generated_journeys.Orders(indx) = orders_per_journey;
                            generated_journeys.Shift(indx) = 3.2;
                            journey_ID = journey_ID +1;
                            indx = indx + 1;
                        end
                        
                        % update departure time for third shift
                        departure_time_triple_shift_third = departure_time_triple_shift_second + hours(this_day_journey_times + journey_spacing);
                        
                        for iJourney = 1:n_journeys_triple_shift_third   
                            generated_journeys.Route_ID(indx) = journey_ID;
                            generated_journeys.Branch_ID(indx) = this_branch_ID;
                            generated_journeys.Start_Date_of_Route(indx) = datetime(base_year) + days((this_week-1)*7 + iDay - 1) + calyears(iYear-year_offset);
                            generated_journeys.Start_Time_of_Route(indx) = departure_time_triple_shift_third;
                            generated_journeys.End_Time_of_Route(indx) = departure_time_triple_shift_third + hours(this_day_journey_times);
                            generated_journeys.Planned_total_Mileage(indx) = this_day_EV_range;
                            generated_journeys.Loaded_Kgs(indx) = set_kgs*orders_per_journey;
                            generated_journeys.Loaded_Total_Crates(indx) = avg_crates_to_order*orders_per_journey;
                            generated_journeys.Orders(indx) = orders_per_journey;
                            generated_journeys.Shift(indx) = 3.3;
                            journey_ID = journey_ID +1;
                            indx = indx + 1;
                        end
                        

                    end
                end
            end
        end
        
        % write the output journeys to an output csv file
        writetable(generated_journeys, fullfile(user_path, 'Outputs', strcat(run_date, '.', client, '.', vehicle_case{:}, '_', num2str(this_year), '_synthetic_journeys', '.', run_version, '.', user_initials, '.csv')));
    end
 
end

toc

