path = 'C:\Users\FPSScripting2\Documents\Consolidated_Models\Vehicle_Modelling\Order_Volume_Scenario_Generation\Testing Outputs';

central_all = readtable(fullfile(path, 'central_scenario_all_poisson_22-May-2020.csv'));
central_selected = readtable(fullfile(path, 'central_scenario_selected_poisson_22-May-2020.csv'));
extreme_all = readtable(fullfile(path, 'extreme_operational_scenario_all_poisson_22-May-2020.csv'));
extreme_selected = readtable(fullfile(path, 'extreme_operational_scenario_selected_poisson_22-May-2020.csv'));
high_all = readtable(fullfile(path, 'high_economic_scenario_all_poisson_22-May-2020.csv'));
high_selected = readtable(fullfile(path, 'high_economic_scenario_selected_poisson_22-May-2020.csv'));
low_all = readtable(fullfile(path, 'low_economic_scenario_all_poisson_22-May-2020.csv'));
low_selected = readtable(fullfile(path, 'low_economic_scenario_selected_poisson_22-May-2020.csv'));

numb_scenarios = 100;

store = 122;

figure
for iSim = 1:numb_scenarios
    plot(central_all.Orders(central_all.Store_ID == store & central_all.Scenario == iSim), '-b')
    hold on
end
hold on
plot(central_selected.Orders(central_selected.Store_ID == store), '-r', 'LineWidth',2)
close

figure
for iSim = 1:numb_scenarios
    plot(high_all.Orders(high_all.Store_ID == store & high_all.Scenario == iSim), '-b')
    hold on
end
hold on
plot(high_selected.Orders(high_selected.Store_ID == store), '-r', 'LineWidth',2)
close

figure
for iSim = 1:numb_scenarios
    plot(low_all.Orders(low_all.Store_ID == store & low_all.Scenario == iSim), '-b')
    hold on
end
hold on
plot(low_selected.Orders(low_selected.Store_ID == store), '-r', 'LineWidth',2)
close

% IF OLD METHOD: demonstrates that taking max of max network isn't going to give max of
% all years. Purpose of this test is to test effects of coincidence of high
% volume weeks with inluencing high external factors. Hence should likely
% scrape values from all scenarios
% IF NEW METHOD: shows that extracted scenario is now correctly the 99th
% realistic volume
figure
for iSim = 1:numb_scenarios
    plot(low_all.Orders(low_all.Store_ID == store & low_all.Scenario == iSim), '-g','DisplayName','All Low Poisson')
    hold on
end
for iSim = 1:numb_scenarios
    plot(central_all.Orders(central_all.Store_ID == store & central_all.Scenario == iSim), '-k','DisplayName','All Central Poisson')
    hold on
end
for iSim = 1:numb_scenarios
    plot(high_all.Orders(high_all.Store_ID == store & high_all.Scenario == iSim), '-y','DisplayName','All High Poisson')
    hold on
end
for iSim = 1:numb_scenarios
    plot(extreme_all.Orders(extreme_all.Store_ID == store & extreme_all.Scenario == iSim), '-b','DisplayName','All Extreme Poisson')
    hold on
end
hold on
plot(extreme_selected.Orders(extreme_selected.Store_ID == store), '-r', 'LineWidth',2)
xlabel('Order Volume')
ylabel('Week')
xlim([0 53])
% legend('All Low Poisson', 'All Central Poisson', 'All High Poisson', 'All Extreme Poisson', 'Compiled Extreme Output', 'Location', 'southoutside')
% lgd = legend;
title('Store 122: Weekly Order Volumes Post-Poisson Permutations')
close



% compare low, central and high
figure
plot(low_selected.Orders(low_selected.Store_ID == store),'LineWidth',2)
hold on
plot(central_selected.Orders(central_selected.Store_ID == store),'LineWidth',2)
plot(high_selected.Orders(high_selected.Store_ID == store),'LineWidth',2)
plot(extreme_selected.Orders(extreme_selected.Store_ID == store), 'LineWidth',2)
ylabel('Order Volume')
xlabel('Week')
xlim([0 53])
title('Store 122: Weekly Order Volumes Final Output Scenarios')

% legend('Low', 'Central', 'High', 'Extreme')
close

