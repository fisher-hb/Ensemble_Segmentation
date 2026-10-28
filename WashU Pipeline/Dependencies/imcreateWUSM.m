function segImage = imcreateWUSM (filedate,mousename,scanlabel,label)

% Check for input and output labels
if ~exist('label') || isempty(label) || isempty(label.out) 
    label.out='';
else
    label.out=label.out;
end
if ~exist('label') || ~isfield(label,'in') || isempty(label.in)
    label.in='';
else
    label.in=label.in;
end

% Load relevant filestem
filestem = getfilestem_WUSM(filedate,mousename,scanlabel);

try
    load(strcat(filestem,"-qc",label.in))
catch
    disp("Quality control data has not been generated. Please run qcWOI.m before proceeding")
    return
end

% Load in landmark data
filestem = getfilestem_WUSM(filedate,mousename);
try
    load(strcat(filestem,"-segcon",label.in,".mat"),'LM')
catch
    try
        load(strcat(filestem,"-segcon.mat"),'LM')
    catch
        try
            filestem = getfilestem(filedate,mousename,scanlabel);
            load(strcat(filestem,"-segment.mat"),'LM')
        catch
            disp('Landmarks have not been selected. Please run lmWOI.m')
        end
    end
end

imcoord = imref2d([512 512]);
tformi = transformLM(LM);

load(strcat('T:\Data_OIS\WashU\Data_OIS\masks\',filedate,'-',mousename,'-',scanlabel,'_WL'),'isbrain')


al_WL = imresize(rot90(imwarp(imresize(WL,4),tformi,'cubic','OutputView',imcoord)),0.25);
al_oldMask = imresize(imwarp(imresize(logical(rot90(rot90(rot90(isbrain)))),4),tformi,'cubic','OutputView',imcoord),0.25);

filestem = getfilestem_WUSM(filedate,mousename,scanlabel);
save(strcat(filestem,"-qc",label.in),'al_WL','al_oldMask','-append')

try
    % Resize and normalize data
    ua_1 = double(imresize(imdata(:,:,1),[512 512]))/max(max(double(imresize(imdata(:,:,1),[512 512]))));
    ua_2 = double(imresize(imdata(:,:,2),[512 512]))/max(max(double(imresize(imdata(:,:,2),[512 512]))));
    ua_3 = double(imresize(imdata(:,:,3),[512 512]))/max(max(double(imresize(imdata(:,:,3),[512 512]))));
    ua_4 = double(imresize(imdata(:,:,4),[512 512]))/max(max(double(imresize(imdata(:,:,4),[512 512]))));
    
    % Define affine transformed greyscale images for each wavelength
    al_1 = rot90(imwarp(ua_1,tformi,'cubic','OutputView',imcoord));
    al_2 = rot90(imwarp(ua_2,tformi,'cubic','OutputView',imcoord));
    al_3 = rot90(imwarp(ua_3,tformi,'cubic','OutputView',imcoord));
    al_4 = rot90(imwarp(ua_4,tformi,'cubic','OutputView',imcoord));

    for i = 1:4
        lcorr_ua = min(qcdata.rlocal(:,:,i,:),[],4);
        lcorr_ua = imresize(lcorr_ua,[512 512]);
        std_ua = qcdata.stdr(:,:,i);
        std_ua = interp1([0,max(max(std_ua))],[0,1],std_ua);
        std_ua = adapthisteq(std_ua,"Distribution","exponential");
        std_ua = imresize(std_ua,[512 512]);
    
        lcorr(:,:,i) = rot90(imwarp(lcorr_ua,tformi,'cubic','OutputView',imcoord));
        std(:,:,i) = rot90(imwarp(std_ua,tformi,'cubic','OutputView',imcoord));
    end

    % Create composite spacial-temporal images
    comb_ch1(:,:,1) = al_1;     comb_ch1(:,:,2) = lcorr(:,:,1);    comb_ch1(:,:,3) = std(:,:,1);
    comb_ch2(:,:,1) = al_2;     comb_ch2(:,:,2) = lcorr(:,:,2);    comb_ch2(:,:,3) = std(:,:,2);
    comb_ch3(:,:,1) = al_3;     comb_ch3(:,:,2) = lcorr(:,:,3);    comb_ch3(:,:,3) = std(:,:,3);
    comb_ch4(:,:,1) = al_4;     comb_ch3(:,:,2) = lcorr(:,:,4);    comb_ch3(:,:,3) = std(:,:,4);

    segImage.ch1 = comb_ch1;  segImage.ch2 = comb_ch2;  segImage.ch3 = comb_ch3;    segImage.ch4 = comb_ch4;

catch
    % Resize and normalize data
    ua_1 = double(imresize(imdata(:,:,1),[512 512]))/max(max(double(imresize(imdata(:,:,1),[512 512]))));
    ua_2 = double(imresize(imdata(:,:,2),[512 512]))/max(max(double(imresize(imdata(:,:,2),[512 512]))));
    ua_3 = double(imresize(imdata(:,:,3),[512 512]))/max(max(double(imresize(imdata(:,:,3),[512 512]))));
    
    % Define affine transformed greyscale images for each wavelength
    al_1 = rot90(imwarp(ua_1,tformi,'cubic','OutputView',imcoord));
    al_2 = rot90(imwarp(ua_2,tformi,'cubic','OutputView',imcoord));
    al_3 = rot90(imwarp(ua_3,tformi,'cubic','OutputView',imcoord));

    for i = 1:3
        lcorr_ua = min(qcdata.rlocal(:,:,i,:),[],4);
        lcorr_ua = imresize(lcorr_ua,[512 512]);
        std_ua = qcdata.stdr(:,:,i);
        std_ua = interp1([0,max(max(std_ua))],[0,1],std_ua);
        std_ua = adapthisteq(std_ua,"Distribution","exponential");
        std_ua = imresize(std_ua,[512 512]);
    
        lcorr(:,:,i) = rot90(imwarp(lcorr_ua,tformi,'cubic','OutputView',imcoord));
        std(:,:,i) = rot90(imwarp(std_ua,tformi,'cubic','OutputView',imcoord));
    end

    % Create composite spacial-temporal images
    comb_ch1(:,:,1) = al_1;     comb_ch1(:,:,2) = lcorr(:,:,1);    comb_ch1(:,:,3) = std(:,:,1);
    comb_ch2(:,:,1) = al_2;     comb_ch2(:,:,2) = lcorr(:,:,2);    comb_ch2(:,:,3) = std(:,:,2);
    comb_ch3(:,:,1) = al_3;     comb_ch3(:,:,2) = lcorr(:,:,3);    comb_ch3(:,:,3) = std(:,:,3);

    segImage.ch1 = comb_ch1;    segImage.ch2 = comb_ch2;    segImage.ch3 = comb_ch3;
end

end

function tformi = transformLM(LM)
LM.ams = LM.ams.*4;
LM.lambda = LM.lambda.*4;

ref.ams = [258 440];
ref.lambda = [258 60];

ref.mid=(ref.ams+ref.lambda)/2;
LM.mid=(LM.ams+LM.lambda)/2;

A=[ref.ams;ref.lambda]; % Ref points
M=[LM.ams;LM.lambda]; % Mouse points

Ti_lm=[1 0 0 ; 0 1 0 ; -LM.mid(2) -LM.mid(1) 1]; % LM midpoint -> Origin
Ti_ref=[1 0 0 ; 0 1 0 ; ref.mid(2) ref.mid(1) 1]; % Origin -> Ref midpoint

phi=atan2(LM.ams(1)-LM.lambda(1),LM.ams(2)-LM.lambda(2));
theta=-phi;
Ri=[cos(theta) sin(theta) 0 ; -sin(theta) cos(theta) 0 ; 0 0 1];

slm=norm(A(1,:)-A(2,:))/norm(M(1,:)-M(2,:));
S_lm=diag([slm,slm,1]);

M2Ai=Ti_lm*Ri*S_lm*Ti_ref;

tformi=affine2d(M2Ai);

end