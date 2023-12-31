%% Set parameters

clear

% Number of random asteroids to generate
n_asteroids = 200;

% Max order of the i-th asteroid to generate
max_order = 14;

% Grade and order of the (n+1)x(n+1) matrices C and S (must be <= max_order)
length_matrix_coef = 14;

% Size of the mesh 
grid_lambda = 10;
grid_phi = 10;

% Fraction of the Eros like asteroids (n_asteroids/frac_eros)
frac_eros = 25;

% Percent of variation of the Eros like asteroids (+- percent on the C and S)
percent = 0.25;

% Percent of the n_asteroids used to train
factor_train = 0.8;

% Number of validation asteroids used to train
frac_validation = n_asteroids/5;

% Number of training epochs
epochs = 200;

% Number of random asteroids within the data_test to plot graphical metrics
n_plots = 3;

% len is the n-by-n mesh that plots the asteroids (can be different than the mesh of the train asteroids)
len = 50;

%% Generate the data

% Generate random asteroids (including asteroids like Eros)
[data,eros_SH] = generate_asteroids(n_asteroids,max_order,grid_lambda,grid_phi,length_matrix_coef,percent,frac_eros);

% Separate the asteroid variable in harmonics and r component 
if any(any(data(:,1,:)==0)) && any(any(data(:,2,:)==0))
    for i=1:size(data,1)
        if (any(data(i,1,:)==0) && any(data(i,2,:)==0))
            data_cut_SH = data(1:i-1,1:2,:);
            data_cut_r = data(:,3,:);
            eros_SH_SH = eros_SH(1:i-1,3:4);
            break
        end
    end
else
    for i=1:size(data,1)
        if any(data(i,3,:)==0)
            data_cut_SH = data(:,1:2,:);
            data_cut_r = data(1:i-1,3,:);
            eros_SH_SH = eros_SH(:,3:4);
            break
        end
    end
end

len_r = size(data_cut_r,1);
len_SH = size(data_cut_SH,1);

%% Prepare the data 

% Standardize Data
mu_r = mean(data_cut_r, 1);
sig_r = std (data_cut_r, 0, 1);

dataStandardized_r = zeros(size(data_cut_r));
for i = 1:n_asteroids
    dataStandardized_r(:,:,i) = (data_cut_r(:,:,i) - mu_r(:,:,i)) ./ sig_r(:,:,i);
end

[dataStandardized_SH, eros_Standardized_SH,stand_params] = stand_by_harmonics(data_cut_SH,eros_SH_SH,max_order);

% Separate the data into train data and test data
percent_train = floor(factor_train*n_asteroids);
data_train_SH = dataStandardized_SH(:,:,1:percent_train+1);
data_train_r = dataStandardized_r(:,:,1:percent_train+1);
data_test_SH = dataStandardized_SH(:,:,percent_train+2:end);
data_test_r = dataStandardized_r(:,:,percent_train+2:end);

% Separate the data train into input data and target data
input_data = pagetranspose(data_train_r);
input_data = reshape(input_data,[grid_lambda, grid_phi, 1, size(input_data,3)]);

target_data = pagetranspose(data_train_SH);
% target_data = reshape(target_data, [len_SH, size(target_data,3)]);

% Set the validation data for the training
idx = randperm(size(input_data,4),frac_validation);
XValidation = input_data(:,:,:,idx);
input_data(:,:,:,idx) = [];
YValidation = target_data(:,:,idx);
YValidation_1 = squeeze(YValidation(1,:,:))';
YValidation_2 = squeeze(YValidation(2,:,:))';
target_data(:,:,idx) = [];

%% BUILD THE NN

num_inputs = [1 size(input_data,2)];
num_outputs = size(target_data,2);

layers = [ ...
    imageInputLayer([grid_lambda grid_phi 1])
    convolution2dLayer(2,10,'Padding','same')
    batchNormalizationLayer
    reluLayer
    convolution2dLayer(2,10,'Padding','same')
    batchNormalizationLayer
    reluLayer
    fullyConnectedLayer(50, 'Name','FC1')  
    fullyConnectedLayer(25, 'Name','FC2')  
    sigmoidLayer
    fullyConnectedLayer(num_outputs, 'Name','Output')   
    regressionLayer];

options_1 = trainingOptions('sgdm', ...
    'MaxEpochs',epochs, ...
    'MiniBatchSize', 256, ...
    'ValidationData',{XValidation,YValidation_1}, ...
    'ValidationFrequency', 5000, ...
    'InitialLearnRate',0.01, ...
    'LearnRateSchedule','piecewise', ...
    'LearnRateDropPeriod',150, ...
    'LearnRateDropFactor',0.95, ...
    'Verbose',0, ...
    'ExecutionEnvironment','cpu', ...
    'OutputFcn',@(x) makeLogVertAx(x, [true,true]), ...
    'Plots','training-progress');

options_2 = trainingOptions('sgdm', ...
    'MaxEpochs',epochs, ...
    'MiniBatchSize', 256, ...
    'ValidationData',{XValidation,YValidation_2}, ...
    'ValidationFrequency', 5000, ...
    'InitialLearnRate',0.01, ...
    'LearnRateSchedule','piecewise', ...
    'LearnRateDropPeriod',150, ...
    'LearnRateDropFactor',0.95, ...
    'Verbose',0, ...
    'ExecutionEnvironment','cpu', ...
    'OutputFcn',@(x) makeLogVertAx(x, [true,true]), ...
    'Plots','training-progress');

net_1 = trainNetwork(input_data,squeeze(target_data(1,:,:))',layers,options_1);
net_2 = trainNetwork(input_data,squeeze(target_data(2,:,:))',layers,options_2);
%% Predict

% Separate the data_test into input and target data
input_data_test = pagetranspose(data_test_r);
input_data_test = reshape(input_data_test,[grid_lambda,grid_phi,1,size(input_data_test,3)]);
target_data_test = pagetranspose(data_test_SH);

[C_eros_square, S_eros_square] = get_coefs(length_matrix_coef, eros_SH(:,1:2), eros_SH);

% Define the angles of the longitude and latitude 
lambda = linspace(0, 2*pi, grid_phi);
phi = linspace(-pi/2, pi/2, grid_lambda);

% Creates the mesh
[lambda, phi] = meshgrid(lambda, phi);

% True r Eros
k = 1;
r_eros_input = zeros(1,size(lambda,1)*size(lambda,2));
for i=1:grid_phi
    for j=1:grid_lambda
        r_eros_input(k) = get_R(lambda(1,i), phi(j,1), C_eros_square, S_eros_square, 1, 0, 0);
        k = k + 1;
    end
end 

mu_r_eros = mean(r_eros_input, 2);
sig_r_eros = std (r_eros_input, 0, 2);
r_eros_input = (r_eros_input - mu_r_eros) ./ sig_r_eros;
r_eros_input = reshape(r_eros_input,[grid_lambda,grid_phi,1]);

% Predict
pred_1 = predict(net_1, input_data_test);
pred_2 = predict(net_2, input_data_test);
pred = cat(2,pred_1,pred_2);
pred = pagetranspose(pred);


pred_eros_1 = predict(net_1, r_eros_input);
pred_eros_2 = predict(net_2, r_eros_input);
pred_eros = cat(2,pred_eros_1,pred_eros_2);
pred_eros = pagetranspose(pred_eros);


% Save data standardize
pred_stand = pred;
pred_eros_stand = pred_eros;
data_test_stand_r = data_test_r;
data_test_stand_SH = data_test_SH;

% Unstandardize the predictions and the test data
[aux1, aux2] = unstand_by_harmonics(reshape(pred,size(pred_1,2),2,size(pred,2)),reshape(pred_eros,size(pred_eros_1,2),2),max_order,stand_params,percent_train);
pred = reshape([aux1(:,1,:);aux1(:,2,:)],size(pred,1:2));
pred_eros = reshape([aux2(:,1);aux2(:,2)],size(pred_eros,1:2));

[data_test_SH, ~] = unstand_by_harmonics(data_test_SH,zeros(size(eros_Standardized_SH)),max_order,stand_params,percent_train);


%% Plot predicted vs true values

% Take n_plots samples at random to plot 
rng_plot_init = randi(size(data_test_SH,3)-n_plots);
rng_plot_end = rng_plot_init + n_plots-1;

for i=rng_plot_init:rng_plot_end
    lim_min_test_C = min(min(data_test_SH(:,1,i)))-100;
    lim_max_test_C = max(max(data_test_SH(2:end,1,i)))+100;    % 2 to not show the C00 (Reference radius) 
    lim_min_pred_C = min(pred(1:len_r,i))-100;
    lim_max_pred_C = max(pred(2:len_r,i))+100;               % 2 to not show the C00 (Reference radius) 

    lim_min_test_S = min(min(data_test_SH(:,2,i)))-100;
    lim_max_test_S = max(max(data_test_SH(2:end,2,i)))+100;    % 2 to not show the C00 (Reference radius) 
    lim_min_pred_S = min(pred(len_r+1:end,i))-100;
    lim_max_pred_S = max(pred(len_r+1:end,i))+100;

    figure('Renderer', 'painters', 'Position', [300 100 900 600])
    subplot(1,2,1)
    scatter(data_test_SH(:,1,i),pred(1:size(pred_1,2),i),'x','LineWidth',1.5) 
    hold on
    line([lim_min_test_C lim_max_test_C],[lim_min_pred_C lim_max_pred_C],'Color','red','LineStyle','--')
    hold off
    xlabel('True values')
    ylabel('Predicted values')
    title('Coefficients C_n_m')
    axis([lim_min_test_C lim_max_test_C lim_min_pred_C lim_max_pred_C])
    grid on
    
    subplot(1,2,2)
    scatter(data_test_SH(:,2,i),pred(size(pred_2,2)+1:end,i),'x','LineWidth',1.5)
    hold on
    line([lim_min_test_S lim_max_test_S],[lim_min_pred_S lim_max_pred_S],'Color','red','LineStyle','--')
    hold off
    xlabel('True values')
    ylabel('Predicted values')
    title('Coefficients S_n_m')  
    axis([lim_min_test_S lim_max_test_S lim_min_pred_S lim_max_pred_S])
    grid on
end

lim_min_test_C_eros = min(min(eros_SH(:,3)))-100;
lim_max_test_C_eros = max(max(eros_SH(2:end,3)))+100;    % 2 to not show the C00 (Reference radius) 
lim_min_pred_C_eros = min(pred_eros(1:len_SH))-100;
lim_max_pred_C_eros = max(pred_eros(2:len_SH))+100;               % 2 to not show the C00 (Reference radius) 

lim_min_test_S_eros = min(min(eros_SH(:,4)))-100;
lim_max_test_S_eros = max(max(eros_SH(2:end,4)))+100;    % 2 to not show the C00 (Reference radius) 
lim_min_pred_S_eros = min(pred_eros(len_SH+1:end))-100;
lim_max_pred_S_eros = max(pred_eros(len_SH+1:end))+100;

figure('Renderer', 'painters', 'Position', [300 100 900 600])
subplot(1,2,1)
scatter(eros_SH(:,3),pred_eros(1:len_SH),'x','LineWidth',1.5)  
hold on
line([lim_min_test_C_eros lim_max_test_C_eros],[lim_min_pred_C_eros lim_max_pred_C_eros],'Color','red','LineStyle','--')
hold off
xlabel('True values')
ylabel('Predicted values')
title('Eros Coefficients C_n_m')
axis([lim_min_test_C_eros lim_max_test_C_eros lim_min_pred_C_eros lim_max_pred_C_eros])
grid on

subplot(1,2,2)
scatter(eros_SH(:,4),pred_eros(len_SH+1:end),'x','LineWidth',1.5)
hold on
line([lim_min_test_S_eros lim_max_test_S_eros],[lim_min_pred_S_eros lim_max_pred_S_eros],'Color','red','LineStyle','--')
hold off
xlabel('True values')
ylabel('Predicted values')
title('Eros Coefficients S_n_m')
axis([lim_min_test_S_eros lim_max_test_S_eros lim_min_pred_S_eros lim_max_pred_S_eros])
grid on

%% Plot predicted asteroids

% Create the mesh
lambda = linspace(0, 2*pi, len);
phi = linspace(-pi/2, pi/2, len);

[lambda, phi] = meshgrid(lambda, phi);

% Set normalize 1 if the SH are fully normalized or 0 if not
normalize_P = 1;
normalize_C = 0;
normalize_S = 0;

C_pred = pred(1:len_SH,:);
C_pred_eros = pred_eros(1:len_SH);
S_pred = pred(len_SH+1:end,:);
S_pred_eros = pred_eros(len_SH+1:end);

n = zeros(max_order + 2,1);
m = zeros(max_order + 2,1);
k = 1;
for i=0:length(n)-1
    for j=0:i-1
        n(k) = i-1;
        m(k) = j;
        k = k + 1;
    end
end

nm = zeros(0.5*(max_order + 2)*(max_order + 1),2);
nm(:,1) = n;
nm(:,2) = m;

% Calculate the r's with the predicted harmonics of the random selected
% asteroids

Data_pred = zeros(size(C_pred,1),4);
Data_pred(:,1:2) = nm(1:size(C_pred,1),:);
Data = zeros(size(data_test_SH,1),4);
Data(:,1:2) = nm(1:size(data_test_SH,1),:);

cont_plots = 1;
r_CS_pred = zeros(length(lambda).^2,n_plots);
r_CS = zeros(length(lambda).^2,n_plots);
for n=rng_plot_init:rng_plot_end
    
    % Get the coefficients C and S in a square form
    Data_pred(:,3) = C_pred(:,n);
    Data_pred(:,4) = S_pred(:,n);
    [C_pred_square, S_pred_square] = get_coefs(length_matrix_coef, nm, Data_pred);

    Data(:,3) = data_test_SH(:,1,n);
    Data(:,4) = data_test_SH(:,2,n);
    [C_square, S_square] = get_coefs(length_matrix_coef, nm, Data);

    k = 1;
    for i=1:len
        for j=1:len
            r_CS_pred(k,cont_plots) = get_R(lambda(1,i), phi(j,1), C_pred_square, S_pred_square, normalize_P, normalize_C, normalize_S);
            k = k + 1;
        end
    end 
    k = 1;
    for i=1:len
        for j=1:len
            r_CS(k,cont_plots) = get_R(lambda(1,i), phi(j,1), C_square, S_square, normalize_P, normalize_C, normalize_S);
            k = k + 1;
        end
    end   
    cont_plots = cont_plots + 1;
end

% Calculate the r of the predicted Eros

Data_eros_pred = zeros(size(data_test_SH,1),4);
Data_eros_pred(:,1:2) = nm(1:size(data_test_SH,1),:);
Data_eros_pred(:,3) = pred_eros(1:len_SH);
Data_eros_pred(:,4) = pred_eros(len_SH+1:end);

[C_eros_square_pred, S_eros_square_pred] = get_coefs(length_matrix_coef, nm, Data_eros_pred);
[C_eros_square, S_eros_square] = get_coefs(length_matrix_coef, nm, eros_SH);
r_CS_eros = zeros(1,len^2);
r_CS_eros_pred = zeros(1,len^2);
k = 1;
for i=1:len
    for j=1:len
        r_CS_eros(k) = get_R(lambda(1,i), phi(j,1), C_eros_square, S_eros_square, normalize_P, normalize_C, normalize_S);
        r_CS_eros_pred(k) = get_R(lambda(1,i), phi(j,1), C_eros_square_pred, S_eros_square_pred, normalize_P, normalize_C, normalize_S);
        k = k + 1;
    end
end   

r_test = zeros([len len n_plots]);
r_pred = zeros([len len n_plots]);

x_test = zeros([len len n_plots]);
y_test = zeros([len len n_plots]);
z_test = zeros([len len n_plots]);

x_pred = zeros([len len n_plots]);
y_pred = zeros([len len n_plots]);
z_pred = zeros([len len n_plots]);

for i=1:size(r_CS_pred,2)

    % Reshape the r to make it a square matrix
    r_test(:,:,i) = reshape(r_CS(:,i), size(lambda));
    r_pred(:,:,i) = reshape(r_CS_pred(:,i), size(lambda));

    % Convert spherical coordinates to cartesian
    [x_test(:,:,i), y_test(:,:,i), z_test(:,:,i)] = sph2cart(lambda, phi, r_test(:,:,i));
    [x_pred(:,:,i), y_pred(:,:,i), z_pred(:,:,i)] = sph2cart(lambda, phi, r_pred(:,:,i));

end

% Get coordintates of Eros
r_eros = reshape(r_CS_eros, size(lambda));
r_eros_pred= reshape(r_CS_eros_pred, size(lambda));

[x_eros, y_eros, z_eros] = sph2cart(lambda, phi, r_eros);
[x_eros_pred, y_eros_pred, z_eros_pred] = sph2cart(lambda, phi, r_eros_pred);

for i=1:size(r_CS_pred,2)
    f = figure();
    t = tiledlayout(1,2);
    ax = nexttile;
    mesh(x_test(:,:,i), y_test(:,:,i), z_test(:,:,i),r_test(:,:,i),'FaceColor', 'interp','EdgeColor',[0,0,0])
    light
    axis equal
    title('True asteroid')
    xlabel('x [m]')
    ylabel('y [m]')
    zlabel('z [m]')
    a = colorbar('Location','layout');
    a.Layout.Tile = 'south';
    a.Label.String = 'r [m]';
    a.Label.FontSize = 20;
    ax.XLabel.FontSize = 12;
    ax.YLabel.FontSize = 12;
    ax.ZLabel.FontSize = 12;
    ax.TitleFontSizeMultiplier = 1.5;

    ax = nexttile;
    mesh(x_pred(:,:,i), y_pred(:,:,i), z_pred(:,:,i),r_pred(:,:,i),'FaceColor', 'interp','EdgeColor',[0,0,0])
    light
    axis equal
    title('Predicted asteroid')
    xlabel('x [m]')
    ylabel('y [m]')
    zlabel('z [m]')
    ax.XLabel.FontSize = 12;
    ax.YLabel.FontSize = 12;
    ax.ZLabel.FontSize = 12;
    ax.TitleFontSizeMultiplier = 1.5;
end

f = figure();
t = tiledlayout(1,2);
ax = nexttile;
mesh(x_eros, y_eros, z_eros,r_eros,'FaceColor', 'interp','EdgeColor',[0,0,0])
light
axis equal
title('True Eros')
xlabel('x [m]')
ylabel('y [m]')
zlabel('z [m]')
a = colorbar('Location','layout');
a.Layout.Tile = 'south';
a.Label.String = 'r [m]';
a.Label.FontSize = 20;
ax.XLabel.FontSize = 12;
ax.YLabel.FontSize = 12;
ax.ZLabel.FontSize = 12;
ax.TitleFontSizeMultiplier = 1.5;

ax = nexttile;
mesh(x_eros_pred, y_eros_pred, z_eros_pred,r_eros_pred,'FaceColor', 'interp','EdgeColor',[0,0,0])
light
axis equal
title('Predicted Eros')
xlabel('x [m]')
ylabel('y [m]')
zlabel('z [m]')
ax.XLabel.FontSize = 12;
ax.YLabel.FontSize = 12;
ax.ZLabel.FontSize = 12;
ax.TitleFontSizeMultiplier = 1.5;

%% Calculate accuracy

CS_true = data_test_SH;
CS_pred = zeros(size(CS_true));
CS_pred(:,1,:) = pred(1:len_SH,:);
CS_pred(:,2,:) = pred(len_SH+1:end,:);

CS_true_stand = data_test_stand_SH;
CS_pred_stand = zeros(size(CS_true_stand));
CS_pred_stand(:,1,:) = pred_stand(1:len_SH,:);
CS_pred_stand(:,2,:) = pred_stand(len_SH+1:end,:);

% Normalize the data
minimum = min(CS_true);
max_min = range(CS_true);
CS_true_norm = (CS_true - minimum)./max_min;

minimum = min(CS_pred);
max_min = range(CS_pred);
CS_pred_norm = (CS_pred - minimum)./max_min;

minimum = min(eros_SH_SH);
max_min = range(eros_SH_SH);
eros_norm = (eros_SH_SH - minimum)./max_min;

minimum = min(C_pred_eros);
max_min = range(C_pred_eros);
C_pred_eros_norm = (C_pred_eros - minimum)./max_min;
minimum = min(S_pred_eros);
max_min = range(S_pred_eros);
S_pred_eros_norm = (S_pred_eros - minimum)./max_min;


accuracy_C = mean(1-sum((CS_true(:,1,:)-CS_pred(:,1,:)).^2) ./ sum((CS_true(:,1,:)-mean(CS_true(:,1,:))).^2));
accuracy_S = mean(1-sum((CS_true(:,2,:)-CS_pred(:,2,:)).^2) ./ sum((CS_true(:,2,:)-mean(CS_true(:,2,:))).^2));
disp('Global accuracy R^2 of C and S')
disp([accuracy_C,accuracy_S])

%% Calculate accuracy and errors by harmonics

max_order_SH = max_order + 1;

error_SH_C = zeros(size(CS_true_norm,3),max_order_SH);
error_SH_S = zeros(size(CS_true_norm,3),max_order_SH);
error_SH_C_eros = zeros(1,max_order_SH);
error_SH_S_eros = zeros(1,max_order_SH);

checkpoint = 0;
for i=1:max_order_SH
    if i==1
        checkpoint_end = 1;
        checkpoint_init = 1;

        SH_C = CS_true_norm(checkpoint_init : checkpoint_end,1,:);
        SH_C_eros = eros_norm(checkpoint_init : checkpoint_end,1);

        SH_S = CS_true_norm(checkpoint_init : checkpoint_end,2,:);
        SH_S_eros = eros_norm(checkpoint_init : checkpoint_end,2);


        SH_C_pred = CS_pred_norm(checkpoint_init : checkpoint_end,1,:);
        SH_C_pred_eros = C_pred_eros_norm(checkpoint_init : checkpoint_end);

        SH_S_pred = CS_pred_norm(checkpoint_init : checkpoint_end,2,:);
        SH_S_pred_eros = S_pred_eros_norm(checkpoint_init : checkpoint_end);
 
        error_SH_C(:,i) = abs(SH_C(:,1,:) - SH_C_pred(:,1,:));
        error_SH_S(:,i) = abs(SH_S(:,1,:) - SH_S_pred(:,1,:));

        error_SH_C_eros(i) = sum(abs(SH_C_eros - SH_C_pred_eros));
        error_SH_S_eros(i) = sum(abs(SH_S_eros - SH_S_pred_eros));

    else
        checkpoint_init = checkpoint_init + checkpoint;
        checkpoint_end = checkpoint_init + checkpoint ;

        SH_C = CS_true_norm(checkpoint_init : checkpoint_end,1,:);
        SH_C_eros = eros_norm(checkpoint_init : checkpoint_end,1);

        SH_S = CS_true_norm(checkpoint_init : checkpoint_end,2,:);
        SH_S_eros = eros_norm(checkpoint_init : checkpoint_end,2);


        SH_C_pred = CS_pred_norm(checkpoint_init : checkpoint_end,1,:);
        SH_C_pred_eros = C_pred_eros_norm(checkpoint_init : checkpoint_end);

        SH_S_pred = CS_pred_norm(checkpoint_init : checkpoint_end,2,:);
        SH_S_pred_eros = S_pred_eros_norm(checkpoint_init : checkpoint_end);

        error_SH_C(:,i) = squeeze(sum(abs(SH_C(:,1,:) - SH_C_pred(:,1,:))));
        error_SH_S(:,i) = squeeze(sum(abs(SH_S(:,1,:) - SH_S_pred(:,1,:))));

        error_SH_C_eros(i) = sum(abs(SH_C_eros - SH_C_pred_eros));
        error_SH_S_eros(i) = sum(abs(SH_S_eros - SH_S_pred_eros));

    end
    checkpoint = checkpoint + 1; 
end     

mean_error_SH_C = mean(error_SH_C);
mean_error_SH_S = mean(error_SH_S);

tabla_error_eros = table(error_SH_C_eros',error_SH_S_eros','VariableNames',{'Error C Eros','Error S Eros'});
tabla_mean_error= table(mean_error_SH_C',mean_error_SH_S','VariableNames',{'Mean Error C','Mean Error S'});
tabla_errors_SH = [tabla_mean_error, tabla_error_eros];

%% Bar plot of the errors
figure('Renderer', 'painters', 'Position', [300 100 900 600])
subplot(1,2,1)
bar(mean_error_SH_C,0.75)
hold on 
bar(mean_error_SH_S,0.3)
title('Abs Errors by harmonics')
legend('C','S','Location','northwest')
xlabel('N^t^h Harmonic')
ylabel('Abs Error (m)')
xticklabels(mat2cell(0:max_order,1))
grid minor
hold off

subplot(1,2,2)
bar(error_SH_C_eros,0.75)
hold on
bar(error_SH_S_eros,0.3)
title('Abs Eros433 Errors by harmonics')
legend('C','S','Location','northwest')
xlabel('N^t^h Harmonic')
ylabel('Abs Error (m)')
xticklabels(mat2cell(0:max_order,1))
grid minor
hold off


%% Errors

% Normalize the r's
r_CS_norm = (r_CS - mean(r_CS,1)) ./ std(r_CS,0,1);
r_CS_pred_norm = (r_CS_pred - mean(r_CS_pred,1)) ./ std(r_CS_pred,0,1);

% SH and r absolute error
error_abs_C = sum(abs(CS_true(:,1,:)-CS_pred(:,1,:)));
error_abs_C_norm = abs(CS_true(:,1,:)-CS_pred(:,1,:));
error_abs_C_norm = squeeze(sum((error_abs_C_norm - min(error_abs_C_norm))./range(error_abs_C_norm)));
error_abs_C_eros = sum(abs(eros_SH_SH(:,1)-pred_eros(1:len_SH)));
error_abs_C_eros_norm = abs(eros_SH_SH(:,1)-pred_eros(1:len_SH));
error_abs_C_eros_norm = squeeze(sum((error_abs_C_eros_norm - min(error_abs_C_eros_norm))./range(error_abs_C_eros_norm)));

error_abs_r = sum(abs(r_CS-r_CS_pred));
error_abs_r_norm = abs(r_CS-r_CS_pred);
error_abs_r_norm = squeeze(sum((error_abs_r_norm - min(error_abs_r_norm))./range(error_abs_r_norm)));
error_abs_r_eros = sum(abs(r_CS_eros-r_CS_eros_pred));
error_abs_r_eros_norm = abs(r_CS_eros-r_CS_eros_pred);
error_abs_r_eros_norm = squeeze(sum((error_abs_r_eros_norm - min(error_abs_r_eros_norm))./range(error_abs_r_eros_norm)));

error_abs_S = sum(abs(CS_true(:,2,:)-CS_pred(:,2,:)));
error_abs_S_norm = abs(CS_true(:,2,:)-CS_pred(:,2,:));
error_abs_S_norm = squeeze(sum((error_abs_S_norm - min(error_abs_S_norm))./range(error_abs_S_norm)));
error_abs_S_eros = sum(abs(eros_SH_SH(:,2)-pred_eros(len_SH+1:end)));
error_abs_S_eros_norm = abs(eros_SH_SH(:,2)-pred_eros(len_SH+1:end));
error_abs_S_eros_norm = squeeze(sum((error_abs_S_eros_norm - min(error_abs_S_eros_norm))./range(error_abs_S_eros_norm)));


tabla_abs_errors = table(mean(error_abs_C_norm),mean(error_abs_S_norm), mean(error_abs_r_norm), ...
    mean(error_abs_C_eros_norm),mean(error_abs_S_eros_norm),mean(error_abs_r_eros_norm), ...
    'VariableNames',{'Abs error C','Abs error S','Abs error r','Abs error C Eros', ...
    'Abs error S Eros','Abs error r Eros'});

% Geometric absolute error r
error_sqrt_abs_r = sqrt(sum(abs(r_CS_norm-r_CS_pred_norm).^2));

% SH  percent error
% Nondimensionalization of the SH to make sure that there are not 0 values
ref_min = -1;
ref_max = 1;

C_nondim = (CS_true_norm(:,1,:) - ref_min)./(ref_max - ref_min);
C_pred_nondim = (CS_pred_norm(:,1,:) - ref_min)./(ref_max - ref_min);

S_nondim = (CS_true_norm(:,2,:) - ref_min)./(ref_max - ref_min);
S_pred_nondim = (CS_pred_norm(:,2,:) - ref_min)./(ref_max - ref_min);

error_per_C = mean(sum(abs( (C_nondim-C_pred_nondim)./C_nondim )) * 100 / size(C_nondim,1));
error_per_S = mean(sum(abs( (S_nondim-S_pred_nondim)./S_nondim )) * 100 / size(S_nondim,1));
disp('Global error % of C and S')
disp([error_per_C,error_per_S])

% Percent error by harmonics
checkpoint = 0;
error_per_SH_C = zeros(1,max_order_SH,size(SH_C,3));
error_per_SH_S = zeros(1,max_order_SH,size(SH_C,3));

for i=1:max_order_SH
    if i == 1
        checkpoint_init = 1;
        checkpoint_end = 1;

        SH_C_nondim = (CS_true_norm(checkpoint_init:checkpoint_end,1,:) - ref_min)./(ref_max - ref_min);
        SH_C_pred_nondim = (CS_pred_norm(checkpoint_init:checkpoint_end,1,:) - ref_min)./(ref_max - ref_min);
        SH_S_nondim = (CS_true_norm(checkpoint_init:checkpoint_end,2,:) - ref_min)./(ref_max - ref_min);
        SH_S_pred_nondim = (CS_pred_norm(checkpoint_init:checkpoint_end,2,:) - ref_min)./(ref_max - ref_min);

        error_per_SH_C(1,i,:) = mean(abs( (SH_C_nondim-SH_C_pred_nondim)./SH_C_nondim ) * 100 / size(SH_C_nondim,1));
        error_per_SH_S(1,i,:) = mean(abs( (SH_S_nondim-SH_S_pred_nondim)./SH_S_nondim ) * 100 / size(SH_S_nondim,1));
    else
        checkpoint_init = checkpoint_init + checkpoint;
        checkpoint_end = checkpoint_init + checkpoint ;

        SH_C_nondim = (CS_true_norm(checkpoint_init:checkpoint_end,1,:) - ref_min)./(ref_max - ref_min);
        SH_C_pred_nondim = (CS_pred_norm(checkpoint_init:checkpoint_end,1,:) - ref_min)./(ref_max - ref_min);
        SH_S_nondim = (CS_true_norm(checkpoint_init:checkpoint_end,2,:) - ref_min)./(ref_max - ref_min);
        SH_S_pred_nondim = (CS_pred_norm(checkpoint_init:checkpoint_end,2,:) - ref_min)./(ref_max - ref_min);
        
        error_per_SH_C(1,i,:) = mean(sum(abs( (SH_C_nondim-SH_C_pred_nondim)./SH_C_nondim )) * 100 / size(SH_C_nondim,1));
        error_per_SH_S(1,i,:) = mean(sum(abs( (SH_S_nondim-SH_S_pred_nondim)./SH_S_nondim )) * 100 / size(SH_S_nondim,1));
    
    end
    checkpoint = checkpoint + 1; 
end

error_per_SH_C = mean(error_per_SH_C,3);
error_per_SH_S = mean(error_per_SH_S,3);

tabla_error_per_SH = table(error_per_SH_C',error_per_SH_S','VariableNames',{'Error % C','Error % S'});

figure()
bar(0:max_order_SH-1,error_per_SH_C,0.75)
hold on
bar(0:max_order_SH-1,error_per_SH_S,0.3)
title('Error per harmonic')
xlabel('N^t^h Harmonic')
ylabel('Error %')
legend('C','S','Location','northwest')
hold off

%% FUNCTIONS

% This local function sets the plot's vertical axis to logarithmic
function stop = makeLogVertAx(state, whichAx)
 
    stop = false; % The function has to return a value.

    % Only do this once, following the 1st iteration
    if state.Iteration == 1

      % Get handles to "Training Progress" figures:
      hF  = findall(0,'type','figure','Tag','NNET_CNN_TRAININGPLOT_UIFIGURE');

      % Assume the latest figure (first result) is the one we want, and get its axes:
      hAx = findall(hF(1),'type','Axes');

      % Remove all irrelevant entries (identified by having an empty "Tag", R2018a)
      hAx = hAx(~cellfun(@isempty,{hAx.Tag}));
      set(hAx(whichAx),'YScale','log');
    end

end

