copy %1.h mml.h
cc psgcomp.c -o psgcomp.exe
psgcomp %1.pdt
conv2 %1.pdt %1.obj
