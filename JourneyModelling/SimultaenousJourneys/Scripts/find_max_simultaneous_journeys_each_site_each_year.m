%% Script to find the number of simultaneous journeys occuring - BF, 27/05/2020
% reference 1 - https://www.itprotoday.com/sql-server/calculating-concurrent-sessions-part-3

%% Set user run parameters and date

% user set version of run
run_version = '01';

% user set client
client = 'SSL';

% user set initials 
user_initials = 'BF';

% set user input file path
user_path = 'C:\Users\FPSScripting2\Documents\Consolidated_Models\JourneyModelling\SimultaenousJourneys';

% extract year and month of run
run_year = num2str(year(datetime(now, 'ConvertFrom','datenum')));
run_year = run_year(3:4);
run_month = num2str(month(datetime(now, 'ConvertFrom','datenum')));
if length(run_month) == 1
    run_month = strcat('0', run_month);
end
run_date = strcat(run_year, '-', run_month);

%% Script begins

% load in the journey data set and sort
route_data_raw = readtable(fullfile(user_path, 'Inputs\cleaned_route_data_all.csv'));

% route_data = sortrows(route_data_raw);
route_data = route_data_raw;
route_data = route_data(year(route_data.Start_Date_of_Route) == 2019, :);

% create empty arrays to store results
year_out = [];
site_ID_out = [];
site_name_out = [];
date_out = NaT;
sim_journeys_out = [];

% find the unique site IDs
unique_sites = unique(route_data.Branch_ID);

% initialise counter
iOut = 1;

tic
% for each site
for iSite = 1:length(unique_sites)
    % find the site ID
    this_site = unique_sites(iSite);
    disp(this_site)
    % extract the site data
    this_site_data = route_data(route_data.Branch_ID == this_site, :);
    % find the site name
    site_name = unique(this_site_data.FL_Name);
    % find the years of data present for the site
    unique_years = unique(year(this_site_data.Start_Date_of_Route));
% for each year
    for iYear = 1:length(unique_years)
        % find the year
        this_year = unique_years(iYear);
        % extract the year data
        this_year_data = this_site_data(year(this_site_data.Start_Date_of_Route) == this_year, :); 
        
        % extract start times and sort
        ts = this_year_data.Start_Date_of_Route + hours(hour(this_year_data.Start_Time_of_Route)) + minutes(minute(this_year_data.Start_Time_of_Route)) + seconds(second(this_year_data.Start_Time_of_Route));
        ts = sortrows(ts);
        % label start times as 1
        type = ones(size(ts, 1), 1);
        % give each sorted start time an index
        start_ordinal = 1:size(ts, 1);
        start_ordinal = start_ordinal';

        % create table of start times and sort
        start_times_table = table(ts, type, start_ordinal, 'VariableNames', {'ts', 'type', 'start_ordinal'});
        start_times_table = sortrows(start_times_table);

        % extract end times and sort
        ts = this_year_data.Start_Date_of_Route + hours(hour(this_year_data.End_Time_of_Route)) + minutes(minute(this_year_data.End_Time_of_Route)) + seconds(second(this_year_data.End_Time_of_Route));
        ts = sortrows(ts);
        % label end times as -1
        type = ones(size(ts, 1), 1);
        type = type*-1;
        % label index of each end time as NaN
        start_ordinal = NaN(size(ts, 1), 1);

        % create table of end times
        end_times_table = table(ts, type, start_ordinal, 'VariableNames', {'ts', 'type', 'start_ordinal'});

        % find the union of the two data sets
        union_times = union(start_times_table, end_times_table);

        % create index for all rows and add to union
        start_or_end = [1:height(union_times)]';
        union_times = addvars(union_times, start_or_end);

        % find the simultaneous events
        simultaneous = 2*union_times.start_ordinal - union_times.start_or_end;

        % find the max simultaneous events which occurs
        max_simultaneous_events = max(simultaneous);
        
        % update results
        year_out(iOut,1) = this_year;
        site_ID_out(iOut,1) = this_site;
        site_name_out{iOut,1} = site_name;
        sim_journeys_out(iOut,1) = max_simultaneous_events;
        max_route_times = union_times.ts(simultaneous == max_simultaneous_events);
        date_out(iOut,1) = max_route_times(1);
       
        
        % update counter
        iOut = iOut+1;
    end
end

toc

% create the output table
output_table = table(year_out, site_ID_out, site_name_out, sim_journeys_out, date_out,...
    'VariableNames', {'Year', 'Site_ID', 'Site_Name', 'Max_Sim_Journeys', 'Time_of_Sim_Journeys'});
output_table = sortrows(output_table, 'Year');

% save final output table with datestamp to the output folder
writetable(output_table, fullfile(user_path, 'Outputs', strcat(run_date, '.', client, '.', 'max_simultaneous_journeys', '.', run_version, '.', user_initials, '.csv')));
