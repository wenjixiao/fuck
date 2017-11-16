-module(game).

-include("planet.hrl").

start(ClientProxyPid1,ClientProxyPid2) ->
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
