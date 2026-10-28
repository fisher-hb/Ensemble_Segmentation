function procWUSM_auto(filedate,mousename,scanlabel,label,varargin)

%% Load in rawdata collected from camera along with info and flags

% Get directory information
filestem=getfilestem_WUSM(filedate,mousename,scanlabel);
filestem2=getfilestem_WUSM(filedate,mousename);

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

%%
disp(['PROCESSING: ',filedate,'-',mousename,'-',scanlabel,label.in])

% Load rawdata
disp('Loading Data')
try
    load([filestem,'-rdata',label.in],'rdata','fndata','flags')
catch
    disp('** No ratio data available; qcOIS not yet performed. **')
    return
end

% Flags
[flags]=getflags(flags,'FluoroFC',varargin); %clear varargin

load([filestem,'-qc',label.in],'scan','mask','qcdata')

try
    load([filestem2,'-segcon',label.in],'isbrain')
    seg = isbrain; 
catch
    load([filestem,'-segment'],'mask')
    seg = logical(mask.guided); % prevent overwrite
end

mask.guided=seg; clear seg

if ~any(any(any(mask.tot)))
    disp('** No data passed QC thresholds. Further analysis not possible. **')
    return
end

%% Filtering and Resampling
% % {
disp('Filtering and Resampling')
% Find out image series length (in time) after resampling (allows initializing of matrices properly)

%% REMOVE LATER
scan.ER = 30.1205;
%% REMOVE LATER

testpixel=resampledata(double(squeeze(rdata(1,1,:,:))),scan.ER,flags.freqout_hb,10^-5);
scan.T2H=size(testpixel,2);
scan.framerate_hb=flags.freqout_hb;
clear testpixel

% Filter
rdata_rs=zeros(scan.Px*scan.Py,scan.hbled,scan.T2H,'like',rdata); % initialize
rdata=reshape(rdata,scan.Px*scan.Py,scan.hbled,scan.T1);

% Loop over pixels (as this is very memory intensive)
parfor p=1:scan.Px*scan.Py
    % pull out pixel data
    pixdata=double(squeeze(rdata(p,:,:)));
    
    % Highpass, Lowpass, and Downsample
    rdata_rs(p,:,:)=fcfilt(pixdata,scan.ER,flags.freqout_hb,flags.highpass_hb,flags.lowpass_hb);
end
rdata_rs=reshape(rdata_rs,scan.Px,scan.Py,scan.hbled,scan.T2H);

% Filter Fluoro
if any(scan.exled)
    testpixel=resampledata(double(squeeze(fndata(1,1,:))),scan.ER,flags.freqout_f,10^-5);
    scan.T2F=size(testpixel,2);
    scan.framerate_f=flags.freqout_f;
    clear testpixel

    % Filter
    fndata_rs=zeros(scan.Px*scan.Py,scan.T2F,'like',rdata); % initialize
    fndata=reshape(fndata,scan.Px*scan.Py,scan.T1);

    % Loop over pixels (as this is very memory intensive)
    parfor p=1:scan.Px*scan.Py
        % pull out pixel data
        pixdata=double(squeeze(fndata(p,:,:)));

        % Highpass, Lowpass, and Downsample
        fndata_rs(p,:,:)=fcfilt(pixdata,scan.ER,flags.freqout_f,flags.highpass_f,flags.lowpass_f);
    end
    fndata_rs=reshape(fndata_rs,scan.Px,scan.Py,scan.T2F);
end
%}
% rdata_rs=rdata;

%%
disp('Spatial Smoothing')

% qcdata.sigma=qcdata.stdmua;
[rdata_sm,masksmooth_hb]=smoothimage(rdata_rs,mask,flags,scan);
mask.smooth_hb=masksmooth_hb;

if any(scan.exled)
    [fndata_sm,masksmooth_f]=smoothimage(fndata_rs,mask,flags,scan);
    mask.smooth_f=masksmooth_f;
else
    fndata_sm=[];
    mask.smooth_f=[];
end


%% Spectroscopy (Wavelength Censoring)
disp('Spectroscopy')


mask.comb=zeros(scan.Px,scan.Py,scan.hbled,'logical');
for c=1:scan.hbled
    mask.comb(:,:,c)=mask.smooth_hb(:,:,c).*mask.guided;
end

try
    [datahb,isbrain]=WOI_hb_spect(rdata_sm,mask.comb,scan);
catch
    scan.ledlambda = [470,530,625];
    [datahb,isbrain]=WOI_hb_spect(rdata_sm,mask.comb,scan);
end

mask.spect=logical(isbrain);

%% Fluorescence Correction
% if ~isempty(dataff)
%     disp('Fluorescence Correction')
%     gcampcorrect(dataff,datahb,E,op,scan)
% 
% end
fdata=fndata_sm;
mask.fluoro=mask.smooth_f;

%%
disp('Saving')
scan.procdate=date;
try
    save([filestem,'-qc',label.out],'qcdata','mask','scan','-append')
catch
end

save([filestem,'-datahb',label.out],'datahb','fdata','scan','flags','-v7.3')

end

function [data]=fcfilt(data,FR,freqout,HP,LP)

% Highpass and Lowpass
if HP
data=highpass(data,HP,FR);
end
if LP
data=lowpass(data,LP,FR);
end

% Downsample
data=resampledata(data,FR,freqout,10^-5);

end