function array = cycling(array, index, strategy)
%   ARRAY = CYCLING(ARRAY, INDEX, STRATEGY) returns an array
%   that is a permutation of ARRAY according to INDEX, STRATEGY.
%
%   ARRAY is the array to permute. It must be a vector.
%   INDEX is a number from -1, 1, 2, ..., length(array). If INDEX = -1, then there is
%   no permutation.
%   STRATEGY is a nonnegative integer from 0 to 3, indicating the strategy of the
%   permutation as follows.
%
%
%   0  No permutation.
%
%   1  The element of the index will be moved to the first element of the array.
%
%   EXAMPLE
%   Let array = a3 a1 a2 a4 a5 and let the original index be 3 (pointing to a2).
%   If with_cycling_memory is true, the output is a2 a3 a1 a4 a5.
%   If with_cycling_memory is false, we first sort the array to a1 a2 a3 a4 a5,
%   remap the original index 3 to sorted index 2, and obtain a2 a1 a3 a4 a5.
%
%   2  The element of the index and the following ones until the end will be
%      moved ahead of the array.
%
%   EXAMPLE
%   Let array = a4 a5 a1 a2 a3 and let the original index be 4 (pointing to a2).
%   This array is a cyclic order that can appear in BDS when strategy 2 is used.
%   If with_cycling_memory is true, the output is a2 a3 a4 a5 a1.
%   If with_cycling_memory is false, we first sort the array to a1 a2 a3 a4 a5,
%   remap the original index 4 to sorted index 2, and obtain a2 a3 a4 a5 a1.
%
%   3  The element of the following ones after the index until the end will be
%      moved ahead of the array.
%
%   EXAMPLE
%   Let array = a3 a4 a5 a1 a2 and let the original index be 4 (pointing to a1).
%   If with_cycling_memory is true, the output is a2 a3 a4 a5 a1.
%   If with_cycling_memory is false, we first sort the array to a1 a2 a3 a4 a5,
%   remap the original index 4 to sorted index 1, and obtain a2 a3 a4 a5 a1.
%

% Check whether the input is given in the correct type.
if ~isrealvector(array)
    error("Array is not a real vector.");
end
if ~isintegerscalar(index)
    error("Index is not an integer.");
end
if ~isintegerscalar(strategy) || strategy < 0 || strategy > 3
    error("Strategy is not a positive integer or less than or equal to 3.");
end

%   If index < 0, then there is no "success_index" and there is no
%   permutation. If strategy == 0, then the permutation is unchanged.
if index < 0 || strategy == 0
    return;
end

switch strategy
    case {1}
        array(1:index) = array([index, 1:index-1]);
    case {2}
        array = array([index:end, 1:index-1]);
    case {3}
        array = array([index+1:end, 1:index]);
end

% Check whether the output is in the right type.
if ~isrealvector(array)
    error("Array is not a real vector.");
end
    
end