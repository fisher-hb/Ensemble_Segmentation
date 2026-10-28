mice = readtable('T:\Hayden\Code_OIS_Hayden\Automated Pipeline\WashU Pipeline\WashU_mice.csv');

label.in = '-auto';

Sp = zeros(128,128);

for k = 1:height(mice)
    filedate = char(string(mice{k,1}));
    mousename = char(mice{k,2});
    scanlabel = char(mice{k,3});
    filestem = getfilestem_WUSM(filedate,mousename,scanlabel);
    load([filestem,'-qc',label.in],'al_oldMask');
    mask = al_oldMask;

    for i=1:128
        for j=1:128
            Sp(i,j) = Sp(i,j)+mask(i,j);
        end
    end
end

Sp = (Sp/height(mice));
Sp = rot90(Sp);