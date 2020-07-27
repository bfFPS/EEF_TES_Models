%% Script to distrubute perfect journey start and end times (uniform after generation) - BF, 02/2020

%% Set user run parameters and date

% user set version of run
run_version = '01';

% user set client
client = 'SSL';

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

% load in synthetic journeys
vehicle_journeys = readtable(fullfile(user_path, 'Outputs\20-06.JLP.T4_2020_synthetic_journeys.01.BF.csv'));

% max number of hours to shift each departure/end time by fo each shift pattern
% [single shift, double shift, triple shift]
departure_time_peturbations = [1.5, 1, 0.5];

% year of data set
unique_years = unique(year(vehicle_journeys.Start_Date_of_Route));

% find the unique store IDs contained in the synthetic journey dataset
unique_stores = unique(vehicle_journeys.Branch_ID);

% departure time of the first shift for each shift pattern
this_store_single_first = 8;
this_store_double_first = 6;
this_store_triple_first = 5.5;

%% Script begins


% for each unique store in the dataset
for iStore = 1:length(unique_stores)
    disp(iStore)
    % find the store ID
    this_store = unique_stores(iStore);

    % find the rows of journeys for this store
    this_store_idx = vehicle_journeys.Branch_ID == this_store;

    % for each year in the journey dataset
    for iYear = 1:length(unique_years)
        
        this_year = unique_years(iYear);
        % find the rows of journeys for this year
        this_year_idx = year(vehicle_journeys.Start_Date_of_Route) == this_year;
        % for each day of the year
        for iDay = 1:365
            % find the rows of journeys for this day
            % as dates for all years are aligned to 2019, 2020 requires a
            % correction as it is a leap year
            if this_year == 2020 && iDay > 59
                this_day_idx = day(vehicle_journeys.Start_Date_of_Route, 'dayofyear') == iDay+1;
            else
                this_day_idx = day(vehicle_journeys.Start_Date_of_Route, 'dayofyear') == iDay;
            end
            
            % combine the row indexing to find those for the relevant store/year/day
            % of year combination
            req_indx = this_store_idx & this_year_idx & this_day_idx;
            
            % if there are journeys this year for this store and day
            if sum(req_indx) > 0
                % find the departure times of those journeys in hours
                dep_time_hours = hour(vehicle_journeys.Start_Time_of_Route) + minute(vehicle_journeys.Start_Time_of_Route)/60;

                % find the unique departure times
                unique_dep_hours = unique(hour(vehicle_journeys.Start_Time_of_Route(req_indx)) + minute(vehicle_journeys.Start_Time_of_Route(req_indx))/60);

                % take the first unique departure time of that day, and
                % depending on which shift pattern it matches to, assign the
                % max perturbation for journey departure/end times
                this_departure_time = unique_dep_hours(1);
                this_perturbation = departure_time_peturbations(length(unique_dep_hours));

                % if there if only one unique departue time that day (single
                % shift day)
                if length(unique_dep_hours) == 1
                    % create vector of random numbers shifted by up to
                    % +this_perturbation/-this_perturbation
                    peturbations_vector = (this_perturbation-(-this_perturbation)).*rand(length(vehicle_journeys.Start_Time_of_Route(dep_time_hours == this_departure_time & req_indx)),1) + (-this_perturbation);
                    % add this random vector to the departure and end times of
                    % the journeys
                    vehicle_journeys.Start_Time_of_Route(dep_time_hours == this_departure_time & req_indx) = vehicle_journeys.Start_Time_of_Route(dep_time_hours == this_departure_time & req_indx)...
                        + hours(peturbations_vector);
                    vehicle_journeys.End_Time_of_Route(dep_time_hours == this_departure_time & req_indx) = vehicle_journeys.End_Time_of_Route(dep_time_hours == this_departure_time & req_indx)...
                        + hours(peturbations_vector);

                % else if there were two unique start and end times (double
                % shift day)
                elseif length(unique_dep_hours) == 2

                    % create vector of random numbers shifted by up to
                    % +this_perturbation/-this_perturbation
                    peturbations_vector = (this_perturbation-(-this_perturbation)).*rand(length(vehicle_journeys.Start_Time_of_Route(dep_time_hours == this_departure_time & req_indx)),1) + (-this_perturbation);


                    % add this random vector to the departure and end times of
                    % the first journeys
                    vehicle_journeys.Start_Time_of_Route(dep_time_hours == this_departure_time & req_indx) = vehicle_journeys.Start_Time_of_Route(dep_time_hours == this_departure_time & req_indx)...
                        + hours(peturbations_vector);
                    vehicle_journeys.End_Time_of_Route(dep_time_hours == this_departure_time & req_indx) = vehicle_journeys.End_Time_of_Route(dep_time_hours == this_departure_time & req_indx)...
                        + hours(peturbations_vector);


                    % update departure time to second shift
                    this_departure_time = unique_dep_hours(2);

                    % find the number of departures occuring at the second
                    % shift departure time
                    numb_departures = length(vehicle_journeys.Start_Time_of_Route(dep_time_hours == this_departure_time & req_indx));

                    % add random vector (1:number of second shift journeys) to the departure and end times of
                    % the second shift journeys
                    vehicle_journeys.Start_Time_of_Route(dep_time_hours == this_departure_time & req_indx) = vehicle_journeys.Start_Time_of_Route(dep_time_hours == this_departure_time & req_indx)...
                        + hours(peturbations_vector(1:numb_departures));
                    vehicle_journeys.End_Time_of_Route(dep_time_hours == this_departure_time & req_indx) = vehicle_journeys.End_Time_of_Route(dep_time_hours == this_departure_time & req_indx)...
                        + hours(peturbations_vector(1:numb_departures));

                % else if there were three unique start and end times (triple
                % shift day)
                elseif length(unique_dep_hours) == 3

                    % create vector of random numbers shifted by up to
                    % +this_perturbation/-this_perturbation
                    peturbations_vector = (this_perturbation-(-this_perturbation)).*rand(length(vehicle_journeys.Start_Time_of_Route(dep_time_hours == this_departure_time & req_indx)),1) + (-this_perturbation);


                    % add this random vector to the departure and end times of
                    % the first journeys
                    vehicle_journeys.Start_Time_of_Route(dep_time_hours == this_departure_time & req_indx) = vehicle_journeys.Start_Time_of_Route(dep_time_hours == this_departure_time & req_indx)...
                        + hours(peturbations_vector);
                    vehicle_journeys.End_Time_of_Route(dep_time_hours == this_departure_time & req_indx) = vehicle_journeys.End_Time_of_Route(dep_time_hours == this_departure_time & req_indx)...
                        + hours(peturbations_vector);

                    % update departure time to second shift
                    this_departure_time = unique_dep_hours(2);

                    % find the number of departures occuring at the second
                    % shift departure time
                    numb_departures = length(vehicle_journeys.Start_Time_of_Route(dep_time_hours == this_departure_time & req_indx));

                    % add random vector to the departure and end times of
                    % the second shift journeys
                    vehicle_journeys.Start_Time_of_Route(dep_time_hours == this_departure_time & req_indx) = vehicle_journeys.Start_Time_of_Route(dep_time_hours == this_departure_time & req_indx)...
                        + hours(peturbations_vector(1:numb_departures));
                    vehicle_journeys.End_Time_of_Route(dep_time_hours == this_departure_time & req_indx) = vehicle_journeys.End_Time_of_Route(dep_time_hours == this_departure_time & req_indx)...
                       + hours(peturbations_vector(1:numb_departures));

                    % update departure time to third shift
                    this_departure_time = unique_dep_hours(3);

                    % find the number of departures occuring at the third
                    % shift departure time
                    numb_departures = length(vehicle_journeys.Start_Time_of_Route(dep_time_hours == this_departure_time & req_indx));

                    % add random vector (1:number of second third journeys) to the departure and end times of
                    % the third shift journeys
                    vehicle_journeys.Start_Time_of_Route(dep_time_hours == this_departure_time & req_indx) = vehicle_journeys.Start_Time_of_Route(dep_time_hours == this_departure_time & req_indx)...
                        + hours(peturbations_vector(1:numb_departures));
                    vehicle_journeys.End_Time_of_Route(dep_time_hours == this_departure_time & req_indx) = vehicle_journeys.End_Time_of_Route(dep_time_hours == this_departure_time & req_indx)...
                        + hours(peturbations_vector(1:numb_departures));
                end
            end
        end
    end
end
    
vehicle_journeys.Start_Time_of_Route = dateshift(vehicle_journeys.Start_Time_of_Route, 'start', 'second');
vehicle_journeys.End_Time_of_Route = dateshift(vehicle_journeys.End_Time_of_Route, 'start', 'second');

% save final table to output folder
writetable(vehicle_journeys, fullfile(user_path, 'Outputs', strcat(run_date, '.', client, '.', 'T4_2020_varied_departure', '.', run_version, '.', user_initials, '.csv')));
