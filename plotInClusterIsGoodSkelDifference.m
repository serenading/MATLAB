close all
clear

strains = {'npr1','N2'};
wormnums = {'40','HD'};
for numCtr = 1:length(wormnums)
    wormnum = wormnums{numCtr};
    for strainCtr = 1:length(strains)
        strain = strains{strainCtr};
        filename1 = strcat('TrackingQualityRed_ClusterProportion_',strain,'_',wormnum,'_withoutIsGoodSkel.mat');
        load(filename1);
        clusterProp1 = clusterProportion;
        filename2 = strcat('TrackingQualityRed_ClusterProportion_',strain,'_',wormnum,'.mat');
        load(filename2);
        clusterProp2 = clusterProportion;
        compare = zeros(size(clusterProp1,1),9);
        compare(:,1:3)=clusterProp1;
        compare(:,4:6)=clusterProp2;
        compare(:,7:9)=clusterProp1-clusterProp2;
    end
end