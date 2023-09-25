function Data = build_data(C, S, r)

    % Create the matrix Data and set its length to match the length of r
    
%     Data = zeros(length(r),3);
%     Data(:,1) = C(1:length(r));
%     Data(:,2) = S(1:length(r));
%     Data(:,3) = r;
    if length(r) <= length(C)
        Data = zeros(length(C),3);
        Data(:,1) = C;
        Data(:,2) = S;
        Data((1:length(r)),3) = r;
    else
        Data = zeros(length(r),3);
        Data(1:length(C),1) = C;
        Data(1:length(S),2) = S;
        Data(:,3) = r;
    end
end