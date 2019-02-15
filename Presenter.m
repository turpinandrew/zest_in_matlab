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
        background_color
        ref_color
        ref_x
        ref_y
        ref_image
        key_pressed   % latest key pressed
    end % properties
   
    methods (Static)
        function c = circle(radius, cx, cy, back_color, color)
            im = back_color * ones(2*radius, 2*radius);
            for x = -radius:radius
                for y = -radius:radius
                    if x^2 + y^2 < radius^2
                        im(x + cx + 1, y + cy + 1) = uint8(color);
                    end
                end
            end
            c = im;
        end
    end
    
    methods
        function keyHandler(obj,src,event)
            obj.key_pressed = event.Key;
        end

           % Constructor
        % x,y,radius is position  of stimuli centre & radius in pixels
        % background_color is the ... [0..255]
        % duration is stimulus on time in seconds
        function obj = Presenter(x,y, radius,background_color, ref_color, ref_x, ref_y, duration)
            obj.x = x;
            obj.y = y;
            obj.msg = 'No stim shown yet';
            obj.duration = duration;     
            obj.radius = radius;     
            obj.ref_color = ref_color;     
            obj.background_color = background_color;     
            obj.ref_x = round(ref_x - radius/2);
            obj.ref_y = round(ref_y - radius/2);
            obj.blank_image = background_color * ones(2*radius, 2*radius, 'uint8');
            obj.ref_image = Presenter.circle(radius, radius, radius, background_color, ref_color);
        end % Presenter() constructor
  
        function waiter(obj)
            start = clock();
            while etime(clock, start) < obj.duration && isempty(obj.key_pressed)
                pause(0.01);
            end
        end
        
        % show reference in centre, then stimuli alternating 
        % for duration until a key is pressed.
        % true for seen, false for not (yes no).
        % true for decrease stim, false for increase (2AFC).
        function seen = show(obj, stim_value)
                % set up stim circle
            stim_image = Presenter.circle(obj.radius, obj.radius, obj.radius, obj.background_color, stim_value);
            
            set(gcf,'KeyPressFcn',@obj.keyHandler);
            obj.key_pressed = [];
            
            x = round(obj.x - obj.radius/2);
            y = round(obj.y - obj.radius/2);

            while isempty(obj.key_pressed)
                    % show stim for obj.duration
                image('XData',obj.ref_x, 'YData',obj.ref_y, 'CData',obj.ref_image);
                obj.waiter();
                image('XData',obj.ref_x, 'YData',obj.ref_y, 'CData',obj.blank_image);
                
                image('XData',x, 'YData',y, 'CData',stim_image);
                beep();
                obj.waiter();
                image('XData',x, 'YData',y, 'CData',obj.blank_image);      
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