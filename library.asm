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
		DB '1. Borrow Book',13,10
		DB '2. Return Book / Pay Fine',13,10
		DB '3. Member Top-up',13,10
		DB '4. Daily Summary Report',13,10
		DB '5. Logout',13,10
		DB '0. Exit System',13,10
		DB '=======================================',13,10
		DB 'Please enter your choice (1-5): $'
		
	CHOICE DB ?
	
	;==================================================================================================================
	
	TotalBooks 	  DB 0     ; 借出书总数
	TotalFine     DB 0     ; 罚款总额
	TotalRevenue  DB 0     ; 总收入
	MemberBalance DB 50    ; 会员余额

	msgRepTitle DB 13,10,13,10,13,10,'===== DAILY SUMMARY REPORT =====$'
	msgRepBooks DB 13,10,'Total Books Borrowed : $'
	msgRepFine  DB 13,10,'Total Fine (RM)      : $'
	msgRepRev   DB 13,10,'Total Revenue (RM)   : $'
	msgRepLine  DB 13,10,'================================$'
	
	;================================================= Prompts ========================================================

	msgPromtMemberID DB 13,10,'MemberID(M0000): $'
	msgPromtPassword DB 13,10,'Password(5 Digit): $'
	msgPromtOverdue  DB 13,10,'Enter overdue days (0-9): $'
	msgPromtDays 	 DB 13,10,'Enter borrow days (1-9): $'
	msgPromtTopup    DB 13,10,'Enter Top-up amount RM (01-99): $'
	msgReceiptEnd 	 DB 13,10,'Thank you!$'
	msgInvalidNum 	 DB 13,10,'Invalid input! Only numbers 0-9 allowed.$'
	msgOverflow      DB 13,10,'Exceeds maximum limit (RM 255)!$'
	
	msgNoMoney 		 DB 13,10,13,10,'Insufficient balance! Please go to Top-up (Menu 3).$'
	msgBalanceShow 	 DB 13,10,13,10,'Current Balance: RM $'
	msgPressAnyKey 	 DB 13,10,13,10,'Press any key to continue next step...$'
	
	msgTopupSuccess  DB 13,10,13,10,'=== TOP-UP SUCCESS ===$'
	
	msgReceipt 		 DB 13,10,13,10,'=== BORROW SUCCESS ==='
					 DB 13,10,'Please pay RM $'
				 
	msgReturnSuccess DB 13,10,13,10,'=== BOOK RETURNED ==='
					 DB 13,10,'Successfully! No fine.$'
					 
	msgFinePaid      DB 13,10,13,10,'=== LATE RETURN ==='
					 DB 13,10,'Fine deducted: RM $'
	
	; Register prompts
	msgRegisterTitle DB 13,10,13,10,'=== MEMBER REGISTRATION ===$'
	msgRegSuccess    DB 13,10,13,10,'Registration successful!$'
	msgRegFail       DB 13,10,13,10,'Registration failed (File Error)!$'
	
	;================================================= Error Messages =================================================

	ERRORMSG1 DB 13,10,'WRONG Choice $'
	ERRORMSG2 DB 13,10,'WRONG ID OR PASSWORD $'
	ERRORMSG3 DB 13,10,'WRONG PASSWORD $'
	ERRORMSG4 DB 13,10,'Too many wrong attempts! Returning to Menu.$'
	ERRORMSG5 DB 13,10,"Invalid input! Must be 1 to 9.$"
	
	;================================================= Buffers & File Variables =======================================

	MemberID_INPUT DB 5 DUP(?)
	Password_INPUT DB 5 DUP(?)
	RegRecord      DB 13 DUP(?)
	buffer         DB 512 DUP(?)
	
	fileName   DB 'account.txt', 0
	logMsg     DB 'M0001,12345', 13, 10
	msgLen     DW 13
	fileHandle DW ?
	
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
	
	CMP CHOICE, "1"
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

WRONG_CHOICE:
	MOV CHOICE_STATUS, 1   ; 把错误状态标记为 1
	JMP SELECT_PAGE         ; 重新循环回页面顶部（触发清屏并准备报错）

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
	LEA DX, fileName
	INT 21H
	JNC OPEN_FILE_OK
	JMP ERROR_OPEN

OPEN_FILE_OK:
	MOV fileHandle, AX

	; 2. Read entire file into buffer
	MOV AH, 3FH
	MOV BX, fileHandle
	MOV CX, 500
	LEA DX, buffer
	INT 21H
	PUSH AX                  ; Save total bytes read
	
	; Close File Handle
	MOV AH, 3EH
	MOV BX, fileHandle
	INT 21H
	POP CX                   ; CX = bytes read

	CMP CX, 0
	JNE START_PARSER
	JMP AUTH_FAIL

START_PARSER:
	LEA SI, buffer

CHECK_NEXT_RECORD:
	CMP CX, 11
	JAE COMPARE_RECORD_FIELDS
	JMP AUTH_FAIL

COMPARE_RECORD_FIELDS:
	; Compare ID (5 bytes)
	LEA DI, MemberID_INPUT
	PUSH CX
	PUSH SI
	MOV CX, 5
COMPARE_REC_ID:
	MOV AL, [SI]
	CMP AL, [DI]
	JNE RECORD_MISMATCH
	INC SI
	INC DI
	LOOP COMPARE_REC_ID

	; Verify comma separator
	CMP BYTE PTR [SI], ','
	JNE RECORD_MISMATCH
	INC SI

	; Compare Password (5 bytes)
	LEA DI, Password_INPUT
	MOV CX, 5
COMPARE_REC_PASS:
	MOV AL, [SI]
	CMP AL, [DI]
	JNE RECORD_MISMATCH
	INC SI
	INC DI
	LOOP COMPARE_REC_PASS

	; Success -> Go to Main Menu
	POP SI
	POP CX
	JMP GO_TO_MAIN_MENU

GO_TO_MAIN_MENU:
	JMP MAIN_MENU

RECORD_MISMATCH:
	POP SI
	POP CX

SKIP_LINE:
	MOV AL, [SI]
	INC SI
	DEC CX
	JZ  AUTH_FAIL_BRIDGE
	CMP AL, 10
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
	LEA DX, fileName
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
	JE RETURN_BOOK_PAGE    ;Return Book
	
	CMP CHOICE, '3'
	JE TOP_UP_PAGE         ;Top Up
	
	CMP CHOICE, '4'
	JE SHOW_REPORT_PAGE    ;View Report
	
	CMP CHOICE,'5'
	JE SELECT_PAGE_MID_POINT			;Logout
	
	CMP CHOICE, '0'
	JE FIN                 ; 退出系统
	
	MOV CHOICE_STATUS,1
	JMP MAIN_MENU
	
BORROW_BOOK_PAGE:
	;1
	CALL Borrow_Book
	JMP MAIN_MENU

RETURN_BOOK_PAGE:
	;2
	CALL RETURN_BOOK
	JMP MAIN_MENU
	
TOP_UP_PAGE:
	;3
	CALL TOP_UP
	JMP MAIN_MENU
	
SHOW_REPORT_PAGE:
	;4
	CALL PRINT_REPORT
	JMP MAIN_MENU

SELECT_PAGE_MID_POINT:
	;5
	JMP SELECT_PAGE
;================================================= END ================================================================
FIN:
	CALL CLEAR_SCREEN
    MOV AX, 4C00H
    INT 21H

MAIN ENDP

; ==========================================================
; Register Member: Appends "ID,Password\r\n" to account.txt
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

	; 2. Read Password (5 chars)
	MOV AH, 09H
	LEA DX, msgPromtPassword
	INT 21H
	CALL READ_PASSWORD

	; 3. Format buffer: [ID:5] + [','] + [Pass:5] + [0DH] + [0AH]
	LEA DI, RegRecord
	LEA SI, MemberID_INPUT
	MOV CX, 5
COPY_REG_ID:
	MOV AL, [SI]
	MOV [DI], AL
	INC SI
	INC DI
	LOOP COPY_REG_ID
	
	MOV BYTE PTR [DI], ','
	INC DI
	
	LEA SI, Password_INPUT
	MOV CX, 5
COPY_REG_PASS:
	MOV AL, [SI]
	MOV [DI], AL
	INC SI
	INC DI
	LOOP COPY_REG_PASS
	
	MOV BYTE PTR [DI], 13      ; CR
	INC DI
	MOV BYTE PTR [DI], 10      ; LF
	
	; 4. Open account.txt (Read/Write Access: AL = 2)
	MOV AH, 3DH
	MOV AL, 2
	LEA DX, fileName
	INT 21H
	JNC OPEN_REG_OK

	; Create file if missing
	MOV AH, 3CH
	MOV CX, 0
	LEA DX, fileName
	INT 21H
	JC  REG_FILE_ERROR

OPEN_REG_OK:
	MOV fileHandle, AX

	; 5. Seek to End of File (AL = 2, CX:DX = 0)
	MOV AH, 42H
	MOV AL, 2
	MOV BX, fileHandle
	XOR CX, CX
	XOR DX, DX
	INT 21H
	JC  REG_FILE_ERROR

	; 6. Append 13 bytes
	MOV AH, 40H
	MOV BX, fileHandle
	MOV CX, 13
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
; 1. Borrow Book
; ==========================================================
Borrow_Book PROC
BORROW_START:
	CALL CLEAR_SCREEN
	
	; === Status Checking ===
	CMP BORROW_STATUS, 1
	JE  SHOW_ERR_INVALID
	CMP BORROW_STATUS, 2
	JE  SHOW_ERR_NOMONEY
	JMP CONTINUE_BORROW

SHOW_ERR_INVALID:
	MOV AH, 09H
	LEA DX, ERRORMSG5       ; 显示 Invalid input!
	INT 21H
	MOV BORROW_STATUS, 0    ; 重置状态
	JMP CONTINUE_BORROW

SHOW_ERR_NOMONEY:
	MOV AH, 09H
	LEA DX, msgNoMoney      ; 显示 Insufficient balance!
	INT 21H
	MOV BORROW_STATUS, 0    ; 重置状态
	JMP CONTINUE_BORROW

CONTINUE_BORROW:
	CALL PRINT_BALANCE
	
	MOV AH, 09H
	LEA DX, msgPromtDays
	INT 21H
	
	MOV AH, 01H
	INT 21H
	MOV BL, AL              ; <--- 关键：立刻把输入保存到 BL

	MOV AH, 09H             ; <--- 统一加入换行，排版更美观
	LEA DX, NL
	INT 21H
	
	; === Valid Check ===
	CMP BL, '0'
	JNE CHECK_BORROW_RANGE
	JMP Exit_BORROW_BOOK

CHECK_BORROW_RANGE:
	CMP BL, '1'
	JB  INVALID_DAYS
	CMP BL, '9'
	JA  INVALID_DAYS

	; === Calculation (1 Day RM 2) ===
	SUB BL, 30H             ; 使用 BL 计算
	MOV AL, BL
	MOV CL, 2
	MUL CL                  ; 结果存在 AL (借书费)
	
	; === Check value enough to process ===
	CMP MemberBalance, AL
	JB INSUFFICIENT_BAL
	
	; === Update Data ===
	SUB MemberBalance, AL
	INC TotalBooks
	
	; === Display Receipt Form ===
	MOV AH, 09H
	LEA DX, msgReceipt
	INT 21H
	
	; Display Receipt Detail
	CALL PRINT_NUM
	
	; Display Receipt End
	MOV AH, 09H
	LEA DX, msgReceiptEnd
	INT 21H
	CALL PRINT_BALANCE
	
Exit_BORROW_BOOK:
	CALL WAIT_KEY
	RET                     ; 成功退出

INVALID_DAYS:
	MOV BORROW_STATUS, 1
	JMP BORROW_START

INSUFFICIENT_BAL:
	MOV BORROW_STATUS, 2
	JMP BORROW_START
Borrow_Book ENDP

; ==========================================================
; 2. Return Book / Pay Fine
; ==========================================================
RETURN_BOOK PROC
RETURN_START:
	CALL CLEAR_SCREEN
	
	; === Status Checking ===
	CMP RETURN_STATUS, 1
	JE  SHOW_ERR_INVALID2
	CMP RETURN_STATUS, 2
	JE  SHOW_ERR_NOMONEY2
	JMP CONTINUE_RETURN
	
SHOW_ERR_INVALID2:
	MOV AH, 09H
	LEA DX, ERRORMSG5       ; 显示 Invalid input!
	INT 21H
	MOV RETURN_STATUS, 0    ; 重置状态
	JMP CONTINUE_RETURN

SHOW_ERR_NOMONEY2:
	MOV AH, 09H
	LEA DX, msgNoMoney      ; 显示 Insufficient balance!
	INT 21H
	MOV RETURN_STATUS, 0    ; 重置状态
	JMP CONTINUE_RETURN

CONTINUE_RETURN:
	CALL PRINT_BALANCE
	
	MOV AH, 09H
	LEA DX, msgPromtOverdue
	INT 21H

	MOV AH, 01H
	INT 21H
	MOV BL, AL              ; <--- 关键：统一把输入保存到 BL
	
	MOV AH, 09H             ; <--- 统一加入换行
	LEA DX, NL
	INT 21H

	; === Valid Check ===
	CMP BL, '0'             ; 使用 BL 验证
	JE NO_FINE
	CMP BL, '1'
	JB  INVALID_DAYS2
	CMP BL, '9'
	JA  INVALID_DAYS2
	
	; === Calculation (1 Day RM 3) ===
	SUB BL, 30H             ; 使用 BL 计算
	MOV AL, BL
	MOV CL, 3
	MUL CL
	MOV BL, AL              ; 结果存在 BL (罚款费)
	
	; === Check value enough to process ===
	CMP MemberBalance, BL
	JB INSUFFICIENT_BAL_RET

	; === Update Data ===
	SUB MemberBalance, BL
	ADD TotalFine, BL 

	; === Display Form ===
	MOV AH, 09H
	LEA DX, msgFinePaid
	INT 21H

	; Dispaly Detail
	MOV AL, BL
	CALL PRINT_NUM

	JMP SHOW_CURRENT_BAL

NO_FINE:
	MOV AH, 09H
	LEA DX, msgReturnSuccess
	INT 21H
	JMP END_RETURN

SHOW_CURRENT_BAL:
	CALL PRINT_BALANCE

END_RETURN:
	CALL WAIT_KEY
	RET                     ; 成功退出

INVALID_DAYS2:
	MOV RETURN_STATUS, 1
	JMP RETURN_START
	
INSUFFICIENT_BAL_RET:
	MOV RETURN_STATUS, 2
	JMP RETURN_START
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
	SUB BL, 30H
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
	SUB BL, 30H
	ADD CH, BL              ; CH = 真正充值的金额 (十位 + 个位)

	; === Value Checking (Carry) ===
	MOV AL, MemberBalance
	ADD AL, CH
	JC  OVERFLOW_TOPUP 

	; === Update Data ===
	MOV MemberBalance, AL
	ADD TotalRevenue, CH

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
	LEA DX, msgRepRev
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

; ==========================================================
; Allow Display 3 Number
; Put Number in AL, And Call
; ==========================================================
PRINT_NUM PROC
	;First Number Store In CH
	MOV AH, 0
	MOV BL, 100
	DIV BL
	MOV CH, AL

	;Second Number Store In CL, And Last Number Store In DH
	MOV AL, AH
	MOV AH, 0
	MOV BL, 10
	DIV BL
	MOV CL, AL
	MOV DH, AH

	;Print
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
    LEA SI, MemberID_INPUT
    MOV CX, 5
READ_U:
    MOV AH, 01H
    INT 21H
    MOV [SI], AL
    INC SI
    LOOP READ_U
    RET
READ_USERNAME ENDP
	
READ_PASSWORD PROC
    LEA SI, Password_INPUT
    MOV CX, 5
READ_P:
    MOV AH, 01H
    INT 21H
    MOV [SI], AL
    INC SI
    LOOP READ_P
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

END MAIN