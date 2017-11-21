-module(server).

-include("planet.hrl").

-export([start/0,mount/1,range/2]).

-record(state,{proxy_infos,broken_proxy_infos,game_infos}).

start() ->
	% proxys contains proxy_infos
    loop(#state{proxy_infos=[],broken_proxy_infos=[],game_infos=[]}).

%% 把level量化，以便计算 
%% 18k->...->1k->1d->...->9d->1p->...->9p
mount(Level) ->
	{NumStr,SuffixStr} = lists:split(length(Level)-1,Level),
	Num = list_to_integer(NumStr),
	LevelMinK = 18, LevelMaxD = 9,
	case SuffixStr of
		?LevelK -> LevelMinK - Num + 1;
		?LevelD -> LevelMinK + Num;
		?LevelP -> LevelMinK + LevelMaxD + Num
	end.

%% 对局条件一般是等级差距大概是多少，然后确定对方等级是否在范围内
range(Level,Diff) ->
	Mount = mount(Level),
	MinMount = Mount - Diff, MaxMount = Mount + Diff,
	MinMount1 = if MinMount < 1 -> 1; MinMount >= 1 -> MinMount end,
	MaxMount1 = if MaxMount > 36 -> 36; MaxMount =< 36 -> MaxMount end,
	{MinMount1,MaxMount1}.

make_rule(Player1,Player2,InviteCondition) ->
	DeltaLevel = abs(mount(Player1#player.level) - mount(Player2#player.level)),
	Rule = #rule{handicap = DeltaLevel},
	Komi = if DeltaLevel == 0 -> 6.5; DeltaLevel =/= 0 -> DeltaLevel end,
	Rule#rule{komi = Komi,time=InviteCondition#invite_condition.time}.
                                                   
loop(State) ->
	receive
		{ProxyInfo,{login,PlayerId,Password}} ->
			io:format("{~p,~p} login!~n",[PlayerId,Password]),
			case lists:keytake(PlayerId,2,State#state.broken_proxy_infos) of
				% relogin, because of player's line broken
				{value,Tuple,TupleList2} -> 
					NewTuple = Tuple#proxy_info{proxy_pid=ProxyInfo#proxy_info.proxy_pid},
					loop(State#state{proxy_infos=[NewTuple|TupleList2],broken_proxy_infos=TupleList2});
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
		{ProxyInfo,connbroken} ->
			case lists:keytake(ProxyInfo#proxy_info.player_id,2,State#state.proxy_infos) of
				{value,Tuple,TupleList2} -> 
					loop(State#state{proxy_infos=TupleList2,broken_proxy_infos=[Tuple|State#state.broken_proxy_infos]});
				false -> throw("impossible")
			end;
		{ProxyInfo,{invite,PlayerId,InviteCondition}} ->
			Rule = #rule{}, %make_rule(),
			case lists:keyfind(PlayerId,2,State#state.proxy_infos) of
				ProxyInfo1 ->
					Rule = make_rule(ProxyInfo#proxy_info.player,ProxyInfo1#proxy_info.player,InviteCondition),	
					game:start(ProxyInfo,ProxyInfo1,Rule);
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