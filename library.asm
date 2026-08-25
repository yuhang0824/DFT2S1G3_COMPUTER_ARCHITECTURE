.MODEL SMALL
.STACK 100
.DATA
	;==================================================================================================================
	msgPromtSelectPage DB 13,10
		DB '=======================================',13,10
		DB '1. Login',13,10
		DB '0. Exit',13,10
		DB '=======================================',13,10
		DB 'Enter number to choose: $'
	
	;==================================================================================================================
	
	msgPromtSelectFunction DB 13,10
		DB '=======================================',13,10
		DB '       WELCOME TO LIBRARY SYSTEM       ',13,10
		DB '=======================================',13,10
		DB '1. Borrow Book',13,10                   ; 借书
		DB '2. Return Book / Pay Fine',13,10        ; 还书与罚款
		DB '3. Member Top-up',13,10                 ; 会员充值
		DB '4. Daily Summary Report',13,10          ; 今日营业报表
		DB '5. Logout',13,10                        ; 登出返回上一层
		DB '0. Exit System',13,10                   ; 彻底退出
		DB '=======================================',13,10
		DB 'Please enter your choice (1-5): $'
		
	CHOICE DB ?
	
	;==================================================================================================================
	
	TotalBooks 	  DB 0     ; 记录今天总共借出的书数量 (初始为0)
	TotalFine     DB 0     ; 今日逾期收取的总罚款 (初始为0)
	TotalRevenue  DB 0     ; 记录今天总共收取的金额 (初始为0)
	MemberBalance DB 50    ; 当前会员余额 (暂时预设为50，方便测试，后续可做文件读取)

	msgRepTitle DB 13,10,13,10,13,10,'===== DAILY SUMMARY REPORT =====$'
	msgRepBooks DB 13,10,'Total Books Borrowed : $'
	msgRepFine  DB 13,10,'Total Fine (RM)      : $'
	msgRepRev   DB 13,10,'Total Revenue (RM)   : $'
	msgRepLine  DB 13,10,'================================$'
	
	;================================================= Promt ==========================================================

	msgPromtMemberID DB 13,10,'MemberID(M0000): $'
	msgPromtPassword DB 13,10,'Password(5 Digit): $'
	msgPromtOverdue  DB 13,10,'Enter overdue days (0-9): $'
	msgPromtDays 	 DB 13,10,'Enter borrow days (1-9): $'
	msgPromtTopup    DB 13,10,'Enter Top-up amount RM (01-99): $'
	msgReceiptEnd 	 DB 13,10,'Thank you!$'
	msgInvalidNum 	 DB 13,10,'Invalid input! Only numbers 0-9 allowed.$'
	msgOverflow   	 DB 13,10,'Exceeds maximum limit (RM 255)!$'
	
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
					 
	;================================================= Error msg ======================================================

	ERRORMSG1 DB 13,10,'WRONG Choice $'
	ERRORMSG2 DB 13,10,'WRONG ID $'
	ERRORMSG3 DB 13,10,'WRONG PASSWORD $'
	ERRORMSG4 DB 13,10,'Too many wrong attempts! Returning to Menu.$'
	ERRORMSG5 DB 13,10,"Invalid input! Must be 1 to 9.$"
	
	;================================================= Input Variable =================================================

	MemberID_INPUT DB 5 DUP(?)
	Password_INPUT DB 5 DUP(?)
	
	;================================================= File Variable ==================================================
	
	MemberID_FILE DB 5 DUP(?) ;file data
	Password_FILE DB 5 DUP(?) ;file data
	
	buffer DB 5120 DUP(?)       ; 预留 100 个字节的空白房间来装数据
	
	fileName DB 'account.txt', 0		;save file name
    logMsg DB 'M0001,12345', 13, 10		;first time use will create basic data
    msgLen DW 11						;logMsg how long
    fileHandle DW ?						;when using file service need handle the file key
	
	;================================================= Other Variable =================================================
	RETRY_COUNT DB 3
	; 0=Normal, 1=Input Invalid, 2=can't process
	CHOICE_STATUS DB 0
	BORROW_STATUS DB 0 
	RETURN_STATUS DB 0
	TOPUP_STATUS  DB 0
	
	NL DB 10,13,'$'
	
.CODE
MAIN PROC
	MOV AX, @DATA
	MOV DS,AX
	
SELECT_PAGE:
	CALL CLEAR_SCREEN
	
	CMP CHOICE_STATUS,1
	JE  DISPLAY_ERROR
	JMP SHOW_MENU

DISPLAY_ERROR:
	MOV AH, 09H
	LEA DX, ERRORMSG1
	INT 21H
	MOV CHOICE_STATUS,0   

SHOW_MENU:
	MOV AH, 09H
	LEA DX, msgPromtSelectPage
	INT 21H
	
	MOV AH, 01H
	INT 21H
	MOV CHOICE, AL
	
	; NEW LINE
	MOV AH, 09H
	LEA DX, NL
	INT 21H
	
	CMP CHOICE, "1"
	JE PREPARE_LOGIN  
	
	CMP CHOICE, '0'
	JNE WRONG_CHOICE
	JMP FIN

WRONG_CHOICE:
	MOV CHOICE_STATUS, 1   ; 把错误状态标记为 1
	JMP SELECT_PAGE         ; 重新循环回页面顶部（触发清屏并准备报错）

PREPARE_LOGIN:
	CALL CLEAR_SCREEN
	MOV RETRY_COUNT, 3    ; 每次从菜单进入登录时，都把机会重置为 3 次
	
LOGIN_ID_PAGE:
	MOV AH,09H
	LEA DX,msgPromtMemberID
	INT 21H
	CALL READ_USERNAME

    ; ===== 1. 打开文件 =====
    MOV AH, 3DH
    MOV AL, 0
    LEA DX, fileName
    INT 21H
    JC ERROR_OPEN
    MOV fileHandle, AX

    ; ===== 2. 读取文件 =====
    MOV AH, 3FH
    MOV BX, fileHandle
    MOV CX, 100         ; 读 100 个字够了
    LEA DX, buffer
    INT 21H

    ; ===== 3. 处理读取到的内容 =====
    ; 此时 AX 是读取到的真实长度
    LEA SI, buffer
    ADD SI, AX
    MOV BYTE PTR [SI], '$' ; 封口
	
    ; ===== 4. 关闭文件 =====
    MOV AH, 3EH
    MOV BX, fileHandle
    INT 21H

    ; ===== 5. 提取逗号前的 ID =====
    LEA SI, buffer
    LEA DI, MemberID_FILE
    MOV CX, 100          ; 设定最大扫描限制

SCAN_LOOP_ID:
    MOV AL, [SI]
    CMP AL, ','
    JE  COMMA_FOUND_ID
    CMP AL, '$'
    JE  END_OF_DATA1
    
    MOV [DI], AL
    INC DI
    INC SI
    LOOP SCAN_LOOP_ID

COMMA_FOUND_ID:
    MOV BYTE PTR [DI], '$'
    JMP END_OF_DATA1      ; 提取成功，跳去比对环节

ERROR_OPEN:
    ; (如果文件不存在，就在这里创建它)
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

END_OF_DATA1:
    ; 5 个字母连续对比 ID
    LEA SI, MemberID_INPUT
    LEA DI, MemberID_FILE
    MOV CX, 5            ; 循环 5 次对比 5 个字母

COMPARE_LOOP1:
    MOV AL, [SI]
    CMP AL, [DI]
    JNE ACCOUNT_WRONG    ; 只要有一个字母错，立刻跳去报错！
    
    INC SI
    INC DI
    LOOP COMPARE_LOOP1

    ; 全对！跳去密码页面
	MOV RETRY_COUNT, 3 ;REFRESH
	JMP LOGIN_PASSWORD_PAGE

ACCOUNT_WRONG:
	DEC RETRY_COUNT      ; 机会减 1
	CMP RETRY_COUNT, 0   ; 检查机会是不是变成 0 了？
	JE  TOO_MANY_TRIES   ; 如果是 0，跳去惩罚区

    MOV AH, 09H
    LEA DX, ERRORMSG2
    INT 21H
    JMP LOGIN_ID_PAGE


;================================================= PASSWORD =================================================
LOGIN_PASSWORD_PAGE:
	MOV AH,09H
	LEA DX,msgPromtPassword
	INT 21H
	CALL READ_PASSWORD

    ; ===== 提取逗号后的 Password =====
    LEA SI, buffer
    LEA DI, Password_FILE
    MOV CX, 100          ; 设定最大扫描限制

SCAN_LOOP_PASS:
    MOV AL, [SI]
	CMP AL,','
	JE SAVE_READY
    INC SI
    LOOP SCAN_LOOP_PASS  ; 一直找，直到找到逗号
	
SAVE_READY:
    INC SI
	MOV CX,5
	
SAVE_PASS:
    MOV AL, [SI]
    MOV [DI], AL
    INC DI
    INC SI
    LOOP SAVE_PASS

    MOV BYTE PTR [DI], '$'
    JMP END_OF_DATA2      
    
END_OF_DATA2:
   
    LEA SI, Password_INPUT
    LEA DI, Password_FILE
    MOV CX, 5            ; 循环 5 次对比 5 个字母

COMPARE_LOOP2:
    MOV AL, [SI]
    CMP AL, [DI]
    JNE PASSWORD_WRONG   ; 只要有一个字母错，立刻跳去报错！
    
    INC SI
    INC DI
    LOOP COMPARE_LOOP2
	
    ; === 密码也全对！程序成功登录，跳转到结束或者报表区 ===
    JMP MAIN_MENU 

PASSWORD_WRONG:
	DEC RETRY_COUNT      ; 机会减 1
	CMP RETRY_COUNT, 0   ; 检查机会是不是变成 0 了？
	JE  TOO_MANY_TRIES   ; 如果是 0，跳去惩罚区

    MOV AH, 09H
    LEA DX, ERRORMSG3    ; (可以用不同的报错信息)
    INT 21H
    JMP LOGIN_PASSWORD_PAGE  ; 密码错了重新输入密码

TOO_MANY_TRIES:
	; 机会用尽，打印提示并踢回主菜单
	MOV AH, 09H
	LEA DX, ERRORMSG4
	INT 21H
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
	CMP BL, '0'             ; 使用 BL 验证
	JE Exit_BORROW_BOOK
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