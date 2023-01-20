	li	x6, 0
	li	x7, 9999
	li	x1, 8



	li	x2, 152

loop:	lw	x3, 0(x1)	



	mul	x3,	x3,	x7 # r2 <- a * x[i]
	lw	x4, 0(x2)	

    
	add	x3,	x4,	x3 # r2 += y[i]
	sw	x3, 0(x2)	
    wfi
