function scan = createScanFile(filedate,mousename,scanlabel)
    scan.numled = 3;
    scan.ledtime = [0.7500,0.7500,0.7500];
    scan.ledmax = [1000,1000,1000];
    scan.sdk = 'SDK3';
    scan.xbin = 8;
    scan.ybin = 8;
    scan.aoix = 1024;
    scan.aoiy = 1024;
    scan.framerate = 120;
    scan.texp = 0.002;
    scan.sr = 10000;
    scan.outv = 3;
    scan.system = 'WASHU';
    scan.filedate = filedate;
    scan.mousename = mousename;
    scan.scanlabel = scanlabel;
    scan.ST = 300;
    scan.ledlambda = [470,530,625];
    scan.Px = 128;
    scan.Py = 128;
    scan.bd = 16;

    filestem = getfilestem_WUSM(filedate,mousename,scanlabel);

    % Save scan file
    save([filestem,'-scan'],'scan')
end