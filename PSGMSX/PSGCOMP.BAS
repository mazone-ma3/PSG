10     'SAVE"PSGCOMP.BAS"
20 U=USR9(-1):CLEAR100,&HC9FF:DEFINTA-Z:RESTORE1010:ZB=-1:PE(0)=0:PE(1)=0:PE(2)=0:J=0
30 AD=&HDAFF:F=0:FM=0
40 FOR J=0 TO 2:SA=AD:PRINTFM;J:TEMPO=120:LE=4:OCT=4:VOL=9:ZR!=0
50 READ AA$:PRINTAA$:IF AA$="P" THEN 110 ELSE IF AA$="!" THEN BEEP:SA=0:GOTO 110:POKE AD,254:AD=AD+ZB:GOTO 110 ELSE IF AA$="END" OR AA$="*" THEN 530
60 '
70 FOR H=1 TO LEN(AA$):A$=MID$(AA$,H,1):IF A$=>"a" AND A$<="z" THEN A$=CHR$(ASC(A$)-32) ELSE IF A$=" " THEN 120
80 A=INSTR("RC D EF G A B><OLTVSMNY",A$):IF A=0 THEN 510
90 IF A<=13 THEN GOSUB 150 ELSE ON (A-13) GOSUB 260,270,280,300,330,350,380,400,420,440'JUMP
100 NEXT H:POKE AD,254:AD=AD+ZB:GOTO 50
101 'HEADER WRITE
110 POKEAD,255:AD=AD+ZB:PRINTZR!
120 BT=&HDB00+(2-J)*2+FM*8:F$=HEX$(SA):POKE BT,VAL("&h"+RIGHT$(F$,2)):POKE BT+1,VAL("&h"+LEFT$(F$,2)):NEXT J
130 FM=FM+1:GOTO 40
140 'OTO
150 IF A=1 THEN NUM=0 ELSE NUM=(OCT-1)*12+A-1
160 A$=MID$(AA$,H+1,1)
170 IF A$="+" OR A$="#" THEN NUM=NUM+1:IF NUM>96 THEN 510 ELSE H=H+1:GOTO 160
180 IF A$="-" THEN NUM=NUM-1:IF NUM<1 THEN 510 ELSE H=H+1:GOTO 160
190 LN=VAL(A$):IF LN=0 THEN IF NUM=0 OR A$="." THEN LN=4:GOTO 210 ELSE ZE!=ZR!+ME!-INT(ME!):IF ZE!<1 THEN ZR!=ZE!:POKE AD,NUM+128:AD=AD+ZB:RETURN ELSE MA!=ME!:GOTO 230
200 H=H+1:A=-1:C=64:D=1:GOSUB 470:IF A<>-1 THEN LN=A ELSE LN=LE:H=H-1
210 MA!=14400/(LN*TEMPO)
220 A$=MID$(AA$,H+1,1):IF A$="." THEN MA!=MA!*1.5:H=H+1:GOTO 220
230 ZR!=ZR!+MA!-INT(MA!):IF ZR!=>1 THEN MA!=MA!+INT(ZR!):ZR!=ZR!-INT(ZR!)'MAM=MAM!
240 POKE AD,NUM:AD=AD+ZB:POKE AD,INT(MA!):AD=AD+ZB:RETURN
250 'OCT
260 OCT=OCT-(OCT<8):RETURN
270 OCT=OCT+(OCT>1):RETURN
280 A=4:C=8:D=1:GOSUB 460:OCT=A:RETURN
290 'LENGTH
300 A=4:C=64:D=1:GOSUB 460:LE=A
310 POKE AD,227:AD=AD+ZB:GOSUB 490:POKE AD,INT(ME!):AD=AD+ZB:RETURN
320 'TEMPO
330 A=120:C=255:D=80:GOSUB 460:TEMPO=A:GOSUB 310:RETURN
340 'VOLUME
350 A=4:C=16:D=0:GOSUB 460:VOL=A
360 POKE AD,226:AD=AD+ZB:POKE AD,VOL:AD=AD+ZB:RETURN
370 'M
380 A=0:C=16:D=0:GOSUB 460:POKE AD,226:AD=AD+ZB:POKE AD,16+A:AD=AD+ZB:RETURN
390 'S
400 A=8000:C=32767:D=0:GOSUB 460:POKE AD,225:AD=AD+ZB:POKE AD,11:AD=AD+ZB:POKE AD,A AND 255:AD=AD+ZB:POKE AD,225:AD=AD+ZB:POKE AD,12:AD=AD+ZB:POKE AD,A\256:AD=AD+ZB:RETURN
410 'N
420 RETURN
430 'Y
440 RETURN
450 'SUB
460 H=H+1
470 A$=(MID$(AA$,H,1)):B=VAL(A$):IF B=0 AND A$<>"0" THEN H=H-1:RETURN ELSE A=B
480 A$=MID$(AA$,H+1,1):IF A$=>"0" AND A$<="9" THEN A=A*10+VAL(A$):H=H+1:GOTO 480 ELSE IF A>C OR A<D THEN 510 ELSE RETURN
490 ME!=14400/(LE*TEMPO):RETURN
500 'ERROR
510 PRINT "DATA ERROR.":BEEP:END
520 'SAVE
530 PRINT USING "START &  & END &  &";HEX$(AD);HEX$(BT+7):A$="N":INPUT ".PDT ̧��(������-�̧��)�¸�Ͻ?";A$:IF INSTR("Yy",A$)=0 THEN 545
540 F$="":LINE INPUT "FILENAME:";F$:IF F$<>"" THEN BSAVE F$+".PDT",AD,BT+7
545 A$="N":INPUT ".PLY ̧��(��޼ު��̧��)�¸�Ͻ?";A$:IF INSTR("Yy",A$)=0 THEN END
550 F$="":LINE INPUT "FILENAME:";F$:IF F$="" THEN END ELSE BSAVE F$+".PLY",AD,&HDE3F:KEY1,"U=USR9(-2)"+CHR$(13)+CHR$(7):END
900 '��-�� ��Ӽޥ�Ӽ� �������ֲ ��޼ ¶�Ų ��-�� ! � ���Ѷ Lr���� ���-��-� � ����
1000 SOUND7,&B011100:SOUND6,2
1010 DATA V13T180L8O6GEGEAGFEGEGEFEDCO6GEGEAGFEGEGEFEDCO6DO5GO6DO5GO6EDCO5GABO6CO5AGAGEO6DO5GO6DO5GO6EDCO5GO6DEFAG2,P
1020 DATA O3V13T180L8CGCGCACACGCGO2GBGBO3CGCGCACACGCGO2BO3GO2BO3GO2GBGBO3CECEO2GBGBO3CECEO2GBGBO3CECEO3FEDCO2BAGF,P
1030 DATA T180S8M3000L4CCCCCCCCM3000CCCCCCCCM3000CCM300CCM3000CCM300CCM3000CCM300CCR8CCM3000L8CC,P,END
