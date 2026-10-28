function qcWOI_auto(filedate,mousename,scanlabel,label,varargin)
% Quality Control for OIS Data
% Uses Pixel-Wise Quality Metrics

%% Loading
disp(['QUALITY CONTROL: ',filedate,'-',mousename,'-',scanlabel])
disp('Loading')

% Get directory information
filestem=getfilestem(filedate,mousename,scanlabel);

if ~exist('label') || isempty(label) || isempty(label.out) 
    label.out='';
else
    label.out=['-',label.out];
end
if ~exist('label') || ~isfield(label,'in') || isempty(label.in)
    label.in='';
else
    label.in=['-',label.in];
end

% Flags
[flags]=getflags([],'qcdefault',varargin);

% Load Data
try
    [rawdata,scan]=loaddata(filestem);
catch
    disp('File not found, please confirm entry spelling')
end

if ~isfield(scan,'exled')
    scan.exled=zeros(1,scan.numled);
end

scan.hbled=sum(~scan.exled);

% Create White-Light Image from first frame
frameone=double(rawdata(:,:,:,1));
WL(:,:,1)=frameone(:,:,4)/max(max(frameone(:,:,4))); % red
WL(:,:,2)=frameone(:,:,2)/max(max(frameone(:,:,2))); % green
WL(:,:,3)=frameone(:,:,1)/max(max(frameone(:,:,1))); % blue

%% Dark Count Removal

if exist('dark','var')

else
    % Load Calibration File
    % Contains dark level of camera
    try
        calib=readkeyfile([scan.system,'_calib']);
    catch
        calib.offset=0;
    end

    dark=calib.offset*ones(scan.Px,scan.Py);
end

%% Initial QC
disp('QC: Saturation')

% Maximum data at each pixel over time
qcdata.max=max(rawdata,[],4);

% Exclude saturated pixels
mask.sat=logical(qcdata.max<(2^scan.bd-1));

%% Calibration
disp('Dark Noise Correction')
rawdata=rawdata-repmat(dark,1,1,scan.numled,scan.T1);

% Reset for pixels at noise floor
rawdata(rawdata<0)=0;

% Mean value at each pixel over time
qcdata.mean=mean(rawdata,4);

%% Detrending
disp('Detrending')

% Remove Linear Trend (keep mean value)
% rawdata2=detdata(rawdata);
rawdata2=permute(detrend(permute(rawdata,[4 1 2 3])),[2 3 4 1]);
rawdata2=rawdata2+qcdata.mean;

%% Noise Floor Mask
disp('QC: Noise Floor')

% Remove data that ends up below floor
if numel(flags.lambda_min) == 1
    flags.lambda_min=repmat(flags.lambda_min,1,scan.numled);
end

for c=1:scan.numled
    qcdata.floor(:,:,c)=sum(rawdata2(:,:,c,:)<flags.lambda_min(c),4); % Count pixels below floor
    mask.floor(:,:,c)=all(rawdata2(:,:,c,:)>flags.lambda_min(c),4); % Mask pixels that ever drop below floor
end

rawdata2(rawdata2<0)=0;

mask.zeronan=~any(rawdata2==0,4);

%% Beer-Lambert
disp('Ratiometric Data')
% Log-Ratio data: For Hb data
lrdata=logmean(rawdata2(:,:,~scan.exled,:),logical(mask.zeronan(:,:,~scan.exled).*mask.sat(:,:,~scan.exled)),scan,flags);
rdata=diffdata(rawdata2(:,:,~scan.exled,:),qcdata.mean(:,:,~scan.exled),logical(mask.zeronan(:,:,~scan.exled).*mask.sat(:,:,~scan.exled)),scan);

% Fluorescence Data: Ratio fluorescence data (not hb-corrected)
if any(scan.exled)
    fndata=diffdata(rawdata2(:,:,scan.exled==1,:),qcdata.mean(:,:,scan.exled==1),logical(mask.zeronan(:,:,scan.exled==1).*mask.sat(:,:,scan.exled==1)),scan);
else
    fndata=[];
end

disp('Saving Ratio-Data')
save([filestem,'-rdata',label.out],'rdata','lrdata','fndata','flags','scan','-v7.3')

%% SNR
disp('QC: Signal Variance')

% Standard Deviations at each pixel over time
qcdata.std=std(rawdata2,0,4); % After detrending

if any(scan.exled)
    qcdata.stdr=zeros(scan.Px,scan.Py,scan.numled,'like',rawdata);
    qcdata.stdr(:,:,~scan.exled)=std(rdata,0,4);
    qcdata.stdr(:,:,scan.exled==1)=std(fndata,0,3);
else
    % qcdata.stdlr=std(lrdata,0,4);
    qcdata.stdr=std(rdata,0,4);
end

if numel(flags.lambda_std) == 1
    flags.lambda_std=repmat(flags.lambda_std,1,scan.numled);
end

for c=1:scan.numled
    mask.std(:,:,c)=qcdata.stdr(:,:,c)<flags.lambda_std(c);
end

%% Local Correlations
disp('QC: Local Correlations')

% Sqrt(mean) of each pixel over time (for Poisson-like noise assumption)
qcdata.sqroot=sqrt(qcdata.mean);

% Local Correlations
qcdata.rlocal=localcorr(rawdata2,scan);

% Must meet threshold
if numel(flags.lambda_rlocal) == 1
    flags.lambda_rlocal=repmat(flags.lambda_rlocal,1,4);
end

for c=1:scan.numled
    mask.corr(:,:,c)=all(qcdata.rlocal(:,:,c)>=flags.lambda_rlocal(c),4);
end


%%

% Combine Masks
mask.tot=logical(mask.sat.*mask.std.*mask.corr.*mask.floor);

%% Display Figures
if flags.dispfig
    viewqc(qcdata,mask,WL,scan,calib)
end

%% Saving

% Record date processing occured
scan.qcdate=date;

disp('Saving')
save([filestem,'-qc',label.out],'WL','mask','qcdata','calib','scan','flags')

end

function [rawdata,scan]=loaddata(filestem)

if isfile([filestem,'-rawdata.mat']) % If data already loaded, don't read .tif again
    disp('- rawdata from .mat')
    load([filestem,'-rawdata.mat'],'rawdata') % Don't read in prior flags (if present)
    load([filestem,'-scan.mat']);
    if ~isfield(scan,'system')
        scan.system='CHOP1Andor';
    end
   
elseif isfile([filestem,'-images.mat']) % SDK3 output
    disp('- Images from .mat')
    load([filestem,'-images.mat'])
    load([filestem,'-scan.mat']);
    
    switch ndims(rawdata)
        case 3
            % How many frames are available?
            scan.T1=size(rawdata,3)/scan.numled;
            
            % Reshape: X x Y x Color x Time
            rawdata=reshape(rawdata,scan.Px,scan.Py,scan.numled,scan.T1);
            
        case 4
            scan.T1=size(rawdata,4);
    end
    
    % convert from uint16 to single to allow fractions
    rawdata=single(rawdata);
    
    % Save rawdata
    save([filestem,'-rawdata'],'rawdata','-v7.3')
    save([filestem,'-scan'],'scan')
    
else % Then read in .tif file
    
    if ~isfile([filestem,'.tif'])
        disp('*** Requested File Not Found ***')
        return
    end
    
    disp('- Images from .tif')
    
    % Read in rawdata
    [rawdata,iminfo]=readtiff([filestem,'.tif']);
    
    % Load Scan File
    if isfile([filestem,'-scan.mat']) % If using runOISAndor() and Andor SDK
        clear iminfo
        
        load([filestem,'-scan.mat']);
        
        if exist('syst') % If using old version of runOISAndor()
            scan=mergestruct(scan,syst);
        end
        
        if ~isfield(scan,'system')
            scan.system='CHOP1Andor';
        end
        
    else % If using runOIS() and Solis -- then scan isn't automatically created
        scan.system='CHOP1';
        scan=mergestruct(scan,readkeyfile([scan.system,'.txt']));
        
        scan.Px=iminfo.Width;
        scan.Py=iminfo.Height;
        clear iminfo
        
        scan.ER=29.76;
        scan.bd = 14;
        scan.numled = 4;
        scan.AF=size(rawdata,3);
    end
    
    if scan.AF ~= size(rawdata,3)
        disp('** Mismatch between .tif size and expected number of frames. The .tif may be corrupt. **')
        return
    end
    
    % cut off bad initial frames
    % THIS IS SDK2 ONLY -- if SDK3 ever saves as .tif, this needs to change!
    rawdata=rawdata(:,:,2:end); % remove "dummy" frame
    rawdata=rawdata(:,:,(flags.trimframes*scan.numled+1):end); % remove full trimframes
    
    if mod(size(rawdata,3),4)
        disp('** Irregular number of acquired frames. The .tif may be corrupt. **')
        return
    end
    
    % How many frames are available?
    scan.T1=size(rawdata,3)/scan.numled;
    
    % Reshape: X x Y x Color x Time
    rawdata=reshape(rawdata,scan.Px,scan.Py,scan.numled,scan.T1);
    
    % convert from uint16 to single to allow fractions
    rawdata=single(rawdata);                                                                                        
    
    % Save rawdata
    save([filestem,'-rawdata'],'rawdata','-v7.3')
    save([filestem,'-scan'],'scan')
end

if ~isfield(scan,'filedate') % Backwards compatability
    temp=split(filestem,'\');
    
    filename=temp{end};
    
    fileparts=split(filename,'-');
    
   scan.filedate=fileparts{1};
   scan.mousename=fileparts{2};
   scan.scanlabel=fileparts{3};
   save([filestem,'-scan'],'scan')
end

end