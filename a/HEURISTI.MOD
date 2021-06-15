IMPLEMENTATION MODULE Heuristics; 

(* Heuristics by:  *)
(* Craig           *) 
(* Bhovani         *) 
(* Rhagiv          *) 


FROM Types IMPORT BoardType; 

TYPE    HoldType = ARRAY [0..1],[0..20] OF INTEGER;
CONST   TakeOffIncentive=5;
VAR     BlkVal : ARRAY [0..1],[1..24] OF INTEGER;


PROCEDURE CalculateBoardValue(TempBoard:BoardType;VAR Val: INTEGER);
VAR Count:INTEGER;
BEGIN
   IF Interaction(TempBoard) THEN
      Val:=CPointCount(TempBoard)-PPointCount(TempBoard); (* + takeoffinc*)
      Val:=Val+CBlocks(TempBoard)-PBlocks(TempBoard); (*includes bar eval*)
      Val:=Val+COpen(TempBoard);
      Val:=Val+CBack(TempBoard)-PBack(TempBoard);     (*back incentive*)
   ELSE
      IF InHome(TempBoard) THEN
         Val:=CPointCount(TempBoard); (* + takeoffinc*)
      ELSE
         Val:=COutPointCount(TempBoard); 
      END;
   END;
END CalculateBoardValue;


PROCEDURE CPointCount(TempBoard:BoardType): INTEGER;
VAR Count,Points,Index: INTEGER;
BEGIN
   Points:=0;    Count:=0;
   FOR Index:=1 TO 25 DO
      IF TempBoard[Index]<0 THEN
         Points:=Points-(25-Index)*TempBoard[Index];
         Count:=Count-TempBoard[Index];             (* keep count of pieces*)
      END;
   END;                                             (* pts for removed pieces*)
   IF Count<15 THEN Points:=Points+ (15-Count)*(25+TakeOffIncentive) END;
   RETURN Points;
END CPointCount;


PROCEDURE PPointCount(TempBoard:BoardType): INTEGER;
VAR Count,Points,Index: INTEGER;
BEGIN
   Points:=0;    Count:=0;
   FOR Index:=0 TO 24 DO
      IF TempBoard[Index]>0 THEN
         Points:=Points+Index*TempBoard[Index];
         Count:=Count+TempBoard[Index];             (* keep count of pieces*)
      END;
   END;                                             (* pts for removed pieces*)
   IF Count<15 THEN Points:=Points+ (15-Count)*(25+TakeOffIncentive) END;
   RETURN Points;
END PPointCount;


PROCEDURE CBlocks(TempBoard:BoardType): INTEGER;
VAR Index,Count : INTEGER;
BEGIN
   Count:=0;
   FOR Index:=1 TO 25 DO  (* give points for blocks *)
      IF TempBoard[Index]<-1 THEN
         Count:=Count+BlkVal[0,Index]
      END;
      IF TempBoard[Index]<-2 THEN  (* give minus points for blocks >2 pips *)
         Count:=Count+TempBoard[Index]+2;
      END;
   END;
   IF TempBoard[0]>0 THEN (* give extra pts to home blks if opponent hit*)
      FOR Index:=1 TO 6 DO  (* give points for blocks *)
         IF TempBoard[Index]<-1 THEN
            Count:=Count+TempBoard[0]*3
         END;
      END;
   END;
   RETURN Count;
END CBlocks;


PROCEDURE PBlocks(TempBoard:BoardType): INTEGER;
VAR Index,Count : INTEGER;
BEGIN
   Count:=0;
   FOR Index:=1 TO 25 DO  (* give points for blocks *)
      IF TempBoard[Index]>1 THEN
         Count:=Count+BlkVal[1,Index]
      END;
   END;
   IF TempBoard[25]<0 THEN (* give extra pts to home blks if opponent hit*)
      FOR Index:=19 TO 24 DO  (* give points for blocks *)
         IF TempBoard[Index]>1 THEN
            Count:=Count+3*(-TempBoard[25])
         END;
      END;
   END;
   RETURN Count;
END PBlocks;


PROCEDURE COpen(TempBoard:BoardType): INTEGER;
VAR Index,Count : INTEGER;
    Temp,Temp1 : REAL;Temp2:CARDINAL;
BEGIN
   Count:=0;
   FOR Index:=1 TO 24 DO
      IF TempBoard[Index]=-1 THEN
         Temp:=FLOAT(ChanceToHitC(TempBoard,Index))/18.0;
         Temp1:=FLOAT(25-Index)*Temp;
         CASE NumberPBlocks(TempBoard) OF
            1: Temp1 := Temp1 * 1.5  |
            2: Temp1 := Temp1 * 1.6  |
            3: Temp1 := Temp1 * 1.75 |
            4: Temp1 := Temp1 * 3.0  |
            5: Temp1 := Temp1 * 4.0  |
            6: Temp1 := Temp1 * 7.0
         ELSE END;
         Temp2:=TRUNC(Temp1+0.5);
         Count:=Count-INTEGER(Temp2);
         (* -15 incentive if open man in back court when opponent on bar *)
         IF (Index<7)AND(TempBoard[0]>0) THEN Count:=Count-10; END;
         (* -3 incentive if open man in back court *)
         IF (Index<7) THEN Count:=Count-3; END;
      END;
   END;
   RETURN Count;
END COpen;


(*PROCEDURE COutPointCount(TempBoard:BoardType): INTEGER;
VAR Count,Points,Index: INTEGER;
BEGIN
   Points:=0;    Count:=0;
   IF PPointCount(TempBoard)-CPointCount(TempBoard)>50 THEN (* IF WAY BEHIND*)
      Points := -100     (* dont untangle if possible if way behind*)
   END;
   FOR Index:=25 TO 7 BY -1 DO
      IF TempBoard[Index]<0 THEN
         Points:=Points+(25-Index)*(-TempBoard[Index]);
      END;
   END;
   RETURN Points;
END COutPointCount;*)

PROCEDURE COutPointCount(TempBoard:BoardType): INTEGER;
VAR Points,Index: INTEGER;
BEGIN
   Points:=0;
   IF PPointCount(TempBoard)-CPointCount(TempBoard)>50 THEN (* IF WAY BEHIND*)
      Points := -100     (* dont untangle if possible if way behind*)
   END;
   FOR Index:=25 TO 7 BY -1 DO
      IF TempBoard[Index]<0 THEN
         Points:=Points+(Index-5)*(TempBoard[Index]); (* 2 bonus for take in*)
      END;
   END;
   RETURN Points;
END COutPointCount;


PROCEDURE CBack(TempBoard:BoardType): INTEGER;
VAR Count,Index : INTEGER;
BEGIN
   Count:=0;
   FOR Index:=20 TO 24 DO
      IF TempBoard[Index]<0 THEN
         Count:=Count+TempBoard[Index]*(Index - 19)
      END;
   END;
   RETURN Count ; (* will be negative *)
END CBack;


PROCEDURE PBack(TempBoard:BoardType): INTEGER;
VAR Count,Index : INTEGER;
BEGIN
   Count:=0;
   FOR Index:=1 TO 5 DO
      IF TempBoard[Index]>0 THEN
         Count:=Count-TempBoard[Index]*(6 - Index)
      END;
   END;
   RETURN Count ; (* will be negative *)
END PBack;


PROCEDURE NumberPBlocks(TempBoard:BoardType): INTEGER;
VAR Count,Index : INTEGER;
BEGIN
   Count:=0;
   FOR Index:=19 TO 24 DO
      IF TempBoard[Index]>1 THEN INC(Count) END;
   END;
   RETURN Count;
END NumberPBlocks;


(**************************************************************)


PROCEDURE Interaction(TempBoard:BoardType):BOOLEAN;
VAR  PFound: BOOLEAN;
     Count : INTEGER;
BEGIN
   Count:=0; PFound:=FALSE;
   WHILE (Count<=25) DO
      IF (TempBoard[Count]>0) THEN PFound:=TRUE END;
      IF (TempBoard[Count]<0) AND (PFound) THEN RETURN TRUE END;
      INC(Count)
   END;
   RETURN FALSE 
END Interaction;


PROCEDURE InHome(TempBoard:BoardType):BOOLEAN;
VAR   Count : INTEGER;
BEGIN
   Count:=7;
   WHILE (Count<=25) DO
      IF (TempBoard[Count]<0) THEN RETURN FALSE END;
      INC(Count)
   END;
   RETURN TRUE 
END InHome;


PROCEDURE ChanceToHitC(TempBoard:BoardType; Pos:INTEGER):INTEGER;
VAR Index,Die1,Die2,HoldSize : INTEGER;
    Hold : HoldType;
BEGIN
   HoldSize:=0;
   FOR Index:=0 TO Pos-1 DO (*LOOK AT OPPONENTS PIECES AHEAD OF OPEN PIECE*)
      IF TempBoard[Index]>0 THEN (* place pointed to has piece *)
         FOR Die1 := 1 TO 6 DO   (* FIND ALL DIE COMBINATIONS*)
            FOR Die2 := 1 TO 6 DO
               IF (Index+Die1+Die2<25) THEN
                  IF (Index+Die1+Die2=Pos)AND 
                     ((TempBoard[Index+Die1]>-2)OR(TempBoard[Index+Die2]>-2))OR
                     (Index+Die1=Pos)OR(Index+Die2=Pos) THEN
                     AddToHold(Die1,Die2,HoldSize,Hold);
                  END;
               END;
            END;
         END;
      END;
   END;
(*   GoTo(1,25);WriteString('Chanc=     ');
   GoTo(8,25);WriteInt(HoldSize,1);WriteString(' Pos=');WriteInt(Pos,1); 
   Read(CCCC); *)
   RETURN HoldSize;
END ChanceToHitC;

PROCEDURE ChanceToHitP(TempBoard:BoardType; Pos:INTEGER):INTEGER;
VAR Index,Die1,Die2,HoldSize : INTEGER;
    Hold : HoldType;
BEGIN
   HoldSize:=0;
   FOR Index:=24 TO Pos+1 DO (*LOOK AT OPPONENTS PIECES AHEAD OF OPEN PIECE*)
      IF TempBoard[Index]<0 THEN (* place pointed to has piece *)
         FOR Die1 := 1 TO 6 DO   (* FIND ALL DIE COMBINATIONS*)
            FOR Die2 := 1 TO 6 DO
               IF (Index-Die1-Die2>0) THEN
                  IF (Index-Die1-Die2=Pos)AND 
                     ((TempBoard[Index-Die1]<2)OR(TempBoard[Index-Die2]<2))OR
                     (Index-Die1=Pos)OR(Index-Die2=Pos) THEN
                     AddToHold(Die1,Die2,HoldSize,Hold);
                  END;
               END;
            END;
         END;
      END;
   END;
   RETURN HoldSize;
END ChanceToHitP;


PROCEDURE AddToHold(Die1,Die2:INTEGER;VAR HoldSize:INTEGER;VAR Hold:HoldType);
VAR Count:INTEGER;
    Found : BOOLEAN;
BEGIN
   Found:=FALSE;
   FOR Count:=0 TO HoldSize-1 DO
      IF (Hold[0,Count]=Die1)AND(Hold[1,Count]=Die2)OR
         (Hold[1,Count]=Die1)AND(Hold[0,Count]=Die2)THEN
         Found:=TRUE 
      END;
   END;
   IF NOT Found THEN
      Hold[0,HoldSize]:=Die1;
      Hold[1,HoldSize]:=Die2;
      HoldSize:=HoldSize+1;
   END;
END AddToHold;


(**************************************************************)

PROCEDURE Assign(VAR S:ARRAY OF CHAR; T:ARRAY OF CHAR);
VAR Count: INTEGER;
BEGIN  FOR Count:=0 TO 47 DO   S[Count]:=T[Count] END;
END Assign;

VAR S:ARRAY [0..47] OF CHAR;
    Count: INTEGER;
BEGIN
   Assign(S,'161617181918171614141111111111111117030303030301');
   FOR Count:=0 TO 23 DO
      BlkVal[0,Count+1]:= 10* (ORD (S[2*Count])-48)+
                          ORD(S[2*Count+1])-48
   END;
   Assign(S,'010303030303171111111111111114141617181918171616');
   FOR Count:=0 TO 23 DO 
      BlkVal[1,Count+1]:= 10* (ORD(S[2*Count])-48)+
                          ORD(S[2*Count+1])-48
   END;
END Heuristics.
