function [c,il,ir] = innerjoin(a,b,varargin)
%INNERJOIN Inner join between two tables or two timetables.
%   T = INNERJOIN(TLEFT, TRIGHT) creates the table T as the inner join
%   between the tables TLEFT and TRIGHT.  If TLEFT is a timetable, then
%   TRIGHT can be either a table or a timetable, and innerjoin returns T as
%   a timetable for either combination of inputs.  An inner join retains
%   only the rows that match between TLEFT and TRIGHT.
%
%   INNERJOIN first finds one or more key variables.  A key is a variable
%   that occurs in both TLEFT and TRIGHT with the same name.  If both TLEFT
%   and TRIGHT are timetables, the key variables are the time vectors of
%   TLEFT and TRIGHT.  INNERJOIN then uses those key variables to match up
%   rows between TLEFT and TRIGHT.  T contains one row for each pair of
%   rows in TLEFT and TRIGHT that share the same combination of key values.
%   In general, if there are M rows in TLEFT and N rows in TRIGHT that all
%   contain the same combination of key values, T contains M*N rows for
%   that combination.  INNERJOIN sorts the rows in the result T by the key
%   values.
%
%   T contains all variables from both TLEFT and TRIGHT, but only one copy
%   of the key variables. If TLEFT and TRIGHT contain variables with
%   identical names, INNERJOIN adds a unique suffix to the corresponding
%   variable names in T.
%
%   T = INNERJOIN(TLEFT, TRIGHT, 'PARAM1',val1, 'PARAM2',val2, ...) allows
%   you to specify optional parameter name/value pairs to control how
%   INNERJOIN uses the variables in TLEFT and TRIGHT.  Parameters are:
%
%           'Keys'      - specifies the variables to use as keys.
%           'LeftKeys'  - specifies the variables to use as keys in TLEFT.
%           'RightKeys' - specifies the variables to use as keys in TRIGHT.
%
%   You may provide either the 'Keys' parameter, or both the 'LeftKeys' and
%   'RightKeys' parameters.  The value for these parameters is a positive
%   integer, a vector of positive integers, a variable name, a cell array
%   of character vectors or string array of variable names, or a logical
%   vector.  'LeftKeys' or 'RightKeys' must both specify the same number of
%   key variables, and the left and right keys are paired in the order
%   specified.
%
%   When joining two timetables, 'Keys', or 'LeftKeys' and 'RightKeys',
%   must be the time vector names of the timetables.
%
%      'LeftVariables'  - specifies which variables from TLEFT to include in T.
%                         By default, INNERJOIN includes all variables from TLEFT.
%      'RightVariables' - specifies which variables from TRIGHT to include in T.
%                         By default, INNERJOIN includes all variables from TRIGHT
%                         except the key variables.
%
%   'LeftVariables' or 'RightVariables' can be used to include or exclude
%   key variables as well as data variables.  The value for these
%   parameters is a positive integer, a vector of positive integers, a
%   variable name, a cell array of character vectors or string array
%   containing one or more variable names, or a logical vector.
%
%   [T,ILEFT,IRIGHT] = INNERJOIN(TLEFT, TRIGHT, ...) returns index vectors
%   ILEFT and IRIGHT indicating the correspondence between rows in T and
%   those in TLEFT and TRIGHT.  INNERJOIN constructs T by horizontally
%   concatenating TLEFT(ILEFT,LEFTVARS) and TRIGHT(IRIGHT,RIGHTVARS).
%
%   Example:
%
%     % Create two tables that both contain the key variable 'Key1'.  The
%     % two arrays contain rows with common values of Key1, but each array
%     % also contains rows with values of Key1 not present in the other.
%     Tleft = table({'a' 'b' 'c' 'e' 'h'}',[1 2 3 11 17]','VariableNames',{'Key1' 'Var1'})
%     Tright = table({'a' 'b' 'd' 'e'}',[4 5 6 7]','VariableNames',{'Key1' 'Var2'})
%
%     % Join Tleft and Tright, retaining only rows whose key values match.
%     T = innerjoin(Tleft,Tright,'key','Key1')
%
%
%     % Create two timetables Tleft and Tright. The time vectors of each timetable
%     % partially overlap.
%     Tleft = timetable(seconds([1;2;4;6]),[1 2 3 11]')
%     Tright = timetable(seconds([2;4;6;7]),[4 5 6 7]')
%
%     % Combine Tleft and Tright with an inner join.  Only retains rows whose times have
%     % a match.
%     T = innerjoin(Tleft,Tright)
%
%   See also OUTERJOIN, JOIN, HORZCAT, SORTROWS,
%            UNION, INTERSECT, ISMEMBER, UNIQUE, INNER2OUTER, ROWS2VARS.

%   Copyright 2012-2019 The MathWorks, Inc.

narginchk(2,inf);
if ~matlab.internal.datatypes.istabular(a) || ~matlab.internal.datatypes.istabular(b)
    error(message('MATLAB:table:join:InvalidInput'));
end

type = 'inner';
keepOneCopy = [];
pnames = {'Keys' 'LeftKeys' 'RightKeys' 'LeftVariables' 'RightVariables'};
dflts =  {   []         []          []              []               [] };
[keys,leftKeys,rightKeys,leftVars,rightVars,supplied] ...
         = matlab.internal.datatypes.parseArgs(pnames, dflts, varargin{:});
supplied.KeepOneCopy = 0;
    
[leftVars,rightVars,leftVarDim,rightVarDim,leftKeyVals,rightKeyVals,leftKeys,rightKeys] ...
    = tabular.joinUtil(a,b,type,inputname(1),inputname(2), ...
                       keys,leftKeys,rightKeys,leftVars,rightVars,keepOneCopy,supplied);
                   
% If leftVariables and rightVariables are provided, it indicates which
% variable (and thus properties) are kept for key variables. We only need
% to merge key variable properties if leftVariables and rightVariables are
% not provided.
if ~supplied.LeftVariables && ~supplied.RightVariables
    mergeKeyProps = true; 
else
    mergeKeyProps = false;
end

leftOuter = false;
rightOuter = false;
[c,il,ir] = tabular.joinInnerOuter(a,b,leftOuter,rightOuter,leftKeyVals,rightKeyVals, ...
                                   leftVars,rightVars,leftKeys,rightKeys,leftVarDim,rightVarDim,mergeKeyProps);
