-module(utils).

-export([fuck/0,around_point/1,unique/1]).

-include("planet.hrl").

% 库里提供的是usort，实现时发现sort是有用的，因为有了顺序，不用全部比较
unique(List) -> unique1(List,[]).

unique1([],Acc) -> Acc;
unique1([Head|Tail],[]) -> unique1(Tail,[Head]);
unique1([Head|Tail],Acc) ->
	case lists:member(Head,Acc) of
		true -> unique1(Tail,Acc);
		false -> unique1(Tail,Acc++[Head])
	end.

%% 把活子，分成块
to_blocks(LiveStones) ->
	{BlackStones,WhiteStones} = lists:partition(fun(Stone) -> Stone#stone.color == ?BLACK end,LiveStones),
	to_blocks1([],BlackStones) ++ to_blocks1([],WhiteStones).

to_blocks1(Blocks,[]) -> Blocks;
to_blocks1(Blocks,Stones) -> 
	{BlockStones,OtherStones} = one_block(Stones),
	to_blocks1([BlockStones|Blocks],OtherStones).
	
%% 从一堆子里面摘出一个块
one_block(Stones) -> one_block1([],Stones).

one_block1([],[Stone|Stones]) -> one_block1([Stone],Stones);
one_block1(BlockStones,Stones) ->
	{AroundStones,OtherStones} = stones_at_points(points_around_block(BlockStones),Stones),
	Len = length(BlockStones),
	if 
		Len == 0 -> {BlockStones,OtherStones};
		Len > 0 -> 	one_block1(BlockStones++AroundStones,OtherStones)
	end.

%% 某点是否有子
point_has_stone(Point,Stones) ->
	Points = [Stone#stone.point || Stone <- Stones],
	lists:member(Point,Points).

%% 这些点上的子和不在这些点上的子
stones_at_points(Points,Stones) ->  
	lists:partition(fun(X)-> sets:is_element(X#stone.point,Points) end,Stones).

%% 块周围的点
points_around_block(BlockStones) ->
	StonePoints = lists:filter(fun(X)-> X#stone.point end,BlockStones),
	CrossPoints = block_cross_points(StonePoints),
	sets:subtract(CrossPoints,StonePoints).
	
%% 点的运算，用set
block_cross_points(Points) -> block_cross_points1(sets:new(),Points).

block_cross_points1(CrossPoints,[]) -> CrossPoints; 
block_cross_points1(CrossPoints,[Point|Points]) ->
	block_cross_points1(sets:union(CrossPoints,sets:from_list(cross_points(Point))),Points);

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
	io:format("kdskfkdskfls~n").