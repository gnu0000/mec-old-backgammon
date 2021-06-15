/*
 *
 * Display.c
 * Monday, 6/14/1993.
 *
 */

#define INCL_VIO
#include <os2.h>
#include <stdio.h>
#include <stdlib.h>
#include <gnuscr.h>
#include "Backgamm.h"


void PaintDiamond (int iPos, int iChar, int iCount)
   {
   int i, xBase, yBase, x, y, yInc;

   yBase = (iPos < 13 ? 3 : 14);
   yInc  = (iPos < 13 ? 1 : -1);
   if (iPos < 13)
      xBase = (iPos + !!(iPos > 6)) * 5 - 1;
   else
      xBase = ((25-iPos) + !!(iPos < 19)) * 5 - 1;

   if (iPos == 0 || iPos == 25)
      xBase = 34;

   for (i=0; i<iCount; i++)
      {
      x = xBase + !!(i>4) - !!(i>9)*2;
      y = yBase + (i % 5) * yInc;
      GnuPaintNChar (NULL, y, x, 0, 1, (CHAR)iChar, 1);
      }

   for (i=iCount; i<16; i++)
      {
      x = xBase + !!(i>4) - !!(i>9)*2;
      y = yBase + (i % 5) * yInc;
      GnuPaintNChar (NULL, y, x, 0, 1, ' ', 1);
      }
   }


void PaintPips (BOARD brd)
   {
   int i;

   for (i=0; i<25; i++)
      {
      if (brd[0][i])
         PaintDiamond (i, 'X', brd[0][i]);
      if (brd[1][i])
         PaintDiamond (25-i, 'O', brd[1][i]);
      }
   }



void PaintBoard ()
   {
   int i;

   GnuPaint (NULL, 1,  0, 0, 0, "    1    2    3    4    5    6         7    8    9    10   11   12  ");
   GnuPaint (NULL, 2,  0, 0, 0, " ษออออออออออออออออออออออออออออออหอออหออออออออออออออออออออออออออออออป");
   for (i=3; i<15; i++)
      GnuPaint (NULL, i, 0, 0, 0, " บ                              บ   บ                              บ");
   GnuPaint (NULL, 15, 0, 0, 0, " ศออออออออออออออออออออออออออออออสอออสออออออออออออออออออออออออออออออผ");
   GnuPaint (NULL, 16, 0, 0, 0, "    24   23   22   21   20   19        18   17   16   15   14   13  ");
   }



void PaintDie (int i, int r)
   {
   PSZ psz, psz2;

   switch (i)
      {
      case 2: case 3: psz="      "; break;
      case 4: case 5: psz="     "; break;
      case 6:         psz="    "; break;
      default:        psz="       ";
      }
   GnuPaint (NULL, r, 72, 0, 2, psz);
   psz2 = (i%2 ? "      " : "       ");
   GnuPaint (NULL, r+1, 72, 0, 2, psz2);

   if (i == 2 || i == 3)
      psz="      ";
   GnuPaint (NULL, r+2, 72, 0, 2, psz);
   }





void PaintDice (DICE dice)
   {
   PaintDie (dice[0], 4);
   PaintDie (dice[1], 10);
   }
