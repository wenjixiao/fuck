-module(client_proxy).

-record(state,{socket,server_pid,playing_games=[],watching_games=[]}).

send(Msg) -> self() ! {send,Msg}.
close(Pid) -> self() ! close.

start(Socket,ServerPid) -> 
	loop(#state{socket=Socket,server_pid=ServerPid}).
	
loop(State) ->
	receive
        {tcp,Socket,Bin} -> 
            Msg = binary_to_term(Bin),
            io:format("mm ~p: socket->: ~p~n",[self(),Msg]),
            loop(State);
        {tcp_closed,Socket} -> 
            io:format("mm ~p: socket->: tcp_closed~n",[self()]),
        close -> 
            io:format("mm ~p: #close# make gen_tcp:close~n",[self()]),
            gen_tcp:close(State#state.socket);
        {send,Msg} -> 
            io:format("mm ~p: ->socket: ~p~n",[self(),Msg]),
            gen_tcp:send(State#state.socket,term_to_binary(Msg)),
            loop(State);
	end.
