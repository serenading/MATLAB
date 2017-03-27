% loads previously saved ClusterProportion calculations from 
% the .mat file and returns a graph with multiple subplots visualising it

close all
clear

strains = {'N2_1','HA_1','npr1_1'};
wormnums = {'40','HD'};
figure;
for numCtr = 1:length(wormnums)
    wormnum = wormnums{numCtr};
    for strainCtr = 1:length(strains)
        strain = strains{strainCtr};
        filename = strcat('TrackingQualityGreen_ClusterProportion_',strain,'_',wormnum);
        load(filename);
        [numRow,~] = size(clusterProportion);
        clusterProp = zeros(numRow,2);
        clusterProp(:,1) = clusterProportion(:,1); % in cluster
        clusterProp(:,2) = 1 - clusterProp(:,1); % out of cluster
        subplot(length(wormnums),length(strains),(numCtr-1)*length(strains)+strainCtr);
        bar(clusterProp*100,'stacked');
        title([strain ' ' wormnum],'FontWeight','normal')
        xlim([0,numRow+1]);
        ylim([0,100]);
        ylabel('Relative proportion of worms (%)');
        xlabel('Recording replicate');
        legend('inCluster','loneWorms')
        hold on
        average = mean(clusterProp(:,1))*100;
        plot(xlim,[average average],'r--');
    end
end
savefig('ClusterProportionsGreen');