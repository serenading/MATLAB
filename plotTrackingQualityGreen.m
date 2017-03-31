% quantify how much data has been tracked and filtered out at
% various stages: first, minimum intensity threshold filter; second,
% maximum blob size filter; third, maximum speed filter.
close all
clear

%% set parameters
strains = {'npr1','N2'};
wormnums = {'40','HD'};
dataset = 2; % set to 1 for first dataset and set to 2 for second dataset (TwoColour)
if dataset ==2
    minIntensities = [60, 40]; %script takes minIntensity 100 for 1W, 50 for 40W, and 40 for HD
elseif dataset ==1
        minIntensities = [50,40]
    end
end
maxBlobSize = 1e4;
pixelsize = 100/19.5; % 100 microns is 19.5 pixels
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
        if dataset ==2
        filenames = importdata([strains{strainCtr} '_' wormnum '_g_list.txt']);
        else 
        filenames = importdata([strains{strainCtr} '_' wormnum '_list.txt']);
        end
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
            validWormInd2 = blobFeats.area*pixelsize^2 < maxBlobSize;
            rmWormInd2 = unique(trajData.worm_index_joined(~validWormInd2));
            wormInd2 = setdiff(wormInd1,rmWormInd2);
            numMaxBlobSize = numel(wormInd2);
            % write filtered worms into hdf5
            filtered = validWormInd1(validWormInd2);
            h5create(filename,'/filtered',...
                        size(filtered))
                    h5write(filename,'/min_neighbor_dist_rr',...
                        logical(filtered))
            % in vs out of cluster worms based on unique worms that have
            % passed the previous two filters
            if strcmp(wormnum,'1W') == 0
                frameList = [1:32400];
            else
                frameList = [1:10800];
            end
            clusterStatus = zeros(length(frameList),3);
            trajData.filtered = trajData.worm_index_joined(filtered);
            parfor frame = 1:length(frameList)
                [inCluster, loneWorms, rest] = getWormClusterStatus(trajData, frame, pixelsize, maxNeighbourDist, inClusterRadius, inClusterNeighbourNum);
                clusterStatus(frame,:) = [nnz(inCluster),nnz(loneWorms),nnz(rest)];
            end
            numInCluster = sum(clusterStatus(:,1));
            numLoneWorms = sum(clusterStatus(:,2));
            numRest = sum(clusterStatus(:,3));
            totalnum = numInCluster + numLoneWorms + numRest;
            clusterNumbers(fileCtr,:) = [numInCluster,numLoneWorms,numRest];
            clusterProportion(fileCtr,:)=[numInCluster,numLoneWorms,numRest]./totalnum;
            %% fill in a values for making a struct
            nameSplit = strsplit(filename,'/');
            if dataset == 2
               hdf5Name = nameSplit(9);
            else 
               hdf5Name = nameSplit(7);
            end
            hdf5Split = strsplit(hdf5Name{1},'_X1');
            recordingName = hdf5Split(1);
            namestr = recordingName{1};
            recordingNumber = namestr(10:end);
            recordingNamesList(fileCtr)= {recordingNumber};
            numTracksVec(fileCtr)= numTracks;
            numMinIntVec(fileCtr)= numMinInt;
            numMaxBlobSizeVec(fileCtr) = numMaxBlobSize;
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
        %% make a struct with plot values
        plotvalues = struct('Recording',recordingNamesList,'Tracks',numTracksVec,'MinInt',numMinIntVec,'MaxBlobSize',numMaxBlobSizeVec);
        if dataset ==2
            structName = strcat('TrackingQualityGreen_',strain,'_',wormnum,'.mat');
            figName = strcat('TrackingQualityGreen_',strain,'_',wormnum,'.fig');
        else
            structName = strcat('TrackingQualityGreen_',strain,'_',wormnum,'_1.mat');
            figName = strcat('TrackingQualityGreen_',strain,'_',wormnum,'_1.fig');
        end
        save(structName,'plotvalues');
        savefig(figName);
        close all;
        %% make second plot showing proportion of in/out/rest cluster worms,
        % save figure, save clusterProportion matrix
        figure;
        bar(clusterProportion*100,'stacked')
        title([strain ' ' wormnum],'FontWeight','normal')
        xticklabels(recordingNamesList);
        ylim([0,100])
        ylabel('Relative proportion of worms (%)');
        legend('inCluster','loneWorms','rest')
        if dataset ==2
            fig2Name = strcat('TrackingQualityGreen_ClusterProportion_',strain,'_',wormnum,'.fig');
            matrix1Name = strcat('TrackingQualityGreen_ClusterProportion_',strain,'_',wormnum,'.mat');
            matrix2Name = strcat('TrackingQualityGreen_ClusterProportion_',strain,'_',wormnum,'.mat');
        elseif dataset ==1
            fig2Name = strcat('TrackingQualityGreen_ClusterProportion_',strain,'_',wormnum,'_1.fig');
            matrix1Name = strcat('TrackingQualityGreen_ClusterProportion_',strain,'_',wormnum,'_1.mat');
            matrix2Name = strcat('TrackingQualityGreen_ClusterProportion_',strain,'_',wormnum,'_1.mat');
        end
        savefig(fig2Name);
        save(matrix1Name,'clusterProportion')
        save(matrix2Name,'clusterNumbers')
        close all;
    end
end