# EEF_TES
Contains all models and any modifications used in the EEF TES (PCM) project.

Folder structure:
* AllocationAndChargeModelling
    * ChargeOptimisationModelling
    * VehicleToJourneyAllocationWithPowerConstraintsAndRefrigeration
    * VehicleToJourneyAllocationWithRefrigeration
* ClientDataCleaningAndStatGeneration
    * EnergyMeterData
        * SSL
            * SiteLoadProfilesExtraction
* RefrigerationOpsData
* TariffData
* TransportData
    * JLP
        * OrdersAndJourneysCleaning
        * OrdersAndJourneysExtraction
* DashboardTemplates
* GitHubScripts
    * GenerateContentsStructure
* JourneyModelling
    * MinimumVehiclesRequired
    * SimultaenousJourneys
    * SyntheticJourneyGeneration
        * ClusteringMethod
* LoadModelling
    * LoadProfileCleaning
    * LoadProfileForecasting
        * EvLoads
        * ForecastingSiteLoads
* OrderModelling
    * NewPostcodeRegression
    * OrderVolumeScenarioGeneration
* StorageAndDispatchModelling
* TariffModelling
    * FutureTariffForecasting
    * HistoricalComponentAssembly
* TcoAndEmissionModelling
    * FleetLevelEmissionsModels
    * FleetLevelTcoModels
    * StationarySystemCostAndEmissionsModels
    * VehicleLevelEmissionsModels
    * VehicleLevelTcoModels
    * VehicleEnergyUseModelling


Each directory contains a family of models which are applicable to a specific area of energy infrastructure.
E.g. "Vehicle_Modelling" contains scripts which should be used for generation of order volume scenarios, allocation
of orders to individual vehicles to formulate full journeys, and other related applications.

The directory for each family of models is broken down into "Scripts", "Inputs" and "Outputs" folders. When running scripts
on a local clone, the directory structure allows for models to use outputs of other models as required with the need for minimal
path specification by the user.

A local clone of this repository should include a .gitignore file with the following:
*.xlsx
*.xls
*.csv
*.pdf
*.png
*.xlsm
*.rtf
*.fig
*.asv

to prevent unnecessary upload of inputs and outputs to the repository.

Non-project specific inputs can be found on this SharePoint site: https:TBD...
Project specific inputs and outputs should be saved in the appropriate file share location for the project
