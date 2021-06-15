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

   yBase = (i < 13 ? 3 : 14);
   yInc  = (i < 13 ? 1 : -1);
   if (i < 13)
      xBase = (iPos + !!(iPos > 6)) * 5 - 1;
   else
      xBase = 70 - (iPos - !!(iPos < 18)) * 5 - 1;

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
      GnuPaint (NULL, 3+i, 0, 0, 0, " บ                              บ   บ                              บ");
   GnuPaint (NULL, 15, 0, 0, 0, " ศออออออออออออออออออออออออออออออสอออสออออออออออออออออออออออออออออออผ");
   GnuPaint (NULL, 16, 0, 0, 0, "    24   23   22   21   20   19        18   17   16   15   14   13  ");
   }


