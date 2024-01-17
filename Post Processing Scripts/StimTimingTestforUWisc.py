import os
import h5py
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path
from tkinter import Tk
from tkinter.filedialog import askopenfilename, askdirectory
from scipy.signal import find_peaks, peak_prominences, butter, lfilter
import json

axisMap = ['X', 'Y', 'Z']
wellMap = ['A1', 'A2', 'A3', 'A4', 'A5', 'A6', 
           'B1', 'B2', 'B3', 'B4', 'B5', 'B6', 
           'C1', 'C2', 'C3', 'C4', 'C5', 'C6', 
           'D1', 'D2', 'D3', 'D4', 'D5', 'D6']

offsetName = 'time_offsets' #[3,N]
indexName = 'time_indices' #[N]
dataName = 'tissue_sensor_readings' #[9,N]
stimName = "stimulation_readings"  #[2,M]

numWells = 24
numSensors = 3
numAxes = 3
memsicCenterOffset = 2**15
memsicMSB = 2**16
memsicFullScale = 16
gauss2MilliTesla = .1
UUID_PROTOCOL_INFO = 'ede638ce-544e-427a-b1d9-c40784d7c82d'
colors = ['blue', 'orange', 'green', 'red', 'purple']

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
fullStimData = None
largestStimData = None
protocolList = {}
pulseTimingDict = {}

for file in os.listdir(targetDataPath):
    if not file.endswith('.h5') or file.startswith('Calibration'):
        continue
    wellID = file[file.rfind('_')+1:-3]
    if wellMap[wellNum] != wellID:
        print("Error!!")
    
    dataFile =  h5py.File(file, 'r')    
    
    protocolList[wellID] = dataFile.attrs[UUID_PROTOCOL_INFO] 
    thisProtocol = json.loads(protocolList[wellID])
    numSubprotocols = len(thisProtocol["subprotocols"])
    pulseTimingTemp = np.zeros(numSubprotocols)
    for subprotocolIndex, subprotocol in enumerate(thisProtocol["subprotocols"]):
        pulseTimingTemp[subprotocolIndex] += (subprotocol["interphase_interval"] + 
                                          subprotocol["phase_one_duration"] + 
                                          subprotocol["phase_two_duration"] + 
                                          subprotocol["postphase_interval"])
        pulseTimingTemp[subprotocolIndex]/=1e6
    pulseTimingDict[wellID] = pulseTimingTemp
    
    rawTimeOffsets = np.array(dataFile[offsetName])
    rawTimeIndices = np.array(dataFile[indexName])
    rawData = np.array(dataFile[dataName])
    rawStimData = np.array(dataFile[stimName])
    numStimDataPoints = rawStimData.shape[1]
    
    if wellNum == 0:
        numSamples = rawTimeIndices.size
        fullTimestamps = np.zeros((numWells, numSensors, numSamples))
        fullData = np.zeros((numWells, numSensors, numAxes, numSamples))
        #Initialize what is the longest recorded stim data so that we only have to make one pass over the h5 files
        largestStimData = numStimDataPoints
        fullStimData = np.zeros((numWells, 2, largestStimData))
        
    #If the raw stim data is longer than the longest previously allocated array, we need to expand the size of fullStimData
    if numStimDataPoints > largestStimData:
        amountToExpand = numStimDataPoints - largestStimData
        fullStimData = np.pad(fullStimData, ((0,0),(0,amountToExpand)), 'edge')
        largestStimData = numStimDataPoints
        
    #If the raw stim data is shorter than the size of the array, it also needs to be padded before being inserted
    if numStimDataPoints != largestStimData:
        amountToExpand =  largestStimData - numStimDataPoints
        if numStimDataPoints == 0:
            rawStimData = np.pad(rawStimData, ((0,0),(0,amountToExpand)), 'constant', constant_values = 255)
        else:
            rawStimData = np.pad(rawStimData, ((0,0),(0,amountToExpand)), 'edge')
        
    fullStimData[wellNum] = rawStimData
    fullStimData[wellNum, 0] /= 1e6

    for sensorNum in range(numSensors):
        fullTimestamps[wellNum, sensorNum] = (rawTimeIndices - rawTimeOffsets[sensorNum]) / 1e6
        for axisNum in range(numAxes):
            fullData[wellNum, sensorNum, axisNum] = (rawData[sensorNum * numSensors + axisNum].astype('float64') - memsicCenterOffset) * memsicFullScale / memsicMSB * gauss2MilliTesla

    wellNum+=1

#%% Iterate over every subprotocol and plot the delays and the individual pulse graph
peakedData = fullData[:,0,2,:]
peakedTimestamps = fullTimestamps[:,0,:]
fig, axs = plt.subplots(4, 6, figsize=(100, 100), sharey = True)
numNotCaptured = 0
for wellNum in range(numWells):
    row = int(wellNum / 6)
    col = int(wellNum % 6)
    thisData = peakedData[wellNum]
    thisTimestamps = peakedTimestamps[wellNum]
    peaks = find_peaks(thisData)[0]
    # Find the prominence of each peak
    prominences = peak_prominences(thisData, peaks)[0]
    # Filter the peaks so that we are only paying attention to those that have a significant prominence
    filteredPeaks = find_peaks(thisData, prominence = np.amax(prominences)/3)[0]
    totalPulses = 0
    SubprotocolLabel = 1
    for subprotocolNumber, subprotocolIndex in enumerate(fullStimData[wellNum, 1]):
        if subprotocolIndex != 255:
            startTime = fullStimData[wellNum, 0, subprotocolNumber]
            endTime = fullStimData[wellNum, 0, subprotocolNumber + 1] if subprotocolNumber < fullStimData.shape[2] - 1 else np.max(thisTimestamps)
            if endTime - startTime < 5:
                continue
            thisSubprotocolPulseTiming = pulseTimingDict[wellMap[wellNum]][int(subprotocolIndex)]
            pulseStarts = np.arange(startTime, endTime, thisSubprotocolPulseTiming)
            
            timestampIndexAtBeginning = np.argmin(np.abs(thisTimestamps - pulseStarts[0]))
            timestampIndexAtEnding = np.argmin(np.abs(thisTimestamps - pulseStarts[-1]))
            
            # Find the index in the filtered peaks array that matches up to the index at the beginning of the timestamp array for this subprotocol
            firstPeakIndex = np.argmin(np.abs(thisTimestamps[filteredPeaks] - pulseStarts[0]))
            if thisTimestamps[filteredPeaks[firstPeakIndex]] - pulseStarts[0] > (thisSubprotocolPulseTiming / 2):
                pulseStarts = pulseStarts[1:]
            # Find the index in the filtered peaks array that matches up to the index at the ending of the timestamp array for this subprotocol
            lastPeakIndex = np.argmin(np.abs(thisTimestamps[filteredPeaks] - pulseStarts[-1])) + 1
            # if thisTimestamps[lastPeakIndex] - pulseStarts[:-1]:
                
            windowedPeaks = filteredPeaks[firstPeakIndex:lastPeakIndex]
            peakDelays = np.diff(thisTimestamps[windowedPeaks])                
            avgPeakDelay = np.mean(peakDelays)
            if np.min(peakDelays) < avgPeakDelay / 2:
                indicesToDelete = []
                for index, delay in enumerate(peakDelays):
                    if (delay < avgPeakDelay / 2):
                        beforePeakIndex = windowedPeaks[index]
                        afterPeakIndex = windowedPeaks[index + 1]
                        indicesToDelete.append(index if thisData[afterPeakIndex] > thisData[beforePeakIndex] else (index+1))
                windowedPeaks = np.delete(windowedPeaks, indicesToDelete)
                
            if pulseStarts.shape[0] != windowedPeaks.shape[0]:
                pulseDifference = windowedPeaks.shape[0] - pulseStarts.shape[0]
                # Too many pulses, not enough peaks
                if pulseDifference in range(-2, 0):
                    pulseStarts = pulseStarts[:-1]
                #     if subprotocolNumber == 0 and len(fullStimData[wellNum, 1]) > 1:
                #         firstPulseIndex -= pulseDifference
                #     else: 
                #         lastPulseIndex += pulseDifference
            #     # Too many peaks, not enough pulses
            #     if pulseDifference is in range(1, 3):
            if pulseStarts.shape[0] == thisTimestamps[windowedPeaks].shape[0]:
                # Derive a delay array from when the pulses started compared to their corresponding peaks
                delays = thisTimestamps[windowedPeaks] - pulseStarts
                # Plot the delay array
                axs[row, col].plot(np.arange(totalPulses, totalPulses + pulseStarts.shape[0]), delays, color = colors[SubprotocolLabel - 1], label=f'Subprotocol Number {SubprotocolLabel}')
            else:
                print (f'Skipping Well {wellMap[wellNum]}, subprotocol {subprotocolNumber}, did not capture')
                numNotCaptured += 1
            totalPulses += pulseStarts.shape[0]
            
            # Splitting every subprotocol into its own graph
            figSub, axsSub = plt.subplots(figsize=(20, 20))
            axsSub.plot(thisTimestamps[timestampIndexAtBeginning:timestampIndexAtEnding], thisData[timestampIndexAtBeginning:timestampIndexAtEnding] * 1000, label='Sensor 1 Axis Z')
            graphTop = axs.get_ylim()[1]
            graphBottom = axs.get_ylim()[0]
            axsSub.vlines(pulseStarts, graphBottom, graphTop, linewidths = .5, colors = "red")
            
            axsSub.set_title(f'Well {wellMap[wellNum]} Subprotocol #{SubprotocolLabel} of Frequency {1/thisSubprotocolPulseTiming:.2f} Hz', fontsize = 40)
            axsSub.set_xlabel('Time (sec)', fontsize = 30)
            axsSub.set_ylabel('Magnitude (uT)', fontsize = 30)
            axsSub.tick_params(which = 'major', labelsize = 20)
            axsSub.minorticks_on()
            axsSub.grid(which='major', linewidth=1.5)
            axsSub.grid(which='minor', linewidth=.5)
            axsSub.legend(fontsize = 20)
            
            if (os.path.exists(f"{targetPlotsFolderName}\{targetDataFolderName}_plots") == False): 
                os.mkdir(f"{targetPlotsFolderName}\{targetDataFolderName}_plots")
            if (os.path.exists(f"{targetPlotsFolderName}\{targetDataFolderName}_plots\Well{wellMap[wellNum]}") == False): 
                os.mkdir(f"{targetPlotsFolderName}\{targetDataFolderName}_plots\Well{wellMap[wellNum]}")
            figSub.savefig(f"{targetPlotsFolderName}\{targetDataFolderName}_plots\Well{wellMap[wellNum]}\Subprotocol{SubprotocolLabel}", bbox_inches = 'tight')
        SubprotocolLabel+=1
        
    axs[row, col].set_title(f'Well {wellMap[wellNum]}', fontsize = 60)
    axs[row, col].set_xlabel('Pulse Number', fontsize = 30)
    axs[row, col].set_ylabel('Twitch Delay (sec)', fontsize = 20)
    axs[row, col].tick_params(which = 'major', labelsize = 20)
    axs[row, col].minorticks_on()
    axs[row, col].grid(which='major', linewidth=1.5)
    axs[row, col].grid(which='minor', linewidth=.5)
    axs[row, col].legend(fontsize = 20)
   
print(f"Number of protocols not captured: {numNotCaptured}")     
fig.savefig(f"{targetPlotsFolderName}\{targetDataFolderName}_subprotocolDelays", bbox_inches = 'tight')
    