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

#%%
# root = Tk()
# root.wm_attributes('-topmost', 1)
# fileName = askopenfilename()
# root.destroy()
# stimConfig = json.load(open(fileName, 'r'))
# thisProtocol = stimConfig["protocols"][0]["protocol"]
# numSubprotocols = len(thisProtocol["subprotocols"])

# pulseTiming = np.zeros(numSubprotocols)
# for subprotocolIndex, subprotocol in enumerate(thisProtocol["subprotocols"]):
#     pulseTiming[subprotocolIndex] += (subprotocol["interphase_interval"] + 
#                                       subprotocol["phase_one_duration"] + 
#                                       subprotocol["phase_two_duration"] + 
#                                       subprotocol["postphase_interval"])
#     pulseTiming[subprotocolIndex]/=1000

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
    
#%%
finalIndex = 7000
fig, axs = plt.subplots(4, 6, figsize=(100, 100), sharey=True)
for wellNum in range(numWells):
# for wellNum in range(1):
    row = int(wellNum / 6)
    col = int(wellNum % 6)
    for sensorNum in range(numSensors):
        for axisNum in range(numAxes):
            axs[row, col].plot(fullTimestamps[wellNum, sensorNum, :finalIndex], fullData[wellNum, sensorNum, axisNum, :finalIndex] * 1000, label=f'Sensor {sensorNum + 1} Axis {axisMap[axisNum]}')
    axs[row, col].set_title(f'Well {wellMap[wellNum]}', fontsize = 60)
    axs[row, col].set_xlabel('Time (sec)', fontsize = 30)
    axs[row, col].set_ylabel('Magnitude (uT)', fontsize = 20)
    axs[row, col].tick_params(which = 'major', labelsize = 20)
    axs[row, col].minorticks_on()
    axs[row, col].grid(which='major', linewidth=1.5)
    axs[row, col].grid(which='minor', linewidth=.5)
    axs[row, col].legend(fontsize = 20)

graphTop = axs[0, 0].get_ylim()[1]
graphBottom = axs[0, 0].get_ylim()[0]
graphRight = np.max(fullTimestamps)
graphLeft = np.min(fullTimestamps)
    
for wellNum in range(numWells):
    row = int(wellNum / 6)
    col = int(wellNum % 6)
    for subprotocolNumber, subprotocolIndex in enumerate(fullStimData[wellNum, 1]):
        # axs[row, col].vlines(fullStimData[wellNum], axs[row, col].get_ylim()[0], axs[row, col].get_ylim()[1], linewidths = .5)
    
        if subprotocolIndex != 255:
            thisSubprotocolPulseTiming = pulseTimingDict[wellMap[wellNum]][int(subprotocolIndex)]
            beginning = fullStimData[wellNum, 0, subprotocolNumber]
            #If the stimulation began before the recording started, we want to shift where the beginning is to be within the recording range
            if beginning < np.min(fullTimestamps):
                beginning = graphLeft + ((beginning - graphLeft) % thisSubprotocolPulseTiming)
            ending = fullStimData[wellNum, 0, subprotocolNumber + 1] if subprotocolNumber < fullStimData.shape[2] - 1 else graphRight
            pulseStarts = np.arange(beginning, ending, thisSubprotocolPulseTiming)
            axs[row, col].vlines(pulseStarts, graphBottom, graphTop, linewidths = .5, colors = "red")
    
fig.savefig(f"{targetPlotsFolderName}\{targetDataFolderName}_transient", bbox_inches = 'tight')

#%% Peak finding algorithms
twitchDelays = []
# Select only sensor 1 axis Z
peakedData = fullData[:,0,2,:]
peakedTimestamps = fullTimestamps[:,0,:]
wellNums = [18,20]
# fig, axs = plt.subplots(len(wellNums), figsize=(80, 40))
fig, axs = plt.subplots(4, 6, figsize=(100, 100), sharey = True)
for wellNum in range(numWells):
    if wellNum != 22:
        thisData = peakedData[wellNum]
        thisTimestamps = peakedTimestamps[wellNum]
    # for wellNum in range(1):
        row = int(wellNum / 6)
        col = int(wellNum % 6)
        # Find the peaks on sensor 1 axis Z
        peaks = find_peaks(thisData)[0]
        # Find the prominence of each peak
        prominences = peak_prominences(thisData, peaks)[0]
        # Filter the peaks so that we are only paying attention to those that have a significant prominence
        filteredPeaks = find_peaks(thisData, prominence = np.amax(prominences)/1.25)[0]
        
        twitchDelays.insert(wellNum, np.mean(np.diff(thisTimestamps[filteredPeaks])))
        
        totalPulses = 0
        
        for subprotocolNumber, subprotocolIndex in enumerate(fullStimData[wellNum, 1]):
            # If we are looking at a null subprotocol, ignore it
            if subprotocolIndex != 255:
                # Find the beginning timestamp of the subprotocol
                beginning = fullStimData[wellNum, 0, subprotocolNumber]
                # If the stimulation began before the recording started, we want to shift where the beginning is to be within the recording range
                if beginning < 0:
                    beginning = graphLeft + ((beginning - graphLeft) % pulseTiming[int(subprotocolIndex)])
                # Find the index in the timestamp array that this beginning starts at
                timestampIndexAtBeginning = np.argmin(np.abs(thisTimestamps - beginning))
                # Find the ending timestamp of the subprotocol
                ending = fullStimData[wellNum, 0, subprotocolNumber + 1] if subprotocolNumber < fullStimData.shape[2] - 1 else graphRight
                # Find the index in the timestamp array that this ending ends at
                timestampIndexAtEnding = np.argmin(np.abs(thisTimestamps - ending))
                # Interpolate a time index series from the beginning to the end of the subprotocol stimulation to overlay on the magnetometer data
                pulseStarts = np.arange(beginning, ending, pulseTiming[int(subprotocolIndex)])
                
                # Find the index in the interpolated pulse array that matches up to the index at the beginning of the timestamp array for this subprotocol
                firstPulseIndex = np.argmin(np.abs(pulseStarts - thisTimestamps[timestampIndexAtBeginning]))
                # Find the index in the interpolated pulse array that matches up to the index at the ending of the timestamp array for this subprotocol
                lastPulseIndex = np.argmin(np.abs(pulseStarts - thisTimestamps[timestampIndexAtEnding])) + 1
                # If there are more or less pulses in the pulse array then peaks in the data, then there is a good chance you aren't capturing tissue and I can't help ya bud
                
                # Find the index in the filtered peaks array that matches up to the index at the beginning of the timestamp array for this subprotocol
                firstPeakIndex = np.argmin(np.abs(thisTimestamps[filteredPeaks] - thisTimestamps[timestampIndexAtBeginning]))
                # Find the index in the filtered peaks array that matches up to the index at the ending of the timestamp array for this subprotocol
                lastPeakIndex = np.argmin(np.abs(thisTimestamps[filteredPeaks] - thisTimestamps[timestampIndexAtEnding])) + 1
                windowedPeaks = filteredPeaks[firstPeakIndex:lastPeakIndex]
                
                if ((lastPulseIndex) - firstPulseIndex) != thisTimestamps[windowedPeaks].shape[0]:
                    pulseDifference = windowedPeaks.shape[0] - (lastPulseIndex - firstPulseIndex)
                    # If you are a little under the correct number, the peak may be slightly cut off on the end
                    if pulseDifference < 0 and pulseDifference > -3:
                        if subprotocolNumber == 0 and len(fullStimData[wellNum, 1]) > 1:
                            firstPulseIndex -= pulseDifference
                        else: 
                            lastPulseIndex += pulseDifference
                    #If you are a little over the correct number, then we are just going to do a bit of filtering
                    elif pulseDifference < ((lastPulseIndex - firstPulseIndex)/4):
                        sampleDelays = np.diff(windowedPeaks)
                        avgSampleDelay = np.mean(sampleDelays)
                        indicesToDelete = []
                        for index, delay in enumerate(sampleDelays):
                            if (delay < avgSampleDelay/2):
                                beforePeakIndex = windowedPeaks[index]
                                afterPeakIndex = windowedPeaks[index + 1]
                                indicesToDelete.append(index if thisData[afterPeakIndex] > thisData[beforePeakIndex] else (index+1))
                        windowedPeaks = np.delete(windowedPeaks, indicesToDelete)
                if ((lastPulseIndex) - firstPulseIndex) == thisTimestamps[windowedPeaks].shape[0]:
                    # Derive a delay array from when the pulses started compared to their corresponding peaks
                    delays = thisTimestamps[windowedPeaks] - pulseStarts[firstPulseIndex:lastPulseIndex]
                    # Plot the delay array
                    axs[row, col].plot(np.arange(totalPulses, totalPulses + delays.shape[0]), delays, label=f'Subprotocol Number {subprotocolNumber}')
                    totalPulses += delays.shape[0]
                else:
                    print (f'Skipping Well {wellMap[wellNum]}, subprotocol {subprotocolNumber}, did not capture')
        
        axs[row, col].set_title(f'Well {wellMap[wellNum]}', fontsize = 60)
        axs[row, col].set_xlabel('Pulse Number', fontsize = 30)
        axs[row, col].set_ylabel('Twitch Delay (sec)', fontsize = 20)
        axs[row, col].tick_params(which = 'major', labelsize = 20)
        axs[row, col].minorticks_on()
        axs[row, col].grid(which='major', linewidth=1.5)
        axs[row, col].grid(which='minor', linewidth=.5)
        axs[row, col].legend(fontsize = 20)
    
fig.savefig(f"{targetPlotsFolderName}\{targetDataFolderName}_subprotocolDelays", bbox_inches = 'tight')

#%%
fig, axs = plt.subplots(figsize=(50, 50))
wellNum = 18
for sensorNum in range(numSensors):
    for axisNum in range(numAxes):
        axs.plot(fullTimestamps[wellNum, sensorNum, :-1], fullData[wellNum, sensorNum, axisNum, :-1] * 1000, label=f'Sensor {sensorNum + 1} Axis {axisMap[axisNum]}')
axs.set_title(f'Well {wellMap[wellNum]}', fontsize = 60)
axs.set_xlabel('Time (sec)', fontsize = 60)
axs.set_ylabel('Magnitude (uT)', fontsize = 40)
axs.tick_params(which = 'major', labelsize = 40)
axs.minorticks_on()
axs.grid(which='major', linewidth=1.5)
axs.grid(which='minor', linewidth=.5)
axs.legend(fontsize = 20)

graphTop = axs.get_ylim()[1]
graphBottom = axs.get_ylim()[0]
graphRight = np.max(fullTimestamps)
    
for subprotocolNumber, subprotocolIndex in enumerate(fullStimData[wellNum, 1]):
    # axs[row, col].vlines(fullStimData[wellNum], axs[row, col].get_ylim()[0], axs[row, col].get_ylim()[1], linewidths = .5)

    if subprotocolIndex != 255:
        beginning = fullStimData[wellNum, 0, subprotocolNumber]
        #If the stimulation began before the recording started, we want to shift where the beginning is to be within the recording range
        if beginning < 0:
            beginning = graphLeft + ((beginning - graphLeft) % pulseTiming[int(subprotocolIndex)])
        ending = fullStimData[wellNum, 0, subprotocolNumber + 1] if subprotocolNumber < fullStimData.shape[2] - 1 else graphRight
        pulseStarts = np.arange(beginning, ending, pulseTiming[int(subprotocolIndex)])
        axs.vlines(pulseStarts, graphBottom, graphTop, linewidths = .5, colors = "red")
    
fig.savefig(f"{targetPlotsFolderName}\{targetDataFolderName}_transient_zoomed", bbox_inches = 'tight')
		

#%% Zoomed in Transient on only the sensing axis

#Build the filter
order = 4
fs = 100.0       # sample rate, Hz
cutoff = 10  # desired cutoff frequency of the filter, Hz
nyq = 0.5 * fs
normal_cutoff = cutoff / nyq
b, a = butter(order, normal_cutoff, btype='low', analog=False)

wellNums = [8,18]
sensingAxisData = fullData[:,0,2,:]
sensingAxisTimestamps = fullTimestamps[:,0,:]
fig, axs = plt.subplots(len(wellNums), figsize=(80, 40))
for idx, wellNum in enumerate(wellNums):
    thisData = lfilter(b, a, sensingAxisData[wellNum, :1000])
    thisTimestamps = sensingAxisTimestamps[wellNum, :1000]
    axs[idx].plot(thisTimestamps[100:], thisData[100:] * 1000, linewidth = 2, label=f'Sensor {sensorNum + 1} Axis {axisMap[axisNum]}')
    axs[idx].set_title(f'Well {wellMap[wellNum]}', fontsize = 60)
    axs[idx].set_xlabel('Time (sec)', fontsize = 30)
    axs[idx].set_ylabel('Magnitude (uT)', fontsize = 20)
    axs[idx].tick_params(which = 'major', labelsize = 20)
    axs[idx].minorticks_on()
    axs[idx].grid(which='major', linewidth=1.5)
    axs[idx].grid(which='minor', linewidth=.5)
    axs[idx].legend(fontsize = 20)

    graphTop = axs[idx].get_ylim()[1]
    graphBottom = axs[idx].get_ylim()[0]
    graphRight = np.max(thisTimestamps)
    graphLeft = np.min(thisTimestamps)
    
    for subprotocolNumber, subprotocolIndex in enumerate(fullStimData[wellNum, 1]):
        if subprotocolIndex != 255:
            beginning = fullStimData[wellNum, 0, subprotocolNumber]
            #If the stimulation began before the recording started, we want to shift where the beginning is to be within the recording range
            if beginning < np.min(fullTimestamps):
                beginning = graphLeft + ((beginning - graphLeft) % pulseTiming[int(subprotocolIndex)])
            ending = fullStimData[wellNum, 0, subprotocolNumber + 1] if subprotocolNumber < fullStimData.shape[2] - 1 else graphRight
            pulseStarts = np.arange(beginning, ending, pulseTiming[int(subprotocolIndex)])
            axs[idx].vlines(pulseStarts, graphBottom, graphTop, linewidths = 1, colors = "red")
    
fig.savefig(f"{targetPlotsFolderName}\{targetDataFolderName}_transient_zoomed", bbox_inches = 'tight')
