IMPLEMENTATION MODULE Parse;

FROM Types IMPORT DiceRec,BoardType;

VAR I : CARDINAL;


PROCEDURE ParseMove(S:ARRAY OF CHAR;VAR q:DiceRec);
VAR Count,From,Num : INTEGER; Seperator,Seperator2 : CHAR;

   PROCEDURE GetChar(VAR Ch: CHAR);
   BEGIN
      Ch := 0C;   IF I<80 THEN Ch := S[I]; INC(I); END;
   END GetChar;

   PROCEDURE GetNonBlank(VAR Ch: CHAR);
   BEGIN
      Ch := 0C;
      IF I<80 THEN
         REPEAT  Ch := S[I]; INC(I); UNTIL (Ch#' ')OR(I>=80)
      END;
   END GetNonBlank;

   PROCEDURE ReadNum(VAR Num : INTEGER;VAR Ch : CHAR);
   BEGIN
      Num:=0;
      GetNonBlank(Ch);IF CAP(Ch)='B' THEN Ch:='0' END;
      IF CAP(Ch)='.' THEN Num:= 999; RETURN END;
      WHILE (Ch>='0')AND(Ch<='9')AND(Num<3275) DO
         Num:=Num*10+INTEGER(ORD(Ch))-48;
         GetChar(Ch);
      END;
   END ReadNum;

BEGIN
   I := 0;
   FOR Count:=0 TO 3 DO 
      q.Move[0,Count]:=0;q.Move[1,Count]:=0;
   END;
   q.Moves:=0;
   IF HIGH(S)<2 THEN RETURN END;
   REPEAT
      ReadNum(Num,Seperator);
      WHILE (Num=999) DO (* special processing for '.' *)
         IF (q.Moves>0)AND (q.Moves<4) THEN
            q.Move[0,q.Moves]:= q.Move[0,q.Moves-1]; 
            q.Move[1,q.Moves]:= q.Move[1,q.Moves-1];
            INC(q.Moves);
            ReadNum(Num,Seperator);
         ELSE RETURN
         END;
      END;
      IF (Seperator=' ') THEN  GetNonBlank(Seperator) END;
      WHILE ((Seperator='/')OR(Seperator='-'))AND(q.Moves<4) DO
         From := Num;
         ReadNum(Num,Seperator2);
         IF Seperator='/' THEN Num:= Num+ From END;
         Seperator:= Seperator2;
         q.Move[0,q.Moves]:=From; q.Move[1,q.Moves]:=Num;
         INC(q.Moves);
      END;   
   UNTIL (Seperator#' ')OR(q.Moves>3);
END ParseMove;


END Parse.
