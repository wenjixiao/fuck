% color
-define(BLACK,1).
-define(WHITE,0).
% levels
-define(LevelK,"k").
-define(LevelD,"d").
-define(LevelP,"p").
% win types
-define(MID_WIN,0).
-define(COUNT_WIN,1).
-define(TIME_WIN,2).
-define(BROKEN_WIN,3).
% domain entitys
-record(loc,{x,y}).
-record(stone,{color,loc,seq}).
-record(counting,{countdown,times_retent,seconds_per_time}).
-record(time,{seconds,counting}).
-record(rule,{handicap=0,komi=6.5,time}).
-record(result,{hase_winner,winner_color,win_type,howmuch}).
-record(wait_condition,{level_diff,
							min_seconds,mas_seconds,
							min_countdown,max_countdown,
							min_times_retent,max_times_retent,
							min_seconds_per_time,max_seconds_per_time}).
-record(invite_condition,{level_diff,time}).
-record(player,{id,level,is_playing,is_accept_invite,wait_condition}).

-record(proxy_info,{proxy_pid,player_id,player}).
-record(game_info,{game_pid,game_id}).

-record(server_msg,{msg}).
-record(game_msg,{game_id,msg}).
