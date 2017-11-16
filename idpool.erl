-module(idpool).
-compile(export_all).
-behaviour(gen_server).

%%
%% Client Functions
%%
start_link() ->
    start_link(10).

start_link(NumMax) ->
    gen_server:start_link({local,?MODULE},?MODULE,NumMax,[]).

get_num() ->
    gen_server:call(?MODULE,get_num).

now_nums() ->
    gen_server:call(?MODULE,now_nums).

put_num(Num) ->
    gen_server:cast(?MODULE,{put_num,Num}).

stop() ->
    gen_server:call(?MODULE,stop).

%%
%% Callback Functions
%%
init(NumMax) -> 
    {ok,{NumMax,lists:seq(1,NumMax)}}.

handle_call(get_num,_From,{NumMax,Nums}) ->
    [Num|TailNums] = Nums,
    {reply,Num,{NumMax,TailNums}};

handle_call(now_nums,_From,{NumMax,Nums}) ->
    {reply,Nums,{NumMax,Nums}};

handle_call(stop,_From,{NumMax,Nums}) ->
    {stop,normal,stopped,{NumMax,Nums}}.

handle_cast({put_num,Num},{NumMax,Nums}) ->
    {noreply,{NumMax,[Num|Nums]}}.

terminate(Reason,{NumMax,Nums}) ->
    ok.
