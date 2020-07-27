%% load complete profiles (13/09/2019)
% loads and concatenates store profiles into complete dataset

%% PLEASE CHANGE THE PATH 
savedir1 = 'C:\Users\benfl\OneDrive - Flexible Power Systems Ltd\Documents\PCM\SSL Interactions and Work\Load Profiles Sensitivity Forecast 26022020\MATLAB\Load Profiles - All'; 

mainFolder = savedir1;  % Use absolute paths
mainList  = dir(mainFolder);
subFolder = {mainList([mainList.isdir]).name};
subFolder(ismember(subFolder, {'.','..'})) = [];
Result = cell(1, numel(subFolder));
T = [];

load_schema_format = readtable('C:\Users\benfl\OneDrive - Flexible Power Systems Ltd\Documents\FPS Developer\SSL_data_cleaning_v3\Documentation\Profile_Schema_2.xlsx','ReadRowNames',true);

% Read in the separate '*_complete.xlsx' files and concatenate with each other

for iSub = 1:numel(subFolder)
    File = fullfile(mainFolder, subFolder{iSub});
    cd(File);
    allFiles = dir('*_complete.xlsx');
    n=length(allFiles); 
    data=cell(1,n);
    
    if n > 0 
        for i = 1
            disp(allFiles(i).name)
            store_profile = readmatrix(allFiles(i).name);  % read each file
            split_filename = string(split(allFiles(i).name,'_'));
            branch_id = str2double(split_filename(1));
            len = length(store_profile);
            [branch_id_array{1:len}] = deal(branch_id);
            branch_id_array = [branch_id_array{:}];
            branch_id_array = branch_id_array.';
            data{i} = [store_profile branch_id_array];
            data_table = readtable(allFiles(i).name);  % read each file
            clear branch_id_array
        end
    
    
        for i=2:n
            disp(allFiles(i).name)
            store_profile = readmatrix(allFiles(i).name);  % read each file
            this_tab = readtable(allFiles(i).name);  % read each file
            split_filename = string(split(allFiles(i).name,'_'));
            branch_id = str2double(split_filename(1));
            len = length(store_profile);
            [branch_id_array{1:len}] = deal(branch_id);
            branch_id_array = [branch_id_array{:}];
            branch_id_array = branch_id_array.';
            data{i} = [store_profile branch_id_array];
            data_table = [data_table; this_tab];
            clear branch_id_array
        end
    end
    
end

width_headings = size(load_schema_format,1);

[a_rows, a_cols] = size(data);
all_profiles_data = data{1,1};

% will throw error if include convenience stores

for a = 2:a_cols
    all_profiles_data = [all_profiles_data;data{1,a}];
end


%  Add BranchID as variable to data_table

data_table_NEW = addvars(data_table, all_profiles_data(:, size(all_profiles_data,2)), 'NewVariableNames', load_schema_format.Properties.RowNames{end}); % add branch ID data

%  Extract portal variable names from load_schema_format

variable_names_portal = load_schema_format.Variable_Name_portal;

% NEED TO ENSURE Variable Names (Portal) is of a format which MATLAB won't
% change to make a valid variable name. This requires it to also be the
% case when assigning names in the Python script

%  For each of these, check if the variable exists in the dataset
%  If it does not, insert it after the variable it should follow

empty_col_vals = zeros(height(data_table_NEW),1);

empty_col_vals(:,:) = NaN;

% Convert names as given in input to those specified in load_schema_format

for idx_name = 1:width(data_table_NEW)
    var_name = data_table_NEW.Properties.VariableNames{idx_name};
    var_loc = strcmp(variable_names_portal, var_name);
    if sum(var_loc) ~= 0
        data_table_NEW.Properties.VariableNames(idx_name) = load_schema_format.Properties.RowNames(var_loc);
    end
end

% Add in variables from load_schema_format which are not present in input
% data

for idx_name = 2:length(variable_names_portal) % <- assuming date is always first
    var_name = load_schema_format.Properties.RowNames{idx_name};
    if sum(strcmp(data_table_NEW.Properties.VariableNames, var_name)) == 0
        data_table_NEW = addvars(data_table_NEW, empty_col_vals, 'After', load_schema_format.Properties.RowNames(idx_name-1), 'NewVariableNames', load_schema_format.Properties.RowNames(idx_name));
    end
end

% Update headers

data_table_NEW.Properties.VariableNames = load_schema_format.Properties.RowNames;


% Find Aggregates which were not calculated/given in input (e.g. Miscellaneous)

to_calculate_aggregate_locs = find((load_schema_format.Aggregate & strcmp(load_schema_format.Variable_Name_portal, 'None')) == 1);

for idx_loc = 1:length(to_calculate_aggregate_locs)
    agg_var_name = load_schema_format.Properties.RowNames{to_calculate_aggregate_locs(idx_loc)};
    % create empty column for adding subs to
    agg_vals = zeros(height(data_table_NEW),1);
    % for each sub which is in the aggregate
    sub_load_locs = find(strcmp(load_schema_format.Category_of_Load, agg_var_name) ==1);
    for idx_sub = 1:length(sub_load_locs)
        sub_var_name = load_schema_format.Properties.RowNames(sub_load_locs(idx_sub));
        % add to new column
        agg_vals = nansum([agg_vals,  data_table_NEW{:,sub_var_name}], 2);
    end
    % swap values in aggregate for those in column
    data_table_NEW{:,agg_var_name} = agg_vals;
end

% Find Remainders which were not calculated/given in input (e.g. Miscellaneous)

to_calculate_remainder_electricity_locs = find((load_schema_format.Remainder & load_schema_format.Electrical) == 1);

for idx_loc = 1:length(to_calculate_remainder_electricity_locs)
    rmd_var_name = load_schema_format.Properties.RowNames{to_calculate_remainder_electricity_locs(idx_loc)};
    % find main electrical values
    rmd_vals = data_table_NEW{:,load_schema_format.Main & load_schema_format.Electrical};
    % find locs of electrical aggregates
    aggs_locs = find((load_schema_format.Aggregate & load_schema_format.Electrical) == 1);
    % for each of these
    for idx_agg = 1:length(aggs_locs)
        agg_var_name = load_schema_format.Properties.RowNames(aggs_locs(idx_agg));
        % subtract values from copy of main
        rmd_vals = nansum([rmd_vals, -data_table_NEW{:,agg_var_name}], 2);
    end 
    % assign column value to rmd_var_name
    data_table_NEW{:,rmd_var_name} = rmd_vals;
end

% cd 'C:\Users\benfl\OneDrive\Documents\PCM\Matlab\'
% run('C:\Users\benfl\OneDrive\Documents\PCM\Matlab\Load_allData.m')
