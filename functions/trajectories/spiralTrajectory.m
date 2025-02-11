% ----------------------------
%  Pseudo sprial k-space trajectory
%  For MR Solutions custom 3D k-space (exLUT)
%
%  Gustav Strijkers
%  Oct 2023
%
% ----------------------------


%% clear all

clc;
clearvars;
close all force;

%% dimlist

dims = [80 80];

% %dims = [ ...
%     64 32; ...
%     64 48; ...
%     64 64; ...
%     80 80; ...
%     96 48; ...
%     96 64; ...
%     96 96; ...
%     128 24; ...
%     128 32; ...
%     128 48; ...
%     128 64; ...
%     128 96; ...
%     128 128; ...
%     160 24; ...
%     160 32; ...
%     160 48; ...
%     160 64; ...
%     160 96; ...
%     160 128; ...
%     160 160; ...
%     192 24; ...
%     192 32; ...
%     192 48; ...
%     192 64; ...
%     192 96; ...
%     192 128; ...
%     192 160; ...
%     192 192 ...
%     ];

for dnr = 1:size(dims,1)

    for anr = [1 3 6 10]

        %% Initialization

        dimy = dims(dnr,1);     % k-space y dimension (no_views)
        dimz = dims(dnr,2);     % k-space z dimension (no_views_2)
        order = 1;              % 0 = one direction; 1 = back and forth,
        angleNr = anr;          % golden angle number (see list below)
        rev = 1;                % number of revolutions
        display = true;        % show result true / false
        outputdir = pwd;        % output directory

        % Tiny golden angles
        tinyGoldenAngles = [111.24611, 68.75388, 49.75077, 38.97762, 32.03967, 27.19840, 23.62814, 20.88643, 18.71484, 16.95229];



        %% Make a spiral

        % Start with 0 angle
        angle = 0;
        numberOfSpiralPoints = 256;

        % Start with same x and y radius
        dimYZ = 256;
        radiusY = floor(dimYZ/2);
        radiusZ = floor(dimYZ/2);
        center = [radiusY,radiusZ];

        % Last point on spiral
        edge = center + [round(radiusY * cosd(angle)),round(radiusZ * sind(angle))];

        % Radius of first point to second
        r = norm(edge-center);

        % Angle between two point wrt the y-axis
        thetaOffset = tan((edge(2)- center(2))/(edge(1)-center(1)));

        % Radius as spiral decreases
        t = linspace(0,r,numberOfSpiralPoints);

        % Angle as spiral decreases
        theta = linspace(0,2*pi*rev,numberOfSpiralPoints) + thetaOffset;

        % The final spiral
        y0 = 2*cos(theta).*t.*t/numberOfSpiralPoints + center(1);
        z0 = 2*sin(theta).*t.*t/numberOfSpiralPoints + center(2);



        %% Repeat with golden angle increments

        ky = [];
        kz = [];
        numberOfSpirals = 2000;

        for ns = 1:numberOfSpirals

            % Increment the angle
            angle = angle + tinyGoldenAngles(angleNr);

            % Rotate the spiral
            y =  (y0-center(1))*cosd(angle) + (z0-center(2))*sind(angle) + center(1);
            z = -(y0-center(1))*sind(angle) + (z0-center(2))*cosd(angle) + center(2);

            % Scale to correct y and z dimensions;
            y = y * dimy/dimYZ;
            z = z * dimz/dimYZ;

            if order == 1 && mod(ns,2) == 1
                y = flip(y);
                z = flip(z);
            end

            % Add the spiral to the list
            ky = [ky, y]; %#ok<*AGROW>
            kz = [kz, z];

        end


        %% Discretize and remove repeats

        % Discretize
        ky = floor(ky - dimy/2);
        kz = floor(kz - dimz/2);

        % List of k-space points
        kSpaceList = [ky',kz'];

        % Remove repeats
        for i = 1:100
            idx = find(~any(diff(kSpaceList), 2))+1;
            kSpaceList(idx, :) = [];
        end

        % Limit number of [0 0]s vy removing half of them
        loc = find(kSpaceList(:,1) == 0 & kSpaceList(:,2)==0);
        loc = loc(1:2:end);
        kSpaceList(loc,:) = [];


        disp(min(kSpaceList))
        disp(max(kSpaceList))


        %% export matrix

        kSpaceList = kSpaceList(1:dimy*dimz,:);
        disp(length(kSpaceList))

        if order == 1
            ord = 'r';
        else
            ord = 'o';
        end

        filename = strcat(outputdir,filesep,'Spiral_y=',num2str(dimy),'_z=',num2str(dimz),'_a=',num2str(round(tinyGoldenAngles(angleNr),2)),'_r',num2str(rev),'.txt');
        fileID = fopen(filename,'w');

        for i = 1:length(kSpaceList)

            fprintf(fileID,num2str(kSpaceList(i,1)));
            fprintf(fileID,'\n');
            fprintf(fileID,num2str(kSpaceList(i,2)));
            fprintf(fileID,'\n');

        end

        fclose(fileID);

    end

end

%% Display the trajectory true/false

if display

    figure(1); %#ok<UNRCH>
    plot1 = scatter(kSpaceList(1,1),kSpaceList(1,2),'s');
    set(gcf, 'Position', [100, 100, 700, 600])
    xlim([-40,40]);
    ylim([-40,40]);

    for i=1:length(kSpaceList)
        plot1.XData = kSpaceList(1:i,1);
        plot1.YData = kSpaceList(1:i,2);
        pause(0.000001);
    end

    figure(2);
    DataDensityPlot(kSpaceList(:,1),kSpaceList(:,2),20);
    set(gcf, 'Position', [1000, 100, 700, 600])
    xlim([-40,40]);
    ylim([-40,40]);

end


