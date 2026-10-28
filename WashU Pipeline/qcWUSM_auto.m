function qcWUSM_auto(filedate,mousename,scanlabel,label,varargin)
% Quality Control for OIS Data
% Uses Pixel-Wise Quality Metrics

%% Loading
disp(['QUALITY CONTROL: ',filedate,'-',mousename,'-',scanlabel])
disp('Loading')

% Get directory information
filestem=getfilestem_WUSM(filedate,mousename,scanlabel);

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
[flags]=getflags([],'qcdefault_WUSM',varargin);


% Load Data
try
    load([filestem,'-rawdata']);
    load([filestem,'-scan'])
catch
    try
        rawdata=loaddata(filedate,mousename,scanlabel);
        load([filestem,'-scan'])
    catch
        disp('File not found, please confirm entry spelling')
        return
    end
end

if ~isfield(scan,'exled')
    scan.exled=zeros(1,scan.numled);
end

scan.hbled=sum(~scan.exled);

% Create White-Light Image from first frame
frameone=double(rawdata(:,:,:,40));

if contains(mousename,'NWB') || contains(mousename, 'R88')
    WL(:,:,1)=frameone(:,:,4)/max(max(frameone(:,:,4))); % red
    WL(:,:,2)=frameone(:,:,2)/max(max(frameone(:,:,2))); % green
    WL(:,:,3)=frameone(:,:,1)/max(max(frameone(:,:,1))); % blue

    imdata(:,:,1)=frameone(:,:,1)/max(max(frameone(:,:,1))); % 470
    imdata(:,:,2)=frameone(:,:,2)/max(max(frameone(:,:,2))); % 525
    imdata(:,:,3)=frameone(:,:,3)/max(max(frameone(:,:,3))); % 525
    imdata(:,:,4)=frameone(:,:,4)/max(max(frameone(:,:,4))); % 525

elseif contains(mousename,'NE') || contains(mousename,'N4') || contains(mousename, 'N6')
    WL(:,:,1)=frameone(:,:,2)/max(max(frameone(:,:,2))); % red
    WL(:,:,2)=frameone(:,:,1)/max(max(frameone(:,:,1))); % green
    WL(:,:,3)=frameone(:,:,1)/max(max(frameone(:,:,1))); % blue

    imdata(:,:,1)=frameone(:,:,1)/max(max(frameone(:,:,1))); % 525
    imdata(:,:,2)=frameone(:,:,2)/max(max(frameone(:,:,2))); % 625
    imdata(:,:,3)=frameone(:,:,3)/max(max(frameone(:,:,3))); % 525
else
    WL(:,:,1)=frameone(:,:,3)/max(max(frameone(:,:,3))); % red
    WL(:,:,2)=frameone(:,:,2)/max(max(frameone(:,:,2))); % green
    WL(:,:,3)=frameone(:,:,2)/max(max(frameone(:,:,2))); % blue

    imdata(:,:,1)=frameone(:,:,1)/max(max(frameone(:,:,1))); % 470
    imdata(:,:,2)=frameone(:,:,2)/max(max(frameone(:,:,2))); % 525
    imdata(:,:,3)=frameone(:,:,3)/max(max(frameone(:,:,3))); % 625
end

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
    if sum(scan.exled) > 1
        std_fndata=std(fndata,0,3);
        qcdata.stdr(:,:,logical([1,0,0,0]))=std_fndata(:,:,1);
        qcdata.stdr(:,:,logical([0,0,1,0]))=std_fndata(:,:,2);
    else
        qcdata.stdr(:,:,scan.exled==1)=std(fndata,0,3);
    end
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
save([filestem,'-qc',label.out],'WL','mask','qcdata','calib','scan','flags','imdata')

end


%% ___________________________ Load Data _______________________________ %%

function rawdata = loaddata(filedate,mousename,scanlabel)

filestem = getfilestem_WUSM(filedate,mousename,scanlabel);

try
    load([filestem,'-scan.mat']);
catch
    createScanFile(filedate,mousename,scanlabel);
    load([filestem,'-scan.mat']);
end

disp('- Images from .mat')
load([filestem,'_raw.mat']);

switch ndims(raw)
    case 3
        % How many frames are available?
        scan.T1=size(raw,3)/scan.numled;
        
        % Reshape: X x Y x Color x Time
        raw=reshape(raw,scan.Px,scan.Py,scan.numled,scan.T1);

        rawdata=raw(:,:,:,300:9336);
        rawdata=single(rescale(rawdata,100,10000));

        scan.T1=size(rawdata,3)/scan.numled;
        
    case 4
        if contains(mousename,'NE') || contains(mousename,'N4') || contains(mousename, 'N6')
            rawdata=raw(:,:,1:3,300:9336);
        else
            rawdata=raw(:,:,:,300:9336);
        end
        rawdata=single(rescale(rawdata,100,10000));
        
        scan.T1=size(rawdata,4);
end

rawdata = rot90(rot90(rot90(rawdata)));

% Save rawdata
save([filestem,'-rawdata'],'rawdata','-v7.3')
save([filestem,'-scan'],'scan')

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

%% _______________________ Create Scan File ____________________________ %%

function scan = createScanFile(filedate,mousename,scanlabel)
    
    scan.sdk = 'SDK3';
    scan.xbin = 8;
    scan.ybin = 8;
    scan.aoix = 1024;
    scan.aoiy = 1024;
    scan.framerate = 120;
    scan.texp = 0.002;
    scan.sr = 10000;
    scan.outv = 3;
    scan.system = 'WASHU';
    scan.filedate = filedate;
    scan.mousename = mousename;
    scan.scanlabel = scanlabel;
    scan.ST = 300;
    scan.Px = 128;
    scan.Py = 128;
    scan.bd = 16;
    scan.ER = 30.125;

    if contains(mousename,'NWB') || contains(mousename, 'R88')
        scan.numled = 4;
        scan.ledtime = [0.7500,0.7500,0.7500,0.7500];
        scan.ledmax = [1000,1000,1000,1000];
        scan.ledlambda = [470,525,525,625];
        scan.exled = [1,0,1,0];
    elseif contains(mousename,'NE') || contains(mousename,'N4') || contains(mousename, 'N6')
        scan.numled = 3;
        scan.ledtime = [0.7500,0.7500,0.7500];
        scan.ledmax = [1000,1000,1000];
        scan.ledlambda = [525,625,525];
        scan.xled = [0,0,1];
    else
        scan.numled = 3;
        scan.ledtime = [0.7500,0.7500,0.7500];
        scan.ledmax = [1000,1000,1000];
        scan.ledlambda = [470,535,625]; 
        scan.xled = [1,0,0];
    end

    filestem = getfilestem_WUSM(filedate,mousename,scanlabel);

    % Save scan file
    save([filestem,'-scan'],'scan')
end