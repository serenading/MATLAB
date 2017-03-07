% plot intensity distribution to work out the threshold for cutting off
% larve data

% retrieve the list of files to plot, one line at a time
fid = fopen('list2plot.txt');
directory = fgetl(fid);

% set counter for assigning line color
ii = 1;

while ischar(directory)
    disp(directory)

% load intensities data
BlobFeats = h5read(directory,'/blob_features');
%trajData = h5read(directory,'/trajectories_data');

% plot distribution
    plotcolor = colorcube(15);
    histogram(BlobFeats.intensity_mean,'BinWidth',1,'DisplayStyle','stairs','EdgeColor',plotcolor(ii,:),'Normalization','countdensity')  
    xlabel('Intensity','FontSize',20)
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
   