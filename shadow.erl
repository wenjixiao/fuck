-module(shadow).

-compile(export_all).

-record(game_info,{game_id,game_pid}).
-record(state,{socket,player,server_pid,playing_game_infos=[],watching_game_infos=[]}).

-record(server_msg,{msg}).
-record(game_msg,{game_id,msg}).

send(Pid,Msg) -> Pid ! {send,Msg}.
close(Pid) -> Pid ! close.

start(Socket,ServerPid) -> 
	loop(#state{socket=Socket,server_pid=ServerPid}).
	
loop(State) ->
	receive
        {tcp,Socket,Bin} -> 
            case binary_to_term(Bin) of
            	#server_msg{msg=Msg} -> 
            		State#state.server_pid ! {self(),Msg};
            	#game_msg{game_id=GameId,msg=Msg} ->
            		game_infos = State#state.playing_game_infos ++ State#state.watching_game_infos,
					case lists:keyfind(GameId,1,game_infos) of
						#game_info{game_pid=GamePid} -> 
							GamePid ! {self(),Msg};
						false -> throw("can't find game id!")
					end
			end,
            io:format("client_proxy ~p: socket->: ~p~n",[self(),Msg]),
            loop(State);
        {tcp_closed,Socket} -> 
            io:format("client_proxy ~p: socket->: tcp_closed~n",[self()]);
        close ->
        	gen_tcp:close(State#state.socket);
        {send,Msg} -> 
            io:format("client_proxy ~p: ->socket: ~p~n",[self(),Msg]),
            gen_tcp:send(State#state.socket,term_to_binary(Msg)),
            loop(State)
	end.
