% takes the "plotvalue" struct saved from previously saved
% TrackingQualityGreen matrix and plots a stacked bar graph for each movie
% showing the proportion of data remaining after each filter

strains = {'npr1','N2'};
wormnums = {'40','HD'};

for numCtr = 1:length(wormnums)
    wormnum = wormnums{numCtr};
    for strainCtr = 1:length(strains)
        strain = strains{strainCtr};
        % load saved plotvalue data
        filename = strcat('TrackingQualityGreen_',strain,'_',wormnum,'.mat');
        load(filename)
        % fill Table with original values in columns 1-5, calculate
        % differences from numTracks in columns 6-9, and calculate
        % percentage as numTracks in columns 10-13
        numTracks = plotvalues.Tracks;
        Table = zeros(length(numTracks),5);
        Table(:,1) = numTracks;
        Table(:,2) = plotvalues.MinInt;
        Table(:,3) = plotvalues.MaxBlobSize;
        Table(:,4) = Table(:,1) - Table (:,2);
        Table(:,5) = Table(:,2) - Table (:,3);
        percentageTable = zeros(length(numTracks),3);
        percentageTable(:,1) = 100* Table(:,3)./Table(:,1);
        percentageTable(:,2:3) = 100* Table (:,4:5)./Table(:,1);
        C = struct2cell(plotvalues);
        recordingNames = C(1,:);
        % plot
        figure;
        bar(percentageTable,'stacked')
        title([strain ' ' wormnum],'FontWeight','normal')
        ylim([0 100])
        ylabel('Proportion of overall tracking data (%)')
        xlabel('Recording Name')
        legend('good','MinInt','MaxBlobSize')
        xticklabels(recordingNames);
        % save figure
        figName = strcat('TrackingQualityGreen_',strain,'_',wormnum,'_StackedBar.fig');
        savefig(figName);
        close all;
    end
end        