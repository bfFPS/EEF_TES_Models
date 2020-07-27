%% Script to calculate Costs and Emissions with optimistic assumptions - JA, 12/2019

%% Set user run parameters and date

% user set version of run
run_version = '01';

% user set client
client = 'JLP';

% user set initials 
user_initials = 'BF';

% set user input file path
user_path = 'C:\Users\FPSScripting2\Documents\Consolidated_Models\TcoAndEmissionModelling';

% extract year and month of run
run_year = num2str(year(datetime(now, 'ConvertFrom','datenum')));
run_year = run_year(3:4);
run_month = num2str(month(datetime(now, 'ConvertFrom','datenum')));
if length(run_month) == 1
    run_month = strcat('0', run_month);
end
run_date = strcat(run_year, '-', run_month);

%% Set parameters

%Cost Factors 
%Diesel Vehicle - Mercedes Sprinter
 Purchasecost = 31100/7; %Purchase cost divided across 7 years
 Drivercost = 21316; 
 VED = 255; %Vehicle excise duty
 Insurance = [1147; 1147; 1147; 1147; 1147; 1147; 744;1147]; %Insurance for different vehicle types
 MPG = 27.5; %miles per gallon
 Tyre =  [0.0131; 0.0131; 0.0131; 0.0131; 0.0131; 0.0131; 0.0072;0.0131]; %For different vehicle types
 Maint = 0.0834; %maintenance costs
 Fuelcost = 4.92; % £/gallon
 
 %Electric Vehicles
 %LDVE80, Renault Master ZE, Arrival T4, eSprinter-LR, eSprinter-HR,
 %eSprinter-3.9T, eVito, future Vehicle
 EV_Purchasecost = [(60000-8000-4236.29)/7; (56000-8000-2496.38)/7; (55000-8000-4538.8)/7; (47500-8000-6377.13)/7; (47505-8000-4168.20)/7; (49605-8000-4160.64)/7; (40000-8000-3131.83)/7;(47505-8000-4168.20)/7;]; 
 EV_VED = 0; %vehicle excise duty
 Electricity = [0.582; 0.542; 0.604; 0.717; 0.738; 0.738; 0.563; 0.664]; %kWh/mile for different EV types
 EV_Maint = [0.04; 0.04; 0.04; 0.04; 0.04; 0.04; 0.03; 0.04]; %maintenance costs for different EV types

 EP = 0.06;   %electricity price £/kW

 ChargerMC = 125+70; %charger maintenance costs
 %Battery replacement costs
 BPCost = [0.02; 0.01; 0.011; 0.012; 0.015; 0.015; 0.011;0.022];
 
 %Emission Factors
 %Diesel
 EF_D_1 = 2.68779; %Scope 1 Emission factor kg/litres
 EF_D_2 = 0; %Scope 2 Emission factor
 EF_D_3 = 0.62564 ; %Scope 3 Emission factor
 
 %Electric
 EF_EV_1 = 0; %Scope 1 Emission factor kg/kWh
 EF_EV_2 = 0.28307; %Scope 2 Emission factor
 EF_EV_3 = 0.02413; %Scope 3 Emission factor
 
 %Other parameters
 Charger_ = [3.3;6.3;9.9;45]; %Different charger types 
 Range = [95.94; 60.148; 99.4 ;57.17; 74.56; 74.56; 74.1;124.3]; %EV Range 
 Battery = [56; 33;60 ;41; 55; 55; 41.4;82.5]; %Battery pack capacity
 Type = {'LDVE80'; 'Master ZE'; 'Arrival T4'; 'eSprinter-LR'; 'eSprinter-HR'; 'eSprinter-3.9T'; 'eVito'; 'Future'};
 siz_c = size(Charger_,1);
 %Load stores.mat 
 b = size(branch_id,1);

 %Creating output table
 sz = [1 14]; % size of the table based on the number of vans being used in the store (+ ev)
    varTypes = {'double', 'string', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double'};
    varNames = {'BranchId', 'Vehicletype', 'VehicleNo', 'Purchasecost', 'DriverCost', 'VED' , 'Insurancecost', 'FuelCost', 'Tyrecost', 'MaintenaceCost', 'Charger', 'FixedCost' , 'Variablecost', 'TotalVehicleCost' };
    result = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames); %creating table

 % Initialise z  = 0 
 z = 0;   
 
 %% Script begins
 
% Calculation steps 
 for v = 1: size(Type,1) % for each vehicle type
     clc
    fprintf('status: %d/%d', v, size(Type,1))
    for c = 1: siz_c  %for each charger rating
    
        if Charger_(c) > 6.3
         ChargerFC = (925+285+45)/10;  %Charger Fixed Costs based on the rating
        else 
         ChargerFC = (905+285+45)/10;
        end
     
    for bid = 1:b % Loop through every store 
         clc
   fprintf('status: %d/%d', bid, b)
     d_1 = readtable(fullfile(user_path, strcat(num2str(Range(v)),'_newstoreD_',num2str(branch_id(bid)),'_',num2str(Battery(v)),'_',num2str(Electricity(v)),'_',num2str(Charger_(c)),'.csv'))); %Reading StoreE and storeD output files
     d_2 = readtable(fullfile(user_path, strcat(num2str(Range(v)),'_newstoreE_',num2str(branch_id(bid)),'_',num2str(Battery(v)),'_', num2str(Electricity(v)),'_',num2str(Charger_(c)),'.csv')));
      %d_1.Properties.VariableNames{40} = 'chargerType';
            if size(d_1,1) > 0 
                data = [d_1;d_2]; 
            else
                 data = d_2;
            end  
    %Fixing date range to one year - ignore if done individually for each
    %year
%      d1 = datetime(2019,01,01);
%      d2 = datetime(2019,12,31);
%     idx = data.Start_Date_of_Route >= d1 & data.Start_Date_of_Route <= d2;
   
%     data = data(idx,:);
    
    %Filtering diesel and EV journeys 
     data_diesel = data(data.vannumber_d_ > 0,:); 
     data_ev = data(data.vannumber_ev_ > 0,:); 
 
     %Finding unique diesel and EV vans being used 
     vans = unique(data_diesel.vannumber_d_);
     ev = unique(data_ev.vannumber_ev_);
     
        if vans > 0 %If diesel vans exist
                for i = 1:size(vans,1) %loop through all the diesel vans
                    data_d = data_diesel(data_diesel.vannumber_d_ == i,:); %Filter journeys for particular diesel van
                    result.BranchId(i+z) = branch_id(bid); 
                    result.Vehicletype(i+z) = 'D'; 
                    result.VehicleNo(i+z) = vans(i);
                    result.Mileage(i+z) = sum(data_d.newJourneyMileage); %Calculate the annual mileage
                    result.Purchasecost(i+z) = Purchasecost;
                    result.DriverCost(i+z) = Drivercost;
                    result.VED(i+z) = VED;
                    result.Insurancecost(i+z) = Insurance(v);
                    result.FuelCost(i+z) = ((result.Mileage(i+z)/MPG)) *Fuelcost; 
                    result.Tyrecost(i+z) = result.Mileage(i+z) * Tyre(v);
                    result.MaintenaceCost(i+z) = result.Mileage(i+z) * Maint;
                    result.FixedCost(i+z) = result.Purchasecost(i+z) + result.DriverCost(i+z) + result.VED(i+z) + result.Insurancecost(i+z);
                    result.Variablecost(i+z) = result.FuelCost(i+z) + result.Tyrecost(i+z) + result.MaintenaceCost(i+z) ;
                    result.TotalVehicleCost(i+z) = result.FixedCost(i+z) + result.Variablecost(i+z);
                    result.Charger(i+z) = Charger_(c); 
                    result.Type(i+z) = Type(v);
                    result.Fuel(i+z) = result.Mileage(i+z) ./ MPG;
                    result.Scope1(i+z) = result.Fuel(i+z) * 4.55 * EF_D_1/1000; % *4.55 to convert gal to lt; in tonnes
                    result.Scope2(i+z) = result.Fuel(i+z)* EF_D_2; % Scope 2 in tonnes
                    result.Scope3(i+z) = result.Fuel(i+z) * 4.55 * EF_D_3 / 1000 ;% Scope 3 in tonnes
                    result.Total(i+z) = result.Scope1(i+z) + result.Scope2(i+z) + result.Scope3(i+z) ;%Total emissions
                end
        end
 
        for i = (1+ size(vans,1)) : (size(ev,1) + size(vans,1)) %loop through all the ev vans
            data_e = data_ev(data_ev.vannumber_ev_ == (i-size(vans,1)) ,:);
            result.BranchId(i+z) = branch_id(bid);
            result.Vehicletype(i+z) = 'EV';
            result.VehicleNo(i+z) = ev(i-size(vans,1));
            result.Mileage(i+z) = sum(data_e.newJourneyMileage);
            result.Purchasecost(i+z) = EV_Purchasecost(v);
            result.DriverCost(i+z) = Drivercost;
            result.VED(i+z) = EV_VED;
            result.Insurancecost(i+z) = Insurance(v);
            result.FuelCost(i+z) = result.Mileage(i+z)  .* (Electricity(v) * EP);
            result.Tyrecost(i+z) = result.Mileage(i+z)  * Tyre(v);
            result.MaintenaceCost(i+z) = result.Mileage(i+z)  * EV_Maint(v);
            result.BPCost(i+z) = BPCost(v) * result.Mileage(i+z);
            result.Charger_cost(i+z) = ChargerFC + ChargerMC;
            result.FixedCost(i+z) = result.Purchasecost(i+z) + result.DriverCost(i+z) + result.VED(i+z) + result.Insurancecost(i+z) + result.Charger(i+z) ;
            result.Variablecost(i+z) = result.FuelCost(i+z) + result.Tyrecost(i+z) + result.MaintenaceCost(i+z) +  result.BPCost(i+z);
            result.TotalVehicleCost(i+z) = result.FixedCost(i+z) + result.Variablecost(i+z);
            result.Charger(i+z) = Charger_(c);
            result.Type(i+z) = Type(v);
            result.Fuel(i+z) = result.Mileage(i+z)  .* Electricity(v) ;
            result.Scope1(i+z) = result.Fuel(i+z) * EF_EV_1; %Scope 1 emissions in tonnes
            result.Scope2(i+z) = result.Fuel(i+z)* EF_EV_2/1000; %Scope 2 emissions in tonnes
            result.Scope3(i+z) = result.Fuel(i+z)* EF_EV_3 / 1000; %Scope 3 emissions in tonnes
            result.Total(i+z) = result.Scope1(i+z) + result.Scope2(i+z) + result.Scope3(i+z); % Total emissions in tonnes
            %Calculate alternative diesel costsss
            result.FuelCost_(i+z) = ((result.Mileage(i+z)/MPG)) *Fuelcost; 
            result.Tyrecost_(i+z) = result.Mileage(i+z) * Tyre(v);
            result.MaintenaceCost_(i+z) = result.Mileage(i+z) * Maint;
            result.FixedCost_(i+z) = Purchasecost + Drivercost + VED + Insurance(v);
            result.Variablecost_(i+z) = result.FuelCost_(i+z) + result.Tyrecost_(i+z) + result.MaintenaceCost_(i+z) ;
            result.TotalVehicleCost_(i+z) = result.FixedCost_(i+z) + result.Variablecost_(i+z);
            %
            if result.TotalVehicleCost_(i+z) < result.TotalVehicleCost(i+z) %Checking if diesel vehicle would be profitable
               result.TotalVehicleCost(i+z) =  result.TotalVehicleCost_(i+z);
               result.Vehicletype(i+z) = 'D';
               result.FixedCost(i+z) = result.FixedCost_(i+z);
               result.Variablecost(i+z) = result.Variablecost_(i+z);
               result.Fuel(i+z) = result.Mileage(i+z) ./ MPG;
               % If diesel then calculate emissions 
               result.Scope1(i+z) = result.Fuel(i+z) * 4.55 * EF_D_1/1000; % *4.55 to convert gal to lt; in tonnes
               result.Scope2(i+z) = result.Fuel(i+z)* EF_D_2; % Scope 2 in tonnes
               result.Scope3(i+z) = result.Fuel(i+z) * 4.55 * EF_D_3 / 1000 ;% Scope 3 in tonnes
               result.Total(i+z) = result.Scope1(i+z) + result.Scope2(i+z) + result.Scope3(i+z) ;%T
            end
        end
        z = size(result,1)
    end
  end
 end

writetable(result, fullfile(user_path, 'Outputs', strcat(run_date, '.', client, '.', '2020TCO_optimistic_new', '.', run_version, '.', user_initials, '.csv')));