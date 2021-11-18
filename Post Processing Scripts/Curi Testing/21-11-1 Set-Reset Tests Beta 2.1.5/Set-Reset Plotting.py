#%% Import Libraries
import numpy as np
import matplotlib.pyplot as plt
from tkinter import Tk
from tkinter.filedialog import askopenfilename
from pathlib import Path
from scipy import signal as sig


#%% Load data
root = Tk()
root.wm_attributes('-topmost', 1)
fileName = askopenfilename()
root.destroy()

filePath = Path(fileName)
dateName = Path(fileName).stem[:-5]

numWells = 24
numSensors = 3
numAxes = 3
rowDim = 4
colDim = 6
dimensionsTuple = (numWells, numSensors, numAxes)
axisMap = ['X', 'Y', 'Z']
wellMap = ['A1', 'A2', 'A3', 'A4', 'A5', 'A6', 
           'B1', 'B2', 'B3', 'B4', 'B5', 'B6', 
           'C1', 'C2', 'C3', 'C4', 'C5', 'C6', 
           'D1', 'D2', 'D3', 'D4', 'D5', 'D6']
memsicCenterOffset = 2**15
memsicMSB = 2**16
memsicFullScale = 16
gauss2MilliTesla = .1

totDataPoints = numWells * numSensors * numAxes

config = np.loadtxt(fileName, max_rows = 1, delimiter = ', ').reshape(dimensionsTuple)

activeSensors = np.any(config, axis = 2)
spacerCounter = 1
timestampSpacer = [0]
dataSpacer = []
for (wellNum, sensorNum), status in np.ndenumerate(activeSensors):
    if status:
        numActiveAxes = np.count_nonzero(config[wellNum,sensorNum])
        for numAxis in range(1, numActiveAxes + 1):
            dataSpacer.append(timestampSpacer[spacerCounter - 1] + numAxis)
        timestampSpacer.append(timestampSpacer[spacerCounter - 1] + numActiveAxes + 1)
        spacerCounter+=1
        
timestamps = np.loadtxt(fileName, skiprows = 1, delimiter = ', ', usecols = tuple(timestampSpacer[:-1])) / 1000000
data = (np.loadtxt(fileName, skiprows = 1, delimiter = ', ', usecols = tuple(dataSpacer)) - memsicCenterOffset) * memsicFullScale / memsicMSB * gauss2MilliTesla
numSamples = timestamps.shape[0] - 2
fullData = np.zeros((numWells, numSensors, numAxes, numSamples))
fullTimestamps = np.zeros((numWells, numSensors, numSamples))

dataCounter = 0
for (wellNum, sensorNum, axisNum), status in np.ndenumerate(config):
    if status:
        fullData[wellNum, sensorNum, axisNum] = data[2:, dataCounter]
        dataCounter+=1
       
timestampCounter = 0
for (wellNum, sensorNum), status in np.ndenumerate(activeSensors):
    if status:
        fullTimestamps[wellNum, sensorNum] = timestamps[2:, timestampCounter]
        timestampCounter+=1
        
#%% Check if any data is coming from broken sensors, or if there are bad samples in the data capture
brokenArray = np.any(np.any((fullData==.7999755859375001), axis = 3), axis = 2)
for (wellNum, sensorNum), isBroken in np.ndenumerate(brokenArray):
    if isBroken:
        print (f'Well {wellMap[wellNum]} sensor {sensorNum+1} is broken, setting all data points to 0')
fullData[fullData==.7999755859375001] = 0

outlierIndices = []
for (wellNum, sensorNum, axisNum), _ in np.ndenumerate(fullData[:,:,:,0]):
    axisData = fullData[wellNum, sensorNum, axisNum, :]
    positiveOutliers = sig.find_peaks(axisData, threshold = .1)[0]
    for outlier in positiveOutliers:
        if outlier not in outlierIndices:
            outlierIndices.append(outlier)
    negativeOutliers = sig.find_peaks(axisData*-1, threshold = .1)[0]
    for outlier in negativeOutliers:
        if outlier not in outlierIndices:
            outlierIndices.append(outlier)
        
for outlier in outlierIndices:
    print (f"Bad data packet at index {outlier}, smoothing it")
    fullData[:,:,:,outlier] = fullData[:,:,:,outlier-2]

abberantArray = np.any(np.any((fullData==-.8), axis = 3), axis = 1)
for (wellNum, sensorNum), isBroken in np.ndenumerate(abberantArray):
    if isBroken:
        print (f'Well {wellMap[wellNum]} sensor {sensorNum+1} has aberrant data, setting all aberrant data points to 0.  If you are running a frequency analysis, I recommend recapturing the data')
fullData[fullData==-.8] = 0
        
#%%
fullDataSet = fullData[:,:,:,0::2]
fullDataReset = fullData[:,:,:,1::2]
fullTimestampsOffsetCompensated = fullTimestamps[:,:,0::2]
if fullDataReset.shape[-1] != fullDataSet.shape[-1]:
    fullDataSet = fullDataSet[:,:,:,:-1]
    fullTimestampsOffsetCompensated = fullTimestampsOffsetCompensated[:,:,:-1]
fullDataOffsetCompensated = (fullDataSet + fullDataReset)/2

#%%
fig, axs = plt.subplots(4, 6, figsize=(100, 100))
for wellNum in range(numWells):
    row = int(wellNum / 6)
    col = int(wellNum % 6)
    # fig, axs = plt.subplots(3, figsize=(10, 30))
    # fig, axs = plt.subplots(3, 3, figsize=(30, 30))
    for (sensorNum, axisNum), status in np.ndenumerate(config[wellNum]):
        axs[row, col].plot(fullTimestampsOffsetCompensated[wellNum, sensorNum, :], fullDataSet[wellNum, sensorNum, axisNum, :] * 1000, label=f'Sensor {sensorNum + 1} Axis {axisMap[axisNum]} Set')
        axs[row, col].plot(fullTimestampsOffsetCompensated[wellNum, sensorNum, :], fullDataReset[wellNum, sensorNum, axisNum, :] * 1000, label=f'Sensor {sensorNum + 1} Axis {axisMap[axisNum]} Reset')
        axs[row, col].plot(fullTimestampsOffsetCompensated[wellNum, sensorNum, :], fullDataOffsetCompensated[wellNum, sensorNum, axisNum, :] * 1000, label=f'Sensor {sensorNum + 1} Axis {axisMap[axisNum]} Comp')
    axs[row, col].set_title(f'Well {wellMap[wellNum]}', fontsize = 60)
    axs[row, col].set_xlabel('Time (sec)', fontsize = 30)
    axs[row, col].set_ylabel('Magnitude (uT)', fontsize = 20)
    axs[row, col].tick_params(which = 'major', labelsize = 20)
    axs[row, col].minorticks_on()
    axs[row, col].grid(which='major', linewidth=1.5)
    axs[row, col].grid(which='minor', linewidth=.5)
    axs[row, col].legend(fontsize = 20)
    
fig.savefig(f"{filePath.parent.parent / 'plots'}\{dateName}_transient", bbox_inches = 'tight')

#%%
for wellNum in range(numWells):
    fig, axs = plt.subplots(3, 3, figsize=(60, 60))
    for (sensorNum, axisNum), status in np.ndenumerate(config[wellNum]):
        axs[sensorNum, axisNum].plot(fullTimestampsOffsetCompensated[wellNum, sensorNum, :], fullDataSet[wellNum, sensorNum, axisNum, :] * 1000, label=f'Sensor {sensorNum + 1} Axis {axisMap[axisNum]} Set')
        axs[sensorNum, axisNum].plot(fullTimestampsOffsetCompensated[wellNum, sensorNum, :], fullDataReset[wellNum, sensorNum, axisNum, :] * 1000, label=f'Sensor {sensorNum + 1} Axis {axisMap[axisNum]} Reset')
        axs[sensorNum, axisNum].plot(fullTimestampsOffsetCompensated[wellNum, sensorNum, :], fullDataOffsetCompensated[wellNum, sensorNum, axisNum, :] * 1000, label=f'Sensor {sensorNum + 1} Axis {axisMap[axisNum]} Comp')
        axs[sensorNum, axisNum].set_title(f'Sensor {sensorNum + 1}: Axis {axisMap[axisNum]}', fontsize = 60)
        axs[sensorNum, axisNum].set_xlabel('Time (sec)', fontsize = 30)
        axs[sensorNum, axisNum].set_ylabel('Magnitude (uT)', fontsize = 20)
        axs[sensorNum, axisNum].tick_params(which = 'major', labelsize = 20)
        axs[sensorNum, axisNum].minorticks_on()
        axs[sensorNum, axisNum].grid(which='major', linewidth=1.5)
        axs[sensorNum, axisNum].grid(which='minor', linewidth=.5)
        axs[sensorNum, axisNum].legend(fontsize = 20)
    fig.suptitle(f'Well {wellMap[wellNum]}', fontsize = 250)
    fig.savefig(f"{filePath.parent.parent / 'plots'}\{dateName}_{wellMap[wellNum]}_transient", bbox_inches = 'tight')
        
#%%
fig, axs = plt.subplots(4, 6, figsize=(100, 100))
for wellNum in range(numWells):
    row = int(wellNum / 6)
    col = int(wellNum % 6)
    # fig, axs = plt.subplots(3, figsize=(10, 30))
    # fig, axs = plt.subplots(3, 3, figsize=(30, 30))
    for (sensorNum, axisNum), status in np.ndenumerate(config[wellNum]):
        if status:
            #axs[row, col].plot(fullTimestampsOffsetCompensated[wellNum, sensorNum, :], fullDataSet[wellNum, sensorNum, axisNum, :], label=f'Sensor {sensorNum + 1} Axis {axisMap[axisNum]} Set')
            #axs[row, col].plot(fullTimestampsOffsetCompensated[wellNum, sensorNum, :], fullDataReset[wellNum, sensorNum, axisNum, :], label=f'Sensor {sensorNum + 1} Axis {axisMap[axisNum]} Reset')
            axs[row, col].plot(fullTimestampsOffsetCompensated[wellNum, sensorNum, :], fullDataOffsetCompensated[wellNum, sensorNum, axisNum, :], label=f'Sensor {sensorNum + 1} Axis {axisMap[axisNum]} Comp')
    axs[row, col].set_title(f'Well {wellMap[wellNum]}', fontsize = 60)
    axs[row, col].set_xlabel('Time (sec)', fontsize = 30)
    axs[row, col].set_ylabel('Magnitude (mT)', fontsize = 20)
    axs[row, col].tick_params(which = 'both', labelsize = 20)
    axs[row, col].grid(which='both')
    axs[row, col].legend(fontsize = 20)
#%% 
fig, axs = plt.subplots(4, 6, figsize=(100, 100))
for wellNum in range(numWells):
    row = int(wellNum / 6)
    col = int(wellNum % 6)
    # fig, axs = plt.subplots(3, figsize=(10, 30))
    # fig, axs = plt.subplots(3, 3, figsize=(30, 30))
    for (sensorNum, axisNum), status in np.ndenumerate(config[wellNum]):
        if status:
            #axs[row, col].plot(fullTimestampsOffsetCompensated[wellNum, sensorNum, :], fullDataSet[wellNum, sensorNum, axisNum, :], label=f'Sensor {sensorNum + 1} Axis {axisMap[axisNum]} Set')
            #axs[row, col].plot(fullTimestampsOffsetCompensated[wellNum, sensorNum, :], fullDataReset[wellNum, sensorNum, axisNum, :], label=f'Sensor {sensorNum + 1} Axis {axisMap[axisNum]} Reset')
            axs[row, col].plot(fullTimestampsOffsetCompensated[wellNum, sensorNum, :], fullDataOffsetCompensated[wellNum, sensorNum, axisNum, :], label=f'Sensor {sensorNum + 1} Axis {axisMap[axisNum]} Comp')
    axs[row, col].set_title(f'Well {wellMap[wellNum]}', fontsize = 60)
    axs[row, col].set_xlabel('Time (sec)', fontsize = 30)
    axs[row, col].set_ylabel('Magnitude (mT)', fontsize = 20)
    axs[row, col].tick_params(which = 'both', labelsize = 20)
    axs[row, col].grid(which='both')
    axs[row, col].legend(fontsize = 20)