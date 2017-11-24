-module(utils).
-export([fuck/0,unique/1]).
-include("planet.hrl").

%% 算block的气
gas(BlockStones,Stones) ->
	length(lists:filter(fun(Point)-> not point_has_stone(Point,Stones) end,sets:to_list(points_around_block(BlockStones)))).
	
%% 把活子，分成块
to_blocks(LiveStones) ->
	{BlackStones,WhiteStones} = lists:partition(fun(Stone) -> Stone#stone.color == ?BLACK end,LiveStones),
	to_blocks([],BlackStones) ++ to_blocks([],WhiteStones).
to_blocks(Blocks,[]) -> Blocks;
to_blocks(Blocks,Stones) -> 
	{BlockStones,OtherStones} = one_block(Stones),
	to_blocks([BlockStones|Blocks],OtherStones).
	
%% 从一堆子里面摘出一个块
one_block(Stones) -> one_block([],Stones).
one_block(BlockStones,[]) -> {BlockStones,[]};
one_block([],[Stone|Stones]) -> one_block([Stone],Stones);
one_block(BlockStones,Stones) ->
	{AroundStones,OtherStones} = stones_at_points(points_around_block(BlockStones),Stones),
	case length(AroundStones) of
		0 -> {BlockStones,OtherStones};
		_ -> one_block(BlockStones++AroundStones,OtherStones) 
	end.

%% 某点是否有子
point_has_stone(Point,Stones) ->
	Points = [Stone#stone.point || Stone <- Stones],
	lists:member(Point,Points).

%% 这些点上的子和不在这些点上的子
stones_at_points(Points,Stones) ->  lists:partition(fun(X)-> sets:is_element(X#stone.point,Points) end,Stones).

%% 块周围的点
points_around_block(BlockStones) ->
	StonePoints = lists:map(fun(X)-> X#stone.point end,BlockStones),
	CrossPoints = block_cross_points(StonePoints),
	sets:subtract(CrossPoints,sets:from_list(StonePoints)).
	
%% 点的运算，用set
block_cross_points(Points) -> block_cross_points(sets:new(),Points).
block_cross_points(CrossPoints,[]) -> CrossPoints; 
block_cross_points(CrossPoints,[Point|Points]) ->
	block_cross_points(sets:union(CrossPoints,sets:from_list(cross_points(Point))),Points).

%% from stones,parse it to lives and deads
simulate_next_stone(Stones,Lives,Deads) -> {Stones,Lives,Deads}.

%% we have lives and deads,remove stone
simulate_pre_stone(Stones,Lives,Deads) -> {Stones,Lives,Deads}.

filter_point({X,Y}) ->
	InRange = fun(A) -> (A>=1) and (A=<19) end,
	InRange(X) and InRange(Y).

cross_points({X,Y}) ->
	lists:filter(fun filter_point/1,[{X,Y-1},{X,Y+1},{X-1,Y},{X+1,Y},{X,Y}]).
	
fuck() ->
	Stones = sgf:get_stones("test1.SGF"),
	Blocks = to_blocks(Stones),
	lists:map(fun(B)-> io:format("block:~p,gas:~p~n",[B,gas(B,Stones)]) end,Blocks),
	ok. 
	