/*
 * bg.h
 *
 *
 */

#define MINBG -10000

#define BAR 0;
#define OUT 25;
#define ELEMENTS 26


typedef double BIG;

typedef int BOARD[2][ELEMENTS];

typedef int DICE[2];
typedef int MOVE[2][4];  /*-- 0= pos, 1= die --*/


/**********************************************************************/
/*                                                                    */
/*                                                                    */
/*                                                                    */
/**********************************************************************/


/**********************************************************************/
/*                                                                    */
/* Logic                                                              */
/*                                                                    */
/**********************************************************************/
int ComputerMove (int Who, BOARD brd, DICE dice, MOVE move);
int MoveErr (int Who, BOARD brd, int iSpot, int iDie);
BIG CalcBoardValue (int Who, BOARD brd);
void InitPips (BOARD brd);
void InitHeuristics (void);



/**********************************************************************/
/*                                                                    */
/* Display                                                            */
/*                                                                    */
/**********************************************************************/
void PaintBoard (void);
void PaintPips (BOARD brd);
void PaintDice (DICE dice);


/**********************************************************************/
/*                                                                    */
/* Parse                                                              */
/*                                                                    */
/**********************************************************************/
BOOL GetPersonMove (MOVE move);

