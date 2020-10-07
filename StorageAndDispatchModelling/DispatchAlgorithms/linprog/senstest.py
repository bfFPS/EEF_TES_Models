# code for sensivity test on the LP model. the actual variable that is 
# varied can be changed easily, with no changes to the structure of the 
# file
# Michail Athanasakis for Flexible Power Systems.
# Last updated: 26 August 2020

import linprog as lp
import operational_variables as ov
from os import remove
from os.path import isfile
from datetime import datetime
from plotly.subplots import make_subplots
import plotly.graph_objects as go

print("Start...")

sensStart = datetime.now()

start1 = "15/07/2018"
end1 = "14/10/2018"

start2 = "15/10/2018"
end2= "14/01/2019"

start3 = "15/01/2019"
end3 = "14/04/2019"

start4 = "15/04/2019"
end4 = "14/07/2019"

# Because linprog can't run a multi-day analysis for more than three months
# at a time, to run a longer analysis you need to break the time period
# into 3-month periods and run the multi-day analyses successively, 
# appending the results into a single variable.
starts = [start1, start2, start3, start4] # for full year
ends = [end1, end2, end3, end4] # for full year
schedsched = []     # will hold the full schedule

# change the fileFolder into whatever folder you want to save the results in
fileFolder = "/home/michail/FPS/PCM/despatch_algorithm/linprog/sensitivity tests/yearly/"
filePrefix = fileFolder+"sensYearlyTradeProfitRecording"
fileNumber = 1

# will hold the results of all analyses
periodicrates, profits, charges, discharges, trades = [], [], [], [], []

# save the currently stored value in the variable to be varied
initialPeriodicDischargeRate = ov.pcm.get_periodicDischargeRate()

# set variable behavior
initialValue = 0.001
increment = 0.15
finalValue = 1

# set an initial value for the sensitivity test
ov.pcm.set_periodicDischargeRate(0.001)

i = increment
while i < finalValue:
    for j in range(len(starts)):
        tempProf, tempCh, tempDis, tempTr, tempSch = lp.pulplinprog(starts[j], ends[j], print_summary=True)
        schedsched += tempSch
    
    # populate the results lists
    periodicrates.append(ov.pcm.get_periodicDischargeRate())
    profits.append(tempProf)
    charges.append(tempCh)
    discharges.append(tempDis)
    trades.append(tempTr)

    # these prints are to make sure that the variable behaves as expected
    print(ov.pcm.get_periodicDischargeRate())
    ov.pcm.set_periodicDischargeRate(ov.pcm.get_periodicDischargeRate() + increment)
    print(ov.pcm.get_periodicDischargeRate())
    print("i="+str(i))

    i += increment

# restore the previously kept value
ov.pcm.set_periodicDischargeRate(initialPeriodicDischargeRate)

print("Sensitivity test finished")

# if a file with the filePrefix and the fileNumber exists, then increase
# the fileNumber until there is no existing file with this name
while isfile(filePrefix+str(fileNumber)+".txt"):          # from os.path
    fileNumber += 1

# write the schedule results in the file
file = open(filePrefix+str(fileNumber)+".txt", "w")
for i, line in enumerate(schedsched):
    if i % 10 == 0:
       file.write(str(line)+"\n")
file.close()

# make the plots using plotly
fig = make_subplots(rows=2, cols=1, subplot_titles=("Profit vs periodic discharge rate", "Trades vs periodic discharge rate"))
fig.add_trace(
    go.Scatter(x=periodicrates, y=profits), row=1, col=1)
fig.add_trace(
    go.Scatter(x=periodicrates, y=trades), row=2, col=1)
fig.update_layout(height=800, width=600, showlegend=False, title_text="Note: periodic discharge even when SOC=0")
fig.update_xaxes(title_text="Periodic discharge rate (kW)")
fig.update_yaxes(title_text="Profit (GBP)", row=1, col=1)
fig.update_yaxes(title_text="Total trades", row=2, col=1)
fig.show()

# print total test runtime
sensRuntime = datetime.now() - sensStart
print("Sensitivity test runtime: "+str(sensRuntime))