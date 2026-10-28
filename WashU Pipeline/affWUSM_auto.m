function affWUSM_auto(filedate,mousename,scanlabel,label,varargin)

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

% imwarp crash work-around
iptsetpref('UseIPPL',false);

%%
disp('Loading')
% Standard directory info
filestem=getfilestem_WUSM(filedate,mousename,scanlabel);
filestem_base=getfilestem_WUSM(filedate,mousename);

% Load reference positions
ref=readkeyfile('Reference.txt');

% load Mask
load([filestem,'-qc',label.in],'WL','mask')

% load scan
try
    load([filestem,'-datahb',label.in],'scan','flags')
catch
    disp('** No processed data available; procOIS not yet performed. **')
    return
end


% Flags
[flags]=getflags(flags,'StandardFC',varargin);

% Load LM
if isfield(flags,'LMmeth')
    switch flags.LMmeth
        case 'scout'
            load([filestem_base,'-scout'],'scoutLM');
            LM.ams=scoutLM.ams/4;
            LM.lambda=scoutLM.lambda/4;
            scan.LMmeth='scout';
        case 'segcon'
            temp=load([filestem_base,'-segcon',label.in]);
            if ~ismember(scanlabel,temp.scanlabel) % If -segcon doesn't apply
                load([filestem,'-segment',label.in],'LM') % load individual LM
            else
                LM=temp.LM; clear temp
            end % else keep LM from -segcon
            scan.LMmeth='segcon';
        case 'individual'
            load([filestem,'-segment',label.in],'LM')
            scan.LMmeth='individual';
    end
else
    if exist([filestem_base,'-scout.mat'],'file')
        load([filestem_base,'-scout'],'scoutLM','scoutkey');

        if ~isfield(scoutkey,'scoutexclude')
            LM.ams=scoutLM.ams/4;
            LM.lambda=scoutLM.lambda/4;
            scan.LMmeth='scout';
            
        elseif ismember(scanlabel,scoutkey.scoutexclude) % If -scout doesn't apply
            load([filestem,'-segment',label.in],'LM') % load individual LM
            scan.LMmeth='individual';
            
        else
            LM.ams=scoutLM.ams/4;
            LM.lambda=scoutLM.lambda/4;
            scan.LMmeth='scout';
        end
        
    elseif exist([filestem_base,'-segcon',label.in,'.mat'],'file')
        temp=load([filestem_base,'-segcon',label.in]);
        
        if ~ismember(scanlabel,temp.scanlabel) % If -segcon doesn't apply
            load([filestem,'-segment',label.in],'LM') % load individual LM
             scan.LMmeth='individual';
        else
            LM=temp.LM; clear temp
             scan.LMmeth='segcon';
        end % else keep LM from -segcon
         
    else % if no -segcon
        load([filestem,'-segment',label.in],'LM')
        scan.LMmeth='individual';
    end
end

%%
disp('Creating Affine Transforms')
% Define midpoints
ref.mid=(ref.ams+ref.lambda)/2;
LM.mid=(LM.ams+LM.lambda)/2;

% Make matrices of points to define transforms
A=[ref.ams;ref.lambda]; % Ref points
M=[LM.ams;LM.lambda]; % Mouse points

% Pad with ones (augmented coordinates) -- needed for affine transforms
% Aaug=cat(2,A,[1;1]);
% Maug=cat(2,M,[1;1]);

% Translation Matrices
% For Points
T_lm=[1 0 0 ; 0 1 0 ; -LM.mid 1]; % LM midpoint -> Origin
T_ref=[1 0 0 ; 0 1 0 ; ref.mid 1]; % Origin -> Ref midpoint
% For Images
Ti_lm=[1 0 0 ; 0 1 0 ; -LM.mid(2) -LM.mid(1) 1]; % LM midpoint -> Origin
Ti_ref=[1 0 0 ; 0 1 0 ; ref.mid(2) ref.mid(1) 1]; % Origin -> Ref midpoint

% Rotation matrix
% For Points
phi=atan2(LM.ams(1)-LM.lambda(1),LM.ams(2)-LM.lambda(2));
Rp=[cos(phi) sin(phi) 0 ; -sin(phi) cos(phi) 0 ; 0 0 1];
% For Images
theta=-phi;
Ri=[cos(theta) sin(theta) 0 ; -sin(theta) cos(theta) 0 ; 0 0 1];

% Scale Factors
slm=norm(A(1,:)-A(2,:))/norm(M(1,:)-M(2,:));
% Scale Matrices
S_lm=diag([slm,slm,1]);

% Overall Affine
M2Ap=T_lm*Rp*S_lm*T_ref;
M2Ai=Ti_lm*Ri*S_lm*Ti_ref;

% Make affine transform for Matlab
tformi=affine2d(M2Ai);

% Make image cropping for matlab
imcoord = imref2d([scan.Px scan.Py]);

%%
disp('Affine transforming WL and isbrain')

% Apply transform to WL & isbrain
WLt = imwarp(WL,tformi,'cubic','OutputView',imcoord);

%%
disp('Testing')
load('seeds.mat','seeds','seednames')
% seednames=fieldnames(seeds);
% side=fieldnames(seeds.(seednames{1}));
numseeds=numel(seednames);

isbrain=mask.guided;

[pax]=PaxAtlas;

[PIm]=MousePaxinos(pax,isbrain,WLt);

% Test plot
if flags.dispfig
    figure
    subplot(2,2,1)
    image(rot90(WL))
    axis image
    hold on
    plot(LM.ams(1),scan.Py+1-LM.ams(2),'bo')
    plot(LM.lambda(1),scan.Py+1-LM.lambda(2),'bo')
    title('Pre-Transform WL')
    
    subplot(2,2,2)
    image(rot90(WLt))
    axis image
    hold on
    plot(ref.ams(1),scan.Py+1-ref.ams(2),'ro')
    plot(ref.lambda(1),scan.Py+1-ref.lambda(2),'ro')
    for s=1:numseeds
%         seedlabel=seednames{s};
%         for d=1:2 % right and left
            plot(seeds(s,1),scan.Py+1-seeds(s,2),'r*')
%             if d==1
                text(seeds(s,1),scan.Py+1-seeds(s,2),seednames{s})
%             end
%         end
    end
    title('Transformed WL')
    
    subplot(2,2,3)
    imagesc(rot90(isbrain))
    axis image
    hold on
    plot(ref.ams(1),scan.Py+1-ref.ams(2),'ro')
    plot(ref.lambda(1),scan.Py+1-ref.lambda(2),'ro')
    title('Transformed Mask')
    colormap('gray')
    
    subplot(2,2,4)
    image(rot90(PIm))
    axis image off
    title('Transformed Paxinos Atlas')
end

if ~any(any(any(mask.tot)))
    disp('** No quality data remains after affine transform. Further analysis not possible. **')
    return
end


%% Transform Data
disp('Loading Data')
try
    load([filestem,'-datahb',label.in],'datahb','fdata')
catch
    disp('** No processed data available; procOIS not yet performed. **')
    return
end

disp('Affine transforming datahb and datamua')
% switch class(datahb)
%     case 'struct'
%         Fmua=fieldnames(datamua);
%         Fhb=fieldnames(datahb);
%
%         for f=1:numel(Fmua)
%             datamua.(Fmua{f}) = imwarp(datamua.(Fmua{f}),tformi,'cubic','OutputView',imcoord);
%         end
%
%         for f=1:numel(Fhb)
%             datahb.(Fhb{f})(datahb.(Fhb{f})==Inf)=0;% imwarp confused by Inf
%
%             datahb.(Fhb{f}) = imwarp(datahb.(Fhb{f}),tformi,'cubic','OutputView',imcoord);
%         end
%     case {'double','single'}

% datamua = imwarp(datamua,tformi,'cubic','OutputView',imcoord);

datahb(datahb==Inf)=0; % imwarp confused by Inf
datahb = imwarp(datahb,tformi,'cubic','OutputView',imcoord);
% end

if any(scan.exled)
    fdata(fdata==Inf)=0; % imwarp confused by Inf
    fdata = imwarp(fdata,tformi,'cubic','OutputView',imcoord);
else
    fdata=[];
end

WL=WLt;

%% Segmentation correction

% muanan=sum(isnan(datamua),4);
hbnan=sum(isnan(datahb),4);
fnan=sum(isnan(fdata),3);

% muananmask=~(muanan==scan.T2);
hbnanmask=~(hbnan==scan.T2H);
if ~isempty(fnan)
    fnanmask=~(fnan==scan.T2F);
else
    fnanmask=[];
end

% mask.combaff=mask.combaff.*muananmask;

mask.spectaff=mask.spect.*hbnanmask(:,:,3);
mask.fluoroaff=mask.fluoro.*fnanmask;

%% Saving
disp('Saving')

scan.affdate=date;

save([filestem,'-affine',label.out],'datahb','fdata','WL','scan','flags','seeds','M2Ai','M2Ap','ref','mask')

end

