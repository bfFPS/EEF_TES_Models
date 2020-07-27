%% SCRIPT TO LOAD AND FORMAT TARIFFS, CALCULATE SAVINGS, AND PLOT VARIOUS SAVINGS AND DISTRIBUTIONS - BF, 22/04/2020

%% Set user run parameters and date

% user set version of run
run_version = '03';

% user set client
client = 'JLP';

% user set initials 
user_initials = 'BF';

% set user input file path
user_path = 'C:\Users\FPSScripting2\Documents\Consolidated_Models\TariffModelling\HistoricalComponentAssembly';

% extract year and month of run
run_year = num2str(year(datetime(now, 'ConvertFrom','datenum')));
run_year = run_year(3:4);
run_month = num2str(month(datetime(now, 'ConvertFrom','datenum')));
if length(run_month) == 1
    run_month = strcat('0', run_month);
end
run_date = strcat(run_year, '-', run_month);

%% Set parameters

use_triads = 1;

LLF_possible_start_periods = 5;

%% Script begins

%% LOAD IN DATA

documents = {'Policy_charges_data.xlsx', '40209-Triad Dates.xlsx',...
    'Final TNUoS Tariffs for 2018-19 - Tables.xlsm', 'Current_RF_BSUoS_Data_175.xls',...
    'Current_SF_BSUoS_Data_184.xls', '0000001780_tlm.csv', 'n2ex-day-ahead-auction-prices_2019_hourly_gbp.xlsx',...
    'n2ex-day-ahead-auction-prices_2018_hourly_gbp.xlsx', 'n2ex-day-ahead-auction-prices_2017_hourly_gbp.xlsx',...
    'TNUoS_formatted.xlsx', 'LLF_input.xlsx', 'TLM_in.csv', 'Carbon_Intensity_Data.csv', 'final_component_order_and_factors.xlsx'};
titles = {'Policy_charges_in', 'Triad_Dates', 'TNUoS_Tariffs', 'BSUoS_RF', 'BSUoS_SF', 'TLF', 'n2ex_2019', 'n2ex_2018', 'n2ex_2017', 'TNUoS_formatted', 'LLF_raw', 'TLM_raw', 'carbon_intensity'}; % included for reference, variable not used in code

DUoS_documents = {'London Power Networks - Schedule of charges and other tables - 2017 V3.2.xlsx',...
    'London Power Networks - Schedule of charges and other tables - 2018 V.3.4.xlsx',...
    'London Power Networks - Schedule of charges and other tables - 2019 V2.2.xlsx',...
    'Eastern Power Networks - Schedule of charges and other tables - 2017 V3.2.xlsx',...
    'Eastern Power Networks - Schedule of charges and other tables - 2018 V.3.6.xlsx',...
    'Eastern Power Networks - Schedule of charges and other tables - 2019 V2.2.xlsx',...
    'South Eastern Power Networks - Schedule of charges and other tables - 2017 V3.2.xlsx',...
    'South Eastern Power Networks - Schedule of charges and other tables - 2018 V.3.5.xlsx',...
    'South Eastern Power Networks - Schedule of charges and other tables - 2019 V2.2.xlsx',...
    'DUoS_formatted_2.xlsx'}; % individual DUoS documents are assembled to DUoS_formatted_2.xlsx manually
DUoS_titles = {'DSUoS_London_2017', 'DSUoS_London_2018', 'DSUoS_London_2019', 'DSUoS_Eastern_2017', 'DSUoS_Eastern_2018', 'DSUoS_Eastern_2019',...
    'DSUoS_South_Eastern_2017', 'DSUoS_South_Eastern_2018', 'DSUoS_South_Eastern_2019', 'DUoS_formatted'}; % included for reference, variable not used in code

Policy_charges_in = readtable(fullfile(user_path, 'Inputs', documents{1}));
Triad_Dates = readtable(fullfile(user_path, 'Inputs', documents{2}), 'Sheet', 'Sheet1');
% TNUoS_Tariffs = readtable(fullfile(user_path, 'Inputs', documents{3}), 'Sheet', 'T2');
BSUoS_RF = readtable(fullfile(user_path, 'Inputs', documents{4}));
BSUoS_SF = readtable(fullfile(user_path, 'Inputs', documents{5}));
TLF = readtable(fullfile(user_path, 'Inputs', documents{6}));
% n2ex_2019 = readtable(fullfile(user_path, 'Inputs', documents{7}));
% n2ex_2018 = readtable(fullfile(user_path, 'Inputs', documents{8}));
% n2ex_2017 = readtable(fullfile(user_path, 'Inputs', documents{9}));
TNUoS_formatted = readtable(fullfile(user_path, 'Inputs', documents{10}));
LLF_raw = readtable(fullfile(user_path, 'Inputs', documents{11}));
% TLM_raw = readtable(fullfile(user_path, 'Inputs', documents{12}));
% carbon_intensity = readtable(fullfile(user_path, 'Inputs', documents{13}));
final_component_order_and_factors = readtable(fullfile(user_path, 'Inputs', documents{14}));

DNO_region_labelling = readtable(fullfile(user_path, 'Inputs', 'DNO_region_labelling.xlsx'));
% dates_formatted = readtable(fullfile(user_path, 'Inputs', 'dates_formatted.xlsx'));
wholesale = readtable(fullfile(user_path, 'Inputs', 'wholesale_all_years_formatted.xlsx'));

DUoS_formatted = readtable(fullfile(user_path, 'Inputs\DUoS', DUoS_documents{10}));

%% Format date and period consistently across data sets
% Required for handling clock change correctly when performing inner-outer
% joins 
% Done out of script as pre-processing


%% FIND BSUoS DATA FROM RF PERIODS - USE OUTERJOIN TO MATCH UP DATES

% - join RF and SF BSUoS with outerjoin function
BSUoS_joined = outerjoin(BSUoS_RF,BSUoS_SF,'Keys',[1 2], 'MergeKeys', 1);

% find where RF price is NaN
nan_RF = isnan(BSUoS_joined.BSUoSPrice___MWhHour__BSUoS_RF);
% replace with NaN RF prices with SF
BSUoS_joined.BSUoSPrice___MWhHour__BSUoS_RF(nan_RF) = BSUoS_joined.BSUoSPrice___MWhHour__BSUoS_SF(nan_RF);
% remove unncessary variables and rename remaining
BSUoS_joined = removevars(BSUoS_joined, {'Half_hourlyCharge_BSUoS_RF', 'TotalDailyBSUoSCharge_BSUoS_RF',...
    'RunType_BSUoS_RF', 'BSUoSPrice___MWhHour__BSUoS_SF', 'Half_hourlyCharge_BSUoS_SF', 'TotalDailyBSUoSCharge_BSUoS_SF', 'RunType_BSUoS_SF'});
BSUoS_joined.Properties.VariableNames{'BSUoSPrice___MWhHour__BSUoS_RF'} = 'BSUoS';

% swap move SettlementPeriod to second position of table
TLF_ro = movevars(TLF, 'SettlementPeriod', 'After', 'SettlementDate');
% merge GSP regions (1-14) with names
TLF_ro = outerjoin(TLF_ro, DNO_region_labelling, 'Keys', 4, 'MergeKeys', 1);
% rename TLF variables
TLF_ro.Properties.VariableNames{'OffTaking'} = 'OffTaking_TLF';
TLF_ro.Properties.VariableNames{'Delivering'} = 'Delivering_TLF';
% delete unnecessary variables
TLF_ro = removevars(TLF_ro, {'DNOID', 'Operator', 'GSPGroupID', 'MarketParticipantID'});
% outerjoin re-ordered TLF with other BSUoS
BSUoS_TLF_joined = outerjoin(BSUoS_joined, TLF_ro, 'Keys',[1 2], 'MergeKeys', 1);



%% CONCATENATE WHOLESALE DATA, CONVERT PERIOD TO HH PERIOD AND FIND DATA FROM SF PERIODS
% note that whitespace in period data in wholesale (e.g. '23 - 00') is
% non-breakingspace and so cannot be removed by matlab functions
BSUoS_TLF_wholesale_joined = outerjoin(BSUoS_TLF_joined, wholesale, 'Keys', [1 2], 'MergeKeys', 1);



%% EXTRACT CLIMATE CHANGE LEVY AND POPULATE CORRECT ROWS WITH IT, THEN ADD AS NEW VARIABLE TO TARIFF_DATA
% create empty array height of tariff_data to fill with policy cost
policy_charges_data = zeros(size(BSUoS_TLF_wholesale_joined,1), 1);

% - for each policy cost in order of latest date to oldest date, find date which
%   policy cost levy applies from, convert this date to a datenum; find rows in
%   tariff_data which are this date; if there are rows -> set policy cost for all
%   rows before this to policy cost before this date

% for each column of policy cost
offset = 1; % required as first column is commodity type
to_remove = 'RateFrom';
for i = 1+offset:length(Policy_charges_in.Properties.VariableNames)
    % split var name at 'RateFrom' and take [2]
    var_nam = Policy_charges_in.Properties.VariableNames(i);
    var_nam = erase(var_nam,to_remove);

    
    % convert column header into datetime
    Policy_cost_date = datetime(var_nam, 'InputFormat', 'dMMMMyyyy');
    % find rows from tariff_data datetime split are from before the day,
    % month and year
    date_rows = find(BSUoS_TLF_wholesale_joined{:,1}==Policy_cost_date);
    % if exists, populate rows before this date with appropriate policy cost
    if nnz(date_rows)>0
        policy_charges_data(date_rows(1)<=1:size(policy_charges_data,1),:) = Policy_charges_in{6,i}; % convert policy cost from £/kWh to p/kWh
    end
end

BSUoS_TLF_wholesale_policy_joined = addvars(BSUoS_TLF_wholesale_joined, policy_charges_data, 'NewVariableNames', 'Policy');


%% ADD IN FLAGS FOR TRIAD PERIODS

% convert each triad 'HHEnding' column into HH period number
Triad_Dates_HH = Triad_Dates;
Triad_Dates_HH{:,5} = Triad_Dates_HH{:,5}*48 - 1;
Triad_Dates_HH{:,10} = Triad_Dates_HH{:,10}*48 - 1;
Triad_Dates_HH{:,15} = Triad_Dates_HH{:,15}*48 - 1;

% - for each of the three triad period date columns
	% - find rows corresponding to date in tariff_data
    % - check HH ending period

offset = 2;
triad_flags = zeros(height(BSUoS_TLF_wholesale_policy_joined),1);
% indicate column numbers which contain dat of triad period
triad_data_date_columns = [3 8 13];

% if triad should be included
if use_triads == 1
    % for each of the htree triad date columns
    for i = triad_data_date_columns
        % find triad dates
        [triad_dates,idx_dates] = intersect(Triad_Dates_HH{:,i},BSUoS_TLF_wholesale_policy_joined{:,1},'stable');
        % for each of the historical triad dates in the assembled tariff
        % date range
        for z = 1:length(triad_dates)
            % find the HH of the triad
            triad_row = find(Triad_Dates_HH{:,i} == triad_dates(z));
            tariff_row = find(BSUoS_TLF_wholesale_policy_joined.SettlementDate == triad_dates(z) & BSUoS_TLF_wholesale_policy_joined.SettlementPeriod == Triad_Dates_HH{triad_row,i+offset});
            % set triad period indicator to 1
            triad_flags(tariff_row,1) = 1;
        end
    end
end

% add triad flags to assembled tariff
BSUoS_TLF_wholesale_policy_triad_joined = addvars(BSUoS_TLF_wholesale_policy_joined, triad_flags, 'NewVariableNames', 'Triad');


%% Add correct TNUoS charges
% join GSP zones to formatted TNUoS charges dataset
TNUoS_formatted_joined = outerjoin(TNUoS_formatted, DNO_region_labelling, 'Keys', 2, 'MergeKeys', 1);
% delete unused zones
TNUoS_formatted_joined = TNUoS_formatted_joined(~any(ismissing(TNUoS_formatted_joined),2),:);
% find rows where triad periods occured
triad_rows = find(BSUoS_TLF_wholesale_policy_triad_joined.Triad>0);
% shift all dates backwards by 180 days in new table
shifted_flags = [array2table(BSUoS_TLF_wholesale_policy_triad_joined.SettlementDate-180, 'VariableNames', {'SettlementDate'}) array2table(BSUoS_TLF_wholesale_policy_triad_joined.Triad, 'VariableNames', {'Triad'})];
% find TNUoS charges for that region
split_tmp = split(TNUoS_formatted_joined.Year, '/');
TNUoS_formatted_joined.Year = split_tmp(:,1);

% for each year, extract the TNUoS charge, and set triad period value from
% that year equal to it
unique_years = unique(year(BSUoS_TLF_wholesale_policy_triad_joined.SettlementDate));
unique_zones = unique(TNUoS_formatted_joined.GSPZone);
for iZone = 1:length(unique_zones)
    this_zone = unique_zones(iZone);
    for i = 1:length(unique_years)
        TNUoS_this_year = TNUoS_formatted_joined.HHDemandTariff___kW_(strcmp(TNUoS_formatted_joined.Year, num2str(unique_years(i))) & TNUoS_formatted_joined.GSPZone == this_zone);
        BSUoS_TLF_wholesale_policy_triad_joined.Triad(shifted_flags.Triad>0 & year(shifted_flags.SettlementDate) == unique_years(i) & BSUoS_TLF_wholesale_policy_triad_joined.GSPZone == this_zone) = TNUoS_this_year;
    end
end



%% FORMAT DUoS CHARGES
% join GSP zones to formatted DUoS charges dataset
DUoS_formatted_joined = outerjoin(DUoS_formatted, DNO_region_labelling, 'Keys', 2, 'MergeKeys', 1);
% delete any rows containing NaNs
DUoS_formatted_joined = DUoS_formatted_joined(~any(ismissing(DUoS_formatted_joined),2),:);
% remove unnecessary variables
DUoS_formatted_joined = removevars(DUoS_formatted_joined, {'Time', 'DNOID', 'GSPGroupID', 'MarketParticipantID'});
% sort assembled tariff by GSP Zone
BSUoS_TLF_wholesale_policy_triad_joined = sortrows(BSUoS_TLF_wholesale_policy_triad_joined, 'GSPZone');
% delete rows where GSP Zone is NaN
BSUoS_TLF_wholesale_policy_triad_joined(isnan(BSUoS_TLF_wholesale_policy_triad_joined.GSPZone), :) = [];
% create array to store DUoS data
DUoS_data = zeros(height(BSUoS_TLF_wholesale_policy_triad_joined),3);
DUoS_operational = cell(height(BSUoS_TLF_wholesale_policy_triad_joined),1);
% set DUoS periods and initialise charges
DUoS_data(:,1) = BSUoS_TLF_wholesale_policy_triad_joined.SettlementPeriod;
DUoS_data(:,2) = NaN;
% find the unique GSP zones and years which the DUoS data set covers
unique_zones = unique(DUoS_formatted_joined.GSPZone);
unique_years = unique(DUoS_formatted_joined.Year);
%find the day of the week of each data row
DayNum = weekday(BSUoS_TLF_wholesale_policy_triad_joined{:,1});
% find which rows are weekdays and which are weekends
weekdays = (DayNum == 2 | DayNum == 3 | DayNum == 4 | DayNum == 5 | DayNum == 6);
weekends = (DayNum == 7 | DayNum == 1);

% for each unique GSP Zone
for iZone = 1:length(unique_zones)
    % find the zone
    this_zone = unique_zones(iZone);
    % find rows corresponding to that zone
    zone_rows = BSUoS_TLF_wholesale_policy_triad_joined.GSPZone == this_zone;
    % for weekdays/weekends
    for isWeekend = 0:1
        % for each year
        for iYear = 1:length(unique_years)
            % find the tariff rows for this year 
            year_rows = year(BSUoS_TLF_wholesale_policy_triad_joined.SettlementDate) == unique_years(iYear);
            % should this go up to 50 ? <- DUoS charge data should also go
            % up to HH = 50
            for HH = 1:48
                % find the required DUoS charge
                DUoS_charge = DUoS_formatted_joined.DUoS(DUoS_formatted_joined.Year == unique_years(iYear) &...
                    DUoS_formatted_joined.GSPZone == this_zone & DUoS_formatted_joined.SettlementPeriod == HH & DUoS_formatted_joined.Weekend == isWeekend);
                % find the corresponding DUoS band
                DUoS_band = DUoS_formatted_joined.Band(DUoS_formatted_joined.Year == unique_years(iYear) &...
                    DUoS_formatted_joined.GSPZone == this_zone & DUoS_formatted_joined.SettlementPeriod == HH & DUoS_formatted_joined.Weekend == isWeekend);
                % if it's a weekday, index into the weekday rows
                if isWeekend == 0
                    DUoS_data(zone_rows & year_rows & weekdays & DUoS_data(:,1) == HH,2) = DUoS_charge;
                    DUoS_operational(zone_rows & year_rows & weekdays & DUoS_data(:,1) == HH,1) = DUoS_band;
                % else, index into the weekend rows
                else
                    DUoS_data(zone_rows & year_rows & weekends & DUoS_data(:,1) == HH,2) = DUoS_charge;
                    DUoS_operational(zone_rows & year_rows & weekends & DUoS_data(:,1) == HH,1) = DUoS_band;
                end
                % write the corresponding DNO zone
                DUoS_data(zone_rows & year_rows & weekends & DUoS_data(:,1) == HH,3) = this_zone;
            end
        end
    end
end

% append DUoS data to tariff_data_2
BSUoS_TLF_wholesale_policy_triad_DUoS_joined = addvars(BSUoS_TLF_wholesale_policy_triad_joined, DUoS_data(:,2), DUoS_operational(:,1), 'NewVariableNames',{'DUoS','DUoS_band'});

%% Add LLFs

% add GSP Zones to LLF (merging on 'Name' variable)
LLF_raw = outerjoin(LLF_raw, DNO_region_labelling);
% call function for each DNO 
BSUoS_TLF_wholesale_policy_triad_DUoS_joined = sortrows(BSUoS_TLF_wholesale_policy_triad_DUoS_joined, 'GSPZone');
unique_zones = unique(BSUoS_TLF_wholesale_policy_triad_DUoS_joined.GSPZone);
% initialise full LLF formatted array
LLF_formatted_all = [];
% for each of the unique GSP Zones
for iZone = 1:length(unique_zones)
    this_zone = unique_zones(iZone);
    % set the corresponding zone 
    if this_zone == 10
        tmp = 1;
    end
    
    % find the name of the DNO region
    DNO_region = DNO_region_labelling.Name(DNO_region_labelling.GSPZone == this_zone);

    % format the LLFs as period rows for this GSP Zone
    tariff_this_zone = BSUoS_TLF_wholesale_policy_triad_DUoS_joined(BSUoS_TLF_wholesale_policy_triad_DUoS_joined.GSPZone == this_zone, :);
    LLF_formatted = format_LLFs(LLF_raw, DNO_region{1}, tariff_this_zone, LLF_possible_start_periods);
    % append to other GSP Zones formatted LLFs
    LLF_formatted_all = [LLF_formatted_all; LLF_formatted];
end

% join LLF component to the other tariff components
BSUoS_TLF_wholesale_policy_triad_DUoS_LLF_joined = innerjoin(BSUoS_TLF_wholesale_policy_triad_DUoS_joined, LLF_formatted_all);
% sort rows based on GSPZone
BSUoS_TLF_wholesale_policy_triad_DUoS_LLF_joined = sortrows(BSUoS_TLF_wholesale_policy_triad_DUoS_LLF_joined, 'GSPZone');

%% Rearrange variables, convert units to p/kWh and add total

% apply input component ordering to tariff table
component_order = final_component_order_and_factors.Component;
BSUoS_TLF_wholesale_policy_triad_DUoS_LLF_joined = BSUoS_TLF_wholesale_policy_triad_DUoS_LLF_joined(:,component_order);
% apply unit conversion factors
% for each component
for iComponent = 1:height(final_component_order_and_factors)
    % find the corresponding factor
    factor = final_component_order_and_factors.ConversionFactor(iComponent);
    % if it's non-zero and not NaN
    if factor > 0 && ~isnan(factor)
        % find the corresponding component name
        this_component = final_component_order_and_factors.Component(iComponent);
        % apply the factor
        BSUoS_TLF_wholesale_policy_triad_DUoS_LLF_joined{:, this_component} =....
            BSUoS_TLF_wholesale_policy_triad_DUoS_LLF_joined{:, this_component}.*factor;
    end
end

% find the total, accounting for hourly wholesalve with spline
total = (BSUoS_TLF_wholesale_policy_triad_DUoS_LLF_joined.DUoS +...
    BSUoS_TLF_wholesale_policy_triad_DUoS_LLF_joined.BSUoS +...
    fillmissing(BSUoS_TLF_wholesale_policy_triad_DUoS_LLF_joined.Wholesale, 'spline')).*...
    BSUoS_TLF_wholesale_policy_triad_DUoS_LLF_joined.LLF.*...
    (1./BSUoS_TLF_wholesale_policy_triad_DUoS_LLF_joined.OffTaking_TLF);

% add total to tariff
BSUoS_TLF_wholesale_policy_triad_DUoS_LLF_total_joined = addvars(BSUoS_TLF_wholesale_policy_triad_DUoS_LLF_joined,...
    total, 'NewVariableNames', 'Total_excl_triad');
    
       
% save final output table to the output folder
writetable(BSUoS_TLF_wholesale_policy_triad_DUoS_LLF_total_joined, fullfile(user_path, 'Outputs', strcat(run_date, '.', client, '.', 'compiled_historical_tariffs', '.', run_version, '.', user_initials, '.csv')));