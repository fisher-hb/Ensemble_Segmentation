function [filestem,dirstem]=getfilestem_WUSM(filedate,mousename,scanlabel)

fileinfo=readkeyfile('directory.txt');
fileinfo.dir_data_win = 'T:\Data_OIS\WashU\Data_OIS';

switch computer
    case 'PCWIN64'
        dir_data=fileinfo.dir_data_win;
        dir_div='\';
        
    case 'MACI64'
        dir_data=fileinfo.dir_data_mac;
        dir_div='/';
end

if exist('scanlabel')
    filestem=[dir_data,dir_div,filedate,'-',mousename,'-',scanlabel];
    dirstem=[dir_data,mousename,dir_div,filedate,dir_div];
else
    filestem=[dir_data,dir_div,filedate,'-',mousename];
    dirstem=[dir_data,mousename,dir_div,filedate,dir_div];
end

end