function returns = displaySeg(filedate,mousename,scanlabel,label)

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

filestem = getfilestem_WUSM(filedate,mousename,scanlabel);
load([filestem,'-qc',label.in],'al_WL','al_oldMask');

% filestem = getfilestem_WUSM(filedate,mousename);
% load([filestem,'-segcon',label.in],'isbrain')

% For Multi-wavelength model NOT ENSEMBLE
filestem = getfilestem_WUSM(filedate,mousename);
load([filestem,'-segcon-auto_MW'],'isbrain')

[B,L] = bwboundaries(rot90(logical(al_oldMask)));
boundary = B{1};

finalImage = labeloverlay(al_WL,rot90(isbrain));
testMaskImage = labeloverlay(al_WL,rot90(logical(al_oldMask)));
finalImage2 = labeloverlay(al_WL,rot90(isbrain),'Colormap','winter','Transparency',0.3);
finalImage2 = labeloverlay(finalImage2,rot90(logical(al_oldMask)),'Colormap','autumn','Transparency',0.6);

% figure
% subplot(1,2,1)
% imshow(rot90(isbrain))
% hold on
% plot(boundary(:,2), boundary(:,1), 'c', 'LineWidth', 3);

% subplot(1,2,2)
% imshow(rot90(double(isbrain)))
% hold on
% plot(boundary(:,2), boundary(:,1), 'c', 'LineWidth', 3);

returns.accuracy(:,1) = dice(isbrain,logical(al_oldMask));
returns.accuracy(:,2) = jaccard(isbrain,logical(al_oldMask));
returns.accuracy(:,3) = bfscore(isbrain,logical(al_oldMask),4);

returns.finalImage = finalImage2;

returns.isbrain = isbrain;
returns.boundary = boundary;

end