function [data]=fcfilt(data,FR,freqout,HP,LP)

% Highpass and Lowpass
if HP
data=highpass(data,HP,FR);
end
if LP
data=lowpass(data,LP,FR);
end

% Downsample
data=resampledata(data,FR,freqout,10^-5);

end