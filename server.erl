-module(server).

-include("planet.hrl").

-compile(export_all).

-record(shadow_info,{shadow_pid,player_id}).
-record(state,{shadows,games}).

start() ->
    loop(#state{shadows=[],games=[]}).
                                                   
loop(State) ->
	receive
		{From,{login,PlayerId,Password}} ->
			io:format("{~p,~p} login!~n",[PlayerId,Password]),
			case lists:keytake(PlayerId,2,State#state.shadows) of
				% player's line broken
				{value,Tuple,TupleList2} -> 
					NewTuple = Tuple#shadow_info{shadow_pid=From},
					loop(State#state{shadows=[NewTuple|TupleList2]});
				% player not login now
				false ->
					case get_player(PlayerId) of
						{value,Player} ->
		    				ShadowInfo = #shadow_info{shadow_pid=From,player_id=Player#player.id},  
							NewState = State#state{shadows=[ShadowInfo|State#state.shadows]},
							shadow:send(From,{login_return,value,Player}),
							loop(NewState);
						false ->
							Reason = "player_id error or password error!",
							shadow:send(From,{login_return,false,Reason}),
							loop(State)
					end
			end;
		{From,{invite,PlayerId}} ->
			case lists:keyfind(PlayerId,2,State#state.shadows) of
				#shadow_info{shadow_pid=ShadowPid} -> 
					game:start(From,ShadowPid);
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