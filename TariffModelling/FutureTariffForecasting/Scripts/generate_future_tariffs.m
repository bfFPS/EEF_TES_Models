%% Script to forecast future tariff pricing based on historical tariffs - BF, 04/2020

%% Set user run parameters and date

% user set version of run
run_version = '02';

% user set client
client = 'JLP';

% user set initials 
user_initials = 'BF';

% set user input file path
user_path = 'C:\Users\FPSScripting2\Documents\Consolidated_Models\TariffModelling\FutureTariffForecasting';

% extract year and month of run
run_year = num2str(year(datetime(now, 'ConvertFrom','datenum')));
run_year = run_year(3:4);
run_month = num2str(month(datetime(now, 'ConvertFrom','datenum')));
if length(run_month) == 1
    run_month = strcat('0', run_month);
end
run_date = strcat(run_year, '-', run_month);

%% Script begins

% read in historical tariffs
historic_tariffs = readtable(fullfile(user_path, 'Inputs', '20-06.JLP.compiled_historical_tariffs.03.BF.csv'));

% read in DNO parameters by year
DNO_parameters = readtable(fullfile(user_path, 'Inputs', 'DNO_parameters.xlsx'));

% read in stores by DNO
stores_by_DNO = readtable(fullfile(user_path, 'Inputs', 'stores_by_DNO.xlsx'));

% read in policy charges
Policy_charges_in = readtable(fullfile(user_path, 'Inputs', 'Policy_charges_data.xlsx'));

% find unique DNOs
unique_DNO = unique(DNO_parameters.Area);

% find unique forecasting years
unique_years = unique(DNO_parameters.Year);

% final output table
compiled_forecasts = table;

% for each year
for iYear = 1:length(unique_years)
    this_year = unique_years(iYear);
    % extract DNO parameters for this year
    this_year_DNO_parameters = DNO_parameters(DNO_parameters.Year == this_year, :);
    % for each DNO region
    for iDNO = 1:length(unique_DNO)
        % find the DNO region
        this_DNO = unique_DNO(iDNO);
        % find the corresponding DNO parameters
        this_DNO_DNO_parameters = this_year_DNO_parameters(strcmp(this_year_DNO_parameters.Area, this_DNO), :);
        % load the corresponding historical tariff 
        this_DNO_historical_tariff = historic_tariffs(strcmp(historic_tariffs.Name, this_DNO), :);
        % set DUoS multipliers
        DUoS_min_mult = this_DNO_DNO_parameters.DUoS_min_mult;
        DUoS_max_mult = this_DNO_DNO_parameters.DUoS_max_mult;
        % find percentile price lies in
        DUoS_perc = invprctile(this_DNO_historical_tariff.DUoS,this_DNO_historical_tariff.DUoS);
        % multiply percentile by difference
        % add this product to min multiplier
        DUoS_val_mult = DUoS_perc/100*(DUoS_max_mult-DUoS_min_mult)+DUoS_min_mult;
        % multiply prices by this combined multiplier
        DUoS_future = this_DNO_historical_tariff.DUoS.*DUoS_val_mult;
        % green and amber bands increase relative to red
        DUoS_green_mult = this_DNO_DNO_parameters.DUoS_green_mult;
        DUoS_amber_mult = this_DNO_DNO_parameters.DUoS_amber_mult;
        DUoS_red_mult = this_DNO_DNO_parameters.DUoS_red_mult;
%         DUoS_red_mult = this_DNO_historical_tariff.DUoS.*DUoS_red_mult;
        % multiply by relevant mult
        DUoS_future(strcmp(this_DNO_historical_tariff.DUoS_band, 'Green')) = DUoS_future(strcmp(this_DNO_historical_tariff.DUoS_band, 'Green'))*DUoS_green_mult;
        DUoS_future(strcmp(this_DNO_historical_tariff.DUoS_band, 'Amber')) = DUoS_future(strcmp(this_DNO_historical_tariff.DUoS_band, 'Amber'))*DUoS_amber_mult;
        DUoS_future(strcmp(this_DNO_historical_tariff.DUoS_band, 'Red')) = DUoS_future(strcmp(this_DNO_historical_tariff.DUoS_band, 'Red'))*DUoS_red_mult;
        % subtract original mean OLD VARIABLE WAS n2ex CHNAGE REQUIRED TO
        % HISTORICAL ASSEMBLEY
        wholesale_vol = fillmissing(this_DNO_historical_tariff.Wholesale, 'spline') - nanmean(this_DNO_historical_tariff.Wholesale);
        % find where the wholesale price is now negative, and where positive
        neg_vol = find(wholesale_vol<0);
        pos_vol = find(wholesale_vol>=0);
        % find the magnitude of the wholesale value
        abs_wholesale = abs(wholesale_vol);
        % get the sign multiplier (+1/-1) of each value of wholesale
        wholesale_sign = wholesale_vol./abs_wholesale;
        % set min and max multipliers
        wholesale_min_mult = this_DNO_DNO_parameters.wholesale_min_mult;
        wholesale_max_mult = this_DNO_DNO_parameters.wholesale_max_mult;
        % find percentile price lies in
        % whlsle_perc = invprctile(fillmissing(complete_data_2.n2ex, 'spline'),fillmissing(complete_data_2.n2ex, 'spline'));
        whlsle_perc = invprctile(wholesale_vol,wholesale_vol);
        % multiply percentile by difference
        % add this product to min multiplier
        wholesale_val_mult = whlsle_perc/100*(wholesale_max_mult-wholesale_min_mult)+wholesale_min_mult;
        % multiply prices by this combined multiplier  
        wholesale_future = abs_wholesale.*wholesale_val_mult;
        wholesale_future = wholesale_future.*wholesale_sign;
        % add new mean
        wholesale_future_mean = this_DNO_DNO_parameters.wholesale_future_mean;
        wholesale_future = wholesale_future + wholesale_future_mean;
        
        
        % flatten TUoS
        TNUoS_charge_future = this_DNO_DNO_parameters.TNUoS_charge_future;
        TNUoS_future = zeros(1, height(this_DNO_historical_tariff));
        TNUoS_future(1:length(TNUoS_future)) = TNUoS_charge_future/(365*24);
        
        % policy charges increase (assume linear growth)

        policy_forecast = Policy_charges_in{height(Policy_charges_in), width(Policy_charges_in)} + (this_year-2021)*(Policy_charges_in{height(Policy_charges_in), width(Policy_charges_in)} - Policy_charges_in{height(Policy_charges_in), 2})/(width(Policy_charges_in)-2); 

        % assemble future tariff
        future_tariff = this_DNO_historical_tariff;
        % OLD VARIABLE WAS n2ex CHANGE REQUIRED TO
        % HISTORICAL ASSEMBLEY
        future_tariff.Wholesale = wholesale_future;
        future_tariff.Triad = TNUoS_future';
        future_tariff.DUoS = DUoS_future;
        future_tariff.Policy(:) = policy_forecast;
        
        future_tariff.Total_excl_triad = future_tariff.BSUoS + future_tariff.Wholesale + future_tariff.Triad + future_tariff.DUoS + future_tariff.Policy;
        future_tariff.Total_excl_triad = future_tariff.Total_excl_triad.*future_tariff.LLF.*future_tariff.OffTaking_TLF;
        
        compiled_forecasts = [compiled_forecasts; future_tariff];
        % save final output table to the output folder
%         writetable(future_tariff, fullfile(user_path, 'Outputs', strcat(run_date, '.', client, '.', this_DNO{:}, '_forecast_tariff_', num2str(this_year), '.', run_version, '.', user_initials, '.csv')));
    end
    % TEMP DELETE CLOCK CHANGE
    compiled_forecasts(compiled_forecasts.SettlementPeriod == 49 |compiled_forecasts.SettlementPeriod == 50, :) = [];
    
    % save final output table to the output folder
    writetable(compiled_forecasts, fullfile(user_path, 'Outputs', strcat(run_date, '.', client, '.', 'high', '_forecast_tariff_', num2str(this_year), '.', run_version, '.', user_initials, '.csv')));
end
