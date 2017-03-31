% quantify how much data has been tracked and filtered out at various stages: 
% 1. minimum intensity threshold filter; 2. maximum blob size filter; 3. has skeleton
% 4. has good skeleton; 5. minimum skeleton length filter; 
% saves a struct that contains the amount of data left after each filter
% and a plot that provides visualisation of it
close all
clear

%% set parameters
strains = {'npr1','N2'};
wormnums = {'40','HD'};
minIntensities = [35, 70]; % script takes 35 for all movies but recordings 54 and 55, which takes 70 because the dynamic ranges were different for those movies
maxBlobSize = 250000;
minSkelLength = 850;
pixelsize = 100/19.5; % 100 microns is 19.5 pixels
maxNeighbourDist = 2500;
inClusterRadius = 500;
inClusterNeighbourNum = 3;
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
            validWormInd2 = blobFeats.area*pixelsize^2 < maxBlobSize;
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
    end
end