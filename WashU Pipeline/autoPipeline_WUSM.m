%% ______ Function for Automated Segmentation Pipeline Processing ______ %%

function returns = autoPipeline_WUSM(filedate,mousename,scanlabel,label)

%% __________________ Run Quality Control on All Scans _________________ %%

% Define QC label input so data directly from scanner is used
% qclabel.in = ''; qclabel.out = label.out;

% try
%     filestem = getfilestem_WUSM(filedate,mousename,scanlabel);
%     qcTest = load(strcat(filestem,"-qc-",label.in),'WL');
%     clear qcTest
%     userResponse = input('QC file already exists, do you wish to rerun QC? (y/n): ', 's');
%     if contains(lower(userResponse),'y')
%         disp('Rerunning Quality Control')
%         qcWUSM_auto(filedate,mousename,scanlabel,qclabel)
%     end
% catch
%     qcWUSM_auto(filedate,mousename,scanlabel,qclabel)
% end
% 
% close all

%% _________________ Create Landmarks and Segmentation _________________ %%

% try
%     filestem = getfilestem_WUSM(filedate,mousename);
%     iblmTest = load(strcat(filestem,"-segcon-",label.in),'LM');
%     clear iblmTest
%     userResponse = input('Segmentation files already exist, do you wish to rerun? (y/n): ', 's');
%     if contains(lower(userResponse),'y')
%         disp('Rerunning Segmentation')
%         makeIBLM_WUSM_auto(filedate,mousename,scanlabel,label)
%     end
% catch
%     makeIBLM_WUSM_auto(filedate,mousename,scanlabel,label)
% end

makeIBLM_WUSM_auto(filedate,mousename,scanlabel,label)

% %% ______________________ Visualize Segmentation _______________________ %%
% 
% try
%     display(mousename)
%     displaySeg(filedate,mousename,scanlabel,label)
%     userResponse = input('Display next figure? (y/n): ', 's');
% catch
%     disp('Could not display segmentation');
% end

returns = displaySeg(filedate,mousename,scanlabel,label);

% %% _________________ Run Post Processing on All Scans __________________ %%
% 
% try
%     filestem = getfilestem_WUSM(filedate,mousename,scanlabel);
%     fcTest = load(strcat(filestem,"-fchbt-",label.in),'RG');
%     clear fcTest
%     userResponse = input('Post Processing files already exist, do you wish to rerun? (y/n): ', 's');
%     if contains(lower(userResponse),'y')
%         disp('Rerunning Post Processing')
%         procWUSM_auto(filedate,mousename,scanlabel,label)
%         affWUSM_auto(filedate,mousename,scanlabel,label)
%         fcWUSM_auto(filedate,mousename,scanlabel,label)
%     end
% catch
%     procWUSM_auto(filedate,mousename,scanlabel,label)
%     affWUSM_auto(filedate,mousename,scanlabel,label)
%     fcWUSM_auto(filedate,mousename,scanlabel,label)
% end

end