%% SCRIPT TO REFORMAT AN INPUT OF LLFs FOR EACH REGION IN A USABLE TIMESERIES FORMAT FOR OTHER TARIFFS - BF, 28112019

function LLF_formatted = format_LLFs(LLF_raw, region_input)


% path = 'C:\Users\benfl\OneDrive - Flexible Power Systems Ltd\Documents\PCM\Tariff Modelling\Input_Data\';
% LLF_raw_file = 'LLF_input.xlsx';
% 
% LLF_raw = readtable(strcat(path, LLF_raw_file));
% region_input = 'South East';

day_types_LLF = {'WD', 'NWD'}; % day types as formatted in the raw LLF datafile
LLF_formatted = tariff_data_union_2(:,1:2); % store for LLF data as formatted below
% region | date | period | factor
region = cell(height(tariff_data_union_2),1);
region(:,1) = {region_input};
LLF_init = zeros(height(tariff_data_union_2),1);
LLF_formatted = addvars(LLF_formatted,region,'Before',1);
LLF_formatted = addvars(LLF_formatted,LLF_init,'After',3);
col_start_period = 5; % column in LLF raw data where first start period is located
offset_start_period = 2; %the offset between each column containing a start period
LLF_rows_region = strcmp(LLF_raw{:,1}, region_input) == 1; % raw LLF rows where region matched input region
LLF_formatted_region = strcmp(LLF_formatted{:,1}, region_input) == 1; % formatted LLF rows where region matched input region


for iday = 1:length(day_types_LLF) % for each of the day types in the raw LLF data
    LLF_rows_region_day = strcmp(LLF_raw{LLF_rows_region,4}, day_types_LLF{iday}) == 1; % raw LLF rows where where the day matched the day type
    LLF_data_region_day = LLF_raw(LLF_rows_region_day,:); % raw LLF data where where the day matched the day type
    row_nums = find(LLF_rows_region_day == 1); % raw LLF row numbers where region matched day types
    LLF_formatted_region_day = LLF_formatted_region & isweekend(LLF_formatted{:,2})==iday-1; % formatted LLF rows where region matched day types
    for irow = 1:length(row_nums) % for all of the raw LLF rows for the current selection
        start_date = LLF_data_region_day{irow,2};
        end_date = LLF_data_region_day{irow,3};
        start_periods = zeros(2,1); % store for the start periods, pre-sized as minimum number possible
        LLFs = zeros(4,1); % store for the LLF values, pre-sized as minimum number possible
        for cnt = 1:4 % count for the number of possible start periods in raw LLF data
            start_period = LLF_data_region_day(irow,col_start_period+(cnt-1)*offset_start_period); % extract the start period
            if ~isnan(start_period{:,:}) % if its not null
                start_periods(cnt) = start_period{:,:}; % store the start period
                LLFs(cnt,1) = LLF_data_region_day{irow,col_start_period+1+(cnt-1)*offset_start_period}; % store the LLF vaue
            end
        end
        start_periods(length(start_periods)+1) = 49; % append a final start period to act as final end period
        for iperiod = 1:length(start_periods)-1 % for all the raw LLF start periods
            start_period = start_periods(iperiod); % extract the start time
            end_period = start_periods(iperiod+1) - 1; % extract the end time
            LLF_formatted_region_day_period = LLF_formatted_region_day &...
                LLF_formatted{:,3} >= start_period & LLF_formatted{:,3} <= end_period &...
                LLF_formatted{:,2} >= start_date & LLF_formatted{:,2} <= end_date; % periods of formatted LLF between start and end periods
%             LLF_formatted_region_day_period = LLF_formatted{LLF_formatted_region_day,3} >= start_period &...
%                 LLF_formatted{LLF_formatted_region_day,3} <= end_period; % periods of formatted LLF between start and end periods
            LLF_formatted{LLF_formatted_region_day_period, 4} = LLFs(iperiod,1); % set values of LLF formatted 
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

            
            