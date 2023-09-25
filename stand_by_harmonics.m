function [dataStandardized_SH, eros_Standardized_SH, stand_params] = stand_by_harmonics(data_cut_SH, eros_SH_SH,max_order)

max_order = max_order + 1;
SH_C = zeros([max_order*2-1 max_order size(data_cut_SH,3)]);
SH_S = zeros([max_order*2-1 max_order size(data_cut_SH,3)]);
SH_C_eros = zeros([max_order*2-1 max_order]);
SH_S_eros = zeros([max_order*2-1 max_order]);

mean_C = zeros(max_order,size(data_cut_SH,3));
sig_C =  zeros(max_order,size(data_cut_SH,3));
mean_S = zeros(max_order,size(data_cut_SH,3));
sig_S =  zeros(max_order,size(data_cut_SH,3));

mean_C_eros = zeros(max_order,1);
sig_C_eros =  zeros(max_order,1);
mean_S_eros = zeros(max_order,1);
sig_S_eros =  zeros(max_order,1);

dataStandardized_SH = zeros(size(data_cut_SH));
eros_Standardized_SH = zeros(size(eros_SH_SH));

checkpoint = 0;
for i=1:max_order
    if checkpoint==0
        checkpoint_end = 1;
        checkpoint_init = 1;

        SH_C(checkpoint_init:checkpoint_end,i,:) = data_cut_SH(checkpoint_init : checkpoint_end,1,:);
        SH_C_eros(checkpoint_init:checkpoint_end,i) = eros_SH_SH(checkpoint_init : checkpoint_end,1);
        SH_S(checkpoint_init:checkpoint_end,i,:) = data_cut_SH(checkpoint_init : checkpoint_end,2,:);
        SH_S_eros(checkpoint_init:checkpoint_end,i) = eros_SH_SH(checkpoint_init : checkpoint_end,2);

        mean_C(i,:) = reshape(mean(SH_C(checkpoint_init : checkpoint_end,i,:),1),1,size(data_cut_SH,3));
%         sig_C(i,:) =  reshape(std(SH_C(checkpoint_init : checkpoint_end,i,:),0,1),1,size(data_cut_SH,3));
        sig_C(i,:) = 1;
        mean_S(i,:) = reshape(mean(SH_S(checkpoint_init : checkpoint_end,i,:),1),1,size(data_cut_SH,3));
%         sig_S(i,:) =  reshape(std(SH_S(checkpoint_init : checkpoint_end,i,:),0,1),1,size(data_cut_SH,3));
        sig_S(i,:) = 1;

        mean_C_eros(i) = mean(SH_C_eros(checkpoint_init : checkpoint_end,i),1);
%         sig_C_eros(i) =  std(SH_C_eros(checkpoint_init : checkpoint_end,i),0,1);
        sig_C_eros(i) = 1;
        mean_S_eros(i) = mean(SH_S_eros(checkpoint_init : checkpoint_end,i),1);
%         sig_S_eros(i) =  std(SH_S_eros(checkpoint_init : checkpoint_end,i),0,1);
        sig_S_eros(i) = 1;
        
        dataStandardized_SH(checkpoint_init : checkpoint_end,1,:) = (SH_C(checkpoint_init : checkpoint_end,i,:) - reshape(mean_C(i,:),1,1,size(data_cut_SH,3))) ./ reshape(sig_C(i,:),1,1,size(data_cut_SH,3));
        dataStandardized_SH(checkpoint_init : checkpoint_end,2,:) = (SH_S(checkpoint_init : checkpoint_end,i,:) - reshape(mean_S(i,:),1,1,size(data_cut_SH,3))) ./ reshape(sig_S(i,:),1,1,size(data_cut_SH,3));
        eros_Standardized_SH(checkpoint_init : checkpoint_end,1) = (SH_C_eros(checkpoint_init : checkpoint_end,i,:) - mean_C_eros(i)) ./ sig_C_eros(i);
        eros_Standardized_SH(checkpoint_init : checkpoint_end,2) = (SH_S_eros(checkpoint_init : checkpoint_end,i,:) - mean_S_eros(i)) ./ sig_S_eros(i);
   
    else
        checkpoint_init = checkpoint_init + checkpoint;
        checkpoint_end = checkpoint_init + checkpoint ;

        SH_C = data_cut_SH(checkpoint_init : checkpoint_end,1,:);
        SH_C_eros = eros_SH_SH(checkpoint_init : checkpoint_end,1);
        SH_S = data_cut_SH(checkpoint_init : checkpoint_end,2,:);
        SH_S_eros = eros_SH_SH(checkpoint_init : checkpoint_end,2);
        
        mean_C(i,:) = reshape(mean(SH_C,1),1,size(data_cut_SH,3));
        sig_C(i,:) =  reshape(std(SH_C,0,1),1,size(data_cut_SH,3));
        mean_S(i,:) = reshape(mean(SH_S,1),1,size(data_cut_SH,3));
        sig_S(i,:) =  reshape(std(SH_S,0,1),1,size(data_cut_SH,3));

        mean_C_eros(i) = mean(SH_C_eros,1);
        sig_C_eros(i) =  std(SH_C_eros,0,1);
        mean_S_eros(i) = mean(SH_S_eros,1);
        sig_S_eros(i) =  std(SH_S_eros,0,1);

        dataStandardized_SH(checkpoint_init : checkpoint_end,1,:) = (SH_C - reshape(mean_C(i,:),1,1,size(data_cut_SH,3))) ./ reshape(sig_C(i,:),1,1,size(data_cut_SH,3));
        dataStandardized_SH(checkpoint_init : checkpoint_end,2,:) = (SH_S - reshape(mean_S(i,:),1,1,size(data_cut_SH,3))) ./ reshape(sig_S(i,:),1,1,size(data_cut_SH,3));
        eros_Standardized_SH(checkpoint_init : checkpoint_end,1) = (SH_C_eros - mean_C_eros(i)) ./ sig_C_eros(i);
        eros_Standardized_SH(checkpoint_init : checkpoint_end,2) = (SH_S_eros - mean_S_eros(i)) ./ sig_S_eros(i);
        

    end
    checkpoint = checkpoint + 1; 

end    

param_headings = {'mean_C','mean_C_eros','mean_S','mean_S_eros','sig_C','sig_C_eros','sig_S','sig_S_eros'};
aux1 = mat2cell(mean_C,size(mean_C,1));
aux2 = mat2cell(mean_C_eros,size(mean_C_eros,1));
aux3 = mat2cell(mean_S,size(mean_S,1));
aux4 = mat2cell(mean_S_eros,size(mean_S_eros,1));
aux5 = mat2cell(sig_C,size(sig_C,1));
aux6 = mat2cell(sig_C_eros,size(sig_C_eros,1));
aux7 = mat2cell(sig_S,size(sig_S,1));
aux8 = mat2cell(sig_S_eros,size(sig_S_eros,1));

stand_params = cell2struct([aux1,aux2,aux3,aux4,aux5,aux6,aux7,aux8],param_headings,2);
end