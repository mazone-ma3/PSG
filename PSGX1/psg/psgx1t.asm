;===========================================
;	PSG(AY-3-8910) MUSIC PLAYER
;	(X1turbo VERSION) 2024/8/26- m@3
;	VERSION 1.00
;
;	SSG３音出力の組み込み用BGMドライバ
;	テンポずれ修正＋フェードアウト付き
;
;	演奏データは専用のコンパイラで
;	ＭＭＬから生成します
;
;	コメントは後から付けたものです
;===========================================
;-------------------------------------------
; ＜データ型式＞
; 0CAFFH番地から0番地の方向に入っていく
; 各演奏コマンドは数値で指示(可変長)
; 
; ＜コマンド一覧＞
; 0-96       音(音長n、nは60/n秒間)、0は休符
; 128-224,n  音(音長指定無し)、128は休符
; 225,m,n    SOUND m,n
; 226,n      VOLUME=n、n=16ならエンベローブ
; 227,n      LENGTH=n、0-96のコマンドの音長
; 254        全てのパートの同期を取る
; 255        ダ・カーポ
;-------------------------------------------
; 一部参考 NRTDRV、試験に出るX1

;	ASEG

;WRTPSG	EQU	0093H		; ＰＳＧに出力するBIOSルーチン

PSGDATA	EQU	(0DB3EH-01000H)		; ＰＳＧ音階出力値格納番地
MBOOT	EQU	(0DB00H-01000H) 		; 曲演奏データ先頭番地の格納アドレス
;MDATA	EQU	0DBFFH		; 演奏データ（0番地に向かって格納する）
;HOOK	EQU	0FD9FH		; システムの1/60秒割り込みフック
;INT3	EQU	0F308H
PARTSUU	EQU	3		; 演奏する最大パート数
FEEDTIME EQU	12		; フェードアウトレベル

;	ORG	0DC00H		; プログラムの開始番地(BASICからUSR関数で実行)
;	ORG	0B000H
	ORG	0CC00H
	JP	INIT
	JP	STOP
	JP	FEEDO
PARA:
	DB	0,0
PARA2:
	DB	0
PARA3:
	DB	00111000B
PARA4:
	DB	200	; CTC Ch.0
PARA5:
	DB	21	; CTC Ch.3

;-------------------------------------------
;	初期設定ルーチン
;-------------------------------------------
INIT:
	LD	A,(PARA2)
	LD	E,A
	LD	A,6
	CALL	WRTPSG
	LD	A,(PARA3)
	LD	E,A
	LD	A,7
	CALL	WRTPSG

;//		write_psg(6,127);
;	LD	A,6
;	LD	E,127
;	CALL	WRTPSG
;//		write_psg(11,0);
;	LD	A,11
;	LD	E,0
;	CALL	WRTPSG
;//		write_psg(12,15);
;	LD	A,12
;	LD	E,15
;	CALL	WRTPSG
;//		write_psg(7,0x9c);  // 10011100
;	LD	A,7
;	LD	E,9CH
;	CALL	WRTPSG
;//		write_psg(13,9);
;	LD	A,13
;	LD	E,9
;	CALL	WRTPSG
;//		write_psg(10,0x10);
;	LD	A,10
;	LD	E,10H
;	CALL	WRTPSG

;	RET

;	LD	HL,(0F7F8H)	; BASICからの引数をロード（整数のみ）
	LD	HL,(PARA)

	XOR	A		; Ａレジスタを０にする
	LD	(FEEDVOL),A	; フェードアウト音量をクリアする
	LD	(STOPPARTS),A	; 演奏停止パート情報をクリアする
	LD	(ENDFRG),A	; 演奏終了フラグをクリアする

	LD	A,L		; 引数の下位8bitは曲番号データ
	INC	A
	LD	(NSAVE),A	; 曲番号をワークエリアに格納する

;	JP	Z,STOP		; 曲番号が255(-1)なら演奏停止
;	INC	A		; CP 254の代わり
;	JP	Z,FEEDO		; 254(-2)ならフェードアウト

	DI
	PUSH	HL
	LD	A,H		; 引数の上位8bitは演奏回数情報
	LD	(LOOPTIME),A	; 演奏回数をセット(0〜255、0で無限ループ)
	CALL	PSGOFF		; PSGをオフ(BIOS)

;	LD	DE,HOOKWRK	; システムの割り込みをチェーンするアドレス
;	LD	A,(DE)
;	OR	A		; 0かどうか調べる
;	JR	NZ,NOSAVE	; 既に常駐しているなら再常駐しない
;	LD	BC,5		; LDIR命令の転送バイト数
;	LD	HL,HOOK		; システムの1/60秒割り込みベクタ（転送元）
;	LDIR			; ベクタの内容をセーブする

;NOSAVE:
	POP	HL

	SLA	L
	SLA	L
	SLA	L		; 8倍する
	LD	C,L
	LD	B,0		; BCに曲番号のオフセット値を作成

	LD	HL,MBOOT	; 曲演奏情報の先頭アドレス
	ADD	HL,BC		; 曲番号のアドレスをセットする

	LD	B,PARTSUU	; 演奏パート数をセット

INILP:	XOR	A		; ループ開始
	PUSH	BC
	LD	C,B
	DEC	C
	LD	B,A		; BCにパート毎のオフセット値を作成

	LD	E,(HL)
	INC	HL
	LD	D,(HL)		; 曲データ開始アドレスを取得
	INC	HL
	PUSH	HL

	CP	D

	JR	NZ,PASS1	; 開始アドレスが0以外なら分岐する

	CALL	SYNCFGON	; 
	DEC	A		; Aを２５５（−１）にする（非演奏パート）

	JR	PASS2

PASS1:
;--
	LD	HL,0F000H	;-01000H
	ADD	HL,DE

;	HALT
;	PUSH	HL
;	POP	DE
	LD	D,H
	LD	E,L

;--
PASS2:

	LD	HL,MAXVOL	; 最大ボリュームのワークアドレス
	ADD	HL,BC		; 格納番地確定
	LD	(HL),A		; 最大ボリュームを255にする

	LD	HL,COUNT	; 演奏カウントのワークアドレス
	ADD	HL,BC		; 格納番地確定
	LD	(HL),1		; 演奏カウントを1にする

	LD	HL,STOPFRG	; 演奏停止フラグのワークアドレス
	ADD	HL,BC		; 格納番地確定
	LD	(HL),A		; 演奏停止フラグを２５５（−１）にする

	LD	HL,STARTADR	; 演奏開始するアドレスの格納番地
	ADD	HL,BC		; 曲番号に対応した格納番地を作成
	ADD	HL,BC		; (オフセット値はBCの２倍)

	LD	(HL),E		; 演奏開始アドレスをワークエリアにコピー
	INC	HL
	LD	(HL),D



	LD	HL,OFFSET	; 演奏中アドレスの格納番地
	ADD	HL,BC		; 格納番地を作成
	ADD	HL,BC		; (オフセット２倍)

	LD	(HL),E		; 同様にコピーする
	INC	HL
	LD	(HL),D

	POP	HL		; (曲演奏情報の先頭アドレスを復帰)
	POP	BC		; (ループカウンタを復帰)
	DJNZ	INILP		; パート数ぶん繰り返す

;	LD	A,I			; システムの割り込みベクタ(EE00H)
;	LD	A,EE
;	LD	H,A
;	LD	L,0C0H+8

;	LD	H,0EEH
	LD	A,(2)
	LD	H,A			; システムワークの上位アドレス

	LD	L,0C0H+6	; CTC Ch.3 割り込みベクタ

	LD	DE,PLAYLOOP
	LD	(HL),E		; 開始アドレス下位をベクタにセットする
	INC	HL
	LD	(HL),D		; 開始アドレス上位ベクタにセットする

	PUSH	BC

	LD	A,3
	LD	L,08CH
;	LD	BC,(0EE8CH)	; 01FA0H	;	CTC Work
	LD	C,(HL)					;	CTC Work
	INC	HL
	LD	B,(HL)					;	CTC Work
	DEC	BC
	DEC	BC

	OUT	(C),A	;	CTC Ch.0 Reset
	INC	BC
	INC	BC
	INC	BC
;	LD	BC,01FA3H
	OUT	(C),A	;	CTC Ch.3 Reset

	DEC	BC
	DEC	BC
	DEC	BC
;	LD	BC,01FA0H	;	CTC Ch.0 Set
	LD	A,0111B
	OUT	(C),A
	LD	A,(PARA4)	; 200
	OUT	(C),A

;	LD	A,58H
;	OUT	(C),A

	INC	BC
	INC	BC
	INC	BC
;	LD	BC,01FA3H	;	CTC Ch.3 Set
	LD	A,011000111B
	OUT	(C),A
	LD	A,(PARA5)	; 22
	OUT	(C),A

	POP	BC

;	HALT

END:
	EI
	RET			; 終了してシステムに戻る

;-------------------------------------------
;	フェードアウトルーチン
;-------------------------------------------

FEEDO:	LD	A,1		; 
	LD	(FEEDVOL),A	; フェードアウトボリュームを１にする
	LD	(FCOUNT),A	; フェードアウトカウンタを１にする

	LD	B,PARTSUU	; ループカウンタをパート数にセットする

FEEDLOOP:
	PUSH	BC

	LD	HL,MAXVOL	; ボリューム格納アドレスの先頭番地
	LD	C,B		; 
	DEC	C		; パート数をオフセットにする
	LD	B,0		; 
	ADD	HL,BC		; アドレスを生成する

	LD	A,(HL)		; フェードアウトボリュームを取得
	INC	A
	JR	Z,NOFELFO	; ボリュームが０なら何もしない

	CP	16+1
	JR	C,NOFELFO	; ボリュームが15以下なら何もしない

	LD	A,15
	LD	(HL),A		; ボリュームを15（最大値）にする

NOFELFO:POP	BC
	DJNZ	FEEDLOOP

	RET

;-------------------------------------------
;	演奏停止ルーチン
;-------------------------------------------

STOP:
	LD	A,(2)
	LD	H,A			; システムワークの上位アドレス

	LD	L,08CH
	LD	C,(HL)
	INC	HL
	LD	B,(HL)
;	LD	BC,(0EE8CH)	; 01FA0H	;	CTC Work

	INC	BC
;	LD	BC,01FA3H
	LD	A,3
	OUT	(C),A	;	CTC Ch.3 Reset

;	LD	HL,HOOKWRK	; フックの退避アドレス
;	XOR	A
;	CP	(HL)		; まだ常駐していなければ終了する
;	RET	Z
;	LD	DE,HOOK		; 1/60秒割り込みのベクタアドレス
;	LD	BC,5
;	PUSH	HL

;	EI

;	POP	HL
;	LD	(HL),A		; ０を格納する

PSGOFF:	LD	HL,MAXVOL	; ボリューム値の格納アドレス
	LD	B,PARTSUU	; ループカウンタにパート数を設定

OFFLP:	LD	A,(HL)
	INC	A
	JR	Z,OFLPED	; ボリュームが２５５（−１）ならループ終了

	LD	A,11		; ＰＳＧのボリュームレジスタの値
	SUB	B		; パートに対応する出力レジスタを設定
	LD	E,0		; 音量を０にする
	CALL	WRTPSG		; ＰＳＧに音量０を出力する(BIOS)
	INC	HL		; 次のパートのボリューム値格納アドレスへ

OFLPED:	DJNZ	OFFLP		; ループする

	RET

;-------------------------------------------
;	フェードアウトサブルーチン
;-------------------------------------------

FEEDSUB:LD	HL,FCOUNT	; フェードアウトカウンタをセット
	DEC	(HL)
	RET	NZ		; 処理を間引く
	LD	(HL),FEEDTIME	; カウンタを初期化

	LD	HL,FEEDVOL	; フェードアウト音量の格納番地
	INC	(HL)		; １レベル上げる

	LD	HL,MAXVOL
	ADD	HL,BC
	LD	A,(HL)
	INC	A
	RET	Z		; 既に２５５（−１）なら終了

	CP	16
	CALL	C,PUTVOL	; 15以下ならボリュームを出力する
	RET

;-------------------------------------------
;	演奏ルーチン、割り込みで呼ばれる
;-------------------------------------------

;DO_RETI:
;	RETI

PLAYLOOP:
;	CALL	DO_RETI
;	DI
	PUSH	AF
	PUSH	HL
	PUSH	DE
	PUSH	BC
;	PUSH	IX
;	PUSH	IY
;	EX	AF,AF'
;	PUSH	AF


PLAYLOOP2:
	LD	A,(FEEDVOL)	; フェードアウトレベルを調べる
	CP	15
;	JR	Z,STOP		; フェードアウト終了なら演奏を停止する
	JR	Z,HOOKWRK2		; フェードアウト終了なら演奏を停止する
	OR	A
	CALL	NZ,FEEDSUB	; フェードアウトする

	LD	B,PARTSUU	; ループカウンタをパート数にする

COUNTER:
	PUSH	BC

	LD	C,B
	DEC	C
	LD	B,0		; オフセットをループカウンタ-1とする

	LD	HL,STOPFRG	; 演奏状態ステータスのアドレスをセット
	ADD	HL,BC
	LD	A,(HL)		; そのパートの演奏状態を調べる
	CP	254		; 同期待ち中または演奏終了か判断する
	JR	NC,LOOPEND	; 演奏処理をスキップする

	LD	HL,COUNT	; 音長カウンタの先頭アドレス
	ADD	HL,BC		; パート毎のアドレスにする
	DEC	(HL)		; 音長カウンタから1を引く
	CALL	Z,PING		; カウンタが0なら演奏処理をする

LOOPEND:
	POP	BC
	DJNZ	COUNTER		; ループする

	LD	B,PARTSUU	; 演奏しているパート数
	LD	A,(STOPPARTS)	; 演奏を停止したパート数
	CP	B		; 同じかどうか比較する
	JR	NZ,PSTOP	; 演奏を終了する

	LD	C,B
	LD	HL,STOPFRG	; 演奏状態ステータスのアドレス
	LD	DE,COUNT	; 音長カウンタの先頭アドレス

LPE:
	LD	A,(HL)		; 演奏ステータスを調べる
	INC	A
	JR	Z,LPNX		; 255(-1)なら演奏停止なので処理しない

	XOR	A
	LD	(HL),A		; 演奏ステータスを0（演奏中）とする
	INC	A
	LD	(DE),A		; 音長カウンタを1とする

	DEC	C		; 演奏停止パート数の計算をする

LPNX:
	INC	HL		; 次のパートの演奏状態ステータスのアドレス
	INC	DE
	DJNZ	LPE		; 次のパートを見る

	LD	A,C
	LD	(STOPPARTS),A	; 演奏停止パート数をセットする

	JR	PLAYLOOP2	; ループする

;-------------------------------------------
;	割り込みルーチンを終了する
;-------------------------------------------
PSTOP:	XOR	A
	LD	HL,ENDFRG	; 終了カウンタのアドレス
	DEC	(HL)		; 終了カウンタから1を引く
	LD	(HL),A		; 終了フラグに0をセット
	JR	NZ,HOOKWRK	; 終了カウンタが0なら割り込み終了

	LD	HL,LOOPTIME	; ループするべき回数を調べる
	OR	(HL)		; 0かどうか調べる

	JR	Z,HOOKWRK	; 0なら割り込み終了

	DEC	(HL)		; ループ回数から1を引く
	JR	NZ,PLAYLOOP	; 0ならループする

HOOKWRK2:
	CALL	STOP		; 演奏自己停止

HOOKWRK:
	DI
	LD	A,5
	OUT	(0E4H),A	;CUT INT 5-7
	
;	POP	AF
;	EX	AF,AF'
;	POP	IY
;	POP	IX
	POP	BC
	POP	DE
	POP	HL
	POP	AF
	
	EI

	RETI
	;DB	0,0C9H,0C9H,0C9H,0C9H	; 割り込みのチェーン

;-------------------------------------------
;	演奏処理ルーチン
;-------------------------------------------

PING:	LD	HL,OFFSET	; 演奏中データのアドレスを格納するアドレス
	ADD	HL,BC		; パート毎のアドレスをセット
	ADD	HL,BC

	LD	E,(HL)
	INC	HL
	LD	D,(HL)		; 演奏中のデータの現在の番地を生成

PINGPONG:LD	A,(DE)		; 実行するコマンドを調べる

	CP	225
	JP	C,PLAY		; 224以下なら演奏コマンド

	PUSH	HL

	DEC	DE;*		; 演奏番地を先にすすめる
	CALL	COMAND		; コマンド解析ルーチンを呼ぶ

	POP	HL

	DEC	DE;*		; 演奏番地を先にすすめる
	JR	PINGPONG	; ループする

;-------------------------------------------
;	演奏データ内コマンド解析ルーチン
;-------------------------------------------

COMAND:	CP	226
	JR	Z,CHNVOL	; コマンド226、音量変更(MMLのVコマンド)

	CP	227
	JR	Z,LEN		; コマンド227、標準音長変更(MMLのTコマンド)

	CP	225
	JR	Z,YCOM		; コマンド225、直接出力（MMLのYコマンド）

	INC	A
	JR	Z,D_C		; コマンド255、ループ

	INC	A
	RET	NZ		; コマンド254でなければコマンド解析終了

	CALL	SYNCON		; 同期コマンド
	PUSH	DE
	CALL	NOPUT		; 音の出力を停止する
	POP	DE

SUTETA:	POP	HL		; スタックから元のリターンアドレスを破棄する
	LD	A,1
	JP	LENG		; そのままメインループに戻る

;-------------------------------------------
;	各演奏パートの同期処理
;-------------------------------------------

SYNCON:	LD	HL,STOPFRG	; 演奏状態ステータスへのアドレス
	ADD	HL,BC		; パート毎のアドレスにする
	LD	(HL),254	; 演奏状態を254(-2)とする
	INC	DE;*		; 演奏アドレスに1を足しておく

SYNCFGON:LD	HL,STOPPARTS	; 演奏停止パート数の格納アドレス
	INC	(HL)		; 演奏停止パート数に1を足す
	RET

;-------------------------------------------
;	ボリューム変更処理
;-------------------------------------------

CHNVOL:	LD	A,(DE)		; 音量を取得する
	LD	HL,MAXVOL	; 音量の格納アドレス
	ADD	HL,BC		; パート毎のアドレスにする
	LD	(HL),A		; 音量を格納
	RET

;-------------------------------------------
;	標準音長設定処理
;-------------------------------------------

LEN:	LD	A,(DE)		; 標準音長を取得する
	LD	HL,LENGTH	; 標準音長の格納アドレス
	ADD	HL,BC		; パート毎のアドレスにする
	LD	(HL),A		; 標準音長を格納
	RET

;-------------------------------------------
;	ＰＳＧのレジスタに直接値を書く処理
;-------------------------------------------

YCOM:	LD	A,(DE)		; 出力するデータを得る
	LD	H,A		; 一旦別のレジスタに退避する
	DEC	DE;*		; 演奏番地を先にすすめる
	LD	A,(DE)		; 出力するデータを得る
	PUSH	DE
	LD	E,A
	LD	A,H
	CALL	WRTPSG		; PSG出力(BIOS)を呼び出す
	POP	DE

	RET

;-------------------------------------------
;	ダ・カーポ処理
;-------------------------------------------

D_C:
	LD	HL,STARTADR	; 演奏開始アドレスの格納アドレス
	ADD	HL,BC		; パート毎のアドレスにする
	ADD	HL,BC
	LD	E,(HL)
	INC	HL
	LD	D,(HL)		; 演奏開始アドレスを取得する

	INC	DE;*		; アドレスに1加算しておく

	LD	A,1
	LD	(ENDFRG),A	; 終了ステータスを1にする

	RET

;-------------------------------------------
;	PSGに音を出力する
;-------------------------------------------

PLAY:	PUSH	HL
	AND	01111111B	; 音調情報を削除
	CALL	PSGPUT		; PSGに音を出力する

	LD	A,(DE)
	AND	10000000B	; 音長が設定されているか調べる
	LD	HL,LENGTH
	ADD	HL,BC		; （Zフラグは影響を受けない）
	LD	A,(HL)		; 標準の音調を取得する
	JR	NZ,LENG		; 音調が設定されてないなら分岐

	DEC	DE;*		; 演奏アドレスをすすめる
	LD	A,(DE)		; 音長を取得する

LENG:	LD	HL,COUNT	; 音長カウンタのアドレス
	ADD	HL,BC		; パート数に対応したアドレスを生成
	LD	(HL),A		; 音長をセットする

	POP	HL

STCOUNT:DEC	DE;*		; 演奏アドレスをすすめる

	LD	(HL),D
	DEC	HL
	LD	(HL),E		; 演奏アドレスを記録する

	RET

;-------------------------------------------
;	ＰＳＧに音を出力するルーチン
;-------------------------------------------

PSGPUT:
	PUSH	DE
	PUSH	HL
	LD	HL,STOPFRG	; 演奏終了状態のアドレス
	ADD	HL,BC		; パート毎のアドレスにする
	LD	(HL),A

	SLA	A		; 2倍する
	LD	E,A
	LD	D,0		; オフセットアドレスの生成

	LD	HL,PSGDATA	; トーンの先頭格納番地
	ADD	HL,DE		; トーンの格納番地を生成

	LD	A,C
	SLA	A		; パートを2倍する(PSGの出力レジスタ)
	LD	E,(HL)		; 下位のトーンをセット
	CALL	WRTPSG		; PSGに下位トーンを出力(BIOS)

	INC	HL		; 上位のトーンの格納番地
	INC	A		; 出力先レジスタを1すすめる
	LD	E,(HL)		; 上位のトーンをセット
	CALL	WRTPSG		; PSGに上位トーンを出力(BIOS)

	CALL	PUTMVOL		; ボリュームの設定

	POP	HL
	POP	DE
	RET

;-------------------------------------------
;	ボリュームを設定するルーチン
;-------------------------------------------

PUTMVOL:LD	HL,STOPFRG	; 演奏状態ステータスのアドレス
	ADD	HL,BC		; パート毎のアドレスにする
	LD	A,(HL)		; 演奏状態を取得
	OR	A		; 0かどうか調べる
	JR	Z,PUTVOL	; 演奏停止中ならボリュームを0とする

	LD	HL,MAXVOL	; 設定したボリュームを得る
	ADD	HL,BC		; パート毎のアドレスにする
	LD	A,(HL)		; ボリュームを設定

PUTVOL:	CP	16		; エンベローブかどうか調べる
	CALL	NC,PUTENV	; 処理を分岐する

	LD	E,A
	LD	A,(FEEDVOL)	; フェードアウトレベルを得る
	LD	D,A
	LD	A,E
	SUB	D		; 音量からフェードアウトレベルを引く
	JR	NC,YESPUT	; 音量が0以上なら分岐

NOPUT:	XOR	A		; 音量を0とする

YESPUT:	LD	E,A		; 音量を設定する
	LD	A,8		; 先頭の音量レジスタ
	ADD	A,C		; パート毎のレジスタにする
	JP	WRTPSG		; 常に音を出す(BEEP音、等への対策)

;-------------------------------------------
;	ＰＳＧのハードエンベローブ設定
;-------------------------------------------

PUTENV:	ADD	A,-16		; エンベローブのパターン番号を得る
	LD	E,A
	LD	A,13		; エンベローブの出力レジスタ
	CALL	WRTPSG		; PSGに出力(BIOS)
	LD	A,16		; 音量をエンベローブ出力とする
	RET

;-------------------------------------------
;	レジスタセット
;-------------------------------------------

WRTPSG:
	PUSH	DE
	LD	D,A
;WRTPSGL:
;	IN	A,(44H)
;	RLCA
;	JR	C,WRTPSGL

	PUSH	BC
	LD	BC,01C00H

	LD	A,D
	OUT	(C),A		; register
:	LD	A,(IX+0)

	DEC	B
	LD	A,E
	OUT	(C),A		; data

	POP	BC

	LD	A,D
	POP	DE
	RET

;-------------------------------------------
;	ワークエリア
;-------------------------------------------
;	ORG	0DE1EH

COUNT:	DB	1,1,1		; 音長カウンタ
STOPFRG:DB	0,0,0		; WAIT&SYNC&OFF
MAXVOL:	DB	15,15,15	; ボリューム
LENGTH:	DB	5,5,5		; 基本音長

OFFSET:	DB	0,0,0,0,0,0	; 演奏データ実行中アドレス
STARTADR:DB	0,0,0,0,0,0	; 演奏データ開始アドレス
FEEDVOL:DB	0		; フェードアウトレベル
FCOUNT:DB	1		; フェードアウトカウンタ
LOOPTIME:DB	0		; 演奏回数（０は無限ループ）
STOPPARTS:DB	0		; 
ENDFRG:	DB	0		; 
NSAVE:DB	0		; 

;-------------------------------------------
;	ここがDISKBASICの公式推奨最終番地
;-------------------------------------------

;	END
