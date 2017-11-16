-module(waiting).

-compile(export_all).

start() ->
    listen(8787).

listen(Port) ->
    ServerPid = spawn(server,start,[]),
    ListenOptions = [binary, {packet,4}, {active,true}, {nodelay,true}],
    case gen_tcp:listen(Port,ListenOptions) of
    	{ok,ListenSocket} -> wait_connect(ListenSocket,ServerPid);
    	{error,Reason} -> io:format("socket listen error:~p~n",[Reason])
    end.

wait_connect(ListenSocket,ServerPid) ->
	io:format("begin listening...~n"),
    {ok,Socket} = gen_tcp:accept(ListenSocket),
    % continue wait
    spawn(?MODULE,wait_connect,[ListenSocket,ServerPid]),
    % run client_proxy
    shadow:start(Socket,ServerPid).

