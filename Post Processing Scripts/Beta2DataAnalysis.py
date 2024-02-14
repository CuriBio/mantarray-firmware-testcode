#%% Import Libraries
import os
import numpy as np
import matplotlib.pyplot as plt
from scipy import fft
from scipy import signal as sig
from pandas import DataFrame as df
from tabulate import tabulate
from tkinter import Tk
from tkinter.filedialog import askopenfilename, askdirectory
from pathlib import Path
from scipy.signal import butter, lfilter, freqz

numWells = 24
numSensors = 3
numAxes = 3
axisMap = ['X', 'Y', 'Z']
wellMap = ['A1', 'A2', 'A3', 'A4', 'A5', 'A6', 
           'B1', 'B2', 'B3', 'B4', 'B5', 'B6', 
           'C1', 'C2', 'C3', 'C4', 'C5', 'C6', 
           'D1', 'D2', 'D3', 'D4', 'D5', 'D6']
# sensorReMap = [0, 4, 8, 12, 16, 20,
#                1, 5, 9, 13, 17, 21,
#                2, 6, 10, 14, 18, 22,
#                3, 7, 11, 15, 19, 23]
sensorReMap = [3, 7, 11, 15, 19, 23,
               2, 6, 10, 14, 18, 22,
               1, 5, 9, 13, 17, 21,
               0, 4, 8, 12, 16, 20]
memsicCenterOffset = 2**15
temperatureOffset = 75
memsicMSB = 2**16
temperatureMSB = 2**8
memsicFullScale = 16
temperatureFullScale = 200
gauss2MilliTesla = .1
totDataPoints = numWells * numSensors * numAxes

#%% Load data
root = Tk()
root.wm_attributes('-topmost', 1)
fileName = askopenfilename()
root.destroy()

filePath = Path(fileName)
dateName = Path(fileName).stem[:-5]

config = np.genfromtxt(fileName, max_rows = 1, delimiter = ', ').reshape((numWells,numSensors,numAxes))

activeSensors = np.any(config, axis = 2)
spacerCounter = 1
timestampSpacer = [0]
dataSpacer = []
# temperatureSpacer = [0]
for (wellNum, sensorNum), status in np.ndenumerate(activeSensors):
    if status:
        numActiveAxes = np.count_nonzero(config[wellNum,sensorNum])
        for numAxis in range(1, numActiveAxes + 1):
            dataSpacer.append(timestampSpacer[spacerCounter - 1] + numAxis)
        # temperatureSpacer.append(timestampSpacer[spacerCounter - 1] + numActiveAxes + 1)
        # timestampSpacer.append(temperatureSpacer[spacerCounter - 1] + 1)
        timestampSpacer.append(timestampSpacer[spacerCounter - 1] + numActiveAxes + 1)
        spacerCounter+=1
        
timestamps = np.genfromtxt(fileName, skip_header = 1, delimiter = ', ', usecols = tuple(timestampSpacer[:-1])) / 1000000
data = (np.genfromtxt(fileName, skip_header = 1, delimiter = ', ', usecols = tuple(dataSpacer)) - memsicCenterOffset) * memsicFullScale / memsicMSB * gauss2MilliTesla
# temperature = np.loadtxt(fileName, skiprows = 1, delimiter = ', ', usecols = tuple(temperatureSpacer)) * temperatureFullScale / temperatureMSB - temperatureOffset
numSamples = timestamps.shape[0] - 2
fullData = np.zeros((numWells, numSensors, numAxes, numSamples))
fullTimestamps = np.zeros((numWells, numSensors, numSamples))
# fullTemperature = np.zeros((numWells, numSensors, numSamples))

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
		
# temperatureCounter = 0
# for (wellNum, sensorNum), status in np.ndenumerate(activeSensors):
#     if status:
#         fullTemperature[wellNum, sensorNum] = temperature[2:, temperatureCounter]
#         temperatureCounter+=1

#%% Rearrange the channel numbers to correspond to the new well mapping
newFullData = np.zeros((numWells, numSensors, numAxes, numSamples))
newTimestampArray = np.zeros((numWells, numSensors, numSamples))
for wellNum in range(numWells):
    newFullData[wellNum] = fullData[sensorReMap[wellNum]]
    newTimestampArray[wellNum] = fullTimestamps[sensorReMap[wellNum]]
fullData = newFullData
fullTimestamps = newTimestampArray
        
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

order = 6
fs = 100.0       # sample rate, Hz
cutoff = 15  # desired cutoff frequency of the filter, Hz

# Get the filter coefficients so we can check its frequency response.
b, a = butter_lowpass(cutoff, fs, order)
fullData = butter_lowpass_filter(fullData, cutoff, fs, order)

#%%
timestampVerificationArray = np.zeros((24 ,8))
for wellNum in range(numWells):
    for sensorNum in range(numSensors):
        thisData = fullTimestamps[wellNum, sensorNum].astype('uint64')
        for byteNum in range(2):
            byteData = np.right_shift(thisData, (8*byteNum)).astype('uint8')
            separatedByteData = np.unpackbits(byteData).reshape((thisData.shape[0], 8))
            for bitNum in range(8):
                if np.argwhere(separatedByteData[:,bitNum] == 1).shape[0] != 0:
                    timestampVerificationArray[wellNum, bitNum] = 1
                    
dataVerificationArray = np.zeros((24, 3, 8))
for wellNum in range(numWells):
    for sensorNum in range(numSensors):
        for axisNum in range(numAxes):
            thisData = fullData[wellNum, sensorNum, axisNum].astype('uint64')
            for byteNum in range(2):
                byteData = np.right_shift(thisData, (8*byteNum)).astype('uint8')
                separatedByteData = np.unpackbits(byteData).reshape((thisData.shape[0], 8))
                for bitNum in range(8):
                    if np.argwhere(separatedByteData[:,bitNum] == 1).shape[0] != 0:
                        dataVerificationArray[wellNum, sensorNum, bitNum] = 1
                    
#%% Plot the subsequent transient after the broken and abberant sample compensations
fig, axs = plt.subplots(4, 6, figsize=(100, 100))
# referenceAxis = axs[0, 0].twinx()
for wellNum in range(numWells):
    row = int(wellNum / 6)
    col = int(wellNum % 6)
    # rightAxis = axs[row, col].twinx() if wellNum != 0 else referenceAxis
    # rightAxis.get_shared_y_axes().join(rightAxis, referenceAxis)
    
    for sensorNum, axesStatuses in enumerate(config[wellNum]):
        if np.any(axesStatuses):
            for axisNum, status in enumerate(axesStatuses):
                if status:
                    axs[row, col].plot(fullTimestamps[wellNum, sensorNum, 100:-1], fullData[wellNum, sensorNum, axisNum, 100:-1] * 1000, label=f'Sensor {sensorNum + 1} Axis {axisMap[axisNum]}')
            # rightAxis.plot(fullTimestamps[wellNum, sensorNum, :-1], fullTemperature[wellNum, sensorNum, :-1], label = f'Sensor {sensorNum + 1} Temperature', linewidth=7.0, color='red')
    
    axs[row, col].set_title(f'Well {wellMap[wellNum]}', fontsize = 60)
    axs[row, col].set_xlabel('Time (sec)', fontsize = 30)
    axs[row, col].set_ylabel('Magnitude (uT)', fontsize = 20)
    # rightAxis.set_ylabel('Temperature (°C)', fontsize = 20)
    axs[row, col].tick_params(which = 'major', labelsize = 20)
    axs[row, col].minorticks_on()
    axs[row, col].grid(which='major', linewidth=1.5)
    axs[row, col].grid(which='minor', linewidth=.5)
    axs[row, col].legend(fontsize = 20)
    
fig.savefig(f"{filePath.parent.parent / 'plots'}\{dateName}_transient", bbox_inches = 'tight')

#%%
fig, axs = plt.subplots(figsize=(10, 10))
axs.plot(fullTimestamps[0, 0, :100], fullData[0, 0, 0, :100] * 1000, label=f'Sensor 1 Axis {axisMap[0]}')
axs.set_title(f'Well {wellMap[0]}', fontsize = 60)
axs.set_xlabel('Time (sec)', fontsize = 30)
axs.set_ylabel('Magnitude (uT)', fontsize = 20)
axs.tick_params(which = 'major', labelsize = 20)
axs.minorticks_on()
axs.grid(which='major', linewidth=1.5)
axs.grid(which='minor', linewidth=.5)
axs.legend(fontsize = 20)
        
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
    # print(tabulate(noiseDataFrame, headers = 'keys', tablefmt = 'psql', stralign = 'center'))
    return noiseDataFrame
    
#%%
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

#%%
# Plot the frequency response.
w, h = freqz(b, a, worN=8000)
plt.subplot(2, 1, 1)
plt.plot(0.5*fs*w/np.pi, np.abs(h), 'b')
plt.plot(cutoff, 0.5*np.sqrt(2), 'ko')
plt.axvline(cutoff, color='k')
plt.xlim(0, 0.5*fs)
plt.title("Lowpass Filter Frequency Response")
plt.xlabel('Frequency [Hz]')
plt.grid()
        
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
    print(f'Well {wellNum} completed')
    
fig.savefig(f"{filePath.parent.parent / 'plots'}\{dateName}_PSD", bbox_inches = 'tight')

shapedData = CreateFancyDataFrame(RMSNoiseMatrix, floatNums = True)
logFile = open(f"{filePath.parent.parent / 'plots'}\{dateName}_power_spectrum_RMS.txt", 'w')
logFile.write('RMS Measurements in nT measured from power spectrum of frequency response \nDatasheet states an RMS of .4 mG or 40 nT\n')
logFile.write(str(tabulate(shapedData, headers = 'keys', tablefmt = 'psql', stralign = 'center')))
logFile.close()

# RMS_data[f'{dateName}'] = RMSNoiseMatrix

#%% OPTIONAL If you would like to center all the data around a 0 mean
meanMatrix = np.mean(fullData, axis = 3)
fullData = np.transpose(np.transpose(fullData, (3,0,1,2)) - meanMatrix, (1,2,3,0))

#%% Save certain potions of data arrays to separate file for visual inspection
#np.savetxt('test.txt', fullData.reshape(-1, fullData.shape[-1])[:,5000:6000].transpose(), fmt='%.3f')
#np.savetxt('testTime.txt', fullTimestamps.reshape(-1, fullTimestamps.shape[-1])[:,90000:100000].transpose(), fmt='%.5f')

#%%
# fig, axs = plt.subplots(4, 6, figsize=(100, 100))
fig, axs = plt.subplots(2,2, figsize=(20, 20))
labels = sorted(RMS_data.keys())
for wellNum in range(1):
    row = int(wellNum / 6)
    col = int(wellNum % 6)
    np.zeros(())
    for (sensorNum, axisNum), status in np.ndenumerate(config[wellNum]):
        if status:
            thisValues = []
            for thisKey in enumerate(sorted(RMS_data.keys())):
                thisValues.append(RMS_data[thisKey][wellNum, sensorNum, axisNum])
            axs[row, col].bar(labels, thisValues)
    # axs[row, col].set_title(f'Well {wellMap[wellNum]}', fontsize = 60)
    # axs[row, col].set_xlabel('Frequency (Hz)', fontsize = 30)
    # axs[row, col].set_ylabel(r"Power Spectral Density $\left(\frac{nT}{\sqrt{Hz}}\right)$", fontsize = 20)
    # axs[row, col].tick_params(which = 'both', labelsize = 20)
    # axs[row, col].grid(which='both')
    # axs[row, col].legend(fontsize = 20)
    #print(f'Well {wellNum} completed')
    
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

#%% Processing every data file in a folder
os.chdir(targetDataPath)
fullTimestamps = None
fullData = None

numFiles = len(os.listdir(targetDataPath))
RMSArray = np.zeros((numFiles,numWells,numSensors,numAxes))

for fileNum, fileName in enumerate(os.listdir(targetDataPath)):   
    filePath = Path(f'{targetDataPath}/{fileName}')
    dateName = Path(fileName).stem[:-5]

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
            
    fullTimestampsLinear, timediffLinspace = np.linspace(fullTimestamps[:,:,0], fullTimestamps[:,:,-1], numSamples, retstep=True, axis = 2)

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
        # print(f'Well {wellNum} completed')
        
    fig.savefig(f"{targetPlotsFolderName}\{dateName}_PSD", bbox_inches = 'tight')
    plt.close(fig)

    RMSArray[fileNum + 47] = RMSNoiseMatrix
    shapedData = CreateFancyDataFrame(RMSNoiseMatrix, floatNums = True)
    logFile = open(f"{targetPlotsFolderName}\{dateName}_power_spectrum_RMS.txt", 'w')
    logFile.write('RMS Measurements in nT measured from power spectrum of frequency response \nDatasheet states an RMS of .4 mG or 40 nT\n')
    logFile.write(str(tabulate(shapedData, headers = 'keys', tablefmt = 'psql', stralign = 'center')))
    logFile.close()
        
    print(f'Finished {fileNum} of {numFiles}: {dateName}')
    
RMSMean = np.mean(RMSArray, axis = 0)
shapedData = CreateFancyDataFrame(RMSMean, floatNums = True)
logFile = open(f"{targetPlotsFolderName}\\average_power_spectrum_RMS.txt", 'w')
logFile.write('RMS Measurements in nT measured from power spectrum of frequency response \nDatasheet states an RMS of .4 mG or 40 nT\n')
logFile.write(str(tabulate(shapedData, headers = 'keys', tablefmt = 'psql', stralign = 'center')))
logFile.close()

#%%
np.savetxt(f"{targetPlotsFolderName}\\average_RMS.csv", np.reshape(RMSMean, (24, 9)), delimiter=",", fmt="%.2f")