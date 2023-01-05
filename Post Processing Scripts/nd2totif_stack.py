import os
import nd2
import tifffile
from tkinter import Tk
from tkinter.filedialog import askdirectory, askopenfilename
from pathlib import Path

#%%

root = Tk()
root.wm_attributes('-topmost', 1)
targetDataDirectory = askdirectory ()
targetDataPath = Path(targetDataDirectory)
root.destroy()

targetConvertedFolderName = f'{targetDataPath.parent}/converted'
    
if (os.path.exists(targetConvertedFolderName) == False): 
    os.mkdir(targetConvertedFolderName)

for file in os.listdir(targetDataPath):  
    stacked_nd2_image = nd2.imread(f'{targetDataDirectory}/{file}')
    filename = file[:-4]
    tifffile.imwrite(f'{targetConvertedFolderName}/{filename}.tif', stacked_nd2_image)
    # for index in range(stacked_nd2_image.shape[0]):
    #     tifffile.imwrite(f'{targetConvertedFolderName}/{filename}_{index}.tif', stacked_nd2_image[index])
    
    
#%%
root = Tk()
root.wm_attributes('-topmost', 1)
fileName = askopenfilename()
root.destroy()

filePath = Path(fileName)

targetConvertedFolderName = f'{filePath.parent}'

#%%
stacked_nd2_image = nd2.imread(fileName)
filename = file[:-4]
tifffile.imwrite(f'{targetConvertedFolderName}/{filename}.tif', stacked_nd2_image)
    # for index in range(stacked_nd2_image.shape[0]):
    #     tifffile.imwrite(f'{targetConvertedFolderName}/{filename}_{index}.tif', stacked_nd2_image[index])