/*
 *
 * backgamm.c
 * Monday, 6/14/1993.
 *
 */

#include <os2.h>
#include <stdio.h>
#include <stdlib.h>
#include <GnuScr.h>
#include "Backgamm.h"


BOOL PlayGame ();
   {
   GameSetup ();


   }

void Cleanup ()
   {
   }

void OneTimeSetup ()
   {
   }

int main (int argc, char *argv[])
   {
   OneTimeSetup ();
   while (PlayGame)
      ;
   Cleanup ();
   return 0;
   }

