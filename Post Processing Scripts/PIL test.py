import os
from skimage import io

#%%
folder = 'C:\\Users\where\phenotox\example_dox\Dox_B3_1_2019y09m16d_19h10mDox_B3_1_2019y09m16d_19h10mDox_B3_1_2019y09m16d_19h10mDox_B3_1_2019y09m16d_19h10mDox_B3_1_2019y09m16d_19h10mDox_B3_1_2019y09m16d_19h10mDox_B3_1_2019y09m16d_19h10mDox_B3_1_2019y09m1'
name = 'Dox_B3_1_2019y09m16d_19h10mDox_B3_1_2019y09m16d_19h10mDox_B3_1_2019y09m16d_19h10mDox_B3_1_2019y09m16d_19h10mDox_B3_1_2019y09m16d_19h10mDox_B3_1_2019y09m16d_19h10mDox_B3_1_2019y09m16d_19h10mDox_B3_1_2019y09m1'

foo = io.imread(os.path.join(folder, f'{name}.tif'))

io.imsave(os.path.join(folder, f'{name}{name}_2.tif'), foo)