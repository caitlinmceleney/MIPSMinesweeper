##############################################################
# Homework #3
# name: Caitlin McEleney

##############################################################
.text

##############################
# PART 1 FUNCTIONS
##############################

smiley:
    	li $t0, 0xffff0000	#start at 0,0 square
    	li $t1, '\0'		#load a blank square (no symbol) for all
    	li $t2, 0x0f		#loads black background and white foreground
    	li $t3, 0xffff00c7	#loads the last square location
    	li $t4, 0		#to clear out everything first
    	
    	blackBackground:
    		bgt $t0, $t3, drawSmile		#if past the last square, branch
    		sb $t1, 0($t0)			#store the null
    		sb $t2, 1($t0)			#store the colors
    		addi $t0, $t0, 2		#increment to the next box
    		j blackBackground
    	drawSmile:
    		li $t0, 'b'	#set $t0 to bomb for the eyes
    		li $t1, 0xb7	#set $t1 to colors for the eyes
    		li $t2, 0xffff002e	#load (2,3) eye
    		sb $t0, 0($t2)
    		sb $t1, 1($t2)
    		li $t2, 0xffff0042	#load (3,3) eye
    		sb $t0, 0($t2)
    		sb $t1, 1($t2)
    		li $t2, 0xffff0034	#load (2,6) eye
    		sb $t0, 0($t2)
    		sb $t1, 1($t2)
    		li $t2, 0xffff0048	#load (3,6) eye
    		sb $t0, 0($t2)
    		sb $t1, 1($t2)
    		
    		li $t0, '\0'
    		li $t1, 0x0f
    		li $t2, 0xffff0036
    		sb $t0, 0($t2)
    		sb $t1, 1($t2)
    		li $t2, 0xffff004a
    		sb $t0, 0($t2)
    		sb $t1, 1($t2)
 
    		
    		li $t0, 'e'	#set $t0 to explosion thing
    		li $t1, 0x1f	#set mount color
    		li $t2, 0xffff007c	#load (6,2) mouth
    		sb $t0, 0($t2)
    		sb $t1, 1($t2)
    		li $t2, 0xffff0092	#load (7,3) mouth
    		sb $t0, 0($t2)
    		sb $t1, 1($t2)
    		li $t2, 0xffff00a8	#load (8,4) mouth
    		sb $t0, 0($t2)
    		sb $t1, 1($t2)
    		li $t2, 0xffff00aa	#load (8,5) mouth
    		sb $t0, 0($t2)
    		sb $t1, 1($t2)
    		li $t2, 0xffff0098	#load (7,6) mouth
    		sb $t0, 0($t2)
    		sb $t1, 1($t2)
    		li $t2, 0xffff0086	#load (6,7) mouth
    		sb $t0, 0($t2)
    		sb $t1, 1($t2)			
	jr $ra

##############################
# PART 2 FUNCTIONS
##############################

open_file:		#a0 is given file
	li $a1, 0	#read only
    	li $a2, 0	#read only	
    	li $v0 , 13	#v0 read file code
    	#li $v0, -200
    	syscall
    	jr $ra

close_file:	
	li $v0, 16	#close file code
	move $a0, $a0	#file descriptor to close
	syscall
	#i $v0, -200
    	jr $ra

load_map:		#cells_array $a1
	addi $sp, $sp, -4
	sw $ra, 0($sp)			#to use jal
	la $t0, array_transfer		#location to store coordinates
	li $t1, 0			#coordinate counter
	la $t2, read_file_buffer 	#buffer to hole single char
	move $t9, $a1			#cell_array address into $t9

	readMapLoop:
	li $v0, 14			#read file
	la $a1, ($t2)			#space for byte loaded into read_file_buffer
	li $a2, 1			#read one byte
	syscall
	
	beq $v0, 0, bombCoordinates		#nothing left, file finished
	beq $v0, -1, invalidInput	#if there is an error, it will return -1
	
	lb $t3, 0($t2)			#byte to read in from file
	
	blt $t3, '0', invalidCheck	#if it is not a number, check for good case
    	bgt $t3, '9', invalidCheck	
	j valid
	
	invalidCheck:
	beq $t3, ' ', readMapLoop
    	beq $t3, '\r', readMapLoop
    	beq $t3, '\t', readMapLoop
    	beq $t3, '\n', readMapLoop
	j invalidInput

	
	valid:
	addi $t3, $t3, -0x30
	sb $t3, 0($t0)		#store into array transfer
	addi $t0, $t0, 1	#increment pointer
	addi $t1, $t1, 1	#increment byte counter
	bgt $t1, 198, invalidInput	#cannot have over 100 bytes stored
	j readMapLoop
	
	bombCoordinates:		#read the bomb locations
	li $t3, -1
	sb $t3, 0($t0)
	li $t0, 2
	div $t1, $t0
	mfhi $t0
	bgtz $t0, invalidInput
	
	endBombLoop:			#$t9 holds cells_array address
	la $t0, array_transfer
	#la $t1, ($t9)			#cells_array address now in $t1
	li $t2, 0			#counter
	
	cellArrayLoop:
	li $t3, 10			# # of col, datalength = 1, not needed
	lb $t4, 1($t0)			#first coord
	lb $t5, 0($t0)			#second coord
	addi $t2, $t2, 1		#increment cell counter
	
	mul $t6, $t4, $t3		# i * #col
	add $t6, $t5, $t6		# i * col + j
	add $t1, $t9, $t6		#add to cell array bomb location
	
	#load bomb
	lb $t6, 0($t1)			#load the byte of $t1 into $t4
	bge $t6, 0x20, endBombLoopEnd	#check if there is already a bomb
	li $t6, 0x20			#change from 0x00 to indicate bomb
	sb $t6, 0($t1)			#store back in $t1
	li $t7, 0
	li $t8, 0
	#add adjacent bombs		#$t4 has i, $t5 has j
	
	#left
	addi $t7, $t4, -1
	addi $t8, $t5, -1
	jal adjBombCheck
	
	addi $t7, $t4, -1
	addi $t8, $t5, 1
	jal adjBombCheck
	
	addi $t7, $t4, -1
	addi $t8, $t5, 0
	jal adjBombCheck
	#middle
	addi $t7, $t4, 0
	addi $t8, $t5, -1
	jal adjBombCheck
	
	addi $t7, $t4, 0
	addi $t8, $t5, 1
	jal adjBombCheck
	#right
	addi $t7, $t4, 1
	addi $t8, $t5, -1
	jal adjBombCheck
	
	addi $t7, $t4, 1
	addi $t8, $t5, 1
	jal adjBombCheck
	
	addi $t7, $t4, 1
	addi $t8, $t5, 0
	jal adjBombCheck
	
	endBombLoopEnd:
	addi $t0, $t0, 2		#increment to next coords
	lb $t3, 0($t0)
	bltz $t3, endOfFile
	j cellArrayLoop
	
	adjBombCheck:	#check for valid row/column
	beq $t7, -1, outOfBounds
	beq $t8, -1, outOfBounds
	beq $t7, 10, outOfBounds
	beq $t8, 10, outOfBounds
	li $t6, 10			#to do array manip
	mul $t1, $t7, $t6		#finding data location in cells array
	add $t1, $t8, $t1
	add $t1, $t9, $t1
	lb $t7, 0($t1)
	addi $t7, $t7, 1
	sb $t7, 0($t1)
	jr $ra
	
	outOfBounds:
	jr $ra
	
	invalidInput:
	li $v0, -1
	lw $ra, ($sp)
	addi $sp, $sp, 4
	jr $ra
	
	endOfFile:		#add back $sp
	lw $ra, ($sp)
	addi $sp, $sp, 4
	li $v0, 0    	
    	jr $ra

##############################
# PART 3 FUNCTIONS
##############################

init_display:
    li $t0, '\0'		#sets all locations to null
    la $t1, 0xffff0000		#starting location
    li $t2, 0x70		#gray
    li $t3, 0xffff00c7
    setGray:
    	bge $t1, $t3, setCursorInfo	#if at last cell
    	sb $t0, 0($t1)		#null
    	sb $t2, 1($t1)		#color
    	addi $t1, $t1, 2
    	j setGray
    setCursorInfo:
	li $t0, 0xffff0000		#starting location
    	li $t1, 0xb0			#cursor color
    	sw $0, cursor_row
    	sw $0, cursor_col			#set starting locations of cursors to 0,0
    	sb $t1, 1($t0)
    jr $ra

set_cell:
    move $t0, $a0	#cursor_row to $t0
    move $t1, $a1	#cursor_col to $t1
    move $t2, $a2	#character to display
    
    bgt $t0, 9, invalidSetCell	# 0 <= row < 10 && 0 <= col <10
    bgt $t1, 9, invalidSetCell
    blt $t0, 0, invalidSetCell
    blt $t1, 0, invalidSetCell
    
    move $t3, $a3	#foreground color
    lw $t4, 0($sp)	#push the background color onto the stack
   
    blt $t3, 0, invalidSetCell	#0<=FG<=15 && 0<=BG<=15
    blt $t4, 0, invalidSetCell
    bgt $t4, 15, invalidSetCell
    bgt $t3, 15, invalidSetCell
    
    li $t5, 10			# # of col
    li $t6, 2			#data length
    mul $t0, $t0, $t5		#i * col #
    add $t0, $t0, $t1		#(i*col) + j
    mul $t0, $t0, $t6		#i(i*col+j) * Dl
    li $t5, 0xffff0000		#starting address
    add $t5, $t0, $t5		#add to address
    
    sll $t3, $t3, 4
    add $t3, $t3, $t4		#add background and foreground
    
    sb $t2, 0($t5)		#add display char
    sb $t3, 1($t5)		#add color
    li $v0, 0
    jr $ra
    
    invalidSetCell:
    li $v0, -1
    jr $ra

reveal_map:			#a0 = game status, $a1 = cells_array
	addi $sp, $sp, -16
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	move $t0, $a0		#game status 1: won, 0: ongoing, -1: lost
	
	move $s0, $a1		#cells_array
	
	beq $t0, -1, startloss	#check game status
	beq $t0, 0, ongoing
	beq $t0, 1, won
	
	startloss:
	li $s1, 0
	li $s2, 0
	
	lost:
	lw $a0, cursor_row
	lw $a1, cursor_col	#load the location in appropriate registers for set_cell
	li $a2, 'e'		#explosion in $a2 to send to set cell
	li $a3, 0x0f		#foreground color
	li $t2, 0x09		#bg color
	addi $sp, $sp, -4	#to load the color and $ra on the stack
	sw $t2, 0($sp)		#load the bg color onto the stack
	jal set_cell
	addi $sp, $sp, 4
	
	lossLoop:
 	
 	notRevealed:
 	lb $t2, 0($s0)		#does the cell contain a bomb? 1: yes, 0: no
 	andi $t3, $t2, 0x30
 	move $a0, $s1
 	move $a1, $s2
 	beq $t3, 0x30,	isFlagged
 	beq $t3, 0x20,	notFlagged
 	beq $t3, 0x10,	flagNoBomb
 	j notBombCell
 	
 	flagNoBomb:
 	li $a2, 'f'	#flag
 	li $a3, 0x1	#red
 	li $t4, 0xa	#blue
 	addi $sp, $sp, -4
 	sw $t4, ($sp)
 	jal set_cell
 	addi $sp, $sp, 4
 	j lossLoopEnd
 	
 	isFlagged:		#correct bomb flag location
 	li $a2, 'f'	#flag
 	li $a3, 0xc	#green
 	li $t4, 0xa	#blue
 	addi $sp, $sp, -4
 	sw $t4, ($sp)
 	jal set_cell
 	addi $sp, $sp, 4
 	j lossLoopEnd
 	
 	notFlagged:		#is a bomb location but wasn't flagged
 	li $a2, 'b'		#bomb
 	li $a3, 0x0		#black
 	li $t4, 0x7		#gray
 	addi $sp, $sp, -4
 	sw $t4, ($sp)
 	jal set_cell
 	addi $sp, $sp, 4
 	j lossLoopEnd
 	
 	notBombCell:		#not revealed and isn't a bomb cell
 	li $a3, 0x0		#magenta
 	li $t4, 0xd		#black bg
 	lb $t8, 0($s0)		#load the byte that says # of bombs adjacent to the cell
 	andi $t8, $t8, 0x0F
 	beq $t8, 0, num0
 	beq $t8, 1, num1
 	beq $t8, 2, num2
 	beq $t8, 3, num3
 	beq $t8, 4, num4
 	beq $t8, 5, num5
 	beq $t8, 6, num6
 	beq $t8, 7, num7
 	beq $t8, 8, num8
 	j gameExit
 	
 	num0:
 	li $a2, '\0'
 	addi $sp, $sp, -4
 	sw $t4, ($sp)
 	jal set_cell
 	addi $sp, $sp, 4
 	j lossLoopEnd
 	
 	num1:
 	li $a2, '1'
 	addi $sp, $sp, -4
 	sw $t4, ($sp)
 	jal set_cell
 	addi $sp, $sp, 4
 	j lossLoopEnd
 	
 	num2:
 	li $a2, '2'
 	addi $sp, $sp, -4
 	sw $t4, ($sp)
 	jal set_cell
 	addi $sp, $sp, 4
 	j lossLoopEnd
 	
 	num3:
 	li $a2, '3'
 	addi $sp, $sp, -4
 	sw $t4, ($sp)
 	jal set_cell
 	addi $sp, $sp, 4
 	j lossLoopEnd
 	
 	num4:
 	li $a2, '4'
 	addi $sp, $sp, -4
 	sw $t4, ($sp)
 	jal set_cell
 	addi $sp, $sp, 4
 	j lossLoopEnd
 	
 	num5:
 	li $a2, '5'
 	addi $sp, $sp, -4
 	sw $t4, ($sp)
 	jal set_cell
 	addi $sp, $sp, 4
 	j lossLoopEnd
 	
 	num6:
 	li $a2, '6'
 	addi $sp, $sp, -4
 	sw $t4, ($sp)
 	jal set_cell
 	addi $sp, $sp, 4
 	j lossLoopEnd
 	
 	num7:
 	li $a2, '7'
 	addi $sp, $sp, -4
 	sw $t4, ($sp)
 	jal set_cell
 	addi $sp, $sp, 4
 	j lossLoopEnd
 	
 	num8:
 	li $a2, '8'
 	addi $sp, $sp, -4
 	sw $t4, ($sp)
 	jal set_cell
 	addi $sp, $sp, 4
 	j lossLoopEnd
 	
 	lossLoopEnd:
 	addi $s0, $s0, 1
 	addi $s1, $s1, 1
 	blt $s1, 10, lossLoop
 	li $s1, 0
 	addi $s2, $s2, 1
 	blt $s2, 10, lossLoop
 	j gameExit
 	
 	revealedCell:
 	addi $a1, $a1, 1	#incrememnt cells_array location
 	addi $t0, $t0, 2	#increment starting address
 	j lossLoop
	
	ongoing:
	li $v0, 0
	j gameExit
	
	won:	
	jal smiley
	li $v0, 2
	j gameExit
   
    
    gameExit:
 	
 	lw $ra, 0($sp)
 	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	addi $sp, $sp, 16
    
    jr $ra


##############################
# PART 4 FUNCTIONS
##############################

perform_action:
     addi $sp, $sp, -4
     sw $ra, 0($sp)
    
    beq $a1, 'f', flag
    beq $a1, 'F', flag
    #beq $a1, 'r', reveal
    #beq $a1, 'R', reveal
    beq $a1, 'w', up
    beq $a1, 'W', up
    beq $a1, 'a', left
    beq $a1, 'A', left
    beq $a1, 's', down
    beq $a1, 'S', down
    beq $a1, 'd', right
    beq $a1, 'D', right
    j invalidMove
    
    flag:
    la $t0, ($a0)		#transfer cells_array to $t0
    lw $t1, cursor_row		#cursor row - i
    lw $t2, cursor_col		#cursor column - j
    li $t3, 10			# #col	-> cells_array bytes are 1 length
    li $t5, 0xffff0000
    mul $t4, $t1, $t3		#i * #col
    add $t4, $t4, $t2		#i * col + j
    add $t7, $t0, $t4		#address in cells_array
    
    lb $t2, 0($t7)
    andi $t6, $t2, 0x40		#revealed?
    beq $t6, 0x40, invalidMove	#if is has been revealed already, no flag
    
    li $t6, 0
    andi $t6, $t2, 0x10			#check for flag
    beq $t6, 0x10, alreadyFlagged	#if equal it is flagged
    addi $t6, $t2, 0x10			#if not flagged, add a flag
    sb $t6, 0($t0)			#store flag in 
    lw $a0, cursor_row			#row to $a0
    lw $a1, cursor_col			#col to $a1
    li $a2, 'f'
    li $a3, 0xB
    li $t4, 0x4
    addi $sp, $sp, -4
    sw $t4, ($sp)
    jal set_cell
    addi $sp, $sp, 4
    j exitPerform_action
    
    alreadyFlagged:
    addi $t6, $t2, -0x10
    sb $t6, 0($t0)
    lw $a0, cursor_row			#row to $a0
    lw $a1, cursor_col			#col to $a1
    li $a2, '\0'
    li $a3, 0x7
    li $t4, 0x0
    addi $sp, $sp, -4
    sw $t4, ($sp)
    jal set_cell
    addi $sp, $sp, 4
    j exitPerform_action
    
    reveal:
    la $t0, ($a0)		#transfer cells_array to $t0
    lw $t1, cursor_row		#cursor row - i
    lw $t2, cursor_col		#cursor column - j
    li $t3, 10			# #col	-> cells_array bytes are 1 length
    mul $t4, $t1, $t3		#i * #col
    add $t4, $t4, $t2		#i * col + j
    add $t7, $t0, $t4		#address in cells_array
   
    lb $t0, ($t7)		#load the byte from cells array
    andi $t1, $t0, 0x40		#revealed?
    beq $t1, 0x40, invalidMove
    andi $t1, $t0, 0x20		#bomb?
    beq $t1, 0x20, gameOver
    #andi $t1, $t0, 0x10		#flag?
    #beq $t1, 0x10, flaggedReveal
   
    addi $t0, $t0, 0x40		#mark in cells array as revealed
    andi $t1, $t0, 0x0f		#check value of bomb counter
   
    beq $t1, 0, reveal0
    beq $t1, 1, reveal1
    beq $t1, 2, reveal2
    beq $t1, 3, reveal3
    beq $t1, 4, reveal4
    beq $t1, 5, reveal5
    beq $t1, 6, reveal6
    beq $t1, 7, reveal7
    beq $t1, 8, reveal8		#8 surrounding bombs max
    j exitPerform_action
   
    reveal0:
    lw $a0, cursor_row			#row to $a0
    lw $a1, cursor_col			#col to $a1
    li $a2, '\0'
    li $a3, 0x00
    li $t4, 0x00
    addi $sp, $sp, -4
    sw $t4, ($sp)
    jal set_cell
    addi $sp, $sp, 4
    j exitPerform_action
   
    reveal1:
    lw $a0, cursor_row			#row to $a0
    lw $a1, cursor_col			#col to $a1
    li $a2, '1'
    li $a3, 0xd
    li $t4, 0xb0
    addi $sp, $sp, -4
    sw $t4, ($sp)
    jal set_cell
    addi $sp, $sp, 4
    j exitPerform_action
   
    reveal2:
    lw $a0, cursor_row			#row to $a0
    lw $a1, cursor_col			#col to $a1
    li $a2, '2'
    li $a3, 0xd
    li $t4, 0xb0
    addi $sp, $sp, -4
    sw $t4, ($sp)
    jal set_cell
    addi $sp, $sp, 4
    j exitPerform_action
   
    reveal3:
    lw $a0, cursor_row			#row to $a0
    lw $a1, cursor_col			#col to $a1
    li $a2, '3'
    li $a3, 0xd
    li $t4, 0xb0
    addi $sp, $sp, -4
    sw $t4, ($sp)
    jal set_cell
    addi $sp, $sp, 4
    j exitPerform_action
   
    reveal4:
    lw $a0, cursor_row			#row to $a0
    lw $a1, cursor_col			#col to $a1
    li $a2, '4'
    li $a3, 0xd
    li $t4, 0xb0
    addi $sp, $sp, -4
    sw $t4, ($sp)
    jal set_cell
    addi $sp, $sp, 4
    j exitPerform_action
   
    reveal5:
    lw $a0, cursor_row			#row to $a0
    lw $a1, cursor_col			#col to $a1
    li $a2, '5'
    li $a3, 0xd
    li $t4, 0xb0
    addi $sp, $sp, -4
    sw $t4, ($sp)
    jal set_cell
    addi $sp, $sp, 4
    j exitPerform_action
   
    reveal6:
    lw $a0, cursor_row			#row to $a0
    lw $a1, cursor_col			#col to $a1
    li $a2, '6'
    li $a3, 0xd
    li $t4, 0x00
    addi $sp, $sp, -4
    sw $t4, ($sp)
    jal set_cell
    addi $sp, $sp, 4
    j exitPerform_action
   
    reveal7:
    lw $a0, cursor_row			#row to $a0
    lw $a1, cursor_col			#col to $a1
    li $a2, '7'
    li $a3, 0xd
    li $t4, 0xb0
    addi $sp, $sp, -4
    sw $t4, ($sp)
    jal set_cell
    addi $sp, $sp, 4
    j exitPerform_action
   
    reveal8:
    lw $a0, cursor_row			#row to $a0
    lw $a1, cursor_col			#col to $a1
    li $a2, '8'
    li $a3, 0xd
    li $t4, 0xb0
    addi $sp, $sp, -4
    sw $t4, ($sp)
    jal set_cell
    addi $sp, $sp, 4
    j exitPerform_action
   
    #flaggedReveal:
    #addi $t0, $t0, -0x10	#remove flag
    #andi $t1, $t0, 0x20		#bomb?
    #beq $t1, 0x20, gameOver	#bomb -> game over
    #j reveal			#now unflagged, go reveal
   
    gameOver:
    addi $t0, $t0, 0x40		#add revealed to bomb cell
    sb $t0, 0($t9)
    li $v0, 0
    j exitPerform_action
   
    up:
    la $t0, ($a0)		#transfer cells_array to $t0
    lw $t1, cursor_row
    lw $t2, cursor_col
    beqz $t1, invalidMove	#column less than zero
    li $t3, 10			# #col
 
    mul $t3, $t1, $t3		# i * #col
    add $t3, $t3, $t2		# (i* col) + j
    add $t4, $t0, $t3		#load location in cells array into $t3
    
    lb $t5, 0($t4)		#load the byte from cells arrat
    andi $t5, $t5, 0x40		#revealed?
    beq $t5, 0x40, upRevealed	#if is has been revealed already, no flag
    j upNotRevealed

    upRevealed:
     #$t3 holds address value
    li $t2, 2		#data type
    mul $t3, $t3, $t2	# (i * Col + j)* data type
    li $t2, 0xffff0000	#base address for mmio
    add $t2, $t2, $t3	#cell address in mmio
	#change current cell
    lh $t1, ($t2) 		#load info
    andi $t1, $t1, 0x0fff	#black background, keeps fg
    sh $t1, ($t2)
    #change cell going to
    lh $t1, -20($t2)
    andi $t1, $t1, 0x0fff	#black bg, preserve fg
    ori $t1, $t1, 0xb000		#bg yellow
    sh $t1, -20($t2)
   
    lw $t0, cursor_row		#send down a row
    addi $t0, $t0, -1
    sw $t0, cursor_row
    
    j exitPerform_action
    
   upNotRevealed:
   li $t2, 2		#data type
    mul $t3, $t3, $t2	# (i * Col + j)* data type
    li $t2, 0xffff0000	#base address for mmio
    add $t2, $t2, $t3	#cell address in mmio
    
    #change current cell
    lh $t1, ($t2) 		#load info
    andi $t1, $t1, 0x0fff	#black background, keeps fg
    ori $t1, $t1, 0x7000
    sh $t1, ($t2)
   #change cell going to
    #addi $t4, $t4, 20		#get above 
    lh $t1, -20($t2)
    andi $t1, $t1, 0x0fff	#black bg, preserve fg
    ori $t1, $t1, 0xb000		#bg yellow
    sh $t1, -20($t2)
    
    lw $t0, cursor_row		#send counter up a column
    addi $t0, $t0, -1
    sw $t0, cursor_row
    
    j exitPerform_action
    
    
    left:
    la $t0, ($a0)		#transfer cells_array to $t0
    lw $t1, cursor_row
    lw $t2, cursor_col
    beqz $t2, invalidMove	#column less than zero
    li $t3, 10			# #col
    bge $t1, 10, invalidMove	#if going past num of col

    mul $t3, $t1, $t3		# i * #col
    add $t3, $t3, $t2		# (i* col) + j
    add $t4, $t0, $t3		#load location in cells array into $t3
    
    lb $t5, 0($t4)		#load the byte from cells arrat
    andi $t5, $t5, 0x40		#revealed?
    beq $t5, 0x40, leftRevealed	#if is has been revealed already, no flag
    j leftNotRevealed
    
    
    leftRevealed:
    #$t3 holds address value
    li $t2, 2		#data type
    mul $t3, $t3, $t2	# (i * Col + j)* data type
    li $t2, 0xffff0000	#base address for mmio
    add $t2, $t2, $t3	#cell address in mmio
	#change current cell
    lh $t1, ($t2) 		#load info
    andi $t1, $t1, 0x0fff	#black background, keeps fg
    #ori $t1, $t1, 0x7000
    sh $t1, ($t2)
    #change cell going to
    		#get above 
		#get above 
    lh $t1, -2($t2)
    andi $t1, $t1, 0x0fff	#black bg, preserve fg
    ori $t1, $t1, 0xb000		#bg yellow
    sh $t1, -2($t2)
   
    lw $t0, cursor_col		#send down a row
    addi $t0, $t0, -1
    sw $t0, cursor_col
    
    j exitPerform_action
    
    leftNotRevealed:
#$t3 holds address value
    li $t2, 2		#data type
    mul $t3, $t3, $t2	# (i * Col + j)* data type
    li $t2, 0xffff0000	#base address for mmio
    add $t2, $t2, $t3	#cell address in mmio
    
    #change current cell
    lh $t1, ($t2) 		#load info
    andi $t1, $t1, 0x0fff	#black background, keeps fg
    ori $t1, $t1, 0x7000
    sh $t1, ($t2)
   #change cell going to
    #addi $t4, $t4, 20		#get above 
    lh $t1, -2($t2)
    andi $t1, $t1, 0x0fff	#black bg, preserve fg
    ori $t1, $t1, 0xb000		#bg yellow
    sh $t1, -2($t2)

    
    lw $t0, cursor_col		#send back a col
    addi $t0, $t0, -1
    sw $t0, cursor_col
    
    j exitPerform_action
    
    
    down:
    la $t0, ($a0)		#transfer cells_array to $t0
    lw $t1, cursor_row
    lw $t2, cursor_col
    bge $t1, 9, invalidMove	#if row = 0, top row, cannot move up
    li $t3, 10			# #col
    
    mul $t3, $t1, $t3		# i * #col
    add $t3, $t3, $t2		# (i* col) + j
    add $t4, $t0, $t3		#load location in cells array into $t3
    
    lb $t4, 0($t4)		#load the byte from cells array
    andi $t4, $t4, 0x40		#revealed?
    beq $t4, 0x40, downRevealed	#if is has been revealed already, no flag
    j downNotRevealed
    
    downRevealed:
    #$t3 holds address value
    li $t2, 2		#data type
    mul $t3, $t3, $t2	# (i * Col + j)* data type
    li $t2, 0xffff0000	#base address for mmio
    add $t2, $t2, $t3	#cell address in mmio
	#change current cell
    lh $t1, ($t2) 		#load info
    andi $t1, $t1, 0x0fff	#black background, keeps fg
    #ori $t1, $t1, 0x7000
    sh $t1, ($t2)
    #change cell going to
    		#get above 
    #addi $t4, $t4, 20		#get above 
    lh $t1, 20($t2)
    andi $t1, $t1, 0x0fff	#black bg, preserve fg
    ori $t1, $t1, 0xb000		#bg yellow
    sh $t1, 20($t2)
   
    lw $t0, cursor_row		#send down a row
    addi $t0, $t0, 1
    sw $t0, cursor_row
   
    j exitPerform_action
    
    downNotRevealed:
	#$t3 holds address value
    li $t2, 2		#data type
    mul $t3, $t3, $t2	# (i * Col + j)* data type
    li $t2, 0xffff0000	#base address for mmio
    add $t2, $t2, $t3	#cell address in mmio
    
    #change current cell
    lh $t1, ($t2) 		#load info
    andi $t1, $t1, 0x0fff	#black background, keeps fg
    ori $t1, $t1, 0x7000
    sh $t1, ($t2)
   #change cell going to
    #addi $t4, $t4, 20		#get above 
    lh $t1, 20($t2)
    andi $t1, $t1, 0x0fff	#black bg, preserve fg
    ori $t1, $t1, 0xb000		#bg yellow
    sh $t1, 20($t2)
   
    lw $t0, cursor_row		#send down a row
    addi $t0, $t0, 1
    sw $t0, cursor_row
   
    j exitPerform_action
     
    right:
    la $t0, ($a0)		#transfer cells_array to $t0
    lw $t1, cursor_row
    lw $t2, cursor_col
    bge $t2, 9, invalidMove	#if col = 9cannot, right col, cannot move right
    li $t3, 10			# #col

    mul $t3, $t1, $t3		# i * #col
    add $t3, $t3, $t2		# (i* col) + j
    add $t4, $t0, $t3		#load location in cells array into $t3
    
    lb $t5, 0($t4)		#load the byte from cells arrat
    andi $t5, $t5, 0x40		#revealed?
    beq $t5, 0x40, rightRevealed	#if is has been revealed already, no flag
    j rightNotRevealed
    
    rightRevealed:
    #$t3 holds address value
    li $t2, 2		#data type
    mul $t3, $t3, $t2	# (i * Col + j)* data type
    li $t2, 0xffff0000	#base address for mmio
    add $t2, $t2, $t3	#cell address in mmio
    #change current cell
    lh $t1, 0($t2) 		#load info
    andi $t1, $t1, 0x0fff	#black background, keeps fg
    ori $t1, $t1, 0x7000
    sb $t1, 0($t2)
    #change cell going to
   # addi $t4, $t4, 2		#get behind
    lh $t1, 2($t2)
    andi $t1, $t1, 0x0fff	#black bg, preserve fg
    ori $t1, $t1, 0xb000		#bg yellow
    sh $t1, 2($t2)
    
    lw $t0, cursor_col		#send down a column
    addi $t0, $t0, 1
    sw $t0, cursor_col
    
    j exitPerform_action
    
    rightNotRevealed:
	#$t3 holds address value
    li $t2, 2		#data type
    mul $t3, $t3, $t2	# (i * Col + j)* data type
    li $t2, 0xffff0000	#base address for mmio
    add $t2, $t2, $t3	#cell address in mmio
    #change current cell
    lh $t1, 0($t2) 		#load info
    andi $t1, $t1, 0x0fff	#black background, keeps fg
    ori $t1, $t1, 0x7000
    sh $t1, 0($t2)
    #change cell going to
    #addi $t4, $t4, -20		#get behind
    lh $t1, 2($t2)
    andi $t1, $t1, 0x0fff	#black bg, preserve fg
    ori $t1, $t1, 0xb000		#bg yellow
    sh $t1, 2($t2)
    
    lw $t0, cursor_col		#send down a column
    addi $t0, $t0, 1
    sw $t0, cursor_col
    
    j exitPerform_action
    
    exitPerform_action:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    li $v0, 0
    jr $ra
    
    invalidMove:
    lw $ra, 0($sp)
   addi $sp, $sp, 4
    li $v0, -1
    jr $ra
    
    

game_status:
    move $t0, $a0		#cell_array to $t0
    li $t1, 0
    
    checkLoss:
    bge $t1, 100, checkWin	#counter for cells
    addi $t1, $t1, 1		#increment counter
    lb $t2, ($t0)		#load the byte
    li $t3, 0x60		#check for bomb
    and $t2, $t2, $t3
    beq $t2, $t3, gameLostStatus	#if bomb
    addi $t0, $t0, 1		#increment location
    j checkLoss
    
    gameLostStatus:
    li $v0, -1
    jr $ra
    		
    checkWin:
    move $t0, $a0		#reset starting location of cells array
    li $t1, 0			#reset counter
    
    winLoop:
    bge $t1, 100, gameWon
    addi $t1, $t1, 1
    lb $t2, ($t0)		#load byte of $t0
    andi $t2, $t2, 16		#andi by 16
    beq $t2, 16, isFlag		#check for a flag
    lb $t2, ($t0)		#start over with the byte
    andi $t2, $t2, 32
    beq $t2, 32, isBomb
    addi $t0, $t0, 1
    j winLoop
    
    isFlag:
    lb $t2, ($t0)
    andi $t2, $t2, 32
    bne $t2, 32, ongoingGame
    addi $t0, $t0, 1		#increment location
    j winLoop
    
    isBomb:
    lb $t2, ($t0)
    andi $t2, $t2, 16		#check bit for bomb
    bne $t2, 16, ongoingGame
    addi $t0, $t0, 1
    j winLoop
    
    gameWon:			#game has been won
    li $v0, 1
    jr $ra
    
    ongoingGame:			#game is ongoing
    li $v0, 0
    jr $ra

##############################
# PART 5 FUNCTIONS
##############################

search_cells:
    #Define your code here
    jr $ra


#################################################################
# Student defined data section
#################################################################
.data
.align 2  # Align next items to word boundary
cursor_row: .word -1
cursor_col: .word -1
array_transfer: .space 200
read_file_buffer: .space 1

#place any additional data declarations here

