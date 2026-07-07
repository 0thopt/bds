function prod_memory = remember_accelerated_bds_direction(prod_memory, direction, step, mem_size)
%REMEMBER_ACCELERATED_BDS_DIRECTION Store a successful direction if it is new.

direction = direction(:);
norm_direction = norm(direction);
if norm_direction == 0
    return;
end
direction = direction / norm_direction;

is_dup = false;
for k = 1:numel(prod_memory)
    if abs(prod_memory(k).direction' * direction) > 0.95
        is_dup = true;
        break;
    end
end
if is_dup
    return;
end

if numel(prod_memory) >= mem_size
    prod_memory(end) = [];
end
prod_memory = insert_accelerated_bds_memory_front(prod_memory, direction, step);

end
