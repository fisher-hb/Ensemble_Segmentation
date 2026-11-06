function lmWOI(filedate,mousename,scanlabels,label)

%% Decide whether or not to perform landmarking

filestem = getfilestem(filedate,mousename);

try
    load(strcat(filestem,"-segcon"),'LM')
    disp('Segcon file found: Landmarks are ready to use for segmentation')
catch
    try
        load(strcat(filestem,"-segcon",label.in),'LM')
        disp('Segcon file found: Landmarks are ready to use for segmentation')
    catch
        % try
        %     filestem = getfilestem(filedate,mousename,scanlabels{1});
        %     load(strcat(filestem,"-segment.mat"),'LM')
        %     disp('Landmarks have been selected for individual scans. Please create segcon file to use concensus landmarks')
        % catch
            % Run code to produce landmarks
            disp('Landmarks not yet selected: Running code for selection and concensus')
            LM = createLandmarks(filedate,mousename,scanlabels,label);
        % end
    end
end

% Saving Individual Scan Landmarks
filestem=getfilestem(filedate,mousename);

% Save Landmarks to Segcon File
save([filestem,'-segcon',label.out],'LM')

end


function LM = createLandmarks(filedate,mousename,scanlabels,label)

%% Loading
disp('Loading')
disp(['LANDMARKS: ',filedate,'-',mousename])

% Default LM
LMtemp=[];

conNum = min(length(scanlabels),3);

% Load QC
for i = 1:conNum
    filestem = getfilestem(filedate,mousename,scanlabels{i});
    load([filestem,'-qc',label.in],'scan','WL','mask')
    if isfile([filestem,'-scout.mat'])
        usescout=1;
        
        load([filestem,'-scout'],'scout')
     
        scout=single(scout);
        % High-resolution WL
        SWL(:,:,1)=scout(:,:,4,1)/max(max(scout(:,:,4,1))); % red
        SWL(:,:,2)=scout(:,:,2,1)/max(max(scout(:,:,2,1))); % green
        SWL(:,:,3)=scout(:,:,1,1)/max(max(scout(:,:,1,1))); % blue
    else
        usescout=0;
    end

    scan.lmuser=getenv('username');

    %% Landmarks
    
    disp('Finding Landmarks')
    
    if usescout
        if ~isempty(LMtemp)
            LMnames=fieldnames(LMtemp);
            
            for n=1:numel(LMnames)
                LMtemp.(LMnames{n})(1)=LMtemp.(LMnames{n})(1)*scan.xbin;
                LMtemp.(LMnames{n})(2)=LMtemp.(LMnames{n})(2)*scan.ybin;
            end
        end
        
        [LMtemp]=makeLM(SWL);
        
        LMnames=fieldnames(LMtemp);
        
        for n=1:numel(LMnames)
            LMtemp.(LMnames{n})(1)=LMtemp.(LMnames{n})(1)/scan.xbin;
            LMtemp.(LMnames{n})(2)=LMtemp.(LMnames{n})(2)/scan.ybin;
        end
    else
        [LMtemp]=makeLM(WL);
    end
    LM_ind(i) = LMtemp(1);
end
close all

% Create Composite Landmarks
LM = makeLM(WL,LM_ind);

end