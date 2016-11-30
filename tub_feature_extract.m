% script for detecting tubulin structure and extracting features
% written as an exercise to Andre's mini project 2016

%% retrieving image
% set directory
FilePath =  '/end/home/sding1/Pictures/HeLa10Class2DImages_16bit_tiff/tubul/prot/r14jul98.tubul.03--1---2.tif' 
% read image file
I = imread(FilePath);
%% remove background pixels using the crop
mask1 = I>15;

if max(I(:))<=255
   I = uint8(mask1).*uint8(I);
else
    I=uint16(mask1).*(I);
end

%% generating filter
% make gaussian filter
gFilter = fspecial('gaussian',7,1);
% make laplace filter
laplaceFilter = fspecial('laplacian',0.5);
%laplace of gaussian combine two filters
LoG = conv2(gFilter,laplaceFilter);

%% display filtered image
filterI = imfilter(I,LoG);
imshow(filterI*20)