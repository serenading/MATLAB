% check how much data is thrown away by is_good_skel filter

% takes saved data from two previous red movie QC's, one with
% _is_good_skel filter applied and one without, and generates two
% grouped stacked bar plots (one in absolute numbers and one in
% percentages) showing how much data is filtered out by is_good_skel filter

% not sure how to put label for the grouped stacked bars, but first bar is
% inCluster, second bar is loneWorms, and third bar is rest for each movie

strains = {'N2'};
wormnums = {'40','HD'};
for numCtr = 1:length(wormnums)
    wormnum = wormnums{numCtr};
    for strainCtr = 1:length(strains)
        strain = strains{strainCtr};
        % load saved data
        filename1 = strcat('TrackingQualityRed_ClusterNumbers_',strain,'_',...
            wormnum,'_withoutIsGoodSke.mat');
        load(filename1);
        withoutGoodSkel = clusterNumbers;
        filename2 = strcat('TrackingQualityRed_ClusterNumbers_',strain,'_',...
            wormnum,'.mat');
        load(filename2);
        withGoodSkel = clusterNumbers;
        difference = withoutGoodSkel - withGoodSkel;
        % stacked bar matrix as numbers
        stackData = zeros(length(withoutGoodSkel),3,2); % pre allocate
        stackData(:,:,1) = withGoodSkel;
        stackData(:,:,2) = difference;
        % generate group label
        filenames = importdata([strains{strainCtr} '_' wormnum '_r_list.txt']);
        numFiles = length(filenames);
        recordingNamesList = cell(numFiles,1);
        for fileCtr = 1:numFiles
            filename = filenames{fileCtr};
            nameSplit = strsplit(filename,'/');
            hdf5Name = nameSplit(9);
            hdf5Split = strsplit(hdf5Name{1},'_X1');
            recordingName = hdf5Split(1);
            namestr = recordingName{1};
            recordingNumber = namestr(10:end-1);
            recordingNamesList(fileCtr)= {recordingNumber};
        end
        % plot numbers figure;
        plotBarStackGroups(stackData,recordingNamesList)
        title([strain ' ' wormnum],'FontWeight','normal')
        legend('retained','filtered by is\_good\_skel')
        figname = strcat('TrackingQualityRed_IsGoodSkel_effect_',strain,'_',wormnum,'_numbers.fig');
        ylabel('Number of datapoints')
        savefig(figname);
        close all
        % stacked bar matrix as percentages
        stackData2 = 100*stackData(:,:,1:2)./(stackData(:,:,1)+stackData(:,:,2));
        % plot percentage figure;
        plotBarStackGroups(stackData2,recordingNamesList)
        title([strain ' ' wormnum],'FontWeight','normal')
        legend('retained','filtered by is\_good\_skel')
        figname = strcat('TrackingQualityRed_IsGoodSkel_effect_',strain,'_',wormnum,'_percentage.fig');
        ylabel('Percentage of data')
        savefig(figname);
        close all
    end
end