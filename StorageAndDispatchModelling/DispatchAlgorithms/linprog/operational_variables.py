# Just defines the values for some operational variables. This file gets imported in the other files, 
# so that these variables become global in all files that import them.
# Michail Athanasakis for Flexible Power Systems Ltd.
# Last updated on 20 August 2020



import functions as f
from System import *
#import icl_model as iclm

###############################
date = "15/07/2018"
time_width = 0.5
T_PCM = 0 
Q_mt = 70
Q_lt = 10
PEAK_REFRIGERATION_CAPACITY = 112 # kW
PEAK_ELECTRICAL_CAPACITY = 500 # kW
# timeperiods = f.sort_timeperiods_by_coe_and_cop(date, T_PCM, Q_mt, Q_lt)
pcm = System(mode=False, initialSoc=0)	# subcooling
leftoverSOC = 0


###############################


# make a set 








