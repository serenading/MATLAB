close all
clear

%% set parameters
strains = {'npr1','N2'};
wormnums = {'HD'};
minIntensities_r = [35, 70]; % script takes 35 for all movies but recordings 54 and 55, which takes 70 because the dynamic ranges were different for those movies
minIntensities_g = [60, 40]; %script takes minIntensity 100 for 1W, 60 for 40W, and 40 for HD
maxBlobSize_r = 250000;
maxBlobSize_g = 1e4;
minSkelLength_r = 850;
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
        filenames_r = importdata([strains{strainCtr} '_' wormnum '_r_list.txt']);
        filenames_g = importdata([strains{strainCtr} '_' wormnum '_g_list.txt']);
        numFiles = length(filenames_g);
        assert(length(filenames_r)==numFiles,'Number of files for two channels do not match.')
        clusterProportion = zeros(numFiles,3);
        clusterNumbers = zeros(numFiles,3);
        recordingNamesList = cell(numFiles,1);
        for fileCtr = 1:numFiles
            filename_r = filenames_r{fileCtr};
            filename_g = filenames_g{fileCtr};
            trajData_r = h5read(filename_r,'/trajectories_data');
            trajData_g = h5read(filename_g,'/trajectories_data');
            blobFeats_r = h5read(filename_r,'/blob_features');
            blobFeats_g = h5read(filename_g,'/blob_features');
            skelData_r = h5read(filename_r,'/skeleton');
            % filter worms
            if isempty(find(filename_r == 54)) || isempty(find(filename_r == 55)) == (3>2)
                minIntensity = minIntensities_r(1);
            else
                minIntensity = minIntensities_r(2);
            end
            skelLengths = sum(sqrt(sum((diff(skelData_r,1,2)*pixelsize).^2)));
            trajData_r.filtered = (blobFeats_r.intensity_mean >= minIntensity)&...
                (blobFeats_r.area*pixelsize^2 <= maxBlobSize_r)&...
                logical(trajData_r.is_good_ske);
                logical(skelLengths(:)>minSkelLength_r);
            trajData_g.filtered = (blobFeats_g.area*pixelsize^2 <= maxBlobSize_g)&...
                    (blobFeats_g.intensity_mean >= minIntensities_g(numCtr));
            % in/outCluster
            validFrames = trajData_r.frame_number(trajData_r.filtered);
            clusterStatus = zeros(numel(validFrames),3);
            parfor frameCtr = 1:length(validFrames);
                frame = validFrames(frameCtr);
                [inCluster, loneWorms, rest] = getWormClusterStatus2channel(trajData_r, trajData_g, frame, pixelsize, maxNeighbourDist, inClusterRadius, inClusterNeighbourNum);
                clusterStatus(frameCtr,:) = [nnz(inCluster),nnz(loneWorms),nnz(rest)];
            end
            numInCluster = sum(clusterStatus(:,1));
            numLoneWorms = sum(clusterStatus(:,2));
            numRest = sum(clusterStatus(:,3));
            totalnum = numInCluster + numLoneWorms + numRest;
            clusterNumbers(fileCtr,:) = [numInCluster,numLoneWorms,numRest];
            clusterProportion(fileCtr,:)=[numInCluster,numLoneWorms,numRest]./totalnum;
            %% save filenames
            nameSplit = strsplit(filename_g,'/');
            hdf5Name = nameSplit(9);
            hdf5Split = strsplit(hdf5Name{1},'_X1');
            recordingName = hdf5Split(1);
            namestr = recordingName{1};
            recordingNumber = namestr(10:end-1);
            recordingNamesList(fileCtr)= {recordingNumber};
        end
        figure;
        bar(clusterProportion*100,'stacked')
        title([strain ' ' wormnum],'FontWeight','normal')
        xticklabels(recordingNamesList);
        ylim ([0,100])
        ylabel('Relative proportion of worms (%)');
        legend('inCluster','loneWorms','rest')
        figName = strcat('TrackingQualityRed_ClusterProportion_',strain,'_',wormnum,'.fig');
        matrix1Name = strcat('TrackingQualityRed_ClusterProportion_',strain,'_',wormnum,'.mat');
        matrix2Name = strcat('TrackingQualityRed_ClusterNumbers_',strain,'_',wormnum,'.mat');
        savefig(figName);
        save(matrix1Name,'clusterProportion')
        save(matrix2Name,'clusterNumbers')
        close all;
    end
end