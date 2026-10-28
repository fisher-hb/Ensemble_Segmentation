function fcWUSM_auto(filedate,mousename,scanlabel,label,varargin)

%% Preliminaries
if exist('scanlabel')
    multirun=0;
else
    multirun=1;
end

disp('Loading')
if multirun
    filestem=getfilestem_WUSM(filedate,mousename);
else
    filestem=getfilestem_WUSM(filedate,mousename,scanlabel);
end

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

%% Data Check
if isfile([filestem,'-fchbt',label.in,'.mat'])
    try
        load([filestem,'-fchbt',label.in],'flags','scan')
    catch
    end
    
    if exist('scan')
        [flags]=getflags(flags,'StandardFC',varargin);
        
        if isfield(flags,'toldate') && isfield(scan,'fcdate')
            if datetime(scan.fcdate) > datetime(flags.toldate)
                
                disp('** Data already processed within tolerance. **')
                return
                
            else % If no tolerance passed, just continue
                clear flags scan
            end
            
        else % If no tolerance specied, just continue
            clear flags scan
        end
    end
end

%% Load Data
if multirun
    disp(['FC: ',filedate,'-',mousename,label.in])
    
    try
        load([filestem,'-datahbmerge',label.in])
    catch
        disp('** No merged data available. **')
        return
    end
    
else
    disp(['FC: ',filedate,'-',mousename,'-',scanlabel,label.in])
    
    try
        load([filestem,'-affine',label.in])
    catch
        disp('** No transformed data available; affOIS not yet performed. **')
        return
    end
    
    if ~any(any(any(mask.tot)))
        disp('** No quality data remains after affine transform. Further analysis not possible. **')
        return
    end
    
    % Currently use all possible wavelength combinations -- may want to create
    % look-up table later
    
    if isfield(mask,'spectaff')
        isbrain_hb=logical(mask.guided.*mask.spectaff);
    else
        isbrain_hb=logical(mask.guided.*(sum(mask.wcaff,3)>=2));
    end
    
    for c=1:scan.numled
        isbrain_mua(:,:,c)=logical(mask.guided.*mask.smooth_hb(:,:,c));
    end
    
    % Flags
    [flags]=getflags(flags,'StandardFC',varargin);
end


%% Hb

disp('Hb')

if ~multirun
    disp('- Global Signal')
    %     [temp,RG.(hbnames{f}),gs.(hbnames{f})]=gsr(temp,isbrain_hb);
    [datags,RG,gs]=gsr(datahb,isbrain_hb);
    
    % Global Signal Figure
    if flags.dispfig
        figure
        subplot(2,3,[1:3])
        %     plot(gs.(hbnames{f})')
        plot(gs')
        title('Global Signal')
        legend
        
        for c=1:3
            subplot(2,3,3+c)
            image(ones(scan.Px,scan.Py,3)/2)
            hold on
            %         I=imagesc(rot90(RG.(hbnames{f})(:,:,c)),[-1 1]);
            I=imagesc(rot90(RG(:,:,c)),[-1 1]);
            set(I,'AlphaData',rot90(isbrain_hb))
            axis image
            colormap(jet)
            colorbar
            title(['R-GSR: Hb ',num2str(c)])
        end
        
        drawnow
    end
end

%% Correlation Matrices
disp('- Making R')

%     R.(hbnames{f})=makeR(temp);
if multirun
    datahb=reshape(datahb,scan.Px*scan.Py,scan.T);
    T=reshape(T,scan.Px*scan.Py,scan.T);
    
    datahb2=datahb;
    datahb2(isnan(datahb2))=0;
    
    %     R0=datahb*datahb'; % Unnormalized R
    R0=datahb2*datahb2'; % Unnormalized R
    
    Tkeep=T*T';
    
    %     R=R0./Tkeep;
    R=R0./Tkeep;
    
    %     M=~isnan(R);
    M=~isnan(R);
    
    
    
else
    R=makeR(datags);
    
    disp('- Mask')
    
    %     M.(hbnames{f})=logical(reshape(isbrain_hb,[],1)*reshape(isbrain_hb,[],1)');
    M=logical(reshape(isbrain_hb,[],1)*reshape(isbrain_hb,[],1)');
    
    isbrain=isbrain_hb;
end
% end

%% Saving
disp('- Saving')
scan.fcdate=date;

if multirun
    save([filestem,'-fchbmerge',label.out],'-v7.3','datags','R','M','scan','WL','T','Tkeep','isbrain')
    
else
    save([filestem,'-fchb',label.out],'-v7.3','RG','gs','R','M','flags','scan','WL','mask','isbrain')
    save([filestem,'-datags',label.out],'-v7.3','datags','flags','scan','WL','mask','isbrain')
    
    RG=RG(:,:,3);
    gs=gs(3,:);
    R=R(:,:,3);
    datags=squeeze(datags(:,:,3,:));
    
    save([filestem,'-fchbt',label.out],'-v7.3','RG','gs','R','M','flags','scan','WL','mask','isbrain')
    save([filestem,'-datagst',label.out],'-v7.3','datags','flags','scan','WL','mask','isbrain')
end

end
