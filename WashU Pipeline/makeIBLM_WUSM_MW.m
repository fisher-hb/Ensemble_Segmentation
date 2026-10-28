function makeIBLM_WUSM_MW(filedate,mousename,scanlabel,label,varargin)

% Check for input and output labels
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

% Check for landmarks and qc before proceeding
lmWUSM(filedate,mousename,scanlabel,label);

% Load networks
disp('Loading networks for segmentation...')
    network_530 = load('network_G_25.mat');
    network_625 = load('network_R_25.mat');
    load('sp128.mat');
    % load('Sp_WUSM.mat');

% Create image for segmentation
segImage = imcreateWUSM(filedate,mousename,scanlabel,label);

disp('Segmenting scan: ');

if contains(mousename,'NWB') || contains(mousename, 'R88')
    network_RGETCO = load('network_G_25.mat');
    network_FAD = load('network_G_25.mat');
    mask_1 = semanticseg(segImage.ch1(:,:,1).*256,network_FAD.net)=="brain"; % FAD Mask
    mask_2 = semanticseg(segImage.ch2(:,:,1).*256,network_530.net)=="brain"; % 525 Mask
    mask_3 = semanticseg(segImage.ch3(:,:,1).*256,network_RGETCO.net)=="brain"; % RGETCO Mask
    mask_4 = semanticseg(segImage.ch4(:,:,1).*256,network_625.net)=="brain"; % 625 Mask
    trainedMask = (mask_2 + mask_3 + mask_4)/3;
    % trainedMask = (mask_2 + mask_4)/2;

elseif contains(mousename,'NE') || contains(mousename,'N4') || contains(mousename, 'N6')
    network_RGETCO = load('network_G_25.mat');
    mask_1 = semanticseg(segImage.ch1(:,:,1).*256,network_530.net)=="brain"; % 525 Mask
    mask_2 = semanticseg(segImage.ch2(:,:,1).*256,network_625.net)=="brain"; % 625 Mask
    mask_3 = semanticseg(segImage.ch3(:,:,1).*256,network_RGETCO.net)=="brain"; % RGETCO Mask
    trainedMask = (mask_1 + mask_2 + mask_3)/3;
    % trainedMask = (mask_1 + mask_2)/2;

else
    network_GCAMP = load('network_470nm.mat');
    mask_1 = semanticseg(segImage.ch2(:,:,1).*256,network_GCAMP.net)=="brain"; % GCAMP Mask
    mask_2 = semanticseg(segImage.ch2(:,:,1).*256,network_530.net)=="brain"; % 525 Mask
    mask_3 = semanticseg(segImage.ch3(:,:,1).*256,network_625.net)=="brain"; % 625 Mask
    trainedMask = (mask_2 + mask_3)/2;
end

trainedMask = imresize(trainedMask,0.25);

filestem = getfilestem_WUSM(filedate,mousename,scanlabel);
load([filestem,'-qc',label.in],'al_WL');

segmentation = zeros(128,128);

for j = 1:128
    for k = 1:128
        pixel = trainedMask(j,k);
        weight = 1/(1+exp(8*pixel-4));
        if Sp(j,k) >= weight
            segmentation(j,k) = 1;
        end
    end
end

windowSize = 4;
kernel = ones(windowSize,windowSize) / windowSize ^ 2;
blurryImage = conv2(single(segmentation), kernel, 'same');
segmentedImage = blurryImage > 0.6; % Rethreshold

for i = 1:128
    for j = 1:128
        if al_WL(i,j,2) <= 0.1
            segmentedImage(i,j) = 0;
        end
    end
end

% finalImage = labeloverlay(al_WL,segmentedImage);
% imshow(finalImage)

% Save AutoSegcon file
isbrain = rot90(rot90(rot90(segmentedImage)));

filestem=getfilestem_WUSM(filedate,mousename);
save([filestem,'-segcon',label.out],'isbrain','scanlabel','-append')

end