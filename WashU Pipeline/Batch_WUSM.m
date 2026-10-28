mice = readtable('T:\Hayden\Code_OIS_Hayden\Automated Pipeline\WashU Pipeline\WashU_mice.csv');

label.in = 'auto';  label.out = 'auto';

for i = 1:47
    filedate = char(string(mice{i,1}));
    mousename = char(mice{i,2});
    scanlabel = char(mice{i,3});
    try
        returns = autoPipeline_WUSM(filedate,mousename,scanlabel,label);
        accuracy(i,:) = returns.accuracy;

        % subplot(5,10,i)
        % imshow(rot90(isbrain))
        % hold on
        % plot(boundary(:,2), boundary(:,1), 'c', 'LineWidth', 3);

    catch
        disp('QC could not be completed')
    end
end