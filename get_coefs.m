function [C,S] = get_coefs(length_matrix_coef, index, Data)

    % Get the SH's in a square matrix form
    
    if length_matrix_coef == 0
        C = Data(1,3);
        S = 0;
    else
        C = zeros(length_matrix_coef + 1);
        S = zeros(length_matrix_coef + 1);

        delim = 0;
        for i=1:length_matrix_coef
            delim = delim + i;
        end

        for i=1:(length_matrix_coef + 1)^2-delim
            C(index(i, 1)+1, index(i, 2)+1) = Data(i, 3);
            S(index(i, 1)+1, index(i, 2)+1) = Data(i, 4);
        end
    end
end