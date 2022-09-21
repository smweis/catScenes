# -*- coding: utf-8 -*-
"""
This is a helper script to allow the attention check to be performed. 

Hoorish Abid performed the attention check for all subjects. 

The data she collected is in: /blue/stevenweisberg/share/catscenes/data/qualtricsDataClean.csv
"""

import matplotlib.pyplot as plt
from itertools import cycle
import numpy as np
import pandas as pd
import os
from ast import literal_eval

# WHERE ARE THE IMAGES

# ENTER THE NAME OF THE IMAGE TO CHECK HERE:
imageName = 'airplanecabin5.jpg'
participant = 51


# Get the current directory (directory the script is in)
workingDir = os.getcwd()
# WE WANT THIS TO BE THE DIRECTORY THAT CONTAINS ALL 1000 IMAGES. 
# Try the  pwd command in the console. 
# ..// means up a directory. 
imDir = '..//..//BOLD5000_Original\BOLD5000_Stimuli\BOLD5000_Stimuli\Scene_Stimuli\Presented_Stimuli\Scene'

# WHERE IS THE DATA
dataDir = '..//PavloviaData'
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
    imFullFileNames.append(imDir + os.path.sep + i)

#####################################
# Load in the participant data file #
#####################################

# All CSVs.
dataFileNames = [x for x in dataFiles if 'csv' in x]
dataFileNames = [x for x in dataFileNames if 'analog' in x]
dataFullFileNames = []
for i in dataFileNames:
    dataFullFileNames.append(dataDir + os.path.sep + i)

# If you want to try this with another file, change the 0 in the line below to the number of the file you want. 
with open (dataFullFileNames[participant], "r") as myfile:
       participantData = pd.read_csv(myfile,sep=',')

participantData['drawingFixed'] = np.nan
participantData['drawingFixed'] = participantData['drawingFixed'].astype('object')
imageList = participantData.iloc[(3,0)]

print('Participant ID = ' + dataFileNames[participant][0:5])
print('The Image List used is: ' + imageList)


for index,row in participantData.iterrows():
    if pd.isna(row[imageList]): # If there's no image, do nothing.
        continue
    else:
         participantData.at[index,'drawingFixed'] = literal_eval(row['drawing'])


# Calculations to fix the proportions for plotting
res = participantData.loc[9,'windowSize']
res = res.strip('[]').split(',')
height = int(res[1])




sampleImageIndex = participantData.index[participantData[imageList] == imageName].tolist()[0]

sampleImageIndexImageFile = imFileNames.index(imageName)

sketch = participantData.loc[sampleImageIndex,'drawingFixed']

def plotSanity(sketch):

    px = []
    py = []
    for i,j in enumerate(sketch):
        px.append([])
        py.append([])
        for k,l in enumerate(j):
            px[i].append(l[0]*height)
            py[i].append(l[1]*height)

    fig,ax = plt.subplots()
    plt.imshow(np.flipud(plt.imread(imFullFileNames[sampleImageIndexImageFile])), origin='lower', extent=[-height*.25,height*.25,-height*.25,height*.25])

    colors = cycle(['red','blue','green','purple','pink'])

    for i,j in enumerate(px):
        ax.plot(px[i],py[i],color=next(colors))
    
    plt.show()



plotSanity(sketch)



print(sampleImageIndex)