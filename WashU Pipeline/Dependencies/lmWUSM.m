function lmWUSM(filedate,mousename,scanlabel,label)

%% Decide whether or not to perform landmarking

filestem = getfilestem_WUSM(filedate,mousename);

try
    load(strcat(filestem,"-segcon"),'LM')
    disp('Segcon file found: Landmarks are ready to use for segmentation')
catch
    try
        load(strcat(filestem,"-segcon",label.in),'LM')
        disp('Segcon file found: Landmarks are ready to use for segmentation')
    catch
        try
            filestem = getfilestem_WUSM(filedate,mousename,scanlabel);
            load(strcat(filestem,"-segment.mat"),'LM')
            disp('Landmarks have been selected for individual scans. Please create segcon file to use concensus landmarks')
        catch
            % Run code to produce landmarks
            disp('Landmarks not yet selected: Running code for selection and concensus')
            LM = createLandmarks(filedate,mousename,scanlabel,label);
        end
    end
end

% Saving Individual Scan Landmarks
filestem=getfilestem_WUSM(filedate,mousename);

% Save Landmarks to Segcon File
save([filestem,'-segcon',label.out],'LM')

end


function LM = createLandmarks(filedate,mousename,scanlabel,label)

%% Loading
disp('Loading')
disp(['LANDMARKS: ',filedate,'-',mousename])

% Load QC

filestem = getfilestem_WUSM(filedate,mousename,scanlabel);
load([filestem,'-qc',label.in],'scan','WL')

scan.lmuser=getenv('username');

%% Landmarks

disp('Finding Landmarks')

    LM=makeLM(WL);

close all

end