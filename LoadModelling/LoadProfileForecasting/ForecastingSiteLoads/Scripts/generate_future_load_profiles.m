%% Script to forecast future electrical loads at site - BF, 30/04/2020

% user set version of run
run_version = '02';

% user set client
client = 'SSL';

% user set initials 
user_initials = 'BF';

% set user input file path
user_path = 'C:\Users\FPSScripting2\Documents\Consolidated_Models\LoadModelling\LoadProfileForecasting\ForecastingSiteLoads';

% extract year and month of run
run_year = num2str(year(datetime(now, 'ConvertFrom','datenum')));
run_year = run_year(3:4);
run_month = num2str(month(datetime(now, 'ConvertFrom','datenum')));
if length(run_month) == 1
    run_month = strcat('0', run_month);
end
run_date = strcat(run_year, '-', run_month);

%% Set parameters

% EV fleet file name
EV_fleet_filename = 'new_allCasesVerticalOutputFile_122_55.1_45.csv';

% EV customer file name
EV_customer_filename = '06-20.SSL.customer_charging_profile.01.BF.xlsx';

% read table of parameters used for forecasting
site_parameters = readtable(fullfile(user_path, 'Inputs\SiteParameters\future_parameters_by_site.xlsx'));

% find a structure containing information on the site load files
load_data_listing = dir(fullfile(user_path, 'Inputs\HistoricSiteLoadProfiles'));

% from the structure, extract the file names into an array
historic_load_filenames = cell(size(load_data_listing, 1), 1);
for iEntry = 1:size(load_data_listing, 1)
    historic_load_filenames{iEntry, 1} = load_data_listing(iEntry).name;
end

% find the unique site IDs
unique_sites = unique(site_parameters.Site_ID);

% initialise arrays for recording if no file/parameters was found (script
% diagnostics)
file_found = cell(length(unique_sites), 1);
parameters_found = cell(length(unique_sites), 1);

% for each of those sites
for iSite = 1:length(unique_sites)
	% set skip loop veriable to 0 
    insufficient_data = 0;
    % find this site ID
    this_site_ID = unique_sites(iSite)
    % find if any load profile file filenames contain the site ID
    file_logical_row = contains(historic_load_filenames, num2str(this_site_ID));
    % if no matching filename is found doesn't exist
    if sum(file_logical_row) == 0
        % record that no matching file existed
        file_found{iSite} = {'Load profile file not found'};
        % set insufficient data flag (skip rest of loop)
        insufficient_data = 1;
        continue
    end
    % record that a matching file existed
    file_found{iSite} = {'Load profile file found'};
    % find the matching file name
    historic_load_file_name = historic_load_filenames{file_logical_row, 1};
    % read consolidated site loads in
%     this_site_historic_load_data = readtable(fullfile(load_data_listing(file_logical_row).folder, historic_load_file_name)); % UNCOMMENT
    this_site_historic_load_data = readtable(fullfile('C:\Users\FPSScripting2\Documents\Consolidated_Models\LoadModelling\LoadProfileForecasting\ForecastingSiteLoads\Inputs\HistoricSiteLoadProfiles', historic_load_file_name));
    % extract the parameters for this site
    this_site_parameters = site_parameters(site_parameters.Site_ID == this_site_ID, :);
    % if parameters not provided
    if height(this_site_parameters) == 0
        % record that parameters didn't exist
        parameters_found{iSite} = {'Paramaters not set'};
        % set insufficient data flag (skip rest of loop)
        insufficient_data = 1;
    end
    % record that parameters existed
    parameters_found{iSite} = {'Parameters set'};
    % if required data/information not provided
    if insufficient_data == 1
        % skip the rest of this for loop iteration as not enough
        % data/information to forecast load
        continue
    end
    % find the years for which forecast parameters were set for this site
    year_to_forecast = unique(this_site_parameters.Year(this_site_parameters.Site_ID == this_site_ID));
    % for each year to forecast
    for iYear = 1:length(year_to_forecast)
        % extract this year
        this_year = year_to_forecast(iYear);
        % create copy of the histroic load data to forecast
        this_year_forecast_load_data = this_site_historic_load_data;
        % extract parameters for this forecast year
        this_year_parameters = this_site_parameters(this_site_parameters.Year == this_year, :);
        % set day of week names to display fully and find day of week of
        % each row
        DayForm = 'long';
        [DayNumber,DayName] = weekday(this_year_forecast_load_data.Date, DayForm);
        % create new table variable with dayoftheweek name in it
        this_year_forecast_load_data.DayOfWeek = cellstr(DayName);
        % find the datevactor for each row
        this_site_datevec = datevec(this_year_forecast_load_data.Date);
        % find the half hourly period of each row
        this_year_forecast_load_data.Period = round((this_site_datevec(:,4) + this_site_datevec(:,5)./60).*2);
        % initialise new variables
        this_year_forecast_load_data.FutureOperations(:,:) = 0;
        this_year_forecast_load_data.FutureOperationsSwitch(:,:) = 0;
        % find the unique days of the week in the data set
        unique_daysofweek = unique(this_year_forecast_load_data.DayOfWeek);
        % for each day of the week
        for iDay = 1:length(unique_daysofweek)
            % find the day of the week
            this_dayofweek = unique_daysofweek{iDay};
            % extract the half hourly period for the start and end of daily
            % operations for this day of the week
            this_dayofweek_start_operations = this_year_parameters{:,{['start_' this_dayofweek '_operations_hour']}};
            this_dayofweek_end_operations = this_year_parameters{:,{['end_' this_dayofweek '_operations_hour']}};
            % set future operations indexing
            this_year_forecast_load_data.FutureOperations(strcmp(this_year_forecast_load_data.DayOfWeek, this_dayofweek) & ...
                this_year_forecast_load_data.Period >= this_dayofweek_start_operations & ...
                this_year_forecast_load_data.Period <= this_dayofweek_end_operations) = 1;
            this_year_forecast_load_data.FutureOperationsSwitch(strcmp(this_year_forecast_load_data.DayOfWeek, this_dayofweek) & ...
                this_year_forecast_load_data.Period == this_dayofweek_start_operations & ...
                this_year_forecast_load_data.Period == this_dayofweek_end_operations) = 1;
        end
%% Refrigeration forecast
        % find the refrigeration day and night power consumption efficiencies relative to
        % historical refrigeration
        refrigeration_efficiency_day = this_year_parameters.refrigeration_efficiency_day;
        refrigeration_efficiency_night = this_year_parameters.refrigeration_efficiency_night;
        % forecast the refrigeration load by modifying power efficiencies
        % of historical day and night loads
        this_year_forecast_load_data.RefrigerationElectricity = this_year_forecast_load_data.RefrigerationElectricity.*...
            this_year_forecast_load_data.FutureOperations.*refrigeration_efficiency_day + ...
            this_year_forecast_load_data.RefrigerationElectricity.*...
            (1 - this_year_forecast_load_data.FutureOperations).*refrigeration_efficiency_night;
%% Lighting forecast
        % find the lighting day and night power consumption efficiencies relative to
        % historical lighting
        lighting_efficiency_day = this_year_parameters.lighting_efficiency_day;
        lighting_efficiency_night = this_year_parameters.lighting_efficiency_night;
        % forecast the lighting load by modifying power efficiencies
        % of lighting day and night loads
        this_year_forecast_load_data.LightingElectricity = this_year_forecast_load_data.LightingElectricity.*...
            this_year_forecast_load_data.FutureOperations.*lighting_efficiency_day + ...
            this_year_forecast_load_data.LightingElectricity.*...
            (1 - this_year_forecast_load_data.FutureOperations).*lighting_efficiency_night;
%% Heating forecast
        % extract parameters for heat loads
        convert_heating = this_year_parameters.convert_heating;
        heat_recovery = this_year_parameters.heat_recovery;
        ref_COP = this_year_parameters.refrigeration_COP;
        historical_gas_COP = this_year_parameters.historical_gas_COP;
        ashp_COP = this_year_parameters.ashp_COP;
        heat_ex_eff = this_year_parameters.heat_exchanger_efficiency;
        insulation_efficiency = this_year_parameters.insulation_efficiency;
        % if heating should be converted from gas to electricity
        if convert_heating == 1
            % if heat recovery should be utilised
            if heat_recovery == 1
                % find possible heat recovery at each period        
                heat_recovery_possible = (this_year_forecast_load_data.RefrigerationElectricity.*ref_COP +...
                    this_year_forecast_load_data.RefrigerationElectricity).*heat_ex_eff;
            else
                % if no heat recovery should be used, set possible heat recovery at
                % each period to zero
                heat_recovery_possible = zeros(height(this_year_forecast_load_data),1);
            end
            req_heat_pump_work = nansum([this_year_forecast_load_data.SiteGas, this_year_forecast_load_data.HVACBiomassHeat], 2)*historical_gas_COP*insulation_efficiency - heat_recovery_possible;
            req_heat_pump_load = req_heat_pump_work*(1/ashp_COP);
  
            this_year_forecast_load_data.HeatRecovery = heat_recovery_possible;
            this_year_forecast_load_data.HeatPumpWork = req_heat_pump_work;
            this_year_forecast_load_data.HeatPumpLoad = req_heat_pump_load;
            
            rows_neg = req_heat_pump_work < 0;

            this_year_forecast_load_data.HeatRecovery(rows_neg) = nansum([this_year_forecast_load_data.SiteGas(rows_neg), this_year_forecast_load_data.HVACBiomassHeat(rows_neg)], 2)*historical_gas_COP*insulation_efficiency;  
            this_year_forecast_load_data.HeatPumpWork(rows_neg) = 0;
            this_year_forecast_load_data.HeatPumpLoad(rows_neg) = 0;
            this_year_forecast_load_data.SiteGas(:,:) = 0;
        else
            this_year_forecast_load_data.SiteGas = ((this_year_forecast_load_data.SiteGas./historical_gas_COP).*future_gas_COP).*insulation_efficiency;
        end
% 
%% EV Load, use on an as needed case
%% EV charging fleet PENDING DATASET ADDION
        include_EV_fleet = this_site_parameters.EV_fleet;
        if include_EV_fleet == 1
            % find EVFleetCharging data for that year
%             EV_fleet_charging_data = 0; % TEMP
            EV_fleet_data = readtable(fullfile(user_path, 'Inputs\EVLoads', EV_fleet_filename));
            % sum inidivudal EV charging profiles
            n_vehicles = max(unique(EV_fleet_data.EV_number));
            for iVan = 1:n_vehicles
                this_vehicle_profile = EV_fleet_data(EV_fleet_data.EV_number == iVan, :);
                this_vehicle_profile.HH_Energy_Transfer(this_vehicle_profile.HH_Energy_Transfer < 0) = 0;
                if iVan ==1
                    total_charging = zeros(height(this_vehicle_profile), 1);
                end
                total_charging = total_charging + this_vehicle_profile.HH_Energy_Transfer;
            end
            max_rows = height(this_year_forecast_load_data);
            n_rows = size(total_charging, 1);
            total_charging(max_rows+1:n_rows, :) = [];
            this_year_forecast_load_data.EVFleetCharging = total_charging;
%             this_year_forecast_load_data.CarbonFleetFuel = 0;
        else
            % find CarbonFleetFuel data for that year
%             carbon_fleet_fuel_data = 0; % TEMP
            this_year_forecast_load_data.EVFleetCharging = 0;
%             this_year_forecast_load_data.CarbonFleetFuel = carbon_fleet_fuel_data;
        end
%  
%  Append external data set
        

%% EV charging customer PENDING DATASET ADDITION
        include_EV_customer = this_site_parameters.EV_customer;
        if include_EV_customer == 1
            EV_customer_data = readtable(fullfile(user_path, 'Inputs\EVLoads', EV_customer_filename));
            total_customer_charging_load = zeros(height(this_year_forecast_load_data), 1);
            for iDay = 1:7
                this_day_rows = find(weekday(this_year_forecast_load_data.Date) == iDay);
                n_days = size(this_day_rows, 1)/48;
                this_day_charging = [];
                for iRep = 1:floor(n_days)
                    this_day_charging = [this_day_charging; EV_customer_data.Load(EV_customer_data.Day == iDay)];
                end
                remainder_rows = n_days - floor(n_days);
                remainder_period = round(remainder_rows*48);
                this_day_charging = [this_day_charging; EV_customer_data.Load(EV_customer_data.Day == iDay & EV_customer_data.Period <= remainder_period)];
                total_customer_charging_load(this_day_rows, 1) = this_day_charging;
            end
            this_year_forecast_load_data.EVCustomerCharging = total_customer_charging_load;
%             this_year_forecast_load_data.EVCustomerCharging = EXTERNAL DATA SET:
        else
            this_year_forecast_load_data.EVCustomerCharging = 0;
        end
% %  Append external data set
%         run_date = char(datetime(floor(now),'ConvertFrom','datenum'));
%         split_run_date = split(run_date);
%         split_run_date{1}
% 
%         run_version

%% Save output table to outputs folder
        writetable(this_year_forecast_load_data ,fullfile(user_path, 'Outputs', strcat(run_date, '.', client, '.', num2str(this_site_ID), '_future_load_', num2str(this_year), '.', run_version, '.', user_initials, '.csv')));
    end
end