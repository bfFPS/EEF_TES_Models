%% Script to compile separate submetered data by store in consistent order and schema - BF, 11/06/2020
% Note that this script replaced an older Python script,
% ReadConcatProfiles--ConsistentSchema.ipynb

%% Set user run parameters and date

% user set version of run
run_version = '01';

% user set client
client = 'SSL';

% user set initials 
user_initials = 'BF';

% set user input file path
user_path = 'C:\Users\FPSScripting2\Documents\Consolidated_Models\ClientDataCleaningAndStatGeneration\EnergyMeterData\SSL\SiteLoadProfilesExtraction';

% extract year and month of run
run_year = num2str(year(datetime(now, 'ConvertFrom','datenum')));
run_year = run_year(3:4);
run_month = num2str(month(datetime(now, 'ConvertFrom','datenum')));
if length(run_month) == 1
    run_month = strcat('0', run_month);
end
run_date = strcat(run_year, '-', run_month);

%% Script begins

% read in schema, including names as they will be compiled from the raw
% data files and the corresponding name to replace with
profile_schema = readtable(fullfile(user_path, 'Inputs\Profile_Schema.xlsx'));
% set string to where files are stored
filedir = fullfile(user_path, 'Inputs\LoadProfiles');
% return a structure containing information on the folders contained within
% the directory
subfolders = dir(filedir);
% create an empty array to store the unique Store IDs
unique_site_ids = [];
% initialise the index
idx = 1;

COUNTER_TMP = 1;
VARIABLES_TMP = [];

% for each subfolder in the directory
for iSubfolder = 1:size(subfolders, 1)
    % extract the name of this subfolder
    this_subfolder = subfolders(iSubfolder).name;
    % initialise indicator that this is the first file exakined from this
    % site
    first_site_run = 1;
    % if the subfolder is not a hidden folder
    if strcmp(this_subfolder, '.')~=1 && strcmp(this_subfolder, '..')~=1
        % find unique store id
        split_subfolder = strsplit(this_subfolder, '_');
        this_site_id = split_subfolder(end);
        % return a structure containg information on the files conatined in
        % the subfolder
        this_site_dir = dir(fullfile(filedir, this_subfolder));
        % for each of these files
        for iFile = 1:size(this_site_dir, 1)
            % find the name of this file
            this_file = this_site_dir(iFile).name;
            % display name of file on console
            disp(this_file)
            % if the file is not a hidden file
            if strcmp(this_file, '.')~=1 && strcmp(this_file, '..')~=1
                % load the file
                this_data = readtable(fullfile(this_site_dir(iFile).folder, this_site_dir(iFile).name));
                % replace 'Actual (kW)' with variable name
                % extract the cell containing the meter name
                variable = this_data{1,1};
                % split the string at known delimeter (' at ')
                split_variable = strsplit(variable{:}, ' at ');
                % trim whitespace from first part of split. This is the
                % 'fuel type' (electricity/heat, consumption/production)
                fuel_type = strtrim(split_variable{1});
                % split the second part of the string at known delimeter
                % ('(')
                split_variable = strsplit(split_variable{2}, '(');
                % extract the subload from the first part of the split
                subload = strtrim(split_variable{1});
                % if site ID is contained in the subload, then the load is
                % store level (total electricity or gas), so set subload to
                % empty
                if contains(subload, this_site_id) == 1
                    subload = '';
                end
                % split second part of the split atknown delimeter ('-')
                split_variable = strsplit(split_variable{2}, '-');
                % tri whitespace and set load category
                load_category = strtrim(split_variable{1});
                % form variable name from separate components
                this_variable = strcat(load_category, subload, fuel_type, '_kW_');
                %%%%%%%%%%%%% TEMP
                VARIABLES_TMP{COUNTER_TMP} = this_variable;
                COUNTER_TMP = COUNTER_TMP + 1;
                %%%%%%%%%%%%% TEMP
                % find the row where the recorded data begins. Found
                % through known common data 'Date'
                row_data_start = find(strcmp(this_data{:,1}, 'Date'));
                % find the column where the subject meer data is recorded
                % (indicated by known string 'Actual (kW)')
                variable_col = find(strcmp(this_data{row_data_start,:}, 'Actual (kWh)'));
                % set this cell variable to the constructed variable name
                this_data{row_data_start,variable_col} = {this_variable};
                % set table variable names to variable names of recorded
                % data
                this_data.Properties.VariableNames = this_data{row_data_start, :};
                % delete unnecessary rows
                this_data(1:row_data_start, :) = [];
                % try deleting the temporary file if it exists
                try 
                    delete 'tmp_file.csv'
                % if this throws an error, do nothing
                catch
                    
                end
                % save file as temporary file and re-open to auto-detect datatypes of
                % each column correctly
                writetable(this_data, 'tmp_file.csv');
                this_data = readtable('tmp_file.csv');
                
                % initialise empty array of variable names to delete
                variables_to_remove = [];
                % intiailise array index
                idx_var = 1;
                % for each column
                for iCol = 1:length(this_data.Properties.VariableNames)
                    % find the variable name
                    this_variable_name = this_data.Properties.VariableNames(iCol);
                    % if this variable name is not included in the schema
                    if sum(strcmp(profile_schema.Variable_Name_portal, this_variable_name)) == 0
                        % add the variable to the array of variables to
                        % remove and update index
                        variables_to_remove{idx_var} = this_variable_name{:};
                        idx_var  = idx_var + 1;
                    end
                end
                % delete marked variables
                this_data = removevars(this_data, variables_to_remove);
                
                % if this is the first file for the site
                if first_site_run == 1
                    % set compiled loads equal to this load
                    compiled_loads = this_data;
                    % update that no longer firt site file
                    first_site_run = 0;
                % else if it's not the first run
                else
                    % remove loads which already exist AND aren't 'date'
                    % (pos 1)
                    variables_to_remove = [];
                    for iVar = 2:length(this_data.Properties.VariableNames)
                        idx_var = 1;
                        this_variable_name = this_data.Properties.VariableNames(iVar);
                        if sum(strcmp(compiled_loads.Properties.VariableNames, this_variable_name)) > 0
                            variables_to_remove{idx_var} = this_variable_name{:};
                            idx_var  = idx_var + 1;
                        end
                    end
                    % delete duplicate (excluding 'Date') variables
                    this_data = removevars(this_data, variables_to_remove);
                    
                    % join the compiled loads and new load table on the
                    % Date values
                    compiled_loads = innerjoin(compiled_loads, this_data, 'Keys', 'Date');
                    % remove invalid extra dates, caused by merge on clock
                    % change dates (repeated hours)
                    [v, w] = unique(compiled_loads.Date, 'stable' );
                    duplicate_indices = setdiff(1:numel(compiled_loads.Date), w);
                    compiled_loads(duplicate_indices(1:2:end),:) = [];
                end
            end
        end
        
        % add in variables which were not found for this site with NaN
        % values
        for iVariable = 1:length(profile_schema.Variable_Name_portal)
            this_variable_name = profile_schema.Variable_Name_portal(iVariable);
            if sum(strcmp(this_variable_name, compiled_loads.Properties.VariableNames)) == 0
                compiled_loads{:, this_variable_name} = NaN;
            end
        end
        % rearrange columns
        compiled_loads = compiled_loads(:, profile_schema.Variable_Name_portal);
        % rename columns
        compiled_loads.Properties.VariableNames = profile_schema.Var1;
        % set site id values
        compiled_loads.SiteID(:,:) = str2double(this_site_id{:});
        % save files to output folders
        writetable(compiled_loads, fullfile('Z:\Client Data\SSL\Energy Meter Data\Compiled Data', ...
            strcat(run_date, '.', client, '.', this_site_id{:}, '_', 'historic_compiled_loads', '.', run_version, '.', user_initials, '.csv')));

        writetable(compiled_loads, fullfile(user_path, 'Outputs', ...
            strcat(run_date, '.', client, '.', this_site_id{:}, '_', 'historic_compiled_loads', '.', run_version, '.', user_initials, '.csv')));
    end
end
