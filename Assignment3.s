@ CSC230 --  Traffic Light simulation program
@ Latest edition: Fall 2011
@ Author:  Micaela Serra 
@ Modified by: Zachary Seselja  V00775627

@===== STAGE 0
@  	Sets initial outputs and screen for INIT
@ Calls StartSim to start the simulation,
@	polls for left black button, returns to main to exit simulation

        .equ    SWI_EXIT, 		0x11		@terminate program
        @ swi codes for using the Embest board
        .equ    SWI_SETSEG8, 		0x200	@display on 8 Segment
        .equ    SWI_SETLED, 		0x201	@LEDs on/off
        .equ    SWI_CheckBlack, 	0x202	@check press Black button
        .equ    SWI_CheckBlue, 		0x203	@check press Blue button
        .equ    SWI_DRAW_STRING, 	0x204	@display a string on LCD
        .equ    SWI_DRAW_INT, 		0x205	@display an int on LCD  
        .equ    SWI_CLEAR_DISPLAY, 	0x206	@clear LCD
        .equ    SWI_DRAW_CHAR, 		0x207	@display a char on LCD
        .equ    SWI_CLEAR_LINE, 	0x208	@clear a line on LCD
        .equ 	SEG_A,	0x80		@ patterns for 8 segment display
		.equ 	SEG_B,	0x40
		.equ 	SEG_C,	0x20
		.equ 	SEG_D,	0x08
		.equ 	SEG_E,	0x04
		.equ 	SEG_F,	0x02
		.equ 	SEG_G,	0x01
		.equ 	SEG_P,	0x10                
        .equ    LEFT_LED, 	0x02	@patterns for LED lights
        .equ    RIGHT_LED, 	0x01
        .equ    BOTH_LED, 	0x03
        .equ    NO_LED, 	0x00       
        .equ    LEFT_BLACK_BUTTON, 	0x02	@ bit patterns for black buttons
        .equ    RIGHT_BLACK_BUTTON, 0x01
        @ bit patterns for blue keys 
        .equ    Ph1, 		0x0100	@ =8
        .equ    Ph2, 		0x0200	@ =9
        .equ    Ps1, 		0x0400	@ =10
        .equ    Ps2, 		0x0800	@ =11

		@ timing related
		.equ    SWI_GetTicks, 		0x6d	@get current time 
		.equ    EmbestTimerMask, 	0x7fff	@ 15 bit mask for Embest timer
											@(2^15) -1 = 32,767        										
        .equ	OneSecond,	1000	@ Time intervals
        .equ	TwoSecond,	2000
        .equ	SixSecond, 	6000
	@define the 2 streets
	@	.equ	MAIN_STREET		0
	@	.equ	SIDE_STREET		1
 
       .text           
       .global _start

@===== The entry point of the program
_start:		
	@ initialize all outputs
	BL Init				@ void Init ()
	@ Check for left black button press to start simulation
RepeatTillBlackLeft:
	swi     SWI_CheckBlack
	cmp     r0, #LEFT_BLACK_BUTTON	@ start of simulation
	beq		StrS
	cmp     r0, #RIGHT_BLACK_BUTTON	@ stop simulation
	beq     StpS

	bne     RepeatTillBlackLeft
StrS:	
	BL StartSim		@else start simulation: void StartSim()
	@ on return here, the right black button was pressed
StpS:
	BL EndSim		@clear board: void EndSim()
EndTrafficLight:
	swi	SWI_EXIT
	
@ === Init ( )-->void
@   Inputs:	none	
@   Results:  none 
@   Description:
@ 		both LED lights on
@		8-segment = point only
@		LCD = ID only
Init:
	stmfd	sp!,{r0-r2,lr}
	@ LCD = ID on line 1
	mov	r1, #0			@ r1 = row
	mov	r0, #0			@ r0 = column 
	ldr	r2, =lineID		@ identification
	swi	SWI_DRAW_STRING
	@ both LED on
	mov	r0, #BOTH_LED	@LEDs on
	swi	SWI_SETLED
	@ display point only on 8-segment
	mov	r0, #10			@8-segment pattern off
	mov	r1,#1			@point on
	BL	Display8Segment

DoneInit:
	LDMFD	sp!,{r0-r2,pc}

@===== EndSim()
@   Inputs:  none
@   Results: none
@   Description:
@      Clear the board and display the last message
EndSim:	
	stmfd	sp!, {r0-r2,lr}
	mov	r0, #10				@8-segment pattern off
	mov	r1,#0
	BL	Display8Segment		@Display8Segment(R0:number;R1:point)
	mov	r0, #NO_LED
	swi	SWI_SETLED
	swi	SWI_CLEAR_DISPLAY
	mov	r0, #5
	mov	r1, #7
	ldr	r2, =Goodbye
	swi	SWI_DRAW_STRING  	@ display goodbye message on line 7
	ldmfd	sp!, {r0-r2,pc}
	
@ === StartSim ( )-->void
@   Inputs:	none	
@   Results:  none 
@   Description:
@ 		XXX
StartSim:
	stmfd	sp!,{r1-r10,lr}	
@@@@@@ ### code below might be useful? ###
	mov	r1,#1		@initially start in S1.1
StartCarCycle:
	BL	CarCycleStore	@int:R0 CarCycle(State:R1 )
	cmp	r0,#0		@check why it returned
	beq	DoneStartSim	@right black was pressed - end simulation
	mov	r1,r0		@else set input to ped cycle place of call
	BL	PedCycleStore	@void PedCycle( CallPosition:R1);
@	on return from PedCycle, go back to correct state in CarCycle
@	test R1 where the call position to PedCycle came from originally
@	cmp	r1,#3		@if from I3, go back to S1.1
@	beq	S1Car
@	mov	r1,#5		@else restart CarCycle from State S5
@	bal	StartCarCycle
	mov	r1,#1		@restart CarCycle from State S1.1	
	bal	StartCarCycle
@@@@@@ ### code above might be useful? ###	
	
	@THIS CODE WITH LOOP IS NOT NEEDED - TESTING ONLY NOW
	@display a sample pattern on the screen and one state number
	mov	r10,#5			@display state number on LCD
	BL	DrawState
	mov	r10,#3		@ test all patterns eventually
	BL	DrawScreen 	@DrawScreen(PatternType:R10)
	@blink LED on/off every second while waiting for stop simulation	
	mov	r0, #NO_LED
	swi	SWI_SETLED
	mov	r0,r2	@save LED setting
	mov	r0,#OneSecond
	BL	Wait	@void Wait(Delay:r10)
RepeatTillBlackRight:
	mov	r0,r2	@get previous LED setting
	eor	r0,r0, #BOTH_LED
	mov	r2,r0	@save LED setting
	swi	SWI_SETLED
	mov	r10,#OneSecond
	BL	Wait	@void Wait(Delay:r10)
	swi     SWI_CheckBlack
	cmp     r0, #RIGHT_BLACK_BUTTON	@ stop simulation
	bne     RepeatTillBlackRight

DoneStartSim:
	LDMFD	sp!,{r1-r10,pc}



@ ===========================================  Start of CarCycle #################################################################################################
CarCycleStore:
	stmfd	sp!,{lr}
	cmp R5,#101
	bne CarCycle
	beq sec5



CarCycle:		
	mov R7 ,#0 	  @ R7 is the counter for the carcycle in this program
	
	mov R0, #LEFT_LED
	swi	SWI_SETLED

sec1:      @  Section 1 ==============================================
@s1.1
	
	mov r10,#1
	bl DrawState
	bl DrawScreen
	
	mov r10,#TwoSecond  			@ wait two seconds
	bl Wait
	add R7 ,R7, #2
@s1.2
	mov R10,#1
	bl DrawState
	mov R10,#2
	bl DrawScreen

	mov R10,#OneSecond  		@ wait one Second
	bl Wait
	add R7,R7,#1

	cmp R7,#12
	bne sec1
	@========================== Black button checker.
	swi SWI_CheckBlack
	cmp R0 , #RIGHT_BLACK_BUTTON
	beq BlackEx
	@==========================
	@========================== blue button checker. ==================== This is I1 =======================================
	swi SWI_CheckBlue
	cmp R0 , #Ph1
	beq DoneCarCycle2
	cmp R0 , #Ph2
	beq DoneCarCycle2
	cmp R0 , #Ps1
	beq DoneCarCycle2
	cmp R0 , #Ps2
	beq DoneCarCycle2
	@==========================

sec2:  			 @  Section 2 ==============================================
	
	mov r10,#2
	bl DrawState
	mov r10,#1
	bl DrawScreen
	@========================== Black button checker.
	swi SWI_CheckBlack
	cmp R0 , #RIGHT_BLACK_BUTTON
	beq BlackEx
	@==========================
	@========================== blue button checker.==================== This is I2 =======================================
	swi SWI_CheckBlue
	cmp R0 , #Ph1
	beq DoneCarCycle2
	cmp R0 , #Ph2
	beq DoneCarCycle2
	cmp R0 , #Ps1
	beq DoneCarCycle2
	cmp R0 , #Ps2
	beq DoneCarCycle2
	@==========================
	mov r10,#TwoSecond  			@ wait two seconds
	bl Wait

	mov R10,#2
	bl DrawState
	bl DrawScreen
	@========================== Black button checker.
	swi SWI_CheckBlack
	cmp R0 , #RIGHT_BLACK_BUTTON
	beq BlackEx
	@==========================
	@========================== blue button checker.==================== This is I2 =======================================
	swi SWI_CheckBlue
	cmp R0 , #Ph1
	beq DoneCarCycle2
	cmp R0 , #Ph2
	beq DoneCarCycle2
	cmp R0 , #Ps1
	beq DoneCarCycle2
	cmp R0 , #Ps2
	beq DoneCarCycle2
	@==========================
	mov R10,#OneSecond  		@ wait one Second
	bl Wait
	add R7,R7,#1
	@========================== Black button checker.
	swi SWI_CheckBlack
	cmp R0 , #RIGHT_BLACK_BUTTON
	beq BlackEx
	@==========================
	@========================== blue button checker.==================== This is I2 =======================================
	swi SWI_CheckBlue
	cmp R0 , #Ph1
	beq DoneCarCycle2
	cmp R0 , #Ph2
	beq DoneCarCycle2
	cmp R0 , #Ps1
	beq DoneCarCycle2
	cmp R0 , #Ps2
	beq DoneCarCycle2
	@==========================
	cmp R7,#18
	bne sec2

sec3:  					 @  Section 3 ==============================================
	mov r10,#3
	bl DrawState
	bl DrawScreen
	mov r0, #BOTH_LED
	swi	SWI_SETLED  				@ blink both LED
	mov R0, #NO_LED
	swi	SWI_SETLED
	mov r10,#TwoSecond  			@ wait two seconds
	bl Wait
	mov r0, #BOTH_LED
	swi	SWI_SETLED
sec4:  					@  Section 4 ==============================================
	
	mov r10,#4
	bl DrawState  		@ DrawState of sec 4
	bl DrawScreen 		@ DrawScreen of sec 4
	
	mov r10,#OneSecond 			@ wait two seconds
	bl Wait
	mov R7, #0

sec5:					@Section 5 ==============================================
	mov r0, #RIGHT_LED
	swi	SWI_SETLED
	mov r10,#5
	add R7 ,R7, #2 					 
	bl DrawState 		@ DrawState of sec 5
	bl DrawScreen 		@ Draw screen of sec 5
	
	mov r10,#TwoSecond		@ wait six seconds
	bl Wait
	cmp R7,#6
	bne sec5

sec6: 					 @  Section 6 ==============================================
	mov r10,#6
	bl DrawState 		@ draw state of sec 6
	bl DrawScreen 		@ draw screen of sec 6
	
	mov r10,#TwoSecond  			@ wait two seconds
	bl Wait

sec7: 					@  Section 7 ==============================================
	mov r0, #BOTH_LED 		@ turning both LED's on
	swi	SWI_SETLED
	mov r10,#7
	bl DrawState  			@ drawing state 7
	mov r10,#4 				@ drawing screen 7
	bl DrawScreen
	
	mov r10,#OneSecond 			@ wait two seconds
	bl Wait
	
	@========================== Black button checker.
	swi SWI_CheckBlack
	cmp R0 , #RIGHT_BLACK_BUTTON
	beq BlackEx
	@==========================

	@========================== blue button checker. ==================== This is I3 =======================================
	swi SWI_CheckBlue
	cmp R0 , #Ph1
	beq DoneCarCycle1
	cmp R0 , #Ph2
	beq DoneCarCycle1
	cmp R0 , #Ps1
	beq DoneCarCycle1
	cmp R0 , #Ps2
	beq DoneCarCycle1
	@==========================
	bal CarCycle


@ -----------------------This section determines where the interupt came from and if its from a black or blue button 

DoneCarCycle1: 			@ Blue button is hit within Section 3-7
	mov R0,#1
	mov R5,#0
	LDMFD	sp!,{pc}


DoneCarCycle2: 			@ Blue button is hit within Section 1 or 2
	mov R7, #0
	mov R0,#1
	mov R5,#101
	LDMFD	sp!,{pc}

BlackEx: 			@ this is is if the black button is hit
	mov R1 , #0
	mov R0,#0
	LDMFD	sp!,{pc}

@--------------------------
PedCycleStore:
	stmfd	sp!,{lr}
	
	cmp R5,#101  		@ This is the key in the PED cycle
						@ R5 acts as a key to get into the PED detour === ped1: part 1 & part 2
	beq ped1 			    @ branching to Ped1 if its from I1, or I2.
	bne PedCycle
PedCycle:
	
	
	mov R3,#0 		    @ loading 0 into R3//// R3 acts as a counter for the PED Cycle
	mov R6,#6 		    @ couning down with R6
ped3:                        @---------ped3 should loop 4 times
	mov r10,#10	         @ move 10 into r10
	bl DrawState            @ DrawState of ped3
	mov r10,#7              @ Move 7 into r10
	mov R0,R6 		    @ counting down fro 6 to 3
	bl Display8Segment 	    @ then printing it in the seg 8 box
	bl DrawScreen  	    @drawing screen
	add R3, R3 ,#1 	    @ incrementation of counter
	mov r10,#OneSecond	    @ Move one sec into r10
	bl Wait                 @ wait one second * 4
	sub R6,R6,#1 		    @ deincrementation
	cmp R3 ,#4 		    @ compare R3 to # 4
	bne ped3			    @ if R3 is not 4 then branch to ped3
ped4:                        @---------ped4 should loop 4 times
	mov R0,R6			    @ counting down fro 2 to 1
	bl Display8Segment      @ Set the number counter
	mov r10,#11 		    @ move 11 into r10
	bl DrawState 		
	mov r10,#8              @ move 8 into R10
	bl DrawScreen           @ DrawScreen of ped4
	
	mov r10,#OneSecond      @ move 0ne sec into R10
	bl Wait                 @wait one sec
	add R3, R3 ,#1

	
	sub R6,R6,#1
	cmp R3 ,#6              @ compare r3 to # 6
	bne ped4  		    @ if R3 is not 6 then branch to ped4
ped5:                        @---------ped5 should not loop
	mov R0,R6 
     bl Display8Segment
	mov r10,#12
	bl DrawState
	mov r10,#4
	bl DrawScreen
	
	mov r10,#OneSecond 			@ wait two seconds
	bl Wait
	@========================== Black button checker. ==================== This is I4 =======================================
	swi SWI_CheckBlack
	cmp R0 , #RIGHT_BLACK_BUTTON
	beq BlackEx
	@==========================
	mov R0,#10 
     bl Display8Segment            @ makes Segment8 Blank
	cmp R5,#101                   @ compares to see if Interupt came from 1,2 or 3
	beq DoneCarCycle2             @ goes to sec5
	bne DoneCarCycle1             @ goes to carcycle (sec1)



@====== if the interupt comes from I1 or I2
ped1:
@ part 1
	mov r10,#8
	bl DrawState
	mov r10,#7
	bl DrawScreen
	
	mov r10,#TwoSecond  			@ wait two seconds
	bl Wait

@ part 2
	mov r10,#9
	bl DrawState
	mov r10,#4
	bl DrawScreen
	
	mov r10,#OneSecond 			@ wait two seconds
	bl Wait
	bal PedCycle


@===================== End Of PED Cycle------------------------------------------------------------------------------------------

@ ==== void Wait(Delay:r10) 
@   Inputs:  R10 = delay in milliseconds
@   Results: none
@   Description:
@      Wait for r10 milliseconds using a 15-bit timer 
Wait:
	stmfd	sp!, {r0-R2,r7-r10,lr}
	ldr     r7, =EmbestTimerMask
	swi     SWI_GetTicks		@get time T1
	and		r1,r0,r7			@T1 in 15 bits
WaitLoop:
	swi SWI_GetTicks			@get time T2
	and		r2,r0,r7			@T2 in 15 bits
	cmp		r2,r1				@ is T2>T1?
	bge		simpletimeW
	sub		r9,r7,r1			@ elapsed TIME= 32,676 - T1
	add		r9,r9,r2			@    + T2
	bal		CheckIntervalW
simpletimeW:
		sub		r9,r2,r1		@ elapsed TIME = T2-T1
CheckIntervalW:
	cmp		r9,r10				@is TIME < desired interval?
	blt		WaitLoop
WaitDone:
	ldmfd	sp!, {r0-r2,r7-r10,pc}	
	
@ ==== int:R0 WaitAndPoll(Delay:r10) 
@   Inputs:  R10 = delay in milliseconds
@   Results:	0=>interval finished
@				-1=>stop simulation (right black button)
@				1=>blue button number for pedestrian requestl
@   Description:
@      Wait for r10 milliseconds using a 15-bit timer while polling
@		Stay for the interval unless there is a pedestrian request 
@		(blue button or an end of simulation request (right black button)
WaitAndPoll:
	stmfd	sp!,{r1-r10,lr}
	NOP
DoneWaitAndPoll:
	LDMFD	sp!,{r1-r10,pc}

@ *** void Display8Segment (Number:R0; Point:R1) ***
@   Inputs:  R0=bumber to display; R1=point or no point
@   Results:  none
@   Description:
@ 		Displays the number 0-9 in R0 on the 8-segment
@ 		If R1 = 1, the point is also shown
Display8Segment:
	STMFD 	sp!,{r0-r2,lr}
	ldr 	r2,=Digits
	ldr 	r0,[r2,r0,lsl#2]
	tst 	r1,#0x01 @if r1=1,
	orrne 	r0,r0,#SEG_P 			@then show P
	swi 	SWI_SETSEG8
	LDMFD 	sp!,{r0-r2,pc}
	
@ *** void DrawScreen (PatternType:R10) ***
@   Inputs:  R10: pattern to display according to state
@   Results:  none
@   Description:
@ 		Displays on LCD screen the 5 lines denoting
@		the state of the traffic light
@	Possible displays:
@	1 => S1.1 or S2.1- Green High Street
@	2 => S1.2 or S2.2	- Green blink High Street
@	3 => S3 or P1 - Yellow High Street   
@	4 => S4 or S7 or P2 or P5 - all red
@	5 => S5	- Green Side Road
@	6 => S6 - Yellow Side Road
@	7 => P3 - all pedestrian crossing
@	8 => P4 - all pedestrian hurry

@@@ NOTE: State number on upper right corner is shown
@@@ 		by procedure void DrawState (PatternType:R10)
@@@			called from within each state before calling
@@@			this DrawScreen
DrawScreen:
	STMFD 	sp!,{r0-r2,lr}  		@ switch board function to draw different screens depending on R10
	cmp	r10,#1
	beq	S11
	cmp	r10,#2
	beq	S12
	cmp	r10,#3
	beq	S3
	cmp r10,#4
	beq S4
	cmp r10,#5
	beq S5
	cmp r10,#6
	beq S6
	cmp r10,#7
	beq P3
	cmp r10,#8
	beq P4
	bal	EndDrawScreen






S11:
	ldr	r2,=line1S11
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3S11
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5S11
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen
S12:
	ldr	r2,=line1S12
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3S12
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5S12
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen
S3:
	ldr	r2,=line1S3
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3S3
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5S3
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen
S4:
	ldr	r2,=line1S4
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3S4
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5S4
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen

S5:
	ldr	r2,=line1S5
	mov	r1, #6		@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3S5
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5S5
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen

S6:
	ldr	r2,=line1S6
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3S6
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5S6
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen	

P3:
	ldr	r2,=line1P3
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3P3
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5P3
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen	
P4:
	ldr	r2,=line1P4
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3P4
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5P4
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen	




@ MORE PATTERNS TO BE IMPLEMENTED
EndDrawScreen:
	LDMFD 	sp!,{r0-r2,pc}
	
@ *** void DrawState (PatternType:R10) ***
@   Inputs:  R10: number to display according to state
@   Results:  none
@   Description:
@ 		Displays on LCD screen the state number
@		on top right corner
DrawState:
	STMFD 	sp!,{r0-r2,lr}   					@ switch board function for DrawState to go to different subruteens depending on R10
	cmp	r10,#1
	beq	S1draw
	cmp	r10,#2
	beq	S2draw
	cmp	r10,#3
	beq	S3draw
	cmp r10,#4
	beq S4draw
	cmp r10,#5
	beq S5draw
	cmp r10,#6
	beq S6draw
	cmp r10,#7
	beq S7draw
	cmp r10,#8
	beq P1draw
	cmp r10,#9
	beq P2draw
	cmp r10,#10
	beq P3draw
	cmp r10,#11
	beq P4draw
	cmp r10,#12
	beq P5draw				



	bal	EndDrawScreen
S1draw:
	ldr	r2,=S1label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
S2draw:
	ldr	r2,=S2label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
S3draw:
	ldr	r2,=S3label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
S4draw:
	ldr	r2,=S4label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
S5draw:
	ldr	r2,=S5label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
S6draw:
	ldr	r2,=S6label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
S7draw:
	ldr	r2,=S7label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
P1draw:
	ldr	r2,=P1label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState		
P2draw:
	ldr	r2,=P2label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState				
P3draw:
	ldr	r2,=P3label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState	

P4draw:
	ldr	r2,=P4label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
P5draw:
	ldr	r2,=P5label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState				

EndDrawState:
	LDMFD 	sp!,{r0-r2,pc}
	
@@@@@@@@@@@@=========================
	.data
	.align
Digits:							@ for 8-segment display
	.word SEG_A|SEG_B|SEG_C|SEG_D|SEG_E|SEG_G 	@0
	.word SEG_B|SEG_C 							@1
	.word SEG_A|SEG_B|SEG_F|SEG_E|SEG_D 		@2
	.word SEG_A|SEG_B|SEG_F|SEG_C|SEG_D 		@3
	.word SEG_G|SEG_F|SEG_B|SEG_C 				@4
	.word SEG_A|SEG_G|SEG_F|SEG_C|SEG_D 		@5
	.word SEG_A|SEG_G|SEG_F|SEG_E|SEG_D|SEG_C 	@6
	.word SEG_A|SEG_B|SEG_C 					@7
	.word SEG_A|SEG_B|SEG_C|SEG_D|SEG_E|SEG_F|SEG_G @8
	.word SEG_A|SEG_B|SEG_F|SEG_G|SEG_C 		@9
	.word 0 									@Blank 
	.align
lineID:		.asciz	"Traffic Light -- Zachary Seselja, V00775627"
@ patterns for all states on LCD
line1S11:		.asciz	"        R W        "
line3S11:		.asciz	"GGG W         GGG W"
line5S11:		.asciz	"        R W        "

line1S12:		.asciz	"        R W        "
line3S12:		.asciz	"  W             W  "
line5S12:		.asciz	"        R W        "

line1S3:		.asciz	"        R W        "
line3S3:		.asciz	"YYY W         YYY W"
line5S3:		.asciz	"        R W        "

line1S4:		.asciz	"        R W        "
line3S4:		.asciz	" R W           R W "
line5S4:		.asciz	"        R W        "

line1S5:		.asciz	"       GGG W       "
line3S5:		.asciz	" R W           R W "
line5S5:		.asciz	"       GGG W       "

line1S6:		.asciz	"       YYY W       "
line3S6:		.asciz	" R W           R W "
line5S6:		.asciz	"       YYY W       "

line1P3:		.asciz	"       R XXX       "
line3P3:		.asciz	"R XXX         R XXX"
line5P3:		.asciz	"       R XXX       "

line1P4:		.asciz	"       R !!!       "
line3P4:		.asciz	"R !!!         R !!!"
line5P4:		.asciz	"       R !!!       "

S1label:		.asciz	"S1"
S2label:		.asciz	"S2"
S3label:		.asciz	"S3"
S4label:		.asciz	"S4"
S5label:		.asciz	"S5"
S6label:		.asciz	"S6"
S7label:		.asciz	"S7"
P1label:		.asciz	"P1"
P2label:		.asciz	"P2"
P3label:		.asciz	"P3"
P4label:		.asciz	"P4"
P5label:		.asciz	"P5"

Goodbye:
	.asciz	"*** Traffic Light program ended ***"

	.end
