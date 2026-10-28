%% _________________________ Auto Segment Data _________________________ %%
%
% Author: Hayden Fisher
% Children's Hospital of Philadelphia
% Date: March 20, 2026
%
%% _____________________________________________________________________ %%

function autoSegment(varargin)

% Read in definition file
params = readDefFile('System_Definitions.txt');

% Assign variables based on input parameters
% filename = [params.indir_test,'\',varargin{2}];
filename = [params.indir_test, '\', '260319-1355a1m122-fc2.mat'];

% Load data
disp("... Loading Data ...")
load(filename);

% Confirm System Definition Accuracy
if params.im_size ~= size(rawdata,1)
    error("Error: Image size does not match IM_SIZE specified in system definition file")
elseif size(params.wavelengths,2) ~= size(rawdata,3)
    error("Error: Number of wavelengths does not match length of WAVELENGTHS in system definition file")
end

%% _______________________ Define Networks to Use ______________________ %%

for i = 1:size(params.wavelengths,2)
    if params.include(i)
        networks{i} = load(strcat('network_',string(params.wavelengths(i)),'nm.mat'));
    end
end

%% ___________________ Create Images for Segmentation __________________ %%



%% __________________ Run Quality Control on All Scans _________________ %%
% 
% try
%     for i = 1:length(scanlabels)
%         filestem = getfilestem(filedate,mousename,scanlabels{length(scanlabels)});
%         qcTest = load(strcat(filestem,"-qc",autoLabel),'WL');
%     end
%     clear qcTest
%     userResponse = input('QC files already exist, do you wish to rerun QC? (y/n): ', 's');
%     if contains(lower(userResponse),'y')
%         for i = 1:length(scanlabels)
%             disp('Rerunning Quality Control')
%             qcWOI_auto(filedate,mousename,scanlabels{i},qclabel)
%         end
%     end
% catch
%     for i = 1:length(scanlabels)
%         qcWOI_auto(filedate,mousename,scanlabels{i},qclabel)
%     end
% end
% 
% %% _________________ Create Landmarks and Segmentation _________________ %%
% 
% try
%     iblmTest = load(strcat(filestem,"-segcon",autoLabel),'LM');
%     clear iblmTest
%     userResponse = input('Segmentation files already exist, do you wish to rerun? (y/n): ', 's');
%     if contains(lower(userResponse),'y')
%         disp('Rerunning Segmentation')
%         makeIBLM_auto(filedate,mousename,scanlabels,label)
%     end
% catch
%     makeIBLM_auto(filedate,mousename,scanlabels,label)
% end
% 
% end