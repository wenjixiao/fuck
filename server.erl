-module(server).
-record(player,{player_id,level}).
-record(client_proxy,{pid,player_id,player}).
-record(state,{client_proxys,games}).
-compile(export_all).

start() ->
    loop(#state{client_proxys=[],games=[]}).

loop(State) ->
	receive
		{ClientProxy,{login,PlayerId,Password}} ->
			io:format("{~p,~p} login!~n",[PlayerId,Password]),
			case lists:keytake(PlayerId,2,State#state.client_proxys) of
				% player's line broken
				{value,Tuple,TupleList2} -> 
					NewTuple = Tuple#client_proxy{pid=From},
					loop(State#state{client_proxys=[NewTuple|TupleList2]});
				% player not login now
				false ->
					case get_player(PlayerId) of
						{value,Player} ->
		    				ClientProxy1 = ClientProxy#client_proxy{player_id=PlayerId,player=Player},
							NewState = State#state{client_proxys=[ClientProxy1|State#state.client_proxys]},
							client_proxy:send(From,{login_return,value,Player}),
							loop(NewState);
						false ->
							io:format("exception: ~p~n",[PlayerId]),
							Reason = "player_id error or password error!",
							client_proxy:send(From,{login_return,false,Reason}),
							loop(State)
					end
			end;
		{ClientProxy,{invite,TargetPlayerId}} ->
			case lists:keyfind(TargetPlayerId,2,State#state.client_proxys) of
				ClientProxy1 -> 
					% todo?
					% game:start(ClientProxy,ClientProxy1);
				false -> ok
			end,
			loop(State);
        Msg -> 
            io:format("planet ~p: ~p~n",[self(),Msg]),
            loop(State)
    end.

get_player(Name) ->
	case Name of
		wenjixiao ->
			{value,#player{player_id=wenjixiao,level='3d'}};
		zhongzhong ->
			{value,#player{player_id=zhongzhong,level='1d'}};
		Other ->
			false
	end.