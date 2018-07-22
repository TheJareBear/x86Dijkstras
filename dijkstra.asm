%include "/usr/local/share/csc314/asm_io.inc"

; this file will hold the graph edge data
;%define EDGE_FILE 'edges.txt' replaced by command line arguments


segment .data
	usage		db		"Usage: ./dijktra [edgeFilename]",10,0

	opening		db		"Opening file: %s",10,0
	successOp	db		"File opened successfully",10,0
	failOp		db		"Failure opening edge file, now quiting",10,0
	mode_r		db		"r",0
	first2		db		"%d%d%*c",0
	others		db		"%d%d%d%*c",0
	filePTR		dd		0

	nodeC		dd		0
	edgeC		dd		0
	fromN		dd		0
	toN			dd		0
	weight		dd		0

	nowPrint	db		10,"Now printing edge table",10,10,0

	readStart	db		"Starting node for Dijkstra's: ",0

	single		db		"%d",0 ;for reading in a single integer
	startN		dd		0
	currentD	dd		0
	min			dd		0

	tab			db		"%5d",0

	finalPrint	db		"Distance from node %d to node %d: %d",10,0
	finalPrintU	db		"Distance from node %d to node %d: Unreachable",10,0

	endingPrint	db		"Thank you for using Dijkstra's method!",10,0

segment .bss
	edges		resd	10000 ; this holds edge connections
	distances	resd	100 ; this will hold the distances from the starting node
	locked		resd	100 ; this will hold whether or not the node is locked for distance purposes


segment .text
	global  asm_main
	extern	printf
	extern	fopen
	extern	fread
	extern	fscanf
	extern	fclose
	extern	scanf

asm_main:
	push	ebp
	mov		ebp, esp
	; ********** CODE STARTS HERE **********


;OPENING FILE AND LOADING INTO ARRAY;

;	testing for command line argument count
firstCheck:
	mov		eax, DWORD[ebp + 8]
	cmp		eax, 2
	je		nextCheck ;if there are not exactly 2 arguments then quit
		push	usage
		call	printf
		add		esp, 4
		jmp		endtotal

nextCheck:
	;mov pointer to the file name into fileName
	mov		eax, DWORD [ebp + 12]
	mov		esi, DWORD [eax + 4] ;esi now holds file name pointer

	; print out message stating the opening phase
	push	esi
	push	opening
	call	printf
	add		esp, 8
	;open file using fopen
	push	mode_r
	push	esi
	call	fopen
	add		esp, 8
	mov		DWORD [filePTR], eax

	;if the file fails to open, print fail message and quit the program
	cmp		DWORD [filePTR], 0
		jne		readFile
		push	failOp
		call	printf
		add		esp, 4
		jmp		endtotal

readFile: ; if the file is successfully opened we will jump to here to read in data
	push	successOp ;push the text that the file was opened successfully
	call	printf
	add		esp, 4

	;first we want to read in the number of nodes and edges to set up our loop and maybe dynamically allocate our array
	push	edgeC
	push	nodeC
	push	first2
	push	DWORD [filePTR]
	call	fscanf
	add		esp, 16

	;now we want to loop for the file and read in the file to the array of edges
	;first check if there are no nodes or edges (bad input)
	cmp		DWORD [nodeC], 0
	je		endtotal
	cmp		DWORD [edgeC], 0
	je		endtotal

	mov		ebx, DWORD [edgeC] ;use ebx as looping variable (since ecx is used in fscanf I believe)
	readingTopOfLoop:
		;this fscanf call will read in the set of integers for an edge and then dump the newline character (%*c)
		push	weight
		push	toN
		push	fromN
		push	others
		push	DWORD [filePTR]
		call	fscanf
		add		esp, 20

			;now it is time to put the value into the array of edges to calculate dijkstras and make undirected
			mov		eax, DWORD [fromN]
			cdq
			imul	DWORD [nodeC]
			add		eax, DWORD [toN]
			mov		edi, DWORD [weight]
			mov		DWORD [edges + eax * 4], edi


			;this second one will mirror the first to make undirected
			mov		eax, DWORD [toN]
			cdq
			imul	DWORD [nodeC]
			add		eax, DWORD [fromN]
			mov		edi, DWORD [weight]
			mov		DWORD [edges + eax * 4], edi

		;loop stuff
		dec		ebx
		cmp		ebx, 0
		jle		readingEndOfLoop
	jmp		readingTopOfLoop
	readingEndOfLoop:


	;this is where printing of the table will happen
	push	nowPrint
	call	printf
	add		esp, 4
	;set up some looping variables
	mov		esi, 0
	mov		edi, 0

	printingEdgesTopOfLoop:
		mov		edi, 0
		innerPrintingTop:
			mov		eax, esi
			mul		DWORD [nodeC]
			mov		ebx, eax
			add		ebx, edi
			mov		eax, DWORD [edges + ebx * 4]

			push	eax
			push	tab
			call	printf
			add		esp, 8

			inc		edi
			cmp		edi, DWORD [nodeC]
			jl		innerPrintingTop

		call	print_nl
		inc		esi
		cmp		esi, DWORD [nodeC]
		jl		printingEdgesTopOfLoop

	push	DWORD [filePTR]
	call	fclose
	add		esp, 4

	printingEdgesEnd:
	call	print_nl
	;end of printing the edges table


	;now it is time for the dijkstra's method
	;print out "Starting node for Dijkstra's: "
	push	readStart
	call	printf
	add		esp, 4

	;read in the starting node
	push	startN
	push	single
	call	scanf
	add		esp, 4

	;now check to make sure that the node is a legit starting position <maxNode >0
	mov		eax, DWORD [startN]
	cmp		eax, DWORD [nodeC]
	jge		endtotal
	cmp		DWORD [startN], 0
	jl		endtotal

	;loop through and make distances equal -1 (which means unreachable)
	mov		ecx, 0
	settingLoopTop:
		cmp		ecx, DWORD [nodeC]
		jge		settingLoopEnd
		mov		DWORD [distances + ecx * 4], -1
		inc		ecx
		jmp		settingLoopTop
	settingLoopEnd:
	call	print_nl

	;set the distance to starting node to 0 (distance to self)
	mov		eax, DWORD [startN]
	mov		DWORD [distances + eax * 4], 0


	;STARTING DIJKSTRAS BELOW
	;now loop until no more minimums can be found (this is beef of program)
	dijkstrasTop:
		mov		DWORD [min], -1

		mov		ecx, 0 ;looping variable is ecx
		findMinTop: ;this loop will find the min node to move to next

			cmp		DWORD [locked + ecx * 4], 0
			jne		looperMin

			check1a:
				cmp		DWORD [min], -1
				jne		check2a
			check1b:
				cmp		DWORD [distances + ecx * 4], -1
				je		check2a
				mov		DWORD [min], ecx
				jmp		looperMin


			check2a:
				cmp		DWORD [distances + ecx * 4], -1
				je		looperMin
			check2b:
				mov		eax, DWORD [min]
				mov		ebx, DWORD [distances + eax * 4]
				cmp		DWORD [distances + ecx * 4], ebx
				jge		looperMin
				mov		DWORD [min], ecx

			looperMin:
				inc		ecx
				cmp		ecx, DWORD [nodeC]
				jl		findMinTop

		findMinEnd:

;		these are some tests to check if correct min is produced (Status: working)
;		mov		eax, DWORD [min]
;		call	print_int
;		call	print_nl

		;get prepared to find new distances with new node included
		cmp		DWORD [min], -1 ;this is the condition where no new nodes were found
		je		dijkstrasEnd

		;now we need to lock the min and then find our new distances
		mov		eax, DWORD [min]
		mov		DWORD [locked + eax * 4], 1
		mov		ebx, DWORD [distances + eax * 4]
		mov		DWORD [currentD], ebx ; set the current distance to the node we just found

		;Below we need to check nodes and set their distances
		;now loop to find set new distances
		mov		ecx, 0
		setDistTop:

			mov		eax, DWORD [min]
			cdq
			mul		DWORD [nodeC]
			add		eax, ecx ;hold edge location in eax for the current loop

			;these two check will make sure that the node can be reached from the min node and are not locked
			cmp		DWORD [edges + eax * 4], 0
			je		looperDist
			cmp		DWORD [locked + ecx * 4], 0
			jne		looperDist

			check4a:
				cmp		DWORD [distances + ecx * 4], -1
				jne		check5a
				mov		ebx, DWORD [edges + eax * 4]
				add		ebx, DWORD [currentD]
				mov		DWORD [distances + ecx * 4], ebx
				jmp		looperDist

			check5a:
				mov		ebx, DWORD [edges + eax * 4]
				add		ebx, DWORD [currentD]
				cmp		ebx, DWORD [distances + ecx * 4]
				jge		looperDist
				mov		DWORD [distances + ecx * 4], ebx

			looperDist:
			inc		ecx
			cmp		ecx, DWORD [nodeC]
			jl		setDistTop

		setDistEnd:

		jmp		dijkstrasTop

	dijkstrasEnd:


	;this is the final loop to print the minimum distances found in the dijkstra algorithm
	mov		edi, 0 ;final printing loop variable (ecx acts interestingly with printf
	finalPrintTop:

		cmp		DWORD [distances + edi * 4], -1
			je		unreachablePrint
		push	DWORD [distances + edi * 4]
		push	edi
		push	DWORD [startN]
		push	finalPrint
		call	printf
		add		esp, 16

		jmp		finalLooper

		unreachablePrint:
		push	edi
		push	DWORD [startN]
		push	finalPrintU
		call	printf
		add		esp, 12


		finalLooper:
			inc		edi
			cmp		edi, DWORD [nodeC]
			jl		finalPrintTop

	finalPrintEnd:

		call	print_nl
		push	endingPrint
		call	printf
		add		esp, 4

endtotal:

	; *********** CODE ENDS HERE ***********
	mov		eax, 0
	mov		esp, ebp
	pop		ebp
	ret
