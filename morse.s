/*

 This file contains the code read the value of a pin,
 a message is printed when the button is pressed.

*/
.data
.include "gpiolib.s"

.set middle, pin19 			// shortcut reference to the pins each part of the 7 segment display uses
.set topLeft, pin13
.set topBar, pin6
.set topRight, pin5
.set dot, pin12
.set bottomRight, pin16
.set bottom, pin20
.set bottomLeft, pin21
.bss

//.align 4
//readBuffer: .skip 30

.text
dot: .asciz ". " 		// asciz reference shortcut under dot function 
len_dot= .-dot  		//calculation of the length of dot function 

dash: .asciz "- "
len_dash= .-dash

intro: .asciz "Welcome to the Morse code simulator. Enter e to start the program or enter q to exit the program:\n" 	
len_intro=.-intro
.text

// This is where the program starts
.global main		//specificiation of enter point
.align 4
main: 
	mov r6,#0 			//make sure it doesnt take more than 4 inputs
	ldr r5,=2 			//will be iterated upon to print out the correct letter's code
	bl printintro  
	bl scan_character  //used to take in and branches to corresponding execution per user input

	ldr r0, =pin25 		// Set the pin
	bl loadpin 			// Call the function that enables the pin


	ldr r0, =pin25		// Set the pin
	mov r1, #1 			// Set the direction to in
	bl set_direction 	// Call the function that enables the pin
	mov r11,#0
	mov r9,#0 			//internal loop counter, for up to 400 ms break
	
  
    


	

mov r3,#0  	//initiation of r3, to verify whether the input has been pressed before an output has been yielded
mov r6,#0 	//make sure it doesnt take more than 4 inputs

ldr r5,=2 	//will be iterated upon to print out the correct letter's code

loop:
	

	// Sleep for 1/10 of a second
	mov r0, #5 		//50ms 
	bl partSleep 	//add delay to control the looping speed
	add r9,#1 		//loop counter to exit after 700ms
	cmp r6,#0 		// if no button presses have been registered yet

	cmpgt r9,#8 	//if no button presses yet, check if greater than 8 loop repetitions (400ms)
	movgt r9,#0 	// if more than 8 loops have occurred, reset the timing loop counter
	movgt r5,#2 	// reset the letter's code, so a brand new letter can be described
	movgt r3,#0		// new letter will be initialized, so resetting input boolean (use) counter
	movgt r6,#0 	// reset total input counter (maximum of 4 signals per letter)
	blgt resetter 	//branch into resetter, where the print call to "new letter detected" is run 
	
	ldr r0, =pin25	// Load the pin5
	bl read_value 	// verify/read the status of the push button
	
	cmp r0,#0		// if the button is pressed (0 being pressed)
	addeq r3,#1 	// if pressed, add one to counter r3 (showing that the button has been pressed)

	cmp r3,#5		//check if loop has run 5x 

	bleq loop1 		// enters loop 1, which will loop until button is released/or throw a long holding error
	
	moveq r9,#0 	// if the loop has run 5x, reset internal loop counter
	bleq printdash	 // if it has run 25x, print the dash
	bleq dashadd 	//takes in and will return r1 and r6, r6 being the total count, r1 as the code
	cmp r3,#5 		// compare register has been modified by dashadd, so it must be repeated
	moveq r3,#0 	//if the loop has run 5x, reset the internal button press indicator



	

	cmp r0,#1 		//see if button is not pressed
	moveq r4,#1 	//first of two conditions, button is not pressed
	
	cmp r3,#0 		//if nothing is in the counter 
	addgt r4,#1 	//second condition, if 50ms interval counter is more than zero
	cmp r3,#5 		//see if a button has been pressed for 5 loop repetitions (<250ms)
	addlt r4,#1 	//if button has been pressed, but for less than 250ms, then the second condition is satisfied 
	cmp r4,#3 		//check if all three conditions have been met (the button has been released, the button has been pressed for more than 50ms, but less than 250ms)
	moveq r9,#0 	//reset
	bleq printdot 	//if all conditions are met, print out the dot
	bleq dotadd 	//if all conditions are met, add a 0 to the concatenated individualized letter code
	cmp r4,#3 		//compare register has been modified by dotadd, so it must be repeated


	moveq r3,#0

	
	cmp r6,#4 		//once 4 signals (for single letter) have been provided, a new letter will be begun
	moveq r9,#9 


	bl loop 		// unless interrupted, return to begining of loop

	


resetter:
	push {r0-r7, lr}		// Store the registers
	mov r0, #1				// Set the output as the standard out
	ldr r1, =reset			// Load the pointer the to string
	mov r2, #len_reset		// Get the length of the string
	mov r7, #4				// Set the function of the system call to write(4)
	svc #0					// Do the system call
	pop {r0-r7, lr}			// Restore the value registers
	bx lr					// Return


exit:

	push {r0-r7, lr}	
	ldr r1, =exit_msg  		// loads the address of exit_msg into r1
	mov r2, #exit_msg_len	// sets the length of exit_msg
	mov r7, #4				// system call to write 
	svc #0					//no error call
	bl nanoSleep			// add delay
	bl nanoSleep
	bl black				// branches to function which turns off all of the 7-segment display's LED's 
	mov r7, #1				//system call to exit
	svc #0
loop1:
	push {r0-r7, lr} 
	mov r0, #5 //50ms 
	bl partSleep 		//looping speed of once every 50 ms
	add r11,#1 			//looping counter 

	cmp r11,#14 	//if loop has run (button held) for 700 ms or 14 revolutions
	bleq longerror 	//branch into printing error if run over 14x
	bleq exit		//exit if run over 14x
	ldr r0, =pin25	// Load the pin25
	bl read_value	//return to r0 whether 
	cmp r0,#1 		//if button is released(1)
	blne loop1 		//if not released, loop again

	pop {r0-r7, lr}
	svc #0 
	blx lr



scan_character:
    push {r0-r7, lr}
    mov r1, #1 		// Set the direction to out
    // loads the address of the scan_format to r0
    ldr r0, =scan_format
    // loads the address of the character_read to r1
	mov r1,r5
    ldr r1, =character_read
    // calls the scanf function which takes the parameters message and scan_format
    bl scanf
    // loads character_read again to r1 if incase the data at the link register has changed
    ldr r1, =character_read
    ldrb r1, [r1]
    //compares the r1 with the hex value q
    cmp r1, #0x71 
    //if equal it branches to exit
    bleq exit
    //compares the r1 with the hex value e
    cmp r1, #0x65
    //if equal it branches to set_8 function
	bleq set_8
	bleq black
    bleq loop //this is where the issue of not branching might be
    bl nanoSleep
    bl nanoSleep
    // call other methods before exit
	mov r5,r1
    pop {r0-r7, lr}
    bx lr


printdot:
	push {r0-r7, lr}	// Store the registers
	mov r0, #1			// Set the output as the standard out
	ldr r1, =dot		// Load the pointer the to string
	mov r2, #len_dot	// Get the length of the string
	mov r7, #4			// Set the function of the system call to write(4)
	svc #0				// Do the system call
	pop {r0-r7, lr}		// Restore the value registers
	bx lr				// Return
	
printdash:
	push {r0-r7, lr}	// Store the registers
	mov r0, #1			// Set the output as the standard out
	ldr r1, =dash		// Load the pointer the to string
	mov r2, #len_dot	// Get the length of the string
	mov r7, #4			// Set the function of the system call to write(4)
	svc #0				// Do the system call
	pop {r0-r7, lr}		// Restore the value registers
	bx lr				// Return

printintro:
	push {r0-r7, lr} 
	ldr r1, =intro		 @ loads the address of intro into register r1
	bl print_str		 @ branches to print_str method	
	pop {r0-r7, lr}
	bx lr

print_str:
	 push {r0-r7, lr}
	bl length	@ r0 = string length
	@ set up system call to print
	mov r2, r0
			@ r1 = address of address
	mov r0, #1	@ r0 = output device
	mov r7, #4	@ r7 = system call (4 = write)
	svc #0
	pop {r0-r7, lr}
	bx lr
length:
	push {r1, r2, lr}
	mov r0, #0
	loop2: 
	// loads a single byte from r1 into r2
	ldrb r2, [r1], #1
	// compares the contents of r2 with the null terminating string at the end of asciz
	cmp r2, #0
	// adds 1 to r0 to move onto
	addne r0, r0, #1
	// loops until r0 is 0
	bne loop2
	pop {r1, r2, lr}
	bx lr


dashadd:
    push {r0-r4,r7,lr}
    add r6,#1 //adding one to the counter of number of inputs
    mov r2,r5 //making a duplicate of r5, the register defaulting to 2, but is modified to match different letter's codes
    lsl r5,#1 
    lsl r2,#3
    add r5,r2
    add r5,#1

	// Example: initial value of r5 is #2, when a dash is added, it will return #21 in r5, this is done by multiplying 
	// r5 by 10 and adding #1, resulting in #21,
	// multiplication of 10 is acchieved by n lsl #1 + n lsl #3 == n*10
	bl identify //branches into function to match the current code stored in r5 (2****) to the appropriate letter's 7- segment display function and terminal printage
    pop {r0-r4,r7,lr} 
    blx lr


// This functions just prints a string to the screen
dotadd:
    push {r0-r4,r7,lr} 
    add r6,#1 //adding one to the counter of number of inputs
    mov r2,r5 //making a duplicate of r5, the register defaulting to 2, but is modified to match different letter's codes
    lsl r5,#1
    lsl r2,#3   
    add r5,r2

	// Example: initial value of r5 is #2, when a dot is added, it will return #20 in r5, this is done by multiplying 
	// r5 by 10, resulting in #20,
	// multiplication of 10 is acchieved by n lsl #1 + n lsl #3 == n*10
	bl identify //branches into function to match the current code stored in r5 (2****) to the appropriate letter's 7- segment display function and terminal printage
    pop {r0-r4,r7,lr} 
    blx lr


// this function takes the input of the user (pressing the button) and generates a string of 0's (dots) and 1's (dashes) and matches it to a specific letter
identify:
    push {r0,r1-r4,r6,r7, lr}

    ldr r2, =#201 //load r2 with the value of code for letter A
    cmp r5,r2 //check if r2 matches r5, the code for letter A
    bleq set_A // A

    ldr r2, =#21000
    cmp r5,r2
    bleq set_B // B 

    ldr r2, =#21010
    cmp r5,r2
    bleq set_C // C

    ldr r2, =#2100
    cmp r5,r2
    bleq set_D // D

    ldr r2, =#20
    cmp r5,r2
    bleq set_E // E 

    ldr r2, =#20010
    cmp r5,r2
    bleq set_F // F

    ldr r2, =#2110
    cmp r5,r2
    bleq set_G // G

    ldr r2, =#20000
    cmp r5,r2
    bleq set_H // H 

    ldr r2, =#200
    cmp r5,r2
    bleq set_I // I

    ldr r2, =#20111
    cmp r5,r2
    bleq set_J // J 

    ldr r2, =#2101
    cmp r5,r2
    bleq set_K // K

    ldr r2, =#20100
    cmp r5,r2
    bleq set_L // L

    ldr r2, =#211
    cmp r5,r2
    bleq set_M // M

    ldr r2, =#210
    cmp r5,r2
    bleq set_N // N

    ldr r2, =#2111
    cmp r5,r2
    bleq set_O // O

    ldr r2, =#20110
    cmp r5,r2
    bleq set_P // P

    ldr r2, =#21101
    cmp r5,r2
    bleq set_Q // Q

    ldr r2, =#2010
    cmp r5,r2
    bleq set_R // R

    ldr r2, =#2000
    cmp r5,r2
    bleq set_S // S

    ldr r2, =#21
    cmp r5,r2
    bleq set_T // T

    ldr r2, =#2001
    cmp r5,r2
    bleq set_U // U

    ldr r2, =#20001
    cmp r5,r2
    bleq set_V // V

    ldr r2, =#2011
    cmp r5,r2
    bleq set_W // W

    ldr r2, =#21001
    cmp r5,r2
    bleq set_X // X

    ldr r2, =#21011
    cmp r5,r2
    bleq set_Y // Y

    ldr r2, =#21100
    cmp r5,r2
    bleq set_Z // Z

	// prints out an error msgs 
	ldr r2, =#20011
    cmp r5,r2
    bleq error //branches into error display message




	
    pop {r0,r1-r4,r6,r7, lr} 
    blx lr

error:
	push {r0-r7, lr}		// Store the registers
	mov r0, #1			// Set the output as the standard out
	ldr r1, =erprint	// Load the pointer the to string
	mov r2, #er_length	// Get the length of the string
	mov r7, #4			// Set the function of the system call to write(4)
	svc #0				// Do the system call
	pop {r0-r7, lr}		// Restore the value registers
	bx lr	
longerror:
	push {r0-r7, lr}		// Store the registers
	mov r0, #1			// Set the output as the standard out
	ldr r1, =longprint	// Load the pointer the to string
	mov r2, #long_length	// Get the length of the string
	mov r7, #4			// Set the function of the system call to write(4)
	svc #0				// Do the system call
	pop {r0-r7, lr}		// Restore the value registers
	bx lr	

set_A:
	push {r0-r7, lr}


	ldr r1, =low // setting r1 to low so the following segments can be turned ON 

	ldr r0, =topRight
	bl set_value

	ldr r0, =topBar
	bl set_value

	ldr r0, =bottomRight
	bl set_value

	ldr r0, =bottomLeft
	bl set_value

	ldr r0, =bottom
	bl set_value

	ldr r0, =middle
	bl set_value

	ldr r1, =high //ensuring the following segments are turned OFF

	ldr r0, =topLeft
	bl set_value
	bl aa //enter function to print to terminal 

	pop {r0-r7, lr}

	bx lr
.LTORG //increase pool depth
set_B:
	push {r0-r7, lr}
	bl bb


	ldr r1, =low

	ldr r0, =bottomRight
	bl set_value

	ldr r0, =bottomLeft
	bl set_value

	ldr r0, =topLeft
	bl set_value

	ldr r0, =middle
	bl set_value

	ldr r0, =bottom
	bl set_value

	ldr r1, =high

	ldr r0, =topRight
	bl set_value

	ldr r0, =topBar
	bl set_value

	pop {r0-r7, lr}

	bx lr

set_C:
	push {r0-r7, lr}
	bl cc

	ldr r1, =low

	ldr r0, =bottomLeft
	bl set_value

	ldr r0, =bottom
	bl set_value

	ldr r0, =middle
	bl set_value

	ldr r1, =high

	ldr r0, =topRight
	bl set_value

	ldr r0, =bottomRight
	bl set_value

	ldr r0, =topLeft
	bl set_value

	ldr r0, =topBar
	bl set_value

	pop {r0-r7, lr}

	bx lr

set_D:
	push {r0-r7, lr}
	bl dd

	ldr r1, =low

	ldr r0, =topRight
	bl set_value

	ldr r0, =bottomRight
	bl set_value

	ldr r0, =bottomLeft
	bl set_value

	ldr r0, =middle
	bl set_value

	ldr r0, =bottom
	bl set_value

	ldr r1, =high

	ldr r0, =topLeft
	bl set_value

	ldr r0, =topBar
	bl set_value

	pop {r0-r7, lr}

	bx lr

set_E:
	push {r0-r7, lr}
	bl ee

	ldr r1, =low

	ldr r0, =topBar
	bl set_value

	ldr r0, =bottomLeft
	bl set_value

	ldr r0, =topLeft
	bl set_value

	ldr r0, =middle
	bl set_value

	ldr r0, =bottom
	bl set_value

	ldr r1, =high

	ldr r0, =topRight
	bl set_value

	ldr r0, =bottomRight
	bl set_value

	pop {r0-r7, lr}

	blx lr

set_F:
	push {r0-r7, lr}
	bl ff

	ldr r1, =low

	ldr r0, =topBar
	bl set_value

	ldr r0, =bottomLeft
	bl set_value

	ldr r0, =topLeft
	bl set_value

	ldr r0, =middle
	bl set_value

	ldr r1, =high

	ldr r0, =topRight
	bl set_value

	ldr r0, =bottomRight
	bl set_value

	ldr r0, =bottom
	bl set_value

	pop {r0-r7, lr}

	bx lr

set_G:
	push {r0-r7, lr}
	bl gg

	ldr r1, =low

	ldr r0, =bottomLeft
	bl set_value

	ldr r0, =bottomRight
	bl set_value

	ldr r0, =bottom
	bl set_value

	ldr r0, =topBar
	bl set_value

	ldr r0, =topLeft
	bl set_value

	ldr r0, =middle
	bl set_value

	ldr r1, =high

	ldr r0, =topRight
	bl set_value

	pop {r0-r7, lr}

	bx lr

set_H:
	push {r0-r7, lr}
	bl hh

	ldr r1, =low

	ldr r0, =bottomLeft
	bl set_value

	ldr r0, =bottomRight
	bl set_value

	ldr r0, =topLeft
	bl set_value

	ldr r0, =middle
	bl set_value

	ldr r0, =topRight
	bl set_value

	ldr r1, =high

	ldr r0, =topBar
	bl set_value

	ldr r0, =bottom
	bl set_value

	pop {r0-r7, lr}

	bx lr

set_I:
	push {r0-r7, lr}
	bl ii

	ldr r1, =low

	ldr r0, =bottomRight
	bl set_value

	ldr r1, =high

	ldr r0, =topRight
	bl set_value

	ldr r0, =middle
	bl set_value

	ldr r0, =bottom
	bl set_value

	ldr r0, =topBar
	bl set_value

	ldr r0, =bottomLeft
	bl set_value

	ldr r0, =topLeft
	bl set_value

	pop {r0-r7, lr}

	bx lr

set_J:
	push {r0-r7, lr}
	bl jj

	ldr r1, =low

	ldr r0, =bottomRight
	bl set_value

	ldr r0, =bottom
	bl set_value

	ldr r0, =bottomLeft
	bl set_value

	ldr r0, =topRight
	bl set_value

	ldr r1, =high

	ldr r0, =topBar
	bl set_value

	ldr r0, =topLeft
	bl set_value

	ldr r0, =middle
	bl set_value

	pop {r0-r7, lr}

	bx lr

set_K:
	push {r0-r7, lr}
	bl kk

	ldr r1, =low

	ldr r0, =middle
	bl set_value

	ldr r0, =topBar
	bl set_value

	ldr r0, =bottomRight
	bl set_value

	ldr r0, =bottomLeft
	bl set_value

	ldr r0, =topLeft
	bl set_value

	ldr r1, =high

	ldr r0, =bottom
	bl set_value

	ldr r0, =topRight
	bl set_value

	pop {r0-r7, lr}

	bx lr

set_L:
	push {r0-r7, lr}
	bl ll

	ldr r1, =low

	ldr r0, =bottom
	bl set_value

	ldr r0, =bottomLeft
	bl set_value

	ldr r0, =topLeft
	bl set_value

	ldr r1, =high

	ldr r0, =middle
	bl set_value

	ldr r0, =topBar
	bl set_value

	ldr r0, =bottomRight
	bl set_value

	ldr r0, =topRight
	bl set_value

	pop {r0-r7, lr}

	bx lr

set_M:
	push {r0-r7, lr}
	bl mm

	ldr r1, =low

	ldr r0, =bottomLeft
	bl set_value

	ldr r0, =bottomRight
	bl set_value

	ldr r0, =middle
	bl set_value

	ldr r0, =topBar
	bl set_value

	ldr r1, =high

	ldr r0, =topLeft
	bl set_value

	ldr r0, =topRight
	bl set_value

	ldr r0, =bottom
	bl set_value

	pop {r0-r7, lr}

	bx lr

set_N:
	push {r0-r7, lr}
	bl nn

	ldr r1, =low

	ldr r0, =bottomLeft
	bl set_value

	ldr r0, =bottomRight
	bl set_value

	ldr r0, =middle
	bl set_value

	ldr r1, =high

	ldr r0, =topLeft
	bl set_value

	ldr r0, =topRight
	bl set_value

	ldr r0, =bottom
	bl set_value

	ldr r0, =topBar
	bl set_value

	pop {r0-r7, lr}

	bx lr

set_O:
	push {r0-r7, lr}
	bl oo

	ldr r1, =low

	ldr r0, =bottomLeft
	bl set_value

	ldr r0, =bottomRight
	bl set_value

	ldr r0, =middle
	bl set_value

	ldr r0, =bottom
	bl set_value

	ldr r1, =high

	ldr r0, =topLeft
	bl set_value

	ldr r0, =topRight
	bl set_value

	ldr r0, =topBar
	bl set_value

	pop {r0-r7, lr}

	bx lr

set_P:
	push {r0-r7, lr}
	bl pp

	ldr r1, =low

	ldr r0, =bottomLeft
	bl set_value

	ldr r0, =middle
	bl set_value

	ldr r0, =topLeft
	bl set_value

	ldr r0, =topRight
	bl set_value

	ldr r0, =topBar
	bl set_value

	ldr r1, =high

	ldr r0, =bottom
	bl set_value

	ldr r0, =bottomRight
	bl set_value

	pop {r0-r7, lr}

	bx lr

set_Q:
	push {r0-r7, lr}
	bl qq

	ldr r1, =low

	ldr r0, =bottomRight
	bl set_value

	ldr r0, =middle
	bl set_value

	ldr r0, =topLeft
	bl set_value

	ldr r0, =topRight
	bl set_value

	ldr r0, =topBar
	bl set_value

	ldr r1, =high

	ldr r0, =bottom
	bl set_value

	ldr r0, =bottomLeft
	bl set_value

	pop {r0-r7, lr}

	bx lr

set_R:
	push {r0-r7, lr}
	bl rr

	ldr r1, =low

	ldr r0, =middle
	bl set_value

	ldr r0, =bottomLeft
	bl set_value

	ldr r1, =high

	ldr r0, =bottomRight
	bl set_value

	ldr r0, =bottom
	bl set_value

	ldr r0, =topLeft
	bl set_value

	ldr r0, =topRight
	bl set_value

	ldr r0, =topBar
	bl set_value

	pop {r0-r7, lr}

	bx lr

set_S:
	push {r0-r7, lr}
	bl ss

	ldr r1, =low

	ldr r0, =middle
	bl set_value

	ldr r0, =bottomRight
	bl set_value

	ldr r0, =topLeft
	bl set_value

	ldr r0, =topBar
	bl set_value

	ldr r0, =bottom
	bl set_value

	ldr r1, =high

	ldr r0, =bottomLeft
	bl set_value

	ldr r0, =topRight
	bl set_value

	pop {r0-r7, lr}

	bx lr

set_T:
	push {r0-r7, lr}
	bl tt

	ldr r1, =low

	ldr r0, =middle
	bl set_value

	ldr r0, =topLeft
	bl set_value

	ldr r0, =bottom
	bl set_value

	ldr r0, =bottomLeft
	bl set_value

	ldr r1, =high

	ldr r0, =topRight
	bl set_value

	ldr r0, =bottomRight
	bl set_value

	ldr r0, =topBar
	bl set_value

	pop {r0-r7, lr}

	bx lr

set_U:
	push {r0-r7, lr}
	bl uu

	ldr r1, =low

	ldr r0, =bottom
	bl set_value

	ldr r0, =bottomLeft
	bl set_value

	ldr r0, =bottomRight
	bl set_value

	ldr r1, =high

	ldr r0, =middle
	bl set_value

	ldr r0, =topLeft
	bl set_value

	ldr r0, =topRight
	bl set_value

	ldr r0, =topBar
	bl set_value

	pop {r0-r7, lr}

	bx lr

set_V:
	push {r0-r7, lr}
	bl vv

	ldr r1, =low

	ldr r0, =bottom
	bl set_value

	ldr r0, =topLeft
	bl set_value

	ldr r0, =topRight
	bl set_value

	ldr r1, =high

	ldr r0, =bottomLeft
	bl set_value

	ldr r0, =bottomRight
	bl set_value

	ldr r0, =middle
	bl set_value

	ldr r0, =topBar
	bl set_value

	pop {r0-r7, lr}

	bx lr

set_W:
	push {r0-r7, lr}
	bl ww

	ldr r1, =low

	ldr r0, =bottom
	bl set_value

	ldr r0, =middle
	bl set_value

	ldr r0, =topLeft
	bl set_value

	ldr r0, =topRight
	bl set_value

	ldr r1, =high

	ldr r0, =bottomLeft
	bl set_value

	ldr r0, =bottomRight
	bl set_value

	ldr r0, =topBar
	bl set_value

	pop {r0-r7, lr}

	bx lr

set_X:
	push {r0-r7, lr}
	bl xx

	ldr r1, =low

	ldr r0, =bottom
	bl set_value

	ldr r0, =topBar
	bl set_value

	ldr r0, =middle
	bl set_value

	ldr r1, =high

	ldr r0, =bottomLeft
	bl set_value

	ldr r0, =topLeft
	bl set_value

	ldr r0, =bottomRight
	bl set_value

	ldr r0, =topRight
	bl set_value

	pop {r0-r7, lr}

	bx lr

set_Y:
	push {r0-r7, lr}
	bl yy

	ldr r1, =low

	ldr r0, =topLeft
	bl set_value

	ldr r0, =topRight
	bl set_value

	ldr r0, =middle
	bl set_value

	ldr r0, =bottom
	bl set_value

	ldr r1, =high

	ldr r0, =bottomRight
	bl set_value
	
	ldr r0, =topBar
	bl set_value

	ldr r0, =bottomLeft
	bl set_value

	pop {r0-r7, lr}

	bx lr

set_Z:
	push {r0-r7, lr}
	bl zz

	ldr r1, =low

	ldr r0, =topRight
	bl set_value

	ldr r0, =middle
	bl set_value

	ldr r0, =bottom
	bl set_value

	ldr r0, =topBar
	bl set_value

	ldr r0, =bottomLeft
	bl set_value

	ldr r1, =high

	ldr r0, =topLeft
	bl set_value

	ldr r0, =bottomRight
	bl set_value

	pop {r0-r7, lr}

	bx lr


set_8:

	push {r0-r7, lr}
	

	//sets all of the following segments of the 7-segment display to in/on
	ldr r1, =low

	ldr r0, =topRight
	bl set_value

	ldr r0, =topBar
	bl set_value

	ldr r0, =bottomRight
	bl set_value

	ldr r0, =bottomLeft
	bl set_value

	ldr r0, =topLeft
	bl set_value

	ldr r0, =bottom
	bl set_value

	ldr r0, =middle
	bl set_value

	bl nanoSleep //added short delay

	pop {r0-r7, lr}
	bx lr


black:
	push {r0-r7, lr}
	ldr r1, =high //turning all the segments off

	ldr r0, =topRight
	bl set_value

	ldr r0, =topBar
	bl set_value

	ldr r0, =bottomRight
	bl set_value

	ldr r0, =topLeft
	bl set_value

	ldr r0, =middle
	bl set_value


	ldr r0, =bottom
	bl set_value

	ldr r0, =bottomLeft
	bl set_value

	pop {r0-r7, lr}
	bx lr
set_9:
	push {r0-r7, lr}
	ldr r1, =low

	ldr r0, =topRight
	bl set_value

	ldr r0, =topBar
	bl set_value

	ldr r0, =bottomRight
	bl set_value

	ldr r0, =topLeft
	bl set_value

	ldr r0, =middle
	bl set_value

	ldr r1, =high

	ldr r0, =bottom
	bl set_value

	ldr r0, =bottomLeft
	bl set_value
	@ bl print_9
	pop {r0-r7, lr}
	bx lr
aa:
	push {r0-r7, lr}		// Store the registers
	mov r0, #1			// Set the output as the standard out
	ldr r1, =a	// Load the pointer the to string
	mov r2, #len_a	// Get the length of the string
	mov r7, #4			// Set the function of the system call to write(4)
	svc #0				// Do the system call
	pop {r0-r7, lr}		// Restore the value registers
	bx lr
bb:
	push {r0-r7, lr}		// Store the registers
	mov r0, #1			// Set the output as the standard out
	ldr r1, =b	// Load the pointer the to string
	mov r2, #len_b	// Get the length of the string
	mov r7, #4			// Set the function of the system call to write(4)
	svc #0				// Do the system call
	pop {r0-r7, lr}		// Restore the value registers
	bx lr

cc:
	push {r0-r7, lr}		// Store the registers
	mov r0, #1			// Set the output as the standard out
	ldr r1, =c	// Load the pointer the to string
	mov r2, #len_c	// Get the length of the string
	mov r7, #4			// Set the function of the system call to write(4)
	svc #0				// Do the system call
	pop {r0-r7, lr}		// Restore the value registers
	bx lr

dd:
	push {r0-r7, lr}		// Store the registers
	mov r0, #1			// Set the output as the standard out
	ldr r1, =d	// Load the pointer the to string
	mov r2, #len_d	// Get the length of the string
	mov r7, #4			// Set the function of the system call to write(4)
	svc #0				// Do the system call
	pop {r0-r7, lr}		// Restore the value registers
	bx lr

ee:
	push {r0-r7, lr}		// Store the registers
	mov r0, #1			// Set the output as the standard out
	ldr r1, =e	// Load the pointer the to string
	mov r2, #len_e	// Get the length of the string
	mov r7, #4			// Set the function of the system call to write(4)
	svc #0				// Do the system call
	pop {r0-r7, lr}		// Restore the value registers
	bx lr

ff:
	push {r0-r7, lr}		// Store the registers
	mov r0, #1			// Set the output as the standard out
	ldr r1, =f	// Load the pointer the to string
	mov r2, #len_f	// Get the length of the string
	mov r7, #4			// Set the function of the system call to write(4)
	svc #0				// Do the system call
	pop {r0-r7, lr}		// Restore the value registers
	bx lr

gg:
	push {r0-r7, lr}		// Store the registers
	mov r0, #1			// Set the output as the standard out
	ldr r1, =g	// Load the pointer the to string
	mov r2, #len_g	// Get the length of the string
	mov r7, #4			// Set the function of the system call to write(4)
	svc #0				// Do the system call
	pop {r0-r7, lr}		// Restore the value registers
	bx lr

hh:
	push {r0-r7, lr}		// Store the registers
	mov r0, #1			// Set the output as the standard out
	ldr r1, =h	// Load the pointer the to string
	mov r2, #len_h	// Get the length of the string
	mov r7, #4			// Set the function of the system call to write(4)
	svc #0				// Do the system call
	pop {r0-r7, lr}		// Restore the value registers
	bx lr

ii:
	push {r0-r7, lr}		// Store the registers
	mov r0, #1			// Set the output as the standard out
	ldr r1, =i	// Load the pointer the to string
	mov r2, #len_i	// Get the length of the string
	mov r7, #4			// Set the function of the system call to write(4)
	svc #0				// Do the system call
	pop {r0-r7, lr}		// Restore the value registers
	bx lr

jj:
	push {r0-r7, lr}		// Store the registers
	mov r0, #1			// Set the output as the standard out
	ldr r1, = j	// Load the pointer the to string
	mov r2, #len_j	// Get the length of the string
	mov r7, #4			// Set the function of the system call to write(4)
	svc #0				// Do the system call
	pop {r0-r7, lr}		// Restore the value registers
	bx lr

kk:
	push {r0-r7, lr}		// Store the registers
	mov r0, #1			// Set the output as the standard out
	ldr r1, =k	// Load the pointer the to string
	mov r2, #len_k	// Get the length of the string
	mov r7, #4			// Set the function of the system call to write(4)
	svc #0				// Do the system call
	pop {r0-r7, lr}		// Restore the value registers
	bx lr

ll:
	push {r0-r7, lr}		// Store the registers
	mov r0, #1			// Set the output as the standard out
	ldr r1, =l	// Load the pointer the to string
	mov r2, #len_l	// Get the length of the string
	mov r7, #4			// Set the function of the system call to write(4)
	svc #0				// Do the system call
	pop {r0-r7, lr}		// Restore the value registers
	bx lr

mm:
	push {r0-r7, lr}		// Store the registers
	mov r0, #1			// Set the output as the standard out
	ldr r1, =m	// Load the pointer the to string
	mov r2, #len_m	// Get the length of the string
	mov r7, #4			// Set the function of the system call to write(4)
	svc #0				// Do the system call
	pop {r0-r7, lr}		// Restore the value registers
	bx lr

nn:
	push {r0-r7, lr}		// Store the registers
	mov r0, #1			// Set the output as the standard out
	ldr r1, =n	// Load the pointer the to string
	mov r2, #len_n	// Get the length of the string
	mov r7, #4			// Set the function of the system call to write(4)
	svc #0				// Do the system call
	pop {r0-r7, lr}		// Restore the value registers
	bx lr

oo:
	push {r0-r7, lr}		// Store the registers
	mov r0, #1			// Set the output as the standard out
	ldr r1, =o	// Load the pointer the to string
	mov r2, #len_o	// Get the length of the string
	mov r7, #4			// Set the function of the system call to write(4)
	svc #0				// Do the system call
	pop {r0-r7, lr}		// Restore the value registers
	bx lr
pp:
	push {r0-r7, lr}		// Store the registers
	mov r0, #1			// Set the output as the standard out
	ldr r1, =p	// Load the pointer the to string
	mov r2, #len_p	// Get the length of the string
	mov r7, #4			// Set the function of the system call to write(4)
	svc #0				// Do the system call
	pop {r0-r7, lr}		// Restore the value registers
	bx lr

qq:
	push {r0-r7, lr}		// Store the registers
	mov r0, #1			// Set the output as the standard out
	ldr r1, =q	// Load the pointer the to string
	mov r2, #len_q	// Get the length of the string
	mov r7, #4			// Set the function of the system call to write(4)
	svc #0				// Do the system call
	pop {r0-r7, lr}		// Restore the value registers
	bx lr

rr:
	push {r0-r7, lr}		// Store the registers
	mov r0, #1			// Set the output as the standard out
	ldr r1, =r	// Load the pointer the to string
	mov r2, #len_r	// Get the length of the string
	mov r7, #4			// Set the function of the system call to write(4)
	svc #0				// Do the system call
	pop {r0-r7, lr}		// Restore the value registers
	bx lr

ss:
	push {r0-r7, lr}		// Store the registers
	mov r0, #1			// Set the output as the standard out
	ldr r1, =s	// Load the pointer the to string
	mov r2, #len_s	// Get the length of the string
	mov r7, #4			// Set the function of the system call to write(4)
	svc #0				// Do the system call
	pop {r0-r7, lr}		// Restore the value registers
	bx lr

tt:
	push {r0-r7, lr}		// Store the registers
	mov r0, #1			// Set the output as the standard out
	ldr r1, =t	// Load the pointer the to string
	mov r2, #len_t	// Get the length of the string
	mov r7, #4			// Set the function of the system call to write(4)
	svc #0				// Do the system call
	pop {r0-r7, lr}		// Restore the value registers
	bx lr

uu:
	push {r0-r7, lr}		// Store the registers
	mov r0, #1			// Set the output as the standard out
	ldr r1, =u	// Load the pointer the to string
	mov r2, #len_u	// Get the length of the string
	mov r7, #4			// Set the function of the system call to write(4)
	svc #0				// Do the system call
	pop {r0-r7, lr}		// Restore the value registers
	bx lr

vv:
	push {r0-r7, lr}		// Store the registers
	mov r0, #1			// Set the output as the standard out
	ldr r1, =v	// Load the pointer the to string
	mov r2, #len_v	// Get the length of the string
	mov r7, #4			// Set the function of the system call to write(4)
	svc #0				// Do the system call
	pop {r0-r7, lr}		// Restore the value registers
	bx lr

ww:
	push {r0-r7, lr}		// Store the registers
	mov r0, #1			// Set the output as the standard out
	ldr r1, =w	// Load the pointer the to string
	mov r2, #len_w	// Get the length of the string
	mov r7, #4			// Set the function of the system call to write(4)
	svc #0				// Do the system call
	pop {r0-r7, lr}		// Restore the value registers
	bx lr

xx:
	push {r0-r7, lr}		// Store the registers
	mov r0, #1			// Set the output as the standard out
	ldr r1, =x	// Load the pointer the to string
	mov r2, #len_x	// Get the length of the string
	mov r7, #4			// Set the function of the system call to write(4)
	svc #0				// Do the system call
	pop {r0-r7, lr}		// Restore the value registers
	bx lr

yy:
	push {r0-r7, lr}		// Store the registers
	mov r0, #1			// Set the output as the standard out
	ldr r1, =y	// Load the pointer the to string
	mov r2, #len_y	// Get the length of the string
	mov r7, #4			// Set the function of the system call to write(4)
	svc #0				// Do the system call
	pop {r0-r7, lr}		// Restore the value registers
	bx lr



zz:
	push {r0-r7, lr}		// Store the registers
	mov r0, #1			// Set the output as the standard out
	ldr r1, =z	// Load the pointer the to string
	mov r2, #len_z	// Get the length of the string
	mov r7, #4			// Set the function of the system call to write(4)
	svc #0				// Do the system call
	pop {r0-r7, lr}		// Restore the value registers
	bx lr


.data
welcome_msg: 
    .asciz "Welcome to the Morse code simulator. Enter e to start the program or enter q to exit the program:\n"

string:
    .asciz "%d\n"

scan_format: 
	.asciz "%c"
character_read:
	.word 0 

erprint:
	.asciz "invalid input, input may not exist\n"

er_length = .-erprint
longprint:
	.asciz "you've held the button too long, run program again \n"

long_length = .-longprint
reset:
	.asciz "new letter detected\n"
len_reset = .-reset


a:
	.asciz "A\n" //the letter will be printed when the function its in will be called

len_a = .-a //calculating the length of the prior 

b:
	.asciz "B\n"

len_b = .-b

c:
	.asciz "C\n"

len_c = .-c

d:
	.asciz "D\n"

len_d = .-d

e:
	.asciz "E\n"

len_e = .-e

f:
	.asciz "F\n"

len_f = .-f

g:
	.asciz "G\n"

len_g = .-g

h:
	.asciz "H\n"

len_h = .-h

i:
	.asciz "I\n"

len_i = .-i

j:
	.asciz "J\n"

len_j = .-j

k:
	.asciz "K\n"

len_k = .-k

l:
	.asciz "L\n"

len_l = .-l

m:
	.asciz "M\n"

len_m = .-m

n:
	.asciz "N\n"

len_n = .-n

o:
	.asciz "O\n"

len_o = .-o

p:
	.asciz "P\n"

len_p = .-p

q:
	.asciz "Q\n"

len_q = .-q

r:
	.asciz "R\n"

len_r = .-r

s:
	.asciz "S\n"

len_s = .-s

t:
	.asciz "T\n"

len_t = .-t

u:
	.asciz "U\n"

len_u = .-u

v:
	.asciz "V\n"

len_v = .-v

w:
	.asciz "W\n"

len_w = .-w

x:
	.asciz "X\n"

len_x = .-x

y:
	.asciz "Y\n"

len_y = .-y

z:
	.asciz "Z\n"

len_z = .-z

start_msg:
 	.asciz "Program started\n"


start_msg_length = .-start_msg


incorrect_input: .asciz "Please enter e or q:\n"
incorrect_length = .-incorrect_input

exit_msg: .asciz "Thank you for playing the morse code simulator\n"
exit_msg_len = .-exit_msg

.end 



