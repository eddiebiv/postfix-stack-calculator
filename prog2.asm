; This program computes postfix arithmetic using a stack. The operands and operators are
; entered by the user and are individually checked. If an operand is detected, the value
; is pushed into a stack. If an operator is detected, the stack is popped twice and the program 
; jumps to the subroutine associated with the entered operator. This continues as long as
; values are entered. The result is printed to the screen if the top of the stack ends 
; pointing at the start of the stack, indicating an empty stack.

; Register Table: 
; R0 temporary for printing (holds inputs)
; R1 checking values/ counter
; R2 printing counter
; R3 input
; R4 input
; R5 fail indicatior/ STORES SOLUTION 
; R6 restores stack and for printing
; R7 for holding PC values

.ORIG x3000
	
INPUT
		GETC			; R0 = char
		OUT

		LD R1, EQUALS		; check if input is "="
		ADD R1,R1,R0
		BRz EVALUATE

		LD R1, SPACE		; check if input is a space
		ADD R1,R1,R0
		BRz INPUT

		LD R1, CARETC		; check if input is "^"
		ADD R1,R1,R0
		BRz EVALUATE

		LD R1, MULTC		; check if input is "*"
		ADD R1,R1,R0
		BRn INVALID
		BRz EVALUATE

		ADD R1,R1,#-1		; check if "+"
		BRz EVALUATE
		ADD R1,R1,#-2		; check if "-"
		BRz EVALUATE
		ADD R1,R1,#-2		; check if "/"
		BRz EVALUATE

		LD R1, NINE		; check if input is a single digit number
		ADD R1,R1,R0
		BRp INVALID		
		LD R1, THIRTY		; convert ascii number to hex
		NOT R1,R1
		ADD R1,R1,#1
		ADD R0,R0,R1			
		JSR PUSH		; push if between 0 and 9
		BRnzp INPUT


		DONE HALT

THIRTY .FILL x0030
NINE .FILL xFFC5
SPACE .FILL xFFE0			; negative hex value for "space"
EQUALS .FILL xFFC3
MULTC .FILL xFFD6
CARETC .FILL xFFA2


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INVALID
		LEA R0, STRING
		PUTS
		HALT
	
STRING .STRINGZ "Invalid Expression"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;R3- value to print in hexadecimal
PRINT_HEX
		ST R5, HEXSAVE		; store solution to be printed
		LD R3, HEXSAVE
		AND R1,R1,#0		; clear digit counter
		ADD R1,R1,#4   		; hex digit counter
		
START
		AND R5,R5,#0		; clear R5
		AND R2,R2,#0		; clear bit counter
        	ADD R2,R2,#4        	; bit counter
LOOP
        	ADD R3,R3,#0
        	BRn NEG			; check value of R3
        	BRnzp SKIP			
NEG     	ADD R5,R5,#1		; if MSB is positive, add 1 to bit storage
SKIP    	ADD R3,R3,R3		; left shift R3
        	ADD R2,R2,#-1       	; decrement bit counter
        	BRz DIGIT		; branch when bit counter reaches zero
		ADD R5,R5,R5		; left shift bit storage register if R3 is positive
		ADD R2,R2,#0		; check bit counter value
		BRp LOOP		; branch if counter > 0

DIGIT
        	ADD R0,R5,#-9		; check if <= 9
        	BRp AMINUS
        	LD R0, NUMBER       	; load ascii zero
        	BRnzp ADDING
AMINUS  	LD R0,LETTER        	; load A - 10
ADDING  	ADD R0,R0,R5		; add value to storage to print
        	OUT

        	AND R5,R5,R5        	; clear R5
		ADD R2,R2,#4        	; reset bit counter
        	ADD R1,R1,#-1       	; decrement digit counter
        	BRp START
		LD R5, HEXSAVE

		HALT

HEXSAVE .BLKW #1	; space to save hex value
NUMBER .FILL x0030  	; ascii 0
LETTER .FILL x0037  	; ascii A - 10


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;R0 - character input from keyboard
;R6 - current numerical output
;
;
EVALUATE
		LD R1, EQUALS		; check if input is "="
		ADD R1,R1,R0
		BRnp NOT_EQUALS		; skip if not "="
		JSR POP
		ADD R5,R5,#0
		BRp INVALID		; check R5
		LD R3, STACK_START
		LD R4, STACK_TOP
		NOT R4,R4
		ADD R4,R4,#1
		ADD R4,R3,R4		; check if top is pointing to start
		BRnp INVALID
		AND R5,R5,#0
		AND R3,R3,#0
		ADD R3,R3,R0
		ADD R5,R5,R0
		BRnzp PRINT_HEX		; print popped solution
		
NOT_EQUALS
		LD R1, CARETC		; check if input is "^"
		ADD R1,R1,R0
		BRnp NOT_CARET
		JSR EXP

NOT_CARET
		LD R1, MULTC		; check if input is "*"
		ADD R1,R1,R0
		BRnp NOT_MULT
		JSR MUL

NOT_MULT
		ADD R1,R1,#-1		; check if input is "+"
		BRnp NOT_ADD
		JSR PLUS

NOT_ADD
		ADD R1,R1,#-2		; check if input is "-"
		BRnp NOT_SUB
		JSR MIN

NOT_SUB
		ADD R1,R1,#-2		; check if input is "/"
		BRnp NOT_DIV
		JSR DIV

NOT_DIV
		ADD R5,R5,#0
		BRp INVALID
		BRnzp INPUT		; check for any failures


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;input R3, R4
;out R0
PLUS	
		ST R0, ADD_SAVER0
		ST R3, ADD_SAVER3
		ST R4, ADD_SAVER4
		ST R6, ADD_SAVER6
		ST R7, ADD_SAVER7

		AND R5,R5,#0		; initialize R5 
		JSR POP
		ADD R5,R5,#0
		BRp EXIT_PLUS		; exit if R5 = 1
		ADD R3,R0,#0		; store values in R3
		
		JSR POP
		ADD R5,R5,#0
		BRp PRESTORE_1		; restore if R5 = 1
		ADD R4,R0,#0		; store values in R4

		ADD R0,R3,R4		; add inputs
		
		JSR PUSH		; push R0 value onto stack
		AND R5,R5,#0
		BRp PRESTORE_2		; check if addition failed
		BRnzp EXIT_PLUS


PRESTORE_1
		LD R6, STACK_TOP
		ADD R6,R6,#-1		; push first number back onto stack
		ST R6, STACK_TOP	; update stack top location
		BRnzp EXIT_PLUS

PRESTORE_2	
		LD R6, STACK_TOP
		ADD R6, R6, #-2		;push both numbers back
		ST R6, STACK_TOP	;update STACK_TOP

EXIT_PLUS
		LD R0, ADD_SAVER0	;restore registers
		LD R3, ADD_SAVER3
		LD R4, ADD_SAVER4
		LD R6, ADD_SAVER6
		LD R7, ADD_SAVER7
		RET

ADD_SAVER0 .BLKW #1
ADD_SAVER3 .BLKW #1
ADD_SAVER4 .BLKW #1
ADD_SAVER6 .BLKW #1
ADD_SAVER7 .BLKW #1
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;input R3, R4
;out R0
MIN	
		ST R0, SUB_SAVER0
		ST R3, SUB_SAVER3
		ST R4, SUB_SAVER4
		ST R6, SUB_SAVER6
		ST R7, SUB_SAVER7

		AND R5,R5,#0		; initialize R5 
		JSR POP
		ADD R5,R5,#0
		BRp EXIT_SUB		; exit if R5 = 1
		ADD R3,R0,#0		; store values in R3
		
		JSR POP
		ADD R5,R5,#0
		BRp SRESTORE_1		; restore if R5 = 1
		ADD R4,R0,#0		; store values in R4

		NOT R3,R3
		ADD R3,R3,#1
		ADD R0,R3,R4		; R4 - R3 -> R0
		
		JSR PUSH		; push R0 value onto stack
		AND R5,R5,#0
		BRp SRESTORE_2		; check if subtraction failed
		BRnzp EXIT_SUB


SRESTORE_1
		LD R6, STACK_TOP
		ADD R6,R6,#-1		; push first number back onto stack
		ST R6, STACK_TOP	; update stack top location
		BRnzp EXIT_SUB

SRESTORE_2	
		LD R6, STACK_TOP
		ADD R6, R6, #-2		;push both numbers back
		ST R6, STACK_TOP	;update STACK_TOP

EXIT_SUB
		LD R0, SUB_SAVER0	;restore registers
		LD R3, SUB_SAVER3
		LD R4, SUB_SAVER4
		LD R6, SUB_SAVER6
		LD R7, SUB_SAVER7
		RET

SUB_SAVER0 .BLKW #1
SUB_SAVER3 .BLKW #1
SUB_SAVER4 .BLKW #1
SUB_SAVER6 .BLKW #1
SUB_SAVER7 .BLKW #1
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;input R3, R4
;out R0
MUL	
		ST R1, MUL_SAVER1
		ST R0, MUL_SAVER0
		ST R3, MUL_SAVER3
		ST R4, MUL_SAVER4
		ST R6, MUL_SAVER6
		ST R7, MUL_SAVER7

		AND R5,R5,#0		; initialize R5 
		JSR POP
		ADD R5,R5,#0
		BRp EXIT_MUL		; exit if R5 = 1
		ADD R3,R0,#0		; store values in R3
		
		JSR POP
		ADD R5,R5,#0
		BRp MRESTORE_1		; restore if R5 = 1
		ADD R4,R0,#0		; store values in R4



		AND R0,R0,#0
		ADD R4,R4,#0
		BRzp MULTI		; check if R3 is neg
		NOT R3, R3
		ADD R3, R3, #1  	; negate R3
		NOT R4, R4
		ADD R4, R4, #1  	; negate R4
 
	MULTI	ADD R1,R4,#0		; multiply
	LOOP1	ADD R0,R0,R3
		ADD R1,R1,#-1
		BRp LOOP1



	PUSHM	JSR PUSH		; push R0 value onto stack
		AND R5,R5,#0
		BRp MRESTORE_2		; check if mult failed
		BRnzp EXIT_MUL


MRESTORE_1
		LD R6, STACK_TOP
		ADD R6,R6,#-1		; push first number back onto stack
		ST R6, STACK_TOP	; update stack top location
		BRnzp EXIT_MUL

MRESTORE_2	
		LD R6, STACK_TOP
		ADD R6, R6, #-2		;push both numbers back
		ST R6, STACK_TOP	;update STACK_TOP

EXIT_MUL
		LD R0, MUL_SAVER0	;restore registers
		LD R1, MUL_SAVER1
		LD R3, MUL_SAVER3
		LD R4, MUL_SAVER4
		LD R6, MUL_SAVER6
		LD R7, MUL_SAVER7
		RET

MUL_SAVER0 .BLKW #1
MUL_SAVER1 .BLKW #1
MUL_SAVER3 .BLKW #1
MUL_SAVER4 .BLKW #1
MUL_SAVER6 .BLKW #1
MUL_SAVER7 .BLKW #1
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;input R3, R4
;out R0
DIV	
		ST R1, DIV_SAVER1
		ST R0, DIV_SAVER0
		ST R3, DIV_SAVER3
		ST R4, DIV_SAVER4
		ST R6, DIV_SAVER6
		ST R7, DIV_SAVER7

		AND R5,R5,#0		; initialize R5 
		JSR POP
		ADD R5,R5,#0
		BRp EXIT_DIV		; exit if R5 = 1
		ADD R3,R0,#0		; store values in R3
		
		JSR POP
		ADD R5,R5,#0
		BRp DRESTORE_1		; restore if R5 = 1
		ADD R4,R0,#0		; store values in R4



		AND R0,R0,#0		; clear R0
		ADD R1,R3,#0		; division counter
		NOT R3,R3
		ADD R3,R3,#1
	LOOP2	ADD R4,R4,R3		; divide
		BRn DPUSH		; branch to push if remainder
		ADD R0,R0,#1
		ADD R1,R1,#-1		; increment R0 for each subtraction
		BRp LOOP2



	DPUSH	JSR PUSH		; push R0 value onto stack
		AND R5,R5,#0
		BRp DRESTORE_2		; check if division failed
		BRnzp EXIT_DIV


DRESTORE_1
		LD R6, STACK_TOP
		ADD R6,R6,#-1		; push first number back onto stack
		ST R6, STACK_TOP	; update stack top location
		BRnzp EXIT_DIV

DRESTORE_2	
		LD R6, STACK_TOP
		ADD R6, R6, #-2		; push both numbers back
		ST R6, STACK_TOP	; update STACK_TOP

EXIT_DIV
		LD R0, DIV_SAVER0	; restore registers
		LD R1, DIV_SAVER1
		LD R3, DIV_SAVER3
		LD R4, DIV_SAVER4
		LD R6, DIV_SAVER6
		LD R7, DIV_SAVER7
		RET

DIV_SAVER0 .BLKW #1
DIV_SAVER1 .BLKW #1
DIV_SAVER3 .BLKW #1
DIV_SAVER4 .BLKW #1
DIV_SAVER6 .BLKW #1
DIV_SAVER7 .BLKW #1
	
STACK_START	.FILL x4000	;
STACK_TOP	.FILL x4000	;	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;input R3, R4
;out R0
EXP
		ST R1, EXP_SAVER1
		ST R2, EXP_SAVER2
		ST R0, EXP_SAVER0
		ST R3, EXP_SAVER3
		ST R4, EXP_SAVER4
		ST R6, EXP_SAVER6
		ST R7, EXP_SAVER7

		AND R5,R5,#0		; initialize R5 
		JSR POP
		ADD R5,R5,#0
		BRp EXIT_EXP		; exit if R5 = 1
		ADD R3,R0,#0		; store values in R3
		
		JSR POP
		ADD R5,R5,#0
		BRp ERESTORE_1		; restore if R5 = 1
		ADD R4,R0,#0		; store values in R4


		
		AND R2,R2,#0		; clear storage for current ans
		ADD R2,R2,R4
		AND R0,R0,#0		; clear R0
		ADD R0,R0,#1
		ADD R3, R3, #0
		BRz EPUSH		; chech if R3 = 0
		AND R0,R0,#0		; clear R0
		ADD R0,R0,R4		; R0 = R4 if ^1
		ADD R3, R3, #-1
		BRnz EPUSH   		; check R3 = 1
	LOOP3	AND R0,R0,#0		; clear R0
		ADD R0,R0,R4		; calculate exponent
		JSR PUSH
		AND R0,R0,#0
		ADD R0,R2,#0
		JSR PUSH
		JSR MUL
		JSR POP
		AND R2,R2,#0
		ADD R2,R0,R2		; store current ans in R2
		
		ADD R3,R3,#-1		; decrement R3
		BRp LOOP3



	EPUSH	JSR PUSH		; push R0 value onto stack
		AND R5,R5,#0
		BRp ERESTORE_2		; check if exp failed
		BRnzp EXIT_EXP


ERESTORE_1
		LD R6, STACK_TOP
		ADD R6,R6,#-1		; push first number back onto stack
		ST R6, STACK_TOP	; update stack top location
		BRnzp EXIT_EXP

ERESTORE_2	
		LD R6, STACK_TOP
		ADD R6, R6, #-2		;push both numbers back
		ST R6, STACK_TOP	;update STACK_TOP

EXIT_EXP
		LD R0, EXP_SAVER0	;restore registers
		LD R1, EXP_SAVER1
		LD R1, EXP_SAVER2
		LD R3, EXP_SAVER3
		LD R4, EXP_SAVER4
		LD R6, EXP_SAVER6
		LD R7, EXP_SAVER7
		RET

EXP_SAVER0 .BLKW #1
EXP_SAVER1 .BLKW #1
EXP_SAVER2 .BLKW #1
EXP_SAVER3 .BLKW #1
EXP_SAVER4 .BLKW #1
EXP_SAVER6 .BLKW #1
EXP_SAVER7 .BLKW #1
	
;IN:R0, OUT:R5 (0-success, 1-fail/overflow)
;R3: STACK_END R4: STACK_TOP
;
PUSH	
	ST R3, PUSH_SaveR3	;save R3
	ST R4, PUSH_SaveR4	;save R4
	AND R5, R5, #0		;
	LD R3, STACK_END	;
	LD R4, STACK_TOP	;
	ADD R3, R3, #-1		;
	NOT R3, R3		;
	ADD R3, R3, #1		;
	ADD R3, R3, R4		;
	BRz OVERFLOW		;stack is full
	STR R0, R4, #0		;no overflow, store value in the stack
	ADD R4, R4, #-1		;move top of the stack
	ST R4, STACK_TOP	;store top of stack pointer
	BRnzp DONE_PUSH		;
OVERFLOW
	ADD R5, R5, #1		;
DONE_PUSH
	LD R3, PUSH_SaveR3	;
	LD R4, PUSH_SaveR4	;
	RET


PUSH_SaveR3	.BLKW #1	;
PUSH_SaveR4	.BLKW #1	;


;OUT: R0, OUT R5 (0-success, 1-fail/underflow)
;R3 STACK_START R4 STACK_TOP
;
POP	
	ST R3, POP_SaveR3	;save R3
	ST R4, POP_SaveR4	;save R3
	AND R5, R5, #0		;clear R5
	LD R3, STACK_START	;
	LD R4, STACK_TOP	;
	NOT R3, R3			;
	ADD R3, R3, #1		;
	ADD R3, R3, R4		;
	BRz UNDERFLOW		;
	ADD R4, R4, #1		;
	LDR R0, R4, #0		;
	ST R4, STACK_TOP	;
	BRnzp DONE_POP		;
UNDERFLOW
	ADD R5, R5, #1		;
DONE_POP
	LD R3, POP_SaveR3	;
	LD R4, POP_SaveR4	;
	RET


POP_SaveR3	.BLKW #1	;
POP_SaveR4	.BLKW #1	;
STACK_END	.FILL x3FF0	;


.END
