% calculate worm speeds from tracking data and generates heatmap of speed
% for the entire length of the movie

%% set variables
% directory should be set to the skeleton file for the appropriate movie
directory = '/data2/shared/data/twoColour/Results/recording64/recording64.1g100-350TIFF/recording64.1g_X1_skeletons.hdf5';
% set intensity threshold. Set to 100 for single worm, 50 for 40 worm, and
% 40 for high density movies. 
IntensityThres = 40;
% set maximum speed in microns per frame (=50 for movies at 9fps and =150
% for movies at 3 fps)
maxspeed = 50;
% set the number of frames used to generate each column of the heatmap
framespercol = 20;
% set name of speedmatrix file to be saved at the end. For dataset 1, if at Hammersmith,
% use 49:52; if at SK, use 38:41. For dataset 2, if at SK, use 59:62
% matname = strcat({directory(38:41)},{'speed.mat'});
matname = strcat({directory(59:62)},{'.mat'});

%% load trajectory file
TrajData = h5read(directory,'/trajectories_data');
% determine total number of frames in the video
totalframe = max(TrajData.frame_number);
% determine total columns of frames inside the heatmap, ignoring the last
% few frames that won't suffice for a full framebin 
totalcol = floor(totalframe / framespercol);
% generate empty matrix to hold speed values for each column
speedmatrix = zeros(100,totalcol);
% set first frame
firstframe = 1;
% set first column number
colnum = 1;

%% remove data by intensity threshold
    BlobFeats = h5read(directory,'/blob_features');
    ValidWormIndex = BlobFeats.intensity_mean > IntensityThres;
    ValidWormIndex = int32(ValidWormIndex);
    Frames = TrajData.frame_number;
    Frames = Frames .* ValidWormIndex;
    lowIntIndices = find(Frames == 0);
    Frames(lowIntIndices) = [];
    WormIndexJoined = TrajData.worm_index_joined;
    WormIndexJoined = WormIndexJoined .* ValidWormIndex;
    WormIndexJoined(lowIntIndices) = [];
    XCoord = TrajData.coord_x;
    XCoord = XCoord .* single(ValidWormIndex);
    XCoord(lowIntIndices) = [];
    YCoord = TrajData.coord_y;
    YCoord = YCoord .* single(ValidWormIndex);
    YCoord(lowIntIndices) = [];

%% loop through each column
while colnum <= totalcol
    %% calculate speed for each column
    
    % create a vector to loop through for each frame
    FrameList = [firstframe:firstframe+framespercol];
    ii = 1;
    speedlist = cell(1,framespercol);
    
    % loop through each frame
    for ii = 1:numel(FrameList)
        
        % calculates the x, y positions and u, v displacement components
        currentFrameLogInd = Frames == FrameList(ii);
        nextFrameLogInd = Frames == FrameList(ii) + 1;
        wormInds = unique(WormIndexJoined(currentFrameLogInd));
        nWorms = numel(wormInds);
        % get positions
        x = XCoord(currentFrameLogInd);
        y = YCoord(currentFrameLogInd);
        % initialise displacements
        u = NaN(size(x));
        v = NaN(size(y));
        % calculate displacements, checking that there are no tracking errors
        if nnz(currentFrameLogInd)>nWorms
            warning(['Some worm(s) appear(s) more than once in frame ' num2str(FrameList(ii)) '. Cannot calculate speed.'])
        else
            % check which worms continute to next frame
            nextFrameWormLogInd = nextFrameLogInd&ismember(WormIndexJoined,wormInds); %returns logical indices for next frame that have the worm
            overlapLogInd = ismember(wormInds,WormIndexJoined(nextFrameLogInd)); %returns logical indices for worms that appear in both frames
            if nnz(nextFrameWormLogInd) > nnz(overlapLogInd)
                warning(['Some worm(s) from frame ' num2str(FrameList(ii)) ' appear(s) more than once in frame ' num2str(FrameList(ii)) '+1. Cannot calculate speed.'])
            elseif any(overlapLogInd)
                u(overlapLogInd) = XCoord(nextFrameWormLogInd) - x(overlapLogInd);
                v(overlapLogInd) = YCoord(nextFrameWormLogInd) - y(overlapLogInd);
                speed = sqrt(u.^2 + v.^2);
                if any(~overlapLogInd)
                    disp([ num2str(nnz(~overlapLogInd)) ' of ' num2str(nWorms) ' worms did not appear in frame ' num2str(FrameList(ii)) '+1.'])
                end
                % add speed data to a cell
                speedlist{ii} = speed;
                ii = ii+1;
            end
        end
    end
    % compile speeds within the frame bin, i.e. 20 frames
    speedlist = vertcat(speedlist{:});
    % convert speeds from pixel/frame to micron/frame
    speedlistmicron = speedlist/19.5*100;
    % set maximum speed to 50 microns/frame
    removespeed = find(speedlistmicron>maxspeed);
    speedlistmicron(removespeed)=[];
    % retrieve the number of instances that fall within each speed bin
    h = histogram(speedlistmicron,'BinWidth',0.5,'NumBins',100,'Normalization','Probability');
    % add histogram values to the appropriate column of speed matrix
    speedmatrix(:,colnum) = h.Values';
    
    % go onto the next column
    colnum = colnum+1;
    firstframe = firstframe+framespercol;
end

%% save speedmatrix data and plot heatmap
save(char(matname),'speedmatrix')
figure;
imagesc(speedmatrix);set(gca,'YDir','normal')
disp(directory)