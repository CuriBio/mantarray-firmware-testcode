import numpy as np
import pandas as pd
from tkinter import Tk
from tkinter.filedialog import askopenfilename

#%% Load data
root = Tk()
root.wm_attributes('-topmost', 1)
fileName = askopenfilename()
root.destroy()

# data = pd.read_csv(fileName, ", ")
data = np.loadtxt(fileName, 'uint8', delimiter = ",", skiprows = 1, usecols = 1)

#%%
