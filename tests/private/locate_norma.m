function pmpaths = locate_norma(directory)
%LOCATE_NORMA Locate norma and add required paths for BDS (macOS/Linux compatible).
%
% This function locates norma (https://github.com/blockwise-direct-search/bds_development), adds the
% paths needed for using BDS, and returns these paths in a cell array.
%
% Workflow:
% 1) First try to detect norma from the current MATLAB path.
% 2) If not found, search recursively under the given directory (default: HOME)
%    using the system command 'find'. The constructed 'find' command is compatible
%    with both macOS (BSD find) and Linux (GNU find) by using only commonly
%    supported predicates (e.g., -path, -prune), avoiding GNU-only options such
%    as -maxdepth or -wholename.
% 3) To avoid excessive traversal (which can appear as "no response" on macOS),
%    some common large directories are pruned during the search (e.g., Library,
%    .git, node_modules, .conda, .cache).
%
% Input:
%   directory (optional): root directory under which to search for norma.
%                         Default: getenv('HOME') if norma is not already in path.
%
% Output:
%   pmpaths: a cell array of paths added for norma (currently only the norma root).

% We use the following path as the signature to identify norma.
signature_path = fullfile('bds_development', 'norma');

% pmtools is the path to the directory containing the signature path.
pmtools = '';

if nargin < 1
    % Try to locate norma from MATLAB path first.
    path_strs = strsplit(path(), pathsep);
    ind = find(endsWith(path_strs, signature_path), 1, 'first');
    if ~isempty(ind)
        pmtools = path_strs{ind};
    else
        % Fall back to searching under HOME.
        directory = getenv('HOME');
    end
end

if isempty(pmtools)
    % In the following line, the "*/" before signature_path cannot be removed.
    % It allows matching the signature_path at any depth under the search root.
    name_str = ['"*/', signature_path, '"'];

    % Search recursively using 'find' and stop at the first match.
    %
    % Structure of the find expression:
    %   ( prune_patterns ) -prune -o ( target_match -print -quit )
    %
    % Meaning:
    %   - If the current path matches any of the prune patterns, do not descend
    %     into that directory tree (-prune).
    %   - Otherwise, if it is a directory whose path matches the target signature,
    %     print it and stop searching immediately (-print -quit).
    %   - Redirect stderr to /dev/null to suppress permission errors, etc.
    [~, pmtools] = system([ ...
        'find "', directory, '" ', ...
        '\( -path "*/Library/*" -o -path "*/.git/*" -o -path "*/node_modules/*" -o -path "*/.conda/*" -o -path "*/.cache/*" \) -prune -o ', ...
        '-type d -path ', name_str, ' -print -quit 2>/dev/null' ...
    ]);

    if isempty(pmtools)
        error('locate_norma:normaNotFound', 'Norma of BDS is not found under %s.', directory);
    end
end

% Remove leading/trailing whitespace characters, including the trailing '\n'
% produced by the system command output.
pmtools = strtrim(pmtools);

% There may be other paths to include in the future.
pmpaths = {pmtools};

% Add paths.
for ip = 1 : length(pmpaths)
    addpath(pmpaths{ip});
end
end
