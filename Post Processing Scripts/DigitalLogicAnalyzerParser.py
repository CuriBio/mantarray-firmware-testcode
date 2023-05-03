import os
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path
from tkinter import Tk
from tkinter.filedialog import askopenfilename

wellMap = ['D4', 'C4', 'B4', 'A4']

#%%
root = Tk()
root.wm_attributes('-topmost', 1)
fileName = askopenfilename()
root.destroy()

filePath = Path(fileName)

targetDataFolderName = filePath.name[:-4]
targetPlotsBasePath = f'{filePath.parent.parent}/plots'
targetPlotsFolderName = f'{targetPlotsBasePath}/{targetDataFolderName}_plots'

if (os.path.exists(targetPlotsBasePath) == False): 
    os.mkdir(targetPlotsBasePath)
    
if (os.path.exists(targetPlotsFolderName) == False): 
    os.mkdir(targetPlotsFolderName)
    
#%%
headers = np.loadtxt(fileName, max_rows = 1, delimiter = ',', dtype = str)
numHeaders = headers.shape[0]
numChannels = numHeaders - 1
timestamps = np.loadtxt(fileName, skiprows = 1, delimiter = ',', usecols = 0)
data = np.loadtxt(fileName, skiprows = 1, delimiter = ',', usecols = tuple(np.arange(1, numHeaders)))
    
#%% Clock Parsing
risingEdgeTimepointsClock = timestamps[data == 1][:-1]
clockPeriod = np.mean(np.diff(risingEdgeTimepointsClock))
stimulationStepClock = clockPeriod * 502000
print(f'The clock derived step is {stimulationStepClock}')

#%% Multi-Channel Sitm Parsing
risingEdgePattern = [0,1]
indexArray = np.insert((data[:-1]==risingEdgePattern[0]) & (data[1:]==risingEdgePattern[1]), 0, 0, axis = 0)
broadcastTimestamps = np.broadcast_to(np.expand_dims(timestamps, 1), indexArray.shape)
risingEdgeTimepointsPulses = np.reshape(broadcastTimestamps[indexArray], (-1, 4))
numRisingEdges = risingEdgeTimepointsPulses.shape[0]
stimulationStepAverage = np.mean(np.diff(risingEdgeTimepointsPulses, axis = 0), axis = 0)
# stimulationStepAverage = (risingEdgeTimepointsPulses[-1] - risingEdgeTimepointsPulses[0]) / (numRisingEdges - 1)
print(f'The average mean step is {stimulationStepAverage}')

#%% Stim Parsing
risingEdgeTimepointsPulses = timestamps[data == 1]
numRisingEdges = risingEdgeTimepointsPulses.shape[0]
stimulationStepAverage = np.mean(np.diff(risingEdgeTimepointsPulses, axis = 0))
print(f'The average mean step is {stimulationStepAverage}')

#%%Interpolation
stimulationBegin = risingEdgeTimepointsPulses[0]

# Average based calculation for interpolation
stimulationEndAverage = stimulationBegin + (stimulationStepAverage * numRisingEdges)
interpolatedPulsesAverage = np.linspace(stimulationBegin, stimulationEndAverage, numRisingEdges, False)

# Clock based calculation for interpolation
stimulationEndClock = stimulationBegin + (stimulationStepClock * numRisingEdges)
interpolatedPulsesClock = np.linspace(stimulationBegin, stimulationEndClock, numRisingEdges, False)

delaysAverage = interpolatedPulsesAverage - risingEdgeTimepointsPulses
delaysClock = interpolatedPulsesClock - risingEdgeTimepointsPulses

#%%
fig, axs = plt.subplots(figsize=(20, 20), sharey = True)
axs.plot(np.diff(risingEdgeTimepointsClock) * 1e6)
axs.set_title('Changes in clock period over time', fontsize = 60)
axs.set_xlabel('Pulse Number', fontsize = 30)
axs.set_ylabel('Clock Period (us)', fontsize = 20)
axs.tick_params(which = 'major', labelsize = 20)
axs.minorticks_on()
axs.grid(which='major', linewidth=1.5)
axs.grid(which='minor', linewidth=.5)
axs.legend(fontsize = 20)
    
fig.savefig(f"{targetPlotsFolderName}\{targetDataFolderName}_differences", bbox_inches = 'tight')

#%%
interpolatedClockSignal = np.linspace(risingEdgeTimepointsClock[0], risingEdgeTimepointsClock[0] + (np.mean(np.diff(risingEdgeTimepointsClock)) * risingEdgeTimepointsClock.shape[0]), risingEdgeTimepointsClock.shape[0], False)
fig, axs = plt.subplots(figsize=(20, 20), sharey = True)
axs.plot((risingEdgeTimepointsClock - interpolatedClockSignal) * 1e6)
axs.set_title('Clock Drift from Expected to Measured Rising Edges', fontsize = 40)
axs.set_xlabel('Pulse Number', fontsize = 30)
axs.set_ylabel('Delay Between Expected and Measured Clock (us)', fontsize = 20)
axs.tick_params(which = 'major', labelsize = 20)
axs.minorticks_on()
axs.grid(which='major', linewidth=1.5)
axs.grid(which='minor', linewidth=.5)
axs.legend(fontsize = 20)
    
fig.savefig(f"{targetPlotsFolderName}\{targetDataFolderName}_drift", bbox_inches = 'tight')

#%%
fig, axs = plt.subplots(figsize=(20, 20), sharey = True)
for index, thisData in enumerate(delaysAverage.T):
    axs.plot(thisData * 1000, label=f'{wellMap[index]} Average-Based Interpolation')
for index, thisData in enumerate(delaysClock.T):
    axs.plot(thisData * 1000, label=f'{wellMap[index]} Clock-Based Interpolation')
axs.set_title('Interpolation Accuracies', fontsize = 60)
axs.set_xlabel('Pulse Number', fontsize = 30)
axs.set_ylabel('Delay Between Expected and Measured Pulse (ms)', fontsize = 20)
axs.tick_params(which = 'major', labelsize = 20)
axs.minorticks_on()
axs.grid(which='major', linewidth=1.5)
axs.grid(which='minor', linewidth=.5)
axs.legend(fontsize = 20)
    
fig.savefig(f"{targetPlotsFolderName}\{targetDataFolderName}_differences", bbox_inches = 'tight')

#%%
fig, axs = plt.subplots(figsize=(20, 20), sharey = True)
axs.plot(delaysAverage * 1000, label='Average-Based Interpolation')
axs.set_title('Interpolation Accuracies', fontsize = 60)
axs.set_xlabel('Pulse Number', fontsize = 30)
axs.set_ylabel('Delay Between Expected and Measured Pulse (ms)', fontsize = 20)
axs.tick_params(which = 'major', labelsize = 20)
axs.minorticks_on()
axs.grid(which='major', linewidth=1.5)
axs.grid(which='minor', linewidth=.5)
axs.legend(fontsize = 20)
    
fig.savefig(f"{targetPlotsFolderName}\{targetDataFolderName}_differences", bbox_inches = 'tight')