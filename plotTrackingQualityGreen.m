% quantify how much data has been tracked and filtered out at
% various stages: first, minimum intensity threshold filter; second,
% maximum blob size filter; third, maximum speed filter.
close all
clear
 tic
%% set parameters
strains = {'HA','npr1','N2'};
wormnums = {'40','HD'};
minIntensities = [50, 40]; %script takes minIntensity 100 for 1W, 50 for 40W, and 40 for HD
maxBlobSize = 1e4;
pixelsize = 100/19.5; % 100 microns is 19.5 pixels
%maxSpeed = 10 * pixelsize; % 1000 microns per frame maximum speed
maxNeighbourDist = 2500;
inClusterRadius = 500;
inClusterNeighbourNum = 3;

%% go through different strains, densities, and movies
for numCtr = 1:length(wormnums)
    wormnum = wormnums{numCtr};
    for strainCtr = 1:length(strains)
        strain = strains{strainCtr};
        figure, hold on
        % load green channel file list (from second dataset)
        filenames = importdata([strains{strainCtr} '_' wormnum '_list.txt']);
        numFiles = length(filenames);
        % preallocate space to write values into a struct later
         recordingNamesList = cell(numFiles,1);
         numTracksVec = zeros(numFiles,1);
         numMinIntVec = zeros(numFiles,1);
         numMaxBlobSizeVec = zeros(numFiles,1);
         %numMaxSpeedVec = zeros(numFiles,1);
         ii=1; % set counter for plot line colors
         clusterProportion = zeros(numFiles,3);
        for fileCtr = 1:numFiles
            filename = filenames{fileCtr};
            trajData = h5read(filename,'/trajectories_data');
            blobFeats = h5read(filename,'/blob_features');
            % go through each filter and see how many green worms are
            % retained after filters are applied sequentially
            numTracks = numel(unique(trajData.worm_index_joined));
            % IntensityThreshold
            minIntensity = minIntensities(numCtr);
            validWormInd1 = blobFeats.intensity_mean > minIntensity;
            wormInd1 = unique(trajData.worm_index_joined(validWormInd1));
            numMinInt = numel(wormInd1);
            % numMaxBlobSize
            validWormInd2 = blobFeats.area < maxBlobSize;
            rmWormInd2 = unique(trajData.worm_index_joined(~validWormInd2));
            wormInd2 = setdiff(wormInd1,rmWormInd2);
            numMaxBlobSize = numel(wormInd2);
            % in vs out of cluster worms based on unique worms that have
            % passed the previous two filters
            if strcmp(wormnum,'1W') == 0
                frameList = [1:32400];
            else
                frameList = [1:10800];
            end
            clusterStatus = zeros(length(frameList),3);
            trajData.filtered = trajData.worm_index_joined.*int32(validWormInd1).*int32(validWormInd2);
            parfor frame = 1:length(frameList)
                [inCluster, loneWorms, rest] = getWormClusterStatus(trajData, frame, pixelsize, maxNeighbourDist, inClusterRadius, inClusterNeighbourNum);
                clusterStatus(frame,:) = [nnz(inCluster),nnz(loneWorms),nnz(rest)];
            end
            numInCluster = sum(clusterStatus(:,1));
            numLoneWorms = sum(clusterStatus(:,2));
            numRest = sum(clusterStatus(:,3));
            totalnum = numInCluster + numLoneWorms + numRest;
            clusterProportion(fileCtr,:)=[numInCluster,numLoneWorms,numRest]./totalnum;
            % numMaxSpeed
            %avgWormSpeed = zeros(numMaxBlobSize,1);
            %for objInd3Ctr = 1:numel(wormInd2)
            %    objInd3 = wormInd2(objInd3Ctr);
            %    objRowList = find(trajData.worm_index_joined == objInd3);
            %    objFrameList = trajData.frame_number(objRowList);
            %    objFrameContLogInd = [diff(objFrameList)==1]; % check that the frame numbers are continuous
            %    wormMissingFrame = 0;
            %    if sum(objFrameContLogInd)+1 == numel(objFrameList) % if frame numbers are continous
            %        u = trajData.coord_x(objRowList(1)) - trajData.coord_x(objRowList(numel(objRowList)));
            %        v = trajData.coord_y(objRowList(1)) - trajData.coord_y(objRowList(numel(objRowList)));
            %        avgWormSpeed(objInd3Ctr) = sqrt(u^2 + v^2)/numel(objRowList);
            %    else % if frame numbers are not continous 
            %        disp(filename)
            %        disp(objInd3Ctr)
            %        wormMissingFrame = wormMissingFrame+1;  
            %    end
            %end
            %validWormInd3 = avgWormSpeed < maxSpeed;
            %rmWormInd3 = unique(trajData.worm_index_joined(~validWormInd3));
            %wormInd3 = setdiff(wormInd2,rmWormInd3);
            %numMaxSpeed = numel(wormInd3);
            %% fill in a values for making a struct
            nameSplit = strsplit(filename,'/');
            hdf5Name = nameSplit(7);
            hdf5Split = strsplit(hdf5Name{1},'_X1');
            recordingName = hdf5Split(1);
            namestr = recordingName{1};
            recordingNumber = namestr(10:end);
            recordingNamesList(fileCtr)= {recordingNumber};
            numTracksVec(fileCtr)= numTracks;
            numMinIntVec(fileCtr)= numMinInt;
            numMaxBlobSizeVec(fileCtr) = numMaxBlobSize;
            %numMaxSpeedVec(fileCtr) = numMaxSpeed;
            %% make plot
            plotcolor = colorcube(15);
            plot([numTracks, numMinInt, numMaxBlobSize]./numTracks,'color',plotcolor(ii,:))
            ii=ii+1;
        end
        % format plot
        title([strain ' ' wormnum],'FontWeight','normal')
        xticks([1 2 3])
        xticklabels({'trajectories','minIntensity','maxBlobSize'})
        ylim([0,1])
        legend(recordingNamesList);
        % make a struct with plot values
        plotvalues = struct('Recording',recordingNamesList,'Tracks',numTracksVec,'MinInt',numMinIntVec,'MaxBlobSize',numMaxBlobSizeVec);
        structName = strcat('TrackingQualityGreen_',strain,'_',wormnum,'_1.mat');
        figName = strcat('TrackingQualityGreen_',strain,'_',wormnum,'_1.fig');
        save(structName,'plotvalues');
        savefig(figName);
        close all;
        % make second plot showing proportion of in/out/rest cluster worms,
        % save figure, save clusterProportion matrix
        figure;
        bar(clusterProportion*100,'stacked')
        title([strain ' ' wormnum],'FontWeight','normal')
        xticklabels(recordingNamesList);
        ylim([0,100])
        ylabel('Relative proportion of worms (%)');
        legend('inCluster','loneWorms','rest')
        fig2Name = strcat('TrackingQualityGreen_ClusterProportion_',strain,'_',wormnum,'_1.fig');
        matrix2Name = strcat('TrackingQualityGreen_ClusterProportion_',strain,'_',wormnum,'_1.mat');
        savefig(fig2Name);
        save(matrix2Name,'clusterProportion')
        close all;
    end
end
toc