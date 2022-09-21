# -*- coding: utf-8 -*-
"""
Testing plotting images
"""

import matplotlib.pyplot as plt
from itertools import cycle
import numpy as np
import pandas as pd
import os
from ast import literal_eval


# Get the current directory (directory the script is in)
workingDir = os.getcwd()


# WHERE ARE THE IMAGES
# Images can be downloaded here: https://bold5000.github.io/download.html
imDir = os.path.join('..','..','BOLD5000_Original','BOLD5000_Stimuli','BOLD5000_Stimuli','Scene_Stimuli','Presented_Stimuli','Scene')

# WHERE IS THE DATA
dataDir = os.path.join('..','onlinePilot')
dataFiles = os.listdir(dataDir)

###########################
# Load in a list of images#
###########################

# Get a list of files in the stimuli directory
imFiles = os.listdir(imDir)
# List all of the jpg files
imFileNames = [x for x in imFiles if 'jpg' in x]
imFullFileNames = []
for i in imFileNames:
    imFullFileNames.append(os.path.join(imDir,i))

#####################################
# Load in the participant data file #
#####################################

# All CSVs.
dataFileNames = [x for x in dataFiles if 'csv' in x]
dataFullFileNames = []
for i in dataFileNames:
    dataFullFileNames.append(os.path.join(dataDir,i))

# If you want to try this with another file, change the 0 in the line below to the number of the file you want. 
with open (dataFullFileNames[0], "r") as myfile:
       participantData = pd.read_csv(myfile,sep=',')


participantData['drawingFixed'] = np.nan
participantData['drawingFixed'] = participantData['drawingFixed'].astype('object')


for index,row in participantData.iterrows():
    if pd.isna(row[row.image_list]): # If there's no image, do nothing.
        continue
    else:
         participantData.at[index,'drawingFixed'] = literal_eval(row['drawing'])


# Calculations to fix the proportions for plotting
res = participantData.loc[7,'windowSize']
res = res.strip('[]').split(',')
height = int(res[1])

plt.ioff()

def plotResponse(sampleImageIndex,height):
    
    sketch = participantData.loc[sampleImageIndex,'drawingFixed']
    px = []
    py = []
    for i,j in enumerate(sketch):
        px.append([])
        py.append([])
        for k,l in enumerate(j):
            px[i].append(l[0]*height)
            py[i].append(l[1]*height)

    fig,ax = plt.subplots(figsize=[4,4])

    plt.imshow(np.flipud(plt.imread(imFullFileNames[sampleImageIndex])), origin='lower', extent=[-height*.4,height*.4,-height*.4,height*.4])

    colors = cycle(['red','blue','green','purple','pink'])

    for i,j in enumerate(px):
        ax.plot(px[i],py[i],color=next(colors))
        ax.set_xlim(-height*.4,height*.4)
        ax.set_ylim(-height*.4,height*.4)
        
    plt.show()
    plt.close(fig)



def saveSketchAsArray(sampleImageIndex,height):
    sketch = participantData.loc[sampleImageIndex,'drawingFixed']
    px = []
    py = []
    for i,j in enumerate(sketch):
        px.append([])
        py.append([])
        for k,l in enumerate(j):
            px[i].append(l[0]*height)
            py[i].append(l[1]*height)
    

    fig,ax = plt.subplots(figsize=[4,4],dpi=200)

    fig.tight_layout(pad=0)
    plt.axis('off')
    data = np.frombuffer(fig.canvas.tostring_rgb(), dtype=np.uint8)
    data2 = data.reshape(fig.canvas.get_width_height()[::-1] + (3,))
    plt.close(fig)
    return data2


for i in range(14,20):
    plotResponse(i,height)
    data=saveSketchAsArray(i,height)
