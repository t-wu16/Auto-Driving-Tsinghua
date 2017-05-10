function UpdateSpeed(insideList)
%UpdateSpeed - Simulate the whole crossroad
%
% Syntax:  [~] = SimuXRoad()
%
% Inputs:
%    none      
%
% Outputs:
%    none
%
% Example: 
%    none
%
% Other m-files required: none
% Subfunctions: GenRandState, FindMaxState, GetQValue, Trim
% MAT-files required: none
%
% See also: none

% Author: Bai Liu
% Department of Automation, Tsinghua University 
% email: liubaichn@126.com
% 2017.05; Last revision: 2017.05.10

%------------- BEGIN MAIN FUNCTION --------------

%--- Set global variable(s) ---
global VehicleList;
global intScale;

%--- Initialize variable(s) ---
insideCell = cell(8, 1);
for i = 1:1:8
	insideCell{i} = zeros(0, 1);
end

%--- Classify vehicles ---
for i = 1:1:size(insideList, 1)
	% Initialize variable(s)
	curID = insideList(i, 1);
	curVehicle = VehicleList(curID);
	% Classify vehicles
	if curVehicle.state == 1
		switch 10*curVehicle.route(1)+curVehicle.route(2)
			case 12
				insideCell{1} = [insideCell{1}; curID];
			case 14
				if curVehicle.type == 1
					insideCell{2} = [insideCell{2}; curID];
				end
			case 34
				insideCell{3} = [insideCell{3}; curID];
			case 36
				if curVehicle.type == 1
					insideCell{4} = [insideCell{4}; curID];
				end
			case 56
				insideCell{5} = [insideCell{5}; curID];
			case 58
				if curVehicle.type == 1
					insideCell{6} = [insideCell{6}; curID];
				end
			case 78
				insideCell{7} = [insideCell{7}; curID];
			case 72
				if curVehicle.type == 1
					insideCell{8} = [insideCell{8}; curID];
				end
			otherwise
		end
	end
end

%--- Update vehicle speed ---
for i = 1:1:8
	j = 1;
	while j <= size(insideCell{i}, 1)-1
		% Locate current vehicle
		curID = insideCell{i}(j);
		curVehicle = VehicleList(curID);
		if curVehicle.type == 1
			% Locate the vehicle behind
			nextID = insideCell{i}(j+1);
			nextVehicle = VehicleList(nextID);
			% Get dynamic properties
			v1 = curVehicle.dynamic(1);
			x1 = curVehicle.position(1);
			y1 = curVehicle.position(2);
			v2 = nextVehicle.dynamic(1);
			x2 = nextVehicle.position(1);
			y2 = nextVehicle.position(2);
			% Initialize variables required to calculate new speed
			interval = Trim(sqrt((x1-x2)^2+(y1-y2)^2), intScale);
			curState = [interval, v1, v2];
			if curVehicle.type == 1
				optType = 0;
			else
				optType = 1;
			end
			% Update speed
			nextState = GetNextState(curState, optType);
			VehicleList(curID).dynamic(1) = nextState(2);
			VehicleList(nextID).dynamic(1) = nextState(3);
			% Set index
			j = j+2;
		else
			% Set index
			j = j+1;
		end
	end
end


%------------- END OF MAIN FUNCTION --------------
end



%------------- BEGIN SUBFUNCTION(S) --------------

%--- Get the optimized speed of the next time slot ---
function nextState = GetNextState(curState, optType)

	nextStateList = CalLineAction(curState, optType);
	if ~isempty(nextStateList)
		[nextState, ~] = FindMaxState(nextStateList);
	else

	end

end

%--- Generate random state ---
function [preState, curState, curQ] = GenRandState()
	% Set global variable(s)	
	global intScale;
	global intRange;
	global vScale;
	global vRange;
	global optType;
	% Initialize variable(s)
	preState = zeros(1, 3);
	curState = zeros(1, 3);
	curStateList = zeros(0, 3);
	randVMin = 2;
	randVMax = 6;
	randIntMin = 3;
	randIntMax = 7;
	% Initialize preState
	while isempty(curStateList)
		preState(1) = Trim(randIntMin+(randIntMax-randIntMin)*rand, intScale);
		preState(2) = Trim(randVMin+(randVMax-randVMin)*rand, vScale);
		preState(3) = Trim(randVMin+(randVMax-randVMin)*rand, vScale);
		curStateList = CalLineAction(preState, optType);
	end
	% Initialize curState
	[curState, curQ] = FindMaxState(curStateList);
end

%--- Search for the state with maximum reward ---
function [maxState, maxQ] = FindMaxState(stateList)
	% Initialize variable(s)
	maxState = stateList(1, : );
	maxQ = GetQValue(maxState);
	% Selection sorts
	for i = 2:1:size(stateList, 1)			
		curQ = GetQValue(stateList(i, : ));
		if curQ > maxQ
			maxState = stateList(i, : );
			maxQ = curQ;
		end
	end
end

%--- Map value to index ---
function QValue = GetQValue(state)
	% Set global variable(s)	
	global QMatrixLine;
	global intScale;
	global vScale;
	global optType;
	% Calculate index of optimization type
	typeIndex = optType+1;
	% Calculate index of interval
	intIndex = floor(state(1)/intScale)+1;
	% Calculate index of speed
	vIndex1 = floor(state(2)/vScale)+1;
	vIndex2 = floor(state(3)/vScale)+1;
	% Calculate the value in Q matrix
	QValue = QMatrixLine(typeIndex, intIndex, vIndex1, vIndex2);
end

%--- Trim number to corresponding scale ---
function trimNumber = Trim(originNumber, scale)
	% Calculate the trimmed value
	trimNumber = round(originNumber/scale)*scale;
end

%------------- END OF SUBFUNCTION(S) --------------