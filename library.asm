.MODEL SMALL
.STACK 100
.DATA
	
	msgPromtSelectPage DB 13,10,"1.Login",13,10,"2.Exit",13,10,"Enter number to choice: $"
	msgPromtMemberID DB 13,10,"MemberID(M0000): $"
	
	MemberID_INPUT DB 5 DUP(?)
	Password_INPUT DB 5 DUP(?)
	
	MemberID_FILE DB 5 DUP(?)
	Password_FILE DB 5 DUP(?)
	
	CHOICE DB ?
	
    fileName DB 'account.txt', 0
    logMsg DB 'M0001,12345', 13, 10
    msgLen DW 9
    fileHandle DW ?
	
	buffer DB 5120 DUP(?)       ; 预留 100 个字节的空白房间来装数据
	
	msgReport DB 13,10,13,10,'===== STUDENT RESULT REPORT =====$'
	msgMemberID DB 13,10,	'Member ID    : $'
	msgBookID DB 13,10,		'Book ID      : $'
	msgMemberPoint DB 13,10,'Member Point : $'
	msgAvg DB 13,10,		'Average      : $'
	msgGrade DB 13,10,		'Grade        : $'
		
	ERRORMSG1 DB 13,10,"WRONG ID $"
	ERRORMSG2 DB 13,10,"WRONG Choice $"
	ERRORMSG3 DB 13,10,"Too many wrong attempts! Returning to Menu.$"
	RETRY_COUNT DB 3  ; 专属的重试计数器
	
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
	JE PREPARE_LOGIN  ; [修改 1] 不要直接跳去 LOGIN，先去初始化计数器！
	
	CMP CHOICE, '2'
	JNE WRONG_CHOICE
	JMP FIN

WRONG_CHOICE:
	MOV AH,09H
	LEA DX,ERRORMSG2
	INT 21H
	JMP SELECT_PAGE
		
PREPARE_LOGIN:
	MOV RETRY_COUNT, 3    ; 每次从菜单进入登录时，都把机会重置为 3 次
	
LOGIN_PAGE:
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

SCAN_LOOP:
    MOV AL, [SI]
    CMP AL, ','
    JE  COMMA_FOUND
    CMP AL, '$'
    JE  END_OF_DATA
    
    MOV [DI], AL
    INC DI
    INC SI
    LOOP SCAN_LOOP

COMMA_FOUND:
    MOV BYTE PTR [DI], '$'
    JMP END_OF_DATA      ; 提取成功，跳去比对环节

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
    JMP LOGIN_PAGE       ; 创建完返回重新登录

END_OF_DATA:
    ; [修正] 5 个字母连续对比
    LEA SI, MemberID_INPUT
    LEA DI, MemberID_FILE
    MOV CX, 5            ; 循环 5 次对比 5 个字母

COMPARE_LOOP:
    MOV AL, [SI]
    CMP AL, [DI]
    JNE ACCOUNT_WRONG    ; 只要有一个字母错，立刻跳去报错！
    
    INC SI
    INC DI
    LOOP COMPARE_LOOP

    ; [修正] 如果代码能走到这里（没有跳去 ACCOUNT_WRONG），说明全对！
    ; 打印成功信息！
    MOV AH, 09H
    LEA DX, msgReport    ; 这里借用你的报表头假装登录成功界面
    INT 21H
    JMP FIN              ; 成功后跳去程序结束 (或者可以跳去你的 Main Menu)

ACCOUNT_WRONG:
	DEC RETRY_COUNT      ; 机会减 1
	CMP RETRY_COUNT, 0   ; 检查机会是不是变成 0 了？
	JE  TOO_MANY_TRIES   ; 如果是 0，跳去惩罚区

	; 如果还没到 0，正常报错，并重新跳回 LOGIN_PAGE
    MOV AH, 09H
    LEA DX, ERRORMSG1
    INT 21H
    JMP LOGIN_PAGE       ; 报错后返回重新登录

TOO_MANY_TRIES:
	; 机会用尽，打印提示并踢回主菜单
	MOV AH, 09H
	LEA DX, ERRORMSG3
	INT 21H
	JMP SELECT_PAGE
	
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
	
END MAIN