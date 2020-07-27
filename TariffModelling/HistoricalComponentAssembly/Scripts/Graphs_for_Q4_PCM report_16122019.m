%% Graphs for Q4 PCM report - 16/12/2019



start_date = 17530; % 01/01/2019
offset = 336+336;
end_date = start_date+offset; % 07/09/2019

eff = 1.03;

%% Tariffs 2019 -> 2030

% 1. TNUoS ??

clf
plot(cumsum(complete_data_2.triad_flags(1:17528).*complete_data_2.StoreElectricityConsumption_kW_(1:17528))/(1000*2*100))
xlabel('HH period')
ylabel('Price (£, thousand)')
title('Cumulative TNUoS charges, South Eastern region (01/01/2018 - 31/12/2018)')
xline(4382, '-.r');
xline(4382*2, '-.r');
xline(4382*3, '-.r');
legend('TNUoS', 'Start of quarter', 'Location','southoutside', 'Orientation','horizontal')

figure
plot(cumsum(future_data.triad_flags(1:17528).*future_data.StoreElectricityConsumption_kW_(1:17528))/(1000*2*100))
xlabel('HH period')
ylabel('Price (£, thousand)')
title('Cumulative TNUoS charges, South Eastern region (01/01/2030 - 31/12/2030)')
xline(4382, '-.r');
xline(4382*2, '-.r');
xline(4382*3, '-.r');
legend('TNUoS', 'Start of quarter', 'Location','southoutside', 'Orientation','horizontal')

% 2. DUoS

clf 
plot(complete_data_2.DUoS(start_date:end_date))
xlim([0 offset])
ylim([0 12])
xlabel('HH period')
ylabel('Price (p/kWh)')
title('DUoS charges, South Eastern region (01/09/2019 - 14/09/2019)')
xline(48, '-.r');
xline(48*2, '-.r');
xline(48*3, '-.r');
xline(48*4, '-.r');
xline(48*5, '-.r');
xline(48*6, '-.r');
xline(48*7, '-.r');
xline(48*8, '-.r');
xline(48*9, '-.r');
xline(48*10, '-.r');
xline(48*11, '-.r');
xline(48*12, '-.r');
xline(48*13, '-.r');
legend('DUoS', 'Start of day', 'Location','southoutside', 'Orientation','horizontal')

figure
plot(future_data.DUoS(start_date:end_date))
xlim([0 offset])
ylim([0 12])
xlabel('HH period')
ylabel('Price (p/kWh)')
title('DUoS charges, South Eastern region (01/09/2030 - 14/09/2030)')
xline(48, '-.r');
xline(48*2, '-.r');
xline(48*3, '-.r');
xline(48*4, '-.r');
xline(48*5, '-.r');
xline(48*6, '-.r');
xline(48*7, '-.r');
xline(48*8, '-.r');
xline(48*9, '-.r');
xline(48*10, '-.r');
xline(48*11, '-.r');
xline(48*12, '-.r');
xline(48*13, '-.r');
legend('DUoS', 'Start of day', 'Location','southoutside', 'Orientation','horizontal')

% 3. Wholesale

clf 
plot(fillmissing(complete_data_2.n2ex(start_date:end_date), 'spline'))
xlim([0 offset])
ylim([-1 15])
xlabel('HH period')
ylabel('Price (p/kWh)')
title('Wholesale prices (01/09/2019 - 14/09/2019)')
xline(48, '-.r');
xline(48*2, '-.r');
xline(48*3, '-.r');
xline(48*4, '-.r');
xline(48*5, '-.r');
xline(48*6, '-.r');
xline(48*7, '-.r');
xline(48*8, '-.r');
xline(48*9, '-.r');
xline(48*10, '-.r');
xline(48*11, '-.r');
xline(48*12, '-.r');
xline(48*13, '-.r');
legend('Wholesale', 'Start of day', 'Location','southoutside', 'Orientation','horizontal')

figure
plot(future_data.n2ex(start_date:end_date))
xlim([0 offset])
ylim([-1 15])
xlabel('HH period')
ylabel('Price (p/kWh)')
title('Wholesale prices (01/09/2030 - 14/09/2030)')
xline(48, '-.r');
xline(48*2, '-.r');
xline(48*3, '-.r');
xline(48*4, '-.r');
xline(48*5, '-.r');
xline(48*6, '-.r');
xline(48*7, '-.r');
xline(48*8, '-.r');
xline(48*9, '-.r');
xline(48*10, '-.r');
xline(48*11, '-.r');
xline(48*12, '-.r');
xline(48*13, '-.r');
legend('Wholesale', 'Start of day', 'Location','southoutside', 'Orientation','horizontal')

% 4. Combined

% high renewable NOT USED IN REPORT, TOO MANY NEGATIVES

start_date = 29189; % 01/09/2019
offset = 336+336;


figure
area(1:offset+1,[complete_data_2{start_date:start_date+offset,3} fillmissing(complete_data_2{start_date:start_date+offset,4}, 'spline') complete_data_2{start_date:start_date+offset,5} complete_data_2{start_date:start_date+offset,6} complete_data_2{start_date:start_date+offset,7}])
hold on
xlim([0 offset+1])
ylim([0 25])
xlabel('HH period')
ylabel('Tariff (p/kWh)')
title('Tariff Components (South East region, 01/09/2019 - 07/09/2019)')
xline(48, '-.r');
xline(48*2, '-.r');
xline(48*3, '-.r');
xline(48*4, '-.r');
xline(48*5, '-.r');
xline(48*6, '-.r');
legend('BSUoS', 'Wholesale', 'Policy charge', 'TNUoS', 'DUoS', 'Location','southoutside', 'Orientation','horizontal')

figure
area(1:offset+1,[future_data{start_date:start_date+offset,3} fillmissing(future_data{start_date:start_date+offset,4}, 'spline') future_data{start_date:start_date+offset,5} future_data{start_date:start_date+offset,6} future_data{start_date:start_date+offset,7}], basevalue)
hold on
xlim([0 offset+1])
ylim([0 25])
xlabel('HH period')
ylabel('Tariff (p/kWh)')
title('Future Components (South East region, 01/09/2030 - 07/09/2030)')
xline(48, '-.r');
xline(48*2, '-.r');
xline(48*3, '-.r');
xline(48*4, '-.r');
xline(48*5, '-.r');
xline(48*6, '-.r');
legend('BSUoS', 'Wholesale', 'Policy charge', 'TNUoS', 'DUoS', 'Location','southoutside', 'Orientation','horizontal')


% low renewable USED IN REPORT

start_date = 17530; % 01/01/2019
offset = 336+336;

figure
area(1:offset+1,[complete_data_2{start_date:start_date+offset,3} fillmissing(complete_data_2{start_date:start_date+offset,4}, 'spline') complete_data_2{start_date:start_date+offset,5} complete_data_2{start_date:start_date+offset,6} complete_data_2{start_date:start_date+offset,7}])
hold on
xlim([0 offset+1])
ylim([0 35])
xlabel('HH period')
ylabel('Tariff (p/kWh)')
title('Tariff Components (South East region, 01/01/2019 - 14/01/2019)')
xline(48, '-.r');
xline(48*2, '-.r');
xline(48*3, '-.r');
xline(48*4, '-.r');
xline(48*5, '-.r');
xline(48*6, '-.r');
xline(48*7, '-.r');
xline(48*8, '-.r');
xline(48*9, '-.r');
xline(48*10, '-.r');
xline(48*11, '-.r');
xline(48*12, '-.r');
xline(48*13, '-.r');
legend('BSUoS', 'Wholesale', 'Policy charge', 'TNUoS', 'DUoS', 'Location','southoutside', 'Orientation','horizontal')

figure
area(1:offset+1,[future_data{start_date:start_date+offset,3} fillmissing(future_data{start_date:start_date+offset,4}, 'spline') future_data{start_date:start_date+offset,5} future_data{start_date:start_date+offset,6} future_data{start_date:start_date+offset,7}], basevalue)
hold on
xlim([0 offset+1])
ylim([0 35])
xlabel('HH period')
ylabel('Tariff (p/kWh)')
title('Future Components (South East region, 01/01/2030 - 14/01/2030)')
xline(48, '-.r');
xline(48*2, '-.r');
xline(48*3, '-.r');
xline(48*4, '-.r');
xline(48*5, '-.r');
xline(48*6, '-.r');
xline(48*7, '-.r');
xline(48*8, '-.r');
xline(48*9, '-.r');
xline(48*10, '-.r');
xline(48*11, '-.r');
xline(48*12, '-.r');
xline(48*13, '-.r');
legend('BSUoS', 'Wholesale', 'Policy charge', 'TNUoS', 'DUoS', 'Location','southoutside', 'Orientation','horizontal')


%% Load Management

% 1. Change in Refrigerator load
ref_start = 22946;
raw_ref_load = branch_input{ref_start:ref_start+offset,27};
raw_ref_periods = branch_input_2{ref_start:ref_start+offset,2};
mod_ref_load = raw_ref_load;
mod_ref_load((raw_ref_periods>=start_green_band & raw_ref_periods<=end_green_band)) = mod_ref_load((raw_ref_periods>=start_green_band & raw_ref_periods<=end_green_band))*eff + max_charge_rate;
mod_ref_load((raw_ref_periods>=start_red_band & raw_ref_periods<=end_red_band)) = mod_ref_load((raw_ref_periods>=start_red_band & raw_ref_periods<=end_red_band))*eff - max_discharge_rate;
mod_ref_load(mod_ref_load<0) = 0;

plot(branch_input{ref_start:ref_start+offset,27})
xlabel('HH period')
ylabel('Electrical load (kW)')
title('Refrigeration Electricity consumption without PCM (South East region, Lewes Rd store, 01/01/2019 - 14/01/2019)')
ylim([0 200])
xlim([0 offset+1])
xline(48, '-.r');
xline(48*2, '-.r');
xline(48*3, '-.r');
xline(48*4, '-.r');
xline(48*5, '-.r');
xline(48*6, '-.r');
xline(48*7, '-.r');
xline(48*8, '-.r');
xline(48*9, '-.r');
xline(48*10, '-.r');
xline(48*11, '-.r');
xline(48*12, '-.r');
xline(48*13, '-.r');
legend('Electrical load', 'Start of day', 'Location','southoutside', 'Orientation','horizontal')

figure
plot(mod_ref_load)
xlabel('HH period')
ylabel('Electrical load (kW)')
title('Refrigeration Electricity consumption with PCM (South East region, Lewes Rd store, 01/01/2019 - 14/01/2019)')
ylim([0 200])
xlim([0 offset+1])
xline(48, '-.r');
xline(48*2, '-.r');
xline(48*3, '-.r');
xline(48*4, '-.r');
xline(48*5, '-.r');
xline(48*6, '-.r');
xline(48*7, '-.r');
xline(48*8, '-.r');
xline(48*9, '-.r');
xline(48*10, '-.r');
xline(48*11, '-.r');
xline(48*12, '-.r');
xline(48*13, '-.r');
legend('Electricity cost', 'Start of day', 'Location','southoutside', 'Orientation','horizontal')


% 2. Change in Refrigerator costs


plot(branch_input{ref_start:ref_start+offset,27}.*complete_data_2{ref_start+3:ref_start+offset+3,12}/(100*2))
xlabel('HH period')
ylabel('Electricity half-hourly cost (£)')
title('Refrigeration Electricity cost without PCM (South East region, Lewes Rd store, 01/01/2019 - 14/01/2019)')
ylim([0 15])
xlim([0 offset+1])
xline(48, '-.r');
xline(48*2, '-.r');
xline(48*3, '-.r');
xline(48*4, '-.r');
xline(48*5, '-.r');
xline(48*6, '-.r');
xline(48*7, '-.r');
xline(48*8, '-.r');
xline(48*9, '-.r');
xline(48*10, '-.r');
xline(48*11, '-.r');
xline(48*12, '-.r');
xline(48*13, '-.r');
legend('Electrical load', 'Start of day', 'Location','southoutside', 'Orientation','horizontal')

figure
plot(mod_ref_load.*complete_data_2{ref_start+3:ref_start+offset+3,12}/(100*2))
xlabel('HH period')
ylabel('Electricity half-hourly cost (£)')
title('Refrigeration Electricity cost with PCM (South East region, Lewes Rd store, 01/01/2019 - 14/01/2019)')
ylim([0 15])
xlim([0 offset+1])
xline(48, '-.r');
xline(48*2, '-.r');
xline(48*3, '-.r');
xline(48*4, '-.r');
xline(48*5, '-.r');
xline(48*6, '-.r');
xline(48*7, '-.r');
xline(48*8, '-.r');
xline(48*9, '-.r');
xline(48*10, '-.r');
xline(48*11, '-.r');
xline(48*12, '-.r');
xline(48*13, '-.r');
legend('Electricity cost', 'Start of day', 'Location','southoutside', 'Orientation','horizontal')

% 3. Change in Refrigerator carbon emissions



plot(branch_input{ref_start:ref_start+offset,27}.*complete_data_2{ref_start+3:ref_start+offset+3,14}/(1000*2))
xlabel('HH period')
ylabel('Carbon half-hourly emissions (kg)')
title('Refrigeration Carbon emissions without PCM (South East region, Lewes Rd store, 01/01/2019 - 14/01/2019)')
ylim([0 25])
xlim([0 offset+1])
xline(48, '-.r');
xline(48*2, '-.r');
xline(48*3, '-.r');
xline(48*4, '-.r');
xline(48*5, '-.r');
xline(48*6, '-.r');
xline(48*7, '-.r');
xline(48*8, '-.r');
xline(48*9, '-.r');
xline(48*10, '-.r');
xline(48*11, '-.r');
xline(48*12, '-.r');
xline(48*13, '-.r');
legend('Carbon emissions', 'Start of day', 'Location','southoutside', 'Orientation','horizontal')

figure
plot(mod_ref_load.*complete_data_2{ref_start+3:ref_start+offset+3,14}/(1000*2))
xlabel('HH period')
ylabel('Carbon half-hourly emissions (kg)')
title('Refrigeration Carbon emissions with PCM (South East region, Lewes Rd store, 01/01/2019 - 14/01/2019)')
ylim([0 25])
xlim([0 offset+1])
xline(48, '-.r');
xline(48*2, '-.r');
xline(48*3, '-.r');
xline(48*4, '-.r');
xline(48*5, '-.r');
xline(48*6, '-.r');
xline(48*7, '-.r');
xline(48*8, '-.r');
xline(48*9, '-.r');
xline(48*10, '-.r');
xline(48*11, '-.r');
xline(48*12, '-.r');
xline(48*13, '-.r');
legend('Carbon emissions', 'Start of day', 'Location','southoutside', 'Orientation','horizontal')
