-module(server).

-include("planet.hrl").

-export([start/0,level_mount/1,level_range/2]).

-record(state,{proxy_infos,broken_proxy_infos,game_infos}).

start() ->
	% proxys contains proxy_infos
    loop(#state{proxy_infos=[],broken_proxy_infos=[],game_infos=[]}).

%% 把level量化，以便计算 
%% 18k->...->1k->1d->...->9d->1p->...->9p
level_mount(Level) ->
	{NumStr,SuffixStr} = lists:split(length(Level)-1,Level),
	Num = list_to_integer(NumStr),
	LevelMinK = 18, LevelMaxD = 9,
	case SuffixStr of
		?LevelK -> LevelMinK - Num + 1;
		?LevelD -> LevelMinK + Num;
		?LevelP -> LevelMinK + LevelMaxD + Num
	end.
	
%% 有交集吗？
has_intersection(Min1,Max1,Min2,Max2) -> not ((min1 > max2) or (max1 < min2)).

value_in_range(Value,Min,Max) -> (Value >= Min) and (Value =< Max).
	
%% 条件符合吗？ invite_condition and wait_condition
%% InviteCondition is from Player1
is_condition_match(InviteCondition,Player1,Player2) ->
	WaitCond = Player2#player.wait_condition,
	% level condition
	{Min1,Max1} = level_range(Player1#player.level,InviteCondition#invite_condition.level_diff),
	{Min2,Max2} = level_range(Player2#player.level,WaitCond#wait_condition.level_diff),
	LevelCond = has_intersection(Min1,Max1,Min2,Max2),
	% seconds condition
	Time = InviteCondition#invite_condition.time,
	SecondsCond = (Time#time.seconds >= WaitCond#wait_condition.min_seconds) and
				(Time#time.seconds =< WaitCond#wait_condition.max_seconds),
	% time condition
	Counting = Time#time.counting,
	% counting condition
	CountdownCond = value_in_range(Counting#counting.countdown,
		WaitCond#wait_condition.min_countdown,WaitCond#wait_condition.max_countdown),
	TimesRetentCond = value_in_range(Counting#counting.times_retent,
		WaitCond#wait_condition.min_times_retent,WaitCond#wait_condition.max_times_retent),
	SecondsPerTimeCond = value_in_range(Counting#counting.seconds_per_time,
		WaitCond#wait_condition.min_seconds_per_time,WaitCond#wait_condition.max_seconds_per_time),
	% all together
	LevelCond and SecondsCond and CountdownCond and TimesRetentCond and SecondsPerTimeCond.

%% 对局条件一般是等级差距大概是多少，然后确定对方等级是否在范围内
level_range(Level,Diff) ->
	Mount = level_mount(Level),
	MinMount = Mount - Diff, MaxMount = Mount + Diff,
	MinMount1 = if MinMount < 1 -> 1; MinMount >= 1 -> MinMount end,
	MaxMount1 = if MaxMount > 36 -> 36; MaxMount =< 36 -> MaxMount end,
	{MinMount1,MaxMount1}.

make_rule(Player1,Player2,InviteCondition) ->
	DeltaLevel = abs(level_mount(Player1#player.level) - level_mount(Player2#player.level)),
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