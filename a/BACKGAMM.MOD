MODULE Backgammon; 


(* Backgammon by: Craig Fitzgerald *)


(* IMPORT DebugTrace; *)
FROM RTSMain IMPORT Terminate,Status;
FROM Break   IMPORT InstallBreak,EnableBreak;
FROM Windows IMPORT PushWindow,PopWindow,StartWindowDef,
                    DefineWindow,Border,Window,KillWindow;
FROM Screen IMPORT PrintLn,SetAttrib,Cls,DrawToScreen,LookAtScreen;
IMPORT Screen;
FROM Heuristics IMPORT CalculateBoardValue;
FROM SimpleTerm IMPORT Read,WriteLn,KeyPressed;
FROM BIOSScreen IMPORT GoTo,SetScreenToScroll,ScrollUp,CLS,CopyChar,
                       HTab,XPos,BorderColor,CursorAt;
FROM Random IMPORT RandomCard,Randomize;
FROM Types IMPORT DiceRec,BoardType;
FROM Keys  IMPORT ReadKey, Key;
FROM Parse IMPORT ParseMove;
CONST
   CommandSize = 7;
   CommandCount =11;
VAR
   Ch,
   CColor,   PColor,   MColor,
   EColor,   BColor,   BdColor,
   MeColor,  BkColor,  AkColor,
   ScColor,  HiColor,  DieColor: CHAR;
   CTurn,    AutoDice,
   Suggested,DiceFlag,
   Mirrored, TutorMode: BOOLEAN;
   DoneP,    DoneC,
   Special,  PGames,
   PPoints,  CGames,
   CPoints            : INTEGER;
   Board,    HBoard   : BoardType;
   q                  : DiceRec;
   Cmd                : ARRAY [0..CommandCount],[0..CommandSize] OF CHAR;


(**************************************************************)
(***********     Command routines     *************************)
(**************************************************************)

PROCEDURE TellScore;
BEGIN
   Wrt;WriteColorString('  Computer Score ¯> ',MColor);WriteInt(CGames,CColor);
   WriteColorString('  (',MColor);WriteInt(CPoints,CColor); WriteColor(')',MColor);
   Wrt;WriteColorString('  Humans   Score ¯> ',MColor);WriteInt(PGames,PColor);
   WriteColorString('  (',MColor);WriteInt(PPoints,PColor); WriteColor(')',MColor);
   Wrt;
END TellScore;


PROCEDURE Setup(VAR Board:BoardType);
VAR X,Y,Pos,OldPos: INTEGER;
   InKey: Key; Ch : CHAR;
BEGIN
   Wrt;WriteColorString(' =================== SETUP PROCEDURE ===================',MColor);
   Wrt;WriteColorString(" Use arrows to move cursor around board. Use 'X' and 'O'",MColor);
   Wrt;WriteColorString(' or [INS] and [DEL] keys to add/remove pieces from board',MColor);
   Wrt;WriteColorString('              Press ESCAPE when finished                ',MColor);Wrt;
   Pos := 1; OldPos :=1;
   LOOP
      LocationOfPip(Pos,1,X,Y,Board); 
      IF Pos<13 THEN DEC(Y,2) ELSE INC(Y,2); END;
      GoTo(X,Y);
      IF (Pos#0)AND(Pos#25) THEN  WriteInt(Pos,HiColor)
      ELSE  CopyChar(' ',HiColor,2);
      END;
      ReadKey(InKey,Ch);
      IF Mirrored THEN
         IF InKey=LeftArrow THEN Inkey:=RightArrow
         ELSIF InKey=RightArrow THEN Inkey:=LeftArrow END;
      CASE InKey OF
         UpArrow,DownArrow : Pos:= 25-Pos |
         LeftArrow : CASE Pos OF
                2..6,8..12: DEC(Pos)|       13..17,19..23: INC(Pos)|
                        1 : Pos:=12 |                  7 : Pos:=0  |
                        18: Pos:=25 |                  24: Pos:=13 |
                        0 : Pos:=6  |                  25: Pos:=19 
                      ELSE END |
         RightArrow: CASE Pos OF
                1..5,7..11: INC(Pos)|       14..18,20..24: DEC(Pos)|
                        6 : Pos:=0  |                  12: Pos:=1  |
                        13: Pos:=24 |                  19: Pos:=25 |
                        0 : Pos:=7  |                  25: Pos:=18
                      ELSE END |
         Plus,O,F1,INS:   IF (Board[Pos]<15)AND((Board[Pos]<0)OR(Pos#25)) THEN 
                                INC(Board[Pos]); PrintPips(Board);  END|
         Minus,X,F2,DEL:  IF(Board[Pos]>-15)AND((Board[Pos]>0)OR(Pos#0)) THEN 
                                DEC(Board[Pos]); PrintPips(Board); END |
               Escape      : EXIT;
      ELSE END;
      LocationOfPip(OldPos,1,X,Y,Board); 
      IF OldPos<13 THEN DEC(Y,2) ELSE INC(Y,2); END;
      GoTo(X,Y); 
      IF (OldPos#0)AND(OldPos#25) THEN    WriteInt(OldPos,BColor) 
      ELSE  CopyChar(' ',BColor,2);
      END;
      OldPos := Pos;
   END;
      GoTo(X,Y); 
      IF (Pos#0)AND(Pos#25) THEN WriteInt(Pos,BColor) 
      ELSE  CopyChar(' ',BColor,2);
      END;
END Setup;

PROCEDURE Swap(VAR Board:BoardType);
VAR Count : INTEGER;
BEGIN
   SwapBoard(Board);
   PrintAllPips(Board);
END Swap;

PROCEDURE Mirror(VAR Board:BoardType);
BEGIN
   Mirrored := NOT Mirrored;
   PrintBoardNumbers;
   PrintAllPips(Board);
END Mirror;

PROCEDURE Suggest(VAR Board:BoardType;VAR q: DiceRec);
BEGIN
   SwapBoard(Board);
   IF ((q.Die[0]#q.Die[1])AND(NonDoublesMove(q))) OR
      ((q.Die[0]=q.Die[1])AND(DoublesMove(q)))       THEN
      SwapMove(q);
   END;
   SwapBoard(Board);
END Suggest;

PROCEDURE  Redraw(Board: BoardType);
BEGIN
   CLS; BorderColor(ORD(ScColor));
   SetScreenToScroll(1,80,17,25);    
   WriteBoard;                       
   PrintAllPips(Board);
   ClearKeyboardBuffer();            
END Redraw;

PROCEDURE  Color;
BEGIN
END Color;

PROCEDURE SwapBoard(VAR Board: BoardType);
VAR Count : INTEGER;
    TBoard: BoardType;
BEGIN
   TBoard := Board;
   FOR Count:=0 TO 25 DO Board[Count]:=-TBoard[25-Count] END;
END SwapBoard;

PROCEDURE SwapMove(VAR q: DiceRec);
VAR Count: CARDINAL;
BEGIN 
   FOR Count:=1 TO q.Moves DO
      q.Move[0,Count-1] := 25 - q.Move[0,Count-1];
      q.Move[1,Count-1] := 25 - q.Move[1,Count-1];
   END;
END SwapMove;


PROCEDURE DisplayMove1(q :DiceRec; Color :CHAR);
VAR Count: CARDINAL;
BEGIN
   FOR Count:=0 TO q.Moves-1 DO
      IF (q.Move[0,Count]=25)OR(q.Move[0,Count]=0) THEN
         WriteColorString('Bar',Color);
      ELSE WriteInt(q.Move[0,Count],Color);
      END;
      WriteColor('-',Color);
      IF (q.Move[1,Count]<1)OR(q.Move[1,Count]>24) THEN
         WriteColorString('Home',Color);
      ELSE WriteInt(q.Move[1,Count],Color)
      END;
      WriteColor(' ',Color);
   END;
END DisplayMove1;

PROCEDURE DisplayMove2(q :DiceRec; Color :CHAR);
VAR Count: CARDINAL;
    Dot,T1,T2 : BOOLEAN;
BEGIN
   Dot := FALSE;
   WriteColorString('  (',Color);
   FOR Count:=0 TO q.Moves-1 DO
      IF (Count>0) THEN
         T1:=(q.Move[0,Count]=q.Move[0,Count-1]);
         T2:=(q.Move[1,Count]=q.Move[1,Count-1]);
      END;
      IF (Count>0)AND(T1)AND(T2) THEN
         WriteColorString(' . ',Color);
         Dot := TRUE;
      ELSE
         IF (Count>0)AND(q.Move[0,Count]=q.Move[1,Count-1])AND(NOT Dot) THEN
         ELSE
            WriteColor(' ',Color);
            IF q.Move[0,Count]=25 THEN WriteColorString('B',Color);
            ELSE WriteInt(q.Move[0,Count],Color); END;
         END;
         WriteColor('/',Color);
         WriteInt(q.Move[1,Count]-q.Move[0,Count],Color); 
         Dot := FALSE;
      END;
   END;
      WriteColorString(' )',Color);
END DisplayMove2;



(**************************************************************)
(*****      THESE PROCEDURES ARE FOR THE PLAYER         *******)
(**************************************************************)

PROCEDURE MovePerson(q: DiceRec): BOOLEAN;
VAR TempBoard : BoardType;
    Err, Count : INTEGER;
BEGIN
    TempBoard := Board;
    Err := DiceMatchMove(q);
    IF Err#0 THEN
       CASE Err OF
         1 : Error("too many moves attempted"); |
         2 : Error("Dice don't match move"); |
         3 : Error("Attempted to use same die twice or illegal move");|
       ELSE END;
       RETURN FALSE;
    END;
    FOR Count := 0 TO q.Moves-1 DO
      Err := LegalPersonMove(q.Move[0,Count],q.Move[1,Count],TempBoard);
      IF Err#0 THEN
         CASE Err OF
            1 : Error("Getting piece from bar must be accomplished first"); |
            2 : Error("Illegal range in move");  |
            3 : Error("No piece at specified start position");  |
            4 : Error("Piece unable to move on opponents block");  |
            5 : Error("Cannot remove pieces until all pieces are in home board");|
            6 : Error("Cannot take off specified pieces");  |
            7 : Error("Cannot move opponents piece");
         ELSE END;
         RETURN FALSE;
      ELSE
         MakePersonMoveInArray(q.Move[0,Count],q.Move[1,Count],TempBoard);
      END;
    END;
    IF (q.Die[0]=q.Die[1]) AND (q.Moves<4) THEN
       Err := MoveIsSufficient(0,q.Die[0],TempBoard);
    ELSIF (q.Die[0]#q.Die[1])AND(q.Moves<1) THEN
       Err := MoveIsSufficient(0,q.Die[0],TempBoard);
       IF Err=0 THEN Err := MoveIsSufficient(0,q.Die[1],TempBoard); END;
    ELSIF (q.Die[0]#q.Die[1])AND(q.Moves<2) THEN
       IF (q.Move[1,Count]-q.Move[0,Count] = q.Die[0]) THEN
               Err := MoveIsSufficient(q.Die[0],q.Die[1],TempBoard);
       ELSE    Err := MoveIsSufficient(q.Die[1],q.Die[0],TempBoard);
       END;
    END;
    IF Err#0 THEN
       CASE Err OF
          1 : Error("Valid move not attempted"); |
          2 : Error("More moves possible");
       ELSE END;
       RETURN FALSE;
    END;
    Board := TempBoard;
    RETURN TRUE;
END MovePerson;



PROCEDURE LegalPersonMove(From,To:INTEGER; TempBoard:BoardType):INTEGER;
VAR Count : INTEGER;
BEGIN
   IF (TempBoard[0]>0)AND(From # 0) THEN
      RETURN 1; END;
   IF (From<0) OR (From>24) OR (To<1) OR (To>30)
      OR (To - From>6) OR (To - From<1) THEN
      RETURN 2;
   END;
   IF TempBoard[From]=0 THEN RETURN 3;   END;
   IF TempBoard[From]<0 THEN RETURN 7;   END;
   IF (To<25) AND (TempBoard[To]<-1) THEN RETURN 4;   END;    
   IF To > 24 THEN  (* try to take off pieces *)
        FOR Count := 0 TO 18 DO
            IF TempBoard[Count]>0 THEN RETURN 5; END;
        END;
       IF To>25 THEN
          FOR Count := 19 TO From-1 DO
             IF TempBoard[Count]>0 THEN RETURN 6; END;
          END;
       END;
   END;
   RETURN 0;
END LegalPersonMove;
   


PROCEDURE DiceMatchMove(q: DiceRec): INTEGER;
VAR  Used,UnUsed,Count: INTEGER;
BEGIN
   IF (q.Die[0]#q.Die[1]) AND (q.Moves>2) THEN RETURN 1 END;
   IF (q.Die[0]=q.Die[1]) THEN
      FOR Count:=0 TO q.Moves-1 DO
         IF q.Move[1,Count]- q.Move[0,Count]#q.Die[0] THEN
            RETURN 2;
         END;
      END;
   ELSE 
      IF q.Moves>0 THEN
         IF q.Move[1,0]- q.Move[0,0]#q.Die[0] THEN
            IF q.Move[1,0]- q.Move[0,0]#q.Die[1] THEN RETURN 2;
            ELSE Used:=q.Die[1]; UnUsed:=q.Die[0];
            END;
         ELSE Used:=q.Die[0]; UnUsed:=q.Die[1];
         END;
      END;
      IF (q.Moves>1)AND(q.Move[1,1]-q.Move[0,1]#UnUsed) THEN RETURN 3; END;
   END;
   RETURN 0
END DiceMatchMove;



PROCEDURE MoveIsSufficient(Used,UnUsed:INTEGER; TempBoard:BoardType):INTEGER;
VAR Count,Count2:INTEGER;
BEGIN
   IF Used=0 THEN
      FOR Count:=0 TO 24 DO
         IF LegalPersonMove(Count,Count+UnUsed,TempBoard)=0 THEN
            RETURN 1;
         END;
      END;
   ELSE
      TempBoard:=Board;
      FOR Count:=0 TO 24 DO
         IF LegalPersonMove(Count,Count+Used,TempBoard)=0 THEN
            MakePersonMoveInArray(Count,Count+Used,TempBoard);
            FOR Count2:=0 TO 24 DO
               IF LegalPersonMove(Count2,Count2+UnUsed,TempBoard)=0 THEN
                  RETURN 2;
               END;
            END;
            TempBoard:=Board;
         END;
         IF LegalPersonMove(Count,Count+UnUsed,TempBoard)=0 THEN
            MakePersonMoveInArray(Count,Count+UnUsed,TempBoard);
            FOR Count2:=0 TO 24 DO
               IF LegalPersonMove(Count2,Count2+Used,TempBoard)=0 THEN
                  RETURN 2;
               END;
            END;
            TempBoard:=Board;
         END;
      END;
   END;
   RETURN 0;
END MoveIsSufficient;



PROCEDURE MakePersonMoveInArray(From,To:INTEGER; VAR TempBoard:BoardType);
BEGIN
   DEC(TempBoard[From]);
   IF (To<=24)AND(TempBoard[To]=-1) THEN
      TempBoard[To]:=1; DEC(TempBoard[25]);
   ELSIF (To<=24) THEN  INC(TempBoard[To]); 
   END;
END MakePersonMoveInArray;


PROCEDURE NoLegalMove(q :DiceRec; Board: BoardType): BOOLEAN;
VAR  Count:INTEGER; OutBack : BOOLEAN;
BEGIN
   IF (Board[0]>0)AND   (* ret true if in bar and cant get out *)
      (Board[q.Die[0]]<-1)AND
      (Board[q.Die[1]]<-1) THEN RETURN TRUE END;
   OutBack:=FALSE;
   FOR Count:=0 TO 18 DO  (* ret false of move avail in open board *)
      IF (Board[Count]>0) THEN
         OutBack := TRUE;
         IF (Board[Count+q.Die[0]] >-2)OR(Board[Count+q.Die[1]] >-2) THEN
            RETURN FALSE;
         END;
      END;
   END;
   FOR Count:=19 TO 24 DO
      IF (Board[Count]>0) THEN
         IF (Count+q.Die[0]<25)AND(Board[Count+q.Die[0]]>-2)THEN RETURN FALSE END;
         IF (Count+q.Die[1]<25)AND(Board[Count+q.Die[1]]>-2)THEN RETURN FALSE END;
         IF ((Count+q.Die[0]>24)OR(Count+q.Die[0]>24))AND(NOT OutBack) THEN
            RETURN FALSE;
         END;
      END;
   END;
   RETURN TRUE; 
END NoLegalMove;


(**************************************************************)
(*****      THESE PROCEDURES ARE FOR THE COMPUTER       *******)
(**************************************************************)


PROCEDURE MoveComputer(q: DiceRec);
BEGIN
   IF ((q.Die[0]#q.Die[1])AND(NonDoublesMove(q))) OR
      ((q.Die[0]=q.Die[1])AND(DoublesMove(q)))    THEN
      DoComputerMove(q)
   END;
END MoveComputer;



PROCEDURE NonDoublesMove(VAR q: DiceRec): BOOLEAN;
BEGIN
   IF    TwoMoves(q) THEN RETURN TRUE ;
   ELSIF OneMove(q) THEN RETURN TRUE ;
   ELSE Error(" No Possible Move For Computer");
   END;
   RETURN FALSE;
END NonDoublesMove;



PROCEDURE DoublesMove(VAR q: DiceRec): BOOLEAN;
BEGIN
   IF    FourMoves(q) THEN RETURN TRUE ;
   ELSIF ThreeMoves(q) THEN RETURN TRUE ;
   ELSIF TwoMoves(q) THEN RETURN TRUE ;
   ELSIF OneMove(q) THEN RETURN TRUE ;
   ELSE Error(" No Possible Move For Computer");
   END;
   RETURN FALSE ;
END DoublesMove;



PROCEDURE FourMoves(VAR q: DiceRec):BOOLEAN;
VAR Count,Count2,Count3,Count4,BestVal,Val: INTEGER;
    TempBoard,TempBoard2,TempBoard3,TempBoard4: BoardType;
    MoveFound : BOOLEAN;
BEGIN
   q.Moves:=0; BestVal:=-10000; MoveFound := FALSE;
   FOR Count:=25 TO 1 BY -1 DO
      IF LegalComputerMove(Count,Count-q.Die[0],Board)=0 THEN
         TempBoard:=Board;
         MakeComputerMoveInArray(Count,Count-q.Die[0],TempBoard);
         FOR Count2:=Count TO 1 BY -1 DO
            IF LegalComputerMove(Count2,Count2-q.Die[0],TempBoard)=0 THEN
               TempBoard2:=TempBoard;
               MakeComputerMoveInArray(Count2,Count2-q.Die[0],TempBoard2);
               FOR Count3:=Count2 TO 1 BY -1 DO
                  IF LegalComputerMove(Count3,Count3-q.Die[0],TempBoard2)=0 THEN
                     TempBoard3:=TempBoard2;
                     MakeComputerMoveInArray(Count3,Count3-q.Die[0],TempBoard3);
                     FOR Count4:=Count3 TO 1 BY -1 DO
                        IF LegalComputerMove(Count4,Count4-q.Die[0],TempBoard3)=0 THEN
                           TempBoard4:=TempBoard3;
                           MakeComputerMoveInArray(Count4,Count4-q.Die[0],TempBoard4);
                           CalculateBoardValue(TempBoard4,Val);
                           IF Val>BestVal THEN
                              BestVal:=Val;        q.Moves:=4;
                              q.Move[0,0]:=Count;  q.Move[1,0]:=Count-q.Die[0];
                              q.Move[0,1]:=Count2; q.Move[1,1]:=Count2-q.Die[0];
                              q.Move[0,2]:=Count3; q.Move[1,2]:=Count3-q.Die[0];
                              q.Move[0,3]:=Count4; q.Move[1,3]:=Count4-q.Die[0];
                              MoveFound := TRUE;
   END;END;END; END;END;END; END;END;END;
   RETURN MoveFound;
END FourMoves;


PROCEDURE ThreeMoves(VAR q: DiceRec):BOOLEAN;
VAR Count,Count2,Count3,BestVal,Val: INTEGER;
    TempBoard,TempBoard2,TempBoard3: BoardType;
    MoveFound : BOOLEAN;
BEGIN
   q.Moves:=0; BestVal:=-10000; MoveFound := FALSE;
   FOR Count:=25 TO 1 BY -1 DO
      IF LegalComputerMove(Count,Count-q.Die[0],Board)=0 THEN
         TempBoard:=Board;
         MakeComputerMoveInArray(Count,Count-q.Die[0],TempBoard);
         FOR Count2:=Count TO 1 BY -1 DO
            IF LegalComputerMove(Count2,Count2-q.Die[0],TempBoard)=0 THEN
               TempBoard2:=TempBoard;
               MakeComputerMoveInArray(Count2,Count2-q.Die[0],TempBoard2);
               FOR Count3:=Count2 TO 1 BY -1 DO
                  IF LegalComputerMove(Count3,Count3-q.Die[0],TempBoard2)=0 THEN
                     TempBoard3:=TempBoard2;
                     MakeComputerMoveInArray(Count3,Count3-q.Die[0],TempBoard3);
                     CalculateBoardValue(TempBoard3,Val);
                     IF Val>BestVal THEN
                        BestVal:=Val;        q.Moves:=3;
                        q.Move[0,0]:=Count;  q.Move[1,0]:=Count-q.Die[0];
                        q.Move[0,1]:=Count2; q.Move[1,1]:=Count2-q.Die[0];
                        q.Move[0,2]:=Count3; q.Move[1,2]:=Count3-q.Die[0];
                        MoveFound := TRUE;
   END;END;END; END;END;END; END;
   RETURN MoveFound;
END ThreeMoves;



PROCEDURE TwoMoves(VAR q: DiceRec):BOOLEAN;
VAR Count,Count2,Index,BestVal,Temp,Val,Die : INTEGER;
    TempBoard,TempBoard2: BoardType;
    MoveFound : BOOLEAN;
BEGIN
   q.Moves:=0; BestVal:=-10000; MoveFound := FALSE;
   FOR Index:=1 TO 2 DO (**** go through both dice orders ****)
      FOR Count:=25 TO 1 BY -1 DO
         IF LegalComputerMove(Count,Count-q.Die[0],Board)=0 THEN
            TempBoard:=Board;
            MakeComputerMoveInArray(Count,Count-q.Die[0],TempBoard);
            FOR Count2:=Count TO 1 BY -1 DO
               IF LegalComputerMove(Count2,Count2-q.Die[1],TempBoard)=0 THEN
                  TempBoard2:=TempBoard;
                  MakeComputerMoveInArray(Count2,Count2-q.Die[1],TempBoard2);
                  CalculateBoardValue(TempBoard2,Val);
                  IF Val>BestVal THEN
                     BestVal:=Val;        q.Moves:=2;
                     q.Move[0,0]:=Count;  q.Move[1,0]:=Count-q.Die[0];
                     q.Move[0,1]:=Count2; q.Move[1,1]:=Count2-q.Die[1];
                     MoveFound := TRUE;
                  END;
               END;
            END;
         END;
      END;
      Temp:=q.Die[1]; q.Die[1]:=q.Die[0]; q.Die[0]:=Temp; (**** swap dice order ******)
   END;
   RETURN MoveFound;
END TwoMoves;



PROCEDURE OneMove(VAR q: DiceRec):BOOLEAN;
VAR Count,Index,BestVal,Val,Die : INTEGER;
    TempBoard : BoardType;
    MoveFound : BOOLEAN;
BEGIN
   q.Moves:=0; BestVal:=-10000; MoveFound := FALSE;
   FOR Index:=1 TO 2 DO  (**** 2 dice to pick***)
      IF (Index=1) THEN Die:=q.Die[0]; ELSE Die:=q.Die[1] END;
      FOR Count:=25 TO 1 BY -1 DO
         IF LegalComputerMove(Count,Count-Die,Board)=0 THEN
            TempBoard:=Board;
            MakeComputerMoveInArray(Count,Count-Die,TempBoard);
            CalculateBoardValue(TempBoard,Val);
            IF Val>BestVal THEN
               BestVal:=Val;        q.Moves:=1;
               q.Move[0,0]:=Count;  q.Move[1,0]:=Count-Die;
               MoveFound := TRUE;
            END;
         END;
      END;
      TempBoard:=Board;
   END;
   RETURN MoveFound;
END OneMove;



PROCEDURE LegalComputerMove(From,To : INTEGER; TempBoard:BoardType): INTEGER;
VAR Count : INTEGER;
BEGIN
   IF (TempBoard[25]<0)AND(From # 25) THEN
      RETURN 1; END;
   IF (From<1) OR (From>25) OR (To<-5) OR (To>24)
      OR (From - To >6) OR (From - To<1) THEN
      RETURN 2;
   END;
   IF TempBoard[From]=0 THEN RETURN 3;   END;
   IF TempBoard[From]>0 THEN RETURN 7;   END;
   IF (To>0)AND(TempBoard[To]>1) THEN RETURN 4;   END;    
   IF To < 1 THEN  (* try to take off pieces *)
       (* rest of board empty ? *)
        FOR Count := 7 TO 25 DO
            IF TempBoard[Count]<0 THEN RETURN 5; END;
        END;
       IF To<0 THEN
          FOR Count := From+1 TO 6 DO
             IF TempBoard[Count]<0 THEN RETURN 6; END;
          END;
       END;
   END;
   RETURN 0;
END LegalComputerMove;



PROCEDURE MakeComputerMoveInArray(From,To:INTEGER;VAR TempBoard:BoardType);
BEGIN
   INC(TempBoard[From]);
   IF (To>=1)AND(TempBoard[To]=1) THEN
      TempBoard[To]:=-1; INC(TempBoard[0]);
   ELSIF (To>0) THEN DEC(TempBoard[To]); 
   END;
END MakeComputerMoveInArray;



PROCEDURE DoComputerMove(q:DiceRec);
VAR Count:INTEGER;
BEGIN
   FOR Count:=0 TO q.Moves-1 DO
      MakeComputerMoveInArray(q.Move[0,Count],q.Move[1,Count],Board);
   END;
   Wrt;WriteColorString('  My Move Is (X)¯> ',CColor);
   DisplayMove1(q,CColor);
   Wrt;
END DoComputerMove;

(**************************************************************)
(*****    THESE PROCEDURES ARE FOR DRIVING THE SCREEN  ********)
(**************************************************************)

PROCEDURE WriteBoard;
VAR Count: INTEGER;
BEGIN
DrawToScreen(2); 
Screen.GoTo(1,2);SetAttrib(ORD(BColor));
PrintLn(' ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍËÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»');
FOR Count:=1 TO 12 DO                          
PrintLn(' º                              º   º                              º');
END;                
PrintLn(' ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÊÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼ [ESC]=Help');
PrintLn('                                                                    ');
PrintBoardNumbers;
END WriteBoard;


PROCEDURE PrintBoardNumbers;
BEGIN
   DrawToScreen(2);SetAttrib(ORD(BColor));
   IF Mirrored THEN 
      Screen.GoTo(1,1); PrintLn('    12   11   10   9    8    7         6    5    4    3    2    1   ');
      Screen.GoTo(1,16);PrintLn('    13   14   15   16   17   18        19   20   21   22   23   24  ');
   ELSE
      Screen.GoTo(1,1); PrintLn('    1    2    3    4    5    6         7    8    9    10   11   12  ');
      Screen.GoTo(1,16);PrintLn('    24   23   22   21   20   19        18   17   16   15   14   13  ');
   END;
   LookAtScreen(2);
END PrintBoardNumbers;


PROCEDURE PrintPips(Board:BoardType);
VAR End,X,Y,Count,Count2 : INTEGER;
BEGIN
   FOR Count:=0 TO 25 DO
      IF Board[Count]#HBoard[Count] THEN
         IF ABS(Board[Count])>10 THEN End:=15 ELSE End:=ABS(Board[Count])+4 END;
         FOR Count2:=1 TO End DO
            LocationOfPip(Count,Count2,X,Y,Board);GoTo(X,Y);
            IF Board[Count]>=Count2 THEN WriteColor('O',PColor);
            ELSIF -Board[Count]>=Count2 THEN WriteColor('X',CColor);
            ELSE WriteColor(' ',BkColor) END;
         END;
      END;
   END;
   HBoard := Board;
END PrintPips;


PROCEDURE PrintAllPips(Board:BoardType);
VAR X,Y,Count,Count2 : INTEGER;
BEGIN
   FOR Count:=0 TO 25 DO
      FOR Count2:=1 TO 15 DO
         LocationOfPip(Count,Count2,X,Y,Board);GoTo(X,Y);
         IF Board[Count]>=Count2 THEN WriteColor('O',PColor);
         ELSIF -Board[Count]>=Count2 THEN WriteColor('X',CColor);
         ELSE WriteColor(' ',BkColor) END;
      END;
   END;
   HBoard := Board;
END PrintAllPips;


PROCEDURE LocationOfPip(N,C:INTEGER;VAR X,Y:INTEGER;Board:BoardType);
BEGIN
   IF (N<13) THEN
         Y:=3+(C-1)MOD 5
   ELSE
      Y:=14-(C-1)MOD 5;
      N:=25-N
   END;
   IF Mirrored THEN N:=13-N END;
   X:=N*5;
   IF N>6 THEN X:=X+5 END;
   IF (N=0)OR(N=13) THEN X:= 35 END;
   IF C>10 THEN INC(X) ELSIF C>5 THEN DEC(X); END;
END LocationOfPip;



PROCEDURE PrintDice(q: DiceRec);
BEGIN
   PrintDie(q.Die[0],4); PrintDie(q.Die[1],10);
END PrintDice;


PROCEDURE PrintDie(Die,Pos :CARDINAL);
BEGIN
   GoTo(72,Pos);
   CASE Die OF
      2,3: WriteColorString('      ',DieColor); |
      4,5: WriteColorString('     ',DieColor); |
      6  : WriteColorString('    ',DieColor);
   ELSE    WriteColorString('       ',DieColor); 
   END;
   GoTo(72,Pos+1);
   CASE Die OF
      1,3,5 : WriteColorString('      ',DieColor); |
      ELSE    WriteColorString('       ',DieColor); 
   END;
   GoTo(72,Pos+2);
   CASE Die OF
      2,3: WriteColorString('      ',DieColor); |
      4,5: WriteColorString('     ',DieColor); |
      6  : WriteColorString('    ',DieColor);
   ELSE    WriteColorString('       ',DieColor); 
   END;
END PrintDie;


(**************************************************************)
(******         THESE PROCEDURE ARE FOR PARSING THE MOVE  *****)
(**************************************************************)

PROCEDURE ReadDice(VAR q:DiceRec; Color: CHAR; A:ARRAY OF CHAR):BOOLEAN;
BEGIN
   IF DiceFlag THEN
      ClearKeyboardBuffer();
      Wrt;Wrt;WriteColorString(A,Color);
      ReadInt(q.Die[0],Color);WriteColor(' ',Color);ReadInt(q.Die[1],Color);
      IF (q.Die[0]<1)OR(q.Die[0]>6)OR(q.Die[1]<1)OR(q.Die[1]>6) THEN
         Error("Illegal Die value");
         RETURN FALSE
      END;
   END;
   DiceFlag:= TRUE;
   RETURN TRUE;
END ReadDice;


PROCEDURE ReadPlayerMove(VAR q:DiceRec; VAR Special: INTEGER);
VAR Count : CARDINAL;
    S : ARRAY [1..80] OF CHAR;
BEGIN
   FOR Count:=1 TO 80 DO  S[Count]:=' ' END;
   ClearKeyboardBuffer();
   Wrt;WriteColorString('  Enter your move (O)¯> ',PColor);ReadStr(S,PColor);Wrt;
   SpecialCmd(S,Special);
   IF Special=0 THEN 
      ParseMove(S,q);
   END;
END ReadPlayerMove;



VAR XStart,YStart : INTEGER;

PROCEDURE ReadStr(VAR Str : ARRAY OF CHAR; Att:CHAR);
VAR  StartX,StartY,Index,Max,Last,Count :INTEGER;
     Xs,Ys : CARDINAL;
     InKey : Key; Ch : CHAR;
     InsMode : BOOLEAN;
BEGIN
   Last:= -1;       Index:= -1;
   CursorAt(Xs,Ys);  XStart:= Xs;   YStart:=Ys;
   Max:= HIGH(Str);   InsMode:= FALSE;
   LOOP
      ReadKey(InKey,Ch); IF Ch=3c THEN BreakProc END;
      CASE InKey OF
         Return      : EXIT |
         Ins         : InsMode := NOT InsMode |
         Del         : IF Index<Last THEN
                          FOR Count:=Index+1 TO Last-1 DO
                             Str[Count] := Str[Count+1];
                             Go(Count); WriteColor(Str[Count],Att);
                          END; Go(Last); WriteColor(' ',Att); Go(Index+1); DEC(Last);
                       END; |
         RightArrow  : IF Index<Last THEN INC(Index); Go(Index+1); END; |
         LeftArrow   : IF Index>=0    THEN DEC(Index); Go(Index+1); END; |
         CRightArrow : |
         CLeftArrow  : |
         F1,F2,F3,F4,F5,F6,F7,F8,F9,F0 :|
         Escape      : Help(); |
         Home        : Index := -1; Go(Index+1);  |
         End         : Index := Last; Go(Index+1);|
         BackArrow   : IF Index>=0 THEN
                          FOR Count:=Index TO Last DO
                             Str[Count] := Str[Count+1];
                             Go(Count); WriteColor(Str[Count],Att);
                          END; Go(Last); WriteColor(' ',Att); DEC(Index); Go(Index+1);  DEC(Last);
                       END; |
         CEnd        : IF Index<Last THEN
                          FOR Count:=Index+1 TO Last DO
                             Go(Count); WriteColor(' ',Att);
                          END; Last:=Index; Go(Index+1)
                      END; 
      ELSE
         IF (Index<Max) AND ((NOT InsMode) OR (Last<Max)) THEN
            IF InsMode THEN
               FOR Count:=Last TO Index+1 BY -1 DO
                  Str[Count+1] := Str[Count];
                  Go(Count+1); WriteColor(Str[Count+1],Att);
               END;
               INC(Last);
            END;
            INC(Index); IF (Index>Last) THEN INC(Last); END;
            Go(Index); WriteColor(Ch,Att);  Str[Index] := Ch;
         END;
      END;
   END;
   IF  Last<Max THEN  Str[Last+1]:=0C END;
END ReadStr;


PROCEDURE Go(Index : INTEGER);
VAR X,Y : INTEGER;
BEGIN
   X := ((XStart + Index-1) MOD 80) +1;
   Y := YStart + (XStart + Index-1) DIV 80;
   IF Y>25 THEN Y:=25 END;
   GoTo(X,Y)
END Go;


PROCEDURE SpecialCmd(A:ARRAY OF CHAR; VAR Special:INTEGER);
VAR Index,Y,X: INTEGER;
    Pointer: CARDINAL;
    Matched,Matching : BOOLEAN;
BEGIN
   Index:= 0; Special:= 0; Y:= 0; Matched:=FALSE;
   WHILE (A[Index]=' ') DO INC(Index) END;
   IF A[Index]=0c THEN RETURN END;
   WHILE (Y<=CommandCount)AND(NOT Matched) DO
      Pointer := Index;  Matching:= TRUE;  X:=0;
      WHILE (X<=CommandSize)AND(NOT Matched)AND(Matching) DO
         IF ((Cmd[Y,X]#' ')AND(Cmd[Y,X] # CAP(A[Pointer]))) THEN
            Matching:=FALSE;
         ELSE  INC(Pointer); INC(X);
               IF Pointer>HIGH(A) THEN Special:=0; RETURN END;
         END;
      END;
      Matched := Matching; INC(Y);  Special := Y;
   END;
   IF NOT Matched THEN Special:=0 END;
END SpecialCmd;


(**************************************************************)
(******  THESE ARE GENERAL PURPOSE PROCEDURES  ****************)
(**************************************************************)

PROCEDURE Message(A: ARRAY OF CHAR; C1,C2: CHAR): CHAR;
VAR Ch : CHAR;
BEGIN
   Wrt;WriteColorString(A,MColor);
   REPEAT Read(Ch); IF Ch=33C THEN Help(); END;
   IF Ch=3C THEN BreakProc END;
   UNTIL (CAP(Ch)=C1)OR(CAP(Ch)=C2);
   RETURN CAP(Ch);
END Message;

PROCEDURE WriteColorString(S : ARRAY OF CHAR; Att:CHAR);
VAR Count:INTEGER;
BEGIN
   FOR Count:=0 TO HIGH(S) DO
      CopyChar(S[Count],Att,1); HTab(XPos()+1);
   END;
END WriteColorString;

PROCEDURE WriteColor(Ch,Att:CHAR);
BEGIN
   CopyChar(Ch,Att,1); HTab(XPos()+1);
END WriteColor;

PROCEDURE GetRandomDice(VAR q :DiceRec);
BEGIN
   IF DiceFlag THEN
      q.Die[0] := RandomCard(6) + 1; q.Die[1] := RandomCard(6) + 1;
   END;
   DiceFlag:= TRUE 
END GetRandomDice;

PROCEDURE ShowDice(q: DiceRec; S:ARRAY  OF CHAR; C: CHAR);
BEGIN
   Wrt;WriteColorString(S,C);
   WriteInt(q.Die[0],C);WriteColor(' ',C);WriteInt(q.Die[1],C)
END ShowDice;


PROCEDURE ReadInt(VAR Num: INTEGER; Att: CHAR);
VAR Ch : CHAR; (* READS 1 DIGIT INTEGER *)
BEGIN
   REPEAT  
      Read(Ch); IF Ch=33c THEN Help(); Read(Ch); END;
      IF Ch=3C THEN BreakProc END;
   UNTIL (Ch>='0')AND(Ch<='9');
   Num:=INTEGER(ORD(Ch))-48; WriteColor(Ch,Att);
END ReadInt;


PROCEDURE WriteInt(N: INTEGER; Att : CHAR);
BEGIN
   IF N<0 THEN
      N:=-N; WriteColor('-',Att);
   END;
   IF N>9999 THEN Ch:=CHR(N DIV 10000+48); N:=N MOD 10000;
      WriteColor(Ch,Att);
   END;
   IF N>999 THEN Ch:=CHR(N DIV 1000+48); N:=N MOD 1000;
      WriteColor(Ch,Att);
   END;
   IF N>99 THEN Ch:=CHR(N DIV 100+48); N:=N MOD 100;
      WriteColor(Ch,Att);
   END;
   IF N>9  THEN Ch:=CHR(N DIV 10  +48); N:=N MOD 10;
      WriteColor(Ch,Att);
   END;
   Ch:=CHR(N+48); WriteColor(Ch,Att); 
END WriteInt;


PROCEDURE Error(S : ARRAY OF CHAR);
BEGIN   Wrt;WriteColorString('  ',EColor);WriteColorString(S,EColor); Wrt;
END Error;

PROCEDURE Wrt;  (* to keep output in window *)
BEGIN   ScrollUp; GoTo(1,25); END Wrt;


PROCEDURE ClearKeyboardBuffer();
VAR Ch : CHAR;
BEGIN  WHILE KeyPressed() DO Read(Ch) END;
END ClearKeyboardBuffer;


PROCEDURE EndOfGame(TempBoard: BoardType):BOOLEAN;
VAR Count: INTEGER;
BEGIN
   DoneP:=30;   DoneC:=30;
   FOR Count:=0 TO 25 DO
      IF (TempBoard[25-Count]) >= 1 THEN DoneP:=25-Count END;
      IF (TempBoard[Count])    <=-1 THEN DoneC:=Count END;
   END;
   IF (DoneC=30)OR(DoneP=30) THEN RETURN TRUE ELSE RETURN FALSE END;
END EndOfGame;


PROCEDURE EndDialog(TempBoard: BoardType);
BEGIN
   IF (DoneP=30)    THEN
      IF    (DoneC>18) THEN Error("You BACKGAMMONED me!... cheater!");
                            INC(PGames); INC(PPoints,3);
      ELSIF (DoneC>6)  THEN Error(" You Gammoned me");
                            INC(PGames); INC(PPoints,2);
      ELSE Error("You barely squeaked by me");
                            INC(PGames); INC(PPoints,1);
      END; TellScore; Delay;
   END;
   IF (DoneC=30) THEN
      IF    (DoneP<7)  THEN Error("I BACKGAMMONED you!... loser!");
                            INC(CGames); INC(CPoints,3);
      ELSIF (DoneP<19) THEN Error("I Gammoned you!");
                            INC(CGames); INC(CPoints,2);
      ELSE  Error("I won this game easily");
                            INC(CGames); INC(CPoints,1);
      END; TellScore; Delay;
   END;
END EndDialog;


PROCEDURE Delay;
VAR C1,C2 : INTEGER;
BEGIN
   FOR C1:=1 TO 20 DO;
   FOR C2:=1 TO 10000 DO;
   END; END;
END Delay;


(**************************************************************)
(***********      help routines    ****************************)
(**************************************************************)

PROCEDURE Help;
VAR W:Window;
    Ch : CHAR;
BEGIN
   StartWindowDef(W,30,9,MeColor);
   DefineWindow(' ');
   DefineWindow('        Help Menu');
   DefineWindow('        ÄÄÄÄÄÄÄÄÄ');
   DefineWindow('  1: Making moves');
   DefineWindow('  2: Getting pieces from bar');
   DefineWindow('  3: Taking off pieces');
   DefineWindow('  4: Other commands');
   DefineWindow('  5: Acknowlegements');
   DefineWindow(' ');
   Border(W,BdColor);
   PushWindow(W,20,9);KillWindow(W);
   LOOP
      ClearKeyboardBuffer(); Read(Ch);
      IF Ch=3C THEN BreakProc END;
      CASE CAP(Ch) OF
       '1': Win1; | '2': Win2; |
       '3': Win3; | '4': Win4; | '5': Win5; 
      ELSE EXIT END;
   END;
   PopWindow;
END Help;

PROCEDURE Win1;
VAR W:Window;
    Ch : CHAR;
BEGIN
   StartWindowDef(W,58,20,MeColor);
   DefineWindow(' ');
   DefineWindow('                     To Make Moves                       ');
   DefineWindow('                     ÄÄÄÄÄÄÄÄÄÄÄÄÄ                       ');
   DefineWindow('   You can enter a valid move in either of these 2 ways: ');
   DefineWindow('   1)    7/3  (move piece at position 7  3 spaces)       ');
   DefineWindow('   2)    5-9  (move piece at position 5 to position 9)   ');
   DefineWindow('   If your roll was a 3 and a 4, to move from 1 to 4     ');
   DefineWindow('   and from 12 to 16, you could enter that move in any   ');
   DefineWindow('   of the following four ways:                           ');
   DefineWindow('   1/3 12/4  or  1-4 12-16  or  1/3 12-16  or  1-4 12/4  ');
   DefineWindow('                                                         ');
   DefineWindow('   If you plan to move the same piece more than once,    ');
   DefineWindow('   you can combine moves. For example; to move a piece   ');
   DefineWindow('   from 4 to 9 and then from 9 to 11 you could type:     ');
   DefineWindow('   4/5/2  or  4/5-11  or  4-9/2  or  4-9-11              ');
   DefineWindow('                                                         ');
   DefineWindow('   If you roll doubles and plan to make the same move    ');
   DefineWindow("   more than once, you can use a '.' as a repeat char.   ");
   DefineWindow('   Example:   12/3 . . .  (move 4 pieces from 12 to 15)  ');
   DefineWindow(' ');
   Border(W,BdColor);
   PushWindow(W,10,3); KillWindow(W);
   ClearKeyboardBuffer(); 
   Read(Ch); PopWindow();
END Win1;


PROCEDURE Win2;
VAR W:Window;
    Ch : CHAR;
BEGIN
   StartWindowDef(W,54,12,MeColor);
   DefineWindow(' ');
   DefineWindow('            To Get Pieces from the bar');
   DefineWindow('            ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
   DefineWindow("  You specify the piece with either a '0' or a 'B'");
   DefineWindow(' ');
   DefineWindow('                     Example');
   DefineWindow('                     ÄÄÄÄÄÄÄ');
   DefineWindow('  If one of your Dice was a 3, and you had a piece');
   DefineWindow('  on a bar,you could type any of the following:');
   DefineWindow(' ');
   DefineWindow('              B/3  or  b/3  or  0/3  ');
   DefineWindow(' ');
   Border(W,BdColor);
   PushWindow(W,14,7); KillWindow(W);
   ClearKeyboardBuffer(); 
   Read(Ch); PopWindow();
END Win2;

PROCEDURE Win3;
VAR W:Window;
    Ch : CHAR;
BEGIN
   StartWindowDef(W,58,12,MeColor);
   DefineWindow(' ');
   DefineWindow('               To take pieces off');
   DefineWindow('               ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
   DefineWindow('  To take off pieces normally with the correct dice,');
   DefineWindow('  move off the board as if you were moving to point 25');
   DefineWindow('  Examples:     22/3  or  20/5  or  19-25  ....');
   DefineWindow(' ');
   DefineWindow('  If you must take off pieces with a die roll bigger');
   DefineWindow('  than your roll (lowest point =23 and die is a 5)');
   DefineWindow("  you must use the '/' option.");
   DefineWindow('  Examples     23/5  .....    ');
   DefineWindow(' ');
   Border(W,BdColor);
   PushWindow(W,11,6);KillWindow(W);
   ClearKeyboardBuffer(); 
   Read(Ch); PopWindow();
END Win3;


PROCEDURE Win4;
VAR W:Window;
    Ch : CHAR;
BEGIN
   StartWindowDef(W,43,18,MeColor);
   DefineWindow(' ');
   DefineWindow('              Commands   ');
   DefineWindow('              ÄÄÄÄÄÄÄÄ ');
   DefineWindow('  To enter a command you just type');
   DefineWindow("  it in at the 'Enter your move (O)¯>'");
   DefineWindow('  prompt. The commands are:');
   DefineWindow(' ');
   DefineWindow('  EXIT ..... Quit/Restart prog.');
   DefineWindow('  SETUP .... Change board setup');
   DefineWindow('  SWAP ..... Swap setup with computer');
   DefineWindow('  MIRROR ... Change side of home board');
   DefineWindow('  SUGGEST .. Ask how computer would move');
   DefineWindow('  TUTOR .... Continuous SUGGEST mode');
   DefineWindow('  SCORE .... Show current scores');
   DefineWindow('  REDRAW ... Redraw screen');
   DefineWindow('  AUTOPLAY . Have computer play itself');
   DefineWindow('  HELP ..... Same as [ESC] key');
   DefineWindow(' ');
   Border(W,BdColor);
   PushWindow(W,25,3);KillWindow(W);
   ClearKeyboardBuffer(); 
   Read(Ch); PopWindow();
END Win4;

PROCEDURE Win5;
VAR W:Window;
    Ch : CHAR;
BEGIN
   StartWindowDef(W,32,11,AkColor);
   DefineWindow(' ');
   DefineWindow('        Acknowlegements');
   DefineWindow('        ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
   DefineWindow('  This program was created by');
   DefineWindow(' ');
   DefineWindow('       Craig Fitzgerald');
   DefineWindow('       2330-A4 S.W 35pl.');
   DefineWindow('       Gainesville, Fl.');
   DefineWindow('                   32608 ');
   DefineWindow('        (904) 374-4091');
   DefineWindow(' ');
   Border(W,BdColor);
   PushWindow(W,25,6);KillWindow(W);
   ClearKeyboardBuffer(); 
   Read(Ch); PopWindow();
END Win5;



(**************************************************************)
(***********     Debug routines       *************************)
(**************************************************************)
PROCEDURE PrintQ(q: DiceRec);
VAR Index : CARDINAL;
BEGIN
   GoTo(60,21); WriteColorString('                   ',MColor);
   GoTo(60,22); WriteColorString('                   ',MColor);
   GoTo(60,23); WriteColorString('                   ',MColor);
   GoTo(60,24); WriteColorString('                   ',MColor);
   GoTo(60,25); WriteColorString('                   ',MColor);
   GoTo(60,21); WriteColorString('q.moves=',MColor);WriteInt(q.Moves,MColor);
   IF q.Moves>4 THEN  Error (' there are more than 4 moves !!!!!!!!!! ');
      q.Moves := 4 END;
   FOR Index:=1 TO q.Moves DO
      GoTo(60,21+Index);
      WriteColorString('q[0]=',MColor);   WriteInt(q.Move[0,Index-1],MColor);
      WriteColorString('  q[1]=',MColor); WriteInt(q.Move[1,Index-1],MColor);
   END;
END PrintQ;


(**************************************************************)
(***********     INITIALIZATION PROCS *************************)
(**************************************************************)

PROCEDURE BreakProc;
BEGIN
   Cls;CLS;GoTo(36,12);
   WriteColorString('Good Bye.',AkColor);
   GoTo(1,1);
   Terminate(Normal);
END BreakProc;


PROCEDURE InitializeBreakProc;
BEGIN
   EnableBreak;
   InstallBreak(BreakProc);
END InitializeBreakProc;

PROCEDURE InitializeBoard(VAR Board:BoardType);
VAR A,Count:INTEGER;
BEGIN
   FOR Count:=0 TO 25 DO Board[Count]:=0 END;
   HBoard := Board;
   Board[1]:=  2 ;       Board[6]:=  -5;
   Board[8]:=  -3;       Board[12]:= 5 ;
   Board[13]:= -5;       Board[17]:= 3 ;
   Board[19]:= 5 ;       Board[24]:= -2;
END InitializeBoard;


PROCEDURE LoadCmds;
   PROCEDURE Q(A:ARRAY OF CHAR);
   VAR Index,X,Y: CARDINAL;
   BEGIN Index:=0;
      FOR Y:=0 TO CommandCount DO
         FOR X:=0 TO CommandSize DO Cmd[Y,X]:= A[Index]; INC(Index) END;
      END; END Q;
BEGIN
   Q('EXIT    SETUP   SWAP    MIRROR  SUGGEST REDRAW  COLOR   AUTOPLAYTUTOR   SCORE   HELP    LINDA   ')
END LoadCmds;

PROCEDURE OnceInit;
BEGIN
   CColor  := 4c;   PColor  := 2c;
   MColor  := 5c;   EColor  := 17c;
   BColor  := 13c;  BdColor := 16c;
   MeColor := 5c;   BkColor := 7c;
   AkColor := 15c;  ScColor := 0c;
   HiColor := 160c; DieColor:= 160c;
   DiceFlag :=TRUE;
   Mirrored:=FALSE;   
   CGames := 0; CPoints := 0;
   PGames := 0; PPoints := 0;
   LoadCmds;
   DrawToScreen(2); Cls; 
   CLS; BorderColor(ORD(ScColor));
   SetScreenToScroll(1,80,18,25);    
   InitializeBreakProc;
END OnceInit;


PROCEDURE Init;
BEGIN
   TutorMode:= FALSE;
   Suggested:= FALSE;
   InitializeBoard(Board);
   WriteBoard;                       
   PrintPips(Board);
   ClearKeyboardBuffer();            
   Wrt;Wrt;
   Randomize;
   q.Die[0]:=6; q.Die[1]:=6; PrintDice(q);
END Init;

(**************************************************************)
(***********     MAIN PROGRAM HERE    *************************)
(**************************************************************)

PROCEDURE SpecialCheck(VAR S:INTEGER;VAR Board:BoardType;
                       VAR DiceFlag,CTurn,Suggested,TutorMode:BOOLEAN): BOOLEAN;
VAR Ch : CHAR;
BEGIN
   IF (S>=4)AND(S<=12) THEN
      CTurn:= NOT CTurn;  DiceFlag:= FALSE;
   END;
   CASE S OF
      1 : RETURN TRUE |
      2 : Setup(Board);
          Wrt;Ch:= Message('  Who Goes Next? [H]uman or [C]omputer :','H','C');
          IF CAP(Ch)='H' THEN CTurn:=TRUE ELSE CTurn:=FALSE END;|
      3 : Swap(Board) |
      4 : Mirror(Board) |
      5 : Suggested:=TRUE |
      6 : Redraw(Board) |
      7 : Color    |
      8 : CTurn := NOT CTurn; AutoPlay; CTurn:= NOT CTurn |
      9 : TutorMode:= NOT TutorMode |
     10 : TellScore |
     11 : Help |
     12 : (* Linda *) DiceFlag:= TRUE |
   ELSE END;
   RETURN FALSE;
END SpecialCheck;

PROCEDURE AutoPlay;
VAR Fred : BOOLEAN;
    Pause: BOOLEAN;
BEGIN
   ClearKeyboardBuffer;
   Ch := Message('  Do you want a pause between moves in automove mode? (Y or N) ','N','Y');
   IF Ch='Y' THEN
      Pause := TRUE;
   ELSE
      Wrt;WriteColorString('  < Push any key to exit automove mode >',MColor);Wrt;
      Pause := FALSE;
   END;
   ClearKeyboardBuffer;
   LOOP
      IF Pause THEN
         Wrt;WriteColorString('  [ESC] exits automove, or any other key to continue',MColor);Wrt;
         ClearKeyboardBuffer;  Read(Ch); IF Ch=33C THEN EXIT; END;
      ELSE
         IF KeyPressed() THEN ClearKeyboardBuffer; EXIT END;
      END;
      CASE CTurn OF
         TRUE :GetRandomDice(q);    PrintDice(q);
               ShowDice(q,'  Computers dice roll ¯> ',CColor);
               MoveComputer(q); |
         FALSE:GetRandomDice(q);    PrintDice(q);
               ShowDice(q,'  Humans dice roll ¯> ',PColor);
               IF NoLegalMove(q,Board) THEN
                  Error('Sorry you have no legal move available.');
               ELSE
                  Suggest(Board,q);
                  Wrt;WriteColorString('  Your Move Is (Y)¯> ',PColor);
                  DisplayMove1(q,PColor);Wrt;
               Fred :=  MovePerson(q);
               END;
      END;
      PrintPips(Board);
      IF EndOfGame(Board) THEN EXIT END;
      CTurn:=NOT CTurn;
   END;
END AutoPlay;


PROCEDURE AutoRoll;
VAR a,b: CARDINAL;
BEGIN
   REPEAT GetRandomDice(q) UNTIL (q.Die[0]#q.Die[1]);
   DiceFlag := FALSE;
   IF RandomCard(2)=0 THEN CTurn:=TRUE ELSE CTurn:=FALSE END;
   LOOP (* main program loop if auto roll*)
      CASE CTurn OF
         TRUE :GetRandomDice(q);
               PrintDice(q);
               ShowDice(q,'  Computers dice roll ¯> ',CColor);
               MoveComputer(q); |
         FALSE:GetRandomDice(q);
               PrintDice(q);
               REPEAT ShowDice(q,'  Your dice roll ¯> ',PColor);
                  IF NoLegalMove(q,Board) THEN
                     Error('Sorry you have no legal move available. Press a key to continue ');
                     Special:=99; ClearKeyboardBuffer(); Read(Ch); 
                  ELSE
                     IF (Suggested)OR(TutorMode) THEN
                        Suggested:= FALSE;
                        Suggest(Board,q);
                        Wrt;WriteColorString('  I suggest ¯> ',CColor);
                        DisplayMove1(q,PColor);
                        DisplayMove2(q,PColor);
                     END;
                     ReadPlayerMove(q,Special);
                     IF SpecialCheck(Special,Board,DiceFlag,CTurn,
                                     Suggested,TutorMode) THEN EXIT END;
                  END;
               UNTIL ( (Special>0) OR MovePerson(q) );
      END;
      PrintPips(Board);
      IF EndOfGame(Board) THEN EndDialog(Board); EXIT END;
      CTurn:=NOT CTurn;
   END;
END AutoRoll;


PROCEDURE ManualRoll;
BEGIN
   ClearKeyboardBuffer();
   Wrt;Ch:= Message('  Who Goes First? [H]uman or [C]omputer :','H','C');
   IF CAP(Ch)='C' THEN CTurn:=TRUE ELSE CTurn:=FALSE END;
   LOOP (* main program loop if manual roll *)
      CASE CTurn OF
         TRUE :REPEAT UNTIL ReadDice(q,CColor,'  Enter Computer Dice ¯> ');
               PrintDice(q);
               MoveComputer(q); |
         FALSE:REPEAT 
                  REPEAT UNTIL ReadDice(q,PColor,'  Enter Your Dice ¯> ');
                  PrintDice(q);
                  IF NoLegalMove(q,Board) THEN
                     Error('Sorry you have no legal move available. Press a key to continue ');
                     Special:=99; ClearKeyboardBuffer(); Read(Ch); 
                  ELSE
                     IF (Suggested)OR(TutorMode) THEN 
                        Suggested:=FALSE; Suggest(Board,q);
                        Wrt;WriteColorString('  I suggest ¯> ',CColor);
                        DisplayMove1(q,PColor);
                        DisplayMove2(q,PColor);
                     END;
                     ReadPlayerMove(q,Special);
                     IF SpecialCheck(Special,Board,DiceFlag,CTurn,
                                     Suggested,TutorMode) THEN EXIT END;
                  END;
               UNTIL ( (Special>0) OR MovePerson(q) );
               Special :=0;
      END;     
      PrintPips(Board);
      IF EndOfGame(Board) THEN EndDialog(Board); EXIT END;
      CTurn:=NOT CTurn;
   END;
END ManualRoll;


BEGIN 
   OnceInit;
   LOOP
      Init;
      WriteColorString('  < PUSH [ESC] AT ANY TIME FOR HELP ON MOVING OR COMMANDS >',EColor);
      Wrt;Ch:= Message('      Would you like me to roll the dice? [Y or N]:','Y','N');
      IF CAP(Ch)='N' THEN ManualRoll ELSE AutoRoll END;
      ClearKeyboardBuffer();
      Wrt;Ch:= Message('  Would you like to play again? [Y or N]:','Y','N');
      IF CAP(Ch)='N' THEN EXIT END;
   END;
   BreakProc;
END Backgammon.






