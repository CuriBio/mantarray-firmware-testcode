import os
import h5py
import numpy as np
import matplotlib.pyplot as plt
from scipy import fft
from scipy import signal as sig
from pathlib import Path
from pandas import DataFrame as df
from tabulate import tabulate
from scipy.signal import butter, lfilter, freqz
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
            fullData[wellNum, sensorNum, axisNum] = (rawData[sensorNum * numSensors + axisNum].astype('float64') - memsicCenterOffset) * memsicFullScale / memsicMSB * gauss2MilliTesla

    wellNum+=1
    
#%% Importing calibration data
os.chdir(targetDataPath)
wellNum = 0
fullTimestamps = None
fullData = None

for file in os.listdir(targetDataPath):
    if file.endswith('.h5') and file.startswith('Calibration'):
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
                fullData[wellNum, sensorNum, axisNum] = (rawData[sensorNum * numSensors + axisNum].astype('float64') - memsicCenterOffset) * memsicFullScale / memsicMSB * gauss2MilliTesla
    
        wellNum+=1

#%%
def butter_lowpass(cutoff, fs, order=5):
    nyq = 0.5 * fs
    normal_cutoff = cutoff / nyq
    b, a = butter(order, normal_cutoff, btype='low', analog=False)
    return b, a

def butter_lowpass_filter(data, cutoff, fs, order=5):
    b, a = butter_lowpass(cutoff, fs, order=order)
    y = lfilter(b, a, data)
    return y

order = 4
fs = 100.0       # sample rate, Hz
cutoff = 30  # desired cutoff frequency of the filter, Hz

# Get the filter coefficients so we can check its frequency response.
b, a = butter_lowpass(cutoff, fs, order)
fullData = butter_lowpass_filter(fullData, cutoff, fs, order)

#%%
w, h = freqz(b, a, worN=8000)
plt.subplots(1, 1, figsize=(10, 5))
plt.plot(0.5*fs*w/np.pi, np.abs(h))
plt.xlim(0, 0.5*fs)
plt.title("4th Order Butterworth Filter Frequency Response with 30 Hz Cutoff", fontsize = 15)
plt.xlabel('Frequency [Hz]', fontsize = 15)
plt.tick_params(which = 'major', labelsize = 12)
plt.minorticks_on()
plt.grid(which='major', linewidth=1.5)
plt.grid(which='minor', linewidth=.5)

#%%
fig, axs = plt.subplots(4, 6, figsize=(100, 100), sharey=True)
# fig, axs = plt.subplots(4, 6, figsize=(100, 100))
for wellNum in range(numWells):
    row = int(wellNum / 6)
    col = int(wellNum % 6)
    for sensorNum in range(numSensors):
        for axisNum in range(numAxes):
            axs[row, col].plot(fullTimestamps[wellNum, sensorNum, :-1], fullData[wellNum, sensorNum, axisNum, :-1] * 1000, label=f'Sensor {sensorNum + 1} Axis {axisMap[axisNum]}')
    # axs[row, col].plot(fullTimestamps[wellNum, 0, :-1], fullData[wellNum, 0, 2, :-1] * 1000, label=f'Sensor {sensorNum + 1} Axis {axisMap[axisNum]}')
    axs[row, col].set_title(f'Well {wellMap[wellNum]}', fontsize = 60)
    axs[row, col].set_xlabel('Time (sec)', fontsize = 30)
    axs[row, col].set_ylabel('Magnitude (uT)', fontsize = 20)
    axs[row, col].tick_params(which = 'major', labelsize = 20)
    axs[row, col].minorticks_on()
    axs[row, col].grid(which='major', linewidth=1.5)
    axs[row, col].grid(which='minor', linewidth=.5)
    axs[row, col].legend(fontsize = 20)
    
fig.savefig(f"{targetPlotsFolderName}\{targetDataFolderName}_transient", bbox_inches = 'tight')

#%% IF YOU ARE DOING FREQUENCY ANALYSIS transform the timestamp array into a linear array
# timediff = np.mean(np.diff(fullTimestamps[0,0]))
# bar, timediffLinspace = np.linspace(fullTimestamps[0,0,0], fullTimestamps[0,0,-1], numSamples, retstep=True)
# print("They are the same")
fullTimestampsLinear, timediffLinspace = np.linspace(fullTimestamps[:,:,0], fullTimestamps[:,:,-1], numSamples, retstep=True, axis = 2)

#%% Simple PSD plotting function
fig, axs = plt.subplots(4, 6, figsize=(100, 100))
RMSNoiseMatrix = np.zeros((24,3,3))
for wellNum in range(numWells):
    row = int(wellNum / 6)
    col = int(wellNum % 6)
    for sensorNum in range(numSensors):
        for axisNum in range(numAxes):
            PSDFrequencies, PSDValues = sig.periodogram(fullData[wellNum, sensorNum, axisNum], 1//timediffLinspace[wellNum, sensorNum], scaling = 'density')
            axs[row, col].semilogy(PSDFrequencies[1:-1], np.sqrt(PSDValues)[1:-1] * 1e6, label=f'Sensor {sensorNum + 1} Axis {axisMap[axisNum]}')
            PSDFrequencies, PSDValues = sig.periodogram(fullData[wellNum, sensorNum, axisNum], 1//timediffLinspace[wellNum, sensorNum], scaling = 'spectrum')
            RMSNoiseMatrix[wellNum, sensorNum, axisNum] = np.sqrt(np.sum(PSDValues[1:])) * 1e6
    axs[row, col].set_title(f'Well {wellMap[wellNum]}', fontsize = 60)
    axs[row, col].set_xlabel('Frequency (Hz)', fontsize = 30)
    axs[row, col].set_ylabel(r"Power Spectral Density $\left(\frac{nT}{\sqrt{Hz}}\right)$", fontsize = 20)
    axs[row, col].tick_params(which = 'both', labelsize = 20)
    axs[row, col].grid(which='both')
    axs[row, col].legend(fontsize = 20)
    print(f'Well {wellNum} completed')
    
fig.savefig(f"{targetPlotsFolderName}\{targetDataFolderName}__PSD", bbox_inches = 'tight')

def CreateFancyDataFrame(thisData, floatNums = False):
    noiseMetricsAsDFList = []
    for wellNum in range(numWells):
        sensorList = []
        for sensorNum in range(numSensors):
            thisSensorStats = thisData[wellNum, sensorNum]
            if floatNums:
                sensorList.append(np.array2string(thisSensorStats, formatter={'float_kind':lambda x: "%.3f,"%x}))
            else:
                sensorList.append(np.array2string(thisSensorStats, formatter={'float_kind':lambda x: "%.3e,"%x}))
        noiseMetricsAsDFList.append(sensorList)
        
    noiseDataFrame = df(noiseMetricsAsDFList, range(1,25), ('Sensor 1', 'Sensor 2', 'Sensor 3'))
    print(tabulate(noiseDataFrame, headers = 'keys', tablefmt = 'psql', stralign = 'center'))
    return noiseDataFrame

shapedData = CreateFancyDataFrame(RMSNoiseMatrix, floatNums = True)
logFile = open(f"{targetPlotsFolderName}\{targetDataFolderName}__power_spectrum_RMS.txt", 'w')
logFile.write('RMS Measurements in nT measured from power spectrum of frequency response \nDatasheet states an RMS of .4 mG or 40 nT\n')
logFile.write(str(tabulate(shapedData, headers = 'keys', tablefmt = 'psql', stralign = 'center')))
logFile.close() 

#%% Simple FFT plotting function
fourier_B = 2.0 / numSamples * np.abs(fft.rfft(fullData, axis=3))           #Should be the same length as the spectrum array
fig, axs = plt.subplots(4, 6, figsize=(100, 100))
for wellNum in range(numWells):
    row = int(wellNum / 6)
    col = int(wellNum % 6)
    for sensorNum in range(numSensors):
        for axisNum in range(numAxes):
            spectrum_f = fft.rfftfreq(numSamples, d=(timediffLinspace[wellNum, sensorNum]))
            axs[row, col].semilogy(spectrum_f[1:], fourier_B[wellNum, sensorNum, axisNum, 1:], label=f'Sensor {sensorNum + 1} Axis {axisMap[axisNum]}')
    axs[row, col].set_title(f'Well {wellMap[wellNum]}', fontsize = 60)
    axs[row, col].set_xlabel('Frequency (Hz)', fontsize = 30)
    axs[row, col].set_ylabel('Magnitude (mT)', fontsize = 20)
    axs[row, col].tick_params(which = 'both', labelsize = 20)
    axs[row, col].grid(which='both')
    axs[row, col].legend(fontsize = 20)
    
fig.savefig(f"{targetPlotsFolderName}\{targetDataFolderName}__FFT", bbox_inches = 'tight')

#%%
begin = 5700
end = 6200
fig, axs = plt.subplots(figsize=(10, 10))
axs.plot(fullTimestamps[4, 1, begin:end], fullData[0, 0, 0, begin:end] * 1000, label=f'Sensor {2} Axis {axisMap[0]}')
axs.set_title(f'Well {wellMap[0]}', fontsize = 60)
axs.set_xlabel('Time (sec)', fontsize = 30)
axs.set_ylabel('Magnitude (uT)', fontsize = 20)
axs.tick_params(which = 'major', labelsize = 20)
axs.minorticks_on()
axs.grid(which='major', linewidth=1.5)
axs.grid(which='minor', linewidth=.5)
axs.legend(fontsize = 20)   

fig.savefig(f"{targetPlotsFolderName}\{targetDataFolderName}_transient", bbox_inches = 'tight')        