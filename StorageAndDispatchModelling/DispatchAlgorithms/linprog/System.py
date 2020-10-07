# Class file for systems (refrigeration and PCM)
# Michail Athanasakis for Flexible Power Systems Ltd.
# Last updated: 2 July 2020

import functions as f


class System:
	def __init__(self, mode=False, initialSoc=0):
		# mode=True means SUBCOOLING. mode=False means CONDENSER_BYPASS
		self.mode = mode
		
		self.Q_charge = 0
		self.periodicDischargeRate = 0.001 # in kW
		self.initialSoc = initialSoc
		self.soc = self.initialSoc 		# soc is the State of Charge. Basically, how much MORE heat
		self.maxCapacity = 300			# the PCM can absorb until it reaches self.capacity (which is in kW)
										# This means that when soc is at 450, it is at full charge. Because 
										# it can still absorb the full 450 of capacity until it reaches 0.
										# So: soc=0 means it cannot discharge anymore (absorb heat), and 
										# soc=450 means it cannot charge anymore (release heat)
										# Everytime the PCM is charged, its SOC increases and everytime
										# it discharges, its SOC decreases. Periodically, the SOC decreases
										# because of a self-discharge mechanism.
		if self.soc > self.maxCapacity:
			raise ValueError("SOC exceeds max capacity")

		self.maxChargeRate = 80
		self.maxDischargeRate = -80 
	

####################################################

	def condenser_bypass(self, newmode):
			self.mode = newmode

####################################################


	def increaseSoc(self, value):
		self.soc = self.soc + value

	def decreaseSoc(self, value):
		self.soc = self.soc - value

####################################################


	def set_Q_charge(self, q):		# must be in kW
		self.Q_charge = q
	
	def set_maxCapacity(self, value):
		if value <= 10 or value >=700:
			raise ValueError
		else:
			self.maxCapacity = value
	
	def set_maxChargeRate(self, value):
		self.maxChargeRate = value
	
	def set_maxDischargeRate(self, value):
		self.maxDischargeRate = value

	def set_periodicDischargeRate(self, value):
		self.periodicDischargeRate = value

####################################################

	def get_maxChargeRate(self):
		return self.maxChargeRate
	
	def get_maxDischargeRate(self):
		return self.maxDischargeRate

	def get_soc(self):
		return self.soc

	def get_initialSoc(self):
		return self.initialSoc
	
	def get_periodicDischargeRate(self):
		return self.periodicDischargeRate
####################################################


	def get_Q_charge(self):
		return self.Q_charge

####################################################


	def get_mode(self):
		return self.mode

####################################################


	def get_maxCapacity(self):
		return self.maxCapacity

# PRIVATE METHODS


	#def __calculate_soc():
		#SOC capacity = 450 kWh
























