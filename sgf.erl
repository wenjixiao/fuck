-module(sgf).
-export([get_stones/1]).
-include("planet.hrl").

read_file(FileName) ->
	case file:open(FileName,[raw,read]) of
		{ok,File} -> read_file(File,"");
		{error,Reason} -> io:format("file open error:~p~n",[Reason])
	end.

read_file(File,String) ->
	case file:read(File,1024) of
		{ok,Data} -> read_file(File,String++Data);
		eof -> String;
		{error,Reason} -> io:format("file read error:~p~n",[Reason])
	end.

parse(String) -> parse(String,0,[]).
parse(String,Offset,Acc) ->
	RE = "(B|W)\\[([a-t])([a-t])\\]",
	case re:run(String,RE,[dotall,{capture,first,index},{offset,Offset}]) of
		nomatch -> Acc;
		{match,[{Index,Len}]} ->
			parse(String,Index+Len,Acc++[string:substr(String,Index+1,Len)])
	end.

parse_stones(StoneStrList) -> parse_stones(StoneStrList,[]).
parse_stones([],Acc) -> Acc;
parse_stones([StoneStr|Other],Acc) -> parse_stones(Other,Acc++[parse_stone(StoneStr)]).
	
parse_stone(StoneStr) ->
	Color = case string:substr(StoneStr,1,1) of
				"W" -> ?WHITE;
				"B" -> ?BLACK
			end,
	[X] = string:substr(StoneStr,3,1),
	[Y] = string:substr(StoneStr,4,1),
	#stone{color=Color,point={X-96,Y-96}}.

get_stones(FileName) ->
	parse_stones(parse(read_file(FileName))).
	