#%% Import Libraries
import numpy as np
import matplotlib.pyplot as plt
from scipy import fft
from scipy import signal as sig
from pandas import DataFrame as df
from tabulate import tabulate
from tkinter import Tk
from tkinter.filedialog import askopenfilename
from pathlib import Path

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

config = np.loadtxt(fileName, max_rows = 1, delimiter = ', ').reshape((numWells,numSensors,numAxes))

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
    fullData[:,:,:,outlier] = fullData[:,:,:,outlier-1]

abberantArray = np.any(np.any((fullData==-.8), axis = 3), axis = 1)
for (wellNum, sensorNum), isBroken in np.ndenumerate(abberantArray):
    if isBroken:
        print (f'Well {wellMap[wellNum]} sensor {sensorNum+1} has aberrant data, setting all aberrant data points to 0.  If you are running a frequency analysis, I recommend recapturing the data')
fullData[fullData==-.8] = 0

#%% Plot the subsequent transient after the broken and abberant sample compensations
fig, axs = plt.subplots(4, 6, figsize=(100, 100))
for wellNum in range(numWells):
    row = int(wellNum / 6)
    col = int(wellNum % 6)
    for (sensorNum, axisNum), status in np.ndenumerate(config[wellNum]):
        if status:
            axs[row, col].plot(fullTimestamps[wellNum, sensorNum, :-1], fullData[wellNum, sensorNum, axisNum, :-1] * 1000, label=f'Sensor {sensorNum + 1} Axis {axisMap[axisNum]}')
    axs[row, col].set_title(f'Well {wellMap[wellNum]}', fontsize = 60)
    axs[row, col].set_xlabel('Time (sec)', fontsize = 30)
    axs[row, col].set_ylabel('Magnitude (uT)', fontsize = 20)
    axs[row, col].tick_params(which = 'major', labelsize = 20)
    axs[row, col].minorticks_on()
    axs[row, col].grid(which='major', linewidth=1.5)
    axs[row, col].grid(which='minor', linewidth=.5)
    axs[row, col].legend(fontsize = 20)
    
fig.savefig(f"{filePath.parent.parent / 'plots'}\{dateName}_transient", bbox_inches = 'tight')
        
#%% Quick and dirty noise metrics generator ***NOTE*** peak-to-peak is accurate, RMS is guesstimated (use integal of PSD for more accurate results), and I'm not sure if I'm doing SNR right 
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
    

logFile = open(f"{filePath.parent.parent / 'plots'}\{dateName}_noise_metrics.txt", 'w')

print("Peak-to-peak data")
fullDataMaxes = np.max(fullData, axis = 3)
fullDataMins = np.min(fullData, axis = 3)
fullDataPtP = (fullDataMaxes - fullDataMins) * 1000
fullDataPtPFrame = CreateFancyDataFrame(fullDataPtP, floatNums = True)
logFile.write("Peak-to-peak data (uT)\n")
logFile.write(str(tabulate(fullDataPtPFrame, headers = 'keys', tablefmt = 'psql', stralign = 'center')))

print("RMS data")
fullDataRMS = fullDataPtP / 6.6 * 1000
fullDataRMSFrame = CreateFancyDataFrame(fullDataRMS, floatNums = True)
logFile.write("\nRMS data (estimate) (nT)\n")
logFile.write(str(tabulate(fullDataRMSFrame, headers = 'keys', tablefmt = 'psql', stralign = 'center')))

print("SNR data")
fullDataMean = np.mean(fullData, axis = 3)
fullDataSTD = np.std(fullData, axis=3)
fullDataSNR = np.log10(np.abs(np.where(fullDataSTD == 0, 0, fullDataMean/fullDataSTD)))
fullDataSNRFrame = CreateFancyDataFrame(fullDataSNR, floatNums = True)
logFile.write("\nSNR data (untested) (dB)\n")
logFile.write(str(tabulate(fullDataSNRFrame, headers = 'keys', tablefmt = 'psql', stralign = 'center')))

logFile.close()

#%% IF YOU ARE DOING FREQUENCY ANALYSIS transform the timestamp array into a linear array
# timediff = np.mean(np.diff(fullTimestamps[0,0]))
# bar, timediffLinspace = np.linspace(fullTimestamps[0,0,0], fullTimestamps[0,0,-1], numSamples, retstep=True)
# print("They are the same")
fullTimestampsLinear, timediffLinspace = np.linspace(fullTimestamps[:,:,0], fullTimestamps[:,:,-1], numSamples, retstep=True, axis = 2)
        
#%% Simple FFT plotting function
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
    
fig.savefig(f"{filePath.parent.parent / 'plots'}\{dateName}_FFT", bbox_inches = 'tight')
    
#%% Simple PSD plotting function
fig, axs = plt.subplots(4, 6, figsize=(100, 100))
RMSNoiseMatrix = np.zeros((24,3,3))
for wellNum in range(numWells):
    row = int(wellNum / 6)
    col = int(wellNum % 6)
    for (sensorNum, axisNum), status in np.ndenumerate(config[wellNum]):
        if status:
            PSDFrequencies, PSDValues = sig.periodogram(fullData[wellNum, sensorNum, axisNum], 1//timediffLinspace[wellNum, sensorNum], scaling = 'density')
            axs[row, col].semilogy(PSDFrequencies[1:], np.sqrt(PSDValues)[1:] * 1e6, label=f'Sensor {sensorNum + 1} Axis {axisMap[axisNum]}')
            PSDFrequencies, PSDValues = sig.periodogram(fullData[wellNum, sensorNum, axisNum], 1//timediffLinspace[wellNum, sensorNum], scaling = 'spectrum')
            RMSNoiseMatrix[wellNum, sensorNum, axisNum] = np.sqrt(np.sum(PSDValues[1:])) * 1e6
    axs[row, col].set_title(f'Well {wellMap[wellNum]}', fontsize = 60)
    axs[row, col].set_xlabel('Frequency (Hz)', fontsize = 30)
    axs[row, col].set_ylabel(r"Power Spectral Density $\left(\frac{nT}{\sqrt{Hz}}\right)$", fontsize = 20)
    axs[row, col].tick_params(which = 'both', labelsize = 20)
    axs[row, col].grid(which='both')
    axs[row, col].legend(fontsize = 20)
    #print(f'Well {wellNum} completed')
    
fig.savefig(f"{filePath.parent.parent / 'plots'}\{dateName}_PSD", bbox_inches = 'tight')

shapedData = CreateFancyDataFrame(RMSNoiseMatrix, floatNums = True)
logFile = open(f"{filePath.parent.parent / 'plots'}\{dateName}_power_spectrum_RMS.txt", 'w')
logFile.write('RMS Measurements in nT measured from power spectrum of frequency response \nDatasheet states an RMS of .4 mG or 40 nT\n')
logFile.write(str(tabulate(shapedData, headers = 'keys', tablefmt = 'psql', stralign = 'center')))
logFile.close()

#%% OPTIONAL If you would like to center all the data around a 0 mean
meanMatrix = np.mean(fullData, axis = 3)
fullData = np.transpose(np.transpose(fullData, (3,0,1,2)) - meanMatrix, (1,2,3,0))

#%% Save certain potions of data arrays to separate file for visual inspection
#np.savetxt('test.txt', fullData.reshape(-1, fullData.shape[-1])[:,5000:6000].transpose(), fmt='%.3f')
#np.savetxt('testTime.txt', fullTimestamps.reshape(-1, fullTimestamps.shape[-1])[:,90000:100000].transpose(), fmt='%.5f')