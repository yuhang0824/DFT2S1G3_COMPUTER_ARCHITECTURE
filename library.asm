.MODEL SMALL
.STACK 100
.DATA
	;==================================================================================================================
	msgPromtSelectPage DB 13,10
		DB '=======================================',13,10
		DB '1. Login',13,10
		DB '2. Register',13,10
		DB '0. Exit',13,10
		DB '=======================================',13,10
		DB 'Enter number to choose: $'
	
	;==================================================================================================================
		
	msgPromtSelectFunction DB 13,10
		DB '=======================================',13,10
		DB '       WELCOME TO LIBRARY SYSTEM       ',13,10
		DB '=======================================',13,10
		DB '1. Borrow Book (Tier Restricted)',13,10
		DB '2. Subscribe / Upgrade Membership',13,10
		DB '3. Member Top-up (Wallet)',13,10
		DB '4. Return Book / Late Fine',13,10
		DB '5. Summary Report',13,10
		DB '6. Logout',13,10
		DB '0. Exit System',13,10
		DB '=======================================',13,10
		DB 'Please enter your choice (0-6): $'

	;==================================================================================================================

	msgTierMenu DB 13,10
		DB '====== SELECT MEMBERSHIP TIER ======',13,10
		DB '1. Bronze - RM 50 (Max Borrow:  7 Days)',13,10
		DB '2. Silver - RM 75 (Max Borrow: 14 Days)',13,10
		DB '3. Gold   - RM100 (Max Borrow: 30 Days)',13,10
		DB '0. Back to Main Menu',13,10
		DB '====================================',13,10
		DB 'Choose plan: $'
		
	CHOICE DB ?
	
	;==================================================================================================================
	
	TotalBooks 	  DB 0     ; 借出书总数
	TotalFine     DB 0     ; 罚款总额
	TotalRevenue  DB 0     ; 总收入
	MemberBalance DB 50    ; 会员余额
	MemberTier    DB 'N'     ; 'N'=None, 'B'=Bronze, 'S'=Silver, 'G'=Gold
	ExpiryDay     DB 0
	ExpiryMonth   DB 0
	CurrentDay    DB ?
	CurrentMonth  DB ?

	msgRepTitle DB 13,10,13,10,13,10,'======== SUMMARY REPORT ========$'
	msgRepBooks DB 13,10,'Total Books Borrowed : $'
	msgRepFine  DB 13,10,'Total Fine (RM)      : $'
	msgRepSpe   DB 13,10,'Total Spend(RM)      : $'
	msgRepLine  DB 13,10,'================================$'
	
	;================================================= Prompts ========================================================

	msgPromtMemberID   DB 13,10,'MemberID (M0000): $'
	msgPromtPassword   DB 13,10,'Password (5 Digit): $'
	msgPromtBorrowDays DB 13,10,'Enter borrow days: $'
	msgPromtOverdue    DB 13,10,'Enter overdue days (0-9): $'
	msgPromtTopup      DB 13,10,'Enter Top-up amount RM (01-99): $'
	msgPressAnyKey 	   DB 13,10,'Press any key to continue...$'
	
	msgSubSuccess      DB 13,10,'Subscription Activated! Expiry set 30 days from today.$'
	msgTierExpired     DB 13,10,'[!] Your membership has expired (30 days passed). Tier reset to NONE.$'
	msgNoTierBorrow    DB 13,10,'[!] Tier NONE cannot borrow books. Please subscribe (Menu 2).$'
	msgExceedTierLimit DB 13,10,'[!] Borrow days exceed your tier allowance!$'
	msgBorrowSuccess   DB 13,10,'=== BORROW SUCCESS (Free with Active Tier) ===$'
	
	msgNoMoney 		   DB 13,10,'Insufficient balance! Please Top-up (Menu 3).$'
	msgBalanceShow 	   DB 13,10,'Current Balance: RM $'
	msgTierShow        DB 13,10,'Current Tier: $'
	msgExpiryShow      DB ' | Expiry Date (DD/MM): $'
	msgTierNoneStr     DB 'NONE$'
	msgTierBronzeStr   DB 'BRONZE (Max 7d)$'
	msgTierSilverStr   DB 'SILVER (Max 14d)$'
	msgTierGoldStr     DB 'GOLD (Max 30d)$'
	
	msgTopupSuccess    DB 13,10,'=== TOP-UP SUCCESS ===$'
	msgReturnSuccess   DB 13,10,'=== BOOK RETURNED (No Fine) ===$'
	msgFinePaid        DB 13,10,'=== LATE RETURN: Fine deducted RM $'
	
	; Register prompts
	msgRegisterTitle DB 13,10,13,10,'=== MEMBER REGISTRATION ===$'
	msgRegSuccess    DB 13,10,13,10,'Registration successful!$'
	msgRegFail       DB 13,10,13,10,'Registration failed (File Error)!$'
	msgErrIDFormat   DB 13,10,'Invalid ID format! Must start with uppercase "M" followed by 4 digits (e.g., M0001).$'
	msgErrIDExists   DB 13,10,'Member ID already exists! Registration cancelled.$'
	
	;BOOK Prompts
	msgPromtBookID     DB 13,10,'Enter Book ID (B0001): $'
	msgErrBookNotFound DB 13,10,'[!] Book ID not found in library!$'
	msgErrNotBorrowed  DB 13,10,'[!] You have not borrowed this book!$'
	msgAvailableBooks  DB 13,10,'--- AVAILABLE BOOKS ---$'
	msgDaysBorrowed    DB 13,10,'Total days borrowed: $'
	msgOverdueDaysMsg  DB 13,10,'Overdue days: $'
	
	;Return Book Prompt
	msgBorrowedListTitle DB 13,10,'--- YOUR CURRENT BORROWED BOOKS ---',13,10,'$'
	msgNoBorrowedBooks   DB 13,10,'You currently have no borrowed books.',13,10,'$'
	msgAlreadyBorrowed   DB 13,10,'[!] You have already borrowed this book!$'
	msgBorrowPrefix      DB '-> Book ID: $'
	msgDatePrefix        DB ' | Date Borrowed: $'
	HasBorrowedBooks     DB 0
	
	;================================================= Error Messages =================================================

	ERRORMSG1 DB 13,10,'WRONG Choice $'
	ERRORMSG2 DB 13,10,'WRONG ID OR PASSWORD $'
	ERRORMSG4 DB 13,10,'Too many wrong attempts! Returning to Menu.$'
	ERRORMSG5 DB 13,10,"Invalid input! Must be 1 to 9.$"
	msgInvalidNum DB 13,10,'Invalid input! Only numbers 0-9 allowed.$'
	msgOverflow   DB 13,10,'Exceeds maximum limit (RM 255)!$'
	msgAlreadyActive DB 13,10,'[!] You already have an active membership! You can only re-subscribe once expired.$'
	msgOutOfStock   DB 13,10,'[!] Book is out of stock (Qty: 000)!$'

	;================================================= Buffers & File Variables =======================================

	MemberID_INPUT DB 5 DUP(?)
	Password_INPUT DB 5 DUP(?)
	RegRecord      DB 25 DUP(?)
	; Separate dedicated buffer for 20 books 
	bookBuffer     DB 2048 DUP(?)
	; Standard buffer for account/borrowed records
	buffer         DB 1024 DUP(?)
	
	AccFILE     DB 'account.txt', 0
	logMsg      DB 'M0001,12345,050,N,00,00', 13, 10
	msgLen      DW 24
	fileHandle  DW ?
	accFileSize DW 0
	
	BookFILE       DB 'book.txt', 0
	BorrowFILE     DB 'borrowed.txt', 0
	borrowFileSize DW 0
	
	defaultBooks DB 'B0001,Assembly Language   ,005', 13, 10
                 DB 'B0002,Data Structures     ,005', 13, 10
                 DB 'B0003,Operating Systems   ,005', 13, 10
	defaultBookLen DW 96
	
	BookID_INPUT   DB 5 DUP(?)
	BorrowRecord   DB 19 DUP(?)
	
	BorrowDay      DB 0
	BorrowMonth    DB 0
	DaysElapsed    DB 0
	MaxAllowedDays DB 0
	OverdueDays    DB 0
	
	;================================================= Other Variables ================================================
	RETRY_COUNT   DB 3
	CHOICE_STATUS DB 0
	BORROW_STATUS DB 0 
	RETURN_STATUS DB 0
	TOPUP_STATUS  DB 0
	
	NL DB 10,13,'$'
	
.CODE
MAIN PROC
	MOV AX, @DATA
	MOV DS, AX
	
SELECT_PAGE:
	CALL CLEAR_SCREEN
	
	CMP CHOICE_STATUS, 1
	JE  DO_DISPLAY_ERR
	JMP SHOW_MENU

DO_DISPLAY_ERR:
	MOV AH, 09H
	LEA DX, ERRORMSG1
	INT 21H
	MOV CHOICE_STATUS, 0   

SHOW_MENU:
	MOV AH, 09H
	LEA DX, msgPromtSelectPage
	INT 21H
	
	MOV AH, 01H
	INT 21H
	MOV CHOICE, AL
	
	MOV AH, 09H
	LEA DX, NL
	INT 21H
	
	CMP CHOICE, '1'
	JE  GO_LOGIN
	CMP CHOICE, '2'
	JE  GO_REGISTER
	CMP CHOICE, '0'
	JE  GO_FIN
	
	MOV CHOICE_STATUS, 1
	JMP SELECT_PAGE

GO_LOGIN:
	JMP PREPARE_LOGIN

GO_REGISTER:
	CALL REGISTER_MEMBER
	JMP SELECT_PAGE

GO_FIN:
	JMP FIN

PREPARE_LOGIN:
	CALL CLEAR_SCREEN
	MOV RETRY_COUNT, 3

LOGIN_ID_PAGE:
	MOV AH, 09H
	LEA DX, msgPromtMemberID
	INT 21H
	CALL READ_USERNAME

	MOV AH, 09H
	LEA DX, msgPromtPassword
	INT 21H
	CALL READ_PASSWORD

	; 1. Open File
	MOV AH, 3DH
	MOV AL, 0
	LEA DX, AccFILE
	INT 21H
	JNC OPEN_FILE_OK
	JMP ERROR_OPEN

OPEN_FILE_OK:
	MOV fileHandle, AX

	; Read up to 1000 bytes
	MOV AH, 3FH
	MOV BX, fileHandle
	MOV CX, 1000
	LEA DX, buffer
	INT 21H
	PUSH AX                  ; Total bytes read
	
	MOV AH, 3EH
	MOV BX, fileHandle
	INT 21H
	POP CX

	CMP CX, 0
	JNE START_PARSER
	JMP AUTH_FAIL

START_PARSER:
	LEA SI, buffer

CHECK_NEXT_RECORD:
	; Need at least 5 bytes for MemberID
	CMP CX, 5
	JAE PROCEED_PARSE_USER
	JMP AUTH_FAIL

PROCEED_PARSE_USER:
	; Check for stray characters (space, CR, LF)
	CMP BYTE PTR [SI], ' '
	JE  DO_STRAY_SKIP
	CMP BYTE PTR [SI], 13
	JE  DO_STRAY_SKIP
	CMP BYTE PTR [SI], 10
	JE  DO_STRAY_SKIP
	JMP COMPARE_RECORD_FIELDS    ; Valid char found -> proceed directly

DO_STRAY_SKIP:
	INC SI
	DEC CX
	JNZ CONTINUE_TO_NEXT_REC   ; CX != 0: jump forward (short jump)
	JMP AUTH_FAIL_BRIDGE       ; CX == 0: far jump to fail bridge

CONTINUE_TO_NEXT_REC:
	JMP CHECK_NEXT_RECORD

COMPARE_RECORD_FIELDS:
	; Compare ID (5 bytes)
	LEA DI, MemberID_INPUT
	PUSH CX
	PUSH SI
	MOV CX, 5
	
COMPARE_REC_ID:
	MOV AL, [SI]
	CMP AL, [DI]
	JNE REC_MISMATCH_BRIDGE
	INC SI
	INC DI
	LOOP COMPARE_REC_ID

	; Verify comma separator
	CMP BYTE PTR [SI], ','
	JNE REC_MISMATCH_BRIDGE
	INC SI

	; Compare Password (5 bytes)
	LEA DI, Password_INPUT
	MOV CX, 5
	
COMPARE_REC_PASS:
	MOV AL, [SI]
	CMP AL, [DI]
	JNE REC_MISMATCH_BRIDGE
	INC SI
	INC DI
	LOOP COMPARE_REC_PASS
	
	; Verify second comma
	CMP BYTE PTR [SI], ','
	JNE REC_MISMATCH_BRIDGE
	INC SI
	JMP EXTRACT_BAL_FIELDS

REC_MISMATCH_BRIDGE:
	JMP RECORD_MISMATCH

EXTRACT_BAL_FIELDS:
	; ================= EXTRACT & CONVERT BALANCE =================
	; Hundreds Digit
	MOV AL, [SI]
	SUB AL, '0'
	MOV BL, 100
	MUL BL
	MOV DH, AL               ; DH = Hundreds value
	INC SI

	; Tens Digit
	MOV AL, [SI]
	SUB AL, '0'
	MOV BL, 10
	MUL BL
	ADD DH, AL               ; DH = Hundreds + Tens
	INC SI

	; Units Digit
	MOV AL, [SI]
	SUB AL, '0'
	ADD DH, AL               ; DH = Final calculated balance
	MOV MemberBalance, DH
	INC SI
	
	INC SI                   ; Skip ','
	
	; --- Extract Tier ---
	MOV AL, [SI]
	MOV MemberTier, AL
	INC SI

	INC SI                   ; Skip ','

	; --- Extract Expiry Day (2 digits) ---
	MOV AL, [SI]
	SUB AL, '0'
	MOV BL, 10
	MUL BL
	INC SI
	ADD AL, [SI]
	SUB AL, '0'
	MOV ExpiryDay, AL
	INC SI

	INC SI                   ; Skip ','

	; --- Extract Expiry Month (2 digits) ---
	MOV AL, [SI]
	SUB AL, '0'
	MOV BL, 10
	MUL BL
	INC SI
	ADD AL, [SI]
	SUB AL, '0'
	MOV ExpiryMonth, AL

	POP SI
	POP CX

	; Check subscription validity against current date
	CALL CHECK_EXPIRY_STATUS
	JMP MAIN_MENU

RECORD_MISMATCH:
	POP SI
	POP CX

SKIP_LINE:
	MOV AL, [SI]
	INC SI
	DEC CX
	JZ  AUTH_FAIL_BRIDGE
	CMP AL, 10                 ; Line Feed (LF)
	JNE SKIP_LINE
	JMP CHECK_NEXT_RECORD

AUTH_FAIL_BRIDGE:
	JMP AUTH_FAIL

AUTH_FAIL:
	DEC RETRY_COUNT
	JZ  TOO_MANY_TRIES_BRIDGE

	MOV AH, 09H
	LEA DX, ERRORMSG2
	INT 21H
	JMP LOGIN_ID_PAGE

TOO_MANY_TRIES_BRIDGE:
	JMP TOO_MANY_TRIES

ERROR_OPEN:
	MOV AH, 3CH
	MOV CX, 0
	LEA DX, AccFILE
	INT 21H
	MOV fileHandle, AX

	MOV AH, 40H
	MOV BX, fileHandle
	MOV CX, msgLen
	LEA DX, logMsg
	INT 21H

	MOV AH, 3EH
	MOV BX, fileHandle
	INT 21H
	JMP LOGIN_ID_PAGE

TOO_MANY_TRIES:
	MOV AH, 09H
	LEA DX, ERRORMSG4
	INT 21H
	CALL WAIT_KEY
	JMP SELECT_PAGE
	
;================================================= MAIN MENU =================================================
MAIN_MENU:
	CALL CLEAR_SCREEN
	
	CMP CHOICE_STATUS,1
	JE  DISPLAY_ERROR2
	JMP SHOW_MENU2

DISPLAY_ERROR2:
	MOV AH, 09H
	LEA DX, ERRORMSG1
	INT 21H
	MOV CHOICE_STATUS,0   

SHOW_MENU2:
	CALL PRINT_USER_STATUS
	
	MOV AH,09H
	LEA DX,msgPromtSelectFunction
	INT 21H
	
	;Input
	MOV AH,01H
	INT 21H
	MOV CHOICE,AL
	
	;NEW LINE
	MOV AH,09H
	LEA DX,NL
	INT 21H
	
	;------------------ Switch ------------------
	CMP CHOICE, '1'
	JE BORROW_BOOK_PAGE    ;Borrow Book
	
	CMP CHOICE, '2'
	JE SUBSCRIBE_PAGE    ;SUBSCRIBE MEMBER
	
	CMP CHOICE, '3'
	JE TOP_UP_PAGE         ;Top Up
	
	CMP CHOICE, '4'
	JE RETURN_BOOK_PAGE   ;Return Book
	
	CMP CHOICE, '5'
	JE SHOW_REPORT_PAGE		;View Report
	
	CMP CHOICE,'6'
	JE SELECT_PAGE_BRIDGE			;Logout
	
	CMP CHOICE, '0'
	JE FIN                 ; 退出系统
	
	MOV CHOICE_STATUS,1
	JMP MAIN_MENU
	
SELECT_PAGE_BRIDGE:
	JMP SELECT_PAGE

BORROW_BOOK_PAGE:
	CALL BORROW_BOOK
	JMP MAIN_MENU

SUBSCRIBE_PAGE:
	CALL SUBSCRIBE_TIER
	JMP MAIN_MENU

RETURN_BOOK_PAGE:
	CALL RETURN_BOOK
	JMP MAIN_MENU
	
TOP_UP_PAGE:
	CALL TOP_UP
	JMP MAIN_MENU
	
SHOW_REPORT_PAGE:
	CALL PRINT_REPORT
	JMP MAIN_MENU

FIN:
	CALL CLEAR_SCREEN
	MOV AX, 4C00H
	INT 21H
MAIN ENDP

; ==========================================================
; Register Member: Validates format (Mxxxx) & checks uniqueness
; ==========================================================
REGISTER_MEMBER PROC
	CALL CLEAR_SCREEN
	
	MOV AH, 09H
	LEA DX, msgRegisterTitle
	INT 21H

	; 1. Read Member ID (5 chars)
	MOV AH, 09H
	LEA DX, msgPromtMemberID
	INT 21H
	CALL READ_USERNAME
	
	LEA SI, MemberID_INPUT

	; Check 1st character: Must be 'M'
	CMP BYTE PTR [SI], 'M'
	JE  FIRST_CHAR_OK           ; If it is 'M', skip over the error jump
	JMP REG_INVALID_FORMAT      ; Unconditional jump (no range limit)

FIRST_CHAR_OK:
	INC SI
	
	; Check 2nd, 3rd, 4th, 5th characters: Must be '0'-'9'
	MOV CX, 4
	
CHECK_DIGITS:
	MOV AL, [SI]
	CMP AL, '0'
	JB  DIGIT_FAIL              ; Local short jump
	CMP AL, '9'
	JA  DIGIT_FAIL              ; Local short jump
	INC SI
	LOOP CHECK_DIGITS
	JMP PROCEED_DUP_CHECK       ; All 4 digits valid -> proceed

DIGIT_FAIL:
	JMP REG_INVALID_FORMAT      ; Jump to error

PROCEED_DUP_CHECK:
	; Check if Member ID already exists in file
	MOV AH, 3DH
	MOV AL, 0                   ; Open Read-Only
	LEA DX, AccFILE
	INT 21H
	JC  PROCEED_TO_PASS         ; If file doesn't exist yet, ID is unique
	MOV fileHandle, AX

	; Read file into buffer
	MOV AH, 3FH
	MOV BX, fileHandle
	MOV CX, 1000
	LEA DX, buffer
	INT 21H
	PUSH AX                     ; Save bytes read
	
	MOV AH, 3EH                 ; Close file handle
	MOV BX, fileHandle
	INT 21H
	POP CX                      ; CX = total bytes read

	CMP CX, 0
	JE  PROCEED_TO_PASS         ; File empty -> unique

	; Scan buffer records for duplicate ID
	LEA SI, buffer

CHECK_DUP_RECORD:
	CMP CX, 5
	JB  PROCEED_TO_PASS         ; Remaining bytes less than ID length -> done scanning

	LEA DI, MemberID_INPUT
	PUSH CX
	PUSH SI
	MOV CX, 5
	
COMPARE_DUP_ID:
	MOV AL, [SI]
	CMP AL, [DI]
	JNE DUP_MISMATCH
	INC SI
	INC DI
	LOOP COMPARE_DUP_ID

	; Duplicate match found!
	POP SI
	POP CX
	JMP REG_DUPLICATE_ID

DUP_MISMATCH:
	POP SI
	POP CX

SKIP_DUP_LINE:
	MOV AL, [SI]
	INC SI
	DEC CX
	JZ  PROCEED_TO_PASS         ; Reached EOF without duplicate match
	CMP AL, 10                  ; LF (Newline) found
	JNE SKIP_DUP_LINE
	JMP CHECK_DUP_RECORD

	; 2. Read Password (5 chars)
PROCEED_TO_PASS:
	MOV AH, 09H
	LEA DX, msgPromtPassword
	INT 21H
	CALL READ_PASSWORD

	; 3. Format buffer: [ID:5] + [','] + [Pass:5] + [','] + ['050':3] + [0DH] + [0AH]
	LEA DI, RegRecord
	
	; Copy ID (5 bytes)
	LEA SI, MemberID_INPUT
	MOV CX, 5
COPY_REG_ID:
	MOV AL, [SI]
	MOV [DI], AL
	INC SI
	INC DI
	LOOP COPY_REG_ID
	
	; Add first comma
	MOV BYTE PTR [DI], ','
	INC DI
	
	; Copy Password (5 bytes)
	LEA SI, Password_INPUT
	MOV CX, 5
COPY_REG_PASS:
	MOV AL, [SI]
	MOV [DI], AL
	INC SI
	INC DI
	LOOP COPY_REG_PASS
	
	; Add second comma
	MOV BYTE PTR [DI], ','
	INC DI
	
	; Add default initial balance "050" (RM 50)
	MOV BYTE PTR [DI], '0'
	INC DI
	MOV BYTE PTR [DI], '5'
	INC DI
	MOV BYTE PTR [DI], '0'
	INC DI
	
	MOV BYTE PTR [DI], ','
	INC DI
	
	; Initial Tier = 'N' (NONE)
	MOV BYTE PTR [DI], 'N'
	INC DI
	
	MOV BYTE PTR [DI], ','
	INC DI
	
	; Expiry Day = '00'
	MOV BYTE PTR [DI], '0'
	INC DI
	MOV BYTE PTR [DI], '0'
	INC DI
	
	MOV BYTE PTR [DI], ','
	INC DI
	
	; Expiry Month = '00'
	MOV BYTE PTR [DI], '0'
	INC DI
	MOV BYTE PTR [DI], '0'
	INC DI
	
	; Add CRLF
	MOV BYTE PTR [DI], 13       ; CR
	INC DI
	MOV BYTE PTR [DI], 10       ; LF
	
	; 4. Open account.txt (Read/Write Access: AL = 2)
	MOV AH, 3DH
	MOV AL, 2
	LEA DX, AccFILE
	INT 21H
	JNC OPEN_REG_OK

	; Create file if missing
	MOV AH, 3CH
	MOV CX, 0
	LEA DX, AccFILE
	INT 21H
	JC  REG_FILE_ERROR

OPEN_REG_OK:
	MOV fileHandle, AX

	; 5. Seek to End of File (AL = 2, CX:DX = 0)
	MOV AH, 42H
	MOV AL, 2
	MOV BX, fileHandle
	XOR CX, CX							;EXPLIAN!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!1	
	XOR DX, DX							;EXPLIAN!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!1
	INT 21H
	JC  REG_FILE_ERROR

	; 6. Append 24-byte record (Single write)
	MOV AH, 40H
	MOV BX, fileHandle
	MOV CX, 25
	LEA DX, RegRecord
	INT 21H
	JC  REG_FILE_ERROR

	; 7. Close file handle
	MOV AH, 3EH
	MOV BX, fileHandle
	INT 21H

	MOV AH, 09H
	LEA DX, msgRegSuccess
	INT 21H
	JMP REG_DONE

REG_INVALID_FORMAT:
	MOV AH, 09H
	LEA DX, msgErrIDFormat
	INT 21H
	JMP REG_DONE

REG_DUPLICATE_ID:
	MOV AH, 09H
	LEA DX, msgErrIDExists
	INT 21H
	JMP REG_DONE

REG_FILE_ERROR:
	MOV AH, 3EH
	MOV BX, fileHandle
	INT 21H

	MOV AH, 09H
	LEA DX, msgRegFail
	INT 21H

REG_DONE:
	CALL WAIT_KEY
	RET
REGISTER_MEMBER ENDP

; ==========================================================
; 1. BORROW BOOK (Uses dedicated bookBuffer to prevent file corruption)
; ==========================================================
BORROW_BOOK PROC
	CALL CLEAR_SCREEN
	
	; 1. Check if Tier is NONE
	CMP MemberTier, 'N'
	JE  BORROW_NO_TIER
	JMP SHOW_BOOK_LIST

BORROW_NO_TIER:
	MOV AH, 09H
	LEA DX, msgNoTierBorrow
	INT 21H
	JMP BORROW_EXIT

SHOW_BOOK_LIST:
	CALL CLEAR_SCREEN

	MOV AH, 09H
	LEA DX, msgAvailableBooks
	INT 21H
	
	MOV AH, 09H
	LEA DX, NL
	INT 21H
	
	; Open book.txt (Read-Only)
	MOV AH, 3DH
	MOV AL, 0
	LEA DX, BookFILE
	INT 21H
	JNC READ_BOOKS_OK
	
	; If missing, create default
	MOV AH, 3CH
	MOV CX, 0
	LEA DX, BookFILE
	INT 21H
	MOV fileHandle, AX
	
	MOV AH, 40H
	MOV BX, fileHandle
	MOV CX, defaultBookLen
	LEA DX, defaultBooks
	INT 21H
	
	MOV AH, 3EH
	MOV BX, fileHandle
	INT 21H
	JMP SHOW_BOOK_LIST

READ_BOOKS_OK:
	MOV fileHandle, AX
	MOV AH, 3FH
	MOV BX, fileHandle
	MOV CX, 320                ; Read exactly 10 books (10 * 32 = 320 bytes)
	LEA DX, bookBuffer
	INT 21H
	PUSH AX                    ; Save actual bytes read
	
	MOV AH, 3EH
	MOV BX, fileHandle
	INT 21H
	
	POP CX                     ; CX = Bytes read
	CMP CX, 0
	JNZ PROCEED_PRINT_BOOKS    ; [Fix] Trampoline jump to skip the error
	JMP BOOK_NOT_FOUND

PROCEED_PRINT_BOOKS:
	LEA SI, bookBuffer

	; Print all 10 books directly to screen
	
PRINT_BOOKS_LOOP:
	MOV DL, [SI]
	MOV AH, 02H
	INT 21H
	INC SI
	LOOP PRINT_BOOKS_LOOP

	; --------------------------------------------------
	; 2. Read Book ID Input (5 Chars)
	; --------------------------------------------------
	MOV AH, 09H
	LEA DX, msgPromtBookID
	INT 21H
	
	; Flush keyboard buffer first to prevent accidental skips
	MOV AH, 0CH
	MOV AL, 0
	INT 21H

	LEA SI, BookID_INPUT
	MOV CX, 5
READ_BK_ID:
	MOV AH, 01H
	INT 21H
	CMP AL, 13                  ; Ignore early Enter key
	JE  READ_BK_ID
	MOV [SI], AL
	INC SI
	LOOP READ_BK_ID
	
	MOV AH, 09H
	LEA DX, NL
	INT 21H

	; ==================================================
	; 2.5 Check if User Already Borrowed This Book
	; ==================================================
	MOV AH, 3DH
	MOV AL, 0                   ; Open Read-Only
	LEA DX, BorrowFILE
	INT 21H
	JC  PROCEED_TO_CATALOG      ; If file doesn't exist, safe to borrow

	MOV fileHandle, AX
	
	MOV AH, 3FH
	MOV BX, fileHandle
	MOV CX, 1000
	LEA DX, buffer              ; Read file into buffer
	INT 21H
	PUSH AX                     ; Save bytes read
	
	MOV AH, 3EH
	MOV BX, fileHandle
	INT 21H
	POP CX                      ; CX = Total bytes read

	CMP CX, 0
	JE  PROCEED_TO_CATALOG      ; If file is empty, safe to borrow

	LEA SI, buffer

SCAN_CHK_BORROW:
	CMP CX, 11                  ; A valid record needs at least 11 chars (e.g., M0001,B0001)
	JB  PROCEED_TO_CATALOG      ; If fewer than 11 bytes remain, stop scanning

	; Check Member ID First
	LEA DI, MemberID_INPUT
	PUSH CX
	PUSH SI
	MOV CX, 5
COMP_CHK_MID:
	MOV AL, [SI]
	CMP AL, [DI]
	JNE CHK_REC_MISMATCH        ; If Member ID doesn't match, skip to next line
	INC SI
	INC DI
	LOOP COMP_CHK_MID

	; Member ID matched! Now check if Book ID matches
	INC SI                      ; Skip ','
	
	LEA DI, BookID_INPUT
	MOV CX, 5
COMP_CHK_BID:
	MOV AL, [SI]
	CMP AL, [DI]
	JNE CHK_REC_MISMATCH        ; If Book ID doesn't match, skip to next line
	INC SI
	INC DI
	LOOP COMP_CHK_BID

	; BOTH Member ID and Book ID matched! (User already has this book)
	POP SI
	POP CX
	JMP ALREADY_BORROWED_ERR

CHK_REC_MISMATCH:
	POP SI                      ; Reset pointer to start of this line
	POP CX                      ; Reset byte count

SKIP_CHK_LINE:
	CMP CX, 0
	JE  PROCEED_TO_CATALOG      ; Stop if we reached end of file
	MOV AL, [SI]
	INC SI                      ; Move to next character
	DEC CX                      ; Reduce remaining byte count
	CMP AL, 10                  ; Is it a Line Feed (Newline)?
	JNE SKIP_CHK_LINE           ; If not, keep scanning this line
	JMP SCAN_CHK_BORROW         ; Once newline is found, check the next record

ALREADY_BORROWED_ERR:
	MOV AH, 09H
	LEA DX, msgAlreadyBorrowed
	INT 21H
	JMP BORROW_EXIT             ; Block transaction and exit to menu

PROCEED_TO_CATALOG:
	; ==================================================

	; --------------------------------------------------
	; 3. Scan bookBuffer for Book ID (10 Records)
	; --------------------------------------------------
	LEA SI, bookBuffer
	MOV CX, 10                 ; Search 10 records only                ; Search 10 records only

SCAN_BOOK_EXIST:
	LEA DI, BookID_INPUT
	PUSH CX
	PUSH SI
	MOV CX, 5
COMPARE_BK_ID:
	MOV AL, [SI]
	CMP AL, [DI]
	JNE BK_MISMATCH
	INC SI
	INC DI
	LOOP COMPARE_BK_ID
	
	; Match found!
	POP SI                     ; SI = Start of matched 32-byte book record
	POP CX
	JMP BOOK_VALID_FOUND

BK_MISMATCH:
	POP SI
	POP CX
	ADD SI, 32                 ; Advance to next 32-byte row
	LOOP SCAN_BOOK_EXIST

	; [Fix] If the loop finishes 10 times and doesn't find the book, it MUST go to the error!
	JMP BOOK_NOT_FOUND         

; --------------------------------------------------
; 4. Quantity Check & Decrement
; --------------------------------------------------
BOOK_VALID_FOUND:
	; SI points to start of matched book in bookBuffer
	LEA BX, [SI + 27]          ; Offset 27 = Quantity (e.g. "005")

	; Check if stock == "000"
	CMP BYTE PTR [BX], '0'
	JNE DECREMENT_STOCK
	CMP BYTE PTR [BX+1], '0'
	JNE DECREMENT_STOCK
	CMP BYTE PTR [BX+2], '0'
	JNE DECREMENT_STOCK

	; Out of stock
	MOV AH, 09H
	LEA DX, msgOutOfStock
	INT 21H
	JMP BORROW_EXIT

DECREMENT_STOCK:
	CMP BYTE PTR [BX+2], '0'
	JNE DEC_UNITS
	MOV BYTE PTR [BX+2], '9'
	DEC BYTE PTR [BX+1]
	JMP UPDATE_BOOK_FILE

DEC_UNITS:
	DEC BYTE PTR [BX+2]

UPDATE_BOOK_FILE:
	; Save updated quantity back to book.txt
	MOV AH, 3DH
	MOV AL, 1                  ; Write-Only
	LEA DX, BookFILE
	INT 21H
	MOV fileHandle, AX

	MOV AH, 40H
	MOV BX, fileHandle
	MOV CX, 320
	LEA DX, bookBuffer
	INT 21H

	MOV AH, 3EH
	MOV BX, fileHandle
	INT 21H

; ----------------------------------------------------------
; 5. Build Borrow Record (Strict 20-Byte Row Format)
; Format: [MemberID:5] + ',' + [BookID:5] + ',' + [DD:2] + ',' + [MM:2] + [0DH, 0AH]
; ----------------------------------------------------------
	MOV AH, 2AH                ; Get real-time DOS date
	INT 21H
	MOV BorrowDay, DL
	MOV BorrowMonth, DH
	
	LEA DI, BorrowRecord
	
	; Copy Member ID (5 bytes)
	LEA SI, MemberID_INPUT
	MOV CX, 5
CP_M_ID:
	MOV AL, [SI]
	MOV [DI], AL
	INC SI
	INC DI
	LOOP CP_M_ID
	
	MOV BYTE PTR [DI], ','
	INC DI
	
	; Copy Book ID (5 bytes)
	LEA SI, BookID_INPUT
	MOV CX, 5
CP_B_ID:
	MOV AL, [SI]
	MOV [DI], AL
	INC SI
	INC DI
	LOOP CP_B_ID
	
	MOV BYTE PTR [DI], ','
	INC DI
	
	; Format BorrowDay (2 digits)
	MOV AL, BorrowDay
	MOV AH, 0
	MOV BL, 10
	DIV BL
	ADD AL, '0'
	MOV [DI], AL
	INC DI
	ADD AH, '0'
	MOV [DI], AH
	INC DI
	
	MOV BYTE PTR [DI], ','
	INC DI
	
	; Format BorrowMonth (2 digits)
	MOV AL, BorrowMonth
	MOV AH, 0
	MOV BL, 10
	DIV BL
	ADD AL, '0'
	MOV [DI], AL
	INC DI
	ADD AH, '0'
	MOV [DI], AH
	INC DI
	
	; Always end row with CRLF (\r\n)
	MOV BYTE PTR [DI], 13      ; CR
	INC DI
	MOV BYTE PTR [DI], 10      ; LF

; ----------------------------------------------------------
; 6. Append to borrowed.txt (Always at file end)
; ----------------------------------------------------------
	MOV AH, 3DH
	MOV AL, 2                  ; Read/Write Access
	LEA DX, BorrowFILE
	INT 21H
	JNC OPEN_BORROW_OK
	
	; If file doesn't exist, create it
	MOV AH, 3CH
	MOV CX, 0
	LEA DX, BorrowFILE
	INT 21H

OPEN_BORROW_OK:
	MOV fileHandle, AX
	
	; Seek EOF so it always writes to a new line at the end
	MOV AH, 42H
	MOV AL, 2
	MOV BX, fileHandle
	XOR CX, CX
	XOR DX, DX
	INT 21H
	
	; Write fixed 19-byte row
	MOV AH, 40H
	MOV BX, fileHandle
	MOV CX, 19
	LEA DX, BorrowRecord
	INT 21H
	
	MOV AH, 3EH
	MOV BX, fileHandle
	INT 21H
	
	INC TotalBooks
	MOV AH, 09H
	LEA DX, msgBorrowSuccess
	INT 21H
	
	JMP BORROW_EXIT
	
BOOK_NOT_FOUND:
	MOV AH, 09H
	LEA DX, msgErrBookNotFound
	INT 21H
	; Falls through directly to BORROW_EXIT

BORROW_EXIT:
	CALL WAIT_KEY
	RET
BORROW_BOOK ENDP
; ==========================================================
; 2. SUBSCRIBE / UPGRADE MEMBERSHIP TIER (30-Day Expiry)
; ==========================================================
SUBSCRIBE_TIER PROC
	CALL CLEAR_SCREEN
	
	; === Check if membership is already active ===
	CMP MemberTier, 'N'
	JE  ALLOW_SUBSCRIBE          ; Tier is NONE -> allow user to subscribe

	; Already active (Bronze, Silver, or Gold) -> Block subscription
	MOV AH, 09H
	LEA DX, msgAlreadyActive
	INT 21H
	CALL WAIT_KEY
	RET

ALLOW_SUBSCRIBE:	
	CALL PRINT_BALANCE
	
	MOV AH, 09H
	LEA DX, msgTierMenu
	INT 21H
	
	MOV AH, 01H
	INT 21H
	MOV BL, AL
	
	MOV AH, 09H
	LEA DX, NL
	INT 21H
	
	CMP BL, '1'
	JE  SUB_BRONZE
	CMP BL, '2'
	JE  SUB_SILVER
	CMP BL, '3'
	JE  SUB_GOLD
	RET

SUB_BRONZE:
	CMP MemberBalance, 50
	JB  SUB_NO_MONEY
	SUB MemberBalance, 50
	ADD TotalRevenue, 50
	MOV MemberTier, 'B'
	JMP SET_EXPIRY_DATE

SUB_SILVER:
	CMP MemberBalance, 75
	JB  SUB_NO_MONEY
	SUB MemberBalance, 75
	ADD TotalRevenue, 75
	MOV MemberTier, 'S'
	JMP SET_EXPIRY_DATE

SUB_GOLD:
	CMP MemberBalance, 100
	JB  SUB_NO_MONEY
	SUB MemberBalance, 100
	ADD TotalRevenue, 100
	MOV MemberTier, 'G'
	JMP SET_EXPIRY_DATE

SUB_NO_MONEY:
	MOV AH, 09H
	LEA DX, msgNoMoney
	INT 21H
	CALL WAIT_KEY
	RET

SET_EXPIRY_DATE:
	; Fetch real-time DOS date: DH = Month, DL = Day
	MOV AH, 2AH
	INT 21H
	
	; Expiry is 30 days = same day next month
	MOV ExpiryDay, DL
	INC DH              ; Next month
	CMP DH, 12
	JBE MONTH_OK
	MOV DH, 1           ; Wrap December to January

MONTH_OK:
	MOV ExpiryMonth, DH
	
	CALL SAVE_USER_DATA
	
	MOV AH, 09H
	LEA DX, msgSubSuccess
	INT 21H
	CALL WAIT_KEY
	RET
SUBSCRIBE_TIER ENDP

; ==========================================================
; EXPIRY CHECK ROUTINE
; ==========================================================
CHECK_EXPIRY_STATUS PROC
	CMP MemberTier, 'N'
	JE  EXP_DONE

	MOV AH, 2AH
	INT 21H
	MOV CurrentDay, DL
	MOV CurrentMonth, DH

	MOV AL, CurrentMonth
	CMP AL, ExpiryMonth
	JA  TIER_HAS_EXPIRED
	JB  EXP_DONE

	MOV AL, CurrentDay
	CMP AL, ExpiryDay
	JAE TIER_HAS_EXPIRED
	JMP EXP_DONE

TIER_HAS_EXPIRED:
	MOV MemberTier, 'N'
	MOV ExpiryDay, 0
	MOV ExpiryMonth, 0
	CALL SAVE_USER_DATA
	MOV AH, 09H
	LEA DX, msgTierExpired
	INT 21H
	CALL WAIT_KEY

EXP_DONE:
	RET
CHECK_EXPIRY_STATUS ENDP

; ==========================================================
; 2. RETURN BOOK (Protected Stack, Safe Buffer, No 乱码)
; ==========================================================
RETURN_BOOK PROC
	CALL CLEAR_SCREEN
	CALL PRINT_BALANCE
	
	MOV HasBorrowedBooks, 0

	; --------------------------------------------------
	; Step 1: Display all books borrowed by logged-in user
	; --------------------------------------------------
	MOV AH, 09H
	LEA DX, msgBorrowedListTitle
	INT 21H

	MOV AH, 3DH
	MOV AL, 0
	LEA DX, BorrowFILE
	INT 21H
	JNC OPEN_BORROW_LIST_OK
	JMP NO_BORROWED_LIST

OPEN_BORROW_LIST_OK:
	MOV fileHandle, AX
	MOV AH, 3FH
	MOV BX, fileHandle
	MOV CX, 1000
	LEA DX, buffer
	INT 21H
	PUSH AX
	
	MOV AH, 3EH
	MOV BX, fileHandle
	INT 21H
	POP CX

	CMP CX, 0
	JNE START_LIST_SCAN
	JMP NO_BORROWED_LIST

START_LIST_SCAN:
	LEA SI, buffer

SCAN_USER_BORROWS:
	CMP CX, 5
	JAE PROCEED_BORROW_SCAN
	JMP CHECK_BORROW_COUNT

PROCEED_BORROW_SCAN:
	; Skip whitespace
	CMP BYTE PTR [SI], ' '
	JE  SKIP_LIST_CHAR
	CMP BYTE PTR [SI], 13
	JE  SKIP_LIST_CHAR
	CMP BYTE PTR [SI], 10
	JE  SKIP_LIST_CHAR
	JMP COMPARE_LIST_ENTRY

SKIP_LIST_CHAR:
	INC SI
	DEC CX
	JNZ SCAN_USER_BORROWS
	JMP CHECK_BORROW_COUNT

COMPARE_LIST_ENTRY:
	LEA DI, MemberID_INPUT
	PUSH CX
	PUSH SI
	MOV CX, 5
COMPARE_USER_LIST:
	MOV AL, [SI]
	CMP AL, [DI]
	JNE LIST_MISMATCH
	INC SI
	INC DI
	LOOP COMPARE_USER_LIST

	; Member ID Matched!
	MOV HasBorrowedBooks, 1
	INC SI                      ; Skip ','

	; Display "-> Book ID: "
	MOV AH, 09H
	LEA DX, msgBorrowPrefix
	INT 21H

	; Print strict 5 chars for BookID
	MOV CX, 5
PRINT_5_CHAR_BK:
	MOV DL, [SI]
	MOV AH, 02H
	INT 21H
	INC SI
	LOOP PRINT_5_CHAR_BK

	INC SI                      ; Skip ','

	MOV AH, 09H
	LEA DX, msgDatePrefix
	INT 21H

	; Print strict 2 chars for Day
	MOV DL, [SI]
	MOV AH, 02H
	INT 21H
	INC SI
	MOV DL, [SI]
	MOV AH, 02H
	INT 21H
	INC SI

	INC SI                      ; Skip ','
	
	; Print '/' Separator
	MOV DL, '/'
	MOV AH, 02H
	INT 21H

	; Print strict 2 chars for Month
	MOV DL, [SI]
	MOV AH, 02H
	INT 21H
	INC SI
	MOV DL, [SI]
	MOV AH, 02H
	INT 21H
	INC SI

	MOV AH, 09H
	LEA DX, NL
	INT 21H

	; Restore pointers to the exact start of the line to sync CX safely
	POP SI
	POP CX
	JMP SKIP_TO_NEXT_LINE

LIST_MISMATCH:
	POP SI
	POP CX

SKIP_TO_NEXT_LINE:
	MOV AL, [SI]
	INC SI
	DEC CX
	JZ  CHECK_BORROW_COUNT
	CMP AL, 10                  ; Move forward until newline LF
	JNE SKIP_TO_NEXT_LINE
	JMP SCAN_USER_BORROWS

CHECK_BORROW_COUNT:
	CMP HasBorrowedBooks, 1
	JE  PROMPT_RETURN_INPUT

NO_BORROWED_LIST:
	MOV AH, 09H
	LEA DX, msgNoBorrowedBooks
	INT 21H
	JMP RET_EXIT

	; --------------------------------------------------
	; Step 2: Prompt Book ID to Return
	; --------------------------------------------------
PROMPT_RETURN_INPUT:
	MOV AH, 09H
	LEA DX, msgPromtBookID
	INT 21H
	
	MOV AH, 0CH
	MOV AL, 0
	INT 21H

	LEA SI, BookID_INPUT
	MOV CX, 5
READ_RET_BK:
	MOV AH, 01H
	INT 21H
	CMP AL, 13                  ; Ignore accidental Enter
	JE  READ_RET_BK
	MOV [SI], AL
	INC SI
	LOOP READ_RET_BK

	MOV AH, 09H
	LEA DX, NL
	INT 21H

	; --------------------------------------------------
	; Step 3: Open borrowed.txt & Locate Transaction
	; --------------------------------------------------
	MOV AH, 3DH
	MOV AL, 2
	LEA DX, BorrowFILE
	INT 21H
	JNC OPEN_RET_OK
	JMP NOT_BORROWED_ERR

OPEN_RET_OK:
	MOV fileHandle, AX
	MOV AH, 3FH
	MOV BX, fileHandle
	MOV CX, 1000
	LEA DX, buffer
	INT 21H
	
	MOV borrowFileSize, AX
	MOV CX, AX
	
	MOV AH, 3EH
	MOV BX, fileHandle
	INT 21H
	
	CMP CX, 0
	JNE SCAN_BORROW_START
	JMP NOT_BORROWED_ERR

SCAN_BORROW_START:
	LEA SI, buffer

FIND_BORROW_RECORD:
	CMP CX, 5
	JAE PROCEED_FIND_REC
	JMP NOT_BORROWED_ERR

PROCEED_FIND_REC:
	CMP BYTE PTR [SI], ' '
	JE  SKIP_RET_STRAY
	CMP BYTE PTR [SI], 13
	JE  SKIP_RET_STRAY
	CMP BYTE PTR [SI], 10
	JE  SKIP_RET_STRAY
	JMP MATCH_BORROW_FIELDS

SKIP_RET_STRAY:
	INC SI
	DEC CX
	JNZ FIND_BORROW_RECORD
	JMP NOT_BORROWED_ERR

MATCH_BORROW_FIELDS:
	LEA DI, MemberID_INPUT
	PUSH CX
	PUSH SI
	MOV CX, 5
COMP_RET_MID:
	MOV AL, [SI]
	CMP AL, [DI]
	JNE RET_REC_MISMATCH
	INC SI
	INC DI
	LOOP COMP_RET_MID
	
	INC SI                      ; Skip ','
	
	LEA DI, BookID_INPUT
	MOV CX, 5
COMP_RET_BID:
	MOV AL, [SI]
	CMP AL, [DI]
	JNE RET_REC_MISMATCH
	INC SI
	INC DI
	LOOP COMP_RET_BID
	
	INC SI                      ; Skip ','
	
	; Parse BorrowDay (2 digits)
	MOV AL, [SI]
	SUB AL, '0'
	MOV BL, 10
	MUL BL
	INC SI
	ADD AL, [SI]
	SUB AL, '0'
	MOV BorrowDay, AL
	INC SI
	
	INC SI                      ; Skip ','
	
	; Parse BorrowMonth (2 digits)
	MOV AL, [SI]
	SUB AL, '0'
	MOV BL, 10
	MUL BL
	INC SI
	ADD AL, [SI]
	SUB AL, '0'
	MOV BorrowMonth, AL
	
	POP SI                      ; SI = Start of matched record
	POP CX                      ; CX = Remaining bytes from record start
	JMP CHECK_LATE_FINE_FIRST

RET_REC_MISMATCH:
	POP SI
	POP CX

SKIP_RET_LINE:
	MOV AL, [SI]
	INC SI
	DEC CX
	JNZ CONT_SKIP_RET_LINE
	JMP NOT_BORROWED_ERR

CONT_SKIP_RET_LINE:
	CMP AL, 10
	JNE SKIP_RET_LINE
	JMP FIND_BORROW_RECORD

	; --------------------------------------------------
	; Step 4: Calculate Late Fine & CHECK BALANCE FIRST
	; --------------------------------------------------
CHECK_LATE_FINE_FIRST:
	; PROTECT REGISTERS!
	; INT 21H AH=2AH overwrites CX with the Year. 
	; PRINT_NUM overwrites CX with digits.
	; We MUST safely lock away CX (file bytes) and SI (buffer pointer).
	PUSH CX
	PUSH SI

	MOV AH, 2AH
	INT 21H

	; Month difference with year wrap support
	MOV AL, DH
	CMP AL, BorrowMonth
	JAE NO_YEAR_WRAP_RET
	ADD AL, 12
NO_YEAR_WRAP_RET:
	SUB AL, BorrowMonth
	MOV BL, 30
	MUL BL
	MOV CH, AL

	; Day difference: Add CH first to avoid negative underflow
	MOV AL, DL
	ADD AL, CH
	SUB AL, BorrowDay
	MOV DaysElapsed, AL

	; Max allowance based on tier
	MOV MaxAllowedDays, 7       ; Bronze
	CMP MemberTier, 'B'
	JE  CHECK_FINE_CALC

	CMP MemberTier, 'S'
	JNE CHK_GOLD_ALLOW_RET
	MOV MaxAllowedDays, 14      ; Silver
	JMP CHECK_FINE_CALC

CHK_GOLD_ALLOW_RET:
	CMP MemberTier, 'G'
	JNE CHECK_FINE_CALC
	MOV MaxAllowedDays, 30      ; Gold

CHECK_FINE_CALC:
	MOV AL, DaysElapsed
	CMP AL, MaxAllowedDays
	JBE ALLOW_RETURN_NO_FINE    ; Not overdue

	; Fine = (DaysElapsed - Allowance) * RM 3
	SUB AL, MaxAllowedDays
	MOV OverdueDays, AL
	MOV CL, 3
	MUL CL
	MOV BL, AL                  ; BL = Fine Amount

	; Balance validation
	CMP MemberBalance, BL
	JAE BAL_IS_ENOUGH

	; If not enough balance: Restore stack and exit
	POP SI
	POP CX
	JMP RET_FINE_UNPAID

BAL_IS_ENOUGH:
	; Deduct fine & update memory variables
	SUB MemberBalance, BL
	ADD TotalFine, BL
	ADD TotalRevenue, BL

	MOV AH, 09H
	LEA DX, msgFinePaid
	INT 21H
	MOV AL, BL
	CALL PRINT_NUM
	CALL PRINT_BALANCE
	JMP READY_TO_DELETE

ALLOW_RETURN_NO_FINE:
	MOV AH, 09H
	LEA DX, msgReturnSuccess
	INT 21H

READY_TO_DELETE:
	; RESTORE REGISTERS cleanly BEFORE executing file deletion
	POP SI
	POP CX

	; --------------------------------------------------
	; Step 5: Shift & Delete from borrowed.txt (19 Bytes)
	; --------------------------------------------------
EXECUTE_FILE_DELETION:
	MOV DI, SI                  ; DI = Start of matched record
	ADD SI, 19                  ; SI = Start of next record
	
	SUB CX, 19
	CMP CX, 0
	JLE DONE_SHIFTING_DATA

SHIFT_BUFFER_LOOP_RET:
	MOV AL, [SI]
	MOV [DI], AL
	INC SI
	INC DI
	LOOP SHIFT_BUFFER_LOOP_RET

DONE_SHIFTING_DATA:
	SUB borrowFileSize, 19

	MOV AH, 3CH                 ; Re-create/truncate borrowed.txt
	MOV CX, 0
	LEA DX, BorrowFILE
	INT 21H
	MOV fileHandle, AX

	CMP borrowFileSize, 0
	JE  CLOSE_BORROW_FILE

	MOV AH, 40H
	MOV BX, fileHandle
	MOV CX, borrowFileSize
	LEA DX, buffer
	INT 21H

CLOSE_BORROW_FILE:
	MOV AH, 3EH
	MOV BX, fileHandle
	INT 21H

	; --------------------------------------------------
	; Step 6: Replenish Book Stock in book.txt (+1)
	; --------------------------------------------------
	MOV AH, 3DH
	MOV AL, 2
	LEA DX, BookFILE
	INT 21H
	JNC OPEN_BOOK_INC_OK
	
	; Save user data even if book.txt fails to open
	CALL SAVE_USER_DATA
	JMP RET_EXIT

OPEN_BOOK_INC_OK:
	MOV fileHandle, AX

	MOV AH, 3FH
	MOV BX, fileHandle
	MOV CX, 320
	LEA DX, bookBuffer
	INT 21H

	LEA SI, bookBuffer
	MOV CX, 10

SCAN_BK_FOR_INC_RET:
	LEA DI, BookID_INPUT
	PUSH CX
	PUSH SI
	MOV CX, 5
COMP_BK_FOR_INC_RET:
	MOV AL, [SI]
	CMP AL, [DI]
	JNE NEXT_BK_INC_RET
	INC SI
	INC DI
	LOOP COMP_BK_FOR_INC_RET

	; Increment stock digit at offset 27
	POP SI
	POP CX
	LEA BX, [SI + 27]

	CMP BYTE PTR [BX+2], '9'
	JNE INC_SINGLE_DIGIT_RET
	MOV BYTE PTR [BX+2], '0'
	INC BYTE PTR [BX+1]
	JMP WRITE_UPDATED_BOOK_RET

INC_SINGLE_DIGIT_RET:
	INC BYTE PTR [BX+2]

WRITE_UPDATED_BOOK_RET:
	MOV AH, 42H
	MOV AL, 0
	MOV BX, fileHandle
	XOR CX, CX
	XOR DX, DX
	INT 21H

	MOV AH, 40H
	MOV BX, fileHandle
	MOV CX, 320
	LEA DX, bookBuffer
	INT 21H

	MOV AH, 3EH
	MOV BX, fileHandle
	INT 21H
	
	; Now that buffer is freed, it is 100% safe to save account.txt!
	CALL SAVE_USER_DATA         
	JMP RET_EXIT

NEXT_BK_INC_RET:
	POP SI
	POP CX
	ADD SI, 32
	LOOP SCAN_BK_FOR_INC_RET

	MOV AH, 3EH
	MOV BX, fileHandle
	INT 21H
	
	; Now that buffer is freed, it is 100% safe to save account.txt!
	CALL SAVE_USER_DATA         
	JMP RET_EXIT

RET_FINE_UNPAID:
	MOV AH, 09H
	LEA DX, msgNoMoney
	INT 21H
	JMP RET_EXIT

NOT_BORROWED_ERR:
	MOV AH, 09H
	LEA DX, msgErrNotBorrowed
	INT 21H

RET_EXIT:
	CALL WAIT_KEY
	RET
RETURN_BOOK ENDP

; ==========================================================
; 3. Member Top-up
; ==========================================================
TOP_UP PROC
TOP_UP_START:
	CALL CLEAR_SCREEN
	
	; === Status Checking ===
	CMP TOPUP_STATUS, 1
	JE  SHOW_ERR_INVALID3
	CMP TOPUP_STATUS, 2
	JE  SHOW_ERR_OVERFLOW
	JMP CONTINUE_TOPUP

SHOW_ERR_INVALID3:
	MOV AH, 09H
	LEA DX, msgInvalidNum   ; 显示 Invalid input!
	INT 21H
	MOV TOPUP_STATUS, 0     ; 重置状态
	JMP CONTINUE_TOPUP

SHOW_ERR_OVERFLOW:
	MOV AH, 09H
	LEA DX, msgOverflow     ; 显示 Overflow limit!
	INT 21H
	MOV TOPUP_STATUS, 0     ; 重置状态
	JMP CONTINUE_TOPUP

CONTINUE_TOPUP:
	CALL PRINT_BALANCE
	
	MOV AH, 09H
	LEA DX, msgPromtTopup
	INT 21H

	; === Input Validation Check 1 (十位数) ===
	MOV AH, 01H
	INT 21H
	MOV BL, AL              ; 先存进 BL
	CMP BL, '0'
	JB  INVALID_TOPUP
	CMP BL, '9'
	JA  INVALID_TOPUP
	
	; 换算并存入 CH
	SUB BL, '0'
	MOV AL, BL
	MOV CL, 10
	MUL CL          
	MOV CH, AL              ; 用 CH 保存十位数值

	; === Input Validation Check 2 (个位数) ===
	MOV AH, 01H
	INT 21H
	MOV BL, AL              ; 存进 BL
	CMP BL, '0'
	JB  INVALID_TOPUP
	CMP BL, '9'
	JA  INVALID_TOPUP
	
	MOV AH, 09H             ; <--- 输入两个数字后统一加入换行
	LEA DX, NL
	INT 21H
	
	; 换算并加总
	SUB BL, '0'
	ADD CH, BL              ; CH = 真正充值的金额 (十位 + 个位)

	; === Value Checking (Carry) ===
	MOV AL, MemberBalance
	ADD AL, CH
	JC  OVERFLOW_TOPUP 

	; === Update Data ===
	MOV MemberBalance, AL
	
	CALL SAVE_USER_DATA

	; === Display Form ===
	MOV AH, 09H
	LEA DX, msgTopupSuccess
	INT 21H
	CALL PRINT_BALANCE
	
	CALL WAIT_KEY
	RET                     ; 成功退出

INVALID_TOPUP:
	MOV TOPUP_STATUS, 1
	JMP TOP_UP_START

OVERFLOW_TOPUP:
	MOV TOPUP_STATUS, 2
	JMP TOP_UP_START
TOP_UP ENDP

; ==========================================================
; 4. Daily Summary Report
; ==========================================================
PRINT_REPORT PROC
	CALL CLEAR_SCREEN
	
	;Display Report Form
	MOV AH, 09H
	LEA DX, msgRepTitle
	INT 21H
	
	;Display Report Form (Book Borrow)
	LEA DX, msgRepBooks
	INT 21H

	;Display Report Detail (Book Borrow)
	MOV AL, TotalBooks
	CALL PRINT_NUM

	;Display Report Form (Fine)
	MOV AH, 09H
	LEA DX, msgRepFine
	INT 21H

	;Display Fine Detail (Fine)
	MOV AL, TotalFine
	CALL PRINT_NUM
	
	;Display Report Form (Revenue)
	MOV AH, 09H
	LEA DX, msgRepSpe
	INT 21H

	;Display Report Detail (Revenue)
	MOV AL, TotalRevenue
	CALL PRINT_NUM
	
	;Display Report Form
	MOV AH, 09H
	LEA DX, msgRepLine
	INT 21H
	
	CALL WAIT_KEY
	
	RET
PRINT_REPORT ENDP

PRINT_USER_STATUS PROC
	CALL PRINT_BALANCE
	
	MOV AH, 09H
	LEA DX, msgTierShow
	INT 21H
	
	CMP MemberTier, 'B'
	JE  PR_BRONZE
	CMP MemberTier, 'S'
	JE  PR_SILVER
	CMP MemberTier, 'G'
	JE  PR_GOLD
	
	LEA DX, msgTierNoneStr
	INT 21H
	JMP PR_STATUS_END

PR_BRONZE:
	LEA DX, msgTierBronzeStr
	INT 21H
	JMP PR_EXPIRY

PR_SILVER:
	LEA DX, msgTierSilverStr
	INT 21H
	JMP PR_EXPIRY

PR_GOLD:
	LEA DX, msgTierGoldStr
	INT 21H

PR_EXPIRY:
	MOV AH, 09H
	LEA DX, msgExpiryShow
	INT 21H
	
	MOV AL, ExpiryDay
	CALL PRINT_2DIGIT
	
	MOV AH, 02H
	MOV DL, '/'
	INT 21H
	
	MOV AL, ExpiryMonth
	CALL PRINT_2DIGIT

PR_STATUS_END:
	MOV AH, 09H
	LEA DX, NL
	INT 21H
	RET
PRINT_USER_STATUS ENDP

PRINT_2DIGIT PROC
	MOV AH, 0
	MOV BL, 10
	DIV BL
	MOV DH, AH
	
	MOV DL, AL
	ADD DL, '0'
	MOV AH, 02H
	INT 21H
	
	MOV DL, DH
	ADD DL, '0'
	MOV AH, 02H
	INT 21H
	RET
PRINT_2DIGIT ENDP

PRINT_NUM PROC
	MOV AH, 0
	MOV BL, 100
	DIV BL
	MOV CH, AL

	MOV AL, AH
	MOV AH, 0
	MOV BL, 10
	DIV BL
	MOV CL, AL
	MOV DH, AH

	MOV AH, 02H
	MOV DL, CH
	ADD DL, 30H
	INT 21H

	MOV DL, CL
	ADD DL, 30H
	INT 21H

	MOV DL, DH
	ADD DL, 30H
	INT 21H
	RET
PRINT_NUM ENDP

; ==========================================================
; Print Balance
; ==========================================================
PRINT_BALANCE PROC
	MOV AH, 09H
	LEA DX, msgBalanceShow
	INT 21H

	MOV AL, MemberBalance
	CALL PRINT_NUM 
	
	RET
PRINT_BALANCE ENDP

; ==========================================================
; Allow input 5 Digit
; ==========================================================
READ_USERNAME PROC
	; Flush keyboard buffer first to clear old keystrokes
	MOV AH, 0CH
	MOV AL, 0
	INT 21H

	LEA SI, MemberID_INPUT
	MOV CX, 5
READ_U:
	MOV AH, 01H
	INT 21H
	CMP AL, 13                 ; If user presses Enter too early, keep waiting
	JE  READ_U
	MOV [SI], AL
	INC SI
	LOOP READ_U
	RET
READ_USERNAME ENDP

; ==========================================================
; Safe 5-Character Password Input (Ignores leftover Enter)
; ==========================================================
READ_PASSWORD PROC
	; Flush keyboard buffer so leftover Enter from ID is wiped
	MOV AH, 0CH
	MOV AL, 0
	INT 21H

	LEA SI, Password_INPUT
	MOV CX, 5
READ_P:
	MOV AH, 01H
	INT 21H
	CMP AL, 13                 ; Skip accidental Enter
	JE  READ_P
	MOV [SI], AL
	INC SI
	LOOP READ_P

	; Print newline after typing password
	MOV AH, 09H
	LEA DX, NL
	INT 21H
	RET
READ_PASSWORD ENDP

; ==========================================================
; (Wait for Any Key)
; ==========================================================
WAIT_KEY PROC
	MOV AH, 09H
	LEA DX, msgPressAnyKey
	INT 21H

	MOV AH, 08H
	INT 21H
	
	RET
WAIT_KEY ENDP

; ==========================================================
; (Clear Screen)
; ==========================================================
CLEAR_SCREEN PROC
	MOV AX, 0600H    ; AH=06H (卷动窗口), AL=00H (清空整个屏幕)
	MOV BH, 07H      ; BH=07H (颜色属性：黑底白字，如果是 70H 就是白底黑字)
	MOV CX, 0000H    ; 左上角坐标：行 0, 列 0
	MOV DX, 184FH    ; 右下角坐标：行 24 (18H), 列 79 (4FH)
	INT 10H          ; 呼叫 BIOS 视频服务 (注意：这里是 10H，不是 21H！)

	; 2. 重置光标到左上角 (如果不重置，清屏后字会从屏幕底部开始打)
	MOV AH, 02H      ; AH=02H (设定光标位置)
	MOV BH, 00H      ; 第 0 页
	MOV DX, 0000H    ; 行 0, 列 0
	INT 10H
	
	RET
CLEAR_SCREEN ENDP

; ==========================================================
; Save Current User State (Balance, Tier, Expiry) to account.txt
; ==========================================================
SAVE_USER_DATA PROC
	; 1. Open account.txt (Read/Write Access AL = 2)
	MOV AH, 3DH
	MOV AL, 2
	LEA DX, AccFILE
	INT 21H
	JNC SAVE_OPEN_OK
	JMP SAVE_ERR               ; Far jump bridge

SAVE_OPEN_OK:
	MOV fileHandle, AX

	; 2. Read entire file into buffer
	MOV AH, 3FH
	MOV BX, fileHandle
	MOV CX, 1000
	LEA DX, buffer
	INT 21H
	MOV accFileSize, AX
	PUSH AX                    ; Total bytes read
	POP CX                     ; CX = total bytes read

	CMP CX, 0
	JNE SAVE_START_SCAN
	JMP CLOSE_SAVE_ERR         ; Far jump bridge

SAVE_START_SCAN:
	LEA SI, buffer

FIND_USER_RECORD:
	CMP CX, 5
	JAE COMPARE_USER_ID_START
	JMP CLOSE_SAVE_ERR         ; Far jump bridge

COMPARE_USER_ID_START:
	LEA DI, MemberID_INPUT
	PUSH CX
	PUSH SI
	MOV CX, 5
COMPARE_USER_ID:
	MOV AL, [SI]
	CMP AL, [DI]
	JE  USER_CHAR_MATCH
	JMP RECORD_NOT_TARGET_BRIDGE

USER_CHAR_MATCH:
	INC SI
	INC DI
	LOOP COMPARE_USER_ID

	; Target User Record Located!
	POP SI
	POP CX
	JMP WRITE_USER_FIELDS

RECORD_NOT_TARGET_BRIDGE:
	POP SI
	POP CX
	JMP SKIP_TO_NEXT_USER

WRITE_USER_FIELDS:
	; Skip ID(5) + ','(1) + Pass(5) + ','(1) = 12 bytes to reach Balance
	ADD SI, 12

	; Overwrite 3-digit Balance
	MOV AL, MemberBalance
	MOV AH, 0
	MOV BL, 100
	DIV BL
	ADD AL, '0'
	MOV [SI], AL               ; Hundreds
	INC SI

	MOV AL, AH
	MOV AH, 0
	MOV BL, 10
	DIV BL
	ADD AL, '0'
	MOV [SI], AL               ; Tens
	INC SI

	ADD AH, '0'
	MOV [SI], AH               ; Units
	INC SI

	INC SI                     ; Skip ','

	; Overwrite Tier
	MOV AL, MemberTier
	MOV [SI], AL
	INC SI

	INC SI                     ; Skip ','

	; Overwrite Expiry Day (2 digits)
	MOV AL, ExpiryDay
	MOV AH, 0
	MOV BL, 10
	DIV BL
	ADD AL, '0'
	MOV [SI], AL               ; Tens
	INC SI
	ADD AH, '0'
	MOV [SI], AH               ; Units
	INC SI

	INC SI                     ; Skip ','

	; Overwrite Expiry Month (2 digits)
	MOV AL, ExpiryMonth
	MOV AH, 0
	MOV BL, 10
	DIV BL
	ADD AL, '0'
	MOV [SI], AL               ; Tens
	INC SI
	ADD AH, '0'
	MOV [SI], AH               ; Units

	; 4. Rewind file pointer back to start of account.txt
	MOV AH, 42H
	MOV AL, 0                  ; Seek from start (Offset 0)
	MOV BX, fileHandle
	XOR CX, CX
	XOR DX, DX
	INT 21H

	; 5. Re-write updated buffer back to file
	MOV AH, 40H
	MOV BX, fileHandle
	MOV CX, accFileSize
	LEA DX, buffer
	INT 21H

	; 6. Close file
	MOV AH, 3EH 
	MOV BX, fileHandle
	INT 21H
	RET

SKIP_TO_NEXT_USER:
	MOV AL, [SI]
	INC SI
	DEC CX
	JZ  CLOSE_SAVE_ERR
	CMP AL, 10                 ; Newline LF
	JNE SKIP_TO_NEXT_USER
	JMP FIND_USER_RECORD

CLOSE_SAVE_ERR:
	MOV AH, 3EH
	MOV BX, fileHandle
	INT 21H

SAVE_ERR:
	RET
SAVE_USER_DATA ENDP

END MAIN
