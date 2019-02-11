%{
Class to present a circular, perimetry-style
image stimuli at a particular (x,y) location.
The key method is show().

Author: Andrew Turpin aturpin@unimelb.edu.au
Date: 8 Feb 2019
%}
classdef Presenter < handle
    properties
        x             % center of stim in pixels (relative to top-left 0,0)
        y             % ' ' ' 
        msg           % records information about last shown stimuli
        blank_image   % square patch of background color  
        duration      % stimulus on time in seconds
        radius        % radius of circular stimuli
        key_pressed   % latest key pressed
    end % properties
   
    methods
        function keyHandler(obj,src,event)
            obj.key_pressed = event.Key;
        end

           % Constructor
        % x,y,radius is position  of stimuli centre & radius in pixels
        % background_color is the ... [0..255]
        % duration is stimulus on time in seconds
        function obj = Presenter(x,y, radius,background_color, duration)
            obj.x = x;
            obj.y = y;
            obj.msg = 'No stim shown yet';
            obj.duration = duration;     
            obj.radius = radius;     
            obj.blank_image = background_color * ones(2*radius, 2*radius, 'uint8');
        end % Presenter() constructor
  
        % show stimuli at level stim_value and return 
        % true for seen, false for not (yes no).
        % true for decrease stim, false for increase (2AFC).
        function seen = show(obj, stim_value)
                % set up stim circle
            stim_image = obj.blank_image;
            for x = -obj.radius:obj.radius
                for y = -obj.radius:obj.radius
                    if x^2 + y^2 < obj.radius^2
                        stim_image(obj.radius + x + 1, obj.radius + y + 1) = uint8(stim_value);
                    end
                end
            end
            
            set(gcf,'KeyPressFcn',@obj.keyHandler);
            obj.key_pressed = [];
            
                % show stim for obj.duration
            x = obj.x - obj.radius/2;
            y = obj.y - obj.radius/2;
            
            image('XData',x, 'YData',y, 'CData',stim_image);
            beep();
            start = clock();
            while etime(clock, start) < obj.duration  
                pause(0.01);
            end
            image('XData',x, 'YData',y, 'CData',obj.blank_image);

                % wait until the end of obj.duration for a key press
            while isempty(obj.key_pressed)
                pause(0.01);
            end
                % 1,2,3 for "lower than ref", other for 'higher than ref'
            seen = ~ismember(obj.key_pressed, ['1' '2' '3']);

            obj.msg = sprintf('x= %4d y= %4d Stim= %4.2f seen= %d',obj.x, obj.y, stim_value, seen);
        end % show()
        
        function s = getMsg(obj)
            s = obj.msg;
        end
    end % methods
    
end % classdef