function [ x, y] = getWormPositions(trajData, framenumber)
% calculates worm speeds from tracking data for a given frame
% returns the x, y positions and u, v displacement components
currentFrameLogInd = trajData.frame_number==framenumber;
% optionally filter blobs
if isfield(trajData,'filtered')
    currentFrameLogInd = currentFrameLogInd&trajData.filtered;
end
% get positions
x = trajData.coord_x(currentFrameLogInd);
y = trajData.coord_y(currentFrameLogInd);
end