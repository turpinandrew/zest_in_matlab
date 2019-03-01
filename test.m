
%{
Perform a ZEST at each location given in locations.
Inter-stimulus interval is a random in the range ISI.

Author: Andrew Turpin aturpin@unimelb.edu.au
Date: 7 Feb 2019
%}

SCREEN_SIZE = [1280 800];  % window size to show in pixesl [w h]
PIXELS_PER_MM = 20;        % depends on viewing distance and monitor res.

BACKGROUND_COLOR  = 0;
REF_COLOR = 100;           % level of reference spot [0,255]

STIMULUS_RADIUS   = 0.5/2;    % mm 
STIMULUS_DURARION = 500/1000;  % seconds

ISI = [0.4 0.6]; % inter-stimulus interval is a random in this range seconds

  % locations in mm
%LOCATIONS = [3 0;2.25 0;1.5 0;0.75 0;0 0;-0.75 0;-1.5 0;-2.25 0;-3 0];
LOCATIONS = [1 0;-1 0];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% open window for stimuli and put up reference stim
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cx = SCREEN_SIZE(1) / 2;
cy = SCREEN_SIZE(2) / 2;

imshow(BACKGROUND_COLOR * ones(SCREEN_SIZE(2), SCREEN_SIZE(1), 'uint8'), 'Border', 'tight');
set(gcf,'MenuBar','none');
movegui(gcf, 'northwest');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% setup a zest state for each location
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
states = {};
for xy = LOCATIONS.'
    x_pix = round(cx + (xy(1,1) * PIXELS_PER_MM));
    y_pix = round(cy + (xy(2,1) * PIXELS_PER_MM));
    p = Presenter(x_pix, y_pix, ...
                  round(STIMULUS_RADIUS*PIXELS_PER_MM), ...
                  BACKGROUND_COLOR, ...
                  REF_COLOR, cx, cy, ...
                  STIMULUS_DURARION);
        % prior has leading zeros for values below BACKGROUND_COLOR
        % plus a little bit (to avoid floor effects), and uniform above that
    prior = ones(1,256);
    prior = prior ./ sum(prior);
    
    states = [states, Zest(prior, BACKGROUND_COLOR, p)];
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% now loop through stepping a random state until all are finished
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
t = input('Press Enter to begin');
figure(gcf);
unfinished = 1:length(LOCATIONS);
while length(unfinished) > 0
    i = randi(length(unfinished()));
    z = states(unfinished(i));
    fprintf('Loc: %2d ', unfinished(i));
    z.step();
    fprintf('%s\n', z.getPresentMsg());
    if z.stop()
        fprintf('finished location %d\n', unfinished(i));
        unfinished(i) = [];
    end
    
    pause(ISI(1) + (ISI(2) - ISI(1)) * rand());   % inter-stimulus interval
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% print results
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:size(states,2)
    s = states(i);
    fprintf('Location %2d nump= %2d final= %4.2f\n',i,size(s.pdfs,1), s.final());
end