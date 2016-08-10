set_agent_state(ToState):-
	retractall(agent_state(_)),
	asserta( agent_state(ToState) ).

needs_fuel:-
	player(agent,_,_,_,Fuel,Where ),
	place(FinishIndex,_,_,_,_,finish),
	moves_remaining(MRemaining),
	FReqd is min(abs(Where-FinishIndex), abs(64-Where+FinishIndex))+20,
	MReqd is floor(FReqd/8)+1,
	( FReqd > Fuel; MReqd > MRemaining ).

step_to_go_to( Dest, 0 ):-
	player(agent,_,_,_,_, Where ),
	Where = Dest.

step_to_go_to(Dest, MoveQuantity):-
	player(agent,_,_,_,_, Where ),
	Diff is ((Dest-Where+64) mod 64),
	Diff < 32,
	MoveQuantity is min(8, Diff).

step_to_go_to( Dest, MoveQuantity):-
	% Returns how many steps to move to go home
	player(agent,_,_,_,_, Where ),
	Diff is ((Dest-Where+64) mod 64),
	Diff >= 32,
	MoveQuantity is max(-8, Diff-64).

max_buy(MoveQuantity):-
	agent_choice(BestSeller, BestBuyer),
	place(BestSeller,_,Item,SQ,Price,seller),
	SQ>0,
	place(BestBuyer,_,Item,BQ,_,buyer),
	BQ>0,
	player(agent, WL, Cash, VL, _, _),
	item( Item, IW, IV),
	WLim is floor(WL/IW),
	VLim is floor(VL/IV),
	CLim is floor(Cash/Price),
	min_list([WLim,VLim, CLim],OurLim),
	min_list([floor(SQ), floor(BQ), floor(OurLim)], MoveQuantity).

max_sell( Buyer, MoveQuantity ):-
	% Sell everything you're holding
	place(Buyer, _,Item,_,_,_),
	holding(agent, Item, MoveQuantity1),
	MoveQuantity is floor(MoveQuantity1).

find_best_item(BestSeller, BestBuyer):-
% Finds dealers with best ratio of how much profit we obtain on buying and selling Q of the item to how much fuel is required to get it. Here Q is the minimum of how much the buyer wants, how much the seller can sell and how much we can buy based on how much cash, weight and volume we have.
	player(Player, Weight, Cash, Volume, Fuel, Where),
	writeln(player(Player, Weight, Cash, Volume, Fuel, Where)),
	findall(
		pppdiff(Place1,Place2,Ratio), % Just a name for the structure
		(
				place(Place1,_,Item,Quantity1,Price1,seller),
				place(Place2,_,Item,Quantity2,Price2,buyer),
				Quantity1>0,
				Quantity2>0,
				item( Item, IW, IV),
				WLim is floor(Weight/IW),
				VLim is floor(Volume/IV),
				CLim is floor(Cash/Price1),
				min_list([WLim,VLim, CLim],OurLim),
				min_list([floor(Quantity1),floor(Quantity2),floor(OurLim)], Quantity),
				PriceDiff is Quantity*(Price2 - Price1),
				FReqd is min(abs(Place1-Where), abs(64+Where-Place1))+min(abs(Place2-Place1), abs(64-Place2+Place1)),
				Ratio is PriceDiff/FReqd
		),
		PPList
	),
	writeln(PPList),
	find_max_pricediff( PPList, MaxPriceDiff),
	MaxPriceDiff = pppdiff(BestSeller, BestBuyer, _),
	place(BestSeller, _,_,_,Price, seller),
	writeln(Price).

find_max_pricediff( PPList, MaxPriceDiff):-
	% Returns the member of PPList having max PriceDiff
	% pppdiff( Place1, Place2, PriceDiff)
	findall( PDiff, member(pppdiff(_,_,PDiff), PPList) , PDList ),
	max_list(PDList, MaxPDiff),
	member( pppdiff(Place1, Place2, MaxPDiff ), PPList ),
	MaxPriceDiff = pppdiff(Place1,Place2, MaxPDiff).


find_min_fueldiff( PPList, MinFuelDiff):-
	% Returns the member of PPList having min FuelDiff
	% pppdiff( Place1, Place2, FuelDiff)
	findall( FDiff, member(pppdiff(_,_,FDiff), PPList), FDList ),
	min_list(FDList, MinFDiff),
	member( pppdiff(Place1, Place2, MinFDiff ), PPList ),
	MinFuelDiff = pppdiff(Place1,Place2, MinFDiff).