function mask = combIB(indMasks)

% Combine segmentations across multiple scans in the same subject
numScans = size(indMasks);

% Initialize masks
indMask = zeros(128,128);

% Combine created masks
for i = 1:numScans(3)

    % Combine individual masks across scans
    indMask = indMask + indMasks(:,:,i);
end

% Average Masks
mask = indMask > (numScans(3)/2);

end
