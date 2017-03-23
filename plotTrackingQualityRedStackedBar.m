% takes the "plotvalue" struct saved from previously saved
% TrackingQualityRed matrix and plots a stacked bar graph for each movie
% showing the proportion of data remaining after each filter

strains = {'npr1','N2'};
wormnums = {'40','HD'};

for numCtr = 1:length(wormnums)
    wormnum = wormnums{numCtr};
    for strainCtr = 1:length(strains)
        strain = strains{strainCtr};
        % load saved plotvalue data
        filename = strcat('TrackingQualityRed_',strain,'_',wormnum,'.mat');
        load(filename)
        % fill Table with original values in columns 1-5, calculate
        % differences from numTracks in columns 6-9, and calculate
        % percentage as numTracks in columns 10-13
        numTracks = plotvalues.Tracks;
        Table = zeros(length(numTracks),9);
        Table(:,1) = numTracks;
        Table(:,2) = plotvalues.MinInt;
        Table(:,3) = plotvalues.MaxBlobSize;
        Table(:,4) = plotvalues.HasSkel;
        Table(:,5) = plotvalues.HasGoodSkel;
        Table(:,6) = Table(:,1) - Table (:,2);
        Table(:,7) = Table(:,2) - Table (:,3);
        Table(:,8) = Table(:,3) - Table (:,4);
        Table(:,9) = Table(:,4) - Table (:,5);
        percentageTable = zeros(length(numTracks),5);
        percentageTable(:,1) = 100* Table(:,5)./Table(:,1);
        percentageTable(:,2:5) = 100* Table (:,6:9)./Table(:,1);
        C = struct2cell(plotvalues);
        recordingNames = C(1,:);
        % plot
        figure;
        bar(percentageTable,'stacked')
        title([strain ' ' wormnum],'FontWeight','normal')
        ylim([0 100])
        ylabel('Proportion of overall tracking data (%)')
        xlabel('Recording Name')
        legend('good','MinInt','MaxBlobSize','HasSkel','HasGoodSkel','MinSkelLength')
        xticklabels(recordingNames);
        % save figure
        figName = strcat('TrackingQualityRed_',strain,'_',wormnum,'_StackedBar.fig');
        savefig(figName);
        close all;
    end
end        