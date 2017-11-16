-module(game).
% location
-record(loc,{x,y}).
% stone
-record(stone,{color,loc,seq}).
-record(time,{save,times,per}).
% first_nth=0 means #Random#!
-record(proto,{give_back=6.5,first_nth=0,time,give_stone=0}).
% win_type=0 mid win,win_type=1 count,win_type=2 no winner
-record(result,{win_type,winner_nth,howmuch}).

-record(client_proxy,{pid,player_id,player}).

-record(game,{id,proto,playing_proxys,watching_proxys=[],stones=[],result}).

start(ClientProxy1,ClientProxy2) ->
	Game = #game{id=idpool:get_num(),playing_proxys=[ClientProxy1,ClientProxy2]},
	begin_negotiate(Game).

begin_negotiate(Game) ->
    io:format("game begin-negotiate!~n").

playing(Game) ->
    io:format("game playing!~n"),
	receive
		{push_stone,Stone} -> ok
	after
		1000 -> hehe
	end.

pause(Game) ->
    io:format("game pause!~n").

end_negotiate(Game) ->
    io:format("game end-negotiate!~n").

terminated(Game) ->
    io:format("game terminate!~n").
