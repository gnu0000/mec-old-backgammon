/*
 *
 * bg.c
 * Sunday, 6/13/1993.
 *
 */

#include <os2.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef double BIG;
#define MINBG 1e-10

#define BAR 0;
#define OUT 25;
#define ELEMENTS 26

typedef int BOARD[2][ELEMENTS];

typedef int DICE[4];
typedef int MOVE[4];

#define HOMEBLOCKS1  0
#define HOMEBLOCKS2  1
#define HOMEBLOCKS3  2
#define HOMEBLOCKS4  3
#define HOMEBLOCKS5  4
#define HOMEBLOCKS6  5

int hu [10] = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1};

int hublk [25];


/******************************************************************/
/*                                                                */
/*  Calculate Board Strength                                      */
/*                                                                */
/******************************************************************/

/*
 * returns chance that piece may be hit
 * returns 0 to 1
 * checks to see if opponent has pieces on bar
 */
BIG ChanceToHit (int Who, BOARD brd, int iSpot)
   {
   BIG bg = 0;
   int iOSpot, Die0, Die1;

   iOSpot = 25 - iSpot;
   for (Die0 = 1; Die0 < 7; Die0++)
      for (Die1 = 1; Die1 < 7; Die1++)
         {
         if (brd[1-Who][iOSpot-Die0] ||
             brd[1-Who][iOSpot-Die1] ||
             (brd[1-Who][iOSpot-Die0-Die1] &&
               (brd[Who][25-(iOSpot-Die0)] < 2 ||
                brd[Who][25-(iOSpot-Die1)] < 2)))
            bg += 1.0/36.0;
         }
   return bg;
   }


/*
 * This fn returns the number of
 * blocks in Who's home
 */
int HomeBlocks (int Who, BOARD brd)
   {
   int i, iRet = 0;

   for (i=19; i<25; i++)
      iRet += !!(brd[Who][i] > 1);
   return iRet;
   }


BOOL PipsInteracting (BOARD brd)
   {
   int i;

   for (i=1; i<25; i++)
      {
      if (brd[0][i])
         break;
      }
   for (i=25-i; i; i--)
      if (brd[1][i])
         return TRUE;
   return FALSE;
   }


BOOL InHome (int Who, BOARD brd)
   {
   int i;

   for (i=1; i<19; i++)
      if (brd[Who][i])
         return FALSE;
   return TRUE;
   }


void ShowMove (int Who, BOARD brd, MOVE move, DICE dice, int i)
   {
   return;
   }
















/*
 * This fn calculates the point count of each of the pips
 * This is a simple distance from start sum of pips
 */
BIG PipPoints (int Who, BOARD brd)
   {
   BIG bg = 0;
   int i;

   for (i=1; i<26; i++)
      bg += brd[Who][i] * i;
   return bg;
   }


/*
 * This fn calculates the point count for a pip on the bar
 * This value depends on how many blocks are in the home base
 * and how many pips are on the bar
 */
BIG HitPoint (int Who, BOARD brd, int iBlocks, int iHits)
   {
   BIG bg = 0;

   if (iHits == 1)
      bg = 0 - 3;
   else
      bg = 0 - 5 * (iHits-1);

   switch (iBlocks)
      {
      case 0: break;
      case 1: bg -= iHits * hu[HOMEBLOCKS1]; break;
      case 2: bg -= iHits * hu[HOMEBLOCKS2]; break;
      case 3: bg -= iHits * hu[HOMEBLOCKS3]; break;
      case 4: bg -= iHits * hu[HOMEBLOCKS4]; break;
      case 5: bg -= iHits * hu[HOMEBLOCKS5]; break;
      case 6: bg -= iHits * hu[HOMEBLOCKS6]; break;
      }
   /*--- could do more about contiguous blocks going past spot#6 ---*/
   return bg;
   }


/*
 * This fn calculates the point count for pips on the bar
 * This value depends on how many blocks are in the home base
 * and how many pips are on the bar
 */
BIG HitPoints (int Who, BOARD brd)
   {
   int iBlocks, iHits;

   if (!brd[Who][0])
      return 0;

   iBlocks = HomeBlocks (1-Who, brd);
   iHits   = brd[Who][0];

   return HitPoint (Who, brd, iBlocks, iHits);
   }



/*
 * This fn calculates value for blocks
 * The value of a block is dependent on:
 *    its position   - home and 18 pt is best
 *    #pips in block - 2 pips is best
 *
 */
BIG BlockPoints (int Who, BOARD brd)
   {
   BIG bg = 0;
   int i;

   for (i=1; i<25; i++)
      {
      /*--- points for blocks ---*/
      if (brd[Who][i] > 1)
         bg += hublk[i];

      /*--- remove points for stacked blocks ---*/
      if (brd[Who][i] > 2)
         bg -= brd[Who][i] - 2;
      }
   return bg;   
   }


/*
 * This fn calculates value for open pips
 * results will be negative
 * value for open pip depends on:
 *    piece value
 *    chance to be hit
 *    usefulness on next turn?
 */
BIG OpenPoints (int Who, BOARD brd)
   {
   BIG bg = 0;
   int iBlocks, iHits, i;

   iBlocks = HomeBlocks (1-Who, brd);
   iHits   = brd[Who][0];

   for (i=1; i<25; i++)
      {
      if (brd[Who][i] != 1)
         continue;

      bg -= ChanceToHit (Who, brd, i) * 
            (i + HitPoint (Who, brd, iBlocks, iHits + 1));
      }
   return bg;
   }


/*
 *
 * This fn gives points for leaving pips in opponents 
 * home. Points will be negative.
 */
BIG BackPoints (int Who, BOARD brd)
   {
   BIG bg = 0;
   int i;

   for (i=1; i<7; i++)
      {
      if (brd[Who][i] == 1)
         bg -= (7.0 - i);
      }
   return bg;
   }


/*
 * Points for taking off pieces
 * A point value is given for each pip taken off the board
 */
BIG OffPoints (int Who, BOARD brd)
   {
   return (BIG) brd[Who][25] * 3;
   }

/*
 * Points for taking off pieces
 * A point value is given for each pip taken off the board
 * this one is with no interaction
 */
BIG OffPoints2 (int Who, BOARD brd)
   {
   return (BIG) brd[Who][25] * 7;
   }



/*
 * Points for spreading out pieces and keeping blocks even
 * this only applies after no intersection of players
 */
BIG GoingOutPoints (int Who, BOARD brd)
   {
   BIG bg = 0;
   int i, iCt;

   for (i=1; i<24; i++)
      {
      iCt = brd[Who][i];
      if (!iCt)
         {
         bg -= 2;
         continue;
         }
      bg += 2;          /*--- spread out bonus ---*/

      if (iCt > 2)
         bg -= ((iCt-2) /(50/25-iCt));
      }
   return bg;
   }



/*
 * This fn calculates pips out of home
 * point totals are negative
 */
BIG OutOfHome (int Who, BOARD brd)
   {
   BIG bg = 0;
   int i;

   for (i=1; i<19; i++)
      if (brd[Who][i])
         bg -= 5 + (19 - i);
   return bg;
   }



/*
 * This fn returns the strength of the players position
 * for player "Who" 
 *
 * to do:
 *   points for future block material
 *
 */
BIG CalcBoardValue (int Who, BOARD brd)
   {
   BIG bg = 0;

   /*--- One method if pips are interacting ---*/
   if (PipsInteracting (brd))
      {
      /*--- straight count of piece values ---*/
      bg = PipPoints (Who, brd) - PipPoints (1-Who, brd);

      /*--- points for pips on the bar ---*/
      bg = HitPoints (Who, brd) - HitPoints (1-Who, brd);


      /*--- points for blockades ---*/
      bg += BlockPoints(Who, brd) - BlockPoints (1-Who, brd);

      /*--- points for open pieces (negative) ---*/
      bg += OpenPoints (Who, brd) - OpenPoints (1-Who, brd);

      /*--- points for leaving points back ---*/
      bg += BackPoints (Who, brd) - BackPoints (1-Who, brd);

      /*--- extra points for taking pips off ---*/
      bg += OffPoints (Who, brd) - OffPoints (1-Who, brd);
      }

   /*-- another method if not interacting   ---*/
   else
      {
      /*--- if in home base, try to take off and keep even ---*/
      if (InHome (Who, brd))
         {
         /*--- main goal is to take off points ---*/
         bg  = OffPoints2 (Who, brd);

         /*--- we also want to spread blocks and keep even ---*/
         bg += GoingOutPoints (Who, brd);
         }
      /*--- try to get pieces home and keep even ---*/
      else
         {
         /*--- main goal is to get points to home ---*/
         bg  = OutOfHome (Who, brd);

         /*--- we also want to spread blocks and keep even ---*/
         bg += GoingOutPoints (Who, brd);
         }
      }
   return bg;
   }



/******************************************************************/
/*                                                                */
/*  Enumerate Moves                                               */
/*                                                                */
/******************************************************************/

int MoveErr (int Who, BOARD brd, int iSpot, int iDie)
   {
   int i;

   if (iSpot < 0 || iSpot > 24 || iDie < 1 || iDie > 6)
      return 1;

   if (!brd[Who][iSpot])         /*--- no piece here to move ---*/
      return 2;

   if (brd[1-Who][25-iSpot] > 1) /*--- >1 enemy pip in dest  ---*/
      return 3;

   if (brd[Who][0] && iSpot)     /*--- if on bar, must be 1st ---*/
      return 4;

   if (iSpot + iDie > 24 && !InHome (Who, brd))  /*--- cant take off ---*/
      return 5;

   if (iSpot + iDie > 25)        /*--- cant waste dice pts if possible ---*/
      for (i = iSpot-1; i > 18; i--)
         if (brd[Who][i])
            return 6;

   return 0;
   }


void CopyBoard (BOARD brdDest, BOARD brdSrc)
   {
   memcpy (brdDest, brdSrc, sizeof (int) * ELEMENTS * 2);
   }


void MakeMove (int Who, BOARD brd, int iSpot, int iDie)
   {
   int iDest;

   (brd[Who][iSpot])--;
   iDest = min (25, iSpot + iDie);
   (brd[Who][iDest])++;
   if (iDest < 25 && brd[1-Who][25 - iDest]) /*--- check for a hit ---*/
      {
      (brd[1-Who][25 - iDest])--;
      (brd[1-Who][0])++;
      }
   }




BOARD tmpbrd[4];


BIG DieMove (int Who, BOARD brd, int move[], DICE dice, int iMove, int iDie)
   {
   int i;
   BIG bg, bgBest = MINBG;

   for (i=i; i<25; i++)
      {
      if (MoveErr (Who, brd, i, dice[iDie]))
         continue;
      CopyBoard (tmpbrd[iMove], brd);
      MakeMove (Who, tmpbrd[iMove], i, dice[iDie]);

      if (iMove)
         bg = DieMove (Who, tmpbrd[iMove], move, dice, iMove-1, iDie-1);
      else
         bg = CalcBoardValue (Who, tmpbrd[iMove]);

      if (bg > bgBest)
         {
         bgBest = bg;
         move[iDie] = i;
         }

      /*-- if non doubles , try swapping dice --*/
      if (iMove == 1 && !dice[2]) 
         {
         if (MoveErr (Who, brd, i, dice[0]))
            continue;
         CopyBoard (tmpbrd[iMove], brd);
         MakeMove (Who, tmpbrd[iMove], i, dice[0]);
         bg = DieMove (Who, tmpbrd[iMove], move, dice, 0, 1);

         if (bg > bgBest)
            {
            bgBest = bg;
            move[0] = i;
            }
         }
      }
   return bg;
   }


int ComputerMove (int Who, BOARD brd, DICE dice, MOVE move)
   {
   int i;

   for (i = (dice[2] ? 4 : 2); i; i--)
      {
      /*--- move as many dice as possible ---*/
      if (DieMove (Who, brd, move, dice, i-1, i-1) > MINBG)
         return ShowMove (Who, brd, move, dice, i-1);
      }
   return 0;
   }



int main (int argc, char *argv[])
   {
   BOARD brd;


   brd[1][24] = 1;
   
   return 0;
   }

