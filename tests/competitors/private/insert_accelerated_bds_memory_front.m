function prod_memory = insert_accelerated_bds_memory_front(prod_memory, direction, step)
%INSERT_ACCELERATED_BDS_MEMORY_FRONT Insert a direction at the front of memory.

entry.direction = direction(:);
entry.step = double(step);
if isempty(prod_memory)
    prod_memory = entry;
else
    prod_memory = [entry, prod_memory];
end

end
