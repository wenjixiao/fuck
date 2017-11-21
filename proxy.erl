-module(proxy).

-include("planet.hrl").

-export([start/2,send/2,close/1]).

-record(state,{socket,player,server_pid,game_infos=[]}).

send(Pid,Msg) -> Pid ! {send,Msg}.
close(Pid) -> Pid ! close.

start(Socket,ServerPid) -> 
	loop(#state{socket=Socket,server_pid=ServerPid}).
	
loop(State) ->
	receive
        {tcp,Socket,Bin} ->
        	ProxyInfo = #proxy_info{proxy_pid=self(),State#state.player},
            case binary_to_term(Bin) of
            	#server_msg{msg=Msg} -> 
            		State#state.server_pid ! {ProxyInfo,Msg};
            	#game_msg{game_id=GameId,msg=Msg} ->
					case lists:keyfind(GameId,2,State#state.game_infos) of
						#game_info{game_pid=GamePid} -> 
							GamePid ! {ProxyInfo,Msg};
						false -> throw("can't find game id!")
					end
			end,
            loop(State);
        {tcp_closed,Socket} -> 
        	ProxyInfo = #proxy_info{proxy_pid=self(),State#state.player},
        	% tell server
        	State#state.server_pid ! {ProxyInfo,connbroken},
        	% tell every game
        	lists:foreach(
        		fun(GameInfo) -> 
        			GameInfo#game_info.game_pid ! {ProxyInfo,connbroken} 
        		end,
        		State#state.game_infos);
        close ->
        	gen_tcp:close(State#state.socket);
        {send,Msg} -> 
            NewState = case Msg of
							#server_msg{msg={login_return,value,Player}} -> State#state{player=Player};
							Other -> State 
						end,
            gen_tcp:send(State#state.socket,term_to_binary(Msg)),
            loop(NewState)
	end.
