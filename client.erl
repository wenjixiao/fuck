-module(client).
-record(player,{name,level}).
-record(state,{frame,panel,player}).
-compile(export_all).
-define(mylogin_bt,101).
-define(myinvite_bt,102).
-include_lib("wx/include/wx.hrl").

send(Msg) -> self() ! {send,Msg}.
close(Pid) -> self() ! close.

start() ->
    wx:new(),
    Frame = wxFrame:new(wx:null(),?wxID_ANY,"my gui"),
    Panel = setup(Frame),
    wxFrame:show(Frame),
    loop(#state{frame=Frame,panel=Panel}),
    wx:destroy(),
    ok.

setup(Frame) ->
    Panel = wxPanel:new(Frame,[]),
    MainSizer = wxBoxSizer:new(?wxVERTICAL),
    LoginBt = wxButton:new(Panel,?mylogin_bt,[{label,"login"}]),
    InviteBt = wxButton:new(Panel,?myinvite_bt,[{label,"invite"}]),
    wxSizer:add(MainSizer,LoginBt,[{proportion, 0}, {flag, ?wxEXPAND}]),
    wxSizer:add(MainSizer,InviteBt,[{proportion, 0}, {flag, ?wxEXPAND}]),
    wxPanel:setSizer(Panel,MainSizer),
    wxButton:connect(InviteBt,command_button_clicked),
	wxButton:connect(LoginBt,command_button_clicked),
	wxFrame:connect(Frame,close_window),
    Panel.

loop(State) ->
    receive
    	#wx{id=?myinvite_bt,event=#wxCommand{}} ->
            % mm:send(State#state.mm_pid,{invite,catcat}),
            % Dialog = wxMessageDialog:new(State#state.panel,"i am a message of dialog!",
            %     %?wxICON_QUESTION
            %     [{caption,"hehe"},{style,?wxYES_NO}]),
            % B = wxDialog:show(Dialog),
            % io:format("wxdialog ~p~n",[B]),
            case wxDialog:showModal(Dialog) of
               ?wxID_YES -> io:format("okok!~n");
               ?wxID_NO -> io:format("nono!~n")
            end,
    		loop(State);
        #wx{id=?mylogin_bt,event=#wxCommand{}} ->
            io:format("login now~n"),
            PlayerPid=wenjixiao,Password=123456,
            send({login,PlayerPid,Password}),
            loop(State);
    	#wx{event=#wxClose{}} ->
		    io:format("close window~n"),
            close(),
            wxFrame:destroy(State#state.frame),
            ok;
        {tcp,Socket,Bin} -> 
            Msg = binary_to_term(Bin),
            io:format("mm ~p: socket->: ~p~n",[self(),Msg]),
			case Msg of
				{login_return,value,Player} -> 
					loop(State#state{player=Player});
				{login_return,false,Reason} ->
					io:format("login error: ~p~n",[Reason]),
					loop(State) 
			end;
        {tcp_closed,Socket} -> 
            io:format("mm ~p: socket->: tcp_closed~n",[self()]),
        close -> 
            io:format("mm ~p: #close# make gen_tcp:close~n",[self()]),
            gen_tcp:close(State#state.socket);
        connect ->
			{Host,Port = '127.0.0.1',8787},
			case gen_tcp:connect(Host,Port,[binary,{packet,4},{active,true}]) of
				{ok,Socket} -> loop(State#state{socket=Socket});
				{error,Reason} -> 
					io:format("connect error: ~p~n",[Reason]);
					loop(State)
			end;
        {send,Msg} -> 
            io:format("mm ~p: ->socket: ~p~n",[self(),Msg]),
            gen_tcp:send(State#state.socket,term_to_binary(Msg)),
            loop(State)
    end.