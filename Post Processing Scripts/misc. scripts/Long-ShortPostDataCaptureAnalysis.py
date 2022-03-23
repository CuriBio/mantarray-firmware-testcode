#%% Import Libraries
import numpy as np
import matplotlib.pyplot as plt
from scipy import fft
from scipy import signal as sig
from pandas import DataFrame as df
from tabulate import tabulate

#%%
def ImportData(dateName):
    fileName = f'./data/{dateName}.txt'
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
            
    return fullTimestamps, fullData

def LineraizeTimestampsSingleWell(timestamps):
    linearizedTimestamps, increment = np.linspace(timestamps[:,0], timestamps[:,-1], timestamps.shape[1], retstep=True, axis = 1)
    return linearizedTimestamps, increment

def GraphSingleWellCompare(data_x, 
                           data_y, 
                           axesLabelx, 
                           axesLabely, 
                           title):
    fig, axs = plt.subplots(3, 3, figsize=(40, 30)) 
    for plotNum in range(3):
        for sensorNum in range(3):
            thisXData = data_x[plotNum, sensorNum]
            for axisNum in range(3):
                thisYData = data_y[plotNum, sensorNum, axisNum]
                axs[plotNum, sensorNum].plot(thisXData, thisYData) 
                
            axs[plotNum, sensorNum].set_xlabel(axesLabelx, fontsize = 30)
            axs[plotNum, sensorNum].set_ylabel(axesLabely, fontsize = 30)
            axs[plotNum, sensorNum].grid(which='both')
            axs[plotNum, sensorNum].tick_params(which = 'both', labelsize = 20)
            #axs[plotNum, sensorNum].legend(['Axis X', 'Axis Y', 'Axis Z'], prop={"size":30})
        
    fig.suptitle(title, fontsize = 40)
    return fig
            
#%%
timestamps, data = ImportData('Static Capture - Long Post - Round 1')
longPostData = data[5]
longPostTimestamps = timestamps[5]
longPostTimestampsLinear,_ = LineraizeTimestampsSingleWell(longPostTimestamps)

timestamps, data = ImportData('Static Capture - Short Post - Round 1')
shortPostData = data[5]
shortPostTimestamps = timestamps[5]
shortPostTimestampsLinear,_ = LineraizeTimestampsSingleWell(shortPostTimestamps)

timestamps, data = ImportData('Static Capture - No magnets (A6 only)')
noMagData = data[5]
noMagTimestamps = timestamps[5]
noMagTimestampsLinear,_ = LineraizeTimestampsSingleWell(noMagTimestamps)

#%%
newLength = min(shortPostData.shape[2], longPostData.shape[2], noMagData.shape[2])
threeData = np.stack((shortPostData[:,:,:newLength], longPostData[:,:,:newLength], noMagData[:,:,:newLength]))
threeTimestamps = np.stack((shortPostTimestampsLinear[:,:newLength], longPostTimestampsLinear[:,:newLength], noMagTimestampsLinear[:,:newLength]))
fig = GraphSingleWellCompare(threeTimestamps, threeData, "Time (sec)", "Amplitude (mT)", "Top is Short Post, Middle is Long Post, Bottom is No Magnets")