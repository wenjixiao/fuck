-module(game).

-include("planet.hrl").

-export([start/2]).

-record(state,{id,last_color,rule,playing_proxys,times,watching_proxys=[],stones=[],result}).

start(ProxyInfo1,ProxyInfo2) ->
	State = #state{id=idpool:get_num(),playing_proxys=[ProxyInfo1,ProxyInfo2]},
	created(State).

created(State) ->
    io:format("game begin-negotiate!~n").

running(State) ->
    io:format("game playing!~n"),
	receive
		{push_stone,Stone} -> ok
	after
		1000 -> hehe
	end.

paused(State) ->
    io:format("game pause!~n").

ended(State) ->
    io:format("game end-negotiate!~n").
