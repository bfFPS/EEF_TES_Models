Author(s): BF (FPS)
Date: 05/2020
Project: EEF TES (PCM)
Link to example input file:
Functionality: this script uses the outputs from Step 1 and 2 along with some user set inputs, to generate a set of possible order volumes at the network level. A small number of these based on their percentiles is then passed through to a shuffle of the weekly proportional of network order, MPO and HPO by PCS. Expected order at at PCS each week are then found. A Poisson distrbution is run on these to generate a range of value for each of the passed through scenarios. Finally these are aggregated to the store level based on catchment areas by PCS, then orders, mileages and hours are separated by day based on the ratios found in Step 2. Low, Central and High Economic scenarios as well as an Extreme Infrastructure scenario are the final outputs.
Reference: N/A