# python scripts for auxiliary functions for profit.py
# Michail Athanasakis for Flexible Power Systems Ltd.
# Last updated: 21 August 2020

from icl_model import calc_W
from scipy.interpolate import interp1d
import numpy as np

#---------------------------------- Ambient Temperature processing -------------------------------------
EARLIEST_DATE = "01/01/2018"
# LATEST_DATE = "14/10/2019"
LATEST_DATE = "31/12/2018"

temp_data = []
#file_folder = INSERT THE FOLDER WITH THE INPUT FILES HERE
temp_file_loc = "C:/Users/FPSScripting2/Documents/R&D Projects/EEF_7_149 TES/EEF_TES_Models/StorageAndDispatchModelling/DispatchAlgorithms/linprog/input/loads_0003_2018_BGKtemp.csv"
#temp_file_loc = file_folder+r"\20-06.SSL.0003_historic_cleaned_loads.01.BF.csv"
temp_file = open(temp_file_loc, "r")

for i, line in enumerate(temp_file):
	words = line.split(",")
	words[0] = words[0].split(" ")
	if i % 2 == 0:		# only store the lines with XX:00 times, because the XX:30 lines do not have temperature data
		temp_data.append([words[0], words[3]])

del temp_data[0]		# delete first line with titles
temp_file.close()

temperature_data = []	# create a new list to hold data in a cleaner way. line.split() creates a weird data set
for i, line in enumerate(temp_data):
	temperature_data.append([line[0][0],line[0][1], line[1]])


# because we did not append the lines for XX:30 hours, we will create new such lines and assign to them the temperature
# of the preceding time. So for each line in the current list, we insert after it a new entry with identical data.
i = 0	
while i < len(temperature_data):
	temporary = temperature_data[i]
	temperature_data.insert(i+1, [temporary[0], temporary[1], temporary[2]])
	i+=2
temp = temperature_data[0]
temperature_data.insert(0, [temp[0], temp[1], temp[2]])
temperature_data.insert(0, [temp[0], temp[1], temp[2]])	# first 2 lines manually
														# because the file is clunky

# and at this step, we change all times into time periods. Time periods go from 1 to 48, starting with 00:30 and up to 00:00
j = 1
for i in range(len(temperature_data)):
	if j > 48:
		j = 1
	temperature_data[i][1] = j
	j+=1

#---------------------------------------------------------------------------------------------------------------------------------------

# date in STRING format of "dd/mm/yyyy" from 01/01/2018 to 01/01/2020. Time (INT) is time period (Half-Hours) 1-48
def get_ambient_temperature(date, time):
	for i, entry in enumerate(temperature_data):
		if date == entry[0]:
			if time == entry[1]:
				if entry[2] == "":
					if temperature_data[i-1][2] != "":
						entry[2] = temperature_data[i-1][2]
					else:
						entry[2] = temperature_data[i-2][2]
				if float(entry[2]) < 2.0:
					return 2
				elif float(entry[2]) > 34.0:
					return 34.0
				else:
					return float(entry[2])
	return "No data exists for the specific date."

#--------------------------------------------- COE processing ------------------------------------------------

coe_data = []
coe_file_loc = "C:/Users/FPSScripting2/Documents/R&D Projects/EEF_7_149 TES/EEF_TES_Models/StorageAndDispatchModelling/DispatchAlgorithms/linprog/input/BGK_modified_linprogtariff.csv"
#coe_file_loc = file_folder+r"\20-06.JLP.compiled_historical_tariffs.01.BF.csv"

coe_file = open(coe_file_loc, "r")
for i, line in enumerate(coe_file):
	# if i > 32113:
	if i > 17522:
		break	 # only read CoE values for Eastern England	
	words = line.split(",")
	coe_data.append(words)

i = 0
while i < len(coe_data):
	if coe_data[i][-1] == 'NaN\n':
		del coe_data[i]
	else:
		del coe_data[i][0:2]
		del coe_data[i][2:10]
		coe_data[i][-1] = coe_data[i][-1].strip('\n')
		if i > 0:
			coe_data[i][1] = int(coe_data[i][1])
			coe_data[i][-1] = float(coe_data[i][-1])
			coe_data[i][-1] = round(coe_data[i][-1], 3)
		i += 1
coe_file.close()

list_of_dates = []
for i in range(1, len(coe_data)):
	if i == 1:
		list_of_dates.append(coe_data[i][0])
	elif coe_data[i][0] in list_of_dates:
		continue
	else:
		if coe_data[i][0] == coe_data[i-1][0]:
			continue
		else:
			list_of_dates.append(coe_data[i][0])

# target_date has to be in STRING format "dd/mm/yyyy" from 01/01/2018 until 31/10/2019
# time period has be INT from 1 to 48 and represents half hour intervals. period 1 is 00:30. 00:00 is period 48 
# of the previous day. so 05:00 is period 10, 10:00 is period 20, 15:00 is period 30, 20:00 is period 40
def get_coe_by_date_and_time(target_date, time_period):
	for entry in coe_data:
		if entry[0] == target_date:
			if entry[1] == time_period:
				return entry[2]
	return "No data exists for the specified date."

#---------------------------------------------------------------------------------------------------------------------------------------
# returns a list that contains the CoE for each time period in the target_date
def get_coe_by_date(target_date):
	coe_by_date_list = []
	for entry in coe_data:
		if entry[0] == target_date:
			coe_by_date_list.append(entry)
	return coe_by_date_list

#---------------------------------------------------------------------------------------------------------------------------------------
# returns a list that contains the CoE for each time period in the target_date
def get_date_range(start_date, end_date):
	startIndex = list_of_dates.index(start_date)
	endIndex = list_of_dates.index(end_date) + 1
	return list_of_dates[startIndex:endIndex]

def concatenate_coe_by_date_range(start_date, end_date):
	coeList = []
	dateRange = get_date_range(start_date, end_date)
	for day in dateRange:
		coeData = get_coe_by_date(day)
		coeList += coeData
	return coeList

#---------------------------------------------------------------------------------------------------------------------------------------
# quicksort algorithm for sorting arrays withat least 3 elements. The list gets sorted according to 3rd entry
def quicksort(list, order):
	less = []
	equal = []
	greater = []
	
	if len(list) > 1:
		pivot = list[0]
		for entry in list:
			if entry[2] < pivot[2]:
				less.append(entry)
			elif entry[2] == pivot[2]:
				equal.append(entry)
			elif entry[2] > pivot[2]:
				greater.append(entry)
	
		if order == "ascending":
			return quicksort(less, "ascending")+equal+quicksort(greater, "ascending")
		elif order == "descending":
			return quicksort(greater, "descending")+equal+quicksort(less, "descending")
		else:
			return "The order can only be ascending or descending. Please enter correct order in str format."
	else:
		return list

#---------------------------------------------------------------------------------------------------------------------------------------
# calls get_coe_by_date(..) and returns the quicksorted time periods in the date according to the CoE	
def sort_timeperiods_by_coe(target_date):
	return quicksort(get_coe_by_date(target_date), "ascending")

#---------------------------------------------------------------------------------------------------------------------------------------

def sort_timeperiods_by_coe_and_cop(target_date, T_pcm, Q_mt, Q_lt):
	coe_list = sort_timeperiods_by_coe(target_date)
	mixed_coe_data = []

	for item in coe_list:
		T_amb = get_ambient_temperature(item[0], item[1])
	
		# I only care about the COP so I use _ and __ for the other two variables
		# calc_W(...) returns W_tot, Q_PCM, COP

		_, __, cop = calc_W(T_pcm, T_amb, Q_mt, Q_lt)
		cop = round(cop, 3)
		coe_cop_product = round(1/item[2]*cop, 3)
	
		# append a new entry in the new list with: date, 1/coe * COP, coe, cop
		mixed_coe_data.append([item[0], item[1], coe_cop_product, item[2], cop])
	
	return quicksort(mixed_coe_data, "descending")

#---------------------------------------------------------------------------------------------------------------------------------------
# get total capacity of delivering refrigeration 
#def get_peak_capacity(date, time):
	#this function will be written once we have a revamped model and a script for variable 
	# load during the day currently the peak refrigeration capacity will be given as 1.4 * 80



#---------------------------------------------------------------------------------------------------
# a function that takes a list with integers from 1 to 48 and converts them to strings
# from 00:30 to 00:00
def convert_tp_to_time(timeperiods):
	hour = 0
	deciminute = 3
	convertedHours = []

	for i in range(len(timeperiods)):
		if i % 2 == 0:
			deciminute = 3
		else:
			deciminute = 0
		if i % 2 == 1:
			hour += 1
		
		if hour < 10:
			temp = "0"+str(hour)+":"+str(deciminute)+"0"
		elif hour >= 10 and hour < 24:
			temp = str(hour)+":"+str(deciminute)+"0"
		elif hour == 24:
			hour = 0
			temp = "0"+str(hour)+":"+str(deciminute)+"0"
		
		convertedHours.append(temp)

	return convertedHours



#########################################################################

p = [-120, -80, -40, 0, 40, 80, 120]
temprRange = range(-5,41)

powerLevels = []
temprtrs = []

for i in temprRange:
    powerLevels += p
    temprtrs += len(p) * [i]

imperialCOP = len(temprtrs) * [None]
for j in range(len(temprtrs)):
    if powerLevels[j] < 0:
        _, __, temp = calc_W(5, temprtrs[j], 70, 10, PCM=True)
    else:
        _, __, temp = calc_W(5, temprtrs[j], 70, 10)
    imperialCOP[j] = round(temp, 3)

#powerLevels = np.array(powerLevels)
#temprtrs = np.array(temprtrs)
#imperialCOP = np.array(imperialCOP)
#powerLevels = np.reshape(powerLevels, (len(powerLevels), 1))
#temprtrs = np.reshape(temprtrs, (len(temprtrs), 1))
#coords = np.concatenate((temprtrs, powerLevels), axis=1)	# All great here!

# a function that returns the correct COP depending on whether 
def get_cop(load, date, time):
	T_amb = get_ambient_temperature(date, time)
	load_mt = 7/8 * load
	load_lt = 1/8 * load

	if load >= 0:
		_,__,cop = calc_W(0, T_amb, load_mt, load_lt)
	else:
		_,__,cop = calc_W(0, T_amb, load_mt, load_lt, PCM=True)

	return cop

################ SPLINES NEEDED FOR PIECEWISE VARIABLES #################
maxDischargeTemperatures = [-5, 0, 5, 10, 15, 20, 25, 30, 35, 40]
maxDischargeRates = [0, 0, 0, 10.73759, 22.42149, 36.0174, 56.8107, 54.50289, 62.88506, 70.23952]
# this is now a function which can be called 
maxDischargePower = interp1d(maxDischargeTemperatures, maxDischargeRates, kind="cubic")



########### LOAD PROFILE EXTRACTION HERE #########################
load_file_loc = "C:/Users/FPSScripting2/Documents/R&D Projects/EEF_7_149 TES/EEF_TES_Models/StorageAndDispatchModelling/DispatchAlgorithms/linprog/input/example_dataset.csv"

load_file = open(load_file_loc, 'r')

load_data = []
for i, line in enumerate(load_file):
	if i==0:
		continue
	words = line.split(",")

	words[0] = words[0].split(" ")
	words[2] = words[2].strip('\n')

	if words[1] == '0':
		load_data.append([words[0][0], 48, float(words[2])/0.5])
	else:
		load_data.append([words[0][0], int(words[1]), float(words[2])/0.5])

load_file.close()

del load_data[0]		# delete first line with titles
for i, line in enumerate(load_data):
	if load_data[i][1] == 48:
		load_data[i][0] = load_data[i-1][0]



def get_load_by_date_and_time(date, time):
	for i in range(len(load_data)):
		if load_data[i][0] == date:
			if load_data[i][1] == time:
				return load_data[i][2]
	return("Date and time not in range of the records.")


def get_load_by_date(date):
	load_by_date_list = []
	for entry in load_data:
		if entry[0] == date:
			load_by_date_list.append(entry)
	return load_by_date_list


def concatenate_load_by_date_range(start_date, end_date):
	loadList = []
	dateRange = get_date_range(start_date, end_date)
	for day in dateRange:
		loadData = get_load_by_date(day)
		loadList += loadData
	return loadList


##

# if __name__ == "__main__":
