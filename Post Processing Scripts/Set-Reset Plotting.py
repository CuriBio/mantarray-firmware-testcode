#%% Import Libraries
import numpy as np
import matplotlib.pyplot as plt
from scipy import fft
from scipy import signal as sig
from pandas import DataFrame as df
from tabulate import tabulate


#%%
dateName = "9-2-2021_0-22-48_data"
fileName = f'{dateName}.txt'
numWells = 24
numSensors = 3
numAxes = 3
axisMap = ['X', 'Y', 'Z']
wellMap = ['A1', 'A2', 'A3', 'A4', 'A5', 'A6', 
           'B1', 'B2', 'B3', 'B4', 'B5', 'B6', 
           'C1', 'C2', 'C3', 'C4', 'C5', 'C6', 
           'D1', 'D2', 'D3', 'D4', 'D5', 'D6']
memsicCenterOffset = 2**15
memsicMSB = 2**16
memsicFullScale = 8
gauss2MilliTesla = .1

totDataPoints = numWells * numSensors * numAxes

config = np.loadtxt(fileName, max_rows = 1, delimiter = ', ').reshape((numWells,numSensors,numAxes))

activeSensors = np.any(config, axis = 1)
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
        
#%%
fullDataSet = fullData[:,:,:,0::2]
fullDataReset = fullData[:,:,:,1::2]
fullDataOffsetCompensated = (fullDataSet + fullDataReset)/2
fullTimestampsOffsetCompensated = fullTimestamps[:,:,0::2]

#%%
fig, axs = plt.subplots(4, 6, figsize=(100, 100))
for wellNum in range(numWells):
    row = int(wellNum / 6)
    col = int(wellNum % 6)
    # fig, axs = plt.subplots(3, figsize=(10, 30))
    # fig, axs = plt.subplots(3, 3, figsize=(30, 30))
    for (sensorNum, axisNum), status in np.ndenumerate(config[wellNum]):
        axs[row, col].plot(fullTimestampsOffsetCompensated[wellNum, sensorNum, :], fullDataSet[wellNum, sensorNum, axisNum, :], label=f'Sensor {sensorNum + 1} Axis {axisMap[axisNum]} Set')
        axs[row, col].plot(fullTimestampsOffsetCompensated[wellNum, sensorNum, :], fullDataReset[wellNum, sensorNum, axisNum, :], label=f'Sensor {sensorNum + 1} Axis {axisMap[axisNum]} Reset')
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