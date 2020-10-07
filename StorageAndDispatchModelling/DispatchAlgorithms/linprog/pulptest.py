# PCM schedule with linear programming (PuLP package)
# Michail Athanasakis for Flexible Power Systems Ltd.
# Last updated: 2 September 2020

import numpy as np
import numpy.matlib
from pulp import *
from random import randint
import operational_variables as ov
import functions as f
import icl_model as iclm
from datetime import datetime
from createHeatmap import createHeatmap
from pulp import *

##############################################################################################

def pulpLinprog(start_date=ov.date, end_date=None, print_summary=False, print_schedule=False, dt=ov.time_width, timestepBunch=48):
    # We start by creating all the necessary matrices for calculating the 
    # cost of delivering refrigeration at any point in time.

    # coe = cost of electricity at some half hour period (eg 00:30-01:00)
    # this returns a list of "DATE, HH, COE" for timeperiods in order.
    if end_date == None:
        coe = f.get_coe_by_date(start_date)
    else:
        coe = f.concatenate_coe_by_date_range(start_date, end_date)
    
    # total timesteps is your total number of coe values
    s = len(coe)

    # Create a lower triangular matrix 
    TMatrix = np.zeros((s,s))   # lower triangular matrix
    for i in range(len(TMatrix[:])):
        for j in range(len(TMatrix[0,:])):
            if i >= j:
                TMatrix[i,j] = 1
            else:
                TMatrix[i,j] = 0
    
    # Create the matrix that holds the values for the business-as-usual (bau) load of the
    # refrigeration system
    bauLoad = np.zeros((s,1))
    for i in range(s):
        bauLoad[i] = randint(60, 80)

    # Here we create matrices that hold the COPs (coefficients of performance, ie efficiencies)
    # for the bau case (no pcm), and the system when PCM is discharging. The cop must be 
    # different for these cases because the physical system takes a complete different 
    # arrangement in these two functions.

    # During PCM charging, the cop is the same as bau (no PCM i.e. PCM on standby)

    # For each cop matrix, three entries will be put in each row: the date, the timeperiod,
    # and the cop.

    bauCOP = []               # bauCOP is the BAU cop (and charging COP) matrix
    dischargingCOP = []       # dischargingCOP is the cop matrix for a discharging PCM
    
    # also initialize the matrix that will hold only the coe matrices (no date and time)
    Lambda = np.zeros((s, 1))

    for i in range(s):
        bauCOP.append([None,None,None])
        dischargingCOP.append([None,None,None])

    # two loops might be redundant but it's negligible runtime cost and it's easier to 
    # understand what's happening

    for i in range(s):

        Lambda[i] = round(coe[i][2], 2)     # keep coe matrix as a column s-by-1

        # remember that the coe matrix (not Lambda) also has dates and times, 
        # so copy from there
        bauCOP[i][0] = coe[i][0]            # date
        bauCOP[i][1] = coe[i][1]            # time
        _, __, bauCOP[i][2] = iclm.calc_W(ov.T_PCM, \
            f.get_ambient_temperature(coe[i][0], coe[i][1]), ov.Q_mt, ov.Q_lt)

        dischargingCOP[i][0] = coe[i][0]    # date
        dischargingCOP[i][1] = coe[i][1]    # time
        _, __, temp = iclm.calc_W(ov.T_PCM, \
            f.get_ambient_temperature(coe[i][0], coe[i][1]), ov.Q_mt, ov.Q_lt, PCM=True, bypass_condenser=False)
        dischargingCOP[i][2] = temp - 1.5   # the current way of calculating d_COP is wrong
                                            # and tentative, and produces negative profits
                                            # so this is just to produce positive profit

    # Since the COP when PCM is charging is the same as when the PCM is on standby (bau case)
    # we can just copy the matrix
    chargingCOP = bauCOP

    # This is just a matrix where each item in Lambda is multiplied by dt.
    combinedLambda = dt * Lambda

    ##############################################################################################

    prob = LpProblem("PCM_Schedule_with_PuLP", LpMinimize)

    s = 48
    u = [
        # LpVariable("PCMpower"+str(i+1), -100, 100) for i in range(s)
        LpVariable("PCMpower"+str(i+1)) for i in range(s)
    ]

    # create SOC next-day transfer constraint in bunches of multipleOf48
    multipleOf48 = int( s / timestepBunch )
    for j in range(multipleOf48):
        leftSlice = int(j*timestepBunch + 1)
        rightSlice = int((j+1)*timestepBunch)
        prob += sum(u[leftSlice:rightSlice]) >= 0
        prob += sum(u[leftSlice:rightSlice]) <= ov.pcm.get_maxCapacity()


    # implement here the self-discharge option as you derived in the office
    # the self-discharge takes place at each timestep as SOC loss.
    # At any timestep k, the total self-discharge loss has been dt * lambda * k
    # where lambda is the self-discharge rate in kW and k the current timestep.
    leftLimit = -1*ov.pcm.get_initialSoc()/dt
    rightLimit = (ov.pcm.get_maxCapacity() - ov.pcm.get_initialSoc() ) / dt
    eta = ov.pcm.get_periodicDischargeRate() # by default at 0.001 kW

    j = 0
    for k in range(len(u)):
        T_amb = f.get_ambient_temperature(coe[k][0], coe[k][1]) # coe[k][0] and coe[k][1] are date and timeperiod respectively.
        prob += u[k] >= -1 * bauLoad[k,0]
        # constr. for dynamic (interpolated) discharge power
        prob += u[k] >= -1*f.maxDischargePower(T_amb)
        prob += u[k] <= ov.pcm.get_maxChargeRate()

        if j > 48:
            j = 0
        
        # def left_limit():    # nested function definition to impose a piece-wise constraint
        #     if sum(u) <= 0.5:
        #         return leftLimit
        #     elif sum(u) > 0.5:
        #         return leftLimit + J*eta

        # model.limits.add( (left_limit(), sum(model.u[j] for j in range(1, K+1)), rightLimit) ) # should make this piecewise
        prob += sum(u[:k]) >= leftLimit
        prob += sum(u[:k]) <= rightLimit
        j += 1
    
    # print(prob)
    # return


    # objective function is ready!
    prob += sum(
        combinedLambda[k,0] * (bauLoad[k,0] / bauCOP[k][2] + (1/bauCOP[k][2]) * u[k]) for k in range(len(u))
    )




    prob.solve()
    # print("here")
    # for var in u:
    #     print(var.value())
    ############### MAKE SCHEDULE ##############################

    chargingEvents = 0 
    dischargingEvents = 0
    totalChargeCost = 0
    totalReductionInCost = 0
    pcmSchedule = [["Date", "HH", "Q_dot", "Mode", "SOC", "dt * CoE", "BAU COP"]]

    m = 1
    for k in range(len(u)):
        if m > 48:
            m = 1
        pcmSchedule.append([coe[k][0], m, u[k].value(), "", 0, 0, 0, 0])
        if pcmSchedule[-1][2] == 0:
            pcmSchedule[-1][3] = "standby"
        elif pcmSchedule[-1][2] < 0:
            pcmSchedule[-1][3] = "discharging"
        elif pcmSchedule[-1][2] > 0:
            pcmSchedule[-1][3] = "charging"

        pcmSchedule[-1][2] = round(pcmSchedule[-1][2], 5)

        if k == 0:
            pcmSchedule[-1][4] = ov.pcm.get_initialSoc() + pcmSchedule[-1][2]*dt
        else:
            pcmSchedule[-1][4] = pcmSchedule[-2][4] + pcmSchedule[-1][2]*dt
        pcmSchedule[-1][4] = round(pcmSchedule[-1][4], 1)

        # check if SOC exceeds limits. Sometimes it might go to -0.001 or 300.001 so
        # we increase the limits by 1 kW to prevent false alarms
        if pcmSchedule[-1][4] < -1:
            print("PCM SOC below 0.")
        elif pcmSchedule[-1][4] > ov.pcm.get_maxCapacity()+1:
            print("PCM SOC above max capacity", ov.pcm.get_maxCapacity(),"kWh.")
        
        
        day = coe[k][0]
        hh = pcmSchedule[-1][1]
        pcmSchedule[-1][5] = combinedLambda[hh-1, 0]

        costElectricity = f.get_coe_by_date_and_time(day, hh)
        pcmSchedule[-1][6] = round(costElectricity, 2)


    #     ############ CALCULATE PROFITS #############
        for i in range(len(u)):
            if chargingCOP[i][0] == day and chargingCOP[i][1] == hh:
                c_COP = chargingCOP[i][2]
                d_COP = dischargingCOP[i][2]
                break
        
        if pcmSchedule[-1][2] > 0:
            chargingEvents += 1
            totalChargeCost += pcmSchedule[-1][2] / c_COP * dt * costElectricity

        elif pcmSchedule[-1][2] < 0:
            dischargingEvents += 1
            totalReductionInCost += -1 * pcmSchedule[-1][2] / d_COP * dt * costElectricity

        m += 1
            
    totalProfit = round((totalReductionInCost - totalChargeCost)/100, 2)
    numberTrades = (chargingEvents + dischargingEvents) / 2

    if print_summary:
        print("The initial SOC was", ov.pcm.get_initialSoc()," kWh. The total profit for this schedule is", totalProfit, \
            "GBP with a total of", chargingEvents, "charging events and", \
                dischargingEvents, "discharging events.")
    
    if print_schedule: 
        if end_date == None:
            print("PCM schedule for", start_date, "with initial SOC", ov.pcm.get_initialSoc(), "kWh:")
        else:
            print("PCM schedule for period from", start_date, "to", end_date, "with initial SOC", ov.pcm.get_initialSoc(), "kWh:")
        for line in pcmSchedule:
            print(line)

    return totalProfit, chargingEvents, dischargingEvents,\
         numberTrades, pcmSchedule





if __name__ == "__main__":
    print("Start...")

    start1 = "01/07/2018"
    end1 = "20/07/2018"

    pulpLinprog(start1, end1, print_summary=True)




