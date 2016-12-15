% converted some masked hdf5 frames to tiffs to run piv lab on them
firstFrame = 1;
nFrames = 30000;
pathName = '/Volumes/behavgenom_archive$/Serena/masked videos/26.10.16 recording 37/recording 37.1 green 100-350 TIFF/';
hdf5fileName = 'recording 37.1 green_X1.hdf5';
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