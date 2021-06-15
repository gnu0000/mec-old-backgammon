/*
 *
 * backgamm.c
 * Monday, 6/14/1993.
 *
 */

#define INCL_VIO
#include <os2.h>
#include <stdio.h>
#include <stdlib.h>
#include <GnuScr.h>
#include "Backgamm.h"


PGW pgw = NULL;


void RollDice (DICE dice)
   {
   dice [0] = rand () % 6 + 1;
   dice [1] = rand () % 6 + 1;
   }

void GameSetup (BOARD brd)
   {
   InitPips (brd);
   InitHeuristics ();
   }


BOOL PlayGame (void)
   {
   BOARD brd;
   DICE  dice;
   MOVE  move;

   GameSetup (brd);
   GnuClearWin (NULL, ' ', 0, FALSE);
   PaintBoard ();
   PaintPips (brd);

   RollDice (dice);
   PaintDice (dice);
   ComputerMove (0, brd, dice, move);
   PaintPips (brd);

   RollDice (dice);
   PaintDice (dice);
   ComputerMove (1, brd, dice, move);
   PaintPips (brd);

   return FALSE;
   }

void Cleanup (void)
   {
//   GnuDestroyWin (pgw);
   GnuMoveCursor (NULL, 23, 0);
   }

void OneTimeSetup (void)
   {
   srand (0);
   ScrInitMetrics ();

//   GnuPaintAtCreate (FALSE);
   pgw = GnuCreateWin2 (18, 0, 6, 80, NULL);
//   pgw->bShadow = FALSE;
//   GnuPaintAtCreate (TRUE);
   gnuFreeDat (pgw);
   GnuClearWin (pgw, ' ', 0, TRUE);
   }

int main (int argc, char *argv[])
   {
   OneTimeSetup ();
   while (PlayGame ())
      ;
   Cleanup ();
   return 0;
   }

