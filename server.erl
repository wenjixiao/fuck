-module(server).

-include("planet.hrl").

-export([start/0]).

-record(state,{proxy_infos,game_infos}).

start() ->
	% proxys contains proxy_infos
    loop(#state{proxy_infos=[],game_infos=[]}).
                                                   
loop(State) ->
	receive
		{ProxyInfo,{login,PlayerId,Password}} ->
			io:format("{~p,~p} login!~n",[PlayerId,Password]),
			case lists:keytake(PlayerId,2,State#state.proxy_infos) of
				% player's line broken
				{value,Tuple,TupleList2} -> 
					NewTuple = Tuple#proxy_info{proxy_pid=ProxyInfo#proxy_info.proxy_pid},
					loop(State#state{proxy_infos=[NewTuple|TupleList2]});
				% player not login now
				false ->
					case get_player(PlayerId) of
						{value,Player} ->
		    				ProxyInfo = ProxyInfo#proxy_info{player_id=Player#player.id,player=Player},  
							NewState = State#state{proxy_infos=[ProxyInfo|State#state.proxy_infos]},
							proxy:send(ProxyInfo#proxy_info.proxy_pid,#server_msg{msg={login_return,value,Player}}),
							loop(NewState);
						false ->
							Reason = "player_id error or password error!",
							proxy:send(ProxyInfo#proxy_info.proxy_pid,#server_msg{msg={login_return,false,Reason}}),
							loop(State)
					end
			end;
		{ProxyInfo,{invite,PlayerId}} ->
			case lists:keyfind(PlayerId,2,State#state.proxy_infos) of
				ProxyInfo1 -> game:start(ProxyInfo,ProxyInfo1);
				false -> ok
			end,
			loop(State);
        Other -> 
            io:format("planet msg other ~p: ~p~n",[self(),Other]),
            loop(State)
    end.

get_player(Name) ->
	case Name of
		wenjixiao ->
			{value,#player{id=wenjixiao,level='3d'}};
		zhongzhong ->
			{value,#player{id=zhongzhong,level='1d'}};
		Other ->
			false
	end.