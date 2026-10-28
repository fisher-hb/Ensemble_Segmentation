function makeIBLM_auto(filedate,mousename,scanlabels,label,varargin)

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
lmWOI(filedate,mousename,scanlabels,label);

% Load networks
disp('Loading networks for segmentation...')
    network_B = load('network_470nm.mat');
    network_G = load('network_530nm.mat');
    network_A = load('network_590nm.mat');
    network_R = load('network_625nm.mat');
    load('sp128.mat');

figure(1);

for i = 1:length(scanlabels)

    filestem = getfilestem(filedate,mousename,scanlabels{i});

    % Create image for segmentation
    segImage = imcreateWOI(filedate,mousename,scanlabels{i},label);

    % Segment images
    disp(strcat('Segmenting scan: ',string(i)));
    B_mask = semanticseg(imresize(segImage.blue.*256,0.25),network_B.net)=="brain";
    G_mask = semanticseg(imresize(segImage.green.*256,0.25),network_G.net)=="brain";
    A_mask = semanticseg(imresize(segImage.amber.*256,0.25),network_A.net)=="brain";
    R_mask = semanticseg(imresize(segImage.red.*256,0.25),network_R.net)=="brain";

    trainedMask = (B_mask + 2*G_mask + A_mask + R_mask)/5;

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

    windowSize = 8;
    kernel = ones(windowSize,windowSize) / windowSize ^ 2;
    blurryImage = conv2(single(segmentation), kernel, 'same');
    segmentedImage = blurryImage > 0.6; % Rethreshold
    indMasks(:,:,i) = segmentedImage;

    image(:,:,1) = segImage.red(:,:,1); image(:,:,2) = segImage.green(:,:,1); image(:,:,3) = segImage.blue(:,:,1);
    image128 = imresize(image,0.25);
    finalImage = labeloverlay(image128,segmentedImage);

    subplot(1,length(scanlabels)+1,i+1)
    imshow(finalImage)
end

combMask = combIB(indMasks);

subplot(1,length(scanlabels)+1,1)
imshow(combMask)

% Save AutoSegcon file
scanlabel = scanlabels;
isbrain = rot90(rot90(rot90(combMask)));

filestem=getfilestem(filedate,mousename);
save([filestem,'-segcon',label.out],'isbrain','scanlabel','-append')

end

