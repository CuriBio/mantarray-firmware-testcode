#%%
import numpy as np
import pandas as pd

#%%
rawData = np.array((
    0, 8, -34, 10, 1, 2, 8, -23, 10, 1, 0, 8, -23, 10, 1, 0, 8, -27, 10, 1, 1, 8, -39, 10, 1, 0, 8, 7, 11, 1, 1, 8, -27, 10, 1, 1, 8, -36, 10, 1, 1, 8, -13, 10, 1, 0, 8, -32, 10, 1, 0, 8, -10, 10, 1, 1, 8, -11, 10, 1, 2, 8, -43, 10, 1, 2, 8, -3, 10, 1, 1, 8, -5, 10, 1, 2, 8, -23, 10, 1, 0, 8, -7, 10, 1, 1, 8, -44, 10, 1, 0, 8, 10, 11, 1, 1, 8, -11, 10, 1, 2, 8, -23, 10, 1, 1, 8, -18, 10, 1, 1, 8, -22, 10, 1, 1, 8, 111, 15, 1
    ))
rawData[rawData < 0] += 256
rawData = rawData.reshape((-1,5))

adc8 = (rawData[:,0] + rawData[:,1]*2**8).reshape((-1))
adc9 = (rawData[:,2] + rawData[:,3]*2**8).reshape((-1))
wellMinus = ((2 * (adc8 / 4096) * 3.3) - 3.3).reshape((-1))
wellPlus = 5.7 * ((adc9 / 4096) * 3.3 - 1.65053);
current = (np.abs(wellMinus/33) * 1000).reshape((-1))
stimStatus = rawData[:,4:].astype('str').reshape((-1))
stimStatus = np.char.replace(stimStatus, '0', 'GOOD')
stimStatus = np.char.replace(stimStatus, '1', 'OPEN')
stimStatus = np.char.replace(stimStatus, '3', 'ERROR')

data = {'ADC8':adc8,
        'ADC9':adc9,
        'Well Minus (V)':wellMinus,
        'Current (mA)':current,
        'Status':stimStatus}

df = pd.DataFrame(data)
print(df)


df.to_csv('C:\\Users\\where\\Desktop\\New folder\\test.csv', index=False, header=True)