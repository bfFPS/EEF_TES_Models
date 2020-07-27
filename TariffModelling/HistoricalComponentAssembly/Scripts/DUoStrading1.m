%% Script for only charging/discharging at DUoS green/red bands - BF, 03/12/19

use_triads = 0;

storage_rating = 464;
hours_charge = 6;
max_charge_rate = storage_rating/hours_charge;
hours_discharge = 4;
max_discharge_rate = storage_rating/hours_discharge;
eff = 0.95;
HH_charge = hours_charge*2;
HH_discharge = hours_discharge*2;


% 1. Initialise/load bands HH periods

start_red_band = 33;
end_red_band = 38;

start_green_band = 1;
end_green_band = 12;

% 2. Find if less/more periods required to charge/discharge to fully use system,
% and if so which (assumes 1 charge per day)

cnt = 1;
while end_red_band - start_red_band + 1 > HH_discharge
    if cnt == 1
        start_red_band = start_red_band + 1;
    elseif cnt == -1
        end_red_band = end_red_band - 1;
    end
    cnt = cnt*-1;
end

cnt = 1;
while end_red_band - start_red_band + 1 < HH_discharge
    if cnt == 1
        start_red_band = start_red_band - 1;
    elseif cnt == -1
        end_red_band = end_red_band + 1;
    end
    cnt = cnt*-1;
end

cnt = 1;
while end_green_band - start_green_band + 1 > HH_charge
	end_green_band = end_green_band - 1;
end


while end_green_band - start_green_band + 1 < HH_charge
    end_green_band = end_green_band + 1;
end

% 3. Calculate cost if only charge at charge periods

electricity_pricing = complete_data_2;

if use_triads == 0
    electricity_pricing{:,11} = electricity_pricing{:,11} - electricity_pricing{:,6}.*electricity_pricing{:,9}.*electricity_pricing{:,10};
end

electricity_pricing = electricity_pricing{48+1:17568,[2 11]};

% electricity_pricing(1:47,:) = [];
% electricity_pricing(size(electricity_pricing,1)-41:size(electricity_pricing,1),:) = [];

day_savings_band = zeros(length(electricity_pricing)/48,1);
day_costs_band = zeros(length(electricity_pricing)/48,1);
daily_min_price_band = zeros(length(electricity_pricing)/48,1);
daily_max_price_band = zeros(length(electricity_pricing)/48,1);
  
clearvars daily_prices costs savings
for i = 1:(length(electricity_pricing)/48)-1
    daily_prices_band = electricity_pricing(1+((i-1)*48):(i)*48, :);
    

%     sorted_pricing(1+((i-1)*48):(i)*48)=sort(electricity_pricing(1+((i-1)*48):(i)*48), 2);
    daily_min_price_band(i) = min(daily_prices_band(:,2));
    daily_max_price_band(i) = max(daily_prices_band(:,2));
    
    rows_charge_band = find(daily_prices_band(:,1)>=start_green_band & daily_prices_band(:,1)<=end_green_band);
    rows_discharge_band = find(daily_prices_band(:,1)>=start_red_band & daily_prices_band(:,1)<=end_red_band);
    
%     costs(1+((i-1)*HH_charge):(i)*HH_charge) = max_charge_rate * daily_prices(rows_charge,2);
    
%     savings(1+((i-1)*HH_discharge):(i)*HH_discharge) = eff * max_discharge_rate * daily_prices(rows_discharge,2);
    
%     day_savings(i) = sum(savings(1+((i-1)*hours_discharge):(i)*hours_discharge));
%     day_costs(i) = sum(costs(1+((i-1)*hours_charge):(i)*hours_charge));

    day_costs_band(i) = sum(max_charge_rate/2 * daily_prices_band(rows_charge_band,2));
    day_savings_band(i) = sum(eff * max_discharge_rate/2 * daily_prices_band(rows_discharge_band,2));
end


tot_saving_band = sum(day_savings_band);
tot_cost_band = sum(day_costs_band);
net_saving_system_band = (tot_saving_band - tot_cost_band)/100

prctile(complete_data_2{:,11}, 32) % green band is 8/24 hours

prctile(complete_data_2{:,11}, 76) % red band is 3/24

daily_net_band = (day_savings_band-day_costs_band)/100;

clf
plot(daily_net_band)
hold on
% xlim(1:364)
xline(113, '-.r');
% ylim([0 6000])
xlim([1 364])
title('Daily savings of Medium PCM System in South Eastern region - 11/10/2017-10/10/2018')
xlabel('Day')
ylabel('Daily net savings (£/day)')
legend('Daily savings', 'End of calendar year')
hold off

clf
plot(cumsum(daily_net_band))
hold on
% ylim([0 70])
xline(113, '-.r');
xlim([0 364])
title('Cumulative savings of Medium PCM System in South Eastern region - 11/10/2017-10/10/2018')
xlabel('Day')
ylabel('Cumulative net savings (£, thousand)')
legend('Daily savings', 'End of calendar year', 'location', 'northwest')
hold off

clf
plot(cumsum(day_savings_band))
hold on
plot(cumsum(day_costs_band))
legend('Daily savings', 'Day costs', 'location', 'northwest')

%% Using perfect foresight stratergy

to_sort_pricing = complete_data_2;

if use_triads == 0
    to_sort_pricing{:,11} = to_sort_pricing{:,11} - to_sort_pricing{:,6}.*to_sort_pricing{:,9}.*to_sort_pricing{:,10};
end

to_sort_pricing = to_sort_pricing{48+1:17568,11};

day_savings_pf = zeros(length(to_sort_pricing)/48,1);
day_costs_pf = zeros(length(to_sort_pricing)/48,1);
daily_min_price_pf = zeros(length(to_sort_pricing)/48,1);
daily_max_price_pf = zeros(length(to_sort_pricing)/48,1);
  
clearvars sorted_pricing costs savings
for i = 1:(length(to_sort_pricing)/48)-1
    sorted_pricing(1+((i-1)*48):(i)*48)=sort(to_sort_pricing(1+((i-1)*48):(i)*48));
    daily_min_price_pf(i) = min(sorted_pricing(1+((i-1)*48):(i)*48));
    daily_max_price_pf(i) = max(sorted_pricing(1+((i-1)*48):(i)*48));
    
    costs_pf(1+((i-1)*HH_charge):(i)*HH_charge) = max_charge_rate/2 * sorted_pricing(1+((i-1)*48):HH_charge+((i-1)*48));
    
    savings_pf(1+((i-1)*HH_discharge):(i)*HH_discharge) = eff * max_discharge_rate/2 * sorted_pricing((48-HH_discharge)+1+((i-1)*48):i*48);
    day_savings_pf(i) = sum(savings_pf(1+((i-1)*HH_discharge):(i)*HH_discharge));
    day_costs_pf(i) = sum(costs_pf(1+((i-1)*HH_charge):(i)*HH_charge));
end

tot_cost_pf = sum(costs_pf);
tot_saving_pf = sum(savings_pf);
net_saving_system_pf = (tot_saving_pf - tot_cost_pf)/100

prctile(complete_data_2{:,11}, 32) % green band is 8/24 hours

prctile(complete_data_2{:,11}, 76) % red band is 3/24

daily_net_pf = (day_savings_pf-day_costs_pf)/100;


clf
plot(cumsum(daily_net_band/1000))
hold on
plot(cumsum(daily_net_pf/1000))
legend('DUoS band stratergy', 'Perfect foresight stratergy', 'location', 'northwest')
title('Cumlative sum from trading stratergy')
xlabel('Day')
ylabel('Cumulative net savings (£, thousand)')


