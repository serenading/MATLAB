%%celullar automaton model of worm feeding
function [] = CAfeeding(foodbias,adhesionstrength)
% runs cellular automata simulation of worm foraging and plots the results
% Inputs:
% adhesionstrength should be between 0 and 1, so that p(move) = (1 - adhesionStrength)^num_neighbours
% foodbias  preference for moving to sites with food, should be btw
% 0 and 1

%% initialisation
Nt = 1000; %# of timesteps
Nx = 50; % size of square 2-d lattice
Nw = 50; % number of worms
wormarray = uint16(zeros(Nt,Nw,2)); % allocate a variable to save x&y positions at every time-step
foodarray = false(Nx,Nx,Nt); % allocate a variable to save the amount of food at every point and time-step
foodarray(:,:,1) = true; % intial condition of food everywhere at t=1

p_m = @(n) (1 - adhesionstrength)^n; %probability of movement

rng('shuffle'); %initialise random number generatorwith current time
wormarray(1,:,:) = randi(Nx,Nw,2); %initial condition of randomly distributed worms

%% run the simulation
for t=2:Nt
    % update some arrays outside of the worm-loop
    worms_x = wormarray(t-1,:,1);
    worms_y = wormarray(t-1,:,2);
    foodarray(:,:,t) = foodarray(:,:,t-1);
    wormarray(t,:,:) = wormarray(t-1,:,:);
    
    for wormindex = 1:Nw % loop over worms
        % get worm position
        worm_x = worms_x(wormindex);
        worm_y = worms_y(wormindex);
        % worm eats food
        foodarray(worm_x,worm_y,t) = false; 
        
        % find the worm's neighbours - all that are within distance 1
        xneighbours = abs(worms_x - worm_x) <= 1;
        yneighbours = abs(worms_y - worm_y) <= 1;
        neighbours = xneighbours&yneighbours;
        neighbours(wormindex) = false; % don't count self as a neighbour
        numneighbours = nnz(neighbours);
        
        % worm moves
        actionchoice = rand(1); % choose whether to move or not
        if actionchoice <= p_m(numneighbours)
            % find probabilities of neighbouring patches based on food
            patchoptions = calculatepatchoptions(worm_x,worm_y,foodarray(:,:,t),foodbias);
            directionchoice = rand(1); % choose which direction to move into
            if directionchoice<=patchoptions(1) % move +1 in x
                wormarray(t,wormindex,1) = wormarray(t,wormindex,1) + 1;
            elseif directionchoice<=patchoptions(2) % move -1 in x
                wormarray(t,wormindex,1) = wormarray(t,wormindex,1) - 1;
            elseif directionchoice<=patchoptions(3) % move + 1 in y
                wormarray(t,wormindex,2) = wormarray(t,wormindex,2) + 1;
            elseif directionchoice>patchoptions(3) % move -1 in y
                wormarray(t,wormindex,2) = wormarray(t,wormindex,2) - 1;
            end
        end
    end
end
%% plot results
foodtotal = squeeze(sum(sum(foodarray)));
depletiontime = find(foodtotal==min(foodtotal),1,'first');
plot(foodtotal)
ylim([0,Nx.^2])
ylabel('amount of food left')
xlim([0 depletiontime])
xlabel('time')