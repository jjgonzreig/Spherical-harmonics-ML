function [data_cut_SH, eros_SH_SH] = unstand_by_harmonics(dataStandardized_SH, eros_Standardized_SH,max_order,stand_params,percent80)

max_order = max_order + 1;
SH_C = zeros([max_order*2-1 max_order size(dataStandardized_SH,3)]);
SH_S = zeros([max_order*2-1 max_order size(dataStandardized_SH,3)]);
SH_C_eros = zeros([max_order*2-1 max_order]);
SH_S_eros = zeros([max_order*2-1 max_order]);

data_cut_SH = zeros(size(dataStandardized_SH));
eros_SH_SH = zeros(size(eros_Standardized_SH));

mean_C = stand_params.mean_C(:,percent80+2:end);
sig_C =  stand_params.sig_C(:,percent80+2:end);
mean_S = stand_params.mean_S(:,percent80+2:end);
sig_S =  stand_params.sig_S(:,percent80+2:end);

mean_C_eros = stand_params.mean_C_eros;
sig_C_eros =  stand_params.sig_C_eros;
mean_S_eros = stand_params.mean_S_eros;
sig_S_eros =  stand_params.sig_S_eros;

checkpoint = 0;
for i=1:max_order
    if checkpoint==0
        checkpoint_end = 1;
        checkpoint_init = 1;

        SH_C(checkpoint_init:checkpoint_end,i,:) = dataStandardized_SH(checkpoint_init : checkpoint_end,1,:);
        SH_C_eros(checkpoint_init:checkpoint_end,i) = eros_Standardized_SH(checkpoint_init : checkpoint_end,1);
        SH_S(checkpoint_init:checkpoint_end,i,:) = dataStandardized_SH(checkpoint_init : checkpoint_end,2,:);
        SH_S_eros(checkpoint_init:checkpoint_end,i) = eros_Standardized_SH(checkpoint_init : checkpoint_end,2);


        data_cut_SH(checkpoint_init : checkpoint_end,1,:) = reshape(sig_C(i,:),1,1,size(data_cut_SH,3)).*SH_C(checkpoint_init : checkpoint_end,i,:) + reshape(mean_C(i,:),1,1,size(data_cut_SH,3));
        data_cut_SH(checkpoint_init : checkpoint_end,2,:) = reshape(sig_S(i,:),1,1,size(data_cut_SH,3)).*SH_S(checkpoint_init : checkpoint_end,i,:) + reshape(mean_S(i,:),1,1,size(data_cut_SH,3));
        eros_SH_SH(checkpoint_init : checkpoint_end,1) = sig_C_eros(i).*SH_C_eros(checkpoint_init : checkpoint_end,i,:) + mean_C_eros(i);
        eros_SH_SH(checkpoint_init : checkpoint_end,2) = sig_S_eros(i).*SH_S_eros(checkpoint_init : checkpoint_end,i,:) + mean_S_eros(i);
   
    else
        checkpoint_init = checkpoint_init + checkpoint;
        checkpoint_end = checkpoint_init + checkpoint ;

        SH_C = dataStandardized_SH(checkpoint_init : checkpoint_end,1,:);
        SH_C_eros = eros_Standardized_SH(checkpoint_init : checkpoint_end,1);
        SH_S = dataStandardized_SH(checkpoint_init : checkpoint_end,2,:);
        SH_S_eros = eros_Standardized_SH(checkpoint_init : checkpoint_end,2);
        

        data_cut_SH(checkpoint_init : checkpoint_end,1,:) = reshape(sig_C(i,:),1,1,size(data_cut_SH,3)).*SH_C + reshape(mean_C(i,:),1,1,size(data_cut_SH,3));
        data_cut_SH(checkpoint_init : checkpoint_end,2,:) = reshape(sig_S(i,:),1,1,size(data_cut_SH,3)).*SH_S + reshape(mean_S(i,:),1,1,size(data_cut_SH,3));
        eros_SH_SH(checkpoint_init : checkpoint_end,1) = sig_C_eros(i).*SH_C_eros + mean_C_eros(i);
        eros_SH_SH(checkpoint_init : checkpoint_end,2) = sig_S_eros(i).*SH_S_eros + mean_S_eros(i);
        

    end
    checkpoint = checkpoint + 1; 

end    

end