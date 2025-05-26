#include <stdio.h>

short tone_data[12] = {
	 0xee8, 0xe12, 0xd48, 0xc88, 0xbd4, 0xb2a,
	 0xa8a, 0x9f2, 0x964, 0x8dc, 0x85e, 0x7e6,
};

FILE *stream[2];

int table[8] = { 1, 2, 4, 8, 16, 32, 128, 256};
unsigned char dummy[2] = {0, 0};

void main(void)
{
	int i, j, k = 0;
	unsigned char tonedata[12*8*2], value;
	for(i = 0; i < 8; ++i){
		for(j = 0; j < 12; ++j){
//			printf(" %3x,", tone_data[j] / i);
			printf(" %.2x,", value = tone_data[j] / table[i] % 256);
			tonedata[k++] = value;
			printf(" %.2x,", value = tone_data[j] / table[i] / 256);
			tonedata[k++] = value;
		}
		printf("\n");
	}

	char *savefil = "tone.dat";

	if ((stream[0] = fopen( savefil, "wb")) == NULL) {
		fprintf(stderr, "Can\'t open file %s.", savefil);

		fclose(stream[0]);
		return;
	}
	fwrite(dummy, 1, 2,stream[0]);
	fwrite(tonedata, 1, 12*8*2, stream[0]);
	fclose(stream[0]);
}

