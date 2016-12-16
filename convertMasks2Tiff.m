% converted some masked hdf5 frames to tiffs to run piv lab on them
firstFrame = 5000;
nFrames = 500;
pathName = '/data2/shared/data/MaskedVideos/recording 38.8 green 100-200 TIFF/';
hdf5fileName = 'recording 38.8 green_X1.hdf5';
testImages = h5read([pathName hdf5fileName],'/mask',[1 1 firstFrame],[2560 2160 nFrames]);
% set parameters
imgdata = testImages(:,:,1);
tagstruct.ImageLength = size(imgdata,1);
tagstruct.ImageWidth = size(imgdata,2);
tagstruct.Photometric = 1;
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
tagstruct.BitsPerSample = 8;
% make new sub-folder for the masked tiffs
mkdir(pathName,'maskedTiffs')
% loop through frames
for ii=1:nFrames
t = Tiff([pathName '/maskedTiffs/maskedTiff_' num2str(ii) '.tif'],'w');
imgdata = testImages(:,:,ii);
t.setTag(tagstruct)
t.write(imgdata)
t.close()
end