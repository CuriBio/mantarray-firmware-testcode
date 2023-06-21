#%%
import numpy as np
import pandas as pd

#%%
rawData = np.array((
    -72, 8, 78, 8, 0, -80, 8, 72, 8, 0, -84, 8, 72, 8, 0, -78, 8, 71, 8, 0, -80, 8, 66, 8, 0, -64, 8, 76, 8, 0, -82, 8, 76, 8, 0, -74, 8, 76, 8, 0, -74, 8, 72, 8, 0, -68, 8, 69, 8, 0, -80, 8, 76, 8, 0, -67, 8, 76, 8, 0, -72, 8, 69, 8, 0, -74, 8, 66, 8, 0, -70, 8, 78, 8, 0, -71, 8, 77, 8, 0, -66, 8, 75, 8, 0, -76, 8, 73, 8, 0, -70, 8, 71, 8, 0, -89, 8, 69, 8, 0, -75, 8, 75, 8, 0, -71, 8, 75, 8, 0, -75, 8, 69, 8, 0, -74, 8, 70, 8, 0
    # 2, 8, -58, 10, 1, 1, 8, -54, 10, 1, 0, 8, -58, 10, 1, 2, 8, -23, 10, 1, 1, 8, -40, 10, 1, 1, 8, -27, 10, 1, 0, 8, -9, 10, 1, 2, 8, -70, 10, 1, 0, 8, -27, 10, 1, 1, 8, 4, 11, 1, 1, 8, -62, 10, 1, 2, 8, -42, 10, 1, 1, 8, -28, 10, 1, 1, 8, -32, 10, 1, 2, 8, -14, 10, 1, 2, 8, -35, 10, 1, 1, 8, -35, 10, 1, 2, 8, -38, 10, 1, -40, 11, -70, 12, 3, 2, 8, 4, 11, 1, 1, 8, -18, 10, 1, 1, 8, -36, 10, 1, 0, 8, -50, 10, 1, 2, 8, -29, 10, 1
    # -53, 8, -46, 5, 0, -47, 8, -28, 5, 0, -58, 8, -74, 5, 0, -66, 8, -114, 5, 0, -50, 8, -32, 5, 0, -58, 8, -75, 5, 0, -68, 8, -124, 5, 0, -47, 8, -18, 5, 0, -57, 8, -75, 5, 0, -57, 8, -82, 5, 0, -50, 8, -40, 5, 0, -48, 8, -28, 5, 0, -56, 8, -71, 5, 0, -49, 8, -34, 5, 0, -51, 8, -42, 5, 0, -52, 8, -51, 5, 0, -66, 8, 126, 5, 0, -48, 8, -37, 5, 0, 3, 9, -103, 6, 0, -57, 8, -83, 5, 0, -50, 8, -47, 5, 0, -54, 8, -70, 5, 0, -51, 8, -48, 5, 0, -63, 8, -118, 5, 0
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


df.to_csv('C:\\Users\\aster\\Desktop\\New folder\\test.csv', index=False, header=True)