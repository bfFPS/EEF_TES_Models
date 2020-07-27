%% FUNCTION TO EXTRACT AND FORMAT TLMs FOR APPROPRIATE DNO REGION - BF, 29/11/2019

% 1. Split TLMs into two tables: TAB1 = isnan(raw.Zone) and TAB2 = ~isnan(raw.Zone)

% 2. Map user DNO_input (string, e.g. 'South East') to corresponding
% numerical region indicator

% 3. Extract rows from TAB2 which match that indicator

% region_input = 'South Eastern';

% TLM_raw = readtable('C:\Users\benfl\OneDrive - Flexible Power Systems Ltd\Documents\PCM\Tariff Modelling\Input_Data\TLM_in.csv');

function TLM_formatted = format_TLMs(TLM_raw, region_input)



TLM_single = TLM_raw(isnan(TLM_raw{:,4}),:);

TLM_region = TLM_raw(~isnan(TLM_raw{:,4}),:);




% regions = {{'Eastern', 1}, {'East Midlands', 2}, {'London', 3}, {'Merseyside and North Wales', 4}, {'West Midlands', 5}, {'Northern', 6},{'North Western', 7},...
%     {'Southern', 8}, {'South Eastern', 9}, {'South Wales', 10}, {'South Western', 11}, {'Yorkshire', 12}, {'South of Scotland', 13}, {'North of Scotland', 14}};

regions = {[{'Eastern'},{'East Midlands'},{'London'},{'Merseyside and North Wales'},{'West Midlands'},{'Northern'},{'North West'},...
    {'Southern'},{'South Eastern'},{'South Wales'},{'South Western'},{'Yorkshire'},{'South of Scotland'},{'North of Scotland'}],...
    [{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11},{12},{13},{14}]};

reg_row = find(strcmp(regions{1}(:),region_input));

region_num = regions{2}{reg_row};

TLM_req_region = TLM_region(TLM_region{:,4}==region_num,:);

TLM_formatted = [TLM_single ; TLM_req_region];

end