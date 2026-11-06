function segImage = imcreateWOI (filedate,mousename,scanlabel,label)

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
filestem = getfilestem(filedate,mousename,scanlabel);

try
    load(strcat(filestem,"-qc",label.in,".mat"))
catch
    disp("Quality control data has not been generated. Please run qcWOI.m before proceeding")
end

% Load in scout image for each wavelength
load(strcat(filestem,"-scout.mat"))

% Resize scout data and normalize data
blue_ua = double(imresize(scout(:,:,1,1),[512 512]))/max(max(double(imresize(scout(:,:,1,1),[512 512]))));
green_ua = double(imresize(scout(:,:,2,1),[512 512]))/max(max(double(imresize(scout(:,:,2,1),[512 512]))));
amber_ua = double(imresize(scout(:,:,3,1),[512 512]))/max(max(double(imresize(scout(:,:,3,1),[512 512]))));
red_ua = double(imresize(scout(:,:,4,1),[512 512]))/max(max(double(imresize(scout(:,:,4,1),[512 512]))));

% Load in landmark data
filestem = getfilestem(filedate,mousename);
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

% Define affine transformed greyscale images for each wavelength
blue = rot90(imwarp(blue_ua,tformi,'cubic','OutputView',imcoord));
green = rot90(imwarp(green_ua,tformi,'cubic','OutputView',imcoord));
amber = rot90(imwarp(amber_ua,tformi,'cubic','OutputView',imcoord));
red = rot90(imwarp(red_ua,tformi,'cubic','OutputView',imcoord));

% Load temporal data
filestem = getfilestem(filedate,mousename,scanlabel);
load(strcat(filestem,"-qc",label.in,".mat"))

for i = 1:4
    lcorr_ua = min(qcdata.rlocal(:,:,i,:),[],4);
    lcorr_ua = imresize(lcorr_ua,[512 512]);
    try
        std_ua = qcdata.stdr(:,:,i);
    catch
        std_ua = qcdata.stdlr(:,:,i);
    end
    std_ua = interp1([0,max(max(std_ua))],[0,1],std_ua);
    std_ua = adapthisteq(std_ua,"Distribution","exponential");
    std_ua = imresize(std_ua,[512 512]);

    lcorr(:,:,i) = rot90(imwarp(lcorr_ua,tformi,'cubic','OutputView',imcoord));
    std(:,:,i) = rot90(imwarp(std_ua,tformi,'cubic','OutputView',imcoord));
end

% Create composite spacial-temporal images
blue_comb(:,:,1)  = blue;    blue_comb(:,:,2)  = lcorr(:,:,1);   blue_comb(:,:,3)  = std(:,:,1);
green_comb(:,:,1) = green;   green_comb(:,:,2) = lcorr(:,:,2);   green_comb(:,:,3) = std(:,:,2);
amber_comb(:,:,1) = amber;   amber_comb(:,:,2) = lcorr(:,:,3);   amber_comb(:,:,3) = std(:,:,3);
red_comb(:,:,1)   = red;     red_comb(:,:,2)   = lcorr(:,:,4);   red_comb(:,:,3)   = std(:,:,4);

segImage.blue = blue_comb;  segImage.green = green_comb;  segImage.amber = amber_comb;  segImage.red = red_comb;

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