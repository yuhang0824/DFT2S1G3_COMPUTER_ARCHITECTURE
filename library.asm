.MODEL SMALL
.STACK 100
.DATA
	
	msgPromtSelectPage DB 13,10,"1.Login",13,10,"2.Exit",13,10,"Enter number to choice: $"
	msgPromtMemberID DB 13,10,"MemberID(M0000): $"
	msgPromtPassword DB 13,10,"Password(5 Digit): $"
	
	ERRORMSG1 DB 13,10,"WRONG Choice $"
	ERRORMSG2 DB 13,10,"WRONG ID $"
	ERRORMSG3 DB 13,10,"WRONG PASSWORD $"
	ERRORMSG4 DB 13,10,"Too many wrong attempts! Returning to Menu.$"
	
	RETRY_COUNT DB 3  ; 专属的重试计数器
	
	MemberID_INPUT DB 5 DUP(?) ;member input
	Password_INPUT DB 5 DUP(?) ;member input
	
	MemberID_FILE DB 5 DUP(?) ;file data
	Password_FILE DB 5 DUP(?) ;file data
	
	CHOICE DB ? ;member choice
	
	buffer DB 5120 DUP(?)       ; 预留 100 个字节的空白房间来装数据
	
	msgReport DB 13,10,13,10,'===== STUDENT RESULT REPORT =====$'
	msgMemberID DB 13,10,	'Member ID    : $'
	msgBookID DB 13,10,		'Book ID      : $'
	msgMemberPoint DB 13,10,'Member Point : $'
	msgAvg DB 13,10,		'Average      : $'
	msgGrade DB 13,10,		'Grade        : $'
		
	fileName DB 'account.txt', 0		;save file name
    logMsg DB 'M0001,12345', 13, 10		;first time use will create basic data
    msgLen DW 11						;logMsg how long
    fileHandle DW ?						;when using file service need handle the file key
	
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

SCAN_LOOP_ID:            ; [修复] 重命名标签避免重复
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
    JMP LOGIN_ID_PAGE      ; [修复] 修正标签名为 LOGIN_ID_PAGE

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
	LEA DX,msgReport
	INT 21H
	
FIN:
    MOV AX, 4C00H
    INT 21H
	
MAIN ENDP

;==========================================================
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
    LEA SI, Password_INPUT ; [致命修复] 之前错写成了 MemberID_INPUT！
    MOV CX, 5
READ_P:                  ; [修复] 标签不能和上面的 READ_U 重复
    MOV AH, 01H
    INT 21H
    MOV [SI], AL
    INC SI
    LOOP READ_P
    RET
READ_PASSWORD ENDP

END MAIN