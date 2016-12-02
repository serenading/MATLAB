% Script for generating a histogram of the speed distribution for a single movie frame

%% Set the movie and frame
Directory = '/data2/shared/data/recording 37/Results/recording 37.1 green 100-350 TIFF/recording 37.1 green_X1_trajectories.hdf5';
FrameNumber = 5000;
%tic
%% Generate a list of objects in that frame for speed calculation
% load current trajectory data
trajData = h5read(Directory,'/plate_worms');

% list objects of interest for the frame
% pre-allocate final ObjList
ObjList2 = zeros(1,nnz(trajData.frame_number == FrameNumber));
% set counter for ObjList2
x = 1;
% find obj that match specified frame number
ObjList1 = find(trajData.frame_number == FrameNumber);
for ii = 1:numel(ObjList1)
    % check the object isn't the last frame of the object's trajectory
    if trajData.worm_index_joined(ObjList1(ii)) == trajData.worm_index_joined(ObjList1(ii)+1)
        ObjList2(x) = ObjList1(ii);
        x = x+1;
    end
end
ObjList2 = nonzeros(ObjList2);

%% calculate speed
% pre-allocate a list of speeds for plotting
speedList = zeros(1,numel(ObjList2));
% loop through individual elements within the list of objects
for jj = 1:numel(ObjList2)
    xdiff = trajData.coord_x(ObjList2(jj))-trajData.coord_x(ObjList2(jj)+1);
    ydiff = trajData.coord_y(ObjList2(jj))-trajData.coord_y(ObjList2(jj)+1);
    speed = sqrt(xdiff^2 + ydiff^2);
    % add speed to the list
    speedList(jj) = speed;
end
%toc
%% Plot histogram

histogram(speedList,'BinWidth',0.1)
xlabel('speed','FontSize',20)
ylabel('incidence','FontSize',20)
set(gca,'FontSize',15)