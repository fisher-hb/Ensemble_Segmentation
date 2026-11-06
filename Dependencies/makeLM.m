function [LM]=makeLM(WL,preLM)

% CHANGE LOG
%{
2/6/20:
- Allow grayscale image instead of RGB
- Plot line connecting AMS to Lambda to show midline
- Check is LM is in boundary (otherwise keep pre)

2/7/20: Bux fixes

7/23/21: Collect Bregma
%}

disp('Identify Landmarks')
flm=figure('Name','Choose Landmarks');

[Px,Py,~]=size(WL);

% Display WL
switch ndims(WL)
    case 3
        image(rot90(WL))
    case 2
        imagesc(rot90(WL))
        colormap gray
end
axis image
hold on

% If given prior landmarks to edit
if exist('preLM','var')
    hold on
    % colorstring='bgyrmck';
    
    numscan=numel(preLM);
    for s=1:numscan
        LMnames=fieldnames(preLM(s));
        
        for n=1:numel(LMnames)
            plot(preLM(s).(LMnames{n})(1),Py+1-preLM(s).(LMnames{n})(2),'Marker','o','Color','y')
        end
    end
end

% AMS
[x,y]=getLM('Anterior Midline Suture Landmark',Px,Py);

if isnan(x) || isnan(y)
    if exist(preLM,'var')
        LM.ams=preLM.ams;
    else
        LM.ams=[x,y];
    end
else
    LM.ams=[x,y];
end

plot(LM.ams(1),Py+1-LM.ams(2),'ko')

% Bregma
[x,y]=getLM('Bregma',Px,Py);
if isnan(x) || isnan(y)
    if exist(preLM,'var')
        LM.bregma=preLM.bregma;
    else
        LM.bregma=[x,y];
    end
else
    LM.bregma=[x,y];
end

plot(LM.bregma(1),Py+1-LM.bregma(2),'ko')

% Lambda

[x,y]=getLM('Lambda',Px,Py);
if isnan(x) || isnan(y)
    if exist(preLM,'var')
        LM.lambda=preLM.lambda;
    else
        LM.lambda=[x,y];
    end
else
    LM.lambda=[x,y];
end

plot(LM.lambda(1),Py+1-LM.lambda(2),'ko')

title('Chosen Landmarks');

end

function [x,y]=getLM(loc,Px,Py)
gca;

disp(['- Click ',loc]);
title(['Click ',loc])

[x,y]=ginput(1);

if x>=0 && x<=Px && y>=0 && y<=Py
    % Correct for the way Matlab displays images
    y=Py+1-y;
else
    x=NaN;
    y=NaN;
end

end
