close all, clear all; close all;

%% Hyperspectral Phantom Generation using Random Images
% Original by JH Yoon (%% Random spectral Generation)
% Edited by changh95
%
% A code to generate a 2.5d hypercube model based on segmented regions on a 2D
% image.
%
% Steps:
%       1. Load image
%       2. (if colour) Count number of colours from histogram
%       3. (if colour) Convert RGB into CIE l*a*b* colours, then perform
%       k-means clustering to segment regions.
%       4. (if grayscale) Segment black & white regions
%       5. Generate random spectral bands
%       6. Hyperspectral labelling on segmented regions

%% Random image selection

%Uncomment if random images are not required
    %img = imread('.jpg');

path = cd();
cd images %Prior to running this program, store all images in /images folder
image_names = [];
images = dir('*.png');
num_images = size(images,1)-1;
for k = 1:1:num_images
    image_names = [image_names ; {images(k).name}]
end
img = image_names(randi(num_images),1);
img = imread(img{1:1}); %Read image
figure();
imshow(img);
cd(path)

%% Image Preparation & Questdlg for B/W images

imshow(img);
img = rgb2gray(img);

img_elements = size(img,1) * size(img,2);
    
answer = questdlg('Is the image black & white?','BW Images','Yes','No','No')
switch answer
    case 'Yes'
        image_BW = true;
    case 'No'
        image_BW = false;
end

%% Histogram-based Segmentation for colour images

% TODO: Write for k-means clustering

if image_BW == false
    % generate inverse histogram
    inv_hist = imhist(255-img);
    % find peaks from inverse histogram
    % (peaks in inverse histogram = troughs in normal histogram)
    [pks,pks_location] = findpeaks(inv_hist);
    % filter out small peaks to keep significant peaks
    % 0 and 255 values are also added.
    pks_sig = [0 0];
    for i = 1:1:size(pks)
        if pks(i) > 0.01 * img_elements
            pks_sig = [pks_sig; pks(i) pks_location(i)];
        end
    end
    pks_sig = [pks_sig; 0 255];
    
    % assign labels
    img_label = zeros(size(img,1),size(img,2));
    
    for i = 1:1:size(pks_sig,1)-1
        temp = i * squeeze(pks_sig(i,2)<=img & img<pks_sig(i+1,2));
        img_label = img_label + temp;
    end
end
%% Random Spectral Band Generation

%Parameter Registration via Dialogue
prompt = {'Enter spec channel number:','Enter color number:'};
title = 'Parameters'; dims = [1 35]; definput = {'100','6'};
answer = inputdlg(prompt,title,dims,definput);

%Parameters
spec_channel = [1:1:str2num(answer{1, 1})];
color_number = str2num(answer{2, 1});
spectral_distribution=[];

%Plot spectral distribution
for i=1:1:color_number
    spec=raylpdf(spec_channel,10);
    spec=circshift(spec,i*10)*(0.7+0.3*rand(1));
%     spec=ones(1,100)-spec*12;
    spectral_distribution=[spectral_distribution; spec];
    figure(33),
    plot(spec),hold on;
    pause(0.1)
end

spectral_distribution=spectral_distribution*12;
%% Free up memory

clearvars -except spec_channel color_number spectral_distribution img img_label image_BW

%% HyperCube Generation

TD_cube=zeros(size(img,1),size(img,2),size(spectral_distribution,2)); %reference hypercube generation

if image_BW == true
    img=squeeze(img<200);
    img_label=bwlabeln(img);
end
% Hyperspectral labeling
% figure(33), imagesc(outside),axis image
    %img_label=bwlabeln(img_labels);
for ii=1:1:max(max(img_label))
    target=squeeze(img_label==ii);
%     figure(33), imagesc(target),axis image
%     pause(0.1)
% end
    spec_num=randperm(color_number); %% Fixed randperm(6) into randperm(color_number)
    spec_dist=spectral_distribution(spec_num(1),:);
    spec_dist=reshape(spec_dist,[1 1 length(spec_dist)]);
    TD_spec=repmat(spec_dist,[size(img,1),size(img,2)]);   
    for jj=1:1:size(TD_cube,3)
        TD_spec(:,:,jj)=squeeze(TD_spec(:,:,jj)).*target;
%         figure(33), imagesc(squeeze(TD_spec(:,:,jj))),axis image, title(num2str(jj))
%         pause(0.1)
    end
    TD_cube=TD_cube+TD_spec;
end
TD_cube=ones(size(TD_cube,1),size(TD_cube,2),size(TD_cube,3))-TD_cube; %%Why??
for ii=1:1:size(TD_spec,3)
    figure(33),
    imagesc(squeeze(TD_cube(:,:,ii)),[0 1]),title(num2str(ii))
    pause(0.1);
end

figure(33), imagesc(sum(TD_cube,3)),axis image,colormap('hot')