/*

 This file will now be used to help us control the GPIO pins

 For a better understanding on how the code works check the turning_lights_on files

*/
.data

pin5: .asciz "5\n"
pin6: .asciz "6\n"
pin22: .asciz "22\n"
pin27: .asciz "27\n"
pin17: .asciz "17\n"
pin18: .asciz "18\n"
pin23: .asciz "24\n"
pin25: .asciz "25\n"
pin12: .asciz "12\n"
pin13: .asciz "13\n"
pin19: .asciz "19\n"
pin16: .asciz "16\n"
pin26: .asciz "26\n"
pin20: .asciz "20\n"
pin21: .asciz "21\n"

pathtoexport: .asciz "/sys/class/gpio/export"
pathtounexport: .asciz "/sys/class/gpio/unexport"

pathtodirectionx: .asciz "/sys/class/gpio/gpiox/direction"
pathtodirectionxx: .asciz "/sys/class/gpio/gpioxx/direction"
pathtovaluex: .asciz "/sys/class/gpio/gpiox/value"
pathtovaluexx: .asciz "/sys/class/gpio/gpioxx/value"

/*
 Options for setting direction
*/
in: .asciz "in\n"
len_in = .-in
out: .asciz "out\n"
len_out = .-out

/*
 Error messages
*/
errorfilemessage: .asciz "Could not open the file\n"
len_errorfilemessage = .-errorfilemessage
errorinvalidargument: .asciz "Invalid arguments\n"
len_errorinvalidargument = .-errorinvalidargument

high: .asciz "1\n"
low: .asciz "0\n"

// Uninitialized data
.bss
.align 4
//This is creating an area in memory that will be used by the sleep function
timespec:
	seconds: .skip 4
	nanoSeconds: .skip 4
zonetemps: .skip 8

readBuffer: .skip 10

.text

// This is meant to be a library therefor there are no "main function"

/*


 This function is used for the computer to sleep for a second 


*/
nanoSleep:
	// Store all the registers from r0 to r7 and the lr register
	push {r0-r7, lr} 

	ldr r1, =nanoSeconds
	mov r0, #0
	str r0, [r1]
	
	// Load the pointer to the seconds
	ldr r1, =seconds
	// Set the number of seconds to sleep
	mov r0, #1
	// Store it in the seconds
	str r0, [r1]

	/*
	 Load the timespec which contains the seconds
	*/
	ldr r0, =timespec
	/*
	 Load the timezone
	*/
	ldr r1, =zonetemps
	// 162 is the sleep system call
	mov r7, #162
	// Do the system call
	svc #0

	// Restore all the registers r0 to r7 and the lr register
	pop {r0-r7, lr}
	// Return
	bx lr

// END NANOSLEEP

/*


 This function is used for the computer to sleep for a second 
 
 takes the seconds on r0

*/
secondsSleep:
	// Store all the registers from r0 to r7 and the lr register
	push {r0-r7, lr} 
	
	ldr r1, =nanoSeconds
	mov r2, #0
	str r2, [r1]

	// Load the pointer to the seconds
	ldr r1, =seconds
	// Store it in the seconds
	str r0, [r1]

	/*
	 Load the timespec which contains the seconds
	*/
	ldr r0, =timespec
	/*
	 Load the timezone
	*/
	ldr r1, =zonetemps
	// 162 is the sleep system call
	mov r7, #162
	// Do the system call
	svc #0

	// Restore all the registers r0 to r7 and the lr register
	pop {r0-r7, lr}
	// Return
	bx lr

// END secondsSLEEP

/*




 


 This function allows to sleep for a part of a second. This function will sleep for r0/100
 of a second

*/
partSleep:
	// Store all the registers from r0 to r7 and the lr register
	push {r0-r7, lr} 
	
	// Clean the seconds variable
	ldr r1, =seconds 	// Load the seconds pointer
	mov r2, #0		// Set r2 value to 0
	str r2, [r1]		// Store the value of r0(0) into r1(seconds)

	/*
	 There are limitations on what number we can put using the "#" syntax,
	 and because we will be working with nanoseconds the number we will 
	 have to create will be 100000000 that will be multiplied to by r0 make the
	 number final number of seconds to sleep
	*/
	mov r1, #1000	// Set r1 to 1000
	mov r2, #1000	// Set r2 to 1000
	mul r1, r2	// Multiply r1(1000) and r2(1000) and store it in r1(1000000)
	mov r2, #10	// Set r2 to 10
	mul r1, r2	// Multiply r1(1000000) and r2(10) and store it in r1(10000000)
	mul r0, r1	// Multiply r0(input) by r1(10000000) and store it in r0


	// Load the pointer to the nanoseconds
	ldr r1, =nanoSeconds
	// Store the value of r0(modified input) in r1(nanoSeconds)
	str r0, [r1]

	/*
	 Load the timespec which contains the seconds and nanoSeconds
	*/
	ldr r0, =timespec
	/*
	 Load the timezone
	*/
	ldr r1, =zonetemps
	// 162 is the sleep system call
	mov r7, #162
	// Do the system call
	svc #0

	// Restore all the registers r0 to r7 and the lr register
	pop {r0-r7, lr}
	// Return
	bx lr

// END secondsSLEEP





/* 




 This function read the value from a pin

 It takes the pin on the r0

*/
read_value:
	push {r1-r7, lr}
	
	/*
	
	 To get the value of the pin is similar to setting the value of a pin, but instead
	 of writing the value of the pin to the file we read the value from the pin.

	*/
	
	ldr r1, =pathtovaluex	// Load the path to in the case pin only has 1 number
	ldr r2, =pathtovaluexx	// Load the path to file in the case pin has 2 numbers
	/*
	 Call the function that opens the file based on the pin. After this function on r0.
	 we will have the file
	*/
	bl select_file_read	

	// Not that the file is open we can read it

	mov r5, r0		// Store the file on r5

	/*

	 The read system call takes 3 arguments:
	  - The file to read from which is in r0
	  - The second argument is where the result of the value will be stored, this
	    will be a buffer
	  - The 3rd argument is how many characters to read, it is important to keep this
	    value smaller or equals to the size of the buffer where the value will be stored

	*/
	
	
	ldr r1, =readBuffer	// The place where the value will be stored
	mov r2, #1		// We only need to read one value
	mov r7, #3		// Set the system call to read(3)
	svc #0			// Do the system call

	ldrb r0, [r1]		// Load the value of the string that was just read

	/*
	 The value that we just loaded is will be either '0' and '1', but not the number,
	 the ascii values, which will be either 48 or 49

	 So we can compare the r0(which holds the value that we just read), with the
	 49('1' in ascii), and if they are the same then we set r0 to 1 and if not we set
	 r0 t0 0
	*/
	cmp r0, #49
	moveq r0, #1
	movne r0, #0
	
	// Store the result in r0
	push {r0}

	// Now we close the file

	mov r0, r5	// Set the file 
	mov r7, #6	// Set the system call to close(6)
	svc #0
	
	//Restore the value of r0
	pop {r0}
	
	// Restore all the values
	pop {r1-r7, lr}
	// Return
	bx lr



/*




 This function is used to set the value of a pin
 This function takes 2 arguments
 r0 is the pin of value
 r1 is the value for that pin

 This is done by writing and to "/sys/class/gpio/gpiox/value" or 
 "/sys/class/gpio/gpioxx/value" where the "x" is the pin number

 Note: for this files to exist the pin needs to be exported first which can be done by using the
 laodpin function


*/
set_value:
	// Store the registers from r0 to r7, and the lr
	push {r0-r7, lr}

	push {r1-r2}

	ldr r1, =pathtovaluex
	ldr r2, =pathtovaluexx
	bl select_file

	mov r5, r0 // Save the file descriptor

	pop {r1-r2}
	
/*
 At this point r0 should be the file that was opened on the previous part, and r1 has the value
 that we want to write to the right file
*/
set_value_write:
	
	// Store the file descriptor
	push {r0}
	
	// Copy the value into r0 that will be used to calculate the size of the string 
	mov r0, r1

	// Calculate the size string
	bl calculate_end

	// Save the calculated size in r0
	mov r2, r0

	// Restore the file descriptor 
	pop {r0}
	
	mov r7, #4 // Set the system call to write
	svc #0	   // Do the system call

/*
 Close the file
*/

	mov r0, r5 // Move the file descriptor to r0
	mov r7, #6 // Set the system call to close
	svc #0	   // Do the system call

	// Restore all the registers
	pop {r0-r7, lr}
	// Return
	bx lr

// END set_value








/*
	

 Set this function sets the direction of a pin this function expects:
 r0 as the pin
 r1 the direction which can either be 0 for "in" and 1 for "out"

 This is done by writing to "/sys/class/gpio/gpiox/direction" or "/sys/class/gpio/gpioxx/direction"
 where "x" is the number of the pin

 Note: for this files to exist the pin needs to be exported first which can be done by using the
 laodpin function

*/
set_direction:
	// Save registers r0 to r7 and lr
	push {r0-r7, lr}
	
	/*
	 This checks if the direction is correct by checking if it's bigger than 1 and smaller
	 than 0

	 If the input value is invalid then print the error message and exit the program with a non 
	 0 exit code
	*/
	cmp r1, #1			// Compare r1(direction) with 1
	blgt err_invalid_arguments	// If it is bigger then go the error function
	cmp r1, #0			// Compare r1(direction) with 0
	bllt err_invalid_arguments	// If it is less then go the error function

	push {r1-r2}
	
	ldr r1, =pathtodirectionx
	ldr r2, =pathtodirectionxx
	bl select_file

	mov r5, r0

	pop {r1-r2}
	
/*

 At this point we have a file that is on r0 and a direction on r1

*/
set_direction_write:

	cmp r1, #1 			// Compare the direction with 1
	bleq set_direction_write_out	// Jump to out section of the function

	/*
	 This is the section the is about writing the "in" string in to the file in r0
	*/

	// r0 already contains the file
	ldr r1, =in 	// Load the string
	mov r2, #len_in	// Load the size of the string
	mov r7, #4	// Set the system call to write
	svc #0		// Do the system call
	bl set_direction_write_end // Jump to end and do not do the writing out

set_direction_write_out:

	/*
	 This is the section the is about writing the "out" string in to the file in r0
	*/
	push {r0}
	ldr r0, =out
	push {r0}
	bl calculate_end
	mov r2, r0
	pop {r1}
	pop {r0}

	//r0 already contains the file
	ldr r1, =out		// Load the string
	mov r2, #len_out	// Load the size of the string
	mov r7, #4		// Set the system call to write 
	svc #0			// Do the system call

set_direction_write_end:

	/*
	 At this point we have the file descriptor in r0 and the file write has been written to.
	 So we have to close the system call
	*/
	
	mov r0, r5
	mov r7, #6	// Set the system call to close
	svc #0		// Do the system call
	
	// Restore the r0 to r7 and lr
	pop {r0-r7, lr}
	// Return
	bx lr

// END set_direction

/*
 This functions that selects between the 2 possible strings for a pin and opens the file for pin, in read mode

 r0 - pin
 r1 - file for x
 r2 - file for xx

*/
select_file_read:
	push {r1-r7, lr}

	// Save r0
	push {r0}

	// Calculate the size of the string
	bl calculate_end

	// Store the size of the string in r2
	mov r3, r0
	
	// Restore r0
	pop {r0}
	
	/*
	 Now we to partially validate the pin name to check if name has 2 numbers or just 1.
	 If the pin name has 2 numbers then run the file_xX if not then run the normal
	 one which will deal with 1 number
	*/
	cmp r3, #2		    // Compare r2 (size of the pin string) with 2
	blgt err_invalid_arguments  // If the pin is invalid then run the invalid arguments function
	bleq select_file_read_xx    // If the pin size is 2 then run the set_direction_xx part
	cmp r3, #0		    // Compare r2 (size of the pin string) with 0 
	bleq err_invalid_arguments  // If it's equals to 0 then run the invalid arguments function

// select_file_read_x

	// Get the 1st character from the pin string and store it in r2
	ldrb r2, [r0]
	
	/*
	 Why are we setting and offset of 20?

	 Because if you look at pathtodirectionx "/sys/class/gpio/gpiox/direction" the value that can
	 be changed, is the "x" which is at position 20
	*/
	mov r4, #20

	// Update the string
	strb r2, [r1, r4]
	
	mov r0, r1
	mov r1, #0x0	// Set the mode to write
	mov r2, #0	// No permissions are needed since we are not creating a file 
	mov r7, #5	// Set the system call to open
	svc #0		// Do the system call
	
	// Jump to the end of the function and don't open the file again
	bl select_file_read_end

/*
 This will try to open the file assuming that the pin has the length of 2
*/
select_file_read_xx:
	// Store the 1st character of the pin in r1
	ldrb r1, [r0]
	// Create and offset of 1
	mov r4, #1
	// Store the 2nd character of the pin in r3
	ldrb r3, [r0, r4]
	
	// Set the offset has 20
	mov r4, #20
	
	// Update the 1st character
	strb r1, [r2, r4]
	// Update the offset
	add r4, #1
	// Update the 2nd character
	strb r3, [r2, r4]

	mov r0, r2
	mov r1, #0x0	// Set the mode to write 
	mov r2, #0	// There are no permissions since we are not creating a new file
	mov r7, #5	// Set the system call to open
	svc #0		// Do the system call

// By this point the file descriptor should be on r0
select_file_read_end:
	
	//Check the descriptor for errors
	bl errfile
	
	// Restore the saved pointers
	pop {r1-r7, lr}

	// Return
	bx lr

/*
 This functions that selects between the 2 possible strings for a pin and opens the file for pin

 r0 - pin
 r1 - file for x
 r2 - file for xx

*/
select_file:
	push {r1-r7, lr}

	// Save r0
	push {r0}

	// Calculate the size of the string
	bl calculate_end

	// Store the size of the string in r2
	mov r3, r0
	
	// Restore r0
	pop {r0}
	
	/*
	 Now we to partially validate the pin name to check if name has 2 numbers or just 1.
	 If the pin name has 2 numbers then run the file_xX if not then run the normal
	 one which will deal with 1 number
	*/
	cmp r3, #2		    // Compare r2 (size of the pin string) with 2
	blgt err_invalid_arguments  // If the pin is invalid then run the invalid arguments function
	bleq select_file_xx	    // If the pin size is 2 then run the set_direction_xx part
	cmp r3, #0		    // Compare r2 (size of the pin string) with 0 
	bleq err_invalid_arguments  // If it's equals to 0 then run the invalid arguments function

// select_file_x

	// Get the 1st character from the pin string and store it in r2
	ldrb r2, [r0]
	
	/*
	 Why are we setting and offset of 20?

	 Because if you look at pathtodirectionx "/sys/class/gpio/gpiox/direction" the value that can
	 be changed, is the "x" which is at position 20
	*/
	mov r4, #20

	// Update the string
	strb r2, [r1, r4]
	
	mov r0, r1
	mov r1, #0x1	// Set the mode to write
	mov r2, #0	// No permissions are needed since we are not creating a file 
	mov r7, #5	// Set the system call to open
	svc #0		// Do the system call
	
	// Jump to the end of the function and don't open the file again
	bl select_file_end

/*
 This will try to open the file assuming that the pin has the length of 2
*/
select_file_xx:
	// Store the 1st character of the pin in r1
	ldrb r1, [r0]
	// Create and offset of 1
	mov r4, #1
	// Store the 2nd character of the pin in r3
	ldrb r3, [r0, r4]
	
	// Set the offset has 20
	mov r4, #20
	
	// Update the 1st character
	strb r1, [r2, r4]
	// Update the offset
	add r4, #1
	// Update the 2nd character
	strb r3, [r2, r4]

	mov r0, r2
	mov r1, #0x1	// Set the mode to write 
	mov r2, #0	// There are no permissions since we are not creating a new file
	mov r7, #5	// Set the system call to open
	svc #0		// Do the system call

// By this point the file descriptor should be on r0
select_file_end:
	
	//Check the descriptor for errors
	bl errfile
	
	// Restore the saved pointers
	pop {r1-r7, lr}

	// Return
	bx lr

/*


 This function disables a pin

 This function expects the r0 as the pin name

*/
unloadpin:
	// Save the r1 and lr registers
	push {r1, lr}
	
	// Load the path to unexport into r1
	ldr r1, =pathtounexport
	// Call the dealpin_eu(export/unexport) function
	bl dealpin_eu
	
	// Restore the r1 and lr registers
	pop {r1, lr}
	// Return
	bx lr

// END unloadpin

/*


 This function enables a pin

 This function expects the r0 as the pin name

*/
loadpin:
	// Save the r1 and lr registers
	push {r1, lr}
	
	// Load the path to export into r1
	ldr r1, =pathtoexport
	// Call the dealpin_eu(export/unexport) function
	bl dealpin_eu
	
	// Restore the r1 and lr registers
	pop {r1, lr}
	// Return
	bx lr

// END loadpin

/*

 This function writes to a file the pin name 
 The function expects:
 r0 to be the pin name 
 r1 to be the file name

*/
dealpin_eu:
	// Save the r1 to r7 and lr registers
	push {r0-r7, lr}

	/*
	 Start by opeing the file
	*/

	// Save the r0, which has the pin name
	push {r0}

	mov r0, r1	// Move the file name into the r1
	mov r1, #0x1	// We just want to write to the file
	mov r7, #5	// The set the system call to write  
	svc #0		// Do the system call

	bl errfile	// Check the if the file was open correctly
	mov r5, r0	// Store the file descriptor in r5

	/*
	 Now we can write to the file
	*/
	
	// Restore the pin name, but restore into the r1 register instead of the r0
	pop {r1}

	mov r0, r1 	// Copy the pin name from r1 to r0 because the calculate_end takes the
			// the string on r0	
	
	// Calculate the size of the string
	bl calculate_end
	// Save the size of the string in r2
	mov r2, r0
	
	// Copy the file descriptor from r5 to r0
	mov r0, r5

	/*
	 Now we have:
	 r0 - file descriptor
	 r1 - string of the pin
	 r2 - size of the string
	*/
	mov r7, #4  	// Set the system call to write
	svc #0		// Do the system call	

	/*
	 Now we can close the file
	*/
	
	mov r0, r5
	mov r7, #6	// Set the system call to close
	svc #0		// Do the system call
	
	// Restore the r1 to r7, and lr registers
	pop {r0-r7, lr}
	// Return
	bx lr

// END dealpin_eu

/*


 This function calculates where the '\n' is on a string
 
 This function expects ro to be pointer to the string

*/
calculate_end:
	// Save the r1 to r7 and lr registers
	push {r1-r7, lr}
	
	/*
	 This creates an offset the offset starts at 0 because that is where the we 
	 want to start checking
	*/
	mov r1, #0

// Create a loop jump point
calculate_end_loop:
	
	// Load the from the current position(r0 + r1) of the string into r2
	ldrb r2, [r0, r1]
	
	/*
	 Compare the value of r2, which was already loaded from the string,
	 with 10 which is the value of the character '\n'
	*/
	cmp r2, #10
	// If the number they are not the same then increase the offset by one
	addne r1, #1
	// If the number are not the same then repeat this loop step
	blne calculate_end_loop
	
	// Copy the size from r1 to r0
	mov r0, r1
	
	// Restore the r1 to r7 and lr registers
	pop {r1-r7, lr}
	// Return
	bx lr

// End CALCULATE_END

// Print the invalid arguments message and exit the program
err_invalid_arguments:

	mov r0, #2				// Set the output to stderr
	ldr r1, =errorinvalidargument		// Set the string as error invalid argument 
	mov r2, #len_errorinvalidargument	// Set the length of that string
	mov r7, #4				// Set the system call to write
	svc #0					// Do the system call

	mov r0, #1				// Set the exit code to 1
	mov r7, #1				// Set the system call to exit
	svc #0					// Do the system call

/*
 Function that deals with checking error on open files
 This function expects the file descriptor to be on r0
*/
errfile:
	cmp r0, #-1			// Check if the is valid
	bxgt lr				// If the file is valid then return
	
	mov r0, #2			// Set the output to stderr
	ldr r1, =errorfilemessage	// Set the string to be the error file string
	mov r2, #len_errorfilemessage	// Set the length of that string
	mov r7, #4			// Set the system call to write
	svc #0				// Do the system cal

	mov r0, #1			// Set the exit code to 1
	mov r7, #1			// Set the system call to exit
	svc #0				// Do the system call
