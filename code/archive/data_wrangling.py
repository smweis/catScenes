# -*- coding: utf-8 -*-
"""
Testing plotting images
"""

import matplotlib.pyplot as plt
import numpy as np
from itertools import cycle
import pandas as pd
import os
from ast import literal_eval


# Get the current directory (directory the script is in)
workingDir = os.getcwd()

# WHERE IS THE DATA
dataDir = '..//ToAnalyze'
dataFiles = os.listdir(dataDir)



# Assemble the linguistic coding data into analyzable form.
# This function assigns a 1 if a direction was indicated by that participant
# and a 0 if that direction was not selected. 
def lingDirCheck(index,boxesChecked):
    global masterData
    for direction in ['ahead','left','sharp_left','slight_left','sharp_right','right','slight_right']:
        if 'trial_'+ direction + '_box' in boxesChecked:
            masterData.at[index,direction] = 1
        else:
            masterData.at[index,direction] = 0




def analogDirCheck(index,height):
    global masterData
    sketch = masterData.loc[index,'drawingFixed']
    px = []
    py = []
    for i,j in enumerate(sketch):
        px.append([])
        py.append([])
        for k,l in enumerate(j):
            px[i].append(l[0]*height)
            py[i].append(l[1]*height)
    
    colors = cycle(['red','blue','green','purple','pink'])

    fig,ax = plt.subplots(figsize=[1,1],dpi=100)

    for i,j in enumerate(px):
        ax.plot(px[i],py[i],color=next(colors))
        ax.set_xlim(-height*.4,height*.4)
        ax.set_ylim(-height*.4,height*.4)
    
    fig.tight_layout(pad=0)
    plt.axis('off')
    plt.draw()
    data = np.frombuffer(fig.canvas.tostring_rgb(), dtype=np.uint8)
    plt.close(fig)
    return data

#####################################
# Load in the participant data file #
#####################################

# Change this to false if you edit the load sequence
loaded = False

if not os.path.exists("..//masterData.csv") or not loaded:
    # Get all data files
    dataFileNames = [x for x in dataFiles if 'csv' in x]
   
    # Load all data files in.
    for i,fileName in enumerate(dataFileNames):
        with open (dataDir + os.path.sep + fileName, "r") as myfile:
            participantData = pd.read_csv(myfile,sep=',')
            participantData.rename(columns={participantData.iloc[(3,0)]: "presentedImage"},inplace=True)
    
        # For the first dataset, just create the dataFrame
        if i < 1:
            masterData = participantData.copy()
            masterData.rename(columns={masterData.iloc[(3,0)]: "presentedImage"},inplace=True)
        # Concatenate the rest
        else:
            masterData = pd.concat([masterData,participantData])
    
    masterData.reset_index(inplace=True)
    
    # Fix the drawing values to save better. 
    masterData['drawingFixed'] = np.nan
    masterData['drawingFixed'] = masterData['drawingFixed'].astype('object')
    masterData['drawingCoded'] = np.nan
    masterData['drawingCoded'] = masterData['drawingCoded'].astype('object')
    # Adding columns for the ling coding
    masterData['ahead'] = np.nan
    masterData['left'] = np.nan
    masterData['sharp_left'] = np.nan
    masterData['slight_left'] = np.nan
    masterData['sharp_right'] = np.nan
    masterData['right'] = np.nan
    masterData['slight_right'] = np.nan
    
    
    # Set up drawing data dataframe, which is structured by image. 
    imageNames = masterData.presentedImage.unique().tolist()
    drawingData = pd.DataFrame(columns=imageNames)
    
    for index,row in masterData.iterrows():
        if not pd.isna(row['presentedImage']) and 'analog' in row['expName']:
            masterData.at[index,'drawingFixed'] = literal_eval(row['drawing'])
            # row['windowSize'][1] is the height of the monitor used by the subject. 
            # Critical to use this to normalize the drawing.
            height = int(row['windowSize'].strip('[]').split(',')[1])
            drawingData['temp'] = analogDirCheck(index, height)
            tempDF = drawingData.loc[:,['temp',row['presentedImage']]].copy()
            drawingData.at[:,row['presentedImage']] = tempDF.mean(axis=1)
        elif not pd.isna(row['presentedImage']) and 'ling' in row['expName']:
            lingDirCheck(index,row['boxes_checked'])
            
    # Save out the data
    masterData.to_csv("..//masterData.csv")
    drawingData.drop(columns=['temp',np.nan],inplace=True)
    drawingData.to_csv("..//drawingData.csv")
    
else:
    masterData = pd.read_csv("..//masterData.csv")
    drawingData = pd.read_csv("..//drawingData.csv")
   

lingDirections = masterData.groupby(['presentedImage'])['ahead','right','left','sharp_right','slight_right','slight_left','sharp_left'].mean()


analogCorrMatrix = drawingData.corr()
analogCorrMatrix.sort_index(inplace=True,axis=0)
analogCorrMatrix.sort_index(inplace=True,axis=1)
b = analogCorrMatrix.to_numpy()
b = np.reshape(b,250000)

lingCorrMatrix = lingDirections.T.corr()
lingCorrMatrix.sort_index(inplace=True,axis=0)
lingCorrMatrix.sort_index(inplace=True,axis=1)
a = lingCorrMatrix.to_numpy()
a = np.reshape(a,250000)


c = np.corrcoef(a,b)

analogCorrMatrix.to_csv("..//analogCorrMatrix.csv")
lingCorrMatrix.to_csv("..//lingCorrMatrix.csv")
 
d