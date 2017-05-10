% Filter for small clusters (2-4 neighbrs) using distance to 10 nearest neighbrs written to red hdf5 files. 
% Returns matrices with logical indices for small clusters, and nnz values
% of small clusters
% Generates bar graphs to compare small cluster frequencies across strains and densities.

close all
clear

%% set parameters
strains = {'npr1','N2'};
wormnums = {'40','HD'};
minIntensities_g = [60, 40];
maxBlobSize_g = 1e4;
pixelsize = 100/19.5; % 100 microns is 19.5 pixels
loneClusterRadius = 2000;
inClusterRadius = 500;
minNumNeighbrs = [2,3,4];

%% go through different strains, densities, and movies
for numCtr = 1:length(wormnums)
    wormnum = wormnums{numCtr};
    for strainCtr = 1:length(strains)
        strain = strains{strainCtr};
        % load files
        filenames_g = importdata([strains{strainCtr} '_' wormnum '_g_list.txt']);
        numFiles = length(filenames_g);
        for fileCtr = 1:numFiles
            filename_g = filenames_g{fileCtr};
            trajData_g = h5read(filename_g,'/trajectories_data');
            blobFeats_g = h5read(filename_g,'/blob_features');
            numCloseNeighbr_g = h5read(filename_g,'/num_close_neighbrs');
            neighbrDist_g = h5read(filename_g,'/neighbr_distances');
            % filter worms by intensity and blob size
            trajData_g.filtered = (blobFeats_g.area*pixelsize^2 <= maxBlobSize_g)&...
                    (blobFeats_g.intensity_mean >= minIntensities_g(numCtr));
            % filter for small clusters and write logical indices
            numNeighbrs = length(minNumNeighbrs);
            smallClusterInd = zeros(length(trajData_g.filtered),numNeighbrs);
            for neighbrCtr = 1:length(minNumNeighbrs)
                neighbrNum = minNumNeighbrs(neighbrCtr);
                smallClusterInd(:,neighbrCtr) = trajData_g.filtered&...
                    numCloseNeighbr_g== neighbrNum&...
                    neighbrDist_g(:,neighbrNum+1)>=loneClusterRadius;
            end
            % write number of clusters with 2-4 neighbors
            smallClusterNum(strainCtr,numCtr,fileCtr,1)=nnz(smallClusterInd(:,1));
            smallClusterNum(strainCtr,numCtr,fileCtr,2)=nnz(smallClusterInd(:,2));
            smallClusterNum(strainCtr,numCtr,fileCtr,3)=nnz(smallClusterInd(:,3));
        end
    end
end
%% plot graph
for neighbrCtr = 1:length(minNumNeighbrs);
    neighbrNum = minNumNeighbrs(neighbrCtr);
    figure;
    for numCtr = 1:length(wormnums)
        wormnum = wormnums{numCtr};
        for strainCtr = 1:length(strains)
            strain = strains{strainCtr};
            subplot(2,2,(numCtr-1)*length(strains)+strainCtr)
            bar(squeeze(smallClusterNum(numCtr,strainCtr,:,neighbrCtr)))
            title([strain ' ' wormnum],'FontWeight','normal')
        end
    end
    figName = strcat('smallCluster_',num2str(minNumNeighbrs(neighbrCtr)),'neighbrs_loneRadius',num2str(loneClusterRadius),'.fig');
    savefig(figName)
    %close all
end