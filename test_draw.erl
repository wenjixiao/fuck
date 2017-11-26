-module(test_draw).
-include_lib("wx/include/wx.hrl").
-include("planet.hrl").
-export([start/0]).
-record(state,{frame,win,stones=[]}).

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
    		% io:format("x=~p,y=~p~n",[X,Y]),
    		{Unit,HalfUnit,_,OffsetX,OffsetY,_,_} = compute_size(State#state.win),
    		Cc = Unit+1,LeftCC = Cc div 4,RightCC = Cc - LeftCC,
    		Jx = X-OffsetX-HalfUnit+Unit,Jy = Y-OffsetY-HalfUnit+Unit, 
    		Nx = Jx div Cc,Rx = Jx rem Cc, 
    		Ny = Jy div Cc,Ry = Jy rem Cc,
    		IsNear = fun(Shang,Yu)->  if Yu < LeftCC -> Shang; Yu > RightCC -> Shang+1; true -> -1 end end,
    		MyX = IsNear(Nx,Rx), MyY = IsNear(Ny,Ry),
    		% io:format("nx=~p,rx=~p,ny=~p,ry=~p~n",[Nx,Rx,Ny,Ry]),
    		if
    			(MyX > 0) and (MyY > 0) ->
    				% do things here
    				Stones = State#state.stones, 
    				Color = case Stones of
    							[] -> ?BLACK;
    							% not empty
    							Other -> 
    								LastStone = lists:last(Other),
    								case LastStone#stone.color of
    									?BLACK -> ?WHITE;
    									?WHITE -> ?BLACK
    								end
    						end,
    				NewStones = Stones ++ [#stone{color=Color,point={MyX,MyY}}],
    				io:format("{~p,~p}~n",[MyX,MyY]),
    				NewState = State#state{stones=NewStones},
    				redraw(NewState),
    				loop(NewState);
    			true -> loop(State)
			end;
    		%loop(State);
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
	
draw_board(DC,State=#state{win=Win}) ->
	% basic size compute
	{Unit,_,R,_,_,Fx,Fy} = compute_size(Win),
	% pen,brush,...
    Pen = wxPen:new({0,0,0}, [{width, 1}]),
    % Font = wxFont:new(10, ?wxSWISS, ?wxNORMAL, ?wxNORMAL,[]),
    wxDC:setPen(DC,Pen),
    % wxDC:setFont(DC,Font),
    % draw lines 19*19
    lists:foreach(
    	fun(N)->
    		X = Fx(N),Y1 = Fy(1),Y2 = Fy(19), wxDC:drawLine(DC,{X,Y1},{X,Y2}),
    		Y = Fy(N),X1 = Fx(1),X2 = Fx(19), wxDC:drawLine(DC,{X1,Y},{X2,Y})
    	end,
    	lists:seq(1,19)),
    % draw stars
    wxDC:setBrush(DC, ?wxRED_BRUSH),
    StarXY = [4,10,16],
    lists:foreach(
		fun({StarX,StarY})-> wxDC:drawCircle(DC,{Fx(StarX),Fy(StarY)},R) end,
		[{StarX,StarY} || StarX <- StarXY,StarY <- StarXY]),
	% draw stones
	DrawStone = fun(Stone)->
					StoneR = Unit div 2,
					{X,Y} = Stone#stone.point,Color = Stone#stone.color,
					% io:format("mycolor=~p~n",[Color]),
					ColorBrush = case Color of ?BLACK -> ?wxBLACK_BRUSH; ?WHITE -> ?wxWHITE_BRUSH end,
					wxDC:setBrush(DC, ColorBrush),
					wxDC:drawCircle(DC,{Fx(X),Fy(Y)},StoneR)
				end,
	lists:foreach(DrawStone,State#state.stones),
	ok.
	
		
