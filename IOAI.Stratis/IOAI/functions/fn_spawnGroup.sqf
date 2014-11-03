/*
	FILE :: fn_spawnGroup.sqf ::
	AUTHOR :: Iceman77 ::
	
	DESCRIPTION ::
		- Spawn a random group of a given type (infantry, motorized, armored, mechanized) from the config ::
			-Things to note ::
				- The group itself will ALWAYS be random  
				- The group pool type can be predefined with a number ( see paramaters )
				- Alternatively, the pool can be randomly selected
			::
		::
	::
			
	PARAMETERS ::
		_this select 0 <SIDE> :: (optional - nil) SIDE TO SPAWN eg; WEST, EAST, INDEPENDENT :: 
			- Supported Sides ::
				- west, 
				- blufor,
				- east, 
				- opfor,
				- resistance,
				- independent,
				- sideUnknown
			::
		
		_this select 1 <ARRAY, OBJECT, STRING> :: SPAWN POSITION OF THE GROUP - CAN BE AN OBJECT, ARRAY IN POSITION FORMAT, OR A MARKER STRING ::
		
		_this select 2 <ARRAY, OBJECT, STRING> :: (optional)  GROUP DESTINATION CENTER ( POSITION ) - CAN BE AN OBJECT, ARRAY IN POSITION FORMAT, OR A MARKER STRING ::
		
		_this select 3 <NUMBER> :: (optional)
			Group Type ::
				- 0=INFANTRY TYPE >> RANDOM GROUP
				- 1=MOTORIZED TYPE >> RANDOM GROUP
				- 2=MECHANIZED TYPE >> RANDOM GROUP
				- 3=ARMORED TYPE >> RANDOM GROUP
				- 4=RANDOM TYPE >> RANDOM GROUP				
			::
		::
		
		_this select 4 <NUMBER> :: (optional)
			Group Mode ::
				- 0=PATROL
				- 1=DEFEND
				- 2=ATTACK
				- 3=RANDOM
			::	
			
		::	
		
		_this select 5 <NUMBER> :: (optional) GROUP RESPAWN AMOUNT :: 
		
		_this select 6 <BOOL> ::  (optional) DEBUG MARKERS ::
		
	::
	
	RETURNS :: NOTHING ::
	
	USAGE EXAMPLES :: 
		:: [ sideUnknown, [5000, 3450, 0], "mrk2", 4, 3, 15] spawn IOAI_fnc_spawnGroup; 	
		:: [ west, pad1, nil, 0, 0, 0] spawn IOAI_fnc_spawnGroup; 
		:: [ east, "mrk1", "mrk2", 2, 0, 5] spawn IOAI_fnc_spawnGroup; 
		:: [ resistance, "mrk1", pad2, 1, 2, 25] spawn IOAI_fnc_spawnGroup; 
		:: [ west, "mrk1", pad2, 1, 2, 5, true] spawn IOAI_fnc_spawnGroup; 
		:: [ west, pad1, nil, nil, nil, nil, true ] spawn IOAI_fnc_spawnGroup;
		:: [ west, pad1 ] spawn IOAI_fnc_spawnGroup;
		:: [ nil, pad1 ] spawn IOAI_fnc_spawnGroup;
	::

*/

if ( !( isServer ) ) exitWith {};

private [
	"_side","_spawnPos","_patPos","_patType","_patMode","_respawnCount","_west","_east",
	"_independent","_sideArray","_faction","_typeArray","_sideSTR","_grpArray","_randomType","_cfgArray",
	"_randomGrp","_grp","_IOAI_EH","_patModeHandle","_debugHandle","_spawnDir"
];

_side 			= [_this, 0, sideUnknown, [sideUnknown]] call BIS_fnc_param;
_spawnPos 		= [_this, 1, [0,0,0], ["",objNull,[]], [2,3]] call BIS_fnc_param;
_patPos 			= [_this, 2, _spawnPos, ["",objNull,[]], [2,3]] call BIS_fnc_param;
_patType 		= [_this, 3, 4, [-1]] call BIS_fnc_param;
_patMode 		= [_this, 4, 0, [-1]] call BIS_fnc_param;
_respawnCount 	= [_this, 5, 0, [-1]] call BIS_fnc_param;
_debug 			= [_this, 6, false, [true]] call BIS_fnc_param;

if ( { side _x == east } count allUnits == 0 ) then {_east = createCenter east;}; 
if ( { side _x == west } count allUnits == 0 ) then {_west = createCenter west;}; 
if ( { side _x == independent } count allUnits == 0 ) then {_independent = createCenter independent;}; 

if ( _side == sideUnknown ) then {
	_sideArray = [west,east,independent];
	_side = _sideArray select floor random count _sideArray;
};

_faction = switch ( _side ) do {
	case west:{"BLU_F";};
	case blufor:{"BLU_F";};
	case east:{"OPF_F";};
	case opfor:{"OPF_F";};
	case resistance:{"IND_F";};
	case independent:{"IND_F";};
	default {"BLU_F";};
};

_spawnDir = switch ( typeName _spawnPos ) do {
	case "STRING":{markerDir _spawnPos;};
	case "OBJECT":{getDir _spawnPos;};
	case "ARRAY":{random 360;};
	default {random 360;};
};

_spawnPos = switch ( typeName _spawnPos ) do {
	case "STRING":{getMarkerPos _spawnPos;};
	case "OBJECT":{getPos _spawnPos;};
	case "ARRAY":{_spawnPos;};
	default {_spawnPos;};
};

_patPos = switch ( typeName _patPos ) do {
	case "STRING":{getMarkerPos _patPos;};
	case "OBJECT":{getPos _patPos;};
	case "ARRAY":{_patPos;};
	default {_patPos;};
}; 

_typeArray = switch _patType do {
	case 0:{
		["Infantry"];
	};
	case 1:{
		if ( _faction == "OPF_F" ) then { 
			["Motorized_MTP"];
		} else {
			["Motorized"];
		};
	};
	case 2:{
		["Mechanized"];
	};
	case 3:{
		["Armored"];
	};
	case 4:{
		if ( _faction == "OPF_F" ) then { 
			["Motorized_MTP","Infantry","Mechanized", "Armored"];
		} else {
			["Motorized","Infantry","Mechanized", "Armored"];
		};
	};
	default {
		["Infantry"];
	};
};

_sideSTR = if ( _side in [ blufor, opfor, independent, resistance ] ) then {
	switch _side do {
		case blufor:{"west";};
		case opfor:{"east";};
		case independent:{"indep";};
		case resistance:{"indep";};
	};	
} else {
	str _side;
};

_grpArray = [];
_randomType = ( _typeArray select floor random count _typeArray );
_cfgArray = "_grpArray pushBack (configName _x)" configClasses (configfile >> "CfgGroups" >> _sideSTR >> _faction >> _randomType);
_randomGrp = ( _grpArray select floor random count _grpArray );
_grp = [ _spawnPos, _side, ( configFile >> "CfgGroups" >> _sideSTR >> _faction >> _randomType >> _randomGrp ), nil, nil, nil, nil, [2,random 1], _spawnDir ] call BIS_fnc_spawnGroup;

IOAI_BD = {
	sleep 60;
	deleteVehicle ( _this select 0 );
};

_IOAI_EH = {
	{
		_x addEventhandler ["killed", {_this spawn IOAI_BD;}];
	} forEach ( units _grp );
};

_patModeHandle = { 
	switch _patMode do {
		case 0:{[_grp, _patPos, 50 + random 150] call bis_fnc_taskPatrol;};
		case 1:{[_grp, _patPos] call BIS_fnc_taskDefend;};
		case 2:{[_grp, _patPos] call BIS_fnc_taskAttack;};
		case 3:{
			[
				[_grp, _patPos, 50 + random 150] call bis_fnc_taskPatrol,
				[_grp, _patPos] call BIS_fnc_taskDefend,
				[_grp, _patPos] call BIS_fnc_taskAttack
			] call BIS_fnc_selectRandom;
		};
		default {[_grp, _patPos, 50 + random 150] call bis_fnc_taskPatrol;};
	};
	if ( true ) exitWith {};
};

_debugHandle = {
	if ( _debug ) then {
		[_grp] spawn {
			private ["_markerArray", "_mrk", "_grp","_color"];
			_grp = _this select 0;
			_markerArray = [];
			_color = [side (leader _grp), true] call BIS_fnc_sideColor;
			{
				_mrk = createMarker [ format ["marker%1", random 10000], getPosATL _x]; 
				_mrk setMarkerShape "ICON"; 
				_mrk setMarkerType "mil_dot";
				_mrk setMarkerColor _color;
				_markerArray pushBack [_mrk, _x];
			} forEach ( units _grp );
			
			while { true } do {
				{ 
					if ( alive ( _x select 1 ) ) then {
						( _x select 0 ) setMarkerPos getPosATL ( _x select 1 ); 
					} else {
						deleteMarker ( _x select 0 );
						_markerArray deleteAt _foreachIndex;
					};
				} forEach _markerArray;
				if ( count _markerArray == 0 ) exitWith {};
				sleep 0.1;
			}; 				
		};
	};	
  if ( true ) exitWith {};
};

_nul = call _patModeHandle;
_nul = call _debugHandle;
_nul = call _IOAI_EH;

if ( _respawnCount > 0 ) then {
	for "_i" from 0 to _respawnCount - 1 do {
		waitUntil { sleep 5; { alive _x } count units _grp == 0;};
		_grp = [ _spawnPos, _side, ( configFile >> "CfgGroups" >> _sideSTR >> _faction >> _randomType >> _randomGrp ), nil, nil, nil, nil, [2,random 1], _spawnDir ] call BIS_fnc_spawnGroup;
		_nul = call _patModeHandle;
		_nul = call _debugHandle;
		_nul = call _IOAI_EH;
	};
};

nil
