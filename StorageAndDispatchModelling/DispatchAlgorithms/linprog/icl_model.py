# -*- coding: utf-8 -*-
"""
Created on Sun Jun 30 11:55:06 2019

@author: nl211
"""

#import CoolProp.CoolProp as CP
from CoolProp.CoolProp import PropsSI
import numpy as np

# Tx = PCM temperature, Text = ambient temperature, Q_cab = load on MT evaporator, Q_lt_cab = load on LT evap
def calc_W(Tx, Text, Q_cab, Q_lt_cab, PCM = False, bypass_condenser = False, cop_only=False):

    Tx = int(Tx)
    Text = int(Text)
    #### input of the model
    fluid = 'CO2'
    p11 = 36e5
    p12 = 28e5
    p15 = 14e5
    p_super_crit = 85e5
    T_lt_superheat = 35
    T_ht_superheat = 15
    
    DTcond = int(8)
    eff_iso_comp = 0.65
    
    
    # preprocessing
    supercrit = False
    if Text + DTcond > 30:
        supercrit = True
    Tx = Tx +273.15 ##in K
    Text = Text  +273.15 ##in K
    
    ##### PCM Model #######
    if bypass_condenser == True:
        assert(PCM == True)


    if supercrit == False:
        if PCM == True:
            if bypass_condenser == True:						# supercrit false, PCM true, bypass_condenser true
                Tsat = Tx +DTcond 
                T7 = Tsat
                p7 = PropsSI('P', 'T', T7, 'Q', 0, fluid)
                h7 = PropsSI('H', 'T', T7, 'Q', 0, fluid)    
            else: 											# supercrit false, PCM true, bypass_condenser false
                Tsat = Text + DTcond 
                T7 = Tx+DTcond
                p7 = PropsSI('P', 'T', Tsat, 'Q', 0, fluid)
                h7 = PropsSI('H', 'T', T7, 'P|liquid', p7, fluid)
        else:											# supercrit false, PCM false
            Tsat = Text + DTcond 
            T7 = Tsat
            p7 = PropsSI('P', 'T', T7, 'Q', 0, fluid)
            h7 = PropsSI('H', 'T', T7, 'P|liquid', p7, fluid) 
    else:
        if PCM == True:
            if bypass_condenser == True:						# supercrit true, PCM true, bypass_condenser true
                Tsat = Tx +DTcond 
                T7 = Tsat
                p7 = PropsSI('P', 'T', T7, 'Q', 0, fluid)
                h7 = PropsSI('H', 'T', T7, 'Q', 0, fluid)    
            else:											# supercrit true, PCM true, bypass_condenser false
                Tsat = Text + DTcond 
                T7 = Tx+DTcond
                p7 = p_super_crit
                h7 = PropsSI('H', 'T', T7, 'P', p7, fluid)
        else:											# supercrit true, PCM false
            p7 = p_super_crit
            T7 = Text + DTcond 
            h7 = PropsSI('H', 'T', T7, 'P', p7, fluid)         
    
    
    #### calculate operating points    
    h11 = PropsSI('H', 'P', p11, 'Q', 0, fluid)  
    h9 = PropsSI('H', 'P', p11, 'Q', 1, fluid) 
    
    h12 = h11
    h15 = h11
    
    T10 = PropsSI('T', 'P', p12, 'Q', 1, fluid)
    h10 = PropsSI('H', 'P', p12, 'Q', 1, fluid)
    T16 = PropsSI('T', 'P', p15, 'Q', 1, fluid)
    h16 = PropsSI('H', 'P', p15, 'Q', 1, fluid)
    
    T4 = T10 + T_ht_superheat
    p4 = p12     
    h4 = PropsSI('H', 'T', T4, 'P|gas', p4, fluid)
    s4 = PropsSI('S', 'T', T4, 'P|gas', p4, fluid)

    T1 = T16 + T_lt_superheat    
    p1 = p15
    h1 = PropsSI('H', 'T', T1, 'P|gas', p1, fluid)
    s1 = PropsSI('S', 'T', T1, 'P|gas', p1, fluid)

    p5 = p7
    if supercrit == True and  bypass_condenser == False:
        h5_iso = PropsSI('H', 'S', s4, 'P', p5, fluid)
    else:
        h5_iso = PropsSI('H', 'S', s4, 'P|gas', p5, fluid)
    h5  = h4 + (h5_iso-h4)/eff_iso_comp
    
    p2=p4
    h2_iso = PropsSI('H', 'S', s1, 'P|gas', p2, fluid)
    h2  = h1 + (h2_iso-h1)/eff_iso_comp

    #### calculate mass flowrates
    m_cab =  Q_cab*1e3/(h10-h12) ##kg/s
    m_lt_cab =  Q_lt_cab*1e3/(h16-h15)##kg/s
    r9 = (h7 - h11)/(h9-h11)
    mHP =   (m_lt_cab+  m_cab)/(1-r9)
    m9 = r9*mHP

####error
#    m9 = (h7 - h11)/(h9-h11)
#    mHP =   (m_lt_cab+  m_cab)+m9

    
    #### compressor power
    Wcomp = (h5-h4)*mHP/1000 ##kW
    W_ltcomp =  (h2-h1)*m_lt_cab/1000 ##kW
    W_tot = Wcomp+W_ltcomp
    
    ## calculate PCM requirements
    if PCM == True:
        if bypass_condenser == True:
            Q_PCM = mHP*(h5-h7)
        else: 
            if supercrit == True:
                hl = PropsSI('H', 'T', Tsat, 'P', p7, fluid)
            else:
                hl = PropsSI('H', 'T', Tsat, 'P|liquid', p7, fluid)
            Q_PCM = mHP*(hl-h7)
    else:
        Q_PCM = 0
        
        
    Q_PCM = Q_PCM/1000 ##kW
    COP =(Q_cab+Q_lt_cab)/W_tot
#    print(COP, m_cab, m9)

	# W_tot: total electrical power requirement for evaporators
	# Q_PCM: rate of heat supplied (kW) from PCM
    if cop_only:
        return COP
    else:
        return(W_tot, Q_PCM, COP)

if __name__ == '__main__':
    
    ## model validation
    import pandas as pd
    W_tot, _ = calc_W(5, 12, 70, 10)#, PCM = True, bypass_condenser = True)
    df = pd.read_excel('Wellesbourne.xlsx', skiprows =5)
    df.index = df['Date']
    df['kW1'] = df['Actual (kW)'].shift(-1)
    df['kW2'] = df['Actual (kW)'].shift(1)
    df['kW'] = df['Actual (kW)']/2 + df['kW1']/4+ df['kW2']/4
    df = df[df.index.minute == 0]
    df['Temp']=df['Temperature (°C)']
    df = df [['kW','Temp']]
    df = df.dropna()
    

    df['pred'] = df['Temp'].apply(lambda x: calc_W(5, x, 70, 10)[0])
    
    
#    df1 = df[(df.index.hour > 9) & (df.index.hour < 22)]
    df1 = df
    import matplotlib.pyplot as plt
    plt.figure(1)
    plt.scatter(df1['pred'], df1['kW'])
    plt.plot(range(90), c = 'r')
    plt.figure(2)
    plt.scatter(range(80),df['pred'][:80])
    plt.scatter(range(80),df['kW'][:80])
    print(W_tot)
    
    
