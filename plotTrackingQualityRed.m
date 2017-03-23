% quantify how much data has been tracked and filtered out at various stages: 
% 1. minimum intensity threshold filter; 2. maximum blob size filter; 3. has skeleton
% 4. has good skeleton; 5. minimum skeleton length filter; 6. in vs. out of cluster
% saves a struct that contains the amount of data left after each filter
% and a plot that provides visualisation of it
close all
clear

%% set parameters
strains = {'npr1','N2'};
wormnums = {'40','HD'};
minIntensities = [35, 70]; % script takes 35 for all movies but recordings 54 and 55, which takes 70 because the dynamic ranges were different for those movies
maxBlobSize = 25000;
minSkelLength = 850;
pixelsize = 100/19.5; % 100 microns is 19.5 pixels
maxNeighbourDist = 2500;
inClusterRadius = 500;
inClusterNeighbourNum = 2;
%maxSpeed = 10 * pixelsize; % 1000 microns per frame maximum speed

%% go through different strains, densities, and movies
for numCtr = 1:length(wormnums)
    wormnum = wormnums{numCtr};
    for strainCtr = 1:length(strains)
        strain = strains{strainCtr};
        %% go through all 10+ movies for the specified strain/density combination individually and generate plots and save plotvalues
        % load red channel file list
        filenames = importdata([strains{strainCtr} '_' wormnum '_r_list.txt']);
        numFiles = length(filenames);
        % preallocate space to write values into a struct later
         recordingNamesList = cell(numFiles,1);
         numTracksVec = zeros(numFiles,1);
         numMinIntVec = zeros(numFiles,1);
         numMaxBlobSizeVec = zeros(numFiles,1);
         numHasSkelVec = zeros(numFiles,1);   
         numHasGoodSkelVec = zeros(numFiles,1);
         numMinSkelLengthVec = zeros(numFiles,1);
         ii=1; % set counter for plot line colors
         clusterProportion = zeros(numFiles,3);
         figure; hold on
         for fileCtr = 1:numFiles
            filename = filenames{fileCtr};
            trajData = h5read(filename,'/trajectories_data');
            blobFeats = h5read(filename,'/blob_features');
            skelData = h5read(filename,'/skeleton');
            % go through each filter and see how many red worms are
            % retained after filters are applied sequentually
            numTracks = numel(trajData.worm_index_joined);
            % IntensityThreshold
            if isempty(find(filename == 54)) || isempty(find(filename == 55)) == (3>2)
                minIntensity = minIntensities(1);
            else
                minIntensity = minIntensities(2);
            end
            validWormInd1 = blobFeats.intensity_mean > minIntensity;
            wormInd1 = trajData.worm_index_joined.* int32(validWormInd1);
            numMinInt = nnz(wormInd1);
            % MaxBlobSize
            validWormInd2 = blobFeats.area < maxBlobSize;
            wormInd2 = wormInd1.*int32(validWormInd2);
            numMaxBlobSize = nnz(wormInd2);
            % HasSkeleton
            validWormInd3 = trajData.has_skeleton;
            wormInd3 = wormInd2.*int32(validWormInd3);
            numHasSkel = nnz(wormInd3);
            % HasGoodSkeleton
            validWormInd4 = trajData.is_good_skel;
            wormInd4 = wormInd3.*int32(validWormInd4);
            numHasGoodSkel = nnz(wormInd4);
            % MinSkelLength
            skelLengths = sum(sqrt(sum((diff(skelData,1,2)*pixelsize).^2)));
            validWormInd5 = skelLengths(:) > minSkelLength;
            wormInd5 = wormInd4.*int32(validWormInd5);
            numMinSkelLength = nnz(wormInd5);
            % in/outCluster
            validFrames = trajData.frame_number(logical(wormInd5));
            clusterStatus = zeros(numel(validFrames),3);
            for frameCtr = 1:length(validFrames);
                frame = validFrames(frameCtr);
                [inCluster, loneWorms, rest] = getWormClusterStatus(trajData, frame, pixelsize, maxNeighbourDist, inClusterRadius, inClusterNeighbourNum);
                clusterStatus(frameCtr,:) = [nnz(inCluster),nnz(loneWorms),nnz(rest)];
            end
            numInCluster = sum(clusterStatus(:,1));
            numLoneWorms = sum(clusterStatus(:,2));
            numRest = sum(clusterStatus(:,3));
            totalnum = numInCluster + numLoneWorms + numRest;
            clusterProportion(fileCtr,:)=[numInCluster,numLoneWorms,numRest]./totalnum;
            % MaxSpeed
            %xpos = trajData.coord_x(logical(wormInd5));
            %ypos = trajData.coord_y(logical(wormInd5));
            %uniqueWormInd5 = unique(wormInd5);
            %avgWormSpeed = zeros(wormInd5,1);
            %for objInd5Ctr = 1:numel(wormInd5)
            %    objInd6 = wormInd5(objInd5Ctr);
            %    objRowList = find(trajData.worm_index_joined == objInd6);
            %    objFrameList = trajData.frame_number(objRowList);
            %    objFrameContLogInd = [diff(objFrameList)==1]; % check that the frame numbers are continuous
            %    wormMissingFrame = 0;
            %    if sum(objFrameContLogInd)+1 == numel(objFrameList) % if frame numbers are continous
            %        u = trajData.coord_x(objRowList(1)) - trajData.coord_x(objRowList(numel(objRowList)));
            %        v = trajData.coord_y(objRowList(1)) - trajData.coord_y(objRowList(numel(objRowList)));
            %        avgWormSpeed(objInd5Ctr) = sqrt(u^2 + v^2)/numel(objRowList);
            %    else % if frame numbers are not continous 
            %        disp(filename)
            %        disp(objInd5Ctr)
            %        wormMissingFrame = wormMissingFrame+1;  
            %    end
            %end
            %validWormInd6 = avgWormSpeed < maxSpeed;
            %wormInd6 = wormInd5.*int32(validWormInd6);
            %numMaxSpeed = nnz(wormInd6);
            %% fill in a values for making a struct
            nameSplit = strsplit(filename,'/');
            hdf5Name = nameSplit(9);
            hdf5Split = strsplit(hdf5Name{1},'_X1');
            recordingName = hdf5Split(1);
            namestr = recordingName{1};
            recordingNumber = namestr(10:end);
            recordingNamesList(fileCtr)= {recordingNumber};
            numTracksVec(fileCtr)= numTracks;
            numMinIntVec(fileCtr)= numMinInt;
            numMaxBlobSizeVec(fileCtr) = numMaxBlobSize;
            numHasSkelVec(fileCtr)= numHasSkel;
            numHasGoodSkelVec(fileCtr) = numHasGoodSkel;
            numMinSkelLengthVec(fileCtr) = numMinSkelLength;
            % add data from individual movie file to the plot
            plotcolor = colorcube(15);
            plot([numTracks, numMinInt, numMaxBlobSize, numHasSkel, numHasGoodSkel,numMinSkelLength]./numTracks,'color',plotcolor(ii,:))
            ii=ii+1;
        end 
        % format the overall plot for the specified strain + density combination
        title([strain ' ' wormnum],'FontWeight','normal')
        xticks([1 2 3 4 5 6])
        xticklabels({'trajectories','minIntensity','maxBlobSize','hasSkel','hasGoodSkel','minSkelLength'})
        ylim ([0,1])
        legend(recordingNamesList);
        % make a struct with plot values
        plotvalues = struct('Recording',recordingNamesList,'Tracks',numTracksVec,'MinInt',numMinIntVec,'MaxBlobSize',numMaxBlobSizeVec,'HasSkel',numHasSkelVec,'HasGoodSkel',numHasGoodSkelVec,'MinSkelLength',numMinSkelLengthVec);
        structName = strcat('TrackingQualityRed_',strain,'_',wormnum,'.mat');
        figName = strcat('TrackingQualityRed_',strain,'_',wormnum,'.fig');
        save(structName,'plotvalues');
        savefig(figName);
        close all;
        % make second plot showing proportion of in/out/rest cluster worms,
        % save figure, save clusterProportion matrix
        figure;
        bar(clusterProportion*100,'stacked')
        title([strain ' ' wormnum],'FontWeight','normal')
        xticklabels(recordingNamesList);
        ylim ([0,100])
        ylabel('Relative proportion of worms (%)');
        legend('inCluster','loneWorms','rest')
        fig2Name = strcat('TrackingQualityRed_ClusterProportion_',strain,'_',wormnum,'.fig');
        matrix2Name = strcat('TrackingQualityRed_ClusterProportion_',strain,'_',wormnum,'.mat');
        savefig(fig2Name);
        save(matrix2Name,'clusterProportion')
        close all;
    end
end