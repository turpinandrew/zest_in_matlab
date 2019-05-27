%{
A class to store the state of a zest procedure for a single location.
The constants can be changed at the top to customise the procedure, but
they are common across all Zest objects. Perhaps this might change...

Provides methods 
    step - make a presentation and update pdf
    stop - returns true if termination condition is met
    final - give current threshold estimate

Example use, see Zest.demo().

Author: Andrew Turpin aturpin@unimelb.edu.au
Date: 7 Feb 2019
%}
classdef Zest < handle
    properties (Constant)
        twoAFC = true;      % true for two alternate forced choice, false for yes/no
        stopType = 'S'      % N = fixed number of pres | S = stdev of pdf | H = entropy of pdf
        stopValue = 25      % Value for num prs (N), stdev (S) of Entropy (H)
        maxStimulus = 255   % Highest value to present
        minNotSeenLimit = 2 % Will terminate if minLimit value not seen this many times
        maxSeenLimit    = 2 % Will terminate if maxLimit value seen this many times
        maxPresentations =10000 % Maximum number of presentations
        stimChoice = 'mean'   % 'mean', 'median', 'mode'
    end % properties (Constant)
    
    properties
        present      % An object that contains a show(stim_level) method 
                     % that returns seen (true or false).

        minStimulus  % Lowest value to present

        domain       % domain: possible threshold values

        pdfs = [];   % matrix of pdfs in the procedure, one row per step
        
        likelihood 
        
        maxSeenCount = 0;
        minNotSeenCount = 0;
        
        stimuli = {} % record  of stimuli used
    end % properties 
    
    methods (Static)
        % return stdev of last row of obj.pds
        function res = stdev(obj)
            Epsq = sum(obj.pdfs(end,:) .* obj.domain .* obj.domain);
            Ep_sq = sum(obj.pdfs(end,:) .* obj.domain) ^2;
            res = sqrt(Epsq - Ep_sq);
        end
        
        % return entropy of last row in obj.pdfs
        function res = entropy(obj)
            is = find(obj.pdfs(end, :));
            res = -sum(obj.pdfs(end, is) * log2(obj.pdfs(end, is)));
        end
    end % methods(Static)

    methods
        % Constructor: set pdf=prior, and store present for later
        % domain: possible threshold values
        % prior: array of probabilities of length domain (sums to 1)
        % min_stimuls: the minimum to present (usually the bacground color)
        % present: a Presenter object that has a show() method
        function obj=Zest(domain, prior, min_stimulus, present)
            assert(length(prior) == length(domain),...
                'Zest: Prior wrong length in call to  constructor');
            assert(ismethod(present, 'show'), ...
                'Zest: Present object must contain show method');
            obj.domain = domain      
            obj.pdfs = prior;
            obj.minStimulus = min_stimulus;
            obj.present = present;
        
                % likelihood[s,t] is likelihood of seeing s given t is true thresh
                % (Pr(s|t) where s and t are indexes into domain)
                % We only want to compute it once, hence this persistent thingy
            if Zest.twoAFC; lower = 0.53; else; lower = 0.03; end;
            obj.likelihood = zeros(length(obj.domain), length(obj.domain));
            for i_t = 1:length(obj.domain)
                pd = makedist('Normal','mu',obj.domain(i_t),'sigma',0.1);
                for i_s = 1:length(obj.domain)
                    obj.likelihood(i_s, i_t) = lower + (1-lower-0.03)*(1-cdf(pd, obj.domain(i_s)));
                end
            end
        end % constructor()
        
        % Use the present object to show the stimulus and get a response.
        % Record the stimulus in stimli array.
        % Update the pdf by mulitiplying with appropriate likelihood.
        function step(obj)
            curr_pdf = obj.pdfs(end, :); 
            if obj.stimChoice == 'mean'
                expectation = sum(curr_pdf .* obj.domain);
                s = min(max(obj.minStimulus, expectation), obj.maxStimulus);
                [v, stim_index] = min(abs(obj.domain - s));
                stim = obj.domain(stim_index);
            else 
                error('median and mode unimplemented in zest class')
            end
            obj.stimuli = [obj.stimuli, stim];
            
            seen = obj.present.show(stim);
            
            if seen
                obj.maxSeenCount = obj.maxSeenCount + stim == obj.maxStimulus;
                if Zest.twoAFC
                    new_pdf = curr_pdf .* (1.5 - obj.likelihood(stim_index, :));
                else
                    new_pdf = curr_pdf .* (1.0 - obj.likelihood(stim_index, :));
                end
            else
                obj.minNotSeenCount = obj.minNotSeenCount + stim == obj.minStimulus;
                new_pdf = curr_pdf .* obj.likelihood(stim_index, :);
            end
            new_pdf = new_pdf ./ sum(new_pdf);
            obj.pdfs = [obj.pdfs ; new_pdf];
        end % step()
    
        % Return true if ZEST should stop, false otherwise
        function keepGoing = stop(obj)
            keepGoing = ...
                (size(obj.pdfs,1) < obj.maxPresentations) && ...
                (obj.minNotSeenCount < obj.minNotSeenLimit) && ...
                (obj.maxSeenCount    < obj.maxSeenLimit) && ...
                ( ...
                ((obj.stopType == 'S') && (Zest.stdev(obj) > obj.stopValue)) || ...
                ((obj.stopType == 'H') && (Zest.entropy(obj) > obj.stopValue)) || ...
                ((obj.stopType == 'N') && (size(obj.pdfs,1) < obj.stopValue)) ...
                );
            keepGoing = not(keepGoing);
        end % stop()

        % return current threshold estimate of obj
        function f = final(obj) 
            if obj.stimChoice == 'mean'
                f = sum(obj.pdfs(end,:) .* obj.domain);
            elseif obj.stimChoice == 'mode'
                [v, i] = max(obj.pdfs(end, :));
                f = obj.domain(i);
            elseif obj.stimChoice == 'median'
                c = cumsum(obj.pdfs(end, :));
                [v, i] = min(abs(c - 0.5));
                f = obj.domain(i);
            end
        end % final()

        function s = getPresentMsg(obj)
            s = obj.present.getMsg();
        end
        
    end % methods
    
    methods (Static)
        % just a basic demo.
        function demo(obj)
            BG_COL = 128
                % set up a window
            imshow(BG_COL * ones(100,100, 'uint8'), 'Border', 'tight');
            set(gcf,'MenuBar','none');
    
                 % go!
            p = Presenter(50, 50, 20, BG_COL, 0.2, 1.5 );
            z = Zest(p);
            while ~ z.stop()
                z.step();
                fprintf('%s\n', z.getPresentMsg());
            end
            z.final()
        end % demo()
    end % methods (Static)
    
end%classdef
