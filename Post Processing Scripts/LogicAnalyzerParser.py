import os
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path
from tkinter import Tk
from tkinter.filedialog import askopenfilename

wellMap = ['A6', 'C6', 'D6']

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
    
#%%
risingEdgeIndices = []
for channelNum in range(numChannels):
    thisData = data[:,channelNum]
    differenceArray = np.diff(thisData)
    largeDifferenceIndices = np.argwhere(differenceArray > np.amax(differenceArray)/4)
    largeDifferenceIndicesPositives = largeDifferenceIndices[thisData[1:][largeDifferenceIndices] > .1]
    largeDifferenceIndicesPositives = np.insert(largeDifferenceIndicesPositives, 0, 0)
    risingEdgeIndices.insert(channelNum, largeDifferenceIndicesPositives[1:][np.diff(largeDifferenceIndicesPositives) > 1] + 1)


#%%
fig, axs = plt.subplots(numChannels, figsize=(80, 40))
for channelNum in range(numChannels):
    axs[channelNum].plot(timestamps[:], data[:,channelNum])
    axs[channelNum].plot(timestamps[risingEdgeIndices[channelNum][:]], data[:,channelNum][risingEdgeIndices[channelNum][:]], "x")     #Plot the peaks with little X's
    
fig.savefig(f"{targetPlotsFolderName}\{targetDataFolderName}_test", bbox_inches = 'tight')

#%%
fig, axs = plt.subplots(numChannels, figsize=(80, 40), sharey = True)
for channelNum in range(numChannels):
    timingDifferences = np.diff(timestamps[risingEdgeIndices[channelNum]])
    axs[channelNum].plot(np.arange(timingDifferences.shape[0]), timingDifferences)
    axs[channelNum].set_title(f'Well {wellMap[channelNum]}', fontsize = 60)
    axs[channelNum].set_xlabel('Pulse Number', fontsize = 30)
    axs[channelNum].set_ylabel('Twitch Delay (sec)', fontsize = 20)
    axs[channelNum].tick_params(which = 'major', labelsize = 20)
    axs[channelNum].minorticks_on()
    axs[channelNum].grid(which='major', linewidth=1.5)
    axs[channelNum].grid(which='minor', linewidth=.5)
    axs[channelNum].legend(fontsize = 20)
    
fig.savefig(f"{targetPlotsFolderName}\{targetDataFolderName}_differences", bbox_inches = 'tight')


#%% Clock analysis
differenceArray = np.diff(data)
largeDifferenceIndices = np.argwhere(differenceArray > np.amax(differenceArray)/4)
largeDifferenceIndicesPositives = largeDifferenceIndices[data[1:][largeDifferenceIndices] > .1]
largeDifferenceIndicesPositives = np.insert(largeDifferenceIndicesPositives, 0, 0)
risingEdgeIndices = largeDifferenceIndicesPositives[1:][np.diff(largeDifferenceIndicesPositives) > 1] + 1

fig, axs = plt.subplots(figsize=(80, 10))
timingDifferences = np.diff(timestamps[risingEdgeIndices]) * 1e6
axs.plot(np.arange(timingDifferences.shape[0]), timingDifferences)
axs.set_title('System Clock', fontsize = 60)
axs.set_xlabel('Clock Num', fontsize = 30)
axs.set_ylabel('Clock Period (us)', fontsize = 20)
axs.tick_params(which = 'major', labelsize = 20)
axs.minorticks_on()
axs.grid(which='major', linewidth=1.5)
axs.grid(which='minor', linewidth=.5)
axs.legend(fontsize = 20)
    
fig.savefig(f"{targetPlotsFolderName}\{targetDataFolderName}_differences", bbox_inches = 'tight')
