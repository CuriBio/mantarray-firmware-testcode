from numpy import array, zeros, append
from pandas import DataFrame
from tkinter import Tk
from tkinter.filedialog import askopenfilename
# import os
from tabulate import tabulate

FLIPPED_RESISTOR = True # change to false if ADC9 resistors are not flipped


# File selector
root = Tk()
filepath = askopenfilename(parent=root, filetypes=[('TXT','*mantarray_log*.txt')])
root.destroy()

filename = filepath.split('/')[-1]
filepath_out = filepath[:-4]+'_adc_readings.txt'

i = []

# function that saves to file and prints to screen
def save_to_file(filepath_out, string):
    with open(filepath_out, 'a') as f:
        f.write(string+'\n')
    print(string)


with open(filepath_out, 'w') as f:
    f.write('------------------- ADC readings ------------------\n')

wellLabels = array(["{}{}".format(col, row) for row in [1,2,3,4,5,6] for col in ['A','B','C','D']])

with open(filepath) as f:
    log_file = f.read() # read the entire log file

line_by_line = log_file.split('\n') # split by return carriage

metadata_line = [i for i in line_by_line if 'metadata' in i] # all lines in the log file that have metadata
adc_lines = [i for i in line_by_line if 'adc' in i]          # all lines in the log file that have ADC readings

software_version_line = [i for i in line_by_line if 'Mantarray Controller v' in i] # all lines that contain software version

if len(software_version_line) > 0: # really only use the first line that has the software version
    software_version_line = software_version_line[0]
    idx1 = software_version_line.rfind('v')
    idx2 = software_version_line.rfind('started')
    software_version = software_version_line[idx1+1:idx2-1].split('.')
    software_version = [int(i) for i in software_version]
else:
    software_version = [0, 0, 0]

if len(metadata_line) > 0: # really only use the first line that has the metadata
    metadata_line = metadata_line[0]
    idx1 = metadata_line.find('communication_type')
    metadata_line = metadata_line.replace('UUID(','').replace(')','')
    all_data = eval("{'"+metadata_line[idx1:])
    metadata = all_data['metadata']
    all_metadata = []
    for key, value in metadata.items():
        all_metadata.append(value)
    
    (   board_idx, nickname, 
        instrument_serial_number, 
        channel_micro_version, 
        main_micro_version, 
        statuses, 
        pulse3d_initial_guesses) = tuple(all_metadata)
    
    all_statuses = []
    for key, value in statuses.items():
        all_statuses.append(value)
    
else:
    metadata_line = ''
    instrument_serial_number = 'N/A'
    input('NO METADATA, INVALID LOG FILE. PRESS ENTER TO EXIT.')
    quit()


# Save metadata to file and print to screen
save_to_file(filepath_out,"META DATA: ")
save_to_file(filepath_out,'Serial #: {}'.format(instrument_serial_number))
save_to_file(filepath_out,'Channel Micro Firmware version: {}'.format(channel_micro_version))
save_to_file(filepath_out,'Main Micro Firmware version: {}'.format(main_micro_version))
save_to_file(filepath_out,'Channel Statuses: [{}, {}], [{}]'.format(all_statuses[0], all_statuses[1], ", ".join([str(i) for i in all_statuses[2:]])))
save_to_file(filepath_out,'Pulse 3D Initial Guesses: X: {}, Y: {}, Z: {}, REMN: {}'.format( pulse3d_initial_guesses['X'],
                                                                        pulse3d_initial_guesses['Y'],
                                                                        pulse3d_initial_guesses['Z'],
                                                                        pulse3d_initial_guesses['REMN']))
save_to_file(filepath_out,'\n')


# loop through lines containing ADC readings
k = 1
for line in adc_lines:

    idx = line.find('Communication from the Instrument Controller:' )+len('Communication from the Instrument Controller:') # parse for start of information received from instrument
    adc_info = eval(line[idx:]) # get info, eval should returns a dict

    # there's more information here than just what's parsed out.  We can use as much as we want or need, but this is the most pertinent information stored in the ADC readings
    well_indices = adc_info['well_indices'] # which wells were stimulated
    stimulator_circuit_statuses = adc_info['stimulator_circuit_statuses'] # results (media, error, open)
    adc_readings = adc_info['adc_readings'] # actual ADC readings (counts)
    stim_barcode = adc_info['stim_barcode'] # stim lid barcode
    plate_barcode = adc_info['plate_barcode'] # lattice barcode
    

    columns = ['well','adc8','adc9','V_adc8','V_adc9','W-','W+','current','status'] # infomration to tabulate
    final_values = zeros((9,1)) # dummy
    for well in well_indices:
        wellLabel = wellLabels[well]
        if software_version[2] < 7 and software_version[1] < 1: # handle based on software version.  Software versions below 1.0.7 have different log file outputs than after 1.0.7
            idx = well # pre-1.0.7 uses channel index (0-23)
        else:
            idx = wellLabel # post-1.0.7 uses well label (A1-D6)
        adc8 = adc_readings[idx][0]
        adc9 = adc_readings[idx][1]
        status = stimulator_circuit_statuses[idx]
        adc8_V = round(adc8*3.3/4096,3) # convert count to Voltage
        adc9_V = round(adc9*3.3/4096,3)
        W_minus = round(((2 * adc8_V) - 3.3),3) # Well- = 2*(V8-3.3)
        if FLIPPED_RESISTOR: W_plus = round(adc9_V-(((2.00121286-adc9_V)/47000)*10000),3) # W+ = V9 - (~2 - V9)/47)*10
        else:                W_plus = round(adc9_V-(((2.00121286-adc9_V)/10000)*47000),3)
        current = round((abs(W_minus/33) * 1000),3) # current = W-/33
        well_values = array([wellLabel, adc8, adc9, adc8_V, adc9_V, W_minus, W_plus, current, status]).reshape((9,1))
        final_values = append(final_values, well_values, axis=1)

    # organize information to tabulate and save to file
    df = DataFrame(final_values.transpose(), columns=columns)
    df.drop(0, inplace=True)
    df.set_index('well', inplace=True)
    out_string = tabulate(final_values[:,1:].transpose(), columns).split('\n')
    save_to_file(filepath_out,"ADC READINGS # {}".format(k))
    save_to_file(filepath_out,"PLATE BARCODE: {}".format(plate_barcode))
    save_to_file(filepath_out,"STIM BARCODE: {}".format(stim_barcode))
    
    save_to_file(filepath_out,"----------------------------------------------------------------------------")
    for txt in out_string:
        save_to_file(filepath_out, txt)
    
    save_to_file(filepath_out,"\n")

    k+=1

input("END OF FILE. Saved output to text file. Press ENTER to Exit.")