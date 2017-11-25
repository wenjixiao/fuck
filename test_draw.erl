-module(test_draw).
-include_lib("wx/include/wx.hrl").
-export([start/0]).
-record(state,{frame,win}).

start() ->
    wx:new(),
    Frame = wxFrame:new(wx:null(),?wxID_ANY,"***my drawing***",[{size,{600,600}}]),
    Win = wxPanel:new(Frame,[]),
    wxWindow:connect(Win, size),
    wxWindow:connect(Win, paint),
    wxWindow:connect(Win,left_down),
	wxFrame:connect(Frame,close_window),
    wxFrame:show(Frame),
    loop(#state{frame=Frame,win=Win}),
    wx:destroy().
    
loop(State) ->
    receive
    	#wx{event=#wxSize{}}  ->
    		redraw(State),
    		loop(State);
    	#wx{event=#wxPaint{}} ->
    		redraw(State),
    		loop(State);
    	#wx{event=#wxMouse{type=left_down,x=X,y=Y}} ->
    		io:format("x=~p,y=~p~n",[X,Y]),
    		{Unit,HalfUnit,_,OffsetX,OffsetY,_,_} = compute_size(State#state.win),
    		Cc = Unit+1,LeftCC = Cc div 4,RightCC = Cc - LeftCC,
    		Jx = X-OffsetX-HalfUnit+Unit,Jy = Y-OffsetY-HalfUnit+Unit, 
    		Nx = Jx / Cc,Rx = Jx rem Cc, 
    		Ny = Jy / Cc,Ry = Jy rem Cc,
    		MyX = if Rx < LeftCC -> Nx; Rx > RightCC -> Nx+1; _ -> ok end,
    		MyY = if Ry < LeftCC -> Ny; Ry > RightCC -> Ny+1; _ -> ok end,
    		io:format("nx=~p,rx=~p,ny=~p,ry=~p~n",[Nx,Rx,Ny,Ry]),
    		io:format("myx=~p,myy=~p~n",[MyX,MyY]),
    		loop(State);
    	#wx{event=#wxClose{}} ->
		    io:format("close window~n"),
            wxFrame:destroy(State#state.frame)
	end.
redraw(S = #state{win=Win}) ->
    DC0  = wxClientDC:new(Win),
    DC   = wxBufferedDC:new(DC0),
    redraw(DC,S),
    wxBufferedDC:destroy(DC),
    wxClientDC:destroy(DC0),
    ok.

redraw(DC,State) ->
	wxDC:setBackground(DC, ?wxWHITE_BRUSH),
	wxDC:clear(DC),
	draw_board(DC,State).
	
compute_size(Win) ->
	{W,H} = wxWindow:getSize(Win),
	Length = min(W,H),
	Unit = (Length - 19) div 19,
	HalfUnit = Unit div 2,
	% offset 应该包括高和宽分别
	OffsetX = (W - (Unit*19+19)) div 2,
	OffsetY = (H - (Unit*19+19)) div 2,
	% radius
	R = Unit div 8,
	% x,y坐标函数
    Fx = fun(N)-> HalfUnit+(N-1)*Unit+N+OffsetX end,
    Fy = fun(N) -> HalfUnit+(N-1)*Unit+N+OffsetY end,
    % io:format("length=~p,unit=~p,offset_x=~p,offset_y=~p~n",[Length,Unit,OffsetX,OffsetY]),
	{Unit,HalfUnit,R,OffsetX,OffsetY,Fx,Fy}.	
	
draw_board(DC,#state{win=Win}) ->
	{Unit,_,R,_,_,Fx,Fy} = compute_size(Win),	
    Pen = wxPen:new({0,0,0}, [{width, 1}]),
    % Font = wxFont:new(10, ?wxSWISS, ?wxNORMAL, ?wxNORMAL,[]),
    wxDC:setPen(DC,Pen),
    % wxDC:setFont(DC,Font),
    lists:foreach(
    	fun(N)->
    		X = Fx(N),Y1 = Fy(1),Y2 = Fy(19),
    		wxDC:drawLine(DC,{X,Y1},{X,Y2}),
    		Y = Fy(N),X1 = Fx(1),X2 = Fx(19),
    		wxDC:drawLine(DC,{X1,Y},{X2,Y})
    	end,
    	lists:seq(1,19)),
    % draw stars
    wxDC:setBrush(DC, ?wxRED_BRUSH),
    StarXY = [4,10,16],
    lists:foreach(
		fun({StarX,StarY})-> wxDC:drawCircle(DC,{Fx(StarX),Fy(StarY)},R) end,
		[{StarX,StarY} || StarX <- StarXY,StarY <- StarXY]).
