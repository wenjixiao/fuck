-module(game).

-include("planet.hrl").

-export([start/3,maybe_swap/1]).

% ?BLACK -> 0,?WHITE->1
% 颜色和player_proxys的index有关，0->黑,1->白
-record(state,{id,current_color,rule,playing_proxys,times,watching_proxys=[],stones=[],result}).

maybe_swap([ProxyInfo1,ProxyInfo2]) ->
	R = rand:uniform(),
	if
		R > 0.5 -> [ProxyInfo2,ProxyInfo1];
		R =< 0.5 -> [ProxyInfo1,ProxyInfo2]
	end.
	
first_color(Handicap) ->
	if
		Handicap > 0 -> ?WHITE;
		Handicap =< 0 -> ?BLACK
	end.

start(ProxyInfo1,ProxyInfo2,Rule) ->
	State = #state{
				id=idpool:get_num(),
				current_color=first_color(Rule#rule.handicap),
				rule=Rule,
				playing_proxys=maybe_swap([ProxyInfo1,ProxyInfo2])
			},
	created(State).
	
created(State) ->
    io:format("game begin-negotiate!~n").
    
% push stone msg=> {game_msg,GameId,{push,Time,Stone}}
% {ProxyInfo,{push,Time,Stone}}
% 只有running状态可以下子
running(State) ->
    io:format("game playing!~n"),
	receive
		{push,Time,Stone} -> ok;
		tick -> ok
	end.

paused(State) ->
    io:format("game pause!~n").

ended(State) ->
    io:format("game end-negotiate!~n").
