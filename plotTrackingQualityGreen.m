% quantify how much data has been tracked, and how much filtered out at
% various stages
close all
clear

strains = {'npr1','N2'};
wormnums = {'40','HD'};
minIntensities = [50, 40];
maxBlobSize = 1e4;
maxSpeed = 1e3;

for numCtr = 1:length(wormnums)
    wormnum = wormnums{numCtr};
    for strainCtr = 1:length(strains)
        strain = strains{strainCtr};
        figure, hold on
        % load green channel file list (from second dataset)
        filenames = importdata([strains{strainCtr} '_' wormnum '_g_list.txt']);
        numFiles = length(filenames);
        for fileCtr = 1:numFiles
            filename = filenames{fileCtr};
            trajData = h5read(filename,'/trajectories_data');
            blobFeats = h5read(filename,'/blob_features');
            numFrames = numel(unique(trajData.frame_number));
            % go through each filter and see how many green worms are
            % retained after filters are applied separately (i.e. not
            % sequentially)
            numTracks = numel(unique(trajData.worm_index_joined));
            % IntensityThreshold
            minIntensity = minIntensities(numCtr);
            validWormInd1 = blobFeats.intensity_mean > minIntensity;
            numMinInt = numel(unique(trajData.worm_index_joined(validWormInd1)));
            % numMaxBlobSize
            validWormInd2 = blobFeats.area < maxBlobSize;
            %validWormInd1_2 = logical(validWormInd1 .* validWormInd2);
            % need to work out how to implement this sequentially
            numBlobSizeFilter = numel(unique(trajData.worm_index_joined(validWormInd2));
            % numMaxSpeed
            % need to calculate speed by going through each filtered worm
            % and calculating over frame progression
            % validWormInd3 = < maxSpeed;
            numMaxSpeedFilter = numel(unique(trajData.worm_index_joined(validWormInd3)));
            % plot
            plot([numTracks, numMinInt, numMaxBlobSize, numMaxSpeed]./numFrames)
        end
        title([strain ' ' wormnum],'FontWeight','normal')
        xticks([1 2 3 4])
        xticklabels({'trajectories','minIntensity','maxBlobSize','maxSpeed'})
    end
end