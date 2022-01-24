import os
import h5py
import numpy as np
import matplotlib.pyplot as plt
from scipy import fft
from scipy import signal as sig
from pathlib import Path

from tkinter import Tk
from tkinter.filedialog import askdirectory 

axisMap = ['X', 'Y', 'Z']
wellMap = ['A1', 'A2', 'A3', 'A4', 'A5', 'A6', 
           'B1', 'B2', 'B3', 'B4', 'B5', 'B6', 
           'C1', 'C2', 'C3', 'C4', 'C5', 'C6', 
           'D1', 'D2', 'D3', 'D4', 'D5', 'D6']

offsetName = 'time_offsets' #[3,N]
indexName = 'time_indices' #[N]
dataName = 'tissue_sensor_readings' #[9,N]

numWells = 24
numSensors = 3
numAxes = 3

#%%
root = Tk()
root.wm_attributes('-topmost', 1)
targetDataDirectory = askdirectory ()
targetDataPath = Path(targetDataDirectory)
root.destroy()

targetDataFolderName = targetDataPath.name
targetPlotsBasePath = f'{targetDataPath.parent.parent}/plots'
targetPlotsFolderName = f'{targetPlotsBasePath}/{targetDataFolderName}_plots'

if (os.path.exists(targetPlotsBasePath) == False): 
    os.mkdir(targetPlotsBasePath)
    
if (os.path.exists(targetPlotsFolderName) == False): 
    os.mkdir(targetPlotsFolderName)

#%%
os.chdir(targetDataPath)
wellNum = 0
fullTimestamps = None
fullData = None

for file in os.listdir(targetDataPath):
    if not file.endswith('.h5') or file.startswith('Calibration'):
        continue
    wellID = file[file.rfind('_')+1:-3]
    if wellMap[wellNum] != wellID:
        print("Error!!")
    
    dataFile =  h5py.File(file, 'r')      
    rawTimeOffsets = np.array(dataFile[offsetName])
    rawTimeIndices = np.array(dataFile[indexName])
    rawData = np.array(dataFile[dataName])
    
    if (wellNum == 0):
        numSamples = rawTimeIndices.size
        fullTimestamps = np.zeros((numWells, numSensors, numSamples))
        fullData = np.zeros((numWells, numSensors, numAxes, numSamples))

    for sensorNum in range(numSensors):
        fullTimestamps[wellNum, sensorNum] = (rawTimeIndices + rawTimeOffsets[sensorNum]) / 1e6
        for axisNum in range(numAxes):
            fullData[wellNum, sensorNum, axisNum] = rawData[sensorNum * numSensors + axisNum]

    wellNum+=1


#%%
fig, axs = plt.subplots(4, 6, figsize=(100, 100))
for wellNum in range(numWells):
    row = int(wellNum / 6)
    col = int(wellNum % 6)
    for sensorNum in range(numSensors):
        for axisNum in range(numAxes):
            axs[row, col].plot(fullTimestamps[wellNum, sensorNum, :-1], fullData[wellNum, sensorNum, axisNum, :-1] * 1000, label=f'Sensor {sensorNum + 1} Axis {axisMap[axisNum]}')
    axs[row, col].set_title(f'Well {wellMap[wellNum]}', fontsize = 60)
    axs[row, col].set_xlabel('Time (sec)', fontsize = 30)
    axs[row, col].set_ylabel('Magnitude (uT)', fontsize = 20)
    axs[row, col].tick_params(which = 'major', labelsize = 20)
    axs[row, col].minorticks_on()
    axs[row, col].grid(which='major', linewidth=1.5)
    axs[row, col].grid(which='minor', linewidth=.5)
    axs[row, col].legend(fontsize = 20)
    
fig.savefig(f"{targetPlotsFolderName}\{targetDataFolderName}_transient", bbox_inches = 'tight')
            