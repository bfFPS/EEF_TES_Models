%% SCRIPT TO REFORMAT AN INPUT OF LLFs FOR EACH REGION IN A USABLE TIMESERIES FORMAT FOR OTHER TARIFFS - BF, 28112019

function LLF_formatted = format_LLFs(LLF_raw, region_input, tariff_data_union_2, LLF_possible_start_periods)


% path = 'C:\Users\benfl\OneDrive - Flexible Power Systems Ltd\Documents\PCM\Tariff Modelling\Input_Data\';
% LLF_raw_file = 'LLF_input.xlsx';
% % 
% LLF_raw = readtable(strcat(path, LLF_raw_file));
% region_input = 'South Western';

% remove any NaT values
missing_dates_inexing = ismissing(LLF_raw.StartDate) | ismissing(LLF_raw.EndDate);
LLF_raw = LLF_raw(~missing_dates_inexing,:);

% find the unique day types as specified in the LLF data 
unique_daytypes_LLF = unique(LLF_raw.DayType); % day types as formatted in the raw LLF datafile
LLF_formatted = tariff_data_union_2(:,1:2); % store for LLF data as formatted below
% region | date | period | factor
Name = cell(height(tariff_data_union_2),1);
Name(:,1) = {region_input};
LLF = zeros(height(tariff_data_union_2),1);
LLF(:,:) = 1; % necessary to catch some instances where date range in LLF_in isn't continous
LLF_formatted = addvars(LLF_formatted,Name,'Before',1);
LLF_formatted = addvars(LLF_formatted,LLF,'After',3);
col_start_period = 5; % column in LLF raw data where first start period is located
offset_start_period = 2; %the offset between each column containing a start period
LLF_rows_region = strcmp(LLF_raw{:,1}, region_input) == 1; % raw LLF rows where region matched input region
LLF_formatted_region = strcmp(LLF_formatted{:,1}, region_input) == 1; % formatted LLF rows where region matched input region
LLF_region = LLF_raw(LLF_rows_region,:);


% for each of the day types in the raw LLF data
for iDay = 1:length(unique_daytypes_LLF) 
    % indexing of raw LLF rows where where the day matched the day type
    LLF_rows_region_day = strcmp(LLF_raw.DayType(LLF_rows_region), unique_daytypes_LLF{iDay}) == 1; 
    
    % extract raw LLF data where where the day matched the day type
    LLF_data_region_day = LLF_region(LLF_rows_region_day,:); % raw LLF data where where the day matched the day type
    row_nums = find(LLF_rows_region_day == 1); % raw LLF row numbers where region matched day types
    if strcmp(unique_daytypes_LLF{iDay}, 'NWD')
        LLF_formatted_region_day = LLF_formatted_region & isweekend(LLF_formatted.SettlementDate); % formatted LLF rows where region matched day types
    elseif strcmp(unique_daytypes_LLF{iDay}, 'WD')
        LLF_formatted_region_day = LLF_formatted_region & ~isweekend(LLF_formatted.SettlementDate); % formatted LLF rows where region matched day types
    end
    for iRow = 1:length(row_nums) % for all of the raw LLF rows for the current selection
        start_date = LLF_data_region_day{iRow,2};
        end_date = LLF_data_region_day{iRow,3};
        start_periods = zeros(2,1); % store for the start periods, pre-sized as minimum number possible
        LLFs = zeros(4,1); % store for the LLF values, pre-sized as minimum number possible
        for iCount = 1:LLF_possible_start_periods % count for the number of possible start periods in raw LLF data
%         for iCount = 1:5
            start_period = LLF_data_region_day(iRow,col_start_period+(iCount-1)*offset_start_period); % extract the start period
            if ~isnan(start_period{:,:}) % if its not null
                start_periods(iCount) = start_period{:,:}; % store the start period
                LLFs(iCount,1) = LLF_data_region_day{iRow,col_start_period+1+(iCount-1)*offset_start_period}; % store the LLF vaue
            end
        end
        start_periods(length(start_periods)+1) = 49; % append a final start period to act as final end period
        for iPeriod = 1:length(start_periods)-1 % for all the raw LLF start periods
            start_period = start_periods(iPeriod); % extract the start time
            end_period = start_periods(iPeriod+1) - 1; % extract the end time
            LLF_formatted_region_day_period = LLF_formatted_region_day &...
                LLF_formatted.SettlementPeriod >= start_period & LLF_formatted.SettlementPeriod <= end_period &...
                LLF_formatted.SettlementDate >= start_date & LLF_formatted.SettlementDate <= end_date; % periods of formatted LLF between start and end periods
%             LLF_formatted_region_day_period = LLF_formatted{LLF_formatted_region_day,3} >= start_period &...
%                 LLF_formatted{LLF_formatted_region_day,3} <= end_period; % periods of formatted LLF between start and end periods
            LLF_formatted{LLF_formatted_region_day_period, 4} = LLFs(iPeriod,1); % set values of LLF formatted 
        end
    end
end

end

%% some pseudo code

% loop through each day type
% 	create 0/1 index of where raw input matched daytype
% 	extract raw data rows where raw where input matched daytype
% 	extract the row numbers where raw where input matched daytype
% 	create 0/1 index of where formatted LLFs rows matched daytype
% 	loop through number of rows where raw input matched daytype
% 		loop through 4 times
% 			find the start period of the LLF period
% 			if start period isn't NaN
% 				save the start period
% 				store the LLF value

% plot(LLF_formatted{:,4})

            
            