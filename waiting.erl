-module(waiting).
-compile(export_all).

start() ->
    listen(8787).

listen(Port) ->
    ServerPid = spawn(server,start,[]),
    {ok,ListenSocket} = gen_tcp:listen(Port,[binary, {packet,4}, {active,true}, {nodelay,true}, {reuseaddr,true}]),
    wait_connect(ListenSocket,ServerPid).

wait_connect(ListenSocket,ServerPid) ->
    {ok,Socket} = gen_tcp:accept(ListenSocket),
    % continue wait
    spawn(?MODULE,wait_connect,[ListenSocket,ServerPid]),
    % run client_proxy
    client_proxy:start(Socket,ServerPid).

