#%% Import Libraries
import numpy as np
import matplotlib.pyplot as plt
from scipy import fft
from scipy import signal as sig
from pandas import DataFrame as df
from tabulate import tabulate


#%%
dateName = "Dynamic Capture - One Big Magnet - Step Motion - Magnetic Data"
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
def CreateFancyDataFrame(thisData, floatNums = False):
    noiseMetricsAsDFList = []
    for wellNum in range(numWells):
        sensorList = []
        for sensorNum in range(numSensors):
            thisSensorStats = thisData[wellNum, sensorNum]
            if floatNums:
                sensorList.append(np.array2string(thisSensorStats, formatter={'float_kind':lambda x: "%.2f,"%x}))
            else:
                sensorList.append(np.array2string(thisSensorStats, formatter={'float_kind':lambda x: "%.2e,"%x}))
        noiseMetricsAsDFList.append(sensorList)
        
    noiseDataFrame = df(noiseMetricsAsDFList, range(1,25), ('Sensor 1', 'Sensor 2', 'Sensor 3'))
    print(tabulate(noiseDataFrame, headers = 'keys', tablefmt = 'psql', stralign = 'center'))
    return noiseDataFrame
    
fullDataMaxes = np.max(fullData, axis = 3)
fullDataMins = np.min(fullData, axis = 3)
fullDataPtP = fullDataMaxes - fullDataMins
print("Peak-to-peak data")
CreateFancyDataFrame(fullDataPtP)
fullDataRMS = fullDataPtP / 6.6
print("RMS data")
CreateFancyDataFrame(fullDataRMS)

fullDataMean = np.mean(fullData, axis = 3)
fullDataSTD = np.std(fullData, axis=3)
fullDataSNR = np.log10(np.abs(np.where(fullDataSTD == 0, 0, fullDataMean/fullDataSTD)))
print("SNR data")
CreateFancyDataFrame(fullDataSNR, True)
        
#%%
meanMatrix = np.mean(fullData, axis = 3)
fullData = np.transpose(np.transpose(fullData, (3,0,1,2)) - meanMatrix, (1,2,3,0))

#%%
# timediff = np.mean(np.diff(fullTimestamps[0,0]))
# bar, timediffLinspace = np.linspace(fullTimestamps[0,0,0], fullTimestamps[0,0,-1], numSamples, retstep=True)
# print("They are the same")
fullTimestampsLinear, timediffLinspace = np.linspace(fullTimestamps[:,:,0], fullTimestamps[:,:,-1], numSamples, retstep=True, axis = 2)
        
#%%
fourier_B = 2.0 / numSamples * np.abs(fft.rfft(fullData, axis=3))           #Should be the same length as the spectrum array
fig, axs = plt.subplots(4, 6, figsize=(100, 100))
for wellNum in range(numWells):
    row = int(wellNum / 6)
    col = int(wellNum % 6)
    for (sensorNum, axisNum), status in np.ndenumerate(config[wellNum]):
        if status:
            spectrum_f = fft.rfftfreq(numSamples, d=(timediffLinspace[wellNum, sensorNum]))
            axs[row, col].semilogy(spectrum_f[1:], fourier_B[wellNum, sensorNum, axisNum, 1:], label=f'Sensor {sensorNum + 1} Axis {axisMap[axisNum]}')
    axs[row, col].set_title(f'Well {wellMap[wellNum]}', fontsize = 60)
    axs[row, col].set_xlabel('Frequency (Hz)', fontsize = 30)
    axs[row, col].set_ylabel('Magnitude (mT)', fontsize = 20)
    axs[row, col].tick_params(which = 'both', labelsize = 20)
    axs[row, col].grid(which='both')
    axs[row, col].legend(fontsize = 20)
    
#%%
fig, axs = plt.subplots(4, 6, figsize=(100, 100))
RMSNoiseMatrix = np.zeros((24,3,3))
for wellNum in range(numWells):
    row = int(wellNum / 6)
    col = int(wellNum % 6)
    for (sensorNum, axisNum), status in np.ndenumerate(config[wellNum]):
        if status:
            PSDFrequencies, PSDValues = sig.periodogram(fullData[wellNum, sensorNum, axisNum], 1//timediffLinspace[wellNum, sensorNum])
            axs[row, col].semilogy(PSDFrequencies[1:], np.sqrt(PSDValues)[1:] * 1e6, label=f'Sensor {sensorNum + 1} Axis {axisMap[axisNum]}')
            RMSNoiseMatrix[wellNum, sensorNum, axisNum] = np.sqrt(np.sum(PSDValues)) * 1e6
    axs[row, col].set_title(f'Well {wellMap[wellNum]}', fontsize = 60)
    axs[row, col].set_xlabel('Frequency (Hz)', fontsize = 30)
    axs[row, col].set_ylabel(r"Noise Spectrum $\left(\frac{nT}{\sqrt{Hz}}\right)$", fontsize = 20)
    axs[row, col].tick_params(which = 'both', labelsize = 20)
    axs[row, col].grid(which='both')
    axs[row, col].legend(fontsize = 20)
    print(f'Well {wellNum} completed')
    
shapedData = CreateFancyDataFrame(RMSNoiseMatrix, floatNums = True)
logFile = open(f'./{dateName}_RMS.txt', 'w')
logFile.write('RMS Measurements in nT \nDatasheet states an RMS of .4 mG or 40 nT\n')
logFile.write(str(tabulate(shapedData, headers = 'keys', tablefmt = 'psql', stralign = 'center')))
logFile.close()

#%%
fig, axs = plt.subplots(4, 6, figsize=(100, 100))
for wellNum in range(numWells):
    row = int(wellNum / 6)
    col = int(wellNum % 6)
    # fig, axs = plt.subplots(3, figsize=(10, 30))
    # fig, axs = plt.subplots(3, 3, figsize=(30, 30))
    for (sensorNum, axisNum), status in np.ndenumerate(config[wellNum]):
        if status:
            axs[row, col].plot(fullTimestamps[wellNum, sensorNum, :], fullData[wellNum, sensorNum, axisNum, :], label=f'Sensor {sensorNum + 1} Axis {axisMap[axisNum]}')
    axs[row, col].set_title(f'Well {wellMap[wellNum]}', fontsize = 60)
    axs[row, col].set_xlabel('Time (sec)', fontsize = 30)
    axs[row, col].set_ylabel('Magnitude (mT)', fontsize = 20)
    axs[row, col].tick_params(which = 'both', labelsize = 20)
    axs[row, col].grid(which='both')
    axs[row, col].legend(fontsize = 20)
