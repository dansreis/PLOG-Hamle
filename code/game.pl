:- use_module(library(clpfd)).
:- use_module(library(lists)).

defaultGame:- 
	getLabelingType(Type),
	defaultInfoList(Info),
	setUpBoard(Info, 6, Board),
	displayBoard(Board),
	getEnter,
	solution(Type, Info, 26, 6, Result),
	setUpBoard(Result, 6, FinalBoard),
	displayBoard(FinalBoard).

newGame:- 
	getBoardSize(Size),getLabelingType(Type),
	generateBoard(Size,Size,EmptyReferenceBoard),
	NumberBlacks is Size,
	deployBlacks(EmptyReferenceBoard, Size, NumberBlacks, BoardWithBlacks),
	generateBoard(Size, Size, InitialBoard),
	moveBlacks(1, 1, BoardWithBlacks, InitialBoard, Size, Board),
	displayBoard(Board),
	getEnter,
	NumberWhites is Size*Size - NumberBlacks,
	flattenBoard(Board, [], BoardList),
	solution(Type, BoardList, NumberWhites, Size, Result),
	setUpBoard(Result, Size, FinalBoard),
	displayBoard(FinalBoard).


%-------------------------------------%
%-----------MOVE VALIDATION-----------%
%-------------------------------------%

getBlackCells([], []).
getBlackCells([0 | Tail], Blacklist):-
	getBlackCells(Tail, Blacklist).
getBlackCells([Head | Tail], [Head | Blacklist]):-
	getBlackCells(Tail, Blacklist).


%------------------------------------%
%--------------SOLUTION--------------%
%------------------------------------%
solution(1, Values, NumberWhites, N, Result):-
	length(Values, Length),
	length(Result, Length),
	Max #= N - 1,
	setUpBoard(Result, N, ResultBoard),
	domain(Result, 0, Max),

	restrictMovements(Values,NumberWhites,N,Result),
	blacksNotAdjacent(ResultBoard),
	%whiteInterconnection(ResultBoard, NumberWhites, N),

	%print(Result),nl,
	reset_timer,
	labeling([], Result),
	print_time,
	fd_statistics.

solution(2, Values, NumberWhites, N, Result):-
	length(Values, Length),
	length(Result, Length),
	Max #= N - 1,
	setUpBoard(Result, N, ResultBoard),
	domain(Result, 0, Max),

	restrictMovements(Values,NumberWhites,N,Result),
	blacksNotAdjacent(ResultBoard),
	%whiteInterconnection(ResultBoard, NumberWhites, N),

	%print(Result),nl,
	reset_timer,
	labeling([ffc], Result),
	print_time,
	fd_statistics.



%------------------------------------%
%------------RESTRICTIONS------------%
%------------------------------------%


%*************************************%
%*****BLACKS ADJACENCY CONSTRAIN******%
%*************************************%
blacksNotAdjacent(ResultBoard):-
	transpose(ResultBoard, TResultBoard),
	checkAdjacentCells(TResultBoard),
	checkAdjacentCells(ResultBoard).

checkAdjacentCells([]).
checkAdjacentCells([Head | Tail]):-
	checkAdjacentCellsLine(Head),
	checkAdjacentCells(Tail).


checkAdjacentCellsLine([_ | []]).
checkAdjacentCellsLine([First, Second | Tail]):-
	First #>0 #=> Second #= 0,
	checkAdjacentCellsLine([Second | Tail]).
checkAdjacentCellsLine([_ | Tail]):-
	checkAdjacentCellsLine(Tail).


%***************************************%
%******BLACKS MOVEMENTS CONSTRAIN*******%
%***************************************%

createTuples(0,[]).

createTuples(NumberBlacks,[L|ListTuples]):- 
	NumberBlacks> 0, 
	N1 #= NumberBlacks - 1, 
	length(L,1),
	createTuples(N1,ListTuples).

checkIfRight(Index-Value,N,[Dest]):-
	OriginalFloor is floor((Index-1) / N),
	Dest #= (Index + Value),
	DestFloor is floor((Dest-1) / N),
	DestFloor = OriginalFloor.
checkIfRight(_,_,[]).

checkIfLeft(Index-Value,N,[Dest]):-
	OriginalFloor is floor((Index-1) / N),
	Dest #= (Index - Value),
	DestFloor is floor((Dest-1)/N),
	DestFloor = OriginalFloor.
checkIfLeft(_,_,[]).

checkIfUp(Index-Value,N,[Dest]):-
	Dest is (Index - Value*N),
	Dest >= 1.		
checkIfUp(_,_,[]).

checkIfDown(Index-Value,N,[Dest]):-
	Dest is (Index + Value*N),
	Dest =< (N*N).
checkIfDown(_,_,[]).

tablingTuples([],[],_).

tablingTuples([Tuple|ListTuples],[Piece|ListBlacks],N):-
	checkIfRight(Piece,N,Dest1),
	checkIfLeft(Piece,N,Dest2),
	checkIfUp(Piece,N,Dest3),
	checkIfDown(Piece,N,Dest4),
	table([[Tuple]],[Dest1,Dest2,Dest3,Dest4]),
	tablingTuples(ListTuples,ListBlacks,N).

putPiecesInBoard([],[],_).				
putPiecesInBoard([Tuple|ListTuples],[_-Value | ListBlacks],Result):-
	element(Tuple,Result,Value),
	putPiecesInBoard(ListTuples, ListBlacks ,Result).

restrictMovements(Board,NumberWhites,N,Result):-
	NumberBlacks #= (N*N)-NumberWhites,
	length(ListTuples,NumberBlacks),
	findall(Index-Value,(nth1(Index,Board,Value),Value>0),ListBlacks),
	tablingTuples(ListTuples,ListBlacks,N),
	all_different(ListTuples),
	putPiecesInBoard(ListTuples,ListBlacks,Result).



%***************************************%
%*******WHITE INTERCONNECTION***********%
%***************************************%
whiteInterconnection([RHead | RTail], NumberWhites, N):-
	generateBoard(N, N, RegisterBoard),
	findFirstWhite(1, RHead, Col),
	floodWhites(1, Col, [RHead | RTail], RegisterBoard, _, NumberWhites).

findFirstWhite(Col, [Head | _], Col):-
	Head #= 0.
findFirstWhite(Col, [_ | RTail], FinalCol):-
	NextCol is Col + 1,
	findFirstWhite(NextCol, RTail, FinalCol).

floodWhites(Row, Col, ResultBoard, RegisterBoard, FinalRegisterBoard, ConnectedWhites):-
	Value #= 0,
	getPosition(Row, Col, Value, ResultBoard),
	getPosition(Row, Col, 0, RegisterBoard),
	setPosition(Row, Col, 1, RegisterBoard, R1),
	NextRow is Row + 1,
	PrevRow is Row - 1,
	NextCol is Col + 1,
	PrevCol is Col - 1,
	floodWhites(NextRow, Col, ResultBoard, R1, R2, W1),
	floodWhites(PrevRow, Col, ResultBoard, R2, R3, W2),
	floodWhites(Row, NextCol, ResultBoard, R3, R4, W3),
	floodWhites(Row, PrevCol, ResultBoard, R4, FinalRegisterBoard, W4),
	ConnectedWhites #= 1 + W1 + W2 + W3 + W4.
floodWhites(_,_,_,R,R,0).