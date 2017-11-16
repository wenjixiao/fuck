-module(client).

-include_lib("wx/include/wx.hrl").

-define(mylogin_bt,101).
-define(myinvite_bt,102).
-define(myconnect_bt,103).

-compile(export_all).

-record(server_msg,{msg}).
-record(game_msg,{game_id,msg}).

-record(player,{name,level}).
-record(state,{frame,socket,player}).

send(Msg) -> self() ! {send,Msg}.
close() -> self() ! close.

start() ->
    wx:new(),
    Frame = wxFrame:new(wx:null(),?wxID_ANY,"my gui"),
    Panel = setup(Frame),
    wxFrame:show(Frame),
    loop(#state{frame=Frame}),
    wx:destroy().

setup(Frame) ->
    Panel = wxPanel:new(Frame,[]),
    MainSizer = wxBoxSizer:new(?wxVERTICAL),
    ConnectBt = wxButton:new(Panel,?myconnect_bt,[{label,"connect"}]),
    LoginBt = wxButton:new(Panel,?mylogin_bt,[{label,"login"}]),
    InviteBt = wxButton:new(Panel,?myinvite_bt,[{label,"invite"}]),
    wxSizer:add(MainSizer,ConnectBt,[{proportion, 0}, {flag, ?wxEXPAND}]),
    wxSizer:add(MainSizer,LoginBt,[{proportion, 0}, {flag, ?wxEXPAND}]),
    wxSizer:add(MainSizer,InviteBt,[{proportion, 0}, {flag, ?wxEXPAND}]),
    wxPanel:setSizer(Panel,MainSizer),
    wxButton:connect(ConnectBt,command_button_clicked),
    wxButton:connect(InviteBt,command_button_clicked),
	wxButton:connect(LoginBt,command_button_clicked),
	wxFrame:connect(Frame,close_window).

loop(State) ->
    receive
    	#wx{id=?myinvite_bt,event=#wxCommand{}} ->
            % mm:send(State#state.mm_pid,{invite,catcat}),
            % Dialog = wxMessageDialog:new(State#state.panel,"i am a message of dialog!",
            %     %?wxICON_QUESTION
            %     [{caption,"hehe"},{style,?wxYES_NO}]),
            % B = wxDialog:show(Dialog),
            % io:format("wxdialog ~p~n",[B]),
            % case wxDialog:showModal(Dialog) of
            %   ?wxID_YES -> io:format("okok!~n");
            %   ?wxID_NO -> io:format("nono!~n")
            % end,
    		loop(State);
        #wx{id=?mylogin_bt,event=#wxCommand{}} ->
            io:format("login now~n"),
            PlayerPid=wenjixiao,Password=123456,
            send(#server_msg{msg={login,PlayerPid,Password}}),
            loop(State);
        #wx{id=?myconnect_bt,event=#wxCommand{}} ->
			{Host,Port} = {'127.0.0.1',8787},
			case gen_tcp:connect(Host,Port,[binary,{packet,4},{active,true}]) of
				{ok,Socket} ->
					io:format("connect ok~n"),
					loop(State#state{socket=Socket});
				{error,Reason} -> 
					io:format("connect error: ~p~n",[Reason]),
					loop(State)
			end;
    	#wx{event=#wxClose{}} ->
		    io:format("close window~n"),
		    gen_tcp:shutdown(State#state.socket,read_write),
            gen_tcp:close(State#state.socket),
            wxFrame:destroy(State#state.frame);
        {tcp,Socket,Bin} -> 
            Msg = binary_to_term(Bin),
            io:format("client ~p: socket->: ~p~n",[self(),Msg]),
			case Msg of
				{login_return,value,Player} -> 
					loop(State#state{player=Player});
				{login_return,false,Reason} ->
					io:format("login error: ~p~n",[Reason]),
					loop(State) 
			end;
        {tcp_closed,Socket} -> 
            io:format("client ~p: socket->: tcp_closed~n",[self()]);
        {send,Msg} -> 
            io:format("client ~p: ->socket: ~p~n",[self(),Msg]),
            case gen_tcp:send(State#state.socket,term_to_binary(Msg)) of
            	ok -> loop(State);
            	{error,Reason} -> io:format("msg send error!~n")
            end
    end.
