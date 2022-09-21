# -*- coding: utf-8 -*-
"""
Created on Thu Dec 31 13:43:17 2020

@author: smwei
"""
         
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import scipy.io
import seaborn as sns
import pingouin as pg

#####################################
# Next steps of processing          #
#####################################
masterData = pd.read_csv("..//masterData.csv")
drawingData = pd.read_csv("..//drawingData.csv")
analogCorrMatrix = pd.read_csv("..//analogCorrMatrix.csv",header=0,index_col=0)
lingCorrMatrix = pd.read_csv("..//lingCorrMatrix.csv",header=0,index_col=0)


lingDirections = masterData.groupby(['presentedImage'])['ahead','right','left','sharp_right','slight_right','slight_left','sharp_left'].mean()


#analogCorrMatrix = drawingData.corr()
analogCorrMatrix.sort_index(inplace=True,axis=0)
analogCorrMatrix.sort_index(inplace=True,axis=1)
analog = analogCorrMatrix.to_numpy()
analog1D = np.reshape(analog,analog.size)

#lingCorrMatrix = lingDirections.T.corr()
lingCorrMatrix.sort_index(inplace=True,axis=0)
lingCorrMatrix.sort_index(inplace=True,axis=1)
ling = lingCorrMatrix.to_numpy()
ling1D = np.reshape(ling,ling.size)




plt.imshow(lingCorrMatrix)

plt.imshow(analogCorrMatrix)

presentedImages = pd.DataFrame(masterData['presentedImage'].unique()).dropna()


dataForPartial = np.array([analog1D,ling1D])
dfPartial = pd.DataFrame({'analog':dataForPartial[0,:],'ling':dataForPartial[1,:]})

def loadSubjectBrainData(subject,TR):
    stimListSubjID = subject[:3] + '0' + subject[3:]
    subjMat = scipy.io.loadmat('..\\..\\BOLD5000_Original\\BOLD5000_ROIs\\ROIs\\'
                               + subject + '\\mat\\' 
                               + subject + '_ROIs_TR' + TR + '.mat')
    stimList = pd.read_csv('..\\..\\BOLD5000_Original\\BOLD5000_ROIs\\ROIs\\stim_lists\\' + 
                           stimListSubjID + '_stim_lists.txt', header=None)
    return subjMat,stimList

def calculateBrainBehaviorCorrelations(subjects, TRs, brainRegions):
    global ling1D, analog1D, presentedImages
    
    # Create multi-index
    subjectsInd = np.repeat(subjects,len(TRs))
    TRsInd = np.tile(TRs,len(subjects))
    behavioralInd = np.tile(['analog','ling','partial'],len(TRs)*len(subjects))
    arrays = [subjectsInd,TRsInd,behavioralInd]
    tuples = list(zip(*arrays))
    index = pd.MultiIndex.from_tuples(tuples, names=["subjects", "TRs", "behavioralMeasure"])
    
    brainCorr = pd.DataFrame(columns=brainRegions,index=index)
    
    for subject in subjects:        
        print(subject)
        for TR in TRs:
            print(TR)
            subjMat,stimList = loadSubjectBrainData(subject,TR)            
            for region in brainRegions:
                regionMat = pd.DataFrame(subjMat[region].T,columns=stimList.iloc[:,0])
                regionMat = regionMat[regionMat.columns.intersection(presentedImages.iloc[:,0])]
                regionCorr = regionMat.corr()
                regionCorr.sort_index(inplace=True,axis=0)
                regionCorr.sort_index(inplace=True,axis=1)
                regionCorrNP = regionCorr.to_numpy()
                regionCorr1D = np.empty(regionCorrNP.size)
                regionCorr1D = np.reshape(regionCorrNP,regionCorrNP.size)
                
                dfPartial['brain'] = regionCorr1D
                
                brainCorr.at[(subject,TR,'analog'),region] = np.corrcoef(analog1D,regionCorr1D)[0,1]
        
                brainCorr.at[(subject,TR,'ling'),region] = np.corrcoef(ling1D,regionCorr1D)[0,1]
                
                brainCorr.at[(subject,TR,'partial'),region] = pg.partial_corr(data=dfPartial, 
                                                                             x='analog', 
                                                                             y='brain', 
                                                                             covar='ling').round(3).r.pearson
    return brainCorr
    



subjects = ['CSI1','CSI2','CSI3']

TRs = ['1','2','3','4','5','34']

brainRegions = ['LHEarlyVis','RHEarlyVis','LHOPA','RHOPA','LHPPA','RHPPA','LHRSC','RHRSC']



brainCorr = calculateBrainBehaviorCorrelations(subjects, TRs, brainRegions)

col = brainCorr.loc[: , ["LHEarlyVis","RHEarlyVis"]]
brainCorr['EVC_mean'] = col.mean(axis=1)

col = brainCorr.loc[: , ["LHOPA","RHOPA"]]
brainCorr['OPA_mean'] = col.mean(axis=1)

col = brainCorr.loc[: , ["LHPPA","RHPPA"]]
brainCorr['PPA_mean'] = col.mean(axis=1)

col = brainCorr.loc[: , ["LHRSC","RHRSC"]]
brainCorr['RSC_mean'] = col.mean(axis=1)

brainCorrBiLat = brainCorr[['EVC_mean', 'OPA_mean','PPA_mean','RSC_mean']].copy()

brainCorr.drop(['EVC_mean', 'OPA_mean','PPA_mean','RSC_mean'],axis=1,inplace=True)

brainCorrToPlot=brainCorr.stack([0]).reset_index(name='correlation')
brainCorrToPlot.correlation = brainCorrToPlot.correlation.astype(float)
brainCorrToPlot.rename(columns={'level_3':'ROI'},inplace=True)


brainCorrBiLatToPlot=brainCorrBiLat.stack([0]).reset_index(name='correlation')
brainCorrBiLatToPlot.correlation = brainCorrBiLatToPlot.correlation.astype(float)
brainCorrBiLatToPlot.rename(columns={'level_3':'ROI'},inplace=True)



fig1 = sns.lineplot(x="TRs", y="correlation",
             hue="ROI",style='behavioralMeasure'
             ,data=brainCorrToPlot)


fig2 = sns.lineplot(x="TRs", y="correlation",
             hue="ROI",style='behavioralMeasure'
             ,data=brainCorrBiLatToPlot,legend=False)






