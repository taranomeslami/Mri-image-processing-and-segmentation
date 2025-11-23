clc
 clear 
 close all

% .......................dicom     image     reading....T1  W............................................
% ..................................................................................................
 perfix='Dicom images direction\3D_T1-weighted\2024-03-06_10_42_41.0\I10396548\image_';
 fnum=10;
 ext='.dcm';
 fname=[perfix num2str(1) ext];
 info = dicominfo(fname) ;
voxel_size= [info.PixelBandwidth ; info.FormatVersion];
 size1=[info.Rows info.Columns fnum];
 img=zeros(size1);
 hwaitbar= waitbar(0,'reading dicom files');
 for i=2:fnum
     fname=[perfix num2str(i-1) ext]; 
   img(:,:,i)=int16(dicomread(fname));
     waitbar((i)/fnum);
%        montage(img,'Size',[6,8]);
 end
 delete(hwaitbar);
%%each dicom image has average 160 slices
i=slice number;
im=squeeze(img(:,:,i));

% imtool(im,[]);
% title([' slice' num2str(i)]);
% imshow(im,[],'colormap',jet);colorbar
grayImage = uint8(255 * mat2gray(im)); %Convert to uint8 format
name=['slice' num2str(i) '.jpg'];    
fprintf('Finished saving slice %d .jpg image\n',i)
% grayImage= im2double(dcmImagei);
% gray matter
% imtool(grayImage);
% 
% .................................................................................
% ........................skull striping...........................................
% .................................................................................
workspace;  % Make sure the workspace panel is showing.
format long g;
format compact;
fontSize = 20;

% Check that user has the Image Processing Toolbox installed.
hasIPT = license('test', 'image_toolbox');
if ~hasIPT
  % User does not have the toolbox installed.
  message = sprintf('Sorry, but you do not seem to have the Image Processing Toolbox.\nDo you want to try to continue anyway?');
  reply = questdlg(message, 'Toolbox missing', 'Yes', 'No', 'Yes');
  if strcmpi(reply, 'No')
    % User said No, so exit.
    return;
  end
end

% %===============================================================================
% % Read in a standard MATLAB gray scale demo image.
% folder = 'D:\Temporary stuff';
% baseFileName = 'Jones-54-1-jan10-f3.jpg';
% % Get the full filename, with path prepended.
% fullFileName = fullfile(folder, baseFileName);
% % Check if file exists.
% if ~exist(fullFileName, 'file')
%   % File doesn't exist -- didn't find it there.  Check the search path for it.
%   fullFileNameOnSearchPath = baseFileName; % No path this time.
%   if ~exist(fullFileNameOnSearchPath, 'file')
%     % Still didn't find it.  Alert user.
%     errorMessage = sprintf('Error: %s does not exist in the search path folders.', fullFileName);
%     uiwait(warndlg(errorMessage));
%     return;
%   end
% end
% grayImage = imread('C:\Users\laptop2020\Documents\MATLAB\slice13.jpg');
% Get the dimensions of the image.
% numberOfColorBands should be = 1.
[rows, columns, numberOfColorBands] = size(grayImage);
if numberOfColorBands > 1
  % It's not really gray scale like we expected - it's color.
  % Convert it to gray scale by taking only the green channel.
  grayImage = grayImage(:, :, 2); % Take green channel.
end
% Display the original gray scale image.
figure;
subplot(2, 3, 1);
imshow(grayImage, []);
axis on;
title('Original Grayscale Image', 'FontSize', fontSize);
% Enlarge figure to full screen.
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
% Give a name to the title bar.
set(gcf, 'Name', 'Demo by ImageAnalyst', 'NumberTitle', 'Off')

% Let's compute and display the histogram.
[pixelCount, grayLevels] = imhist(grayImage);
subplot(2, 3, 2);
bar(grayLevels, pixelCount);
grid on;
title('Histogram of original image', 'FontSize', fontSize);
xlim([0 grayLevels(end)]); % Scale x axis manually.

% Crop image to get rid of light box surrounding the image
grayImage = grayImage(3:end-3, 4:end-4);
% Threshold to create a binary image
binaryImage = grayImage > 20;
% Get rid of small specks of noise
binaryImage = bwareaopen(binaryImage, 10);
% Display the original gray scale image.
subplot(2, 3, 3);
imshow(binaryImage, []);
axis on;
title('Binary Image', 'FontSize', fontSize);

% Seal off the bottom of the head - make the last row white.
binaryImage(end,:) = true;
% Fill the image
binaryImage = imfill(binaryImage, 'holes');
subplot(2, 3, 4);
imshow(binaryImage, []);
axis on;
title('Cleaned Binary Image', 'FontSize', fontSize);

% Erode away 15 layers of pixels.
se = strel('disk', 15, 0);
binaryImage = imerode(binaryImage, se);
subplot(2, 3, 5);
imshow(binaryImage, []);
axis on;
title('Eroded Binary Image', 'FontSize', fontSize);

% Mask the gray image
finalImage = grayImage; % Initialize.
finalImage(~binaryImage) = 0;
subplot(2, 3, 6);
imshow(finalImage, []);
axis on;
name=['skull stripping slice' num2str(i) '.jpg'];
imwrite(finalImage,name,'jpg');
title('Skull stripped Image', 'FontSize', fontSize);
msgbox('Done with demo');
% hold on;
figure;
imshow(finalImage);
title('final skull stripped')
skullstripped=im2double(finalImage);

%  imtool(skullstripped);

% ...............................................................................
% ...............................denoising.......................................
% ...............................................................................
% 
D=denoising(finalImage);
imshow(D);
hold on;
% ...........................................................................
% ..................................fuzzy edge detection.....................
% ...........................................................................
% 
 fed=FED(skullstripped);

% % .....................................................................
% % ..........................region growing after stripping.............
% % .....................................................................
% % ...........................gray.......matter.........................
y=189; x=97;
J1= regiongrowing(skullstripped,x,y,0.0589);
figure;
subplot(1,3,1),imshow(J1);
title([' slice' num2str(i) 'regiongrowing'],'FontSize',18)
subplot(1,3,2),imshow(skullstripped+J1);
title([' slice' num2str(i) 'regiongrowing''+ original figure'],'FontSize',18)
subplot(1,3,3),imshow(finalImage);
title([' skull stripped slice' num2str(i) 'regiongrowing''+ original figure'],'FontSize',18)
sliceThickness=1;
olume1 =0;
olume2 =0;
f1=denoising(J1);
imshow(f1);
hold on;
for j=1:24
    olume1=olume1 + nnz(im)*sliceThickness;  
        olume2=olume2 + nnz(f1)*sliceThickness;  
end
 disp("Volume of the object"+num2str(i)+" has "+num2str(olume1)+" cubic pixels");
 disp("Volume of the gray matter object"+num2str(i)+" has "+num2str(olume2)+" cubic pixels");

% ....................................................................................
% .....................................white matter regiongrowing...............................
x=124; y=142;
J2= regiongrowing(skullstripped,x,y,0.06);
figure;
subplot(1,3,1),imshow(J2);
title([' slice' num2str(i) 'regiongrowing'],'FontSize',18)
subplot(1,3,2),imshow(skullstripped+J2);
title([' slice' num2str(i) 'regiongrowing''+ original figure'],'FontSize',18)
subplot(1,3,3),imshow(finalImage);
title([' skull stripped slice' num2str(i) 'regiongrowing''+ original figure'],'FontSize',18)
sliceThickness=1;
olume1 =0;
olume3 =0;
f2=denoising(J2);
imshow(f2);
hold on;
% v2=zeros(1,48);
for j=1:24
    olume1=olume1 + nnz(im)*sliceThickness;  
        olume3=olume3 + nnz(f2)*sliceThickness;  
end
%  disp("Volume of the object"+num2str(i)+" has "+num2str(olume1)+" cubic pixels");
 disp("Volume of the white matter object"+num2str(i)+" has "+num2str(olume2)+" cubic pixels");
  totalvolume=olume2+olume3;
 disp("Volume of the total brain volume is "+num2str(i)+" has "+num2str(totalvolume)+" cubic pixels");
pr1=(totalvolume.\olume2).*100;
pr2=(totalvolume.\olume3).*100;
 disp("Volume of the graye matter pixel on total brain volume is "+num2str(i)+" has "+num2str(pr1)+" cubic pixels");
  disp("Volume of the white matter pixel on total brain volume is "+num2str(i)+" has "+num2str(pr2)+" cubic pixels");
