% checks

% sum(daily_scenarios_table.Orders(daily_scenarios_table.Scenario == 1) - daily_scenarios_table.store_historic_orders(daily_scenarios_table.Scenario == 1))
% %  -> scenario under-estimates by -118009 
% 
plot(daily_scenarios_table.Orders(daily_scenarios_table.Scenario == 1 & daily_scenarios_table.Store_ID == 828))
hold on 
plot(daily_scenarios_table.store_historic_orders(daily_scenarios_table.Scenario == 1 & daily_scenarios_table.Store_ID == 828))
legend('scenario', 'historic')
% % -> large underestimation in orders
% 
% plot(daily_scenarios_table.Orders(daily_scenarios_table.Scenario == 1 & daily_scenarios_table.Store_ID == 122))
% hold on 
% plot(daily_scenarios_table.store_historic_orders(daily_scenarios_table.Scenario == 1 & daily_scenarios_table.Store_ID == 122))
% legend('scenario', 'historic')
% % -> large underestimation in orders

% CHECK THE PROPORTION OF NETWORK ORDERS ACCOUNTED FOR BY FOCUS STORE PCS EACH
% WEEK
by_prop_net = zeros(53,1);
for iWeek = 1:53
    by_prop_net(iWeek) = sum(MPO_HPO_by_PCS.ProportionOfTotalNetworkVolume(MPO_HPO_by_PCS.Week == iWeek));
end
plot(by_prop_net)


for iStore = 1:length(focus_stores)
    this_store = focus_stores(iStore);
    plot(daily_scenarios_table.Orders(daily_scenarios_table.Scenario == 1 & daily_scenarios_table.Store_ID == this_store))
    hold on 
    plot(daily_scenarios_table.store_historic_orders(daily_scenarios_table.Scenario == 1 & daily_scenarios_table.Store_ID == this_store))
    legend('scenario', 'historic')
    pause(4)
    close
end