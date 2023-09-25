function R = get_R(lambda, phi, C, S, normalize_P, normalize_C, normalize_S)

    % Calculates the radial component at a given longitude and latitude (lambda and phi)
    % with the harmonic coefficients C and S
    
    P00 = 1;
    u = sin(phi);
    P = zeros(length(C));
%     P_dif = zeros(length(C));
    P(1,1) = P00;
    
    for n=0:length(C)-2
        P(n+2, n+2) = (2*n + 1)*sqrt(1 - u.^2)*P(n+1,n+1);
        for m=0:n
            if n==0
                P(n+2, m+1) = (2*n + 1)*u*P(n+1,m+1)/(n - m + 1);
            else
                P(n+2, m+1) = (2*n + 1)*u*P(n+1,m+1)/(n - m + 1) - (n + m)*P(n, m+1)/(n - m + 1);
            end
        end
    end

%     for n=0:size(P,1)-1
%         aux = legendre(n,u)';
%         P_dif(n+1,1:size(aux,2)) = aux;
%     end
    
    if normalize_P == 1
        P_norm = zeros(size(P));
        for n=0:length(P)-1
            for m=0:n
                if (n-m == 0)
                    fact_min = 1;
                else
                    fact_min = prod(1:(n-m));
                end
                if (n+m == 0)
                    fact_plus = 1;
                else
                    fact_plus = prod(1:(n+m));
                end
                P_norm(n+1,m+1) = sqrt((2 - eq(0, m))*(2*n + 1)*fact_min / fact_plus) * P(n+1,m+1);
%                 P_norm(n+1,m+1) = sqrt((2 - eq(0, m))*(2*n + 1)*factorial(n - m) / factorial(n + m)) * P(n+1,m+1);
            end
        end        
        P = P_norm;
    end

    if normalize_C == 1
        C_norm = zeros(size(C));
        for n=0:length(P)-1
            for m=0:n
                C_norm(n+1,m+1) = sqrt(factorial(n + m) / ((2 - eq(0, m))*(2*n + 1)*factorial(n - m)) ) * C(n+1,m+1);
            end
        end        
        C = C_norm;
    end   

    if normalize_S == 1
        S_norm = zeros(size(S));
        for n=0:length(P)-1
            for m=0:n
                S_norm(n+1,m+1) = sqrt(factorial(n + m) / ((2 - eq(0, m))*(2*n + 1)*factorial(n - m)) ) * S(n+1,m+1);
            end
        end        
        S = S_norm;
    end 

    R = 0;
    for n=0:length(P)-1
        for m=0:n            
            R = R + P(n+1,m+1)*(C(n+1,m+1)*cos(m*lambda) + S(n+1,m+1)*sin(m*lambda));
        end
    end
    
end