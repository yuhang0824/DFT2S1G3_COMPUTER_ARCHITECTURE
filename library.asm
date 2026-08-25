.MODEL SMALL
.STACK 100
.DATA
	;==================================================================================================================
	msgPromtSelectPage DB 13,10
		DB '=======================================',13,10
		DB '1. Login',13,10
		DB '2. Exit',13,10
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
		DB '6. Exit System',13,10                   ; 彻底退出
		DB '=======================================',13,10
		DB 'Please enter your choice (1-6): $'
		
	CHOICE DB ?
	
	;==================================================================================================================
	
	TotalBooks 	 DB 5     ; 记录今天总共借出的书数量 (初始为0)
	TotalRevenue DB 10     ; 记录今天总共收取的金额 (初始为0)

	msgRepTitle DB 13,10,"===== DAILY SUMMARY REPORT =====$"
	msgRepBooks DB 13,10,"Total Books Borrowed : $"
	msgRepRev   DB 13,10,"Total Revenue (RM)   : $"
	msgRepLine  DB 13,10,"================================$"
	
	;================================================= Promt ==========================================================

	msgPromtMemberID DB 13,10,"MemberID(M0000): $"
	msgPromtPassword DB 13,10,"Password(5 Digit): $"

	;================================================= Error msg ======================================================

	ERRORMSG1 DB 13,10,'WRONG Choice $'
	ERRORMSG2 DB 13,10,'WRONG ID $'
	ERRORMSG3 DB 13,10,'WRONG PASSWORD $'
	ERRORMSG4 DB 13,10,'Too many wrong attempts! Returning to Menu.$'
	
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
	SPACE DB " $"
	NL DB 10,13,'$'
	TEN DB 10
	HUNDRED DB 100
	
.CODE
MAIN PROC
	MOV AX, @DATA
	MOV DS,AX
	
SELECT_PAGE:
	MOV AH,09H
	LEA DX,msgPromtSelectPage
	INT 21H
	
	MOV AH,01H
	INT 21H
	MOV CHOICE,AL
	
	;NEW LINE
	MOV AH,09H
	LEA DX,NL
	INT 21H
	
	CMP CHOICE,"1"
	JE PREPARE_LOGIN  
	
	CMP CHOICE, '2'
	JNE WRONG_CHOICE
	JMP FIN

WRONG_CHOICE:
	MOV AH,09H
	LEA DX,ERRORMSG1
	INT 21H
	JMP SELECT_PAGE
		
PREPARE_LOGIN:
	MOV RETRY_COUNT, 3    ; 每次从菜单进入登录时，都把机会重置为 3 次
	;continue and direct go LOGIN_ID_PAGE
	
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
	MOV AH,09H
	LEA DX,msgPromtSelectFunction
	INT 21H
	
	MOV AH,01H
	INT 21H
	MOV CHOICE,AL
	
	;NEW LINE
	MOV AH,09H
	LEA DX,NL
	INT 21H
	
	CALL PRINT_REPORT
		
	JMP FIN
	
;================================================= END ================================================================
FIN:
    MOV AX, 4C00H
    INT 21H

MAIN ENDP
; ==========================================================
; [模块] 读取5个input
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
; [模块 4] Daily Summary Report
; ==========================================================
PRINT_REPORT PROC
	; 1. 打印报表抬头
	MOV AH, 09H
	LEA DX, msgRepTitle
	INT 21H

	; 2. 打印 "Total Books Borrowed : "
	LEA DX, msgRepBooks
	INT 21H

	; --- 提取并打印 TotalBooks 的数字 ---
	MOV AL, TotalBooks    ; 把当天的总借书量放进 AL
	AAM                   ; 【神仙指令】自动把 AL 里的数字除以 10。商(十位)放在 AH，余数(个位)放在 AL！
	ADD AX, 3030H         ; 把 AH 和 AL 里的数字同时加上 30H，转换成 ASCII 字符
	MOV BX, AX            ; 把转好的字符备份到 BX (BH 是十位，BL 是个位)

	; 打印十位
	MOV AH, 02H           ; 呼叫单字符打印服务
	MOV DL, BH
	INT 21H
	
	; 打印个位
	MOV DL, BL
	INT 21H

	; 3. 打印 "Total Revenue ($) : "
	MOV AH, 09H
	LEA DX, msgRepRev
	INT 21H

	; --- 提取并打印 TotalRevenue 的数字 ---
	MOV AL, TotalRevenue  ; 把当天的总收入放进 AL
	AAM                   ; 再次拆分十位和个位
	ADD AX, 3030H         
	MOV BX, AX            

	; 打印十位
	MOV AH, 02H
	MOV DL, BH
	INT 21H
	; 打印个位
	MOV DL, BL
	INT 21H

	; 4. 打印底部封口线
	MOV AH, 09H
	LEA DX, msgRepLine
	INT 21H
	
	RET                   ; 子程序结束，返回主菜单
PRINT_REPORT ENDP

END MAIN