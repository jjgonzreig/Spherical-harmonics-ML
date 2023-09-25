function [asteroids, eros_SH] = generate_asteroids(num_asteroids,max_order,grid_lambda,grid_phi,length_matrix_coef,percent,frac_eros)
       
    % Set the fraction of the asteroids "to be like Eros 433"
    like_eros = floor(num_asteroids/frac_eros);
    
    % Generate random asteroids
    [C,S,r] = generate_rand(max_order,grid_lambda,grid_phi,length_matrix_coef,num_asteroids - like_eros);
    for i=1:(num_asteroids - like_eros)
        data(:,:,i) = build_data(C(:,i), S(:,i), r(:,i));
    end

    % Geneate random Eros asteroids be like  
    [C_eros,S_eros,r_eros] = generate_like_eros(grid_lambda,grid_phi,length_matrix_coef,max_order,percent,like_eros);
    for i=1:like_eros
        data_eros(:,:,i) = build_data(C_eros(:,i), S_eros(:,i), r_eros(:,i));
    end
    
    % Join and shuffle the asteroids 
    asteroids = zeros([size(data,1:2) , size(data,3)+size(data_eros,3)]);
    asteroids(:,:,1:(num_asteroids - like_eros)) = data;
    asteroids(:,:,(num_asteroids - like_eros + 1):end) = data_eros;

    copy_asteroids = asteroids;

    perm = randperm(size(asteroids,3));
    for i=1:size(asteroids,3)
        asteroids(:,:,i) = copy_asteroids(:,:,perm(i));
    end

    % Load the Eros 433 asteroid
    eros_SH = load("eros433.mat").shcoeff(1:sum(1:max_order+1),:);
     
end