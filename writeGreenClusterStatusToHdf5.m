%%%%%%%%%%%%% working progress

close all
clear

%% set parameters
strains = {'npr1','N2'};
wormnums = {'40','HD'};
dataset = 2; % set to 1 for first dataset and set to 2 for second dataset (TwoColour)
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
        if dataset ==2
        filenames = importdata([strains{strainCtr} '_' wormnum '_g_list.txt']);
        else 
        filenames = importdata([strains{strainCtr} '_' wormnum '_list.txt']);
        end
        numFiles = length(filenames);
        for fileCtr = 1:numFiles
            filename = filenames{fileCtr};
            trajData = h5read(filename,'/trajectories_data');
            if strcmp(wormnum,'1W') == 0
                frameList = [1:32400];
            else
                frameList = [1:10800];
            end
            parfor frame = 1:length(frameList)
                [inCluster, loneWorms, rest] = getWormClusterStatus...
                    (trajData, frame, pixelsize,...
                    maxNeighbourDist, inClusterRadius, inClusterNeighbourNum);
            end
        end
    end
end