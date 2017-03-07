% plot area distribution for tracked objects to work out the threshold for
% cutting off large pharynx clumps

% retrieve the list of files to plot, one line at a time
fid = fopen('list2plot.txt');
directory = fgetl(fid);

% set counter for assigning line color
ii = 1;

while ischar(directory)
    disp(directory)

% load trajectory data
    trajData = h5read(directory,'/trajectories_data');
    area = trajData.area;

% plot distribution
    plotcolor = colorcube(15);
    histogram(area,'BinWidth',1,'DisplayStyle','stairs','EdgeColor',plotcolor(ii,:),'Normalization','countdensity')  
    xlabel('area','FontSize',20)
    ylabel('occurance','FontSize',20)
    set(gca,'FontSize',15)
    hold on

% create logical index for given threshold
%IntLogInd = BlobFeats.intensity_mean > 100;
%trajData = trajData.* IntLogInd;
%lowIntIndices = find(trajData == 0);
%trajData(lowIntIndices) = [];
   
   % go to the next line/file
    directory = fgetl(fid);
    ii = ii+1;
   end
legend('1','2','3','4','5','6','7','8','9','10','11')
fclose(fid);
fprintf 'Done plotting\n'
   