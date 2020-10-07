# Source file for heatmap generation for linprog schedules
# Michail Athanasakis for Flexible Power Systems Ltd.
# Last updated: 12 August 2020


import plotly.graph_objects as go
import numpy as np
from functions import convert_tp_to_time



def createHeatmap(schedule):

    dates = []
    timeperiods = list(range(1, 49))

    for i in range(len(schedule)):
        try:
            dates.index(schedule[i][0])
        except ValueError:
            dates.append(schedule[i][0])
    
    loads = np.zeros((len(timeperiods), len(dates)))

    for i, date in enumerate(dates):
        for j, tp in enumerate(timeperiods):
            for entry in schedule:
                if entry[0] == date and entry[1] == tp:
                    loads[j, i] = entry[2]
    
    # use loads, dates, and timeperiods as your data
    timeperiods = convert_tp_to_time(timeperiods)
    fig = go.Figure(data=go.Heatmap(
        z=loads,
        y=timeperiods,
        x=dates,
        hoverongaps=False,
        colorbar=dict(title='PCM Power (kW)') 
        ))


    fig.update_layout(
        title="PCM Schedule from "+str(dates[1])+" to "+str(dates[-1])
    )
    fig.show()



    return