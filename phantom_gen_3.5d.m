%% 4D Hypercube target generation
% by Hyunggi Chang
%
% Steps:
%       1. Load image
%       2. Generate random spectral bands
%       3. Hyperspectral labelling on the image
%       4. Define 3D point cloud geometry
%       5. Generate 3D point cloud and visualise

clc; clear; close all;

%% Load image

% Load binarized 2D image 
% TODO: Add colour segmentation feature
%img = imbinarize(rgb2gray(imread('USAF.png')));
img = imread('USAF.png');
img = rgb2gray(img);

%% Generate random spectral bands

spec_channel=[1:1:100];
color_number=6;
spectral_distribution=[];
for i=1:1:color_number
    spec=raylpdf(spec_channel,10);
    spec=circshift(spec,i*10)*(0.7+0.3*rand(1));
    spectral_distribution=[spectral_distribution; spec];
    figure(11),
    plot(spec),hold on;
    pause(0.1)
end
spectral_distribution=spectral_distribution*12;
%% Hyperspectral labelling on USAF target

TD_cube=zeros(size(img,1),size(img,2),size(spectral_distribution,2));
img=squeeze(img<200);
img_label=bwlabeln(img);

for ii=1:1:max(max(img_label))
    target=squeeze(img_label==ii);
    spec_num=randperm(color_number); 
    spec_dist=spectral_distribution(spec_num(1),:);
    spec_dist=reshape(spec_dist,[1 1 length(spec_dist)]); % create intensity channel
    TD_spec=repmat(spec_dist,[size(img,1),size(img,2)]);  % all pixels 
    for jj=1:1:size(TD_cube,3)
        TD_spec(:,:,jj)=squeeze(TD_spec(:,:,jj)).*target; % target masking
    end
    TD_cube=TD_cube+TD_spec; % update total hypercube
end
TD_cube=ones(size(TD_cube,1),size(TD_cube,2),size(TD_cube,3))-TD_cube; %%Why??
for ii=1:1:size(TD_spec,3)
    figure(22),
    imagesc(squeeze(TD_cube(:,:,ii)),[0 1]),title(num2str(ii))
    pause(0.1);
end

figure(33), imagesc(sum(TD_cube,3)),axis image,colormap('hot')
%% Define 3D point cloud geometry and intensity layer
% We slice the TD_cube by every wavelength intervals, 
% and 3D warp the image plance slice into U-tubes.

% Define the geometry of U-tube cross-section
radius_tube = size(TD_cube,2)/pi;
theta = 180:-180/(size(TD_cube,2)-1):0;
elements = size(TD_cube,1) * size(TD_cube,2) % elements in single plane

% Define 3D point cloud geometry
pts_location = zeros(elements,3); %[xyz;xyz;xyz;xyz...]
temp = 0;

for ii = 1:1:size(TD_cube,1)
    for jj = 1:1:size(TD_cube,2)
        pts_location(temp+jj,1:3) = [radius_tube*cosd(theta(jj)) radius_tube*sind(theta(jj)) ii];
        %%%%%I FIXED IT
    end
    temp = temp + size(TD_cube,2); % to write all xyzPoints in single list
end

% Generate intensity layers
pts_intensity = zeros(elements, 1, size(TD_cube,3));
temp = zeros(size(TD_cube,1),size(TD_cube,2));

for ii = 1:1:size(TD_cube,3)
    temp = TD_cube(:,:,ii);
    temp = temp';
    pts_intensity(:,1,ii) = reshape(temp,[],1);
end

%% pcshow function doesn't let me set a custom colormap range from 0 to 1.
%So I put an arbitary value of 0 to ensure 0~1 range for intensity.

pts_intensity(1,1,:) = 0;

%% Generate point cloud and visualise

figure(44)

ptClouds = {};
colorMap = linspace(0,1,elements)';

% Register intensity to 3D point cloud
for ii = 1:1:size(pts_intensity,3)
    ptClouds(1,ii)= {pointCloud(pts_location,'Intensity',pts_intensity(:,:,ii))};
end

% Visualise
for jj = 1:1:size(ptClouds,2)
    pcshow(ptClouds{1,jj});
    colorbar;
    title(num2str(jj));
    pause(0.1);
end
