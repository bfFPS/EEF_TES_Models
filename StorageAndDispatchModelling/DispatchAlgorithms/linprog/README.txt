This project contains the source files for the linear programming (LP) 
PCM dispatch algorithm, created by Michail Athanasakis in 2020 for FPS.

# note: when downloading the project to run on your machine, you will 
need to change the folder location strings that locate the input files 
required for the cost of electricity and ambient temperature values.
The functions that retrieve this data are in functions.py, so you will 
have to proceed and look for (as of 28 Aug 2020) lines 14-16 and 76-77.

# note: to successfully run the project, you will need to install some 
python modules using pip. As of 28 Aug 2020 these are numpy, pyomo, 
plotly, scipy, and CoolProp. You will also need to download and install 
the glpk solver to your computer. Pyomo is only a wrapper: it takes your 
input and transforms it into input that glpk can read, and then instructs 
glpk to solve the LP problem. Pyomo does not directly solve anything.

The basic structure of the project is that the file linprog.py houses 
the linprog(..) function, which takes as input a starting date, an 
ending date (optionally, if no end date is provided, single-day 
analysis will be performed), and optionally a choice to print or not a 
summary of the solution and a detailed PCM schedule created from the LP 
solution, and the definition of dt, which is the time width of the 
timestep (by default this is 0.5 hrs) and the definition of timestepBunch,
which determines how many timesteps will be considered together in the 
SOC-transfer constraint (by default 48).

The linprog(..) function is then called at various points in the project 
whenever a schedule is needed.


File explanation:

linprog.py
contains the source code for the implementation of the LP model. It 
uses the Pyomo package, which is a python wrapper that calls the glpk 
LP solver. 

senstest.py
contains the code for running sensitivity test on the LP model by 
running long-term analyses using the linprog(..) function after varying 
some variable. Stores the sensitivity test results in the "sensitivity 
tests" folder.

functions.py
is a file that was created for the heuristic model and carried over 
to the LP model. The version kept in the heuristic model project is 
supersede, as development for that model has stopped and I never 
updated that file. The functions file holds the definitions for all 
the general-purpose functions used in the dispatch schedule, such as 
reading the input files and returning specific temperatures and coe, 
changing timperiods into time, arranging the coe for a range of time-
periods into a variety of forms, etc.

System.py
contains the source code for the System class, whose instances are 
meant to represent PCM units. Honestly, the System class is not too 
useful, since project-oriented programming introduces a lot of 
"bureaucracy" in programming and in this case does not offer too 
tremendous benefits. So at some point the System class should be 
removed altogether. It was created during the development of the 
heuristic model and was carried over to the LP model, which in 
hindsight was a mistake. The System class contains all the member 
variables relevant to a PCM (charge/discharge capacity, SOC capacity,
self-discharge rate, etc.) and all associated functions required to 
retrieve or change these values.

operational_variables.py
contains the assignment of important variables that are used throughout
the different files in the project. Because cross-linking of files is 
prohibited in Python, a central file that contains all the important 
variables simplifies processes such as running sensitivity tests by 
varying one or two variables. The file also contains an instance of 
the System class, which is a PCM.

icl_model.py
contains the code for the refrigeration performance model produced by 
Imperial College. This model is superseded and should be substituted 
by performance maps produced with the new model, which however has 
been coded in Matlab. This old model contains the calc_W(..) function 
that takes the PCM temperature, the ambient temperature, the medium-
temperature compressor cooling demand and the low-temperature cooling 
demand as inputs and outputs the total compressor work, the heat 
transfer rate from/to the PCM, and the COP. Since this old model is 
coded in python, whenever one of the three outputs is needed, the 
calc_W(..) function is called directly. When the new model is 
incorporated, the plan is to run the matlab model repeatedly for all 
different combinations of inputs and create a large table with the 
results. When one of the results is needed for the LP model, the 
code should make a search for the appropriate table entry depending 
on the relevant input values.

createHeatmap.py
contains the source code for creating a plotly heatmap of the PCM 
schedule. Takes as input a "schedule" (which is produced as output
in the linprog function within linprog.py), it isolates the dates, 
the times, and the PCM powers, and produces a heatmap.


