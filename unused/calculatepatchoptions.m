function [ patchoptions ] = calculatepatchoptions(worm_x,worm_y,foodarray,bias)
% calculates probabilities for moving into adjacent patches
Nx = size(foodarray,1);
patchoptions = zeros(1,4);
% calculate number of available patches based on boundary conditions
if (1<worm_x)&&(worm_x<Nx)&&(1<worm_y)&&(worm_y<Nx)
    Na = 4;
elseif ((1<worm_x)&&(worm_x<Nx))||((1<worm_y)&&(worm_y<Nx))
    Na = 3;
else
    Na = 2;
end
% calculate numbe of patches that have food on them
Nf = foodarray(max(worm_x-1,1),worm_y) + foodarray(min(worm_x+1,Nx),worm_y) ...
    + foodarray(worm_x,max(worm_y-1,1)) + foodarray(worm_x,min(worm_y+1,Nx)); % this indexing works because foodarray(worm_x,worm_y) == false

if Nf>0
    p_food = 1/Na*(1 - bias) + bias/Nf;
    p_none = 1/Na*(1 - bias);
else
    p_none = 1/Na;
end

if worm_x<Nx
    if foodarray(worm_x+1,worm_y)
        patchoptions(1) = p_food;
    else
        patchoptions(1) = p_none;
    end
end
if worm_x>1
    if foodarray(worm_x-1,worm_y)
        patchoptions(2) = p_food;
    else
        patchoptions(2) = p_none;
    end
end
if worm_y<Nx
    if foodarray(worm_x,worm_y+1)
        patchoptions(3) = p_food;
    else
        patchoptions(3) = p_none;
    end
end
if worm_y>1
    if foodarray(worm_x,worm_y-1)
        patchoptions(4) = p_food;
    else
        patchoptions(4) = p_none;
    end
end

% check probabilities are normalised
assert(sum(patchoptions)-1<eps,'Error: probabilities do not sum to 1')

patchoptions = cumsum(patchoptions);
end

