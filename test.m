
%{
Perform a ZEST at each location given in locations.
Inter-stimulus interval is a random in the range ISI.

Author: Andrew Turpin aturpin@unimelb.edu.au
Date: 7 Feb 2019
%}

SCREEN_SIZE = [1280 800];  % window size to show in pixesl [w h]
PIXELS_PER_DEGREE = 30;  % depends on viewing distance and monitor res.

BACKGROUND_COLOR  = 128;

STIMULUS_RADIUS   = 0.43/2;    % degrees 
STIMULUS_DURARION = 200/1000;  % seconds
RESPONSE_WINDOW   = 1500/1000; % seconds

ISI = [0.4 0.6]; % inter-stimulus interval is a random in this range seconds

FIX_LEN = 15;   % length of cross hairs fixation marker, pixels (should be odd)
FIX_W = 1;     % width of cross hairs fixation marker, pixels (odd)
FIX_COLOR = 255;

  % locations in degrees
LOCATIONS = [3 0;2.25 0;1.5 0;0.75 0;0 0;-0.75 0;-1.5 0;-2.25 0;-3 0];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% open window for stimuli and put up fixation marker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cx = SCREEN_SIZE(1) / 2;
cy = SCREEN_SIZE(2) / 2;

imshow(BACKGROUND_COLOR * ones(SCREEN_SIZE(2), SCREEN_SIZE(1), 'uint8'), 'Border', 'tight');
set(gcf,'MenuBar','none');

fix_image = BACKGROUND_COLOR * ones(FIX_LEN, FIX_LEN, 'uint8');
m = ceil(FIX_LEN/2);
w = ceil(FIX_W/2);
fix_image(m + (-w:w), 1:FIX_LEN) = FIX_COLOR;
fix_image(1:FIX_LEN, m + (-w:w)) = FIX_COLOR;
image('XData',cx-m, 'YData',cy-m, 'CData',fix_image);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% setup a zest state for each location
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
states = {};
for xy = LOCATIONS.'
    x_pix = round(cx + (xy(1,1) * PIXELS_PER_DEGREE));
    y_pix = round(cy + (xy(2,1) * PIXELS_PER_DEGREE));
    p = Presenter(x_pix, y_pix, ...
                  round(STIMULUS_RADIUS*PIXELS_PER_DEGREE), ...
                  BACKGROUND_COLOR, ...
                  STIMULUS_DURARION, RESPONSE_WINDOW);
        % prior has leading zeros for values below BACKGROUND_COLOR
        % plus a little bit (to avoid floor effects), and uniform above that
    prior = horzcat(zeros(1,BACKGROUND_COLOR-10), ones(1,266-BACKGROUND_COLOR));
    prior = prior ./ sum(prior);
    
    states = [states, Zest(prior, BACKGROUND_COLOR, p)];
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% now loop through stepping a random state until all are finished
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
unfinished = 1:length(LOCATIONS);
while length(unfinished) > 0
    i = randi(length(unfinished()));
    z = states(unfinished(i));
    z.step();
    fprintf("Loc: %2d %s\n", unfinished(i), z.getPresentMsg());
    if z.stop()
        fprintf("finished location %d\n", unfinished(i));
        unfinished(i) = [];
    end
    
    pause(ISI(1) + (ISI(2) - ISI(1)) * rand());   % inter-stimulus interval
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% print results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:size(states,2)
    s = states(i);
    fprintf("Location %2d nump= %2d final= %4.2f\n",i,size(s.pdfs,1), s.final());
end