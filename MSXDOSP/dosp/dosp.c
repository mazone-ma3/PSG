/* MSX PSG呼び出し実験 By m@3 */
/* .COM版 */
/* psgmsxd.objファイルと演奏ファイルを用意してください */
/* ZSDCC版 */

#include <stdio.h>
#iinclude <stdlib.h>
#include <conio.h>

FILE *stream[2];

#define ERROR 1
#define NOERROR 0

void DI(void){
__asm
	DI
__endasm;
}

void EI(void){
__asm
	EI
__endasm;
}

/* MSX BLOADデータをファイルからメモリに読み込む */
short msxload(char *loadfil, unsigned short offset)
{
	unsigned short size;
	unsigned char *address;
	unsigned char buffer[2];

	if ((stream[0] = fopen( loadfil, "rb")) == NULL) {
		printf("Can\'t open file %s.", loadfil);
		return ERROR;
	}

	fread( buffer, 1, 1, stream[0]);
	fread( buffer, 1, 2, stream[0]);
	address = (unsigned short *)(buffer[0] + buffer[1] * 256);
	fread( buffer, 1, 2, stream[0]);
	size = (buffer[0] + buffer[1] * 256) - (unsigned short)address;
	fread( buffer, 1, 2, stream[0]);
	address -= offset;
	printf("Load file %s. Address %x Size %x End %x\n", loadfil, address, size, (unsigned short)address + size);

	fread( address , 1, size, stream[0]);
	fclose(stream[0]);
	return NOERROR;
}

short bload(char *loadfil)
{
	unsigned short size;
	unsigned short *address;
	unsigned char buffer[2];

	if ((stream[0] = fopen( loadfil, "rb")) == NULL) {
		printf("Can\'t open file %s.", loadfil);
		return ERROR;
	}
	fread( buffer, 1, 2, stream[0]);
	address = (unsigned short *)(buffer[0] + buffer[1] * 256);
	fread( buffer, 1, 2, stream[0]);
	size = (buffer[0] + buffer[1] * 256) - (unsigned short)address;
	printf("Load file %s. Address %x Size %x End %x\n", loadfil, address, size, (unsigned short)address + size);

	fread( address, 1, size, stream[0]);
	fclose(stream[0]);
	return NOERROR;
}

short bload2(char *loadfil, unsigned short offset)
{
	unsigned short size;
	unsigned char *address;
	unsigned char buffer[2];

	if ((stream[0] = fopen( loadfil, "rb")) == NULL) {
		printf("Can\'t open file %s.", loadfil);
		return ERROR;
	}
	fread( buffer, 1, 2, stream[0]);
	address = (unsigned short *)(buffer[0] + buffer[1] * 256);
	fread( buffer, 1, 2, stream[0]);
	size = (buffer[0] + buffer[1] * 256) - (unsigned short)address;
	address -= offset;
	printf("Load file %s. Address %x Size %x End %x\n", loadfil, address , size, (unsigned short)address + size);

	fread( address , 1, size, stream[0]);
	fclose(stream[0]);
	return NOERROR;
}

void play_bgm(unsigned char no, unsigned char noise)
{
	unsigned char *mem=(unsigned char *)0xbc09;
	mem[0] = no;
	mem[3] = noise;
__asm
	call #0xbc00
__endasm;
}

void stop_bgm(void)
{
__asm
	call #0xbc03
__endasm;
}

void fade_bgm(void)
{
__asm
	call #0xbc06
__endasm;
}



int	main(int argc,char **argv)
{
	unsigned char no = 0, noise = 0x38;
	if (argc < 2){
		printf("PSGMSX Loader.\n");
		return ERROR;
	}
	if (argc >= 3){ //argv[2] != NULL){
		no = atoi(argv[2]);
		if(no > 9)
			no = 0;
/*		else{
			printf("no: %d\n",no);
			getch();
		}
*/	}

	if (argc >= 4){ //argv[2] != NULL){
		noise = atoi(argv[3]);
//		if(noise > 255)
//			noise = 0xc8;
/*		else{
			printf("no: %d\n",no);
			getch();
		}
*/	}

	if(msxload("psgtone.dat", 0x2000*1) == ERROR)
		return ERROR;

	if(msxload("psgmsxd.msx", 0) == ERROR)
		return ERROR;

	if(msxload(argv[1], 0x2000*1) == ERROR)
		return ERROR;

	EI();

	play_bgm(no, noise);
	getchar();
	stop_bgm();

	return NOERROR;
}

