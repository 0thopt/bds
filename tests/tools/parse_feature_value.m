function value = parse_feature_value(feature_name, default_value)
%PARSE_FEATURE_VALUE parses the numeric value after the last underscore.

if nargin < 2
    default_value = NaN;
end

feature_name = char(feature_name);
underscore_pos = find(feature_name == '_', 1, 'last');

if isempty(underscore_pos) || underscore_pos == length(feature_name)
    value = default_value;
else
    value = str2double(feature_name(underscore_pos + 1:end));
    if isnan(value)
        value = default_value;
    end
end

end
