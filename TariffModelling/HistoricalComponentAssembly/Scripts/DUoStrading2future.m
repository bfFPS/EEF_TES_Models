%% Script for only charging/discharging at DUoS green/red bands - BF, 03/12/19

use_triads = 0;

use_smoothing = 0;
min_perc = 2;
max_perc = 98;

% storage_rating = 464;
% hours_charge = 6;
% max_charge_rate = storage_rating/hours_charge;
% hours_discharge = 4;
% max_discharge_rate = storage_rating/hours_discharge;
% eff = 0.95;

% storage_rating = 348;
% max_charge_rate = 42.5;
% hours_charge = storage_rating/max_charge_rate;
% max_discharge_rate = 116;
% hours_discharge = storage_rating/max_discharge_rate;
% eff = 0.95;

storage_rating = 180;
max_charge_rate = 42.5;
hours_charge = storage_rating/max_charge_rate;
max_discharge_rate = 60;
hours_discharge = storage_rating/max_discharge_rate;
eff = 0.95;

HH_charge = hours_charge*2;
HH_discharge = hours_discharge*2;

HH_charge = round(HH_charge);
HH_discharge = round(HH_discharge);

max_charge_rate = storage_rating/(HH_charge/2);
max_discharge_rate = storage_rating/(HH_discharge/2);


% 1. Initialise/load bands HH periods

start_red_band = 33;
end_red_band = 38;
dur_red_band = end_red_band - start_red_band;

start_green_band = 1;
end_green_band = 12;
dur_green_band = end_green_band - start_green_band;

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

% while end_red_band - start_red_band + 1 > dur_red_band 
%     if cnt == 1
%         start_red_band = start_red_band + 1;
%     elseif cnt == -1
%         end_red_band = end_red_band - 1;
%     end
%     cnt = cnt*-1;
% end

cnt = 1;
while end_red_band - start_red_band + 1 < HH_discharge
    if cnt == 1
        start_red_band = start_red_band - 1;
    elseif cnt == -1
        end_red_band = end_red_band + 1;
    end
    cnt = cnt*-1;
end


while end_green_band - start_green_band + 1 > HH_charge
	end_green_band = end_green_band - 1;
end


while end_green_band - start_green_band + 1 < HH_charge
    end_green_band = end_green_band + 1;
end

% 3. Calculate cost if only charge at charge periods

electricity_pricing = complete_data_2;
% electricity_pricing = future_data;

if use_triads == 0
    electricity_pricing{:,12} = electricity_pricing{:,12} - electricity_pricing{:,6}.*electricity_pricing{:,10}.*electricity_pricing{:,11};
end

if use_smoothing == 1
    upper_perc = prctile(electricity_pricing{:,12},max_perc);
    lower_perc = prctile(electricity_pricing{:,12},min_perc);
    electricity_pricing{electricity_pricing{:,12}>upper_perc,12} = upper_perc; 
    electricity_pricing{electricity_pricing{:,12}<lower_perc,12} = lower_perc;
end

electricity_pricing = electricity_pricing{48+1:17568,[2 12 14]};
% electricity_pricing(1:size(electricity_pricing,1)-3,2:3) = electricity_pricing(3+1:size(electricity_pricing,1),2:3);

smoothed_pricing_2 = electricity_pricing;

% electricity_pricing(1:47,:) = [];
% electricity_pricing(size(electricity_pricing,1)-41:size(electricity_pricing,1),:) = [];

day_savings_band = zeros(length(electricity_pricing)/48,1);
day_costs_band = zeros(length(electricity_pricing)/48,1);
daily_min_price_band = zeros(length(electricity_pricing)/48,1);
daily_max_price_band = zeros(length(electricity_pricing)/48,1);

day_carbon_used_band = zeros(length(electricity_pricing)/48,1);
day_carbon_avoided_band = zeros(length(electricity_pricing)/48,1);
  
clearvars daily_prices costs savings
for i = 1:(length(electricity_pricing)/48)-1
    daily_prices_band = electricity_pricing(1+((i-1)*48):(i)*48, :);
    

%     sorted_pricing(1+((i-1)*48):(i)*48)=sort(electricity_pricing(1+((i-1)*48):(i)*48), 2);
    daily_min_price_band(i) = min(daily_prices_band(:,2));
    daily_max_price_band(i) = max(daily_prices_band(:,2));
    
    rows_charge_band = find(daily_prices_band(:,1)>=start_green_band & daily_prices_band(:,1)<=end_green_band);
    rows_discharge_band = find(daily_prices_band(:,1)>=start_red_band & daily_prices_band(:,1)<=end_red_band);
    
%     costs_band(1+((i-1)*HH_charge):(i)*HH_charge) = max_charge_rate * daily_prices_band(rows_charge_band,2);
%     
%     costs_band(1+((i-1)*HH_charge):(i)*HH_charge) = sort(costs_band(1+((i-1)*HH_charge):(i)*HH_charge), 'ascend');
%     
%     savings_band(1+((i-1)*HH_discharge):(i)*HH_discharge) = eff * max_discharge_rate * daily_prices_band(rows_discharge_band,2);
%     savings_band(1+((i-1)*HH_discharge):(i)*HH_discharge) = sort(savings_band(1+((i-1)*HH_discharge):(i)*HH_discharge), 'descend');
    
%     day_savings(i) = sum(savings(1+((i-1)*hours_discharge):(i)*hours_discharge));
%     day_costs(i) = sum(costs(1+((i-1)*hours_charge):(i)*hours_charge));

    day_costs_band(i) = sum(max_charge_rate/2 * daily_prices_band(rows_charge_band,2));
    day_carbon_used_band(i) = sum(max_charge_rate/2 * daily_prices_band(rows_charge_band,3));
    day_savings_band(i) = sum(eff * max_discharge_rate/2 * daily_prices_band(rows_discharge_band,2));
    day_carbon_avoided_band(i) = sum(eff * max_discharge_rate/2 * daily_prices_band(rows_discharge_band,3));
end


tot_saving_band = sum(day_savings_band);
tot_cost_band = sum(day_costs_band);
% net_saving_system_band = (tot_saving_band - tot_cost_band)/100

prctile(complete_data_2{:,11}, 32) % green band is 8/24 hours

prctile(complete_data_2{:,11}, 76) % red band is 3/24

daily_net_band = (day_savings_band-day_costs_band)/100;

net_saving_system_band = sum(daily_net_band)

net_carbon_system_band = (sum(day_carbon_avoided_band) - sum(day_carbon_used_band))/1000

% clf
% plot(daily_net_band)
% hold on
% % xlim(1:364)
% xline(113, '-.r');
% % ylim([0 6000])
% xlim([1 364])
% title('Daily savings of Medium PCM System in South Eastern region - 11/10/2017-10/10/2018')
% xlabel('Day')
% ylabel('Daily net savings (£/day)')
% legend('Daily savings', 'End of calendar year')
% hold off
% 
% clf
% plot(cumsum(daily_net_band))
% hold on
% % ylim([0 70])
% xline(113, '-.r');
% xlim([0 364])
% title('Cumulative savings of Medium PCM System in South Eastern region - 11/10/2017-10/10/2018')
% xlabel('Day')
% ylabel('Cumulative net savings (£, thousand)')
% legend('Daily savings', 'End of calendar year', 'location', 'northwest')
% hold off
% 
% clf
% plot(cumsum(day_savings_band))
% hold on
% plot(cumsum(day_costs_band))
% legend('Daily savings', 'Day costs', 'location', 'northwest')



%% Using perfect foresight stratergy

to_sort_pricing = complete_data_2;

if use_triads == 0
    to_sort_pricing{:,11} = to_sort_pricing{:,11} - to_sort_pricing{:,6}.*to_sort_pricing{:,9}.*to_sort_pricing{:,10};
end

if use_smoothing == 1
    upper_perc = prctile(to_sort_pricing{:,11},max_perc);
    lower_perc = prctile(to_sort_pricing{:,11},min_perc);
    to_sort_pricing{to_sort_pricing{:,11}>upper_perc,11} = upper_perc; 
    to_sort_pricing{to_sort_pricing{:,11}<lower_perc,11} = lower_perc;
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
    costs_pf(1+((i-1)*HH_charge):(i)*HH_charge) = sort(costs_pf(1+((i-1)*HH_charge):(i)*HH_charge), 'ascend');
    
    savings_pf(1+((i-1)*HH_discharge):(i)*HH_discharge) = eff * max_discharge_rate/2 * sorted_pricing((48-HH_discharge)+1+((i-1)*48):i*48);
    savings_pf(1+((i-1)*HH_discharge):(i)*HH_discharge) = sort(savings_pf(1+((i-1)*HH_discharge):(i)*HH_discharge), 'descend');
    
    day_savings_pf(i) = sum(savings_pf(1+((i-1)*HH_discharge):(i)*HH_discharge));
    day_costs_pf(i) = sum(costs_pf(1+((i-1)*HH_charge):(i)*HH_charge));
end

tot_cost_pf = sum(costs_pf);
tot_saving_pf = sum(savings_pf);
% net_saving_system_pf = (tot_saving_pf - tot_cost_pf)/100

prctile(complete_data_2{:,11}, 32) % green band is 8/24 hours

prctile(complete_data_2{:,11}, 76) % red band is 3/24

daily_net_pf = (day_savings_pf-day_costs_pf)/100;

net_saving_system_pf= sum(daily_net_pf)


clf
plot(cumsum(daily_net_band/1000))
hold on
plot(cumsum(daily_net_pf/1000))
legend('DUoS band stratergy', 'Perfect foresight stratergy', 'location', 'northwest')
title('Cumlative sum from trading stratergy')
xlabel('Day')
ylabel('Cumulative net savings (£, thousand)')



%% Plotting effects of smoothing on tariffs

n_HH = 1000;

smoothing_string = strcat(num2str(max_perc), '/', num2str(min_perc), ' smoothing');
title_str = ['Tariffs - Unsmoothed vs ' num2str(max_perc) '/' num2str(min_perc) ' smoothing'];

% figure
% plot(complete_data_2{48+1:48+n_HH,11})
% hold on
% plot(smoothed_pricing(1:n_HH,2))
% ylim([0,25])
% legend('Unsmoothed', smoothing_string)
% xlabel('HH period')
% ylabel('Price (p/kWh)')
% title(title_str)

% figure
% plot(complete_data_2{48+1:48+n_HH,11})
% hold on 
% % plot(smoothed_pricing_5(1:n_HH,2))
% plot(smoothed_pricing_2(1:n_HH,2))
% % plot(smoothed_pricing_15(1:n_HH,2))
% % plot(smoothed_pricing_20(1:n_HH,2))
% % legend('Unsmoothed', '95/5', '90/10', '85/15', '80/20')
% % legend('Unsmoothed', '90/10', '80/20')
% legend('Unsmoothed', '98/2')
% xlabel('HH period')
% ylabel('Price (p/kWh)')
% ylim([0,25])


