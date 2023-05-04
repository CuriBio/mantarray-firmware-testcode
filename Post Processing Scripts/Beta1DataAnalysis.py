import os
import h5py
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy import fft
from scipy import signal as sig
from pathlib import Path
from pandas import DataFrame as df
from tabulate import tabulate
from scipy.signal import butter, lfilter, freqz
from tkinter import Tk
from tkinter.filedialog import askdirectory 

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
memsicCenterOffset = 2**15
memsicMSB = 2**16
memsicFullScale = 16
gauss2MilliTesla = .1

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

#%% Importing normal data
os.chdir(targetDataPath)
wellNum = 0
fullTimestamps = None
fullData = None

maxSize = 0
for file in os.listdir(targetDataPath):
    if not file.endswith('.h5') or file.startswith('Calibration'):
        continue
    wellID = file[file.rfind('_')+1:-3]
    if wellMap[wellNum] != wellID or wellID == 'C3':
        print("Error!!")
        wellNum+=1
        continue
    dataFile =  h5py.File(file, 'r')      
    rawData = np.array(dataFile[dataName])
    thisSize = rawData.size
    if thisSize > maxSize:
        maxSize = thisSize
    wellNum+=1

fullData = np.zeros((numWells, maxSize))
wellNum = 0

for file in os.listdir(targetDataPath):
    if not file.endswith('.h5') or file.startswith('Calibration'):
        continue
    wellID = file[file.rfind('_')+1:-3]
    if wellMap[wellNum] != wellID or wellID == 'C3':
        print("Error!!")
        wellNum+=1
        continue
    
    dataFile =  h5py.File(file, 'r')      
    rawData = np.array(dataFile[dataName])
    if rawData.size != maxSize:
        rawData = np.pad(rawData, (0,maxSize - rawData.size), 'edge')

    fullData[wellNum] = 1e3 * ((2.5/2**16 * rawData.astype('float64')) / (12.2 * 100 * 4))

    wellNum+=1
    
#%%
fig, axs = plt.subplots(4, 6, figsize=(100, 100))
for wellNum in range(numWells):
    row = int(wellNum / 6)
    col = int(wellNum % 6)
    axs[row, col].plot(fullData[wellNum, :10000])
    axs[row, col].set_title(f'Well {wellMap[wellNum]}', fontsize = 60)
    axs[row, col].set_xlabel('Time (sec)', fontsize = 30)
    axs[row, col].set_ylabel('Magnitude (uT)', fontsize = 20)
    axs[row, col].tick_params(which = 'major', labelsize = 20)
    axs[row, col].minorticks_on()
    axs[row, col].grid(which='major', linewidth=1.5)
    axs[row, col].grid(which='minor', linewidth=.5)
    
fig.savefig(f"{targetPlotsFolderName}\{targetDataFolderName}_time", bbox_inches = 'tight')