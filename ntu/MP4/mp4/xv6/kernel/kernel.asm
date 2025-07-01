
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	85013103          	ld	sp,-1968(sp) # 80008850 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	e2c78793          	addi	a5,a5,-468 # 80005e90 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	e0078793          	addi	a5,a5,-512 # 80000eae <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000106:	04c05663          	blez	a2,80000152 <consolewrite+0x5e>
    8000010a:	8a2a                	mv	s4,a0
    8000010c:	84ae                	mv	s1,a1
    8000010e:	89b2                	mv	s3,a2
    80000110:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000112:	5afd                	li	s5,-1
    80000114:	4685                	li	a3,1
    80000116:	8626                	mv	a2,s1
    80000118:	85d2                	mv	a1,s4
    8000011a:	fbf40513          	addi	a0,s0,-65
    8000011e:	00002097          	auipc	ra,0x2
    80000122:	35c080e7          	jalr	860(ra) # 8000247a <either_copyin>
    80000126:	01550c63          	beq	a0,s5,8000013e <consolewrite+0x4a>
      break;
    uartputc(c);
    8000012a:	fbf44503          	lbu	a0,-65(s0)
    8000012e:	00000097          	auipc	ra,0x0
    80000132:	77a080e7          	jalr	1914(ra) # 800008a8 <uartputc>
  for(i = 0; i < n; i++){
    80000136:	2905                	addiw	s2,s2,1
    80000138:	0485                	addi	s1,s1,1
    8000013a:	fd299de3          	bne	s3,s2,80000114 <consolewrite+0x20>
  }

  return i;
}
    8000013e:	854a                	mv	a0,s2
    80000140:	60a6                	ld	ra,72(sp)
    80000142:	6406                	ld	s0,64(sp)
    80000144:	74e2                	ld	s1,56(sp)
    80000146:	7942                	ld	s2,48(sp)
    80000148:	79a2                	ld	s3,40(sp)
    8000014a:	7a02                	ld	s4,32(sp)
    8000014c:	6ae2                	ld	s5,24(sp)
    8000014e:	6161                	addi	sp,sp,80
    80000150:	8082                	ret
  for(i = 0; i < n; i++){
    80000152:	4901                	li	s2,0
    80000154:	b7ed                	j	8000013e <consolewrite+0x4a>

0000000080000156 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000156:	7159                	addi	sp,sp,-112
    80000158:	f486                	sd	ra,104(sp)
    8000015a:	f0a2                	sd	s0,96(sp)
    8000015c:	eca6                	sd	s1,88(sp)
    8000015e:	e8ca                	sd	s2,80(sp)
    80000160:	e4ce                	sd	s3,72(sp)
    80000162:	e0d2                	sd	s4,64(sp)
    80000164:	fc56                	sd	s5,56(sp)
    80000166:	f85a                	sd	s6,48(sp)
    80000168:	f45e                	sd	s7,40(sp)
    8000016a:	f062                	sd	s8,32(sp)
    8000016c:	ec66                	sd	s9,24(sp)
    8000016e:	e86a                	sd	s10,16(sp)
    80000170:	1880                	addi	s0,sp,112
    80000172:	8aaa                	mv	s5,a0
    80000174:	8a2e                	mv	s4,a1
    80000176:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000178:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000017c:	00011517          	auipc	a0,0x11
    80000180:	00450513          	addi	a0,a0,4 # 80011180 <cons>
    80000184:	00001097          	auipc	ra,0x1
    80000188:	a3e080e7          	jalr	-1474(ra) # 80000bc2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018c:	00011497          	auipc	s1,0x11
    80000190:	ff448493          	addi	s1,s1,-12 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000194:	00011917          	auipc	s2,0x11
    80000198:	08490913          	addi	s2,s2,132 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    8000019c:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000019e:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001a0:	4ca9                	li	s9,10
  while(n > 0){
    800001a2:	07305863          	blez	s3,80000212 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001a6:	0984a783          	lw	a5,152(s1)
    800001aa:	09c4a703          	lw	a4,156(s1)
    800001ae:	02f71463          	bne	a4,a5,800001d6 <consoleread+0x80>
      if(myproc()->killed){
    800001b2:	00002097          	auipc	ra,0x2
    800001b6:	80e080e7          	jalr	-2034(ra) # 800019c0 <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	ebe080e7          	jalr	-322(ra) # 80002080 <sleep>
    while(cons.r == cons.w){
    800001ca:	0984a783          	lw	a5,152(s1)
    800001ce:	09c4a703          	lw	a4,156(s1)
    800001d2:	fef700e3          	beq	a4,a5,800001b2 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001d6:	0017871b          	addiw	a4,a5,1
    800001da:	08e4ac23          	sw	a4,152(s1)
    800001de:	07f7f713          	andi	a4,a5,127
    800001e2:	9726                	add	a4,a4,s1
    800001e4:	01874703          	lbu	a4,24(a4)
    800001e8:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001ec:	077d0563          	beq	s10,s7,80000256 <consoleread+0x100>
    cbuf = c;
    800001f0:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001f4:	4685                	li	a3,1
    800001f6:	f9f40613          	addi	a2,s0,-97
    800001fa:	85d2                	mv	a1,s4
    800001fc:	8556                	mv	a0,s5
    800001fe:	00002097          	auipc	ra,0x2
    80000202:	226080e7          	jalr	550(ra) # 80002424 <either_copyout>
    80000206:	01850663          	beq	a0,s8,80000212 <consoleread+0xbc>
    dst++;
    8000020a:	0a05                	addi	s4,s4,1
    --n;
    8000020c:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000020e:	f99d1ae3          	bne	s10,s9,800001a2 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000212:	00011517          	auipc	a0,0x11
    80000216:	f6e50513          	addi	a0,a0,-146 # 80011180 <cons>
    8000021a:	00001097          	auipc	ra,0x1
    8000021e:	a5c080e7          	jalr	-1444(ra) # 80000c76 <release>

  return target - n;
    80000222:	413b053b          	subw	a0,s6,s3
    80000226:	a811                	j	8000023a <consoleread+0xe4>
        release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	f5850513          	addi	a0,a0,-168 # 80011180 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a46080e7          	jalr	-1466(ra) # 80000c76 <release>
        return -1;
    80000238:	557d                	li	a0,-1
}
    8000023a:	70a6                	ld	ra,104(sp)
    8000023c:	7406                	ld	s0,96(sp)
    8000023e:	64e6                	ld	s1,88(sp)
    80000240:	6946                	ld	s2,80(sp)
    80000242:	69a6                	ld	s3,72(sp)
    80000244:	6a06                	ld	s4,64(sp)
    80000246:	7ae2                	ld	s5,56(sp)
    80000248:	7b42                	ld	s6,48(sp)
    8000024a:	7ba2                	ld	s7,40(sp)
    8000024c:	7c02                	ld	s8,32(sp)
    8000024e:	6ce2                	ld	s9,24(sp)
    80000250:	6d42                	ld	s10,16(sp)
    80000252:	6165                	addi	sp,sp,112
    80000254:	8082                	ret
      if(n < target){
    80000256:	0009871b          	sext.w	a4,s3
    8000025a:	fb677ce3          	bgeu	a4,s6,80000212 <consoleread+0xbc>
        cons.r--;
    8000025e:	00011717          	auipc	a4,0x11
    80000262:	faf72d23          	sw	a5,-70(a4) # 80011218 <cons+0x98>
    80000266:	b775                	j	80000212 <consoleread+0xbc>

0000000080000268 <consputc>:
{
    80000268:	1141                	addi	sp,sp,-16
    8000026a:	e406                	sd	ra,8(sp)
    8000026c:	e022                	sd	s0,0(sp)
    8000026e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000270:	10000793          	li	a5,256
    80000274:	00f50a63          	beq	a0,a5,80000288 <consputc+0x20>
    uartputc_sync(c);
    80000278:	00000097          	auipc	ra,0x0
    8000027c:	55e080e7          	jalr	1374(ra) # 800007d6 <uartputc_sync>
}
    80000280:	60a2                	ld	ra,8(sp)
    80000282:	6402                	ld	s0,0(sp)
    80000284:	0141                	addi	sp,sp,16
    80000286:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000288:	4521                	li	a0,8
    8000028a:	00000097          	auipc	ra,0x0
    8000028e:	54c080e7          	jalr	1356(ra) # 800007d6 <uartputc_sync>
    80000292:	02000513          	li	a0,32
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	540080e7          	jalr	1344(ra) # 800007d6 <uartputc_sync>
    8000029e:	4521                	li	a0,8
    800002a0:	00000097          	auipc	ra,0x0
    800002a4:	536080e7          	jalr	1334(ra) # 800007d6 <uartputc_sync>
    800002a8:	bfe1                	j	80000280 <consputc+0x18>

00000000800002aa <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002aa:	1101                	addi	sp,sp,-32
    800002ac:	ec06                	sd	ra,24(sp)
    800002ae:	e822                	sd	s0,16(sp)
    800002b0:	e426                	sd	s1,8(sp)
    800002b2:	e04a                	sd	s2,0(sp)
    800002b4:	1000                	addi	s0,sp,32
    800002b6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002b8:	00011517          	auipc	a0,0x11
    800002bc:	ec850513          	addi	a0,a0,-312 # 80011180 <cons>
    800002c0:	00001097          	auipc	ra,0x1
    800002c4:	902080e7          	jalr	-1790(ra) # 80000bc2 <acquire>

  switch(c){
    800002c8:	47d5                	li	a5,21
    800002ca:	0af48663          	beq	s1,a5,80000376 <consoleintr+0xcc>
    800002ce:	0297ca63          	blt	a5,s1,80000302 <consoleintr+0x58>
    800002d2:	47a1                	li	a5,8
    800002d4:	0ef48763          	beq	s1,a5,800003c2 <consoleintr+0x118>
    800002d8:	47c1                	li	a5,16
    800002da:	10f49a63          	bne	s1,a5,800003ee <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002de:	00002097          	auipc	ra,0x2
    800002e2:	1f2080e7          	jalr	498(ra) # 800024d0 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002e6:	00011517          	auipc	a0,0x11
    800002ea:	e9a50513          	addi	a0,a0,-358 # 80011180 <cons>
    800002ee:	00001097          	auipc	ra,0x1
    800002f2:	988080e7          	jalr	-1656(ra) # 80000c76 <release>
}
    800002f6:	60e2                	ld	ra,24(sp)
    800002f8:	6442                	ld	s0,16(sp)
    800002fa:	64a2                	ld	s1,8(sp)
    800002fc:	6902                	ld	s2,0(sp)
    800002fe:	6105                	addi	sp,sp,32
    80000300:	8082                	ret
  switch(c){
    80000302:	07f00793          	li	a5,127
    80000306:	0af48e63          	beq	s1,a5,800003c2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000030a:	00011717          	auipc	a4,0x11
    8000030e:	e7670713          	addi	a4,a4,-394 # 80011180 <cons>
    80000312:	0a072783          	lw	a5,160(a4)
    80000316:	09872703          	lw	a4,152(a4)
    8000031a:	9f99                	subw	a5,a5,a4
    8000031c:	07f00713          	li	a4,127
    80000320:	fcf763e3          	bltu	a4,a5,800002e6 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000324:	47b5                	li	a5,13
    80000326:	0cf48763          	beq	s1,a5,800003f4 <consoleintr+0x14a>
      consputc(c);
    8000032a:	8526                	mv	a0,s1
    8000032c:	00000097          	auipc	ra,0x0
    80000330:	f3c080e7          	jalr	-196(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000334:	00011797          	auipc	a5,0x11
    80000338:	e4c78793          	addi	a5,a5,-436 # 80011180 <cons>
    8000033c:	0a07a703          	lw	a4,160(a5)
    80000340:	0017069b          	addiw	a3,a4,1
    80000344:	0006861b          	sext.w	a2,a3
    80000348:	0ad7a023          	sw	a3,160(a5)
    8000034c:	07f77713          	andi	a4,a4,127
    80000350:	97ba                	add	a5,a5,a4
    80000352:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000356:	47a9                	li	a5,10
    80000358:	0cf48563          	beq	s1,a5,80000422 <consoleintr+0x178>
    8000035c:	4791                	li	a5,4
    8000035e:	0cf48263          	beq	s1,a5,80000422 <consoleintr+0x178>
    80000362:	00011797          	auipc	a5,0x11
    80000366:	eb67a783          	lw	a5,-330(a5) # 80011218 <cons+0x98>
    8000036a:	0807879b          	addiw	a5,a5,128
    8000036e:	f6f61ce3          	bne	a2,a5,800002e6 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000372:	863e                	mv	a2,a5
    80000374:	a07d                	j	80000422 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000376:	00011717          	auipc	a4,0x11
    8000037a:	e0a70713          	addi	a4,a4,-502 # 80011180 <cons>
    8000037e:	0a072783          	lw	a5,160(a4)
    80000382:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000386:	00011497          	auipc	s1,0x11
    8000038a:	dfa48493          	addi	s1,s1,-518 # 80011180 <cons>
    while(cons.e != cons.w &&
    8000038e:	4929                	li	s2,10
    80000390:	f4f70be3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	37fd                	addiw	a5,a5,-1
    80000396:	07f7f713          	andi	a4,a5,127
    8000039a:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    8000039c:	01874703          	lbu	a4,24(a4)
    800003a0:	f52703e3          	beq	a4,s2,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003a4:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003a8:	10000513          	li	a0,256
    800003ac:	00000097          	auipc	ra,0x0
    800003b0:	ebc080e7          	jalr	-324(ra) # 80000268 <consputc>
    while(cons.e != cons.w &&
    800003b4:	0a04a783          	lw	a5,160(s1)
    800003b8:	09c4a703          	lw	a4,156(s1)
    800003bc:	fcf71ce3          	bne	a4,a5,80000394 <consoleintr+0xea>
    800003c0:	b71d                	j	800002e6 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003c2:	00011717          	auipc	a4,0x11
    800003c6:	dbe70713          	addi	a4,a4,-578 # 80011180 <cons>
    800003ca:	0a072783          	lw	a5,160(a4)
    800003ce:	09c72703          	lw	a4,156(a4)
    800003d2:	f0f70ae3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003d6:	37fd                	addiw	a5,a5,-1
    800003d8:	00011717          	auipc	a4,0x11
    800003dc:	e4f72423          	sw	a5,-440(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003e0:	10000513          	li	a0,256
    800003e4:	00000097          	auipc	ra,0x0
    800003e8:	e84080e7          	jalr	-380(ra) # 80000268 <consputc>
    800003ec:	bded                	j	800002e6 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003ee:	ee048ce3          	beqz	s1,800002e6 <consoleintr+0x3c>
    800003f2:	bf21                	j	8000030a <consoleintr+0x60>
      consputc(c);
    800003f4:	4529                	li	a0,10
    800003f6:	00000097          	auipc	ra,0x0
    800003fa:	e72080e7          	jalr	-398(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    800003fe:	00011797          	auipc	a5,0x11
    80000402:	d8278793          	addi	a5,a5,-638 # 80011180 <cons>
    80000406:	0a07a703          	lw	a4,160(a5)
    8000040a:	0017069b          	addiw	a3,a4,1
    8000040e:	0006861b          	sext.w	a2,a3
    80000412:	0ad7a023          	sw	a3,160(a5)
    80000416:	07f77713          	andi	a4,a4,127
    8000041a:	97ba                	add	a5,a5,a4
    8000041c:	4729                	li	a4,10
    8000041e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000422:	00011797          	auipc	a5,0x11
    80000426:	dec7ad23          	sw	a2,-518(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000042a:	00011517          	auipc	a0,0x11
    8000042e:	dee50513          	addi	a0,a0,-530 # 80011218 <cons+0x98>
    80000432:	00002097          	auipc	ra,0x2
    80000436:	dda080e7          	jalr	-550(ra) # 8000220c <wakeup>
    8000043a:	b575                	j	800002e6 <consoleintr+0x3c>

000000008000043c <consoleinit>:

void
consoleinit(void)
{
    8000043c:	1141                	addi	sp,sp,-16
    8000043e:	e406                	sd	ra,8(sp)
    80000440:	e022                	sd	s0,0(sp)
    80000442:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000444:	00008597          	auipc	a1,0x8
    80000448:	bcc58593          	addi	a1,a1,-1076 # 80008010 <etext+0x10>
    8000044c:	00011517          	auipc	a0,0x11
    80000450:	d3450513          	addi	a0,a0,-716 # 80011180 <cons>
    80000454:	00000097          	auipc	ra,0x0
    80000458:	6de080e7          	jalr	1758(ra) # 80000b32 <initlock>

  uartinit();
    8000045c:	00000097          	auipc	ra,0x0
    80000460:	32a080e7          	jalr	810(ra) # 80000786 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000464:	00021797          	auipc	a5,0x21
    80000468:	eb478793          	addi	a5,a5,-332 # 80021318 <devsw>
    8000046c:	00000717          	auipc	a4,0x0
    80000470:	cea70713          	addi	a4,a4,-790 # 80000156 <consoleread>
    80000474:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000476:	00000717          	auipc	a4,0x0
    8000047a:	c7e70713          	addi	a4,a4,-898 # 800000f4 <consolewrite>
    8000047e:	ef98                	sd	a4,24(a5)
}
    80000480:	60a2                	ld	ra,8(sp)
    80000482:	6402                	ld	s0,0(sp)
    80000484:	0141                	addi	sp,sp,16
    80000486:	8082                	ret

0000000080000488 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000488:	7179                	addi	sp,sp,-48
    8000048a:	f406                	sd	ra,40(sp)
    8000048c:	f022                	sd	s0,32(sp)
    8000048e:	ec26                	sd	s1,24(sp)
    80000490:	e84a                	sd	s2,16(sp)
    80000492:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    80000494:	c219                	beqz	a2,8000049a <printint+0x12>
    80000496:	08054663          	bltz	a0,80000522 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    8000049a:	2501                	sext.w	a0,a0
    8000049c:	4881                	li	a7,0
    8000049e:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004a2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004a4:	2581                	sext.w	a1,a1
    800004a6:	00008617          	auipc	a2,0x8
    800004aa:	b9a60613          	addi	a2,a2,-1126 # 80008040 <digits>
    800004ae:	883a                	mv	a6,a4
    800004b0:	2705                	addiw	a4,a4,1
    800004b2:	02b577bb          	remuw	a5,a0,a1
    800004b6:	1782                	slli	a5,a5,0x20
    800004b8:	9381                	srli	a5,a5,0x20
    800004ba:	97b2                	add	a5,a5,a2
    800004bc:	0007c783          	lbu	a5,0(a5)
    800004c0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004c4:	0005079b          	sext.w	a5,a0
    800004c8:	02b5553b          	divuw	a0,a0,a1
    800004cc:	0685                	addi	a3,a3,1
    800004ce:	feb7f0e3          	bgeu	a5,a1,800004ae <printint+0x26>

  if(sign)
    800004d2:	00088b63          	beqz	a7,800004e8 <printint+0x60>
    buf[i++] = '-';
    800004d6:	fe040793          	addi	a5,s0,-32
    800004da:	973e                	add	a4,a4,a5
    800004dc:	02d00793          	li	a5,45
    800004e0:	fef70823          	sb	a5,-16(a4)
    800004e4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004e8:	02e05763          	blez	a4,80000516 <printint+0x8e>
    800004ec:	fd040793          	addi	a5,s0,-48
    800004f0:	00e784b3          	add	s1,a5,a4
    800004f4:	fff78913          	addi	s2,a5,-1
    800004f8:	993a                	add	s2,s2,a4
    800004fa:	377d                	addiw	a4,a4,-1
    800004fc:	1702                	slli	a4,a4,0x20
    800004fe:	9301                	srli	a4,a4,0x20
    80000500:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000504:	fff4c503          	lbu	a0,-1(s1)
    80000508:	00000097          	auipc	ra,0x0
    8000050c:	d60080e7          	jalr	-672(ra) # 80000268 <consputc>
  while(--i >= 0)
    80000510:	14fd                	addi	s1,s1,-1
    80000512:	ff2499e3          	bne	s1,s2,80000504 <printint+0x7c>
}
    80000516:	70a2                	ld	ra,40(sp)
    80000518:	7402                	ld	s0,32(sp)
    8000051a:	64e2                	ld	s1,24(sp)
    8000051c:	6942                	ld	s2,16(sp)
    8000051e:	6145                	addi	sp,sp,48
    80000520:	8082                	ret
    x = -xx;
    80000522:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000526:	4885                	li	a7,1
    x = -xx;
    80000528:	bf9d                	j	8000049e <printint+0x16>

000000008000052a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000052a:	1101                	addi	sp,sp,-32
    8000052c:	ec06                	sd	ra,24(sp)
    8000052e:	e822                	sd	s0,16(sp)
    80000530:	e426                	sd	s1,8(sp)
    80000532:	1000                	addi	s0,sp,32
    80000534:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000536:	00011797          	auipc	a5,0x11
    8000053a:	d007a523          	sw	zero,-758(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    8000053e:	00008517          	auipc	a0,0x8
    80000542:	ada50513          	addi	a0,a0,-1318 # 80008018 <etext+0x18>
    80000546:	00000097          	auipc	ra,0x0
    8000054a:	02e080e7          	jalr	46(ra) # 80000574 <printf>
  printf(s);
    8000054e:	8526                	mv	a0,s1
    80000550:	00000097          	auipc	ra,0x0
    80000554:	024080e7          	jalr	36(ra) # 80000574 <printf>
  printf("\n");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	b7050513          	addi	a0,a0,-1168 # 800080c8 <digits+0x88>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	014080e7          	jalr	20(ra) # 80000574 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000568:	4785                	li	a5,1
    8000056a:	00009717          	auipc	a4,0x9
    8000056e:	a8f72b23          	sw	a5,-1386(a4) # 80009000 <panicked>
  for(;;)
    80000572:	a001                	j	80000572 <panic+0x48>

0000000080000574 <printf>:
{
    80000574:	7131                	addi	sp,sp,-192
    80000576:	fc86                	sd	ra,120(sp)
    80000578:	f8a2                	sd	s0,112(sp)
    8000057a:	f4a6                	sd	s1,104(sp)
    8000057c:	f0ca                	sd	s2,96(sp)
    8000057e:	ecce                	sd	s3,88(sp)
    80000580:	e8d2                	sd	s4,80(sp)
    80000582:	e4d6                	sd	s5,72(sp)
    80000584:	e0da                	sd	s6,64(sp)
    80000586:	fc5e                	sd	s7,56(sp)
    80000588:	f862                	sd	s8,48(sp)
    8000058a:	f466                	sd	s9,40(sp)
    8000058c:	f06a                	sd	s10,32(sp)
    8000058e:	ec6e                	sd	s11,24(sp)
    80000590:	0100                	addi	s0,sp,128
    80000592:	8a2a                	mv	s4,a0
    80000594:	e40c                	sd	a1,8(s0)
    80000596:	e810                	sd	a2,16(s0)
    80000598:	ec14                	sd	a3,24(s0)
    8000059a:	f018                	sd	a4,32(s0)
    8000059c:	f41c                	sd	a5,40(s0)
    8000059e:	03043823          	sd	a6,48(s0)
    800005a2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005a6:	00011d97          	auipc	s11,0x11
    800005aa:	c9adad83          	lw	s11,-870(s11) # 80011240 <pr+0x18>
  if(locking)
    800005ae:	020d9b63          	bnez	s11,800005e4 <printf+0x70>
  if (fmt == 0)
    800005b2:	040a0263          	beqz	s4,800005f6 <printf+0x82>
  va_start(ap, fmt);
    800005b6:	00840793          	addi	a5,s0,8
    800005ba:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005be:	000a4503          	lbu	a0,0(s4)
    800005c2:	14050f63          	beqz	a0,80000720 <printf+0x1ac>
    800005c6:	4981                	li	s3,0
    if(c != '%'){
    800005c8:	02500a93          	li	s5,37
    switch(c){
    800005cc:	07000b93          	li	s7,112
  consputc('x');
    800005d0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d2:	00008b17          	auipc	s6,0x8
    800005d6:	a6eb0b13          	addi	s6,s6,-1426 # 80008040 <digits>
    switch(c){
    800005da:	07300c93          	li	s9,115
    800005de:	06400c13          	li	s8,100
    800005e2:	a82d                	j	8000061c <printf+0xa8>
    acquire(&pr.lock);
    800005e4:	00011517          	auipc	a0,0x11
    800005e8:	c4450513          	addi	a0,a0,-956 # 80011228 <pr>
    800005ec:	00000097          	auipc	ra,0x0
    800005f0:	5d6080e7          	jalr	1494(ra) # 80000bc2 <acquire>
    800005f4:	bf7d                	j	800005b2 <printf+0x3e>
    panic("null fmt");
    800005f6:	00008517          	auipc	a0,0x8
    800005fa:	a3250513          	addi	a0,a0,-1486 # 80008028 <etext+0x28>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	f2c080e7          	jalr	-212(ra) # 8000052a <panic>
      consputc(c);
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	c62080e7          	jalr	-926(ra) # 80000268 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000060e:	2985                	addiw	s3,s3,1
    80000610:	013a07b3          	add	a5,s4,s3
    80000614:	0007c503          	lbu	a0,0(a5)
    80000618:	10050463          	beqz	a0,80000720 <printf+0x1ac>
    if(c != '%'){
    8000061c:	ff5515e3          	bne	a0,s5,80000606 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000620:	2985                	addiw	s3,s3,1
    80000622:	013a07b3          	add	a5,s4,s3
    80000626:	0007c783          	lbu	a5,0(a5)
    8000062a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000062e:	cbed                	beqz	a5,80000720 <printf+0x1ac>
    switch(c){
    80000630:	05778a63          	beq	a5,s7,80000684 <printf+0x110>
    80000634:	02fbf663          	bgeu	s7,a5,80000660 <printf+0xec>
    80000638:	09978863          	beq	a5,s9,800006c8 <printf+0x154>
    8000063c:	07800713          	li	a4,120
    80000640:	0ce79563          	bne	a5,a4,8000070a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000644:	f8843783          	ld	a5,-120(s0)
    80000648:	00878713          	addi	a4,a5,8
    8000064c:	f8e43423          	sd	a4,-120(s0)
    80000650:	4605                	li	a2,1
    80000652:	85ea                	mv	a1,s10
    80000654:	4388                	lw	a0,0(a5)
    80000656:	00000097          	auipc	ra,0x0
    8000065a:	e32080e7          	jalr	-462(ra) # 80000488 <printint>
      break;
    8000065e:	bf45                	j	8000060e <printf+0x9a>
    switch(c){
    80000660:	09578f63          	beq	a5,s5,800006fe <printf+0x18a>
    80000664:	0b879363          	bne	a5,s8,8000070a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000668:	f8843783          	ld	a5,-120(s0)
    8000066c:	00878713          	addi	a4,a5,8
    80000670:	f8e43423          	sd	a4,-120(s0)
    80000674:	4605                	li	a2,1
    80000676:	45a9                	li	a1,10
    80000678:	4388                	lw	a0,0(a5)
    8000067a:	00000097          	auipc	ra,0x0
    8000067e:	e0e080e7          	jalr	-498(ra) # 80000488 <printint>
      break;
    80000682:	b771                	j	8000060e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000684:	f8843783          	ld	a5,-120(s0)
    80000688:	00878713          	addi	a4,a5,8
    8000068c:	f8e43423          	sd	a4,-120(s0)
    80000690:	0007b903          	ld	s2,0(a5)
  consputc('0');
    80000694:	03000513          	li	a0,48
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	bd0080e7          	jalr	-1072(ra) # 80000268 <consputc>
  consputc('x');
    800006a0:	07800513          	li	a0,120
    800006a4:	00000097          	auipc	ra,0x0
    800006a8:	bc4080e7          	jalr	-1084(ra) # 80000268 <consputc>
    800006ac:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006ae:	03c95793          	srli	a5,s2,0x3c
    800006b2:	97da                	add	a5,a5,s6
    800006b4:	0007c503          	lbu	a0,0(a5)
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bb0080e7          	jalr	-1104(ra) # 80000268 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006c0:	0912                	slli	s2,s2,0x4
    800006c2:	34fd                	addiw	s1,s1,-1
    800006c4:	f4ed                	bnez	s1,800006ae <printf+0x13a>
    800006c6:	b7a1                	j	8000060e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006c8:	f8843783          	ld	a5,-120(s0)
    800006cc:	00878713          	addi	a4,a5,8
    800006d0:	f8e43423          	sd	a4,-120(s0)
    800006d4:	6384                	ld	s1,0(a5)
    800006d6:	cc89                	beqz	s1,800006f0 <printf+0x17c>
      for(; *s; s++)
    800006d8:	0004c503          	lbu	a0,0(s1)
    800006dc:	d90d                	beqz	a0,8000060e <printf+0x9a>
        consputc(*s);
    800006de:	00000097          	auipc	ra,0x0
    800006e2:	b8a080e7          	jalr	-1142(ra) # 80000268 <consputc>
      for(; *s; s++)
    800006e6:	0485                	addi	s1,s1,1
    800006e8:	0004c503          	lbu	a0,0(s1)
    800006ec:	f96d                	bnez	a0,800006de <printf+0x16a>
    800006ee:	b705                	j	8000060e <printf+0x9a>
        s = "(null)";
    800006f0:	00008497          	auipc	s1,0x8
    800006f4:	93048493          	addi	s1,s1,-1744 # 80008020 <etext+0x20>
      for(; *s; s++)
    800006f8:	02800513          	li	a0,40
    800006fc:	b7cd                	j	800006de <printf+0x16a>
      consputc('%');
    800006fe:	8556                	mv	a0,s5
    80000700:	00000097          	auipc	ra,0x0
    80000704:	b68080e7          	jalr	-1176(ra) # 80000268 <consputc>
      break;
    80000708:	b719                	j	8000060e <printf+0x9a>
      consputc('%');
    8000070a:	8556                	mv	a0,s5
    8000070c:	00000097          	auipc	ra,0x0
    80000710:	b5c080e7          	jalr	-1188(ra) # 80000268 <consputc>
      consputc(c);
    80000714:	8526                	mv	a0,s1
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b52080e7          	jalr	-1198(ra) # 80000268 <consputc>
      break;
    8000071e:	bdc5                	j	8000060e <printf+0x9a>
  if(locking)
    80000720:	020d9163          	bnez	s11,80000742 <printf+0x1ce>
}
    80000724:	70e6                	ld	ra,120(sp)
    80000726:	7446                	ld	s0,112(sp)
    80000728:	74a6                	ld	s1,104(sp)
    8000072a:	7906                	ld	s2,96(sp)
    8000072c:	69e6                	ld	s3,88(sp)
    8000072e:	6a46                	ld	s4,80(sp)
    80000730:	6aa6                	ld	s5,72(sp)
    80000732:	6b06                	ld	s6,64(sp)
    80000734:	7be2                	ld	s7,56(sp)
    80000736:	7c42                	ld	s8,48(sp)
    80000738:	7ca2                	ld	s9,40(sp)
    8000073a:	7d02                	ld	s10,32(sp)
    8000073c:	6de2                	ld	s11,24(sp)
    8000073e:	6129                	addi	sp,sp,192
    80000740:	8082                	ret
    release(&pr.lock);
    80000742:	00011517          	auipc	a0,0x11
    80000746:	ae650513          	addi	a0,a0,-1306 # 80011228 <pr>
    8000074a:	00000097          	auipc	ra,0x0
    8000074e:	52c080e7          	jalr	1324(ra) # 80000c76 <release>
}
    80000752:	bfc9                	j	80000724 <printf+0x1b0>

0000000080000754 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000754:	1101                	addi	sp,sp,-32
    80000756:	ec06                	sd	ra,24(sp)
    80000758:	e822                	sd	s0,16(sp)
    8000075a:	e426                	sd	s1,8(sp)
    8000075c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000075e:	00011497          	auipc	s1,0x11
    80000762:	aca48493          	addi	s1,s1,-1334 # 80011228 <pr>
    80000766:	00008597          	auipc	a1,0x8
    8000076a:	8d258593          	addi	a1,a1,-1838 # 80008038 <etext+0x38>
    8000076e:	8526                	mv	a0,s1
    80000770:	00000097          	auipc	ra,0x0
    80000774:	3c2080e7          	jalr	962(ra) # 80000b32 <initlock>
  pr.locking = 1;
    80000778:	4785                	li	a5,1
    8000077a:	cc9c                	sw	a5,24(s1)
}
    8000077c:	60e2                	ld	ra,24(sp)
    8000077e:	6442                	ld	s0,16(sp)
    80000780:	64a2                	ld	s1,8(sp)
    80000782:	6105                	addi	sp,sp,32
    80000784:	8082                	ret

0000000080000786 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000786:	1141                	addi	sp,sp,-16
    80000788:	e406                	sd	ra,8(sp)
    8000078a:	e022                	sd	s0,0(sp)
    8000078c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000078e:	100007b7          	lui	a5,0x10000
    80000792:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000796:	f8000713          	li	a4,-128
    8000079a:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000079e:	470d                	li	a4,3
    800007a0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007a4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007a8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007ac:	469d                	li	a3,7
    800007ae:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007b2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007b6:	00008597          	auipc	a1,0x8
    800007ba:	8a258593          	addi	a1,a1,-1886 # 80008058 <digits+0x18>
    800007be:	00011517          	auipc	a0,0x11
    800007c2:	a8a50513          	addi	a0,a0,-1398 # 80011248 <uart_tx_lock>
    800007c6:	00000097          	auipc	ra,0x0
    800007ca:	36c080e7          	jalr	876(ra) # 80000b32 <initlock>
}
    800007ce:	60a2                	ld	ra,8(sp)
    800007d0:	6402                	ld	s0,0(sp)
    800007d2:	0141                	addi	sp,sp,16
    800007d4:	8082                	ret

00000000800007d6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007d6:	1101                	addi	sp,sp,-32
    800007d8:	ec06                	sd	ra,24(sp)
    800007da:	e822                	sd	s0,16(sp)
    800007dc:	e426                	sd	s1,8(sp)
    800007de:	1000                	addi	s0,sp,32
    800007e0:	84aa                	mv	s1,a0
  push_off();
    800007e2:	00000097          	auipc	ra,0x0
    800007e6:	394080e7          	jalr	916(ra) # 80000b76 <push_off>

  if(panicked){
    800007ea:	00009797          	auipc	a5,0x9
    800007ee:	8167a783          	lw	a5,-2026(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007f2:	10000737          	lui	a4,0x10000
  if(panicked){
    800007f6:	c391                	beqz	a5,800007fa <uartputc_sync+0x24>
    for(;;)
    800007f8:	a001                	j	800007f8 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007fa:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    800007fe:	0207f793          	andi	a5,a5,32
    80000802:	dfe5                	beqz	a5,800007fa <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000804:	0ff4f513          	andi	a0,s1,255
    80000808:	100007b7          	lui	a5,0x10000
    8000080c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000810:	00000097          	auipc	ra,0x0
    80000814:	406080e7          	jalr	1030(ra) # 80000c16 <pop_off>
}
    80000818:	60e2                	ld	ra,24(sp)
    8000081a:	6442                	ld	s0,16(sp)
    8000081c:	64a2                	ld	s1,8(sp)
    8000081e:	6105                	addi	sp,sp,32
    80000820:	8082                	ret

0000000080000822 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000822:	00008797          	auipc	a5,0x8
    80000826:	7e67b783          	ld	a5,2022(a5) # 80009008 <uart_tx_r>
    8000082a:	00008717          	auipc	a4,0x8
    8000082e:	7e673703          	ld	a4,2022(a4) # 80009010 <uart_tx_w>
    80000832:	06f70a63          	beq	a4,a5,800008a6 <uartstart+0x84>
{
    80000836:	7139                	addi	sp,sp,-64
    80000838:	fc06                	sd	ra,56(sp)
    8000083a:	f822                	sd	s0,48(sp)
    8000083c:	f426                	sd	s1,40(sp)
    8000083e:	f04a                	sd	s2,32(sp)
    80000840:	ec4e                	sd	s3,24(sp)
    80000842:	e852                	sd	s4,16(sp)
    80000844:	e456                	sd	s5,8(sp)
    80000846:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000848:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000084c:	00011a17          	auipc	s4,0x11
    80000850:	9fca0a13          	addi	s4,s4,-1540 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000854:	00008497          	auipc	s1,0x8
    80000858:	7b448493          	addi	s1,s1,1972 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000085c:	00008997          	auipc	s3,0x8
    80000860:	7b498993          	addi	s3,s3,1972 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000864:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000868:	02077713          	andi	a4,a4,32
    8000086c:	c705                	beqz	a4,80000894 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086e:	01f7f713          	andi	a4,a5,31
    80000872:	9752                	add	a4,a4,s4
    80000874:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000878:	0785                	addi	a5,a5,1
    8000087a:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000087c:	8526                	mv	a0,s1
    8000087e:	00002097          	auipc	ra,0x2
    80000882:	98e080e7          	jalr	-1650(ra) # 8000220c <wakeup>
    
    WriteReg(THR, c);
    80000886:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000088a:	609c                	ld	a5,0(s1)
    8000088c:	0009b703          	ld	a4,0(s3)
    80000890:	fcf71ae3          	bne	a4,a5,80000864 <uartstart+0x42>
  }
}
    80000894:	70e2                	ld	ra,56(sp)
    80000896:	7442                	ld	s0,48(sp)
    80000898:	74a2                	ld	s1,40(sp)
    8000089a:	7902                	ld	s2,32(sp)
    8000089c:	69e2                	ld	s3,24(sp)
    8000089e:	6a42                	ld	s4,16(sp)
    800008a0:	6aa2                	ld	s5,8(sp)
    800008a2:	6121                	addi	sp,sp,64
    800008a4:	8082                	ret
    800008a6:	8082                	ret

00000000800008a8 <uartputc>:
{
    800008a8:	7179                	addi	sp,sp,-48
    800008aa:	f406                	sd	ra,40(sp)
    800008ac:	f022                	sd	s0,32(sp)
    800008ae:	ec26                	sd	s1,24(sp)
    800008b0:	e84a                	sd	s2,16(sp)
    800008b2:	e44e                	sd	s3,8(sp)
    800008b4:	e052                	sd	s4,0(sp)
    800008b6:	1800                	addi	s0,sp,48
    800008b8:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ba:	00011517          	auipc	a0,0x11
    800008be:	98e50513          	addi	a0,a0,-1650 # 80011248 <uart_tx_lock>
    800008c2:	00000097          	auipc	ra,0x0
    800008c6:	300080e7          	jalr	768(ra) # 80000bc2 <acquire>
  if(panicked){
    800008ca:	00008797          	auipc	a5,0x8
    800008ce:	7367a783          	lw	a5,1846(a5) # 80009000 <panicked>
    800008d2:	c391                	beqz	a5,800008d6 <uartputc+0x2e>
    for(;;)
    800008d4:	a001                	j	800008d4 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008d6:	00008717          	auipc	a4,0x8
    800008da:	73a73703          	ld	a4,1850(a4) # 80009010 <uart_tx_w>
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	72a7b783          	ld	a5,1834(a5) # 80009008 <uart_tx_r>
    800008e6:	02078793          	addi	a5,a5,32
    800008ea:	02e79b63          	bne	a5,a4,80000920 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008ee:	00011997          	auipc	s3,0x11
    800008f2:	95a98993          	addi	s3,s3,-1702 # 80011248 <uart_tx_lock>
    800008f6:	00008497          	auipc	s1,0x8
    800008fa:	71248493          	addi	s1,s1,1810 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fe:	00008917          	auipc	s2,0x8
    80000902:	71290913          	addi	s2,s2,1810 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000906:	85ce                	mv	a1,s3
    80000908:	8526                	mv	a0,s1
    8000090a:	00001097          	auipc	ra,0x1
    8000090e:	776080e7          	jalr	1910(ra) # 80002080 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000912:	00093703          	ld	a4,0(s2)
    80000916:	609c                	ld	a5,0(s1)
    80000918:	02078793          	addi	a5,a5,32
    8000091c:	fee785e3          	beq	a5,a4,80000906 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000920:	00011497          	auipc	s1,0x11
    80000924:	92848493          	addi	s1,s1,-1752 # 80011248 <uart_tx_lock>
    80000928:	01f77793          	andi	a5,a4,31
    8000092c:	97a6                	add	a5,a5,s1
    8000092e:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000932:	0705                	addi	a4,a4,1
    80000934:	00008797          	auipc	a5,0x8
    80000938:	6ce7be23          	sd	a4,1756(a5) # 80009010 <uart_tx_w>
      uartstart();
    8000093c:	00000097          	auipc	ra,0x0
    80000940:	ee6080e7          	jalr	-282(ra) # 80000822 <uartstart>
      release(&uart_tx_lock);
    80000944:	8526                	mv	a0,s1
    80000946:	00000097          	auipc	ra,0x0
    8000094a:	330080e7          	jalr	816(ra) # 80000c76 <release>
}
    8000094e:	70a2                	ld	ra,40(sp)
    80000950:	7402                	ld	s0,32(sp)
    80000952:	64e2                	ld	s1,24(sp)
    80000954:	6942                	ld	s2,16(sp)
    80000956:	69a2                	ld	s3,8(sp)
    80000958:	6a02                	ld	s4,0(sp)
    8000095a:	6145                	addi	sp,sp,48
    8000095c:	8082                	ret

000000008000095e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000095e:	1141                	addi	sp,sp,-16
    80000960:	e422                	sd	s0,8(sp)
    80000962:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000964:	100007b7          	lui	a5,0x10000
    80000968:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000096c:	8b85                	andi	a5,a5,1
    8000096e:	cb91                	beqz	a5,80000982 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000970:	100007b7          	lui	a5,0x10000
    80000974:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000978:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000097c:	6422                	ld	s0,8(sp)
    8000097e:	0141                	addi	sp,sp,16
    80000980:	8082                	ret
    return -1;
    80000982:	557d                	li	a0,-1
    80000984:	bfe5                	j	8000097c <uartgetc+0x1e>

0000000080000986 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000986:	1101                	addi	sp,sp,-32
    80000988:	ec06                	sd	ra,24(sp)
    8000098a:	e822                	sd	s0,16(sp)
    8000098c:	e426                	sd	s1,8(sp)
    8000098e:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000990:	54fd                	li	s1,-1
    80000992:	a029                	j	8000099c <uartintr+0x16>
      break;
    consoleintr(c);
    80000994:	00000097          	auipc	ra,0x0
    80000998:	916080e7          	jalr	-1770(ra) # 800002aa <consoleintr>
    int c = uartgetc();
    8000099c:	00000097          	auipc	ra,0x0
    800009a0:	fc2080e7          	jalr	-62(ra) # 8000095e <uartgetc>
    if(c == -1)
    800009a4:	fe9518e3          	bne	a0,s1,80000994 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009a8:	00011497          	auipc	s1,0x11
    800009ac:	8a048493          	addi	s1,s1,-1888 # 80011248 <uart_tx_lock>
    800009b0:	8526                	mv	a0,s1
    800009b2:	00000097          	auipc	ra,0x0
    800009b6:	210080e7          	jalr	528(ra) # 80000bc2 <acquire>
  uartstart();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	e68080e7          	jalr	-408(ra) # 80000822 <uartstart>
  release(&uart_tx_lock);
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	2b2080e7          	jalr	690(ra) # 80000c76 <release>
}
    800009cc:	60e2                	ld	ra,24(sp)
    800009ce:	6442                	ld	s0,16(sp)
    800009d0:	64a2                	ld	s1,8(sp)
    800009d2:	6105                	addi	sp,sp,32
    800009d4:	8082                	ret

00000000800009d6 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009d6:	1101                	addi	sp,sp,-32
    800009d8:	ec06                	sd	ra,24(sp)
    800009da:	e822                	sd	s0,16(sp)
    800009dc:	e426                	sd	s1,8(sp)
    800009de:	e04a                	sd	s2,0(sp)
    800009e0:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009e2:	03451793          	slli	a5,a0,0x34
    800009e6:	ebb9                	bnez	a5,80000a3c <kfree+0x66>
    800009e8:	84aa                	mv	s1,a0
    800009ea:	00025797          	auipc	a5,0x25
    800009ee:	61678793          	addi	a5,a5,1558 # 80026000 <end>
    800009f2:	04f56563          	bltu	a0,a5,80000a3c <kfree+0x66>
    800009f6:	47c5                	li	a5,17
    800009f8:	07ee                	slli	a5,a5,0x1b
    800009fa:	04f57163          	bgeu	a0,a5,80000a3c <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    800009fe:	6605                	lui	a2,0x1
    80000a00:	4585                	li	a1,1
    80000a02:	00000097          	auipc	ra,0x0
    80000a06:	2bc080e7          	jalr	700(ra) # 80000cbe <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a0a:	00011917          	auipc	s2,0x11
    80000a0e:	87690913          	addi	s2,s2,-1930 # 80011280 <kmem>
    80000a12:	854a                	mv	a0,s2
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	1ae080e7          	jalr	430(ra) # 80000bc2 <acquire>
  r->next = kmem.freelist;
    80000a1c:	01893783          	ld	a5,24(s2)
    80000a20:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a22:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	24e080e7          	jalr	590(ra) # 80000c76 <release>
}
    80000a30:	60e2                	ld	ra,24(sp)
    80000a32:	6442                	ld	s0,16(sp)
    80000a34:	64a2                	ld	s1,8(sp)
    80000a36:	6902                	ld	s2,0(sp)
    80000a38:	6105                	addi	sp,sp,32
    80000a3a:	8082                	ret
    panic("kfree");
    80000a3c:	00007517          	auipc	a0,0x7
    80000a40:	62450513          	addi	a0,a0,1572 # 80008060 <digits+0x20>
    80000a44:	00000097          	auipc	ra,0x0
    80000a48:	ae6080e7          	jalr	-1306(ra) # 8000052a <panic>

0000000080000a4c <freerange>:
{
    80000a4c:	7179                	addi	sp,sp,-48
    80000a4e:	f406                	sd	ra,40(sp)
    80000a50:	f022                	sd	s0,32(sp)
    80000a52:	ec26                	sd	s1,24(sp)
    80000a54:	e84a                	sd	s2,16(sp)
    80000a56:	e44e                	sd	s3,8(sp)
    80000a58:	e052                	sd	s4,0(sp)
    80000a5a:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a5c:	6785                	lui	a5,0x1
    80000a5e:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a62:	94aa                	add	s1,s1,a0
    80000a64:	757d                	lui	a0,0xfffff
    80000a66:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a68:	94be                	add	s1,s1,a5
    80000a6a:	0095ee63          	bltu	a1,s1,80000a86 <freerange+0x3a>
    80000a6e:	892e                	mv	s2,a1
    kfree(p);
    80000a70:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a72:	6985                	lui	s3,0x1
    kfree(p);
    80000a74:	01448533          	add	a0,s1,s4
    80000a78:	00000097          	auipc	ra,0x0
    80000a7c:	f5e080e7          	jalr	-162(ra) # 800009d6 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	94ce                	add	s1,s1,s3
    80000a82:	fe9979e3          	bgeu	s2,s1,80000a74 <freerange+0x28>
}
    80000a86:	70a2                	ld	ra,40(sp)
    80000a88:	7402                	ld	s0,32(sp)
    80000a8a:	64e2                	ld	s1,24(sp)
    80000a8c:	6942                	ld	s2,16(sp)
    80000a8e:	69a2                	ld	s3,8(sp)
    80000a90:	6a02                	ld	s4,0(sp)
    80000a92:	6145                	addi	sp,sp,48
    80000a94:	8082                	ret

0000000080000a96 <kinit>:
{
    80000a96:	1141                	addi	sp,sp,-16
    80000a98:	e406                	sd	ra,8(sp)
    80000a9a:	e022                	sd	s0,0(sp)
    80000a9c:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000a9e:	00007597          	auipc	a1,0x7
    80000aa2:	5ca58593          	addi	a1,a1,1482 # 80008068 <digits+0x28>
    80000aa6:	00010517          	auipc	a0,0x10
    80000aaa:	7da50513          	addi	a0,a0,2010 # 80011280 <kmem>
    80000aae:	00000097          	auipc	ra,0x0
    80000ab2:	084080e7          	jalr	132(ra) # 80000b32 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ab6:	45c5                	li	a1,17
    80000ab8:	05ee                	slli	a1,a1,0x1b
    80000aba:	00025517          	auipc	a0,0x25
    80000abe:	54650513          	addi	a0,a0,1350 # 80026000 <end>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	f8a080e7          	jalr	-118(ra) # 80000a4c <freerange>
}
    80000aca:	60a2                	ld	ra,8(sp)
    80000acc:	6402                	ld	s0,0(sp)
    80000ace:	0141                	addi	sp,sp,16
    80000ad0:	8082                	ret

0000000080000ad2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ad2:	1101                	addi	sp,sp,-32
    80000ad4:	ec06                	sd	ra,24(sp)
    80000ad6:	e822                	sd	s0,16(sp)
    80000ad8:	e426                	sd	s1,8(sp)
    80000ada:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000adc:	00010497          	auipc	s1,0x10
    80000ae0:	7a448493          	addi	s1,s1,1956 # 80011280 <kmem>
    80000ae4:	8526                	mv	a0,s1
    80000ae6:	00000097          	auipc	ra,0x0
    80000aea:	0dc080e7          	jalr	220(ra) # 80000bc2 <acquire>
  r = kmem.freelist;
    80000aee:	6c84                	ld	s1,24(s1)
  if(r)
    80000af0:	c885                	beqz	s1,80000b20 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000af2:	609c                	ld	a5,0(s1)
    80000af4:	00010517          	auipc	a0,0x10
    80000af8:	78c50513          	addi	a0,a0,1932 # 80011280 <kmem>
    80000afc:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	178080e7          	jalr	376(ra) # 80000c76 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b06:	6605                	lui	a2,0x1
    80000b08:	4595                	li	a1,5
    80000b0a:	8526                	mv	a0,s1
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	1b2080e7          	jalr	434(ra) # 80000cbe <memset>
  return (void*)r;
}
    80000b14:	8526                	mv	a0,s1
    80000b16:	60e2                	ld	ra,24(sp)
    80000b18:	6442                	ld	s0,16(sp)
    80000b1a:	64a2                	ld	s1,8(sp)
    80000b1c:	6105                	addi	sp,sp,32
    80000b1e:	8082                	ret
  release(&kmem.lock);
    80000b20:	00010517          	auipc	a0,0x10
    80000b24:	76050513          	addi	a0,a0,1888 # 80011280 <kmem>
    80000b28:	00000097          	auipc	ra,0x0
    80000b2c:	14e080e7          	jalr	334(ra) # 80000c76 <release>
  if(r)
    80000b30:	b7d5                	j	80000b14 <kalloc+0x42>

0000000080000b32 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b32:	1141                	addi	sp,sp,-16
    80000b34:	e422                	sd	s0,8(sp)
    80000b36:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b38:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b3a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b3e:	00053823          	sd	zero,16(a0)
}
    80000b42:	6422                	ld	s0,8(sp)
    80000b44:	0141                	addi	sp,sp,16
    80000b46:	8082                	ret

0000000080000b48 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b48:	411c                	lw	a5,0(a0)
    80000b4a:	e399                	bnez	a5,80000b50 <holding+0x8>
    80000b4c:	4501                	li	a0,0
  return r;
}
    80000b4e:	8082                	ret
{
    80000b50:	1101                	addi	sp,sp,-32
    80000b52:	ec06                	sd	ra,24(sp)
    80000b54:	e822                	sd	s0,16(sp)
    80000b56:	e426                	sd	s1,8(sp)
    80000b58:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b5a:	6904                	ld	s1,16(a0)
    80000b5c:	00001097          	auipc	ra,0x1
    80000b60:	e48080e7          	jalr	-440(ra) # 800019a4 <mycpu>
    80000b64:	40a48533          	sub	a0,s1,a0
    80000b68:	00153513          	seqz	a0,a0
}
    80000b6c:	60e2                	ld	ra,24(sp)
    80000b6e:	6442                	ld	s0,16(sp)
    80000b70:	64a2                	ld	s1,8(sp)
    80000b72:	6105                	addi	sp,sp,32
    80000b74:	8082                	ret

0000000080000b76 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b76:	1101                	addi	sp,sp,-32
    80000b78:	ec06                	sd	ra,24(sp)
    80000b7a:	e822                	sd	s0,16(sp)
    80000b7c:	e426                	sd	s1,8(sp)
    80000b7e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b80:	100024f3          	csrr	s1,sstatus
    80000b84:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b88:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b8a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b8e:	00001097          	auipc	ra,0x1
    80000b92:	e16080e7          	jalr	-490(ra) # 800019a4 <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	e0a080e7          	jalr	-502(ra) # 800019a4 <mycpu>
    80000ba2:	5d3c                	lw	a5,120(a0)
    80000ba4:	2785                	addiw	a5,a5,1
    80000ba6:	dd3c                	sw	a5,120(a0)
}
    80000ba8:	60e2                	ld	ra,24(sp)
    80000baa:	6442                	ld	s0,16(sp)
    80000bac:	64a2                	ld	s1,8(sp)
    80000bae:	6105                	addi	sp,sp,32
    80000bb0:	8082                	ret
    mycpu()->intena = old;
    80000bb2:	00001097          	auipc	ra,0x1
    80000bb6:	df2080e7          	jalr	-526(ra) # 800019a4 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bba:	8085                	srli	s1,s1,0x1
    80000bbc:	8885                	andi	s1,s1,1
    80000bbe:	dd64                	sw	s1,124(a0)
    80000bc0:	bfe9                	j	80000b9a <push_off+0x24>

0000000080000bc2 <acquire>:
{
    80000bc2:	1101                	addi	sp,sp,-32
    80000bc4:	ec06                	sd	ra,24(sp)
    80000bc6:	e822                	sd	s0,16(sp)
    80000bc8:	e426                	sd	s1,8(sp)
    80000bca:	1000                	addi	s0,sp,32
    80000bcc:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bce:	00000097          	auipc	ra,0x0
    80000bd2:	fa8080e7          	jalr	-88(ra) # 80000b76 <push_off>
  if(holding(lk))
    80000bd6:	8526                	mv	a0,s1
    80000bd8:	00000097          	auipc	ra,0x0
    80000bdc:	f70080e7          	jalr	-144(ra) # 80000b48 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be0:	4705                	li	a4,1
  if(holding(lk))
    80000be2:	e115                	bnez	a0,80000c06 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be4:	87ba                	mv	a5,a4
    80000be6:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bea:	2781                	sext.w	a5,a5
    80000bec:	ffe5                	bnez	a5,80000be4 <acquire+0x22>
  __sync_synchronize();
    80000bee:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000bf2:	00001097          	auipc	ra,0x1
    80000bf6:	db2080e7          	jalr	-590(ra) # 800019a4 <mycpu>
    80000bfa:	e888                	sd	a0,16(s1)
}
    80000bfc:	60e2                	ld	ra,24(sp)
    80000bfe:	6442                	ld	s0,16(sp)
    80000c00:	64a2                	ld	s1,8(sp)
    80000c02:	6105                	addi	sp,sp,32
    80000c04:	8082                	ret
    panic("acquire");
    80000c06:	00007517          	auipc	a0,0x7
    80000c0a:	46a50513          	addi	a0,a0,1130 # 80008070 <digits+0x30>
    80000c0e:	00000097          	auipc	ra,0x0
    80000c12:	91c080e7          	jalr	-1764(ra) # 8000052a <panic>

0000000080000c16 <pop_off>:

void
pop_off(void)
{
    80000c16:	1141                	addi	sp,sp,-16
    80000c18:	e406                	sd	ra,8(sp)
    80000c1a:	e022                	sd	s0,0(sp)
    80000c1c:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c1e:	00001097          	auipc	ra,0x1
    80000c22:	d86080e7          	jalr	-634(ra) # 800019a4 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c26:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c2a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c2c:	e78d                	bnez	a5,80000c56 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c2e:	5d3c                	lw	a5,120(a0)
    80000c30:	02f05b63          	blez	a5,80000c66 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c34:	37fd                	addiw	a5,a5,-1
    80000c36:	0007871b          	sext.w	a4,a5
    80000c3a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c3c:	eb09                	bnez	a4,80000c4e <pop_off+0x38>
    80000c3e:	5d7c                	lw	a5,124(a0)
    80000c40:	c799                	beqz	a5,80000c4e <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c42:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c46:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c4a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c4e:	60a2                	ld	ra,8(sp)
    80000c50:	6402                	ld	s0,0(sp)
    80000c52:	0141                	addi	sp,sp,16
    80000c54:	8082                	ret
    panic("pop_off - interruptible");
    80000c56:	00007517          	auipc	a0,0x7
    80000c5a:	42250513          	addi	a0,a0,1058 # 80008078 <digits+0x38>
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	8cc080e7          	jalr	-1844(ra) # 8000052a <panic>
    panic("pop_off");
    80000c66:	00007517          	auipc	a0,0x7
    80000c6a:	42a50513          	addi	a0,a0,1066 # 80008090 <digits+0x50>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	8bc080e7          	jalr	-1860(ra) # 8000052a <panic>

0000000080000c76 <release>:
{
    80000c76:	1101                	addi	sp,sp,-32
    80000c78:	ec06                	sd	ra,24(sp)
    80000c7a:	e822                	sd	s0,16(sp)
    80000c7c:	e426                	sd	s1,8(sp)
    80000c7e:	1000                	addi	s0,sp,32
    80000c80:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	ec6080e7          	jalr	-314(ra) # 80000b48 <holding>
    80000c8a:	c115                	beqz	a0,80000cae <release+0x38>
  lk->cpu = 0;
    80000c8c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c90:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000c94:	0f50000f          	fence	iorw,ow
    80000c98:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000c9c:	00000097          	auipc	ra,0x0
    80000ca0:	f7a080e7          	jalr	-134(ra) # 80000c16 <pop_off>
}
    80000ca4:	60e2                	ld	ra,24(sp)
    80000ca6:	6442                	ld	s0,16(sp)
    80000ca8:	64a2                	ld	s1,8(sp)
    80000caa:	6105                	addi	sp,sp,32
    80000cac:	8082                	ret
    panic("release");
    80000cae:	00007517          	auipc	a0,0x7
    80000cb2:	3ea50513          	addi	a0,a0,1002 # 80008098 <digits+0x58>
    80000cb6:	00000097          	auipc	ra,0x0
    80000cba:	874080e7          	jalr	-1932(ra) # 8000052a <panic>

0000000080000cbe <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cbe:	1141                	addi	sp,sp,-16
    80000cc0:	e422                	sd	s0,8(sp)
    80000cc2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cc4:	ca19                	beqz	a2,80000cda <memset+0x1c>
    80000cc6:	87aa                	mv	a5,a0
    80000cc8:	1602                	slli	a2,a2,0x20
    80000cca:	9201                	srli	a2,a2,0x20
    80000ccc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cd0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cd4:	0785                	addi	a5,a5,1
    80000cd6:	fee79de3          	bne	a5,a4,80000cd0 <memset+0x12>
  }
  return dst;
}
    80000cda:	6422                	ld	s0,8(sp)
    80000cdc:	0141                	addi	sp,sp,16
    80000cde:	8082                	ret

0000000080000ce0 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000ce6:	ca05                	beqz	a2,80000d16 <memcmp+0x36>
    80000ce8:	fff6069b          	addiw	a3,a2,-1
    80000cec:	1682                	slli	a3,a3,0x20
    80000cee:	9281                	srli	a3,a3,0x20
    80000cf0:	0685                	addi	a3,a3,1
    80000cf2:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000cf4:	00054783          	lbu	a5,0(a0)
    80000cf8:	0005c703          	lbu	a4,0(a1)
    80000cfc:	00e79863          	bne	a5,a4,80000d0c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d00:	0505                	addi	a0,a0,1
    80000d02:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d04:	fed518e3          	bne	a0,a3,80000cf4 <memcmp+0x14>
  }

  return 0;
    80000d08:	4501                	li	a0,0
    80000d0a:	a019                	j	80000d10 <memcmp+0x30>
      return *s1 - *s2;
    80000d0c:	40e7853b          	subw	a0,a5,a4
}
    80000d10:	6422                	ld	s0,8(sp)
    80000d12:	0141                	addi	sp,sp,16
    80000d14:	8082                	ret
  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	bfe5                	j	80000d10 <memcmp+0x30>

0000000080000d1a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d1a:	1141                	addi	sp,sp,-16
    80000d1c:	e422                	sd	s0,8(sp)
    80000d1e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d20:	02a5e563          	bltu	a1,a0,80000d4a <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d24:	fff6069b          	addiw	a3,a2,-1
    80000d28:	ce11                	beqz	a2,80000d44 <memmove+0x2a>
    80000d2a:	1682                	slli	a3,a3,0x20
    80000d2c:	9281                	srli	a3,a3,0x20
    80000d2e:	0685                	addi	a3,a3,1
    80000d30:	96ae                	add	a3,a3,a1
    80000d32:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d34:	0585                	addi	a1,a1,1
    80000d36:	0785                	addi	a5,a5,1
    80000d38:	fff5c703          	lbu	a4,-1(a1)
    80000d3c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d40:	fed59ae3          	bne	a1,a3,80000d34 <memmove+0x1a>

  return dst;
}
    80000d44:	6422                	ld	s0,8(sp)
    80000d46:	0141                	addi	sp,sp,16
    80000d48:	8082                	ret
  if(s < d && s + n > d){
    80000d4a:	02061713          	slli	a4,a2,0x20
    80000d4e:	9301                	srli	a4,a4,0x20
    80000d50:	00e587b3          	add	a5,a1,a4
    80000d54:	fcf578e3          	bgeu	a0,a5,80000d24 <memmove+0xa>
    d += n;
    80000d58:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d5a:	fff6069b          	addiw	a3,a2,-1
    80000d5e:	d27d                	beqz	a2,80000d44 <memmove+0x2a>
    80000d60:	02069613          	slli	a2,a3,0x20
    80000d64:	9201                	srli	a2,a2,0x20
    80000d66:	fff64613          	not	a2,a2
    80000d6a:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000d6c:	17fd                	addi	a5,a5,-1
    80000d6e:	177d                	addi	a4,a4,-1
    80000d70:	0007c683          	lbu	a3,0(a5)
    80000d74:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000d78:	fef61ae3          	bne	a2,a5,80000d6c <memmove+0x52>
    80000d7c:	b7e1                	j	80000d44 <memmove+0x2a>

0000000080000d7e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d7e:	1141                	addi	sp,sp,-16
    80000d80:	e406                	sd	ra,8(sp)
    80000d82:	e022                	sd	s0,0(sp)
    80000d84:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d86:	00000097          	auipc	ra,0x0
    80000d8a:	f94080e7          	jalr	-108(ra) # 80000d1a <memmove>
}
    80000d8e:	60a2                	ld	ra,8(sp)
    80000d90:	6402                	ld	s0,0(sp)
    80000d92:	0141                	addi	sp,sp,16
    80000d94:	8082                	ret

0000000080000d96 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d96:	1141                	addi	sp,sp,-16
    80000d98:	e422                	sd	s0,8(sp)
    80000d9a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000d9c:	ce11                	beqz	a2,80000db8 <strncmp+0x22>
    80000d9e:	00054783          	lbu	a5,0(a0)
    80000da2:	cf89                	beqz	a5,80000dbc <strncmp+0x26>
    80000da4:	0005c703          	lbu	a4,0(a1)
    80000da8:	00f71a63          	bne	a4,a5,80000dbc <strncmp+0x26>
    n--, p++, q++;
    80000dac:	367d                	addiw	a2,a2,-1
    80000dae:	0505                	addi	a0,a0,1
    80000db0:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db2:	f675                	bnez	a2,80000d9e <strncmp+0x8>
  if(n == 0)
    return 0;
    80000db4:	4501                	li	a0,0
    80000db6:	a809                	j	80000dc8 <strncmp+0x32>
    80000db8:	4501                	li	a0,0
    80000dba:	a039                	j	80000dc8 <strncmp+0x32>
  if(n == 0)
    80000dbc:	ca09                	beqz	a2,80000dce <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dbe:	00054503          	lbu	a0,0(a0)
    80000dc2:	0005c783          	lbu	a5,0(a1)
    80000dc6:	9d1d                	subw	a0,a0,a5
}
    80000dc8:	6422                	ld	s0,8(sp)
    80000dca:	0141                	addi	sp,sp,16
    80000dcc:	8082                	ret
    return 0;
    80000dce:	4501                	li	a0,0
    80000dd0:	bfe5                	j	80000dc8 <strncmp+0x32>

0000000080000dd2 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd2:	1141                	addi	sp,sp,-16
    80000dd4:	e422                	sd	s0,8(sp)
    80000dd6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dd8:	872a                	mv	a4,a0
    80000dda:	8832                	mv	a6,a2
    80000ddc:	367d                	addiw	a2,a2,-1
    80000dde:	01005963          	blez	a6,80000df0 <strncpy+0x1e>
    80000de2:	0705                	addi	a4,a4,1
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	fef70fa3          	sb	a5,-1(a4)
    80000dec:	0585                	addi	a1,a1,1
    80000dee:	f7f5                	bnez	a5,80000dda <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df0:	86ba                	mv	a3,a4
    80000df2:	00c05c63          	blez	a2,80000e0a <strncpy+0x38>
    *s++ = 0;
    80000df6:	0685                	addi	a3,a3,1
    80000df8:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000dfc:	fff6c793          	not	a5,a3
    80000e00:	9fb9                	addw	a5,a5,a4
    80000e02:	010787bb          	addw	a5,a5,a6
    80000e06:	fef048e3          	bgtz	a5,80000df6 <strncpy+0x24>
  return os;
}
    80000e0a:	6422                	ld	s0,8(sp)
    80000e0c:	0141                	addi	sp,sp,16
    80000e0e:	8082                	ret

0000000080000e10 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e10:	1141                	addi	sp,sp,-16
    80000e12:	e422                	sd	s0,8(sp)
    80000e14:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e16:	02c05363          	blez	a2,80000e3c <safestrcpy+0x2c>
    80000e1a:	fff6069b          	addiw	a3,a2,-1
    80000e1e:	1682                	slli	a3,a3,0x20
    80000e20:	9281                	srli	a3,a3,0x20
    80000e22:	96ae                	add	a3,a3,a1
    80000e24:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e26:	00d58963          	beq	a1,a3,80000e38 <safestrcpy+0x28>
    80000e2a:	0585                	addi	a1,a1,1
    80000e2c:	0785                	addi	a5,a5,1
    80000e2e:	fff5c703          	lbu	a4,-1(a1)
    80000e32:	fee78fa3          	sb	a4,-1(a5)
    80000e36:	fb65                	bnez	a4,80000e26 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e38:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e3c:	6422                	ld	s0,8(sp)
    80000e3e:	0141                	addi	sp,sp,16
    80000e40:	8082                	ret

0000000080000e42 <strlen>:

int
strlen(const char *s)
{
    80000e42:	1141                	addi	sp,sp,-16
    80000e44:	e422                	sd	s0,8(sp)
    80000e46:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e48:	00054783          	lbu	a5,0(a0)
    80000e4c:	cf91                	beqz	a5,80000e68 <strlen+0x26>
    80000e4e:	0505                	addi	a0,a0,1
    80000e50:	87aa                	mv	a5,a0
    80000e52:	4685                	li	a3,1
    80000e54:	9e89                	subw	a3,a3,a0
    80000e56:	00f6853b          	addw	a0,a3,a5
    80000e5a:	0785                	addi	a5,a5,1
    80000e5c:	fff7c703          	lbu	a4,-1(a5)
    80000e60:	fb7d                	bnez	a4,80000e56 <strlen+0x14>
    ;
  return n;
}
    80000e62:	6422                	ld	s0,8(sp)
    80000e64:	0141                	addi	sp,sp,16
    80000e66:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e68:	4501                	li	a0,0
    80000e6a:	bfe5                	j	80000e62 <strlen+0x20>

0000000080000e6c <strcat>:

char* 
strcat(char* destination, const char* source)
{
    80000e6c:	1101                	addi	sp,sp,-32
    80000e6e:	ec06                	sd	ra,24(sp)
    80000e70:	e822                	sd	s0,16(sp)
    80000e72:	e426                	sd	s1,8(sp)
    80000e74:	e04a                	sd	s2,0(sp)
    80000e76:	1000                	addi	s0,sp,32
    80000e78:	892a                	mv	s2,a0
    80000e7a:	84ae                	mv	s1,a1
  char* ptr = destination + strlen(destination);
    80000e7c:	00000097          	auipc	ra,0x0
    80000e80:	fc6080e7          	jalr	-58(ra) # 80000e42 <strlen>
    80000e84:	00a907b3          	add	a5,s2,a0

  while (*source != '\0')
    80000e88:	0004c703          	lbu	a4,0(s1)
    80000e8c:	cb01                	beqz	a4,80000e9c <strcat+0x30>
    *ptr++ = *source++;
    80000e8e:	0485                	addi	s1,s1,1
    80000e90:	0785                	addi	a5,a5,1
    80000e92:	fee78fa3          	sb	a4,-1(a5)
  while (*source != '\0')
    80000e96:	0004c703          	lbu	a4,0(s1)
    80000e9a:	fb75                	bnez	a4,80000e8e <strcat+0x22>

  *ptr = '\0';
    80000e9c:	00078023          	sb	zero,0(a5)

  return destination;
}
    80000ea0:	854a                	mv	a0,s2
    80000ea2:	60e2                	ld	ra,24(sp)
    80000ea4:	6442                	ld	s0,16(sp)
    80000ea6:	64a2                	ld	s1,8(sp)
    80000ea8:	6902                	ld	s2,0(sp)
    80000eaa:	6105                	addi	sp,sp,32
    80000eac:	8082                	ret

0000000080000eae <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000eae:	1141                	addi	sp,sp,-16
    80000eb0:	e406                	sd	ra,8(sp)
    80000eb2:	e022                	sd	s0,0(sp)
    80000eb4:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000eb6:	00001097          	auipc	ra,0x1
    80000eba:	ade080e7          	jalr	-1314(ra) # 80001994 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ebe:	00008717          	auipc	a4,0x8
    80000ec2:	15a70713          	addi	a4,a4,346 # 80009018 <started>
  if(cpuid() == 0){
    80000ec6:	c139                	beqz	a0,80000f0c <main+0x5e>
    while(started == 0)
    80000ec8:	431c                	lw	a5,0(a4)
    80000eca:	2781                	sext.w	a5,a5
    80000ecc:	dff5                	beqz	a5,80000ec8 <main+0x1a>
      ;
    __sync_synchronize();
    80000ece:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ed2:	00001097          	auipc	ra,0x1
    80000ed6:	ac2080e7          	jalr	-1342(ra) # 80001994 <cpuid>
    80000eda:	85aa                	mv	a1,a0
    80000edc:	00007517          	auipc	a0,0x7
    80000ee0:	1dc50513          	addi	a0,a0,476 # 800080b8 <digits+0x78>
    80000ee4:	fffff097          	auipc	ra,0xfffff
    80000ee8:	690080e7          	jalr	1680(ra) # 80000574 <printf>
    kvminithart();    // turn on paging
    80000eec:	00000097          	auipc	ra,0x0
    80000ef0:	0d8080e7          	jalr	216(ra) # 80000fc4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ef4:	00001097          	auipc	ra,0x1
    80000ef8:	71c080e7          	jalr	1820(ra) # 80002610 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000efc:	00005097          	auipc	ra,0x5
    80000f00:	fd4080e7          	jalr	-44(ra) # 80005ed0 <plicinithart>
  }

  scheduler();        
    80000f04:	00001097          	auipc	ra,0x1
    80000f08:	fca080e7          	jalr	-54(ra) # 80001ece <scheduler>
    consoleinit();
    80000f0c:	fffff097          	auipc	ra,0xfffff
    80000f10:	530080e7          	jalr	1328(ra) # 8000043c <consoleinit>
    printfinit();
    80000f14:	00000097          	auipc	ra,0x0
    80000f18:	840080e7          	jalr	-1984(ra) # 80000754 <printfinit>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	650080e7          	jalr	1616(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000f2c:	00007517          	auipc	a0,0x7
    80000f30:	17450513          	addi	a0,a0,372 # 800080a0 <digits+0x60>
    80000f34:	fffff097          	auipc	ra,0xfffff
    80000f38:	640080e7          	jalr	1600(ra) # 80000574 <printf>
    printf("\n");
    80000f3c:	00007517          	auipc	a0,0x7
    80000f40:	18c50513          	addi	a0,a0,396 # 800080c8 <digits+0x88>
    80000f44:	fffff097          	auipc	ra,0xfffff
    80000f48:	630080e7          	jalr	1584(ra) # 80000574 <printf>
    kinit();         // physical page allocator
    80000f4c:	00000097          	auipc	ra,0x0
    80000f50:	b4a080e7          	jalr	-1206(ra) # 80000a96 <kinit>
    kvminit();       // create kernel page table
    80000f54:	00000097          	auipc	ra,0x0
    80000f58:	310080e7          	jalr	784(ra) # 80001264 <kvminit>
    kvminithart();   // turn on paging
    80000f5c:	00000097          	auipc	ra,0x0
    80000f60:	068080e7          	jalr	104(ra) # 80000fc4 <kvminithart>
    procinit();      // process table
    80000f64:	00001097          	auipc	ra,0x1
    80000f68:	980080e7          	jalr	-1664(ra) # 800018e4 <procinit>
    trapinit();      // trap vectors
    80000f6c:	00001097          	auipc	ra,0x1
    80000f70:	67c080e7          	jalr	1660(ra) # 800025e8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f74:	00001097          	auipc	ra,0x1
    80000f78:	69c080e7          	jalr	1692(ra) # 80002610 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f7c:	00005097          	auipc	ra,0x5
    80000f80:	f3e080e7          	jalr	-194(ra) # 80005eba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	f4c080e7          	jalr	-180(ra) # 80005ed0 <plicinithart>
    binit();         // buffer cache
    80000f8c:	00002097          	auipc	ra,0x2
    80000f90:	dc4080e7          	jalr	-572(ra) # 80002d50 <binit>
    iinit();         // inode cache
    80000f94:	00002097          	auipc	ra,0x2
    80000f98:	52c080e7          	jalr	1324(ra) # 800034c0 <iinit>
    fileinit();      // file table
    80000f9c:	00003097          	auipc	ra,0x3
    80000fa0:	60c080e7          	jalr	1548(ra) # 800045a8 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fa4:	00005097          	auipc	ra,0x5
    80000fa8:	04e080e7          	jalr	78(ra) # 80005ff2 <virtio_disk_init>
    userinit();      // first user process
    80000fac:	00001097          	auipc	ra,0x1
    80000fb0:	cec080e7          	jalr	-788(ra) # 80001c98 <userinit>
    __sync_synchronize();
    80000fb4:	0ff0000f          	fence
    started = 1;
    80000fb8:	4785                	li	a5,1
    80000fba:	00008717          	auipc	a4,0x8
    80000fbe:	04f72f23          	sw	a5,94(a4) # 80009018 <started>
    80000fc2:	b789                	j	80000f04 <main+0x56>

0000000080000fc4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fc4:	1141                	addi	sp,sp,-16
    80000fc6:	e422                	sd	s0,8(sp)
    80000fc8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fca:	00008797          	auipc	a5,0x8
    80000fce:	0567b783          	ld	a5,86(a5) # 80009020 <kernel_pagetable>
    80000fd2:	83b1                	srli	a5,a5,0xc
    80000fd4:	577d                	li	a4,-1
    80000fd6:	177e                	slli	a4,a4,0x3f
    80000fd8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fda:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fde:	12000073          	sfence.vma
  sfence_vma();
}
    80000fe2:	6422                	ld	s0,8(sp)
    80000fe4:	0141                	addi	sp,sp,16
    80000fe6:	8082                	ret

0000000080000fe8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fe8:	7139                	addi	sp,sp,-64
    80000fea:	fc06                	sd	ra,56(sp)
    80000fec:	f822                	sd	s0,48(sp)
    80000fee:	f426                	sd	s1,40(sp)
    80000ff0:	f04a                	sd	s2,32(sp)
    80000ff2:	ec4e                	sd	s3,24(sp)
    80000ff4:	e852                	sd	s4,16(sp)
    80000ff6:	e456                	sd	s5,8(sp)
    80000ff8:	e05a                	sd	s6,0(sp)
    80000ffa:	0080                	addi	s0,sp,64
    80000ffc:	84aa                	mv	s1,a0
    80000ffe:	89ae                	mv	s3,a1
    80001000:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001002:	57fd                	li	a5,-1
    80001004:	83e9                	srli	a5,a5,0x1a
    80001006:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001008:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000100a:	04b7f263          	bgeu	a5,a1,8000104e <walk+0x66>
    panic("walk");
    8000100e:	00007517          	auipc	a0,0x7
    80001012:	0c250513          	addi	a0,a0,194 # 800080d0 <digits+0x90>
    80001016:	fffff097          	auipc	ra,0xfffff
    8000101a:	514080e7          	jalr	1300(ra) # 8000052a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000101e:	060a8663          	beqz	s5,8000108a <walk+0xa2>
    80001022:	00000097          	auipc	ra,0x0
    80001026:	ab0080e7          	jalr	-1360(ra) # 80000ad2 <kalloc>
    8000102a:	84aa                	mv	s1,a0
    8000102c:	c529                	beqz	a0,80001076 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000102e:	6605                	lui	a2,0x1
    80001030:	4581                	li	a1,0
    80001032:	00000097          	auipc	ra,0x0
    80001036:	c8c080e7          	jalr	-884(ra) # 80000cbe <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000103a:	00c4d793          	srli	a5,s1,0xc
    8000103e:	07aa                	slli	a5,a5,0xa
    80001040:	0017e793          	ori	a5,a5,1
    80001044:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001048:	3a5d                	addiw	s4,s4,-9
    8000104a:	036a0063          	beq	s4,s6,8000106a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000104e:	0149d933          	srl	s2,s3,s4
    80001052:	1ff97913          	andi	s2,s2,511
    80001056:	090e                	slli	s2,s2,0x3
    80001058:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000105a:	00093483          	ld	s1,0(s2)
    8000105e:	0014f793          	andi	a5,s1,1
    80001062:	dfd5                	beqz	a5,8000101e <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001064:	80a9                	srli	s1,s1,0xa
    80001066:	04b2                	slli	s1,s1,0xc
    80001068:	b7c5                	j	80001048 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000106a:	00c9d513          	srli	a0,s3,0xc
    8000106e:	1ff57513          	andi	a0,a0,511
    80001072:	050e                	slli	a0,a0,0x3
    80001074:	9526                	add	a0,a0,s1
}
    80001076:	70e2                	ld	ra,56(sp)
    80001078:	7442                	ld	s0,48(sp)
    8000107a:	74a2                	ld	s1,40(sp)
    8000107c:	7902                	ld	s2,32(sp)
    8000107e:	69e2                	ld	s3,24(sp)
    80001080:	6a42                	ld	s4,16(sp)
    80001082:	6aa2                	ld	s5,8(sp)
    80001084:	6b02                	ld	s6,0(sp)
    80001086:	6121                	addi	sp,sp,64
    80001088:	8082                	ret
        return 0;
    8000108a:	4501                	li	a0,0
    8000108c:	b7ed                	j	80001076 <walk+0x8e>

000000008000108e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000108e:	57fd                	li	a5,-1
    80001090:	83e9                	srli	a5,a5,0x1a
    80001092:	00b7f463          	bgeu	a5,a1,8000109a <walkaddr+0xc>
    return 0;
    80001096:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001098:	8082                	ret
{
    8000109a:	1141                	addi	sp,sp,-16
    8000109c:	e406                	sd	ra,8(sp)
    8000109e:	e022                	sd	s0,0(sp)
    800010a0:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010a2:	4601                	li	a2,0
    800010a4:	00000097          	auipc	ra,0x0
    800010a8:	f44080e7          	jalr	-188(ra) # 80000fe8 <walk>
  if(pte == 0)
    800010ac:	c105                	beqz	a0,800010cc <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010ae:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010b0:	0117f693          	andi	a3,a5,17
    800010b4:	4745                	li	a4,17
    return 0;
    800010b6:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010b8:	00e68663          	beq	a3,a4,800010c4 <walkaddr+0x36>
}
    800010bc:	60a2                	ld	ra,8(sp)
    800010be:	6402                	ld	s0,0(sp)
    800010c0:	0141                	addi	sp,sp,16
    800010c2:	8082                	ret
  pa = PTE2PA(*pte);
    800010c4:	00a7d513          	srli	a0,a5,0xa
    800010c8:	0532                	slli	a0,a0,0xc
  return pa;
    800010ca:	bfcd                	j	800010bc <walkaddr+0x2e>
    return 0;
    800010cc:	4501                	li	a0,0
    800010ce:	b7fd                	j	800010bc <walkaddr+0x2e>

00000000800010d0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010d0:	715d                	addi	sp,sp,-80
    800010d2:	e486                	sd	ra,72(sp)
    800010d4:	e0a2                	sd	s0,64(sp)
    800010d6:	fc26                	sd	s1,56(sp)
    800010d8:	f84a                	sd	s2,48(sp)
    800010da:	f44e                	sd	s3,40(sp)
    800010dc:	f052                	sd	s4,32(sp)
    800010de:	ec56                	sd	s5,24(sp)
    800010e0:	e85a                	sd	s6,16(sp)
    800010e2:	e45e                	sd	s7,8(sp)
    800010e4:	0880                	addi	s0,sp,80
    800010e6:	8aaa                	mv	s5,a0
    800010e8:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010ea:	777d                	lui	a4,0xfffff
    800010ec:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010f0:	167d                	addi	a2,a2,-1
    800010f2:	00b609b3          	add	s3,a2,a1
    800010f6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010fa:	893e                	mv	s2,a5
    800010fc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001100:	6b85                	lui	s7,0x1
    80001102:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001106:	4605                	li	a2,1
    80001108:	85ca                	mv	a1,s2
    8000110a:	8556                	mv	a0,s5
    8000110c:	00000097          	auipc	ra,0x0
    80001110:	edc080e7          	jalr	-292(ra) # 80000fe8 <walk>
    80001114:	c51d                	beqz	a0,80001142 <mappages+0x72>
    if(*pte & PTE_V)
    80001116:	611c                	ld	a5,0(a0)
    80001118:	8b85                	andi	a5,a5,1
    8000111a:	ef81                	bnez	a5,80001132 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000111c:	80b1                	srli	s1,s1,0xc
    8000111e:	04aa                	slli	s1,s1,0xa
    80001120:	0164e4b3          	or	s1,s1,s6
    80001124:	0014e493          	ori	s1,s1,1
    80001128:	e104                	sd	s1,0(a0)
    if(a == last)
    8000112a:	03390863          	beq	s2,s3,8000115a <mappages+0x8a>
    a += PGSIZE;
    8000112e:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001130:	bfc9                	j	80001102 <mappages+0x32>
      panic("remap");
    80001132:	00007517          	auipc	a0,0x7
    80001136:	fa650513          	addi	a0,a0,-90 # 800080d8 <digits+0x98>
    8000113a:	fffff097          	auipc	ra,0xfffff
    8000113e:	3f0080e7          	jalr	1008(ra) # 8000052a <panic>
      return -1;
    80001142:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001144:	60a6                	ld	ra,72(sp)
    80001146:	6406                	ld	s0,64(sp)
    80001148:	74e2                	ld	s1,56(sp)
    8000114a:	7942                	ld	s2,48(sp)
    8000114c:	79a2                	ld	s3,40(sp)
    8000114e:	7a02                	ld	s4,32(sp)
    80001150:	6ae2                	ld	s5,24(sp)
    80001152:	6b42                	ld	s6,16(sp)
    80001154:	6ba2                	ld	s7,8(sp)
    80001156:	6161                	addi	sp,sp,80
    80001158:	8082                	ret
  return 0;
    8000115a:	4501                	li	a0,0
    8000115c:	b7e5                	j	80001144 <mappages+0x74>

000000008000115e <kvmmap>:
{
    8000115e:	1141                	addi	sp,sp,-16
    80001160:	e406                	sd	ra,8(sp)
    80001162:	e022                	sd	s0,0(sp)
    80001164:	0800                	addi	s0,sp,16
    80001166:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001168:	86b2                	mv	a3,a2
    8000116a:	863e                	mv	a2,a5
    8000116c:	00000097          	auipc	ra,0x0
    80001170:	f64080e7          	jalr	-156(ra) # 800010d0 <mappages>
    80001174:	e509                	bnez	a0,8000117e <kvmmap+0x20>
}
    80001176:	60a2                	ld	ra,8(sp)
    80001178:	6402                	ld	s0,0(sp)
    8000117a:	0141                	addi	sp,sp,16
    8000117c:	8082                	ret
    panic("kvmmap");
    8000117e:	00007517          	auipc	a0,0x7
    80001182:	f6250513          	addi	a0,a0,-158 # 800080e0 <digits+0xa0>
    80001186:	fffff097          	auipc	ra,0xfffff
    8000118a:	3a4080e7          	jalr	932(ra) # 8000052a <panic>

000000008000118e <kvmmake>:
{
    8000118e:	1101                	addi	sp,sp,-32
    80001190:	ec06                	sd	ra,24(sp)
    80001192:	e822                	sd	s0,16(sp)
    80001194:	e426                	sd	s1,8(sp)
    80001196:	e04a                	sd	s2,0(sp)
    80001198:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	938080e7          	jalr	-1736(ra) # 80000ad2 <kalloc>
    800011a2:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011a4:	6605                	lui	a2,0x1
    800011a6:	4581                	li	a1,0
    800011a8:	00000097          	auipc	ra,0x0
    800011ac:	b16080e7          	jalr	-1258(ra) # 80000cbe <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011b0:	4719                	li	a4,6
    800011b2:	6685                	lui	a3,0x1
    800011b4:	10000637          	lui	a2,0x10000
    800011b8:	100005b7          	lui	a1,0x10000
    800011bc:	8526                	mv	a0,s1
    800011be:	00000097          	auipc	ra,0x0
    800011c2:	fa0080e7          	jalr	-96(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c6:	4719                	li	a4,6
    800011c8:	6685                	lui	a3,0x1
    800011ca:	10001637          	lui	a2,0x10001
    800011ce:	100015b7          	lui	a1,0x10001
    800011d2:	8526                	mv	a0,s1
    800011d4:	00000097          	auipc	ra,0x0
    800011d8:	f8a080e7          	jalr	-118(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011dc:	4719                	li	a4,6
    800011de:	004006b7          	lui	a3,0x400
    800011e2:	0c000637          	lui	a2,0xc000
    800011e6:	0c0005b7          	lui	a1,0xc000
    800011ea:	8526                	mv	a0,s1
    800011ec:	00000097          	auipc	ra,0x0
    800011f0:	f72080e7          	jalr	-142(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011f4:	00007917          	auipc	s2,0x7
    800011f8:	e0c90913          	addi	s2,s2,-500 # 80008000 <etext>
    800011fc:	4729                	li	a4,10
    800011fe:	80007697          	auipc	a3,0x80007
    80001202:	e0268693          	addi	a3,a3,-510 # 8000 <_entry-0x7fff8000>
    80001206:	4605                	li	a2,1
    80001208:	067e                	slli	a2,a2,0x1f
    8000120a:	85b2                	mv	a1,a2
    8000120c:	8526                	mv	a0,s1
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	f50080e7          	jalr	-176(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001216:	4719                	li	a4,6
    80001218:	46c5                	li	a3,17
    8000121a:	06ee                	slli	a3,a3,0x1b
    8000121c:	412686b3          	sub	a3,a3,s2
    80001220:	864a                	mv	a2,s2
    80001222:	85ca                	mv	a1,s2
    80001224:	8526                	mv	a0,s1
    80001226:	00000097          	auipc	ra,0x0
    8000122a:	f38080e7          	jalr	-200(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000122e:	4729                	li	a4,10
    80001230:	6685                	lui	a3,0x1
    80001232:	00006617          	auipc	a2,0x6
    80001236:	dce60613          	addi	a2,a2,-562 # 80007000 <_trampoline>
    8000123a:	040005b7          	lui	a1,0x4000
    8000123e:	15fd                	addi	a1,a1,-1
    80001240:	05b2                	slli	a1,a1,0xc
    80001242:	8526                	mv	a0,s1
    80001244:	00000097          	auipc	ra,0x0
    80001248:	f1a080e7          	jalr	-230(ra) # 8000115e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000124c:	8526                	mv	a0,s1
    8000124e:	00000097          	auipc	ra,0x0
    80001252:	600080e7          	jalr	1536(ra) # 8000184e <proc_mapstacks>
}
    80001256:	8526                	mv	a0,s1
    80001258:	60e2                	ld	ra,24(sp)
    8000125a:	6442                	ld	s0,16(sp)
    8000125c:	64a2                	ld	s1,8(sp)
    8000125e:	6902                	ld	s2,0(sp)
    80001260:	6105                	addi	sp,sp,32
    80001262:	8082                	ret

0000000080001264 <kvminit>:
{
    80001264:	1141                	addi	sp,sp,-16
    80001266:	e406                	sd	ra,8(sp)
    80001268:	e022                	sd	s0,0(sp)
    8000126a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000126c:	00000097          	auipc	ra,0x0
    80001270:	f22080e7          	jalr	-222(ra) # 8000118e <kvmmake>
    80001274:	00008797          	auipc	a5,0x8
    80001278:	daa7b623          	sd	a0,-596(a5) # 80009020 <kernel_pagetable>
}
    8000127c:	60a2                	ld	ra,8(sp)
    8000127e:	6402                	ld	s0,0(sp)
    80001280:	0141                	addi	sp,sp,16
    80001282:	8082                	ret

0000000080001284 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001284:	715d                	addi	sp,sp,-80
    80001286:	e486                	sd	ra,72(sp)
    80001288:	e0a2                	sd	s0,64(sp)
    8000128a:	fc26                	sd	s1,56(sp)
    8000128c:	f84a                	sd	s2,48(sp)
    8000128e:	f44e                	sd	s3,40(sp)
    80001290:	f052                	sd	s4,32(sp)
    80001292:	ec56                	sd	s5,24(sp)
    80001294:	e85a                	sd	s6,16(sp)
    80001296:	e45e                	sd	s7,8(sp)
    80001298:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000129a:	03459793          	slli	a5,a1,0x34
    8000129e:	e795                	bnez	a5,800012ca <uvmunmap+0x46>
    800012a0:	8a2a                	mv	s4,a0
    800012a2:	892e                	mv	s2,a1
    800012a4:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a6:	0632                	slli	a2,a2,0xc
    800012a8:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012ac:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ae:	6b05                	lui	s6,0x1
    800012b0:	0735e263          	bltu	a1,s3,80001314 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012b4:	60a6                	ld	ra,72(sp)
    800012b6:	6406                	ld	s0,64(sp)
    800012b8:	74e2                	ld	s1,56(sp)
    800012ba:	7942                	ld	s2,48(sp)
    800012bc:	79a2                	ld	s3,40(sp)
    800012be:	7a02                	ld	s4,32(sp)
    800012c0:	6ae2                	ld	s5,24(sp)
    800012c2:	6b42                	ld	s6,16(sp)
    800012c4:	6ba2                	ld	s7,8(sp)
    800012c6:	6161                	addi	sp,sp,80
    800012c8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e1e50513          	addi	a0,a0,-482 # 800080e8 <digits+0xa8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	258080e7          	jalr	600(ra) # 8000052a <panic>
      panic("uvmunmap: walk");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e2650513          	addi	a0,a0,-474 # 80008100 <digits+0xc0>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	248080e7          	jalr	584(ra) # 8000052a <panic>
      panic("uvmunmap: not mapped");
    800012ea:	00007517          	auipc	a0,0x7
    800012ee:	e2650513          	addi	a0,a0,-474 # 80008110 <digits+0xd0>
    800012f2:	fffff097          	auipc	ra,0xfffff
    800012f6:	238080e7          	jalr	568(ra) # 8000052a <panic>
      panic("uvmunmap: not a leaf");
    800012fa:	00007517          	auipc	a0,0x7
    800012fe:	e2e50513          	addi	a0,a0,-466 # 80008128 <digits+0xe8>
    80001302:	fffff097          	auipc	ra,0xfffff
    80001306:	228080e7          	jalr	552(ra) # 8000052a <panic>
    *pte = 0;
    8000130a:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130e:	995a                	add	s2,s2,s6
    80001310:	fb3972e3          	bgeu	s2,s3,800012b4 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001314:	4601                	li	a2,0
    80001316:	85ca                	mv	a1,s2
    80001318:	8552                	mv	a0,s4
    8000131a:	00000097          	auipc	ra,0x0
    8000131e:	cce080e7          	jalr	-818(ra) # 80000fe8 <walk>
    80001322:	84aa                	mv	s1,a0
    80001324:	d95d                	beqz	a0,800012da <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001326:	6108                	ld	a0,0(a0)
    80001328:	00157793          	andi	a5,a0,1
    8000132c:	dfdd                	beqz	a5,800012ea <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132e:	3ff57793          	andi	a5,a0,1023
    80001332:	fd7784e3          	beq	a5,s7,800012fa <uvmunmap+0x76>
    if(do_free){
    80001336:	fc0a8ae3          	beqz	s5,8000130a <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000133a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000133c:	0532                	slli	a0,a0,0xc
    8000133e:	fffff097          	auipc	ra,0xfffff
    80001342:	698080e7          	jalr	1688(ra) # 800009d6 <kfree>
    80001346:	b7d1                	j	8000130a <uvmunmap+0x86>

0000000080001348 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001348:	1101                	addi	sp,sp,-32
    8000134a:	ec06                	sd	ra,24(sp)
    8000134c:	e822                	sd	s0,16(sp)
    8000134e:	e426                	sd	s1,8(sp)
    80001350:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001352:	fffff097          	auipc	ra,0xfffff
    80001356:	780080e7          	jalr	1920(ra) # 80000ad2 <kalloc>
    8000135a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000135c:	c519                	beqz	a0,8000136a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000135e:	6605                	lui	a2,0x1
    80001360:	4581                	li	a1,0
    80001362:	00000097          	auipc	ra,0x0
    80001366:	95c080e7          	jalr	-1700(ra) # 80000cbe <memset>
  return pagetable;
}
    8000136a:	8526                	mv	a0,s1
    8000136c:	60e2                	ld	ra,24(sp)
    8000136e:	6442                	ld	s0,16(sp)
    80001370:	64a2                	ld	s1,8(sp)
    80001372:	6105                	addi	sp,sp,32
    80001374:	8082                	ret

0000000080001376 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001376:	7179                	addi	sp,sp,-48
    80001378:	f406                	sd	ra,40(sp)
    8000137a:	f022                	sd	s0,32(sp)
    8000137c:	ec26                	sd	s1,24(sp)
    8000137e:	e84a                	sd	s2,16(sp)
    80001380:	e44e                	sd	s3,8(sp)
    80001382:	e052                	sd	s4,0(sp)
    80001384:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001386:	6785                	lui	a5,0x1
    80001388:	04f67863          	bgeu	a2,a5,800013d8 <uvminit+0x62>
    8000138c:	8a2a                	mv	s4,a0
    8000138e:	89ae                	mv	s3,a1
    80001390:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001392:	fffff097          	auipc	ra,0xfffff
    80001396:	740080e7          	jalr	1856(ra) # 80000ad2 <kalloc>
    8000139a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000139c:	6605                	lui	a2,0x1
    8000139e:	4581                	li	a1,0
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	91e080e7          	jalr	-1762(ra) # 80000cbe <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a8:	4779                	li	a4,30
    800013aa:	86ca                	mv	a3,s2
    800013ac:	6605                	lui	a2,0x1
    800013ae:	4581                	li	a1,0
    800013b0:	8552                	mv	a0,s4
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	d1e080e7          	jalr	-738(ra) # 800010d0 <mappages>
  memmove(mem, src, sz);
    800013ba:	8626                	mv	a2,s1
    800013bc:	85ce                	mv	a1,s3
    800013be:	854a                	mv	a0,s2
    800013c0:	00000097          	auipc	ra,0x0
    800013c4:	95a080e7          	jalr	-1702(ra) # 80000d1a <memmove>
}
    800013c8:	70a2                	ld	ra,40(sp)
    800013ca:	7402                	ld	s0,32(sp)
    800013cc:	64e2                	ld	s1,24(sp)
    800013ce:	6942                	ld	s2,16(sp)
    800013d0:	69a2                	ld	s3,8(sp)
    800013d2:	6a02                	ld	s4,0(sp)
    800013d4:	6145                	addi	sp,sp,48
    800013d6:	8082                	ret
    panic("inituvm: more than a page");
    800013d8:	00007517          	auipc	a0,0x7
    800013dc:	d6850513          	addi	a0,a0,-664 # 80008140 <digits+0x100>
    800013e0:	fffff097          	auipc	ra,0xfffff
    800013e4:	14a080e7          	jalr	330(ra) # 8000052a <panic>

00000000800013e8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e8:	1101                	addi	sp,sp,-32
    800013ea:	ec06                	sd	ra,24(sp)
    800013ec:	e822                	sd	s0,16(sp)
    800013ee:	e426                	sd	s1,8(sp)
    800013f0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013f2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013f4:	00b67d63          	bgeu	a2,a1,8000140e <uvmdealloc+0x26>
    800013f8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013fa:	6785                	lui	a5,0x1
    800013fc:	17fd                	addi	a5,a5,-1
    800013fe:	00f60733          	add	a4,a2,a5
    80001402:	767d                	lui	a2,0xfffff
    80001404:	8f71                	and	a4,a4,a2
    80001406:	97ae                	add	a5,a5,a1
    80001408:	8ff1                	and	a5,a5,a2
    8000140a:	00f76863          	bltu	a4,a5,8000141a <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000140e:	8526                	mv	a0,s1
    80001410:	60e2                	ld	ra,24(sp)
    80001412:	6442                	ld	s0,16(sp)
    80001414:	64a2                	ld	s1,8(sp)
    80001416:	6105                	addi	sp,sp,32
    80001418:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000141a:	8f99                	sub	a5,a5,a4
    8000141c:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000141e:	4685                	li	a3,1
    80001420:	0007861b          	sext.w	a2,a5
    80001424:	85ba                	mv	a1,a4
    80001426:	00000097          	auipc	ra,0x0
    8000142a:	e5e080e7          	jalr	-418(ra) # 80001284 <uvmunmap>
    8000142e:	b7c5                	j	8000140e <uvmdealloc+0x26>

0000000080001430 <uvmalloc>:
  if(newsz < oldsz)
    80001430:	0ab66163          	bltu	a2,a1,800014d2 <uvmalloc+0xa2>
{
    80001434:	7139                	addi	sp,sp,-64
    80001436:	fc06                	sd	ra,56(sp)
    80001438:	f822                	sd	s0,48(sp)
    8000143a:	f426                	sd	s1,40(sp)
    8000143c:	f04a                	sd	s2,32(sp)
    8000143e:	ec4e                	sd	s3,24(sp)
    80001440:	e852                	sd	s4,16(sp)
    80001442:	e456                	sd	s5,8(sp)
    80001444:	0080                	addi	s0,sp,64
    80001446:	8aaa                	mv	s5,a0
    80001448:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000144a:	6985                	lui	s3,0x1
    8000144c:	19fd                	addi	s3,s3,-1
    8000144e:	95ce                	add	a1,a1,s3
    80001450:	79fd                	lui	s3,0xfffff
    80001452:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001456:	08c9f063          	bgeu	s3,a2,800014d6 <uvmalloc+0xa6>
    8000145a:	894e                	mv	s2,s3
    mem = kalloc();
    8000145c:	fffff097          	auipc	ra,0xfffff
    80001460:	676080e7          	jalr	1654(ra) # 80000ad2 <kalloc>
    80001464:	84aa                	mv	s1,a0
    if(mem == 0){
    80001466:	c51d                	beqz	a0,80001494 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001468:	6605                	lui	a2,0x1
    8000146a:	4581                	li	a1,0
    8000146c:	00000097          	auipc	ra,0x0
    80001470:	852080e7          	jalr	-1966(ra) # 80000cbe <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001474:	4779                	li	a4,30
    80001476:	86a6                	mv	a3,s1
    80001478:	6605                	lui	a2,0x1
    8000147a:	85ca                	mv	a1,s2
    8000147c:	8556                	mv	a0,s5
    8000147e:	00000097          	auipc	ra,0x0
    80001482:	c52080e7          	jalr	-942(ra) # 800010d0 <mappages>
    80001486:	e905                	bnez	a0,800014b6 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001488:	6785                	lui	a5,0x1
    8000148a:	993e                	add	s2,s2,a5
    8000148c:	fd4968e3          	bltu	s2,s4,8000145c <uvmalloc+0x2c>
  return newsz;
    80001490:	8552                	mv	a0,s4
    80001492:	a809                	j	800014a4 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001494:	864e                	mv	a2,s3
    80001496:	85ca                	mv	a1,s2
    80001498:	8556                	mv	a0,s5
    8000149a:	00000097          	auipc	ra,0x0
    8000149e:	f4e080e7          	jalr	-178(ra) # 800013e8 <uvmdealloc>
      return 0;
    800014a2:	4501                	li	a0,0
}
    800014a4:	70e2                	ld	ra,56(sp)
    800014a6:	7442                	ld	s0,48(sp)
    800014a8:	74a2                	ld	s1,40(sp)
    800014aa:	7902                	ld	s2,32(sp)
    800014ac:	69e2                	ld	s3,24(sp)
    800014ae:	6a42                	ld	s4,16(sp)
    800014b0:	6aa2                	ld	s5,8(sp)
    800014b2:	6121                	addi	sp,sp,64
    800014b4:	8082                	ret
      kfree(mem);
    800014b6:	8526                	mv	a0,s1
    800014b8:	fffff097          	auipc	ra,0xfffff
    800014bc:	51e080e7          	jalr	1310(ra) # 800009d6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014c0:	864e                	mv	a2,s3
    800014c2:	85ca                	mv	a1,s2
    800014c4:	8556                	mv	a0,s5
    800014c6:	00000097          	auipc	ra,0x0
    800014ca:	f22080e7          	jalr	-222(ra) # 800013e8 <uvmdealloc>
      return 0;
    800014ce:	4501                	li	a0,0
    800014d0:	bfd1                	j	800014a4 <uvmalloc+0x74>
    return oldsz;
    800014d2:	852e                	mv	a0,a1
}
    800014d4:	8082                	ret
  return newsz;
    800014d6:	8532                	mv	a0,a2
    800014d8:	b7f1                	j	800014a4 <uvmalloc+0x74>

00000000800014da <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014da:	7179                	addi	sp,sp,-48
    800014dc:	f406                	sd	ra,40(sp)
    800014de:	f022                	sd	s0,32(sp)
    800014e0:	ec26                	sd	s1,24(sp)
    800014e2:	e84a                	sd	s2,16(sp)
    800014e4:	e44e                	sd	s3,8(sp)
    800014e6:	e052                	sd	s4,0(sp)
    800014e8:	1800                	addi	s0,sp,48
    800014ea:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014ec:	84aa                	mv	s1,a0
    800014ee:	6905                	lui	s2,0x1
    800014f0:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f2:	4985                	li	s3,1
    800014f4:	a821                	j	8000150c <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014f6:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014f8:	0532                	slli	a0,a0,0xc
    800014fa:	00000097          	auipc	ra,0x0
    800014fe:	fe0080e7          	jalr	-32(ra) # 800014da <freewalk>
      pagetable[i] = 0;
    80001502:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001506:	04a1                	addi	s1,s1,8
    80001508:	03248163          	beq	s1,s2,8000152a <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000150c:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000150e:	00f57793          	andi	a5,a0,15
    80001512:	ff3782e3          	beq	a5,s3,800014f6 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001516:	8905                	andi	a0,a0,1
    80001518:	d57d                	beqz	a0,80001506 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000151a:	00007517          	auipc	a0,0x7
    8000151e:	c4650513          	addi	a0,a0,-954 # 80008160 <digits+0x120>
    80001522:	fffff097          	auipc	ra,0xfffff
    80001526:	008080e7          	jalr	8(ra) # 8000052a <panic>
    }
  }
  kfree((void*)pagetable);
    8000152a:	8552                	mv	a0,s4
    8000152c:	fffff097          	auipc	ra,0xfffff
    80001530:	4aa080e7          	jalr	1194(ra) # 800009d6 <kfree>
}
    80001534:	70a2                	ld	ra,40(sp)
    80001536:	7402                	ld	s0,32(sp)
    80001538:	64e2                	ld	s1,24(sp)
    8000153a:	6942                	ld	s2,16(sp)
    8000153c:	69a2                	ld	s3,8(sp)
    8000153e:	6a02                	ld	s4,0(sp)
    80001540:	6145                	addi	sp,sp,48
    80001542:	8082                	ret

0000000080001544 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001544:	1101                	addi	sp,sp,-32
    80001546:	ec06                	sd	ra,24(sp)
    80001548:	e822                	sd	s0,16(sp)
    8000154a:	e426                	sd	s1,8(sp)
    8000154c:	1000                	addi	s0,sp,32
    8000154e:	84aa                	mv	s1,a0
  if(sz > 0)
    80001550:	e999                	bnez	a1,80001566 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001552:	8526                	mv	a0,s1
    80001554:	00000097          	auipc	ra,0x0
    80001558:	f86080e7          	jalr	-122(ra) # 800014da <freewalk>
}
    8000155c:	60e2                	ld	ra,24(sp)
    8000155e:	6442                	ld	s0,16(sp)
    80001560:	64a2                	ld	s1,8(sp)
    80001562:	6105                	addi	sp,sp,32
    80001564:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001566:	6605                	lui	a2,0x1
    80001568:	167d                	addi	a2,a2,-1
    8000156a:	962e                	add	a2,a2,a1
    8000156c:	4685                	li	a3,1
    8000156e:	8231                	srli	a2,a2,0xc
    80001570:	4581                	li	a1,0
    80001572:	00000097          	auipc	ra,0x0
    80001576:	d12080e7          	jalr	-750(ra) # 80001284 <uvmunmap>
    8000157a:	bfe1                	j	80001552 <uvmfree+0xe>

000000008000157c <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000157c:	c679                	beqz	a2,8000164a <uvmcopy+0xce>
{
    8000157e:	715d                	addi	sp,sp,-80
    80001580:	e486                	sd	ra,72(sp)
    80001582:	e0a2                	sd	s0,64(sp)
    80001584:	fc26                	sd	s1,56(sp)
    80001586:	f84a                	sd	s2,48(sp)
    80001588:	f44e                	sd	s3,40(sp)
    8000158a:	f052                	sd	s4,32(sp)
    8000158c:	ec56                	sd	s5,24(sp)
    8000158e:	e85a                	sd	s6,16(sp)
    80001590:	e45e                	sd	s7,8(sp)
    80001592:	0880                	addi	s0,sp,80
    80001594:	8b2a                	mv	s6,a0
    80001596:	8aae                	mv	s5,a1
    80001598:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000159a:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000159c:	4601                	li	a2,0
    8000159e:	85ce                	mv	a1,s3
    800015a0:	855a                	mv	a0,s6
    800015a2:	00000097          	auipc	ra,0x0
    800015a6:	a46080e7          	jalr	-1466(ra) # 80000fe8 <walk>
    800015aa:	c531                	beqz	a0,800015f6 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015ac:	6118                	ld	a4,0(a0)
    800015ae:	00177793          	andi	a5,a4,1
    800015b2:	cbb1                	beqz	a5,80001606 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015b4:	00a75593          	srli	a1,a4,0xa
    800015b8:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015bc:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015c0:	fffff097          	auipc	ra,0xfffff
    800015c4:	512080e7          	jalr	1298(ra) # 80000ad2 <kalloc>
    800015c8:	892a                	mv	s2,a0
    800015ca:	c939                	beqz	a0,80001620 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015cc:	6605                	lui	a2,0x1
    800015ce:	85de                	mv	a1,s7
    800015d0:	fffff097          	auipc	ra,0xfffff
    800015d4:	74a080e7          	jalr	1866(ra) # 80000d1a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015d8:	8726                	mv	a4,s1
    800015da:	86ca                	mv	a3,s2
    800015dc:	6605                	lui	a2,0x1
    800015de:	85ce                	mv	a1,s3
    800015e0:	8556                	mv	a0,s5
    800015e2:	00000097          	auipc	ra,0x0
    800015e6:	aee080e7          	jalr	-1298(ra) # 800010d0 <mappages>
    800015ea:	e515                	bnez	a0,80001616 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015ec:	6785                	lui	a5,0x1
    800015ee:	99be                	add	s3,s3,a5
    800015f0:	fb49e6e3          	bltu	s3,s4,8000159c <uvmcopy+0x20>
    800015f4:	a081                	j	80001634 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015f6:	00007517          	auipc	a0,0x7
    800015fa:	b7a50513          	addi	a0,a0,-1158 # 80008170 <digits+0x130>
    800015fe:	fffff097          	auipc	ra,0xfffff
    80001602:	f2c080e7          	jalr	-212(ra) # 8000052a <panic>
      panic("uvmcopy: page not present");
    80001606:	00007517          	auipc	a0,0x7
    8000160a:	b8a50513          	addi	a0,a0,-1142 # 80008190 <digits+0x150>
    8000160e:	fffff097          	auipc	ra,0xfffff
    80001612:	f1c080e7          	jalr	-228(ra) # 8000052a <panic>
      kfree(mem);
    80001616:	854a                	mv	a0,s2
    80001618:	fffff097          	auipc	ra,0xfffff
    8000161c:	3be080e7          	jalr	958(ra) # 800009d6 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001620:	4685                	li	a3,1
    80001622:	00c9d613          	srli	a2,s3,0xc
    80001626:	4581                	li	a1,0
    80001628:	8556                	mv	a0,s5
    8000162a:	00000097          	auipc	ra,0x0
    8000162e:	c5a080e7          	jalr	-934(ra) # 80001284 <uvmunmap>
  return -1;
    80001632:	557d                	li	a0,-1
}
    80001634:	60a6                	ld	ra,72(sp)
    80001636:	6406                	ld	s0,64(sp)
    80001638:	74e2                	ld	s1,56(sp)
    8000163a:	7942                	ld	s2,48(sp)
    8000163c:	79a2                	ld	s3,40(sp)
    8000163e:	7a02                	ld	s4,32(sp)
    80001640:	6ae2                	ld	s5,24(sp)
    80001642:	6b42                	ld	s6,16(sp)
    80001644:	6ba2                	ld	s7,8(sp)
    80001646:	6161                	addi	sp,sp,80
    80001648:	8082                	ret
  return 0;
    8000164a:	4501                	li	a0,0
}
    8000164c:	8082                	ret

000000008000164e <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000164e:	1141                	addi	sp,sp,-16
    80001650:	e406                	sd	ra,8(sp)
    80001652:	e022                	sd	s0,0(sp)
    80001654:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001656:	4601                	li	a2,0
    80001658:	00000097          	auipc	ra,0x0
    8000165c:	990080e7          	jalr	-1648(ra) # 80000fe8 <walk>
  if(pte == 0)
    80001660:	c901                	beqz	a0,80001670 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001662:	611c                	ld	a5,0(a0)
    80001664:	9bbd                	andi	a5,a5,-17
    80001666:	e11c                	sd	a5,0(a0)
}
    80001668:	60a2                	ld	ra,8(sp)
    8000166a:	6402                	ld	s0,0(sp)
    8000166c:	0141                	addi	sp,sp,16
    8000166e:	8082                	ret
    panic("uvmclear");
    80001670:	00007517          	auipc	a0,0x7
    80001674:	b4050513          	addi	a0,a0,-1216 # 800081b0 <digits+0x170>
    80001678:	fffff097          	auipc	ra,0xfffff
    8000167c:	eb2080e7          	jalr	-334(ra) # 8000052a <panic>

0000000080001680 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001680:	c6bd                	beqz	a3,800016ee <copyout+0x6e>
{
    80001682:	715d                	addi	sp,sp,-80
    80001684:	e486                	sd	ra,72(sp)
    80001686:	e0a2                	sd	s0,64(sp)
    80001688:	fc26                	sd	s1,56(sp)
    8000168a:	f84a                	sd	s2,48(sp)
    8000168c:	f44e                	sd	s3,40(sp)
    8000168e:	f052                	sd	s4,32(sp)
    80001690:	ec56                	sd	s5,24(sp)
    80001692:	e85a                	sd	s6,16(sp)
    80001694:	e45e                	sd	s7,8(sp)
    80001696:	e062                	sd	s8,0(sp)
    80001698:	0880                	addi	s0,sp,80
    8000169a:	8b2a                	mv	s6,a0
    8000169c:	8c2e                	mv	s8,a1
    8000169e:	8a32                	mv	s4,a2
    800016a0:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016a2:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016a4:	6a85                	lui	s5,0x1
    800016a6:	a015                	j	800016ca <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016a8:	9562                	add	a0,a0,s8
    800016aa:	0004861b          	sext.w	a2,s1
    800016ae:	85d2                	mv	a1,s4
    800016b0:	41250533          	sub	a0,a0,s2
    800016b4:	fffff097          	auipc	ra,0xfffff
    800016b8:	666080e7          	jalr	1638(ra) # 80000d1a <memmove>

    len -= n;
    800016bc:	409989b3          	sub	s3,s3,s1
    src += n;
    800016c0:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016c2:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016c6:	02098263          	beqz	s3,800016ea <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ca:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ce:	85ca                	mv	a1,s2
    800016d0:	855a                	mv	a0,s6
    800016d2:	00000097          	auipc	ra,0x0
    800016d6:	9bc080e7          	jalr	-1604(ra) # 8000108e <walkaddr>
    if(pa0 == 0)
    800016da:	cd01                	beqz	a0,800016f2 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016dc:	418904b3          	sub	s1,s2,s8
    800016e0:	94d6                	add	s1,s1,s5
    if(n > len)
    800016e2:	fc99f3e3          	bgeu	s3,s1,800016a8 <copyout+0x28>
    800016e6:	84ce                	mv	s1,s3
    800016e8:	b7c1                	j	800016a8 <copyout+0x28>
  }
  return 0;
    800016ea:	4501                	li	a0,0
    800016ec:	a021                	j	800016f4 <copyout+0x74>
    800016ee:	4501                	li	a0,0
}
    800016f0:	8082                	ret
      return -1;
    800016f2:	557d                	li	a0,-1
}
    800016f4:	60a6                	ld	ra,72(sp)
    800016f6:	6406                	ld	s0,64(sp)
    800016f8:	74e2                	ld	s1,56(sp)
    800016fa:	7942                	ld	s2,48(sp)
    800016fc:	79a2                	ld	s3,40(sp)
    800016fe:	7a02                	ld	s4,32(sp)
    80001700:	6ae2                	ld	s5,24(sp)
    80001702:	6b42                	ld	s6,16(sp)
    80001704:	6ba2                	ld	s7,8(sp)
    80001706:	6c02                	ld	s8,0(sp)
    80001708:	6161                	addi	sp,sp,80
    8000170a:	8082                	ret

000000008000170c <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000170c:	caa5                	beqz	a3,8000177c <copyin+0x70>
{
    8000170e:	715d                	addi	sp,sp,-80
    80001710:	e486                	sd	ra,72(sp)
    80001712:	e0a2                	sd	s0,64(sp)
    80001714:	fc26                	sd	s1,56(sp)
    80001716:	f84a                	sd	s2,48(sp)
    80001718:	f44e                	sd	s3,40(sp)
    8000171a:	f052                	sd	s4,32(sp)
    8000171c:	ec56                	sd	s5,24(sp)
    8000171e:	e85a                	sd	s6,16(sp)
    80001720:	e45e                	sd	s7,8(sp)
    80001722:	e062                	sd	s8,0(sp)
    80001724:	0880                	addi	s0,sp,80
    80001726:	8b2a                	mv	s6,a0
    80001728:	8a2e                	mv	s4,a1
    8000172a:	8c32                	mv	s8,a2
    8000172c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000172e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001730:	6a85                	lui	s5,0x1
    80001732:	a01d                	j	80001758 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001734:	018505b3          	add	a1,a0,s8
    80001738:	0004861b          	sext.w	a2,s1
    8000173c:	412585b3          	sub	a1,a1,s2
    80001740:	8552                	mv	a0,s4
    80001742:	fffff097          	auipc	ra,0xfffff
    80001746:	5d8080e7          	jalr	1496(ra) # 80000d1a <memmove>

    len -= n;
    8000174a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000174e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001750:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001754:	02098263          	beqz	s3,80001778 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001758:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000175c:	85ca                	mv	a1,s2
    8000175e:	855a                	mv	a0,s6
    80001760:	00000097          	auipc	ra,0x0
    80001764:	92e080e7          	jalr	-1746(ra) # 8000108e <walkaddr>
    if(pa0 == 0)
    80001768:	cd01                	beqz	a0,80001780 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000176a:	418904b3          	sub	s1,s2,s8
    8000176e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001770:	fc99f2e3          	bgeu	s3,s1,80001734 <copyin+0x28>
    80001774:	84ce                	mv	s1,s3
    80001776:	bf7d                	j	80001734 <copyin+0x28>
  }
  return 0;
    80001778:	4501                	li	a0,0
    8000177a:	a021                	j	80001782 <copyin+0x76>
    8000177c:	4501                	li	a0,0
}
    8000177e:	8082                	ret
      return -1;
    80001780:	557d                	li	a0,-1
}
    80001782:	60a6                	ld	ra,72(sp)
    80001784:	6406                	ld	s0,64(sp)
    80001786:	74e2                	ld	s1,56(sp)
    80001788:	7942                	ld	s2,48(sp)
    8000178a:	79a2                	ld	s3,40(sp)
    8000178c:	7a02                	ld	s4,32(sp)
    8000178e:	6ae2                	ld	s5,24(sp)
    80001790:	6b42                	ld	s6,16(sp)
    80001792:	6ba2                	ld	s7,8(sp)
    80001794:	6c02                	ld	s8,0(sp)
    80001796:	6161                	addi	sp,sp,80
    80001798:	8082                	ret

000000008000179a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000179a:	c6c5                	beqz	a3,80001842 <copyinstr+0xa8>
{
    8000179c:	715d                	addi	sp,sp,-80
    8000179e:	e486                	sd	ra,72(sp)
    800017a0:	e0a2                	sd	s0,64(sp)
    800017a2:	fc26                	sd	s1,56(sp)
    800017a4:	f84a                	sd	s2,48(sp)
    800017a6:	f44e                	sd	s3,40(sp)
    800017a8:	f052                	sd	s4,32(sp)
    800017aa:	ec56                	sd	s5,24(sp)
    800017ac:	e85a                	sd	s6,16(sp)
    800017ae:	e45e                	sd	s7,8(sp)
    800017b0:	0880                	addi	s0,sp,80
    800017b2:	8a2a                	mv	s4,a0
    800017b4:	8b2e                	mv	s6,a1
    800017b6:	8bb2                	mv	s7,a2
    800017b8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017ba:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017bc:	6985                	lui	s3,0x1
    800017be:	a035                	j	800017ea <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017c0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017c4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017c6:	0017b793          	seqz	a5,a5
    800017ca:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017ce:	60a6                	ld	ra,72(sp)
    800017d0:	6406                	ld	s0,64(sp)
    800017d2:	74e2                	ld	s1,56(sp)
    800017d4:	7942                	ld	s2,48(sp)
    800017d6:	79a2                	ld	s3,40(sp)
    800017d8:	7a02                	ld	s4,32(sp)
    800017da:	6ae2                	ld	s5,24(sp)
    800017dc:	6b42                	ld	s6,16(sp)
    800017de:	6ba2                	ld	s7,8(sp)
    800017e0:	6161                	addi	sp,sp,80
    800017e2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017e4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017e8:	c8a9                	beqz	s1,8000183a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017ea:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017ee:	85ca                	mv	a1,s2
    800017f0:	8552                	mv	a0,s4
    800017f2:	00000097          	auipc	ra,0x0
    800017f6:	89c080e7          	jalr	-1892(ra) # 8000108e <walkaddr>
    if(pa0 == 0)
    800017fa:	c131                	beqz	a0,8000183e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017fc:	41790833          	sub	a6,s2,s7
    80001800:	984e                	add	a6,a6,s3
    if(n > max)
    80001802:	0104f363          	bgeu	s1,a6,80001808 <copyinstr+0x6e>
    80001806:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001808:	955e                	add	a0,a0,s7
    8000180a:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000180e:	fc080be3          	beqz	a6,800017e4 <copyinstr+0x4a>
    80001812:	985a                	add	a6,a6,s6
    80001814:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001816:	41650633          	sub	a2,a0,s6
    8000181a:	14fd                	addi	s1,s1,-1
    8000181c:	9b26                	add	s6,s6,s1
    8000181e:	00f60733          	add	a4,a2,a5
    80001822:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    80001826:	df49                	beqz	a4,800017c0 <copyinstr+0x26>
        *dst = *p;
    80001828:	00e78023          	sb	a4,0(a5)
      --max;
    8000182c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001830:	0785                	addi	a5,a5,1
    while(n > 0){
    80001832:	ff0796e3          	bne	a5,a6,8000181e <copyinstr+0x84>
      dst++;
    80001836:	8b42                	mv	s6,a6
    80001838:	b775                	j	800017e4 <copyinstr+0x4a>
    8000183a:	4781                	li	a5,0
    8000183c:	b769                	j	800017c6 <copyinstr+0x2c>
      return -1;
    8000183e:	557d                	li	a0,-1
    80001840:	b779                	j	800017ce <copyinstr+0x34>
  int got_null = 0;
    80001842:	4781                	li	a5,0
  if(got_null){
    80001844:	0017b793          	seqz	a5,a5
    80001848:	40f00533          	neg	a0,a5
}
    8000184c:	8082                	ret

000000008000184e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000184e:	7139                	addi	sp,sp,-64
    80001850:	fc06                	sd	ra,56(sp)
    80001852:	f822                	sd	s0,48(sp)
    80001854:	f426                	sd	s1,40(sp)
    80001856:	f04a                	sd	s2,32(sp)
    80001858:	ec4e                	sd	s3,24(sp)
    8000185a:	e852                	sd	s4,16(sp)
    8000185c:	e456                	sd	s5,8(sp)
    8000185e:	e05a                	sd	s6,0(sp)
    80001860:	0080                	addi	s0,sp,64
    80001862:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001864:	00010497          	auipc	s1,0x10
    80001868:	e6c48493          	addi	s1,s1,-404 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000186c:	8b26                	mv	s6,s1
    8000186e:	00006a97          	auipc	s5,0x6
    80001872:	792a8a93          	addi	s5,s5,1938 # 80008000 <etext>
    80001876:	04000937          	lui	s2,0x4000
    8000187a:	197d                	addi	s2,s2,-1
    8000187c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000187e:	00016a17          	auipc	s4,0x16
    80001882:	852a0a13          	addi	s4,s4,-1966 # 800170d0 <tickslock>
    char *pa = kalloc();
    80001886:	fffff097          	auipc	ra,0xfffff
    8000188a:	24c080e7          	jalr	588(ra) # 80000ad2 <kalloc>
    8000188e:	862a                	mv	a2,a0
    if(pa == 0)
    80001890:	c131                	beqz	a0,800018d4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001892:	416485b3          	sub	a1,s1,s6
    80001896:	858d                	srai	a1,a1,0x3
    80001898:	000ab783          	ld	a5,0(s5)
    8000189c:	02f585b3          	mul	a1,a1,a5
    800018a0:	2585                	addiw	a1,a1,1
    800018a2:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018a6:	4719                	li	a4,6
    800018a8:	6685                	lui	a3,0x1
    800018aa:	40b905b3          	sub	a1,s2,a1
    800018ae:	854e                	mv	a0,s3
    800018b0:	00000097          	auipc	ra,0x0
    800018b4:	8ae080e7          	jalr	-1874(ra) # 8000115e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018b8:	16848493          	addi	s1,s1,360
    800018bc:	fd4495e3          	bne	s1,s4,80001886 <proc_mapstacks+0x38>
  }
}
    800018c0:	70e2                	ld	ra,56(sp)
    800018c2:	7442                	ld	s0,48(sp)
    800018c4:	74a2                	ld	s1,40(sp)
    800018c6:	7902                	ld	s2,32(sp)
    800018c8:	69e2                	ld	s3,24(sp)
    800018ca:	6a42                	ld	s4,16(sp)
    800018cc:	6aa2                	ld	s5,8(sp)
    800018ce:	6b02                	ld	s6,0(sp)
    800018d0:	6121                	addi	sp,sp,64
    800018d2:	8082                	ret
      panic("kalloc");
    800018d4:	00007517          	auipc	a0,0x7
    800018d8:	8ec50513          	addi	a0,a0,-1812 # 800081c0 <digits+0x180>
    800018dc:	fffff097          	auipc	ra,0xfffff
    800018e0:	c4e080e7          	jalr	-946(ra) # 8000052a <panic>

00000000800018e4 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018e4:	7139                	addi	sp,sp,-64
    800018e6:	fc06                	sd	ra,56(sp)
    800018e8:	f822                	sd	s0,48(sp)
    800018ea:	f426                	sd	s1,40(sp)
    800018ec:	f04a                	sd	s2,32(sp)
    800018ee:	ec4e                	sd	s3,24(sp)
    800018f0:	e852                	sd	s4,16(sp)
    800018f2:	e456                	sd	s5,8(sp)
    800018f4:	e05a                	sd	s6,0(sp)
    800018f6:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8d058593          	addi	a1,a1,-1840 # 800081c8 <digits+0x188>
    80001900:	00010517          	auipc	a0,0x10
    80001904:	9a050513          	addi	a0,a0,-1632 # 800112a0 <pid_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	22a080e7          	jalr	554(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001910:	00007597          	auipc	a1,0x7
    80001914:	8c058593          	addi	a1,a1,-1856 # 800081d0 <digits+0x190>
    80001918:	00010517          	auipc	a0,0x10
    8000191c:	9a050513          	addi	a0,a0,-1632 # 800112b8 <wait_lock>
    80001920:	fffff097          	auipc	ra,0xfffff
    80001924:	212080e7          	jalr	530(ra) # 80000b32 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001928:	00010497          	auipc	s1,0x10
    8000192c:	da848493          	addi	s1,s1,-600 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001930:	00007b17          	auipc	s6,0x7
    80001934:	8b0b0b13          	addi	s6,s6,-1872 # 800081e0 <digits+0x1a0>
      p->kstack = KSTACK((int) (p - proc));
    80001938:	8aa6                	mv	s5,s1
    8000193a:	00006a17          	auipc	s4,0x6
    8000193e:	6c6a0a13          	addi	s4,s4,1734 # 80008000 <etext>
    80001942:	04000937          	lui	s2,0x4000
    80001946:	197d                	addi	s2,s2,-1
    80001948:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194a:	00015997          	auipc	s3,0x15
    8000194e:	78698993          	addi	s3,s3,1926 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001952:	85da                	mv	a1,s6
    80001954:	8526                	mv	a0,s1
    80001956:	fffff097          	auipc	ra,0xfffff
    8000195a:	1dc080e7          	jalr	476(ra) # 80000b32 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000195e:	415487b3          	sub	a5,s1,s5
    80001962:	878d                	srai	a5,a5,0x3
    80001964:	000a3703          	ld	a4,0(s4)
    80001968:	02e787b3          	mul	a5,a5,a4
    8000196c:	2785                	addiw	a5,a5,1
    8000196e:	00d7979b          	slliw	a5,a5,0xd
    80001972:	40f907b3          	sub	a5,s2,a5
    80001976:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001978:	16848493          	addi	s1,s1,360
    8000197c:	fd349be3          	bne	s1,s3,80001952 <procinit+0x6e>
  }
}
    80001980:	70e2                	ld	ra,56(sp)
    80001982:	7442                	ld	s0,48(sp)
    80001984:	74a2                	ld	s1,40(sp)
    80001986:	7902                	ld	s2,32(sp)
    80001988:	69e2                	ld	s3,24(sp)
    8000198a:	6a42                	ld	s4,16(sp)
    8000198c:	6aa2                	ld	s5,8(sp)
    8000198e:	6b02                	ld	s6,0(sp)
    80001990:	6121                	addi	sp,sp,64
    80001992:	8082                	ret

0000000080001994 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001994:	1141                	addi	sp,sp,-16
    80001996:	e422                	sd	s0,8(sp)
    80001998:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000199a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000199c:	2501                	sext.w	a0,a0
    8000199e:	6422                	ld	s0,8(sp)
    800019a0:	0141                	addi	sp,sp,16
    800019a2:	8082                	ret

00000000800019a4 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800019a4:	1141                	addi	sp,sp,-16
    800019a6:	e422                	sd	s0,8(sp)
    800019a8:	0800                	addi	s0,sp,16
    800019aa:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019ac:	2781                	sext.w	a5,a5
    800019ae:	079e                	slli	a5,a5,0x7
  return c;
}
    800019b0:	00010517          	auipc	a0,0x10
    800019b4:	92050513          	addi	a0,a0,-1760 # 800112d0 <cpus>
    800019b8:	953e                	add	a0,a0,a5
    800019ba:	6422                	ld	s0,8(sp)
    800019bc:	0141                	addi	sp,sp,16
    800019be:	8082                	ret

00000000800019c0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019c0:	1101                	addi	sp,sp,-32
    800019c2:	ec06                	sd	ra,24(sp)
    800019c4:	e822                	sd	s0,16(sp)
    800019c6:	e426                	sd	s1,8(sp)
    800019c8:	1000                	addi	s0,sp,32
  push_off();
    800019ca:	fffff097          	auipc	ra,0xfffff
    800019ce:	1ac080e7          	jalr	428(ra) # 80000b76 <push_off>
    800019d2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019d4:	2781                	sext.w	a5,a5
    800019d6:	079e                	slli	a5,a5,0x7
    800019d8:	00010717          	auipc	a4,0x10
    800019dc:	8c870713          	addi	a4,a4,-1848 # 800112a0 <pid_lock>
    800019e0:	97ba                	add	a5,a5,a4
    800019e2:	7b84                	ld	s1,48(a5)
  pop_off();
    800019e4:	fffff097          	auipc	ra,0xfffff
    800019e8:	232080e7          	jalr	562(ra) # 80000c16 <pop_off>
  return p;
}
    800019ec:	8526                	mv	a0,s1
    800019ee:	60e2                	ld	ra,24(sp)
    800019f0:	6442                	ld	s0,16(sp)
    800019f2:	64a2                	ld	s1,8(sp)
    800019f4:	6105                	addi	sp,sp,32
    800019f6:	8082                	ret

00000000800019f8 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019f8:	1141                	addi	sp,sp,-16
    800019fa:	e406                	sd	ra,8(sp)
    800019fc:	e022                	sd	s0,0(sp)
    800019fe:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a00:	00000097          	auipc	ra,0x0
    80001a04:	fc0080e7          	jalr	-64(ra) # 800019c0 <myproc>
    80001a08:	fffff097          	auipc	ra,0xfffff
    80001a0c:	26e080e7          	jalr	622(ra) # 80000c76 <release>

  if (first) {
    80001a10:	00007797          	auipc	a5,0x7
    80001a14:	df07a783          	lw	a5,-528(a5) # 80008800 <first.1>
    80001a18:	eb89                	bnez	a5,80001a2a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a1a:	00001097          	auipc	ra,0x1
    80001a1e:	c0e080e7          	jalr	-1010(ra) # 80002628 <usertrapret>
}
    80001a22:	60a2                	ld	ra,8(sp)
    80001a24:	6402                	ld	s0,0(sp)
    80001a26:	0141                	addi	sp,sp,16
    80001a28:	8082                	ret
    first = 0;
    80001a2a:	00007797          	auipc	a5,0x7
    80001a2e:	dc07ab23          	sw	zero,-554(a5) # 80008800 <first.1>
    fsinit(ROOTDEV);
    80001a32:	4505                	li	a0,1
    80001a34:	00002097          	auipc	ra,0x2
    80001a38:	a0c080e7          	jalr	-1524(ra) # 80003440 <fsinit>
    80001a3c:	bff9                	j	80001a1a <forkret+0x22>

0000000080001a3e <allocpid>:
allocpid() {
    80001a3e:	1101                	addi	sp,sp,-32
    80001a40:	ec06                	sd	ra,24(sp)
    80001a42:	e822                	sd	s0,16(sp)
    80001a44:	e426                	sd	s1,8(sp)
    80001a46:	e04a                	sd	s2,0(sp)
    80001a48:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a4a:	00010917          	auipc	s2,0x10
    80001a4e:	85690913          	addi	s2,s2,-1962 # 800112a0 <pid_lock>
    80001a52:	854a                	mv	a0,s2
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	16e080e7          	jalr	366(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001a5c:	00007797          	auipc	a5,0x7
    80001a60:	da878793          	addi	a5,a5,-600 # 80008804 <nextpid>
    80001a64:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a66:	0014871b          	addiw	a4,s1,1
    80001a6a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a6c:	854a                	mv	a0,s2
    80001a6e:	fffff097          	auipc	ra,0xfffff
    80001a72:	208080e7          	jalr	520(ra) # 80000c76 <release>
}
    80001a76:	8526                	mv	a0,s1
    80001a78:	60e2                	ld	ra,24(sp)
    80001a7a:	6442                	ld	s0,16(sp)
    80001a7c:	64a2                	ld	s1,8(sp)
    80001a7e:	6902                	ld	s2,0(sp)
    80001a80:	6105                	addi	sp,sp,32
    80001a82:	8082                	ret

0000000080001a84 <proc_pagetable>:
{
    80001a84:	1101                	addi	sp,sp,-32
    80001a86:	ec06                	sd	ra,24(sp)
    80001a88:	e822                	sd	s0,16(sp)
    80001a8a:	e426                	sd	s1,8(sp)
    80001a8c:	e04a                	sd	s2,0(sp)
    80001a8e:	1000                	addi	s0,sp,32
    80001a90:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a92:	00000097          	auipc	ra,0x0
    80001a96:	8b6080e7          	jalr	-1866(ra) # 80001348 <uvmcreate>
    80001a9a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a9c:	c121                	beqz	a0,80001adc <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a9e:	4729                	li	a4,10
    80001aa0:	00005697          	auipc	a3,0x5
    80001aa4:	56068693          	addi	a3,a3,1376 # 80007000 <_trampoline>
    80001aa8:	6605                	lui	a2,0x1
    80001aaa:	040005b7          	lui	a1,0x4000
    80001aae:	15fd                	addi	a1,a1,-1
    80001ab0:	05b2                	slli	a1,a1,0xc
    80001ab2:	fffff097          	auipc	ra,0xfffff
    80001ab6:	61e080e7          	jalr	1566(ra) # 800010d0 <mappages>
    80001aba:	02054863          	bltz	a0,80001aea <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001abe:	4719                	li	a4,6
    80001ac0:	05893683          	ld	a3,88(s2)
    80001ac4:	6605                	lui	a2,0x1
    80001ac6:	020005b7          	lui	a1,0x2000
    80001aca:	15fd                	addi	a1,a1,-1
    80001acc:	05b6                	slli	a1,a1,0xd
    80001ace:	8526                	mv	a0,s1
    80001ad0:	fffff097          	auipc	ra,0xfffff
    80001ad4:	600080e7          	jalr	1536(ra) # 800010d0 <mappages>
    80001ad8:	02054163          	bltz	a0,80001afa <proc_pagetable+0x76>
}
    80001adc:	8526                	mv	a0,s1
    80001ade:	60e2                	ld	ra,24(sp)
    80001ae0:	6442                	ld	s0,16(sp)
    80001ae2:	64a2                	ld	s1,8(sp)
    80001ae4:	6902                	ld	s2,0(sp)
    80001ae6:	6105                	addi	sp,sp,32
    80001ae8:	8082                	ret
    uvmfree(pagetable, 0);
    80001aea:	4581                	li	a1,0
    80001aec:	8526                	mv	a0,s1
    80001aee:	00000097          	auipc	ra,0x0
    80001af2:	a56080e7          	jalr	-1450(ra) # 80001544 <uvmfree>
    return 0;
    80001af6:	4481                	li	s1,0
    80001af8:	b7d5                	j	80001adc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001afa:	4681                	li	a3,0
    80001afc:	4605                	li	a2,1
    80001afe:	040005b7          	lui	a1,0x4000
    80001b02:	15fd                	addi	a1,a1,-1
    80001b04:	05b2                	slli	a1,a1,0xc
    80001b06:	8526                	mv	a0,s1
    80001b08:	fffff097          	auipc	ra,0xfffff
    80001b0c:	77c080e7          	jalr	1916(ra) # 80001284 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b10:	4581                	li	a1,0
    80001b12:	8526                	mv	a0,s1
    80001b14:	00000097          	auipc	ra,0x0
    80001b18:	a30080e7          	jalr	-1488(ra) # 80001544 <uvmfree>
    return 0;
    80001b1c:	4481                	li	s1,0
    80001b1e:	bf7d                	j	80001adc <proc_pagetable+0x58>

0000000080001b20 <proc_freepagetable>:
{
    80001b20:	1101                	addi	sp,sp,-32
    80001b22:	ec06                	sd	ra,24(sp)
    80001b24:	e822                	sd	s0,16(sp)
    80001b26:	e426                	sd	s1,8(sp)
    80001b28:	e04a                	sd	s2,0(sp)
    80001b2a:	1000                	addi	s0,sp,32
    80001b2c:	84aa                	mv	s1,a0
    80001b2e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	040005b7          	lui	a1,0x4000
    80001b38:	15fd                	addi	a1,a1,-1
    80001b3a:	05b2                	slli	a1,a1,0xc
    80001b3c:	fffff097          	auipc	ra,0xfffff
    80001b40:	748080e7          	jalr	1864(ra) # 80001284 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b44:	4681                	li	a3,0
    80001b46:	4605                	li	a2,1
    80001b48:	020005b7          	lui	a1,0x2000
    80001b4c:	15fd                	addi	a1,a1,-1
    80001b4e:	05b6                	slli	a1,a1,0xd
    80001b50:	8526                	mv	a0,s1
    80001b52:	fffff097          	auipc	ra,0xfffff
    80001b56:	732080e7          	jalr	1842(ra) # 80001284 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b5a:	85ca                	mv	a1,s2
    80001b5c:	8526                	mv	a0,s1
    80001b5e:	00000097          	auipc	ra,0x0
    80001b62:	9e6080e7          	jalr	-1562(ra) # 80001544 <uvmfree>
}
    80001b66:	60e2                	ld	ra,24(sp)
    80001b68:	6442                	ld	s0,16(sp)
    80001b6a:	64a2                	ld	s1,8(sp)
    80001b6c:	6902                	ld	s2,0(sp)
    80001b6e:	6105                	addi	sp,sp,32
    80001b70:	8082                	ret

0000000080001b72 <freeproc>:
{
    80001b72:	1101                	addi	sp,sp,-32
    80001b74:	ec06                	sd	ra,24(sp)
    80001b76:	e822                	sd	s0,16(sp)
    80001b78:	e426                	sd	s1,8(sp)
    80001b7a:	1000                	addi	s0,sp,32
    80001b7c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b7e:	6d28                	ld	a0,88(a0)
    80001b80:	c509                	beqz	a0,80001b8a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b82:	fffff097          	auipc	ra,0xfffff
    80001b86:	e54080e7          	jalr	-428(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    80001b8a:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b8e:	68a8                	ld	a0,80(s1)
    80001b90:	c511                	beqz	a0,80001b9c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b92:	64ac                	ld	a1,72(s1)
    80001b94:	00000097          	auipc	ra,0x0
    80001b98:	f8c080e7          	jalr	-116(ra) # 80001b20 <proc_freepagetable>
  p->pagetable = 0;
    80001b9c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001ba0:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001ba4:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001ba8:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bac:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bb0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bb4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bb8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bbc:	0004ac23          	sw	zero,24(s1)
}
    80001bc0:	60e2                	ld	ra,24(sp)
    80001bc2:	6442                	ld	s0,16(sp)
    80001bc4:	64a2                	ld	s1,8(sp)
    80001bc6:	6105                	addi	sp,sp,32
    80001bc8:	8082                	ret

0000000080001bca <allocproc>:
{
    80001bca:	1101                	addi	sp,sp,-32
    80001bcc:	ec06                	sd	ra,24(sp)
    80001bce:	e822                	sd	s0,16(sp)
    80001bd0:	e426                	sd	s1,8(sp)
    80001bd2:	e04a                	sd	s2,0(sp)
    80001bd4:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd6:	00010497          	auipc	s1,0x10
    80001bda:	afa48493          	addi	s1,s1,-1286 # 800116d0 <proc>
    80001bde:	00015917          	auipc	s2,0x15
    80001be2:	4f290913          	addi	s2,s2,1266 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001be6:	8526                	mv	a0,s1
    80001be8:	fffff097          	auipc	ra,0xfffff
    80001bec:	fda080e7          	jalr	-38(ra) # 80000bc2 <acquire>
    if(p->state == UNUSED) {
    80001bf0:	4c9c                	lw	a5,24(s1)
    80001bf2:	cf81                	beqz	a5,80001c0a <allocproc+0x40>
      release(&p->lock);
    80001bf4:	8526                	mv	a0,s1
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	080080e7          	jalr	128(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bfe:	16848493          	addi	s1,s1,360
    80001c02:	ff2492e3          	bne	s1,s2,80001be6 <allocproc+0x1c>
  return 0;
    80001c06:	4481                	li	s1,0
    80001c08:	a889                	j	80001c5a <allocproc+0x90>
  p->pid = allocpid();
    80001c0a:	00000097          	auipc	ra,0x0
    80001c0e:	e34080e7          	jalr	-460(ra) # 80001a3e <allocpid>
    80001c12:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c14:	4785                	li	a5,1
    80001c16:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c18:	fffff097          	auipc	ra,0xfffff
    80001c1c:	eba080e7          	jalr	-326(ra) # 80000ad2 <kalloc>
    80001c20:	892a                	mv	s2,a0
    80001c22:	eca8                	sd	a0,88(s1)
    80001c24:	c131                	beqz	a0,80001c68 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c26:	8526                	mv	a0,s1
    80001c28:	00000097          	auipc	ra,0x0
    80001c2c:	e5c080e7          	jalr	-420(ra) # 80001a84 <proc_pagetable>
    80001c30:	892a                	mv	s2,a0
    80001c32:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c34:	c531                	beqz	a0,80001c80 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c36:	07000613          	li	a2,112
    80001c3a:	4581                	li	a1,0
    80001c3c:	06048513          	addi	a0,s1,96
    80001c40:	fffff097          	auipc	ra,0xfffff
    80001c44:	07e080e7          	jalr	126(ra) # 80000cbe <memset>
  p->context.ra = (uint64)forkret;
    80001c48:	00000797          	auipc	a5,0x0
    80001c4c:	db078793          	addi	a5,a5,-592 # 800019f8 <forkret>
    80001c50:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c52:	60bc                	ld	a5,64(s1)
    80001c54:	6705                	lui	a4,0x1
    80001c56:	97ba                	add	a5,a5,a4
    80001c58:	f4bc                	sd	a5,104(s1)
}
    80001c5a:	8526                	mv	a0,s1
    80001c5c:	60e2                	ld	ra,24(sp)
    80001c5e:	6442                	ld	s0,16(sp)
    80001c60:	64a2                	ld	s1,8(sp)
    80001c62:	6902                	ld	s2,0(sp)
    80001c64:	6105                	addi	sp,sp,32
    80001c66:	8082                	ret
    freeproc(p);
    80001c68:	8526                	mv	a0,s1
    80001c6a:	00000097          	auipc	ra,0x0
    80001c6e:	f08080e7          	jalr	-248(ra) # 80001b72 <freeproc>
    release(&p->lock);
    80001c72:	8526                	mv	a0,s1
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	002080e7          	jalr	2(ra) # 80000c76 <release>
    return 0;
    80001c7c:	84ca                	mv	s1,s2
    80001c7e:	bff1                	j	80001c5a <allocproc+0x90>
    freeproc(p);
    80001c80:	8526                	mv	a0,s1
    80001c82:	00000097          	auipc	ra,0x0
    80001c86:	ef0080e7          	jalr	-272(ra) # 80001b72 <freeproc>
    release(&p->lock);
    80001c8a:	8526                	mv	a0,s1
    80001c8c:	fffff097          	auipc	ra,0xfffff
    80001c90:	fea080e7          	jalr	-22(ra) # 80000c76 <release>
    return 0;
    80001c94:	84ca                	mv	s1,s2
    80001c96:	b7d1                	j	80001c5a <allocproc+0x90>

0000000080001c98 <userinit>:
{
    80001c98:	1101                	addi	sp,sp,-32
    80001c9a:	ec06                	sd	ra,24(sp)
    80001c9c:	e822                	sd	s0,16(sp)
    80001c9e:	e426                	sd	s1,8(sp)
    80001ca0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ca2:	00000097          	auipc	ra,0x0
    80001ca6:	f28080e7          	jalr	-216(ra) # 80001bca <allocproc>
    80001caa:	84aa                	mv	s1,a0
  initproc = p;
    80001cac:	00007797          	auipc	a5,0x7
    80001cb0:	36a7be23          	sd	a0,892(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cb4:	03400613          	li	a2,52
    80001cb8:	00007597          	auipc	a1,0x7
    80001cbc:	b5858593          	addi	a1,a1,-1192 # 80008810 <initcode>
    80001cc0:	6928                	ld	a0,80(a0)
    80001cc2:	fffff097          	auipc	ra,0xfffff
    80001cc6:	6b4080e7          	jalr	1716(ra) # 80001376 <uvminit>
  p->sz = PGSIZE;
    80001cca:	6785                	lui	a5,0x1
    80001ccc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cce:	6cb8                	ld	a4,88(s1)
    80001cd0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cd4:	6cb8                	ld	a4,88(s1)
    80001cd6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cd8:	4641                	li	a2,16
    80001cda:	00006597          	auipc	a1,0x6
    80001cde:	50e58593          	addi	a1,a1,1294 # 800081e8 <digits+0x1a8>
    80001ce2:	15848513          	addi	a0,s1,344
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	12a080e7          	jalr	298(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    80001cee:	00006517          	auipc	a0,0x6
    80001cf2:	50a50513          	addi	a0,a0,1290 # 800081f8 <digits+0x1b8>
    80001cf6:	00002097          	auipc	ra,0x2
    80001cfa:	2aa080e7          	jalr	682(ra) # 80003fa0 <namei>
    80001cfe:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d02:	478d                	li	a5,3
    80001d04:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d06:	8526                	mv	a0,s1
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	f6e080e7          	jalr	-146(ra) # 80000c76 <release>
}
    80001d10:	60e2                	ld	ra,24(sp)
    80001d12:	6442                	ld	s0,16(sp)
    80001d14:	64a2                	ld	s1,8(sp)
    80001d16:	6105                	addi	sp,sp,32
    80001d18:	8082                	ret

0000000080001d1a <growproc>:
{
    80001d1a:	1101                	addi	sp,sp,-32
    80001d1c:	ec06                	sd	ra,24(sp)
    80001d1e:	e822                	sd	s0,16(sp)
    80001d20:	e426                	sd	s1,8(sp)
    80001d22:	e04a                	sd	s2,0(sp)
    80001d24:	1000                	addi	s0,sp,32
    80001d26:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d28:	00000097          	auipc	ra,0x0
    80001d2c:	c98080e7          	jalr	-872(ra) # 800019c0 <myproc>
    80001d30:	892a                	mv	s2,a0
  sz = p->sz;
    80001d32:	652c                	ld	a1,72(a0)
    80001d34:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d38:	00904f63          	bgtz	s1,80001d56 <growproc+0x3c>
  } else if(n < 0){
    80001d3c:	0204cc63          	bltz	s1,80001d74 <growproc+0x5a>
  p->sz = sz;
    80001d40:	1602                	slli	a2,a2,0x20
    80001d42:	9201                	srli	a2,a2,0x20
    80001d44:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d48:	4501                	li	a0,0
}
    80001d4a:	60e2                	ld	ra,24(sp)
    80001d4c:	6442                	ld	s0,16(sp)
    80001d4e:	64a2                	ld	s1,8(sp)
    80001d50:	6902                	ld	s2,0(sp)
    80001d52:	6105                	addi	sp,sp,32
    80001d54:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d56:	9e25                	addw	a2,a2,s1
    80001d58:	1602                	slli	a2,a2,0x20
    80001d5a:	9201                	srli	a2,a2,0x20
    80001d5c:	1582                	slli	a1,a1,0x20
    80001d5e:	9181                	srli	a1,a1,0x20
    80001d60:	6928                	ld	a0,80(a0)
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	6ce080e7          	jalr	1742(ra) # 80001430 <uvmalloc>
    80001d6a:	0005061b          	sext.w	a2,a0
    80001d6e:	fa69                	bnez	a2,80001d40 <growproc+0x26>
      return -1;
    80001d70:	557d                	li	a0,-1
    80001d72:	bfe1                	j	80001d4a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d74:	9e25                	addw	a2,a2,s1
    80001d76:	1602                	slli	a2,a2,0x20
    80001d78:	9201                	srli	a2,a2,0x20
    80001d7a:	1582                	slli	a1,a1,0x20
    80001d7c:	9181                	srli	a1,a1,0x20
    80001d7e:	6928                	ld	a0,80(a0)
    80001d80:	fffff097          	auipc	ra,0xfffff
    80001d84:	668080e7          	jalr	1640(ra) # 800013e8 <uvmdealloc>
    80001d88:	0005061b          	sext.w	a2,a0
    80001d8c:	bf55                	j	80001d40 <growproc+0x26>

0000000080001d8e <fork>:
{
    80001d8e:	7139                	addi	sp,sp,-64
    80001d90:	fc06                	sd	ra,56(sp)
    80001d92:	f822                	sd	s0,48(sp)
    80001d94:	f426                	sd	s1,40(sp)
    80001d96:	f04a                	sd	s2,32(sp)
    80001d98:	ec4e                	sd	s3,24(sp)
    80001d9a:	e852                	sd	s4,16(sp)
    80001d9c:	e456                	sd	s5,8(sp)
    80001d9e:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001da0:	00000097          	auipc	ra,0x0
    80001da4:	c20080e7          	jalr	-992(ra) # 800019c0 <myproc>
    80001da8:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001daa:	00000097          	auipc	ra,0x0
    80001dae:	e20080e7          	jalr	-480(ra) # 80001bca <allocproc>
    80001db2:	10050c63          	beqz	a0,80001eca <fork+0x13c>
    80001db6:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001db8:	048ab603          	ld	a2,72(s5)
    80001dbc:	692c                	ld	a1,80(a0)
    80001dbe:	050ab503          	ld	a0,80(s5)
    80001dc2:	fffff097          	auipc	ra,0xfffff
    80001dc6:	7ba080e7          	jalr	1978(ra) # 8000157c <uvmcopy>
    80001dca:	04054863          	bltz	a0,80001e1a <fork+0x8c>
  np->sz = p->sz;
    80001dce:	048ab783          	ld	a5,72(s5)
    80001dd2:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dd6:	058ab683          	ld	a3,88(s5)
    80001dda:	87b6                	mv	a5,a3
    80001ddc:	058a3703          	ld	a4,88(s4)
    80001de0:	12068693          	addi	a3,a3,288
    80001de4:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001de8:	6788                	ld	a0,8(a5)
    80001dea:	6b8c                	ld	a1,16(a5)
    80001dec:	6f90                	ld	a2,24(a5)
    80001dee:	01073023          	sd	a6,0(a4)
    80001df2:	e708                	sd	a0,8(a4)
    80001df4:	eb0c                	sd	a1,16(a4)
    80001df6:	ef10                	sd	a2,24(a4)
    80001df8:	02078793          	addi	a5,a5,32
    80001dfc:	02070713          	addi	a4,a4,32
    80001e00:	fed792e3          	bne	a5,a3,80001de4 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e04:	058a3783          	ld	a5,88(s4)
    80001e08:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e0c:	0d0a8493          	addi	s1,s5,208
    80001e10:	0d0a0913          	addi	s2,s4,208
    80001e14:	150a8993          	addi	s3,s5,336
    80001e18:	a00d                	j	80001e3a <fork+0xac>
    freeproc(np);
    80001e1a:	8552                	mv	a0,s4
    80001e1c:	00000097          	auipc	ra,0x0
    80001e20:	d56080e7          	jalr	-682(ra) # 80001b72 <freeproc>
    release(&np->lock);
    80001e24:	8552                	mv	a0,s4
    80001e26:	fffff097          	auipc	ra,0xfffff
    80001e2a:	e50080e7          	jalr	-432(ra) # 80000c76 <release>
    return -1;
    80001e2e:	597d                	li	s2,-1
    80001e30:	a059                	j	80001eb6 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e32:	04a1                	addi	s1,s1,8
    80001e34:	0921                	addi	s2,s2,8
    80001e36:	01348b63          	beq	s1,s3,80001e4c <fork+0xbe>
    if(p->ofile[i])
    80001e3a:	6088                	ld	a0,0(s1)
    80001e3c:	d97d                	beqz	a0,80001e32 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e3e:	00002097          	auipc	ra,0x2
    80001e42:	7fc080e7          	jalr	2044(ra) # 8000463a <filedup>
    80001e46:	00a93023          	sd	a0,0(s2)
    80001e4a:	b7e5                	j	80001e32 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e4c:	150ab503          	ld	a0,336(s5)
    80001e50:	00002097          	auipc	ra,0x2
    80001e54:	82a080e7          	jalr	-2006(ra) # 8000367a <idup>
    80001e58:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e5c:	4641                	li	a2,16
    80001e5e:	158a8593          	addi	a1,s5,344
    80001e62:	158a0513          	addi	a0,s4,344
    80001e66:	fffff097          	auipc	ra,0xfffff
    80001e6a:	faa080e7          	jalr	-86(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80001e6e:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e72:	8552                	mv	a0,s4
    80001e74:	fffff097          	auipc	ra,0xfffff
    80001e78:	e02080e7          	jalr	-510(ra) # 80000c76 <release>
  acquire(&wait_lock);
    80001e7c:	0000f497          	auipc	s1,0xf
    80001e80:	43c48493          	addi	s1,s1,1084 # 800112b8 <wait_lock>
    80001e84:	8526                	mv	a0,s1
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	d3c080e7          	jalr	-708(ra) # 80000bc2 <acquire>
  np->parent = p;
    80001e8e:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e92:	8526                	mv	a0,s1
    80001e94:	fffff097          	auipc	ra,0xfffff
    80001e98:	de2080e7          	jalr	-542(ra) # 80000c76 <release>
  acquire(&np->lock);
    80001e9c:	8552                	mv	a0,s4
    80001e9e:	fffff097          	auipc	ra,0xfffff
    80001ea2:	d24080e7          	jalr	-732(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    80001ea6:	478d                	li	a5,3
    80001ea8:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001eac:	8552                	mv	a0,s4
    80001eae:	fffff097          	auipc	ra,0xfffff
    80001eb2:	dc8080e7          	jalr	-568(ra) # 80000c76 <release>
}
    80001eb6:	854a                	mv	a0,s2
    80001eb8:	70e2                	ld	ra,56(sp)
    80001eba:	7442                	ld	s0,48(sp)
    80001ebc:	74a2                	ld	s1,40(sp)
    80001ebe:	7902                	ld	s2,32(sp)
    80001ec0:	69e2                	ld	s3,24(sp)
    80001ec2:	6a42                	ld	s4,16(sp)
    80001ec4:	6aa2                	ld	s5,8(sp)
    80001ec6:	6121                	addi	sp,sp,64
    80001ec8:	8082                	ret
    return -1;
    80001eca:	597d                	li	s2,-1
    80001ecc:	b7ed                	j	80001eb6 <fork+0x128>

0000000080001ece <scheduler>:
{
    80001ece:	7139                	addi	sp,sp,-64
    80001ed0:	fc06                	sd	ra,56(sp)
    80001ed2:	f822                	sd	s0,48(sp)
    80001ed4:	f426                	sd	s1,40(sp)
    80001ed6:	f04a                	sd	s2,32(sp)
    80001ed8:	ec4e                	sd	s3,24(sp)
    80001eda:	e852                	sd	s4,16(sp)
    80001edc:	e456                	sd	s5,8(sp)
    80001ede:	e05a                	sd	s6,0(sp)
    80001ee0:	0080                	addi	s0,sp,64
    80001ee2:	8792                	mv	a5,tp
  int id = r_tp();
    80001ee4:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ee6:	00779a93          	slli	s5,a5,0x7
    80001eea:	0000f717          	auipc	a4,0xf
    80001eee:	3b670713          	addi	a4,a4,950 # 800112a0 <pid_lock>
    80001ef2:	9756                	add	a4,a4,s5
    80001ef4:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ef8:	0000f717          	auipc	a4,0xf
    80001efc:	3e070713          	addi	a4,a4,992 # 800112d8 <cpus+0x8>
    80001f00:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f02:	498d                	li	s3,3
        p->state = RUNNING;
    80001f04:	4b11                	li	s6,4
        c->proc = p;
    80001f06:	079e                	slli	a5,a5,0x7
    80001f08:	0000fa17          	auipc	s4,0xf
    80001f0c:	398a0a13          	addi	s4,s4,920 # 800112a0 <pid_lock>
    80001f10:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f12:	00015917          	auipc	s2,0x15
    80001f16:	1be90913          	addi	s2,s2,446 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f1a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f1e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f22:	10079073          	csrw	sstatus,a5
    80001f26:	0000f497          	auipc	s1,0xf
    80001f2a:	7aa48493          	addi	s1,s1,1962 # 800116d0 <proc>
    80001f2e:	a811                	j	80001f42 <scheduler+0x74>
      release(&p->lock);
    80001f30:	8526                	mv	a0,s1
    80001f32:	fffff097          	auipc	ra,0xfffff
    80001f36:	d44080e7          	jalr	-700(ra) # 80000c76 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f3a:	16848493          	addi	s1,s1,360
    80001f3e:	fd248ee3          	beq	s1,s2,80001f1a <scheduler+0x4c>
      acquire(&p->lock);
    80001f42:	8526                	mv	a0,s1
    80001f44:	fffff097          	auipc	ra,0xfffff
    80001f48:	c7e080e7          	jalr	-898(ra) # 80000bc2 <acquire>
      if(p->state == RUNNABLE) {
    80001f4c:	4c9c                	lw	a5,24(s1)
    80001f4e:	ff3791e3          	bne	a5,s3,80001f30 <scheduler+0x62>
        p->state = RUNNING;
    80001f52:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f56:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f5a:	06048593          	addi	a1,s1,96
    80001f5e:	8556                	mv	a0,s5
    80001f60:	00000097          	auipc	ra,0x0
    80001f64:	61e080e7          	jalr	1566(ra) # 8000257e <swtch>
        c->proc = 0;
    80001f68:	020a3823          	sd	zero,48(s4)
    80001f6c:	b7d1                	j	80001f30 <scheduler+0x62>

0000000080001f6e <sched>:
{
    80001f6e:	7179                	addi	sp,sp,-48
    80001f70:	f406                	sd	ra,40(sp)
    80001f72:	f022                	sd	s0,32(sp)
    80001f74:	ec26                	sd	s1,24(sp)
    80001f76:	e84a                	sd	s2,16(sp)
    80001f78:	e44e                	sd	s3,8(sp)
    80001f7a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f7c:	00000097          	auipc	ra,0x0
    80001f80:	a44080e7          	jalr	-1468(ra) # 800019c0 <myproc>
    80001f84:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f86:	fffff097          	auipc	ra,0xfffff
    80001f8a:	bc2080e7          	jalr	-1086(ra) # 80000b48 <holding>
    80001f8e:	c93d                	beqz	a0,80002004 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f90:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f92:	2781                	sext.w	a5,a5
    80001f94:	079e                	slli	a5,a5,0x7
    80001f96:	0000f717          	auipc	a4,0xf
    80001f9a:	30a70713          	addi	a4,a4,778 # 800112a0 <pid_lock>
    80001f9e:	97ba                	add	a5,a5,a4
    80001fa0:	0a87a703          	lw	a4,168(a5)
    80001fa4:	4785                	li	a5,1
    80001fa6:	06f71763          	bne	a4,a5,80002014 <sched+0xa6>
  if(p->state == RUNNING)
    80001faa:	4c98                	lw	a4,24(s1)
    80001fac:	4791                	li	a5,4
    80001fae:	06f70b63          	beq	a4,a5,80002024 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fb2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fb6:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fb8:	efb5                	bnez	a5,80002034 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fba:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fbc:	0000f917          	auipc	s2,0xf
    80001fc0:	2e490913          	addi	s2,s2,740 # 800112a0 <pid_lock>
    80001fc4:	2781                	sext.w	a5,a5
    80001fc6:	079e                	slli	a5,a5,0x7
    80001fc8:	97ca                	add	a5,a5,s2
    80001fca:	0ac7a983          	lw	s3,172(a5)
    80001fce:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fd0:	2781                	sext.w	a5,a5
    80001fd2:	079e                	slli	a5,a5,0x7
    80001fd4:	0000f597          	auipc	a1,0xf
    80001fd8:	30458593          	addi	a1,a1,772 # 800112d8 <cpus+0x8>
    80001fdc:	95be                	add	a1,a1,a5
    80001fde:	06048513          	addi	a0,s1,96
    80001fe2:	00000097          	auipc	ra,0x0
    80001fe6:	59c080e7          	jalr	1436(ra) # 8000257e <swtch>
    80001fea:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fec:	2781                	sext.w	a5,a5
    80001fee:	079e                	slli	a5,a5,0x7
    80001ff0:	97ca                	add	a5,a5,s2
    80001ff2:	0b37a623          	sw	s3,172(a5)
}
    80001ff6:	70a2                	ld	ra,40(sp)
    80001ff8:	7402                	ld	s0,32(sp)
    80001ffa:	64e2                	ld	s1,24(sp)
    80001ffc:	6942                	ld	s2,16(sp)
    80001ffe:	69a2                	ld	s3,8(sp)
    80002000:	6145                	addi	sp,sp,48
    80002002:	8082                	ret
    panic("sched p->lock");
    80002004:	00006517          	auipc	a0,0x6
    80002008:	1fc50513          	addi	a0,a0,508 # 80008200 <digits+0x1c0>
    8000200c:	ffffe097          	auipc	ra,0xffffe
    80002010:	51e080e7          	jalr	1310(ra) # 8000052a <panic>
    panic("sched locks");
    80002014:	00006517          	auipc	a0,0x6
    80002018:	1fc50513          	addi	a0,a0,508 # 80008210 <digits+0x1d0>
    8000201c:	ffffe097          	auipc	ra,0xffffe
    80002020:	50e080e7          	jalr	1294(ra) # 8000052a <panic>
    panic("sched running");
    80002024:	00006517          	auipc	a0,0x6
    80002028:	1fc50513          	addi	a0,a0,508 # 80008220 <digits+0x1e0>
    8000202c:	ffffe097          	auipc	ra,0xffffe
    80002030:	4fe080e7          	jalr	1278(ra) # 8000052a <panic>
    panic("sched interruptible");
    80002034:	00006517          	auipc	a0,0x6
    80002038:	1fc50513          	addi	a0,a0,508 # 80008230 <digits+0x1f0>
    8000203c:	ffffe097          	auipc	ra,0xffffe
    80002040:	4ee080e7          	jalr	1262(ra) # 8000052a <panic>

0000000080002044 <yield>:
{
    80002044:	1101                	addi	sp,sp,-32
    80002046:	ec06                	sd	ra,24(sp)
    80002048:	e822                	sd	s0,16(sp)
    8000204a:	e426                	sd	s1,8(sp)
    8000204c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000204e:	00000097          	auipc	ra,0x0
    80002052:	972080e7          	jalr	-1678(ra) # 800019c0 <myproc>
    80002056:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002058:	fffff097          	auipc	ra,0xfffff
    8000205c:	b6a080e7          	jalr	-1174(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    80002060:	478d                	li	a5,3
    80002062:	cc9c                	sw	a5,24(s1)
  sched();
    80002064:	00000097          	auipc	ra,0x0
    80002068:	f0a080e7          	jalr	-246(ra) # 80001f6e <sched>
  release(&p->lock);
    8000206c:	8526                	mv	a0,s1
    8000206e:	fffff097          	auipc	ra,0xfffff
    80002072:	c08080e7          	jalr	-1016(ra) # 80000c76 <release>
}
    80002076:	60e2                	ld	ra,24(sp)
    80002078:	6442                	ld	s0,16(sp)
    8000207a:	64a2                	ld	s1,8(sp)
    8000207c:	6105                	addi	sp,sp,32
    8000207e:	8082                	ret

0000000080002080 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002080:	7179                	addi	sp,sp,-48
    80002082:	f406                	sd	ra,40(sp)
    80002084:	f022                	sd	s0,32(sp)
    80002086:	ec26                	sd	s1,24(sp)
    80002088:	e84a                	sd	s2,16(sp)
    8000208a:	e44e                	sd	s3,8(sp)
    8000208c:	1800                	addi	s0,sp,48
    8000208e:	89aa                	mv	s3,a0
    80002090:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002092:	00000097          	auipc	ra,0x0
    80002096:	92e080e7          	jalr	-1746(ra) # 800019c0 <myproc>
    8000209a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000209c:	fffff097          	auipc	ra,0xfffff
    800020a0:	b26080e7          	jalr	-1242(ra) # 80000bc2 <acquire>
  release(lk);
    800020a4:	854a                	mv	a0,s2
    800020a6:	fffff097          	auipc	ra,0xfffff
    800020aa:	bd0080e7          	jalr	-1072(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    800020ae:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020b2:	4789                	li	a5,2
    800020b4:	cc9c                	sw	a5,24(s1)

  sched();
    800020b6:	00000097          	auipc	ra,0x0
    800020ba:	eb8080e7          	jalr	-328(ra) # 80001f6e <sched>

  // Tidy up.
  p->chan = 0;
    800020be:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020c2:	8526                	mv	a0,s1
    800020c4:	fffff097          	auipc	ra,0xfffff
    800020c8:	bb2080e7          	jalr	-1102(ra) # 80000c76 <release>
  acquire(lk);
    800020cc:	854a                	mv	a0,s2
    800020ce:	fffff097          	auipc	ra,0xfffff
    800020d2:	af4080e7          	jalr	-1292(ra) # 80000bc2 <acquire>
}
    800020d6:	70a2                	ld	ra,40(sp)
    800020d8:	7402                	ld	s0,32(sp)
    800020da:	64e2                	ld	s1,24(sp)
    800020dc:	6942                	ld	s2,16(sp)
    800020de:	69a2                	ld	s3,8(sp)
    800020e0:	6145                	addi	sp,sp,48
    800020e2:	8082                	ret

00000000800020e4 <wait>:
{
    800020e4:	715d                	addi	sp,sp,-80
    800020e6:	e486                	sd	ra,72(sp)
    800020e8:	e0a2                	sd	s0,64(sp)
    800020ea:	fc26                	sd	s1,56(sp)
    800020ec:	f84a                	sd	s2,48(sp)
    800020ee:	f44e                	sd	s3,40(sp)
    800020f0:	f052                	sd	s4,32(sp)
    800020f2:	ec56                	sd	s5,24(sp)
    800020f4:	e85a                	sd	s6,16(sp)
    800020f6:	e45e                	sd	s7,8(sp)
    800020f8:	e062                	sd	s8,0(sp)
    800020fa:	0880                	addi	s0,sp,80
    800020fc:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800020fe:	00000097          	auipc	ra,0x0
    80002102:	8c2080e7          	jalr	-1854(ra) # 800019c0 <myproc>
    80002106:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002108:	0000f517          	auipc	a0,0xf
    8000210c:	1b050513          	addi	a0,a0,432 # 800112b8 <wait_lock>
    80002110:	fffff097          	auipc	ra,0xfffff
    80002114:	ab2080e7          	jalr	-1358(ra) # 80000bc2 <acquire>
    havekids = 0;
    80002118:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000211a:	4a15                	li	s4,5
        havekids = 1;
    8000211c:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    8000211e:	00015997          	auipc	s3,0x15
    80002122:	fb298993          	addi	s3,s3,-78 # 800170d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002126:	0000fc17          	auipc	s8,0xf
    8000212a:	192c0c13          	addi	s8,s8,402 # 800112b8 <wait_lock>
    havekids = 0;
    8000212e:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002130:	0000f497          	auipc	s1,0xf
    80002134:	5a048493          	addi	s1,s1,1440 # 800116d0 <proc>
    80002138:	a0bd                	j	800021a6 <wait+0xc2>
          pid = np->pid;
    8000213a:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000213e:	000b0e63          	beqz	s6,8000215a <wait+0x76>
    80002142:	4691                	li	a3,4
    80002144:	02c48613          	addi	a2,s1,44
    80002148:	85da                	mv	a1,s6
    8000214a:	05093503          	ld	a0,80(s2)
    8000214e:	fffff097          	auipc	ra,0xfffff
    80002152:	532080e7          	jalr	1330(ra) # 80001680 <copyout>
    80002156:	02054563          	bltz	a0,80002180 <wait+0x9c>
          freeproc(np);
    8000215a:	8526                	mv	a0,s1
    8000215c:	00000097          	auipc	ra,0x0
    80002160:	a16080e7          	jalr	-1514(ra) # 80001b72 <freeproc>
          release(&np->lock);
    80002164:	8526                	mv	a0,s1
    80002166:	fffff097          	auipc	ra,0xfffff
    8000216a:	b10080e7          	jalr	-1264(ra) # 80000c76 <release>
          release(&wait_lock);
    8000216e:	0000f517          	auipc	a0,0xf
    80002172:	14a50513          	addi	a0,a0,330 # 800112b8 <wait_lock>
    80002176:	fffff097          	auipc	ra,0xfffff
    8000217a:	b00080e7          	jalr	-1280(ra) # 80000c76 <release>
          return pid;
    8000217e:	a09d                	j	800021e4 <wait+0x100>
            release(&np->lock);
    80002180:	8526                	mv	a0,s1
    80002182:	fffff097          	auipc	ra,0xfffff
    80002186:	af4080e7          	jalr	-1292(ra) # 80000c76 <release>
            release(&wait_lock);
    8000218a:	0000f517          	auipc	a0,0xf
    8000218e:	12e50513          	addi	a0,a0,302 # 800112b8 <wait_lock>
    80002192:	fffff097          	auipc	ra,0xfffff
    80002196:	ae4080e7          	jalr	-1308(ra) # 80000c76 <release>
            return -1;
    8000219a:	59fd                	li	s3,-1
    8000219c:	a0a1                	j	800021e4 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000219e:	16848493          	addi	s1,s1,360
    800021a2:	03348463          	beq	s1,s3,800021ca <wait+0xe6>
      if(np->parent == p){
    800021a6:	7c9c                	ld	a5,56(s1)
    800021a8:	ff279be3          	bne	a5,s2,8000219e <wait+0xba>
        acquire(&np->lock);
    800021ac:	8526                	mv	a0,s1
    800021ae:	fffff097          	auipc	ra,0xfffff
    800021b2:	a14080e7          	jalr	-1516(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    800021b6:	4c9c                	lw	a5,24(s1)
    800021b8:	f94781e3          	beq	a5,s4,8000213a <wait+0x56>
        release(&np->lock);
    800021bc:	8526                	mv	a0,s1
    800021be:	fffff097          	auipc	ra,0xfffff
    800021c2:	ab8080e7          	jalr	-1352(ra) # 80000c76 <release>
        havekids = 1;
    800021c6:	8756                	mv	a4,s5
    800021c8:	bfd9                	j	8000219e <wait+0xba>
    if(!havekids || p->killed){
    800021ca:	c701                	beqz	a4,800021d2 <wait+0xee>
    800021cc:	02892783          	lw	a5,40(s2)
    800021d0:	c79d                	beqz	a5,800021fe <wait+0x11a>
      release(&wait_lock);
    800021d2:	0000f517          	auipc	a0,0xf
    800021d6:	0e650513          	addi	a0,a0,230 # 800112b8 <wait_lock>
    800021da:	fffff097          	auipc	ra,0xfffff
    800021de:	a9c080e7          	jalr	-1380(ra) # 80000c76 <release>
      return -1;
    800021e2:	59fd                	li	s3,-1
}
    800021e4:	854e                	mv	a0,s3
    800021e6:	60a6                	ld	ra,72(sp)
    800021e8:	6406                	ld	s0,64(sp)
    800021ea:	74e2                	ld	s1,56(sp)
    800021ec:	7942                	ld	s2,48(sp)
    800021ee:	79a2                	ld	s3,40(sp)
    800021f0:	7a02                	ld	s4,32(sp)
    800021f2:	6ae2                	ld	s5,24(sp)
    800021f4:	6b42                	ld	s6,16(sp)
    800021f6:	6ba2                	ld	s7,8(sp)
    800021f8:	6c02                	ld	s8,0(sp)
    800021fa:	6161                	addi	sp,sp,80
    800021fc:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021fe:	85e2                	mv	a1,s8
    80002200:	854a                	mv	a0,s2
    80002202:	00000097          	auipc	ra,0x0
    80002206:	e7e080e7          	jalr	-386(ra) # 80002080 <sleep>
    havekids = 0;
    8000220a:	b715                	j	8000212e <wait+0x4a>

000000008000220c <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000220c:	7139                	addi	sp,sp,-64
    8000220e:	fc06                	sd	ra,56(sp)
    80002210:	f822                	sd	s0,48(sp)
    80002212:	f426                	sd	s1,40(sp)
    80002214:	f04a                	sd	s2,32(sp)
    80002216:	ec4e                	sd	s3,24(sp)
    80002218:	e852                	sd	s4,16(sp)
    8000221a:	e456                	sd	s5,8(sp)
    8000221c:	0080                	addi	s0,sp,64
    8000221e:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002220:	0000f497          	auipc	s1,0xf
    80002224:	4b048493          	addi	s1,s1,1200 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002228:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000222a:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000222c:	00015917          	auipc	s2,0x15
    80002230:	ea490913          	addi	s2,s2,-348 # 800170d0 <tickslock>
    80002234:	a811                	j	80002248 <wakeup+0x3c>
      }
      release(&p->lock);
    80002236:	8526                	mv	a0,s1
    80002238:	fffff097          	auipc	ra,0xfffff
    8000223c:	a3e080e7          	jalr	-1474(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002240:	16848493          	addi	s1,s1,360
    80002244:	03248663          	beq	s1,s2,80002270 <wakeup+0x64>
    if(p != myproc()){
    80002248:	fffff097          	auipc	ra,0xfffff
    8000224c:	778080e7          	jalr	1912(ra) # 800019c0 <myproc>
    80002250:	fea488e3          	beq	s1,a0,80002240 <wakeup+0x34>
      acquire(&p->lock);
    80002254:	8526                	mv	a0,s1
    80002256:	fffff097          	auipc	ra,0xfffff
    8000225a:	96c080e7          	jalr	-1684(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000225e:	4c9c                	lw	a5,24(s1)
    80002260:	fd379be3          	bne	a5,s3,80002236 <wakeup+0x2a>
    80002264:	709c                	ld	a5,32(s1)
    80002266:	fd4798e3          	bne	a5,s4,80002236 <wakeup+0x2a>
        p->state = RUNNABLE;
    8000226a:	0154ac23          	sw	s5,24(s1)
    8000226e:	b7e1                	j	80002236 <wakeup+0x2a>
    }
  }
}
    80002270:	70e2                	ld	ra,56(sp)
    80002272:	7442                	ld	s0,48(sp)
    80002274:	74a2                	ld	s1,40(sp)
    80002276:	7902                	ld	s2,32(sp)
    80002278:	69e2                	ld	s3,24(sp)
    8000227a:	6a42                	ld	s4,16(sp)
    8000227c:	6aa2                	ld	s5,8(sp)
    8000227e:	6121                	addi	sp,sp,64
    80002280:	8082                	ret

0000000080002282 <reparent>:
{
    80002282:	7179                	addi	sp,sp,-48
    80002284:	f406                	sd	ra,40(sp)
    80002286:	f022                	sd	s0,32(sp)
    80002288:	ec26                	sd	s1,24(sp)
    8000228a:	e84a                	sd	s2,16(sp)
    8000228c:	e44e                	sd	s3,8(sp)
    8000228e:	e052                	sd	s4,0(sp)
    80002290:	1800                	addi	s0,sp,48
    80002292:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002294:	0000f497          	auipc	s1,0xf
    80002298:	43c48493          	addi	s1,s1,1084 # 800116d0 <proc>
      pp->parent = initproc;
    8000229c:	00007a17          	auipc	s4,0x7
    800022a0:	d8ca0a13          	addi	s4,s4,-628 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022a4:	00015997          	auipc	s3,0x15
    800022a8:	e2c98993          	addi	s3,s3,-468 # 800170d0 <tickslock>
    800022ac:	a029                	j	800022b6 <reparent+0x34>
    800022ae:	16848493          	addi	s1,s1,360
    800022b2:	01348d63          	beq	s1,s3,800022cc <reparent+0x4a>
    if(pp->parent == p){
    800022b6:	7c9c                	ld	a5,56(s1)
    800022b8:	ff279be3          	bne	a5,s2,800022ae <reparent+0x2c>
      pp->parent = initproc;
    800022bc:	000a3503          	ld	a0,0(s4)
    800022c0:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022c2:	00000097          	auipc	ra,0x0
    800022c6:	f4a080e7          	jalr	-182(ra) # 8000220c <wakeup>
    800022ca:	b7d5                	j	800022ae <reparent+0x2c>
}
    800022cc:	70a2                	ld	ra,40(sp)
    800022ce:	7402                	ld	s0,32(sp)
    800022d0:	64e2                	ld	s1,24(sp)
    800022d2:	6942                	ld	s2,16(sp)
    800022d4:	69a2                	ld	s3,8(sp)
    800022d6:	6a02                	ld	s4,0(sp)
    800022d8:	6145                	addi	sp,sp,48
    800022da:	8082                	ret

00000000800022dc <exit>:
{
    800022dc:	7179                	addi	sp,sp,-48
    800022de:	f406                	sd	ra,40(sp)
    800022e0:	f022                	sd	s0,32(sp)
    800022e2:	ec26                	sd	s1,24(sp)
    800022e4:	e84a                	sd	s2,16(sp)
    800022e6:	e44e                	sd	s3,8(sp)
    800022e8:	e052                	sd	s4,0(sp)
    800022ea:	1800                	addi	s0,sp,48
    800022ec:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022ee:	fffff097          	auipc	ra,0xfffff
    800022f2:	6d2080e7          	jalr	1746(ra) # 800019c0 <myproc>
    800022f6:	89aa                	mv	s3,a0
  if(p == initproc)
    800022f8:	00007797          	auipc	a5,0x7
    800022fc:	d307b783          	ld	a5,-720(a5) # 80009028 <initproc>
    80002300:	0d050493          	addi	s1,a0,208
    80002304:	15050913          	addi	s2,a0,336
    80002308:	02a79363          	bne	a5,a0,8000232e <exit+0x52>
    panic("init exiting");
    8000230c:	00006517          	auipc	a0,0x6
    80002310:	f3c50513          	addi	a0,a0,-196 # 80008248 <digits+0x208>
    80002314:	ffffe097          	auipc	ra,0xffffe
    80002318:	216080e7          	jalr	534(ra) # 8000052a <panic>
      fileclose(f);
    8000231c:	00002097          	auipc	ra,0x2
    80002320:	370080e7          	jalr	880(ra) # 8000468c <fileclose>
      p->ofile[fd] = 0;
    80002324:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002328:	04a1                	addi	s1,s1,8
    8000232a:	01248563          	beq	s1,s2,80002334 <exit+0x58>
    if(p->ofile[fd]){
    8000232e:	6088                	ld	a0,0(s1)
    80002330:	f575                	bnez	a0,8000231c <exit+0x40>
    80002332:	bfdd                	j	80002328 <exit+0x4c>
  begin_op();
    80002334:	00002097          	auipc	ra,0x2
    80002338:	e8c080e7          	jalr	-372(ra) # 800041c0 <begin_op>
  iput(p->cwd);
    8000233c:	1509b503          	ld	a0,336(s3)
    80002340:	00001097          	auipc	ra,0x1
    80002344:	5e8080e7          	jalr	1512(ra) # 80003928 <iput>
  end_op();
    80002348:	00002097          	auipc	ra,0x2
    8000234c:	ef8080e7          	jalr	-264(ra) # 80004240 <end_op>
  p->cwd = 0;
    80002350:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002354:	0000f497          	auipc	s1,0xf
    80002358:	f6448493          	addi	s1,s1,-156 # 800112b8 <wait_lock>
    8000235c:	8526                	mv	a0,s1
    8000235e:	fffff097          	auipc	ra,0xfffff
    80002362:	864080e7          	jalr	-1948(ra) # 80000bc2 <acquire>
  reparent(p);
    80002366:	854e                	mv	a0,s3
    80002368:	00000097          	auipc	ra,0x0
    8000236c:	f1a080e7          	jalr	-230(ra) # 80002282 <reparent>
  wakeup(p->parent);
    80002370:	0389b503          	ld	a0,56(s3)
    80002374:	00000097          	auipc	ra,0x0
    80002378:	e98080e7          	jalr	-360(ra) # 8000220c <wakeup>
  acquire(&p->lock);
    8000237c:	854e                	mv	a0,s3
    8000237e:	fffff097          	auipc	ra,0xfffff
    80002382:	844080e7          	jalr	-1980(ra) # 80000bc2 <acquire>
  p->xstate = status;
    80002386:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000238a:	4795                	li	a5,5
    8000238c:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002390:	8526                	mv	a0,s1
    80002392:	fffff097          	auipc	ra,0xfffff
    80002396:	8e4080e7          	jalr	-1820(ra) # 80000c76 <release>
  sched();
    8000239a:	00000097          	auipc	ra,0x0
    8000239e:	bd4080e7          	jalr	-1068(ra) # 80001f6e <sched>
  panic("zombie exit");
    800023a2:	00006517          	auipc	a0,0x6
    800023a6:	eb650513          	addi	a0,a0,-330 # 80008258 <digits+0x218>
    800023aa:	ffffe097          	auipc	ra,0xffffe
    800023ae:	180080e7          	jalr	384(ra) # 8000052a <panic>

00000000800023b2 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023b2:	7179                	addi	sp,sp,-48
    800023b4:	f406                	sd	ra,40(sp)
    800023b6:	f022                	sd	s0,32(sp)
    800023b8:	ec26                	sd	s1,24(sp)
    800023ba:	e84a                	sd	s2,16(sp)
    800023bc:	e44e                	sd	s3,8(sp)
    800023be:	1800                	addi	s0,sp,48
    800023c0:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023c2:	0000f497          	auipc	s1,0xf
    800023c6:	30e48493          	addi	s1,s1,782 # 800116d0 <proc>
    800023ca:	00015997          	auipc	s3,0x15
    800023ce:	d0698993          	addi	s3,s3,-762 # 800170d0 <tickslock>
    acquire(&p->lock);
    800023d2:	8526                	mv	a0,s1
    800023d4:	ffffe097          	auipc	ra,0xffffe
    800023d8:	7ee080e7          	jalr	2030(ra) # 80000bc2 <acquire>
    if(p->pid == pid){
    800023dc:	589c                	lw	a5,48(s1)
    800023de:	01278d63          	beq	a5,s2,800023f8 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023e2:	8526                	mv	a0,s1
    800023e4:	fffff097          	auipc	ra,0xfffff
    800023e8:	892080e7          	jalr	-1902(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023ec:	16848493          	addi	s1,s1,360
    800023f0:	ff3491e3          	bne	s1,s3,800023d2 <kill+0x20>
  }
  return -1;
    800023f4:	557d                	li	a0,-1
    800023f6:	a829                	j	80002410 <kill+0x5e>
      p->killed = 1;
    800023f8:	4785                	li	a5,1
    800023fa:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800023fc:	4c98                	lw	a4,24(s1)
    800023fe:	4789                	li	a5,2
    80002400:	00f70f63          	beq	a4,a5,8000241e <kill+0x6c>
      release(&p->lock);
    80002404:	8526                	mv	a0,s1
    80002406:	fffff097          	auipc	ra,0xfffff
    8000240a:	870080e7          	jalr	-1936(ra) # 80000c76 <release>
      return 0;
    8000240e:	4501                	li	a0,0
}
    80002410:	70a2                	ld	ra,40(sp)
    80002412:	7402                	ld	s0,32(sp)
    80002414:	64e2                	ld	s1,24(sp)
    80002416:	6942                	ld	s2,16(sp)
    80002418:	69a2                	ld	s3,8(sp)
    8000241a:	6145                	addi	sp,sp,48
    8000241c:	8082                	ret
        p->state = RUNNABLE;
    8000241e:	478d                	li	a5,3
    80002420:	cc9c                	sw	a5,24(s1)
    80002422:	b7cd                	j	80002404 <kill+0x52>

0000000080002424 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002424:	7179                	addi	sp,sp,-48
    80002426:	f406                	sd	ra,40(sp)
    80002428:	f022                	sd	s0,32(sp)
    8000242a:	ec26                	sd	s1,24(sp)
    8000242c:	e84a                	sd	s2,16(sp)
    8000242e:	e44e                	sd	s3,8(sp)
    80002430:	e052                	sd	s4,0(sp)
    80002432:	1800                	addi	s0,sp,48
    80002434:	84aa                	mv	s1,a0
    80002436:	892e                	mv	s2,a1
    80002438:	89b2                	mv	s3,a2
    8000243a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000243c:	fffff097          	auipc	ra,0xfffff
    80002440:	584080e7          	jalr	1412(ra) # 800019c0 <myproc>
  if(user_dst){
    80002444:	c08d                	beqz	s1,80002466 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002446:	86d2                	mv	a3,s4
    80002448:	864e                	mv	a2,s3
    8000244a:	85ca                	mv	a1,s2
    8000244c:	6928                	ld	a0,80(a0)
    8000244e:	fffff097          	auipc	ra,0xfffff
    80002452:	232080e7          	jalr	562(ra) # 80001680 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002456:	70a2                	ld	ra,40(sp)
    80002458:	7402                	ld	s0,32(sp)
    8000245a:	64e2                	ld	s1,24(sp)
    8000245c:	6942                	ld	s2,16(sp)
    8000245e:	69a2                	ld	s3,8(sp)
    80002460:	6a02                	ld	s4,0(sp)
    80002462:	6145                	addi	sp,sp,48
    80002464:	8082                	ret
    memmove((char *)dst, src, len);
    80002466:	000a061b          	sext.w	a2,s4
    8000246a:	85ce                	mv	a1,s3
    8000246c:	854a                	mv	a0,s2
    8000246e:	fffff097          	auipc	ra,0xfffff
    80002472:	8ac080e7          	jalr	-1876(ra) # 80000d1a <memmove>
    return 0;
    80002476:	8526                	mv	a0,s1
    80002478:	bff9                	j	80002456 <either_copyout+0x32>

000000008000247a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000247a:	7179                	addi	sp,sp,-48
    8000247c:	f406                	sd	ra,40(sp)
    8000247e:	f022                	sd	s0,32(sp)
    80002480:	ec26                	sd	s1,24(sp)
    80002482:	e84a                	sd	s2,16(sp)
    80002484:	e44e                	sd	s3,8(sp)
    80002486:	e052                	sd	s4,0(sp)
    80002488:	1800                	addi	s0,sp,48
    8000248a:	892a                	mv	s2,a0
    8000248c:	84ae                	mv	s1,a1
    8000248e:	89b2                	mv	s3,a2
    80002490:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002492:	fffff097          	auipc	ra,0xfffff
    80002496:	52e080e7          	jalr	1326(ra) # 800019c0 <myproc>
  if(user_src){
    8000249a:	c08d                	beqz	s1,800024bc <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000249c:	86d2                	mv	a3,s4
    8000249e:	864e                	mv	a2,s3
    800024a0:	85ca                	mv	a1,s2
    800024a2:	6928                	ld	a0,80(a0)
    800024a4:	fffff097          	auipc	ra,0xfffff
    800024a8:	268080e7          	jalr	616(ra) # 8000170c <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024ac:	70a2                	ld	ra,40(sp)
    800024ae:	7402                	ld	s0,32(sp)
    800024b0:	64e2                	ld	s1,24(sp)
    800024b2:	6942                	ld	s2,16(sp)
    800024b4:	69a2                	ld	s3,8(sp)
    800024b6:	6a02                	ld	s4,0(sp)
    800024b8:	6145                	addi	sp,sp,48
    800024ba:	8082                	ret
    memmove(dst, (char*)src, len);
    800024bc:	000a061b          	sext.w	a2,s4
    800024c0:	85ce                	mv	a1,s3
    800024c2:	854a                	mv	a0,s2
    800024c4:	fffff097          	auipc	ra,0xfffff
    800024c8:	856080e7          	jalr	-1962(ra) # 80000d1a <memmove>
    return 0;
    800024cc:	8526                	mv	a0,s1
    800024ce:	bff9                	j	800024ac <either_copyin+0x32>

00000000800024d0 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024d0:	715d                	addi	sp,sp,-80
    800024d2:	e486                	sd	ra,72(sp)
    800024d4:	e0a2                	sd	s0,64(sp)
    800024d6:	fc26                	sd	s1,56(sp)
    800024d8:	f84a                	sd	s2,48(sp)
    800024da:	f44e                	sd	s3,40(sp)
    800024dc:	f052                	sd	s4,32(sp)
    800024de:	ec56                	sd	s5,24(sp)
    800024e0:	e85a                	sd	s6,16(sp)
    800024e2:	e45e                	sd	s7,8(sp)
    800024e4:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024e6:	00006517          	auipc	a0,0x6
    800024ea:	be250513          	addi	a0,a0,-1054 # 800080c8 <digits+0x88>
    800024ee:	ffffe097          	auipc	ra,0xffffe
    800024f2:	086080e7          	jalr	134(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024f6:	0000f497          	auipc	s1,0xf
    800024fa:	33248493          	addi	s1,s1,818 # 80011828 <proc+0x158>
    800024fe:	00015917          	auipc	s2,0x15
    80002502:	d2a90913          	addi	s2,s2,-726 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002506:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002508:	00006997          	auipc	s3,0x6
    8000250c:	d6098993          	addi	s3,s3,-672 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    80002510:	00006a97          	auipc	s5,0x6
    80002514:	d60a8a93          	addi	s5,s5,-672 # 80008270 <digits+0x230>
    printf("\n");
    80002518:	00006a17          	auipc	s4,0x6
    8000251c:	bb0a0a13          	addi	s4,s4,-1104 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002520:	00006b97          	auipc	s7,0x6
    80002524:	d88b8b93          	addi	s7,s7,-632 # 800082a8 <states.0>
    80002528:	a00d                	j	8000254a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000252a:	ed86a583          	lw	a1,-296(a3)
    8000252e:	8556                	mv	a0,s5
    80002530:	ffffe097          	auipc	ra,0xffffe
    80002534:	044080e7          	jalr	68(ra) # 80000574 <printf>
    printf("\n");
    80002538:	8552                	mv	a0,s4
    8000253a:	ffffe097          	auipc	ra,0xffffe
    8000253e:	03a080e7          	jalr	58(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002542:	16848493          	addi	s1,s1,360
    80002546:	03248163          	beq	s1,s2,80002568 <procdump+0x98>
    if(p->state == UNUSED)
    8000254a:	86a6                	mv	a3,s1
    8000254c:	ec04a783          	lw	a5,-320(s1)
    80002550:	dbed                	beqz	a5,80002542 <procdump+0x72>
      state = "???";
    80002552:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002554:	fcfb6be3          	bltu	s6,a5,8000252a <procdump+0x5a>
    80002558:	1782                	slli	a5,a5,0x20
    8000255a:	9381                	srli	a5,a5,0x20
    8000255c:	078e                	slli	a5,a5,0x3
    8000255e:	97de                	add	a5,a5,s7
    80002560:	6390                	ld	a2,0(a5)
    80002562:	f661                	bnez	a2,8000252a <procdump+0x5a>
      state = "???";
    80002564:	864e                	mv	a2,s3
    80002566:	b7d1                	j	8000252a <procdump+0x5a>
  }
}
    80002568:	60a6                	ld	ra,72(sp)
    8000256a:	6406                	ld	s0,64(sp)
    8000256c:	74e2                	ld	s1,56(sp)
    8000256e:	7942                	ld	s2,48(sp)
    80002570:	79a2                	ld	s3,40(sp)
    80002572:	7a02                	ld	s4,32(sp)
    80002574:	6ae2                	ld	s5,24(sp)
    80002576:	6b42                	ld	s6,16(sp)
    80002578:	6ba2                	ld	s7,8(sp)
    8000257a:	6161                	addi	sp,sp,80
    8000257c:	8082                	ret

000000008000257e <swtch>:
    8000257e:	00153023          	sd	ra,0(a0)
    80002582:	00253423          	sd	sp,8(a0)
    80002586:	e900                	sd	s0,16(a0)
    80002588:	ed04                	sd	s1,24(a0)
    8000258a:	03253023          	sd	s2,32(a0)
    8000258e:	03353423          	sd	s3,40(a0)
    80002592:	03453823          	sd	s4,48(a0)
    80002596:	03553c23          	sd	s5,56(a0)
    8000259a:	05653023          	sd	s6,64(a0)
    8000259e:	05753423          	sd	s7,72(a0)
    800025a2:	05853823          	sd	s8,80(a0)
    800025a6:	05953c23          	sd	s9,88(a0)
    800025aa:	07a53023          	sd	s10,96(a0)
    800025ae:	07b53423          	sd	s11,104(a0)
    800025b2:	0005b083          	ld	ra,0(a1)
    800025b6:	0085b103          	ld	sp,8(a1)
    800025ba:	6980                	ld	s0,16(a1)
    800025bc:	6d84                	ld	s1,24(a1)
    800025be:	0205b903          	ld	s2,32(a1)
    800025c2:	0285b983          	ld	s3,40(a1)
    800025c6:	0305ba03          	ld	s4,48(a1)
    800025ca:	0385ba83          	ld	s5,56(a1)
    800025ce:	0405bb03          	ld	s6,64(a1)
    800025d2:	0485bb83          	ld	s7,72(a1)
    800025d6:	0505bc03          	ld	s8,80(a1)
    800025da:	0585bc83          	ld	s9,88(a1)
    800025de:	0605bd03          	ld	s10,96(a1)
    800025e2:	0685bd83          	ld	s11,104(a1)
    800025e6:	8082                	ret

00000000800025e8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800025e8:	1141                	addi	sp,sp,-16
    800025ea:	e406                	sd	ra,8(sp)
    800025ec:	e022                	sd	s0,0(sp)
    800025ee:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800025f0:	00006597          	auipc	a1,0x6
    800025f4:	ce858593          	addi	a1,a1,-792 # 800082d8 <states.0+0x30>
    800025f8:	00015517          	auipc	a0,0x15
    800025fc:	ad850513          	addi	a0,a0,-1320 # 800170d0 <tickslock>
    80002600:	ffffe097          	auipc	ra,0xffffe
    80002604:	532080e7          	jalr	1330(ra) # 80000b32 <initlock>
}
    80002608:	60a2                	ld	ra,8(sp)
    8000260a:	6402                	ld	s0,0(sp)
    8000260c:	0141                	addi	sp,sp,16
    8000260e:	8082                	ret

0000000080002610 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002610:	1141                	addi	sp,sp,-16
    80002612:	e422                	sd	s0,8(sp)
    80002614:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002616:	00003797          	auipc	a5,0x3
    8000261a:	7ea78793          	addi	a5,a5,2026 # 80005e00 <kernelvec>
    8000261e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002622:	6422                	ld	s0,8(sp)
    80002624:	0141                	addi	sp,sp,16
    80002626:	8082                	ret

0000000080002628 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002628:	1141                	addi	sp,sp,-16
    8000262a:	e406                	sd	ra,8(sp)
    8000262c:	e022                	sd	s0,0(sp)
    8000262e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002630:	fffff097          	auipc	ra,0xfffff
    80002634:	390080e7          	jalr	912(ra) # 800019c0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002638:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000263c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000263e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002642:	00005617          	auipc	a2,0x5
    80002646:	9be60613          	addi	a2,a2,-1602 # 80007000 <_trampoline>
    8000264a:	00005697          	auipc	a3,0x5
    8000264e:	9b668693          	addi	a3,a3,-1610 # 80007000 <_trampoline>
    80002652:	8e91                	sub	a3,a3,a2
    80002654:	040007b7          	lui	a5,0x4000
    80002658:	17fd                	addi	a5,a5,-1
    8000265a:	07b2                	slli	a5,a5,0xc
    8000265c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000265e:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002662:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002664:	180026f3          	csrr	a3,satp
    80002668:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000266a:	6d38                	ld	a4,88(a0)
    8000266c:	6134                	ld	a3,64(a0)
    8000266e:	6585                	lui	a1,0x1
    80002670:	96ae                	add	a3,a3,a1
    80002672:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002674:	6d38                	ld	a4,88(a0)
    80002676:	00000697          	auipc	a3,0x0
    8000267a:	13868693          	addi	a3,a3,312 # 800027ae <usertrap>
    8000267e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002680:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002682:	8692                	mv	a3,tp
    80002684:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002686:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000268a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000268e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002692:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002696:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002698:	6f18                	ld	a4,24(a4)
    8000269a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000269e:	692c                	ld	a1,80(a0)
    800026a0:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800026a2:	00005717          	auipc	a4,0x5
    800026a6:	9ee70713          	addi	a4,a4,-1554 # 80007090 <userret>
    800026aa:	8f11                	sub	a4,a4,a2
    800026ac:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800026ae:	577d                	li	a4,-1
    800026b0:	177e                	slli	a4,a4,0x3f
    800026b2:	8dd9                	or	a1,a1,a4
    800026b4:	02000537          	lui	a0,0x2000
    800026b8:	157d                	addi	a0,a0,-1
    800026ba:	0536                	slli	a0,a0,0xd
    800026bc:	9782                	jalr	a5
}
    800026be:	60a2                	ld	ra,8(sp)
    800026c0:	6402                	ld	s0,0(sp)
    800026c2:	0141                	addi	sp,sp,16
    800026c4:	8082                	ret

00000000800026c6 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026c6:	1101                	addi	sp,sp,-32
    800026c8:	ec06                	sd	ra,24(sp)
    800026ca:	e822                	sd	s0,16(sp)
    800026cc:	e426                	sd	s1,8(sp)
    800026ce:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800026d0:	00015497          	auipc	s1,0x15
    800026d4:	a0048493          	addi	s1,s1,-1536 # 800170d0 <tickslock>
    800026d8:	8526                	mv	a0,s1
    800026da:	ffffe097          	auipc	ra,0xffffe
    800026de:	4e8080e7          	jalr	1256(ra) # 80000bc2 <acquire>
  ticks++;
    800026e2:	00007517          	auipc	a0,0x7
    800026e6:	94e50513          	addi	a0,a0,-1714 # 80009030 <ticks>
    800026ea:	411c                	lw	a5,0(a0)
    800026ec:	2785                	addiw	a5,a5,1
    800026ee:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800026f0:	00000097          	auipc	ra,0x0
    800026f4:	b1c080e7          	jalr	-1252(ra) # 8000220c <wakeup>
  release(&tickslock);
    800026f8:	8526                	mv	a0,s1
    800026fa:	ffffe097          	auipc	ra,0xffffe
    800026fe:	57c080e7          	jalr	1404(ra) # 80000c76 <release>
}
    80002702:	60e2                	ld	ra,24(sp)
    80002704:	6442                	ld	s0,16(sp)
    80002706:	64a2                	ld	s1,8(sp)
    80002708:	6105                	addi	sp,sp,32
    8000270a:	8082                	ret

000000008000270c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000270c:	1101                	addi	sp,sp,-32
    8000270e:	ec06                	sd	ra,24(sp)
    80002710:	e822                	sd	s0,16(sp)
    80002712:	e426                	sd	s1,8(sp)
    80002714:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002716:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000271a:	00074d63          	bltz	a4,80002734 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000271e:	57fd                	li	a5,-1
    80002720:	17fe                	slli	a5,a5,0x3f
    80002722:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002724:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002726:	06f70363          	beq	a4,a5,8000278c <devintr+0x80>
  }
}
    8000272a:	60e2                	ld	ra,24(sp)
    8000272c:	6442                	ld	s0,16(sp)
    8000272e:	64a2                	ld	s1,8(sp)
    80002730:	6105                	addi	sp,sp,32
    80002732:	8082                	ret
     (scause & 0xff) == 9){
    80002734:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002738:	46a5                	li	a3,9
    8000273a:	fed792e3          	bne	a5,a3,8000271e <devintr+0x12>
    int irq = plic_claim();
    8000273e:	00003097          	auipc	ra,0x3
    80002742:	7ca080e7          	jalr	1994(ra) # 80005f08 <plic_claim>
    80002746:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002748:	47a9                	li	a5,10
    8000274a:	02f50763          	beq	a0,a5,80002778 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000274e:	4785                	li	a5,1
    80002750:	02f50963          	beq	a0,a5,80002782 <devintr+0x76>
    return 1;
    80002754:	4505                	li	a0,1
    } else if(irq){
    80002756:	d8f1                	beqz	s1,8000272a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002758:	85a6                	mv	a1,s1
    8000275a:	00006517          	auipc	a0,0x6
    8000275e:	b8650513          	addi	a0,a0,-1146 # 800082e0 <states.0+0x38>
    80002762:	ffffe097          	auipc	ra,0xffffe
    80002766:	e12080e7          	jalr	-494(ra) # 80000574 <printf>
      plic_complete(irq);
    8000276a:	8526                	mv	a0,s1
    8000276c:	00003097          	auipc	ra,0x3
    80002770:	7c0080e7          	jalr	1984(ra) # 80005f2c <plic_complete>
    return 1;
    80002774:	4505                	li	a0,1
    80002776:	bf55                	j	8000272a <devintr+0x1e>
      uartintr();
    80002778:	ffffe097          	auipc	ra,0xffffe
    8000277c:	20e080e7          	jalr	526(ra) # 80000986 <uartintr>
    80002780:	b7ed                	j	8000276a <devintr+0x5e>
      virtio_disk_intr();
    80002782:	00004097          	auipc	ra,0x4
    80002786:	c3c080e7          	jalr	-964(ra) # 800063be <virtio_disk_intr>
    8000278a:	b7c5                	j	8000276a <devintr+0x5e>
    if(cpuid() == 0){
    8000278c:	fffff097          	auipc	ra,0xfffff
    80002790:	208080e7          	jalr	520(ra) # 80001994 <cpuid>
    80002794:	c901                	beqz	a0,800027a4 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002796:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000279a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000279c:	14479073          	csrw	sip,a5
    return 2;
    800027a0:	4509                	li	a0,2
    800027a2:	b761                	j	8000272a <devintr+0x1e>
      clockintr();
    800027a4:	00000097          	auipc	ra,0x0
    800027a8:	f22080e7          	jalr	-222(ra) # 800026c6 <clockintr>
    800027ac:	b7ed                	j	80002796 <devintr+0x8a>

00000000800027ae <usertrap>:
{
    800027ae:	1101                	addi	sp,sp,-32
    800027b0:	ec06                	sd	ra,24(sp)
    800027b2:	e822                	sd	s0,16(sp)
    800027b4:	e426                	sd	s1,8(sp)
    800027b6:	e04a                	sd	s2,0(sp)
    800027b8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027ba:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800027be:	1007f793          	andi	a5,a5,256
    800027c2:	e3ad                	bnez	a5,80002824 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027c4:	00003797          	auipc	a5,0x3
    800027c8:	63c78793          	addi	a5,a5,1596 # 80005e00 <kernelvec>
    800027cc:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800027d0:	fffff097          	auipc	ra,0xfffff
    800027d4:	1f0080e7          	jalr	496(ra) # 800019c0 <myproc>
    800027d8:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800027da:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800027dc:	14102773          	csrr	a4,sepc
    800027e0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027e2:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800027e6:	47a1                	li	a5,8
    800027e8:	04f71c63          	bne	a4,a5,80002840 <usertrap+0x92>
    if(p->killed)
    800027ec:	551c                	lw	a5,40(a0)
    800027ee:	e3b9                	bnez	a5,80002834 <usertrap+0x86>
    p->trapframe->epc += 4;
    800027f0:	6cb8                	ld	a4,88(s1)
    800027f2:	6f1c                	ld	a5,24(a4)
    800027f4:	0791                	addi	a5,a5,4
    800027f6:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027f8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800027fc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002800:	10079073          	csrw	sstatus,a5
    syscall();
    80002804:	00000097          	auipc	ra,0x0
    80002808:	2e0080e7          	jalr	736(ra) # 80002ae4 <syscall>
  if(p->killed)
    8000280c:	549c                	lw	a5,40(s1)
    8000280e:	ebc1                	bnez	a5,8000289e <usertrap+0xf0>
  usertrapret();
    80002810:	00000097          	auipc	ra,0x0
    80002814:	e18080e7          	jalr	-488(ra) # 80002628 <usertrapret>
}
    80002818:	60e2                	ld	ra,24(sp)
    8000281a:	6442                	ld	s0,16(sp)
    8000281c:	64a2                	ld	s1,8(sp)
    8000281e:	6902                	ld	s2,0(sp)
    80002820:	6105                	addi	sp,sp,32
    80002822:	8082                	ret
    panic("usertrap: not from user mode");
    80002824:	00006517          	auipc	a0,0x6
    80002828:	adc50513          	addi	a0,a0,-1316 # 80008300 <states.0+0x58>
    8000282c:	ffffe097          	auipc	ra,0xffffe
    80002830:	cfe080e7          	jalr	-770(ra) # 8000052a <panic>
      exit(-1);
    80002834:	557d                	li	a0,-1
    80002836:	00000097          	auipc	ra,0x0
    8000283a:	aa6080e7          	jalr	-1370(ra) # 800022dc <exit>
    8000283e:	bf4d                	j	800027f0 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002840:	00000097          	auipc	ra,0x0
    80002844:	ecc080e7          	jalr	-308(ra) # 8000270c <devintr>
    80002848:	892a                	mv	s2,a0
    8000284a:	c501                	beqz	a0,80002852 <usertrap+0xa4>
  if(p->killed)
    8000284c:	549c                	lw	a5,40(s1)
    8000284e:	c3a1                	beqz	a5,8000288e <usertrap+0xe0>
    80002850:	a815                	j	80002884 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002852:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002856:	5890                	lw	a2,48(s1)
    80002858:	00006517          	auipc	a0,0x6
    8000285c:	ac850513          	addi	a0,a0,-1336 # 80008320 <states.0+0x78>
    80002860:	ffffe097          	auipc	ra,0xffffe
    80002864:	d14080e7          	jalr	-748(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002868:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000286c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002870:	00006517          	auipc	a0,0x6
    80002874:	ae050513          	addi	a0,a0,-1312 # 80008350 <states.0+0xa8>
    80002878:	ffffe097          	auipc	ra,0xffffe
    8000287c:	cfc080e7          	jalr	-772(ra) # 80000574 <printf>
    p->killed = 1;
    80002880:	4785                	li	a5,1
    80002882:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002884:	557d                	li	a0,-1
    80002886:	00000097          	auipc	ra,0x0
    8000288a:	a56080e7          	jalr	-1450(ra) # 800022dc <exit>
  if(which_dev == 2)
    8000288e:	4789                	li	a5,2
    80002890:	f8f910e3          	bne	s2,a5,80002810 <usertrap+0x62>
    yield();
    80002894:	fffff097          	auipc	ra,0xfffff
    80002898:	7b0080e7          	jalr	1968(ra) # 80002044 <yield>
    8000289c:	bf95                	j	80002810 <usertrap+0x62>
  int which_dev = 0;
    8000289e:	4901                	li	s2,0
    800028a0:	b7d5                	j	80002884 <usertrap+0xd6>

00000000800028a2 <kerneltrap>:
{
    800028a2:	7179                	addi	sp,sp,-48
    800028a4:	f406                	sd	ra,40(sp)
    800028a6:	f022                	sd	s0,32(sp)
    800028a8:	ec26                	sd	s1,24(sp)
    800028aa:	e84a                	sd	s2,16(sp)
    800028ac:	e44e                	sd	s3,8(sp)
    800028ae:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028b0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028b4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028b8:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800028bc:	1004f793          	andi	a5,s1,256
    800028c0:	cb85                	beqz	a5,800028f0 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028c2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800028c6:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800028c8:	ef85                	bnez	a5,80002900 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800028ca:	00000097          	auipc	ra,0x0
    800028ce:	e42080e7          	jalr	-446(ra) # 8000270c <devintr>
    800028d2:	cd1d                	beqz	a0,80002910 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800028d4:	4789                	li	a5,2
    800028d6:	06f50a63          	beq	a0,a5,8000294a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028da:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028de:	10049073          	csrw	sstatus,s1
}
    800028e2:	70a2                	ld	ra,40(sp)
    800028e4:	7402                	ld	s0,32(sp)
    800028e6:	64e2                	ld	s1,24(sp)
    800028e8:	6942                	ld	s2,16(sp)
    800028ea:	69a2                	ld	s3,8(sp)
    800028ec:	6145                	addi	sp,sp,48
    800028ee:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800028f0:	00006517          	auipc	a0,0x6
    800028f4:	a8050513          	addi	a0,a0,-1408 # 80008370 <states.0+0xc8>
    800028f8:	ffffe097          	auipc	ra,0xffffe
    800028fc:	c32080e7          	jalr	-974(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80002900:	00006517          	auipc	a0,0x6
    80002904:	a9850513          	addi	a0,a0,-1384 # 80008398 <states.0+0xf0>
    80002908:	ffffe097          	auipc	ra,0xffffe
    8000290c:	c22080e7          	jalr	-990(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80002910:	85ce                	mv	a1,s3
    80002912:	00006517          	auipc	a0,0x6
    80002916:	aa650513          	addi	a0,a0,-1370 # 800083b8 <states.0+0x110>
    8000291a:	ffffe097          	auipc	ra,0xffffe
    8000291e:	c5a080e7          	jalr	-934(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002922:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002926:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000292a:	00006517          	auipc	a0,0x6
    8000292e:	a9e50513          	addi	a0,a0,-1378 # 800083c8 <states.0+0x120>
    80002932:	ffffe097          	auipc	ra,0xffffe
    80002936:	c42080e7          	jalr	-958(ra) # 80000574 <printf>
    panic("kerneltrap");
    8000293a:	00006517          	auipc	a0,0x6
    8000293e:	aa650513          	addi	a0,a0,-1370 # 800083e0 <states.0+0x138>
    80002942:	ffffe097          	auipc	ra,0xffffe
    80002946:	be8080e7          	jalr	-1048(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000294a:	fffff097          	auipc	ra,0xfffff
    8000294e:	076080e7          	jalr	118(ra) # 800019c0 <myproc>
    80002952:	d541                	beqz	a0,800028da <kerneltrap+0x38>
    80002954:	fffff097          	auipc	ra,0xfffff
    80002958:	06c080e7          	jalr	108(ra) # 800019c0 <myproc>
    8000295c:	4d18                	lw	a4,24(a0)
    8000295e:	4791                	li	a5,4
    80002960:	f6f71de3          	bne	a4,a5,800028da <kerneltrap+0x38>
    yield();
    80002964:	fffff097          	auipc	ra,0xfffff
    80002968:	6e0080e7          	jalr	1760(ra) # 80002044 <yield>
    8000296c:	b7bd                	j	800028da <kerneltrap+0x38>

000000008000296e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000296e:	1101                	addi	sp,sp,-32
    80002970:	ec06                	sd	ra,24(sp)
    80002972:	e822                	sd	s0,16(sp)
    80002974:	e426                	sd	s1,8(sp)
    80002976:	1000                	addi	s0,sp,32
    80002978:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000297a:	fffff097          	auipc	ra,0xfffff
    8000297e:	046080e7          	jalr	70(ra) # 800019c0 <myproc>
  switch (n) {
    80002982:	4795                	li	a5,5
    80002984:	0497e163          	bltu	a5,s1,800029c6 <argraw+0x58>
    80002988:	048a                	slli	s1,s1,0x2
    8000298a:	00006717          	auipc	a4,0x6
    8000298e:	a8e70713          	addi	a4,a4,-1394 # 80008418 <states.0+0x170>
    80002992:	94ba                	add	s1,s1,a4
    80002994:	409c                	lw	a5,0(s1)
    80002996:	97ba                	add	a5,a5,a4
    80002998:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    8000299a:	6d3c                	ld	a5,88(a0)
    8000299c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000299e:	60e2                	ld	ra,24(sp)
    800029a0:	6442                	ld	s0,16(sp)
    800029a2:	64a2                	ld	s1,8(sp)
    800029a4:	6105                	addi	sp,sp,32
    800029a6:	8082                	ret
    return p->trapframe->a1;
    800029a8:	6d3c                	ld	a5,88(a0)
    800029aa:	7fa8                	ld	a0,120(a5)
    800029ac:	bfcd                	j	8000299e <argraw+0x30>
    return p->trapframe->a2;
    800029ae:	6d3c                	ld	a5,88(a0)
    800029b0:	63c8                	ld	a0,128(a5)
    800029b2:	b7f5                	j	8000299e <argraw+0x30>
    return p->trapframe->a3;
    800029b4:	6d3c                	ld	a5,88(a0)
    800029b6:	67c8                	ld	a0,136(a5)
    800029b8:	b7dd                	j	8000299e <argraw+0x30>
    return p->trapframe->a4;
    800029ba:	6d3c                	ld	a5,88(a0)
    800029bc:	6bc8                	ld	a0,144(a5)
    800029be:	b7c5                	j	8000299e <argraw+0x30>
    return p->trapframe->a5;
    800029c0:	6d3c                	ld	a5,88(a0)
    800029c2:	6fc8                	ld	a0,152(a5)
    800029c4:	bfe9                	j	8000299e <argraw+0x30>
  panic("argraw");
    800029c6:	00006517          	auipc	a0,0x6
    800029ca:	a2a50513          	addi	a0,a0,-1494 # 800083f0 <states.0+0x148>
    800029ce:	ffffe097          	auipc	ra,0xffffe
    800029d2:	b5c080e7          	jalr	-1188(ra) # 8000052a <panic>

00000000800029d6 <fetchaddr>:
{
    800029d6:	1101                	addi	sp,sp,-32
    800029d8:	ec06                	sd	ra,24(sp)
    800029da:	e822                	sd	s0,16(sp)
    800029dc:	e426                	sd	s1,8(sp)
    800029de:	e04a                	sd	s2,0(sp)
    800029e0:	1000                	addi	s0,sp,32
    800029e2:	84aa                	mv	s1,a0
    800029e4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800029e6:	fffff097          	auipc	ra,0xfffff
    800029ea:	fda080e7          	jalr	-38(ra) # 800019c0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800029ee:	653c                	ld	a5,72(a0)
    800029f0:	02f4f863          	bgeu	s1,a5,80002a20 <fetchaddr+0x4a>
    800029f4:	00848713          	addi	a4,s1,8
    800029f8:	02e7e663          	bltu	a5,a4,80002a24 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800029fc:	46a1                	li	a3,8
    800029fe:	8626                	mv	a2,s1
    80002a00:	85ca                	mv	a1,s2
    80002a02:	6928                	ld	a0,80(a0)
    80002a04:	fffff097          	auipc	ra,0xfffff
    80002a08:	d08080e7          	jalr	-760(ra) # 8000170c <copyin>
    80002a0c:	00a03533          	snez	a0,a0
    80002a10:	40a00533          	neg	a0,a0
}
    80002a14:	60e2                	ld	ra,24(sp)
    80002a16:	6442                	ld	s0,16(sp)
    80002a18:	64a2                	ld	s1,8(sp)
    80002a1a:	6902                	ld	s2,0(sp)
    80002a1c:	6105                	addi	sp,sp,32
    80002a1e:	8082                	ret
    return -1;
    80002a20:	557d                	li	a0,-1
    80002a22:	bfcd                	j	80002a14 <fetchaddr+0x3e>
    80002a24:	557d                	li	a0,-1
    80002a26:	b7fd                	j	80002a14 <fetchaddr+0x3e>

0000000080002a28 <fetchstr>:
{
    80002a28:	7179                	addi	sp,sp,-48
    80002a2a:	f406                	sd	ra,40(sp)
    80002a2c:	f022                	sd	s0,32(sp)
    80002a2e:	ec26                	sd	s1,24(sp)
    80002a30:	e84a                	sd	s2,16(sp)
    80002a32:	e44e                	sd	s3,8(sp)
    80002a34:	1800                	addi	s0,sp,48
    80002a36:	892a                	mv	s2,a0
    80002a38:	84ae                	mv	s1,a1
    80002a3a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a3c:	fffff097          	auipc	ra,0xfffff
    80002a40:	f84080e7          	jalr	-124(ra) # 800019c0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a44:	86ce                	mv	a3,s3
    80002a46:	864a                	mv	a2,s2
    80002a48:	85a6                	mv	a1,s1
    80002a4a:	6928                	ld	a0,80(a0)
    80002a4c:	fffff097          	auipc	ra,0xfffff
    80002a50:	d4e080e7          	jalr	-690(ra) # 8000179a <copyinstr>
  if(err < 0)
    80002a54:	00054763          	bltz	a0,80002a62 <fetchstr+0x3a>
  return strlen(buf);
    80002a58:	8526                	mv	a0,s1
    80002a5a:	ffffe097          	auipc	ra,0xffffe
    80002a5e:	3e8080e7          	jalr	1000(ra) # 80000e42 <strlen>
}
    80002a62:	70a2                	ld	ra,40(sp)
    80002a64:	7402                	ld	s0,32(sp)
    80002a66:	64e2                	ld	s1,24(sp)
    80002a68:	6942                	ld	s2,16(sp)
    80002a6a:	69a2                	ld	s3,8(sp)
    80002a6c:	6145                	addi	sp,sp,48
    80002a6e:	8082                	ret

0000000080002a70 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002a70:	1101                	addi	sp,sp,-32
    80002a72:	ec06                	sd	ra,24(sp)
    80002a74:	e822                	sd	s0,16(sp)
    80002a76:	e426                	sd	s1,8(sp)
    80002a78:	1000                	addi	s0,sp,32
    80002a7a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a7c:	00000097          	auipc	ra,0x0
    80002a80:	ef2080e7          	jalr	-270(ra) # 8000296e <argraw>
    80002a84:	c088                	sw	a0,0(s1)
  return 0;
}
    80002a86:	4501                	li	a0,0
    80002a88:	60e2                	ld	ra,24(sp)
    80002a8a:	6442                	ld	s0,16(sp)
    80002a8c:	64a2                	ld	s1,8(sp)
    80002a8e:	6105                	addi	sp,sp,32
    80002a90:	8082                	ret

0000000080002a92 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002a92:	1101                	addi	sp,sp,-32
    80002a94:	ec06                	sd	ra,24(sp)
    80002a96:	e822                	sd	s0,16(sp)
    80002a98:	e426                	sd	s1,8(sp)
    80002a9a:	1000                	addi	s0,sp,32
    80002a9c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a9e:	00000097          	auipc	ra,0x0
    80002aa2:	ed0080e7          	jalr	-304(ra) # 8000296e <argraw>
    80002aa6:	e088                	sd	a0,0(s1)
  return 0;
}
    80002aa8:	4501                	li	a0,0
    80002aaa:	60e2                	ld	ra,24(sp)
    80002aac:	6442                	ld	s0,16(sp)
    80002aae:	64a2                	ld	s1,8(sp)
    80002ab0:	6105                	addi	sp,sp,32
    80002ab2:	8082                	ret

0000000080002ab4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ab4:	1101                	addi	sp,sp,-32
    80002ab6:	ec06                	sd	ra,24(sp)
    80002ab8:	e822                	sd	s0,16(sp)
    80002aba:	e426                	sd	s1,8(sp)
    80002abc:	e04a                	sd	s2,0(sp)
    80002abe:	1000                	addi	s0,sp,32
    80002ac0:	84ae                	mv	s1,a1
    80002ac2:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002ac4:	00000097          	auipc	ra,0x0
    80002ac8:	eaa080e7          	jalr	-342(ra) # 8000296e <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002acc:	864a                	mv	a2,s2
    80002ace:	85a6                	mv	a1,s1
    80002ad0:	00000097          	auipc	ra,0x0
    80002ad4:	f58080e7          	jalr	-168(ra) # 80002a28 <fetchstr>
}
    80002ad8:	60e2                	ld	ra,24(sp)
    80002ada:	6442                	ld	s0,16(sp)
    80002adc:	64a2                	ld	s1,8(sp)
    80002ade:	6902                	ld	s2,0(sp)
    80002ae0:	6105                	addi	sp,sp,32
    80002ae2:	8082                	ret

0000000080002ae4 <syscall>:
[SYS_symlink]   sys_symlink,
};

void
syscall(void)
{
    80002ae4:	1101                	addi	sp,sp,-32
    80002ae6:	ec06                	sd	ra,24(sp)
    80002ae8:	e822                	sd	s0,16(sp)
    80002aea:	e426                	sd	s1,8(sp)
    80002aec:	e04a                	sd	s2,0(sp)
    80002aee:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002af0:	fffff097          	auipc	ra,0xfffff
    80002af4:	ed0080e7          	jalr	-304(ra) # 800019c0 <myproc>
    80002af8:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002afa:	05853903          	ld	s2,88(a0)
    80002afe:	0a893783          	ld	a5,168(s2)
    80002b02:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b06:	37fd                	addiw	a5,a5,-1
    80002b08:	4755                	li	a4,21
    80002b0a:	00f76f63          	bltu	a4,a5,80002b28 <syscall+0x44>
    80002b0e:	00369713          	slli	a4,a3,0x3
    80002b12:	00006797          	auipc	a5,0x6
    80002b16:	91e78793          	addi	a5,a5,-1762 # 80008430 <syscalls>
    80002b1a:	97ba                	add	a5,a5,a4
    80002b1c:	639c                	ld	a5,0(a5)
    80002b1e:	c789                	beqz	a5,80002b28 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002b20:	9782                	jalr	a5
    80002b22:	06a93823          	sd	a0,112(s2)
    80002b26:	a839                	j	80002b44 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b28:	15848613          	addi	a2,s1,344
    80002b2c:	588c                	lw	a1,48(s1)
    80002b2e:	00006517          	auipc	a0,0x6
    80002b32:	8ca50513          	addi	a0,a0,-1846 # 800083f8 <states.0+0x150>
    80002b36:	ffffe097          	auipc	ra,0xffffe
    80002b3a:	a3e080e7          	jalr	-1474(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b3e:	6cbc                	ld	a5,88(s1)
    80002b40:	577d                	li	a4,-1
    80002b42:	fbb8                	sd	a4,112(a5)
  }
}
    80002b44:	60e2                	ld	ra,24(sp)
    80002b46:	6442                	ld	s0,16(sp)
    80002b48:	64a2                	ld	s1,8(sp)
    80002b4a:	6902                	ld	s2,0(sp)
    80002b4c:	6105                	addi	sp,sp,32
    80002b4e:	8082                	ret

0000000080002b50 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002b50:	1101                	addi	sp,sp,-32
    80002b52:	ec06                	sd	ra,24(sp)
    80002b54:	e822                	sd	s0,16(sp)
    80002b56:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002b58:	fec40593          	addi	a1,s0,-20
    80002b5c:	4501                	li	a0,0
    80002b5e:	00000097          	auipc	ra,0x0
    80002b62:	f12080e7          	jalr	-238(ra) # 80002a70 <argint>
    return -1;
    80002b66:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002b68:	00054963          	bltz	a0,80002b7a <sys_exit+0x2a>
  exit(n);
    80002b6c:	fec42503          	lw	a0,-20(s0)
    80002b70:	fffff097          	auipc	ra,0xfffff
    80002b74:	76c080e7          	jalr	1900(ra) # 800022dc <exit>
  return 0;  // not reached
    80002b78:	4781                	li	a5,0
}
    80002b7a:	853e                	mv	a0,a5
    80002b7c:	60e2                	ld	ra,24(sp)
    80002b7e:	6442                	ld	s0,16(sp)
    80002b80:	6105                	addi	sp,sp,32
    80002b82:	8082                	ret

0000000080002b84 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002b84:	1141                	addi	sp,sp,-16
    80002b86:	e406                	sd	ra,8(sp)
    80002b88:	e022                	sd	s0,0(sp)
    80002b8a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002b8c:	fffff097          	auipc	ra,0xfffff
    80002b90:	e34080e7          	jalr	-460(ra) # 800019c0 <myproc>
}
    80002b94:	5908                	lw	a0,48(a0)
    80002b96:	60a2                	ld	ra,8(sp)
    80002b98:	6402                	ld	s0,0(sp)
    80002b9a:	0141                	addi	sp,sp,16
    80002b9c:	8082                	ret

0000000080002b9e <sys_fork>:

uint64
sys_fork(void)
{
    80002b9e:	1141                	addi	sp,sp,-16
    80002ba0:	e406                	sd	ra,8(sp)
    80002ba2:	e022                	sd	s0,0(sp)
    80002ba4:	0800                	addi	s0,sp,16
  return fork();
    80002ba6:	fffff097          	auipc	ra,0xfffff
    80002baa:	1e8080e7          	jalr	488(ra) # 80001d8e <fork>
}
    80002bae:	60a2                	ld	ra,8(sp)
    80002bb0:	6402                	ld	s0,0(sp)
    80002bb2:	0141                	addi	sp,sp,16
    80002bb4:	8082                	ret

0000000080002bb6 <sys_wait>:

uint64
sys_wait(void)
{
    80002bb6:	1101                	addi	sp,sp,-32
    80002bb8:	ec06                	sd	ra,24(sp)
    80002bba:	e822                	sd	s0,16(sp)
    80002bbc:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002bbe:	fe840593          	addi	a1,s0,-24
    80002bc2:	4501                	li	a0,0
    80002bc4:	00000097          	auipc	ra,0x0
    80002bc8:	ece080e7          	jalr	-306(ra) # 80002a92 <argaddr>
    80002bcc:	87aa                	mv	a5,a0
    return -1;
    80002bce:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002bd0:	0007c863          	bltz	a5,80002be0 <sys_wait+0x2a>
  return wait(p);
    80002bd4:	fe843503          	ld	a0,-24(s0)
    80002bd8:	fffff097          	auipc	ra,0xfffff
    80002bdc:	50c080e7          	jalr	1292(ra) # 800020e4 <wait>
}
    80002be0:	60e2                	ld	ra,24(sp)
    80002be2:	6442                	ld	s0,16(sp)
    80002be4:	6105                	addi	sp,sp,32
    80002be6:	8082                	ret

0000000080002be8 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002be8:	7179                	addi	sp,sp,-48
    80002bea:	f406                	sd	ra,40(sp)
    80002bec:	f022                	sd	s0,32(sp)
    80002bee:	ec26                	sd	s1,24(sp)
    80002bf0:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002bf2:	fdc40593          	addi	a1,s0,-36
    80002bf6:	4501                	li	a0,0
    80002bf8:	00000097          	auipc	ra,0x0
    80002bfc:	e78080e7          	jalr	-392(ra) # 80002a70 <argint>
    return -1;
    80002c00:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002c02:	00054f63          	bltz	a0,80002c20 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002c06:	fffff097          	auipc	ra,0xfffff
    80002c0a:	dba080e7          	jalr	-582(ra) # 800019c0 <myproc>
    80002c0e:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002c10:	fdc42503          	lw	a0,-36(s0)
    80002c14:	fffff097          	auipc	ra,0xfffff
    80002c18:	106080e7          	jalr	262(ra) # 80001d1a <growproc>
    80002c1c:	00054863          	bltz	a0,80002c2c <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002c20:	8526                	mv	a0,s1
    80002c22:	70a2                	ld	ra,40(sp)
    80002c24:	7402                	ld	s0,32(sp)
    80002c26:	64e2                	ld	s1,24(sp)
    80002c28:	6145                	addi	sp,sp,48
    80002c2a:	8082                	ret
    return -1;
    80002c2c:	54fd                	li	s1,-1
    80002c2e:	bfcd                	j	80002c20 <sys_sbrk+0x38>

0000000080002c30 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c30:	7139                	addi	sp,sp,-64
    80002c32:	fc06                	sd	ra,56(sp)
    80002c34:	f822                	sd	s0,48(sp)
    80002c36:	f426                	sd	s1,40(sp)
    80002c38:	f04a                	sd	s2,32(sp)
    80002c3a:	ec4e                	sd	s3,24(sp)
    80002c3c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002c3e:	fcc40593          	addi	a1,s0,-52
    80002c42:	4501                	li	a0,0
    80002c44:	00000097          	auipc	ra,0x0
    80002c48:	e2c080e7          	jalr	-468(ra) # 80002a70 <argint>
    return -1;
    80002c4c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c4e:	06054563          	bltz	a0,80002cb8 <sys_sleep+0x88>
  acquire(&tickslock);
    80002c52:	00014517          	auipc	a0,0x14
    80002c56:	47e50513          	addi	a0,a0,1150 # 800170d0 <tickslock>
    80002c5a:	ffffe097          	auipc	ra,0xffffe
    80002c5e:	f68080e7          	jalr	-152(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80002c62:	00006917          	auipc	s2,0x6
    80002c66:	3ce92903          	lw	s2,974(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002c6a:	fcc42783          	lw	a5,-52(s0)
    80002c6e:	cf85                	beqz	a5,80002ca6 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002c70:	00014997          	auipc	s3,0x14
    80002c74:	46098993          	addi	s3,s3,1120 # 800170d0 <tickslock>
    80002c78:	00006497          	auipc	s1,0x6
    80002c7c:	3b848493          	addi	s1,s1,952 # 80009030 <ticks>
    if(myproc()->killed){
    80002c80:	fffff097          	auipc	ra,0xfffff
    80002c84:	d40080e7          	jalr	-704(ra) # 800019c0 <myproc>
    80002c88:	551c                	lw	a5,40(a0)
    80002c8a:	ef9d                	bnez	a5,80002cc8 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002c8c:	85ce                	mv	a1,s3
    80002c8e:	8526                	mv	a0,s1
    80002c90:	fffff097          	auipc	ra,0xfffff
    80002c94:	3f0080e7          	jalr	1008(ra) # 80002080 <sleep>
  while(ticks - ticks0 < n){
    80002c98:	409c                	lw	a5,0(s1)
    80002c9a:	412787bb          	subw	a5,a5,s2
    80002c9e:	fcc42703          	lw	a4,-52(s0)
    80002ca2:	fce7efe3          	bltu	a5,a4,80002c80 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002ca6:	00014517          	auipc	a0,0x14
    80002caa:	42a50513          	addi	a0,a0,1066 # 800170d0 <tickslock>
    80002cae:	ffffe097          	auipc	ra,0xffffe
    80002cb2:	fc8080e7          	jalr	-56(ra) # 80000c76 <release>
  return 0;
    80002cb6:	4781                	li	a5,0
}
    80002cb8:	853e                	mv	a0,a5
    80002cba:	70e2                	ld	ra,56(sp)
    80002cbc:	7442                	ld	s0,48(sp)
    80002cbe:	74a2                	ld	s1,40(sp)
    80002cc0:	7902                	ld	s2,32(sp)
    80002cc2:	69e2                	ld	s3,24(sp)
    80002cc4:	6121                	addi	sp,sp,64
    80002cc6:	8082                	ret
      release(&tickslock);
    80002cc8:	00014517          	auipc	a0,0x14
    80002ccc:	40850513          	addi	a0,a0,1032 # 800170d0 <tickslock>
    80002cd0:	ffffe097          	auipc	ra,0xffffe
    80002cd4:	fa6080e7          	jalr	-90(ra) # 80000c76 <release>
      return -1;
    80002cd8:	57fd                	li	a5,-1
    80002cda:	bff9                	j	80002cb8 <sys_sleep+0x88>

0000000080002cdc <sys_kill>:

uint64
sys_kill(void)
{
    80002cdc:	1101                	addi	sp,sp,-32
    80002cde:	ec06                	sd	ra,24(sp)
    80002ce0:	e822                	sd	s0,16(sp)
    80002ce2:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002ce4:	fec40593          	addi	a1,s0,-20
    80002ce8:	4501                	li	a0,0
    80002cea:	00000097          	auipc	ra,0x0
    80002cee:	d86080e7          	jalr	-634(ra) # 80002a70 <argint>
    80002cf2:	87aa                	mv	a5,a0
    return -1;
    80002cf4:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002cf6:	0007c863          	bltz	a5,80002d06 <sys_kill+0x2a>
  return kill(pid);
    80002cfa:	fec42503          	lw	a0,-20(s0)
    80002cfe:	fffff097          	auipc	ra,0xfffff
    80002d02:	6b4080e7          	jalr	1716(ra) # 800023b2 <kill>
}
    80002d06:	60e2                	ld	ra,24(sp)
    80002d08:	6442                	ld	s0,16(sp)
    80002d0a:	6105                	addi	sp,sp,32
    80002d0c:	8082                	ret

0000000080002d0e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d0e:	1101                	addi	sp,sp,-32
    80002d10:	ec06                	sd	ra,24(sp)
    80002d12:	e822                	sd	s0,16(sp)
    80002d14:	e426                	sd	s1,8(sp)
    80002d16:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d18:	00014517          	auipc	a0,0x14
    80002d1c:	3b850513          	addi	a0,a0,952 # 800170d0 <tickslock>
    80002d20:	ffffe097          	auipc	ra,0xffffe
    80002d24:	ea2080e7          	jalr	-350(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80002d28:	00006497          	auipc	s1,0x6
    80002d2c:	3084a483          	lw	s1,776(s1) # 80009030 <ticks>
  release(&tickslock);
    80002d30:	00014517          	auipc	a0,0x14
    80002d34:	3a050513          	addi	a0,a0,928 # 800170d0 <tickslock>
    80002d38:	ffffe097          	auipc	ra,0xffffe
    80002d3c:	f3e080e7          	jalr	-194(ra) # 80000c76 <release>
  return xticks;
}
    80002d40:	02049513          	slli	a0,s1,0x20
    80002d44:	9101                	srli	a0,a0,0x20
    80002d46:	60e2                	ld	ra,24(sp)
    80002d48:	6442                	ld	s0,16(sp)
    80002d4a:	64a2                	ld	s1,8(sp)
    80002d4c:	6105                	addi	sp,sp,32
    80002d4e:	8082                	ret

0000000080002d50 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002d50:	7179                	addi	sp,sp,-48
    80002d52:	f406                	sd	ra,40(sp)
    80002d54:	f022                	sd	s0,32(sp)
    80002d56:	ec26                	sd	s1,24(sp)
    80002d58:	e84a                	sd	s2,16(sp)
    80002d5a:	e44e                	sd	s3,8(sp)
    80002d5c:	e052                	sd	s4,0(sp)
    80002d5e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002d60:	00005597          	auipc	a1,0x5
    80002d64:	78858593          	addi	a1,a1,1928 # 800084e8 <syscalls+0xb8>
    80002d68:	00014517          	auipc	a0,0x14
    80002d6c:	38050513          	addi	a0,a0,896 # 800170e8 <bcache>
    80002d70:	ffffe097          	auipc	ra,0xffffe
    80002d74:	dc2080e7          	jalr	-574(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002d78:	0001c797          	auipc	a5,0x1c
    80002d7c:	37078793          	addi	a5,a5,880 # 8001f0e8 <bcache+0x8000>
    80002d80:	0001c717          	auipc	a4,0x1c
    80002d84:	5d070713          	addi	a4,a4,1488 # 8001f350 <bcache+0x8268>
    80002d88:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002d8c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002d90:	00014497          	auipc	s1,0x14
    80002d94:	37048493          	addi	s1,s1,880 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002d98:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002d9a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002d9c:	00005a17          	auipc	s4,0x5
    80002da0:	754a0a13          	addi	s4,s4,1876 # 800084f0 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002da4:	2b893783          	ld	a5,696(s2)
    80002da8:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002daa:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002dae:	85d2                	mv	a1,s4
    80002db0:	01048513          	addi	a0,s1,16
    80002db4:	00001097          	auipc	ra,0x1
    80002db8:	6ca080e7          	jalr	1738(ra) # 8000447e <initsleeplock>
    bcache.head.next->prev = b;
    80002dbc:	2b893783          	ld	a5,696(s2)
    80002dc0:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002dc2:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002dc6:	45848493          	addi	s1,s1,1112
    80002dca:	fd349de3          	bne	s1,s3,80002da4 <binit+0x54>
  }
}
    80002dce:	70a2                	ld	ra,40(sp)
    80002dd0:	7402                	ld	s0,32(sp)
    80002dd2:	64e2                	ld	s1,24(sp)
    80002dd4:	6942                	ld	s2,16(sp)
    80002dd6:	69a2                	ld	s3,8(sp)
    80002dd8:	6a02                	ld	s4,0(sp)
    80002dda:	6145                	addi	sp,sp,48
    80002ddc:	8082                	ret

0000000080002dde <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002dde:	7179                	addi	sp,sp,-48
    80002de0:	f406                	sd	ra,40(sp)
    80002de2:	f022                	sd	s0,32(sp)
    80002de4:	ec26                	sd	s1,24(sp)
    80002de6:	e84a                	sd	s2,16(sp)
    80002de8:	e44e                	sd	s3,8(sp)
    80002dea:	1800                	addi	s0,sp,48
    80002dec:	892a                	mv	s2,a0
    80002dee:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002df0:	00014517          	auipc	a0,0x14
    80002df4:	2f850513          	addi	a0,a0,760 # 800170e8 <bcache>
    80002df8:	ffffe097          	auipc	ra,0xffffe
    80002dfc:	dca080e7          	jalr	-566(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e00:	0001c497          	auipc	s1,0x1c
    80002e04:	5a04b483          	ld	s1,1440(s1) # 8001f3a0 <bcache+0x82b8>
    80002e08:	0001c797          	auipc	a5,0x1c
    80002e0c:	54878793          	addi	a5,a5,1352 # 8001f350 <bcache+0x8268>
    80002e10:	02f48f63          	beq	s1,a5,80002e4e <bread+0x70>
    80002e14:	873e                	mv	a4,a5
    80002e16:	a021                	j	80002e1e <bread+0x40>
    80002e18:	68a4                	ld	s1,80(s1)
    80002e1a:	02e48a63          	beq	s1,a4,80002e4e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e1e:	449c                	lw	a5,8(s1)
    80002e20:	ff279ce3          	bne	a5,s2,80002e18 <bread+0x3a>
    80002e24:	44dc                	lw	a5,12(s1)
    80002e26:	ff3799e3          	bne	a5,s3,80002e18 <bread+0x3a>
      b->refcnt++;
    80002e2a:	40bc                	lw	a5,64(s1)
    80002e2c:	2785                	addiw	a5,a5,1
    80002e2e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e30:	00014517          	auipc	a0,0x14
    80002e34:	2b850513          	addi	a0,a0,696 # 800170e8 <bcache>
    80002e38:	ffffe097          	auipc	ra,0xffffe
    80002e3c:	e3e080e7          	jalr	-450(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80002e40:	01048513          	addi	a0,s1,16
    80002e44:	00001097          	auipc	ra,0x1
    80002e48:	674080e7          	jalr	1652(ra) # 800044b8 <acquiresleep>
      return b;
    80002e4c:	a8b9                	j	80002eaa <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e4e:	0001c497          	auipc	s1,0x1c
    80002e52:	54a4b483          	ld	s1,1354(s1) # 8001f398 <bcache+0x82b0>
    80002e56:	0001c797          	auipc	a5,0x1c
    80002e5a:	4fa78793          	addi	a5,a5,1274 # 8001f350 <bcache+0x8268>
    80002e5e:	00f48863          	beq	s1,a5,80002e6e <bread+0x90>
    80002e62:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002e64:	40bc                	lw	a5,64(s1)
    80002e66:	cf81                	beqz	a5,80002e7e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e68:	64a4                	ld	s1,72(s1)
    80002e6a:	fee49de3          	bne	s1,a4,80002e64 <bread+0x86>
  panic("bget: no buffers");
    80002e6e:	00005517          	auipc	a0,0x5
    80002e72:	68a50513          	addi	a0,a0,1674 # 800084f8 <syscalls+0xc8>
    80002e76:	ffffd097          	auipc	ra,0xffffd
    80002e7a:	6b4080e7          	jalr	1716(ra) # 8000052a <panic>
      b->dev = dev;
    80002e7e:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002e82:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002e86:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002e8a:	4785                	li	a5,1
    80002e8c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e8e:	00014517          	auipc	a0,0x14
    80002e92:	25a50513          	addi	a0,a0,602 # 800170e8 <bcache>
    80002e96:	ffffe097          	auipc	ra,0xffffe
    80002e9a:	de0080e7          	jalr	-544(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80002e9e:	01048513          	addi	a0,s1,16
    80002ea2:	00001097          	auipc	ra,0x1
    80002ea6:	616080e7          	jalr	1558(ra) # 800044b8 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002eaa:	409c                	lw	a5,0(s1)
    80002eac:	cb89                	beqz	a5,80002ebe <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002eae:	8526                	mv	a0,s1
    80002eb0:	70a2                	ld	ra,40(sp)
    80002eb2:	7402                	ld	s0,32(sp)
    80002eb4:	64e2                	ld	s1,24(sp)
    80002eb6:	6942                	ld	s2,16(sp)
    80002eb8:	69a2                	ld	s3,8(sp)
    80002eba:	6145                	addi	sp,sp,48
    80002ebc:	8082                	ret
    virtio_disk_rw(b, 0);
    80002ebe:	4581                	li	a1,0
    80002ec0:	8526                	mv	a0,s1
    80002ec2:	00003097          	auipc	ra,0x3
    80002ec6:	274080e7          	jalr	628(ra) # 80006136 <virtio_disk_rw>
    b->valid = 1;
    80002eca:	4785                	li	a5,1
    80002ecc:	c09c                	sw	a5,0(s1)
  return b;
    80002ece:	b7c5                	j	80002eae <bread+0xd0>

0000000080002ed0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002ed0:	1101                	addi	sp,sp,-32
    80002ed2:	ec06                	sd	ra,24(sp)
    80002ed4:	e822                	sd	s0,16(sp)
    80002ed6:	e426                	sd	s1,8(sp)
    80002ed8:	1000                	addi	s0,sp,32
    80002eda:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002edc:	0541                	addi	a0,a0,16
    80002ede:	00001097          	auipc	ra,0x1
    80002ee2:	674080e7          	jalr	1652(ra) # 80004552 <holdingsleep>
    80002ee6:	cd01                	beqz	a0,80002efe <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002ee8:	4585                	li	a1,1
    80002eea:	8526                	mv	a0,s1
    80002eec:	00003097          	auipc	ra,0x3
    80002ef0:	24a080e7          	jalr	586(ra) # 80006136 <virtio_disk_rw>
}
    80002ef4:	60e2                	ld	ra,24(sp)
    80002ef6:	6442                	ld	s0,16(sp)
    80002ef8:	64a2                	ld	s1,8(sp)
    80002efa:	6105                	addi	sp,sp,32
    80002efc:	8082                	ret
    panic("bwrite");
    80002efe:	00005517          	auipc	a0,0x5
    80002f02:	61250513          	addi	a0,a0,1554 # 80008510 <syscalls+0xe0>
    80002f06:	ffffd097          	auipc	ra,0xffffd
    80002f0a:	624080e7          	jalr	1572(ra) # 8000052a <panic>

0000000080002f0e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f0e:	1101                	addi	sp,sp,-32
    80002f10:	ec06                	sd	ra,24(sp)
    80002f12:	e822                	sd	s0,16(sp)
    80002f14:	e426                	sd	s1,8(sp)
    80002f16:	e04a                	sd	s2,0(sp)
    80002f18:	1000                	addi	s0,sp,32
    80002f1a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f1c:	01050913          	addi	s2,a0,16
    80002f20:	854a                	mv	a0,s2
    80002f22:	00001097          	auipc	ra,0x1
    80002f26:	630080e7          	jalr	1584(ra) # 80004552 <holdingsleep>
    80002f2a:	c92d                	beqz	a0,80002f9c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002f2c:	854a                	mv	a0,s2
    80002f2e:	00001097          	auipc	ra,0x1
    80002f32:	5e0080e7          	jalr	1504(ra) # 8000450e <releasesleep>

  acquire(&bcache.lock);
    80002f36:	00014517          	auipc	a0,0x14
    80002f3a:	1b250513          	addi	a0,a0,434 # 800170e8 <bcache>
    80002f3e:	ffffe097          	auipc	ra,0xffffe
    80002f42:	c84080e7          	jalr	-892(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80002f46:	40bc                	lw	a5,64(s1)
    80002f48:	37fd                	addiw	a5,a5,-1
    80002f4a:	0007871b          	sext.w	a4,a5
    80002f4e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002f50:	eb05                	bnez	a4,80002f80 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002f52:	68bc                	ld	a5,80(s1)
    80002f54:	64b8                	ld	a4,72(s1)
    80002f56:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002f58:	64bc                	ld	a5,72(s1)
    80002f5a:	68b8                	ld	a4,80(s1)
    80002f5c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002f5e:	0001c797          	auipc	a5,0x1c
    80002f62:	18a78793          	addi	a5,a5,394 # 8001f0e8 <bcache+0x8000>
    80002f66:	2b87b703          	ld	a4,696(a5)
    80002f6a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002f6c:	0001c717          	auipc	a4,0x1c
    80002f70:	3e470713          	addi	a4,a4,996 # 8001f350 <bcache+0x8268>
    80002f74:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002f76:	2b87b703          	ld	a4,696(a5)
    80002f7a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002f7c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002f80:	00014517          	auipc	a0,0x14
    80002f84:	16850513          	addi	a0,a0,360 # 800170e8 <bcache>
    80002f88:	ffffe097          	auipc	ra,0xffffe
    80002f8c:	cee080e7          	jalr	-786(ra) # 80000c76 <release>
}
    80002f90:	60e2                	ld	ra,24(sp)
    80002f92:	6442                	ld	s0,16(sp)
    80002f94:	64a2                	ld	s1,8(sp)
    80002f96:	6902                	ld	s2,0(sp)
    80002f98:	6105                	addi	sp,sp,32
    80002f9a:	8082                	ret
    panic("brelse");
    80002f9c:	00005517          	auipc	a0,0x5
    80002fa0:	57c50513          	addi	a0,a0,1404 # 80008518 <syscalls+0xe8>
    80002fa4:	ffffd097          	auipc	ra,0xffffd
    80002fa8:	586080e7          	jalr	1414(ra) # 8000052a <panic>

0000000080002fac <bpin>:

void
bpin(struct buf *b) {
    80002fac:	1101                	addi	sp,sp,-32
    80002fae:	ec06                	sd	ra,24(sp)
    80002fb0:	e822                	sd	s0,16(sp)
    80002fb2:	e426                	sd	s1,8(sp)
    80002fb4:	1000                	addi	s0,sp,32
    80002fb6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002fb8:	00014517          	auipc	a0,0x14
    80002fbc:	13050513          	addi	a0,a0,304 # 800170e8 <bcache>
    80002fc0:	ffffe097          	auipc	ra,0xffffe
    80002fc4:	c02080e7          	jalr	-1022(ra) # 80000bc2 <acquire>
  b->refcnt++;
    80002fc8:	40bc                	lw	a5,64(s1)
    80002fca:	2785                	addiw	a5,a5,1
    80002fcc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002fce:	00014517          	auipc	a0,0x14
    80002fd2:	11a50513          	addi	a0,a0,282 # 800170e8 <bcache>
    80002fd6:	ffffe097          	auipc	ra,0xffffe
    80002fda:	ca0080e7          	jalr	-864(ra) # 80000c76 <release>
}
    80002fde:	60e2                	ld	ra,24(sp)
    80002fe0:	6442                	ld	s0,16(sp)
    80002fe2:	64a2                	ld	s1,8(sp)
    80002fe4:	6105                	addi	sp,sp,32
    80002fe6:	8082                	ret

0000000080002fe8 <bunpin>:

void
bunpin(struct buf *b) {
    80002fe8:	1101                	addi	sp,sp,-32
    80002fea:	ec06                	sd	ra,24(sp)
    80002fec:	e822                	sd	s0,16(sp)
    80002fee:	e426                	sd	s1,8(sp)
    80002ff0:	1000                	addi	s0,sp,32
    80002ff2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002ff4:	00014517          	auipc	a0,0x14
    80002ff8:	0f450513          	addi	a0,a0,244 # 800170e8 <bcache>
    80002ffc:	ffffe097          	auipc	ra,0xffffe
    80003000:	bc6080e7          	jalr	-1082(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003004:	40bc                	lw	a5,64(s1)
    80003006:	37fd                	addiw	a5,a5,-1
    80003008:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000300a:	00014517          	auipc	a0,0x14
    8000300e:	0de50513          	addi	a0,a0,222 # 800170e8 <bcache>
    80003012:	ffffe097          	auipc	ra,0xffffe
    80003016:	c64080e7          	jalr	-924(ra) # 80000c76 <release>
}
    8000301a:	60e2                	ld	ra,24(sp)
    8000301c:	6442                	ld	s0,16(sp)
    8000301e:	64a2                	ld	s1,8(sp)
    80003020:	6105                	addi	sp,sp,32
    80003022:	8082                	ret

0000000080003024 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003024:	1101                	addi	sp,sp,-32
    80003026:	ec06                	sd	ra,24(sp)
    80003028:	e822                	sd	s0,16(sp)
    8000302a:	e426                	sd	s1,8(sp)
    8000302c:	e04a                	sd	s2,0(sp)
    8000302e:	1000                	addi	s0,sp,32
    80003030:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003032:	00d5d59b          	srliw	a1,a1,0xd
    80003036:	0001c797          	auipc	a5,0x1c
    8000303a:	78e7a783          	lw	a5,1934(a5) # 8001f7c4 <sb+0x1c>
    8000303e:	9dbd                	addw	a1,a1,a5
    80003040:	00000097          	auipc	ra,0x0
    80003044:	d9e080e7          	jalr	-610(ra) # 80002dde <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003048:	0074f713          	andi	a4,s1,7
    8000304c:	4785                	li	a5,1
    8000304e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003052:	14ce                	slli	s1,s1,0x33
    80003054:	90d9                	srli	s1,s1,0x36
    80003056:	00950733          	add	a4,a0,s1
    8000305a:	05874703          	lbu	a4,88(a4)
    8000305e:	00e7f6b3          	and	a3,a5,a4
    80003062:	c69d                	beqz	a3,80003090 <bfree+0x6c>
    80003064:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003066:	94aa                	add	s1,s1,a0
    80003068:	fff7c793          	not	a5,a5
    8000306c:	8ff9                	and	a5,a5,a4
    8000306e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003072:	00001097          	auipc	ra,0x1
    80003076:	326080e7          	jalr	806(ra) # 80004398 <log_write>
  brelse(bp);
    8000307a:	854a                	mv	a0,s2
    8000307c:	00000097          	auipc	ra,0x0
    80003080:	e92080e7          	jalr	-366(ra) # 80002f0e <brelse>
}
    80003084:	60e2                	ld	ra,24(sp)
    80003086:	6442                	ld	s0,16(sp)
    80003088:	64a2                	ld	s1,8(sp)
    8000308a:	6902                	ld	s2,0(sp)
    8000308c:	6105                	addi	sp,sp,32
    8000308e:	8082                	ret
    panic("freeing free block");
    80003090:	00005517          	auipc	a0,0x5
    80003094:	49050513          	addi	a0,a0,1168 # 80008520 <syscalls+0xf0>
    80003098:	ffffd097          	auipc	ra,0xffffd
    8000309c:	492080e7          	jalr	1170(ra) # 8000052a <panic>

00000000800030a0 <balloc>:
{
    800030a0:	711d                	addi	sp,sp,-96
    800030a2:	ec86                	sd	ra,88(sp)
    800030a4:	e8a2                	sd	s0,80(sp)
    800030a6:	e4a6                	sd	s1,72(sp)
    800030a8:	e0ca                	sd	s2,64(sp)
    800030aa:	fc4e                	sd	s3,56(sp)
    800030ac:	f852                	sd	s4,48(sp)
    800030ae:	f456                	sd	s5,40(sp)
    800030b0:	f05a                	sd	s6,32(sp)
    800030b2:	ec5e                	sd	s7,24(sp)
    800030b4:	e862                	sd	s8,16(sp)
    800030b6:	e466                	sd	s9,8(sp)
    800030b8:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800030ba:	0001c797          	auipc	a5,0x1c
    800030be:	6f27a783          	lw	a5,1778(a5) # 8001f7ac <sb+0x4>
    800030c2:	cbd1                	beqz	a5,80003156 <balloc+0xb6>
    800030c4:	8baa                	mv	s7,a0
    800030c6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800030c8:	0001cb17          	auipc	s6,0x1c
    800030cc:	6e0b0b13          	addi	s6,s6,1760 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030d0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800030d2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030d4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800030d6:	6c89                	lui	s9,0x2
    800030d8:	a831                	j	800030f4 <balloc+0x54>
    brelse(bp);
    800030da:	854a                	mv	a0,s2
    800030dc:	00000097          	auipc	ra,0x0
    800030e0:	e32080e7          	jalr	-462(ra) # 80002f0e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800030e4:	015c87bb          	addw	a5,s9,s5
    800030e8:	00078a9b          	sext.w	s5,a5
    800030ec:	004b2703          	lw	a4,4(s6)
    800030f0:	06eaf363          	bgeu	s5,a4,80003156 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800030f4:	41fad79b          	sraiw	a5,s5,0x1f
    800030f8:	0137d79b          	srliw	a5,a5,0x13
    800030fc:	015787bb          	addw	a5,a5,s5
    80003100:	40d7d79b          	sraiw	a5,a5,0xd
    80003104:	01cb2583          	lw	a1,28(s6)
    80003108:	9dbd                	addw	a1,a1,a5
    8000310a:	855e                	mv	a0,s7
    8000310c:	00000097          	auipc	ra,0x0
    80003110:	cd2080e7          	jalr	-814(ra) # 80002dde <bread>
    80003114:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003116:	004b2503          	lw	a0,4(s6)
    8000311a:	000a849b          	sext.w	s1,s5
    8000311e:	8662                	mv	a2,s8
    80003120:	faa4fde3          	bgeu	s1,a0,800030da <balloc+0x3a>
      m = 1 << (bi % 8);
    80003124:	41f6579b          	sraiw	a5,a2,0x1f
    80003128:	01d7d69b          	srliw	a3,a5,0x1d
    8000312c:	00c6873b          	addw	a4,a3,a2
    80003130:	00777793          	andi	a5,a4,7
    80003134:	9f95                	subw	a5,a5,a3
    80003136:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000313a:	4037571b          	sraiw	a4,a4,0x3
    8000313e:	00e906b3          	add	a3,s2,a4
    80003142:	0586c683          	lbu	a3,88(a3)
    80003146:	00d7f5b3          	and	a1,a5,a3
    8000314a:	cd91                	beqz	a1,80003166 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000314c:	2605                	addiw	a2,a2,1
    8000314e:	2485                	addiw	s1,s1,1
    80003150:	fd4618e3          	bne	a2,s4,80003120 <balloc+0x80>
    80003154:	b759                	j	800030da <balloc+0x3a>
  panic("balloc: out of blocks");
    80003156:	00005517          	auipc	a0,0x5
    8000315a:	3e250513          	addi	a0,a0,994 # 80008538 <syscalls+0x108>
    8000315e:	ffffd097          	auipc	ra,0xffffd
    80003162:	3cc080e7          	jalr	972(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003166:	974a                	add	a4,a4,s2
    80003168:	8fd5                	or	a5,a5,a3
    8000316a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000316e:	854a                	mv	a0,s2
    80003170:	00001097          	auipc	ra,0x1
    80003174:	228080e7          	jalr	552(ra) # 80004398 <log_write>
        brelse(bp);
    80003178:	854a                	mv	a0,s2
    8000317a:	00000097          	auipc	ra,0x0
    8000317e:	d94080e7          	jalr	-620(ra) # 80002f0e <brelse>
  bp = bread(dev, bno);
    80003182:	85a6                	mv	a1,s1
    80003184:	855e                	mv	a0,s7
    80003186:	00000097          	auipc	ra,0x0
    8000318a:	c58080e7          	jalr	-936(ra) # 80002dde <bread>
    8000318e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003190:	40000613          	li	a2,1024
    80003194:	4581                	li	a1,0
    80003196:	05850513          	addi	a0,a0,88
    8000319a:	ffffe097          	auipc	ra,0xffffe
    8000319e:	b24080e7          	jalr	-1244(ra) # 80000cbe <memset>
  log_write(bp);
    800031a2:	854a                	mv	a0,s2
    800031a4:	00001097          	auipc	ra,0x1
    800031a8:	1f4080e7          	jalr	500(ra) # 80004398 <log_write>
  brelse(bp);
    800031ac:	854a                	mv	a0,s2
    800031ae:	00000097          	auipc	ra,0x0
    800031b2:	d60080e7          	jalr	-672(ra) # 80002f0e <brelse>
}
    800031b6:	8526                	mv	a0,s1
    800031b8:	60e6                	ld	ra,88(sp)
    800031ba:	6446                	ld	s0,80(sp)
    800031bc:	64a6                	ld	s1,72(sp)
    800031be:	6906                	ld	s2,64(sp)
    800031c0:	79e2                	ld	s3,56(sp)
    800031c2:	7a42                	ld	s4,48(sp)
    800031c4:	7aa2                	ld	s5,40(sp)
    800031c6:	7b02                	ld	s6,32(sp)
    800031c8:	6be2                	ld	s7,24(sp)
    800031ca:	6c42                	ld	s8,16(sp)
    800031cc:	6ca2                	ld	s9,8(sp)
    800031ce:	6125                	addi	sp,sp,96
    800031d0:	8082                	ret

00000000800031d2 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800031d2:	7139                	addi	sp,sp,-64
    800031d4:	fc06                	sd	ra,56(sp)
    800031d6:	f822                	sd	s0,48(sp)
    800031d8:	f426                	sd	s1,40(sp)
    800031da:	f04a                	sd	s2,32(sp)
    800031dc:	ec4e                	sd	s3,24(sp)
    800031de:	e852                	sd	s4,16(sp)
    800031e0:	e456                	sd	s5,8(sp)
    800031e2:	0080                	addi	s0,sp,64
    800031e4:	89aa                	mv	s3,a0
  // You should modify bmap(),
  // so that it can handle doubly indrect inode.
  uint addr, *a, *a2;
  struct buf *bp, *bp2;

  if(bn < NDIRECT){
    800031e6:	4795                	li	a5,5
    800031e8:	08b7fd63          	bgeu	a5,a1,80003282 <bmap+0xb0>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800031ec:	ffa5849b          	addiw	s1,a1,-6
    800031f0:	0004871b          	sext.w	a4,s1

  if(bn < N_SNDIRECT){
    800031f4:	5ff00793          	li	a5,1535
    800031f8:	0ae7f863          	bgeu	a5,a4,800032a8 <bmap+0xd6>
      log_write(bp);
    }
    brelse(bp);
    return addr;
  }
  bn -=N_SNDIRECT;
    800031fc:	9fa5849b          	addiw	s1,a1,-1542
    80003200:	0004871b          	sext.w	a4,s1
  
  if(bn < N_DNDIRECT){
    80003204:	67c1                	lui	a5,0x10
    80003206:	16f77763          	bgeu	a4,a5,80003374 <bmap+0x1a2>
    if((addr = ip->addrs[NDIRECT+N_SNDIRECT_BLOCK ]) == 0)
    8000320a:	08052583          	lw	a1,128(a0)
    8000320e:	10058963          	beqz	a1,80003320 <bmap+0x14e>
      ip->addrs[NDIRECT+N_SNDIRECT_BLOCK ] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003212:	0009a503          	lw	a0,0(s3)
    80003216:	00000097          	auipc	ra,0x0
    8000321a:	bc8080e7          	jalr	-1080(ra) # 80002dde <bread>
    8000321e:	892a                	mv	s2,a0
    a = (uint*)bp->data;
    80003220:	05850a13          	addi	s4,a0,88
    if((addr = a[bn/PTRS_PER_BLOCK]) == 0){
    80003224:	0084d79b          	srliw	a5,s1,0x8
    80003228:	078a                	slli	a5,a5,0x2
    8000322a:	9a3e                	add	s4,s4,a5
    8000322c:	000a2a83          	lw	s5,0(s4) # 2000 <_entry-0x7fffe000>
    80003230:	100a8263          	beqz	s5,80003334 <bmap+0x162>
      a[bn/PTRS_PER_BLOCK] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003234:	854a                	mv	a0,s2
    80003236:	00000097          	auipc	ra,0x0
    8000323a:	cd8080e7          	jalr	-808(ra) # 80002f0e <brelse>
    bp2 = bread(ip->dev, addr);
    8000323e:	85d6                	mv	a1,s5
    80003240:	0009a503          	lw	a0,0(s3)
    80003244:	00000097          	auipc	ra,0x0
    80003248:	b9a080e7          	jalr	-1126(ra) # 80002dde <bread>
    8000324c:	8a2a                	mv	s4,a0
    a2 = (uint*)bp2->data;
    8000324e:	05850793          	addi	a5,a0,88
    if((addr = a2[bn%PTRS_PER_BLOCK]) == 0){
    80003252:	0ff4f593          	andi	a1,s1,255
    80003256:	058a                	slli	a1,a1,0x2
    80003258:	00b784b3          	add	s1,a5,a1
    8000325c:	0004a903          	lw	s2,0(s1)
    80003260:	0e090a63          	beqz	s2,80003354 <bmap+0x182>
      a2[bn%PTRS_PER_BLOCK] = addr = balloc(ip->dev);
      log_write(bp2);
    }
    brelse(bp2); 
    80003264:	8552                	mv	a0,s4
    80003266:	00000097          	auipc	ra,0x0
    8000326a:	ca8080e7          	jalr	-856(ra) # 80002f0e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000326e:	854a                	mv	a0,s2
    80003270:	70e2                	ld	ra,56(sp)
    80003272:	7442                	ld	s0,48(sp)
    80003274:	74a2                	ld	s1,40(sp)
    80003276:	7902                	ld	s2,32(sp)
    80003278:	69e2                	ld	s3,24(sp)
    8000327a:	6a42                	ld	s4,16(sp)
    8000327c:	6aa2                	ld	s5,8(sp)
    8000327e:	6121                	addi	sp,sp,64
    80003280:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003282:	02059493          	slli	s1,a1,0x20
    80003286:	9081                	srli	s1,s1,0x20
    80003288:	048a                	slli	s1,s1,0x2
    8000328a:	94aa                	add	s1,s1,a0
    8000328c:	0504a903          	lw	s2,80(s1)
    80003290:	fc091fe3          	bnez	s2,8000326e <bmap+0x9c>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003294:	4108                	lw	a0,0(a0)
    80003296:	00000097          	auipc	ra,0x0
    8000329a:	e0a080e7          	jalr	-502(ra) # 800030a0 <balloc>
    8000329e:	0005091b          	sext.w	s2,a0
    800032a2:	0524a823          	sw	s2,80(s1)
    800032a6:	b7e1                	j	8000326e <bmap+0x9c>
    if((addr = ip->addrs[NDIRECT+bn/PTRS_PER_BLOCK]) == 0)
    800032a8:	0084d91b          	srliw	s2,s1,0x8
    800032ac:	2919                	addiw	s2,s2,6
    800032ae:	1902                	slli	s2,s2,0x20
    800032b0:	02095913          	srli	s2,s2,0x20
    800032b4:	090a                	slli	s2,s2,0x2
    800032b6:	992a                	add	s2,s2,a0
    800032b8:	05092583          	lw	a1,80(s2)
    800032bc:	c985                	beqz	a1,800032ec <bmap+0x11a>
    bp = bread(ip->dev, addr);
    800032be:	0009a503          	lw	a0,0(s3)
    800032c2:	00000097          	auipc	ra,0x0
    800032c6:	b1c080e7          	jalr	-1252(ra) # 80002dde <bread>
    800032ca:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800032cc:	05850793          	addi	a5,a0,88
    if((addr = a[bn%PTRS_PER_BLOCK]) == 0){
    800032d0:	0ff4f493          	andi	s1,s1,255
    800032d4:	048a                	slli	s1,s1,0x2
    800032d6:	94be                	add	s1,s1,a5
    800032d8:	0004a903          	lw	s2,0(s1)
    800032dc:	02090263          	beqz	s2,80003300 <bmap+0x12e>
    brelse(bp);
    800032e0:	8552                	mv	a0,s4
    800032e2:	00000097          	auipc	ra,0x0
    800032e6:	c2c080e7          	jalr	-980(ra) # 80002f0e <brelse>
    return addr;
    800032ea:	b751                	j	8000326e <bmap+0x9c>
      ip->addrs[NDIRECT+bn/PTRS_PER_BLOCK] = addr = balloc(ip->dev);
    800032ec:	4108                	lw	a0,0(a0)
    800032ee:	00000097          	auipc	ra,0x0
    800032f2:	db2080e7          	jalr	-590(ra) # 800030a0 <balloc>
    800032f6:	0005059b          	sext.w	a1,a0
    800032fa:	04b92823          	sw	a1,80(s2)
    800032fe:	b7c1                	j	800032be <bmap+0xec>
      a[bn%PTRS_PER_BLOCK] = addr = balloc(ip->dev);
    80003300:	0009a503          	lw	a0,0(s3)
    80003304:	00000097          	auipc	ra,0x0
    80003308:	d9c080e7          	jalr	-612(ra) # 800030a0 <balloc>
    8000330c:	0005091b          	sext.w	s2,a0
    80003310:	0124a023          	sw	s2,0(s1)
      log_write(bp);
    80003314:	8552                	mv	a0,s4
    80003316:	00001097          	auipc	ra,0x1
    8000331a:	082080e7          	jalr	130(ra) # 80004398 <log_write>
    8000331e:	b7c9                	j	800032e0 <bmap+0x10e>
      ip->addrs[NDIRECT+N_SNDIRECT_BLOCK ] = addr = balloc(ip->dev);
    80003320:	4108                	lw	a0,0(a0)
    80003322:	00000097          	auipc	ra,0x0
    80003326:	d7e080e7          	jalr	-642(ra) # 800030a0 <balloc>
    8000332a:	0005059b          	sext.w	a1,a0
    8000332e:	08b9a023          	sw	a1,128(s3)
    80003332:	b5c5                	j	80003212 <bmap+0x40>
      a[bn/PTRS_PER_BLOCK] = addr = balloc(ip->dev);
    80003334:	0009a503          	lw	a0,0(s3)
    80003338:	00000097          	auipc	ra,0x0
    8000333c:	d68080e7          	jalr	-664(ra) # 800030a0 <balloc>
    80003340:	00050a9b          	sext.w	s5,a0
    80003344:	015a2023          	sw	s5,0(s4)
      log_write(bp);
    80003348:	854a                	mv	a0,s2
    8000334a:	00001097          	auipc	ra,0x1
    8000334e:	04e080e7          	jalr	78(ra) # 80004398 <log_write>
    80003352:	b5cd                	j	80003234 <bmap+0x62>
      a2[bn%PTRS_PER_BLOCK] = addr = balloc(ip->dev);
    80003354:	0009a503          	lw	a0,0(s3)
    80003358:	00000097          	auipc	ra,0x0
    8000335c:	d48080e7          	jalr	-696(ra) # 800030a0 <balloc>
    80003360:	0005091b          	sext.w	s2,a0
    80003364:	0124a023          	sw	s2,0(s1)
      log_write(bp2);
    80003368:	8552                	mv	a0,s4
    8000336a:	00001097          	auipc	ra,0x1
    8000336e:	02e080e7          	jalr	46(ra) # 80004398 <log_write>
    80003372:	bdcd                	j	80003264 <bmap+0x92>
  panic("bmap: out of range");
    80003374:	00005517          	auipc	a0,0x5
    80003378:	1dc50513          	addi	a0,a0,476 # 80008550 <syscalls+0x120>
    8000337c:	ffffd097          	auipc	ra,0xffffd
    80003380:	1ae080e7          	jalr	430(ra) # 8000052a <panic>

0000000080003384 <iget>:
{
    80003384:	7179                	addi	sp,sp,-48
    80003386:	f406                	sd	ra,40(sp)
    80003388:	f022                	sd	s0,32(sp)
    8000338a:	ec26                	sd	s1,24(sp)
    8000338c:	e84a                	sd	s2,16(sp)
    8000338e:	e44e                	sd	s3,8(sp)
    80003390:	e052                	sd	s4,0(sp)
    80003392:	1800                	addi	s0,sp,48
    80003394:	89aa                	mv	s3,a0
    80003396:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003398:	0001c517          	auipc	a0,0x1c
    8000339c:	43050513          	addi	a0,a0,1072 # 8001f7c8 <itable>
    800033a0:	ffffe097          	auipc	ra,0xffffe
    800033a4:	822080e7          	jalr	-2014(ra) # 80000bc2 <acquire>
  empty = 0;
    800033a8:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033aa:	0001c497          	auipc	s1,0x1c
    800033ae:	43648493          	addi	s1,s1,1078 # 8001f7e0 <itable+0x18>
    800033b2:	0001e697          	auipc	a3,0x1e
    800033b6:	ebe68693          	addi	a3,a3,-322 # 80021270 <log>
    800033ba:	a039                	j	800033c8 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033bc:	02090b63          	beqz	s2,800033f2 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033c0:	08848493          	addi	s1,s1,136
    800033c4:	02d48a63          	beq	s1,a3,800033f8 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800033c8:	449c                	lw	a5,8(s1)
    800033ca:	fef059e3          	blez	a5,800033bc <iget+0x38>
    800033ce:	4098                	lw	a4,0(s1)
    800033d0:	ff3716e3          	bne	a4,s3,800033bc <iget+0x38>
    800033d4:	40d8                	lw	a4,4(s1)
    800033d6:	ff4713e3          	bne	a4,s4,800033bc <iget+0x38>
      ip->ref++;
    800033da:	2785                	addiw	a5,a5,1
    800033dc:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800033de:	0001c517          	auipc	a0,0x1c
    800033e2:	3ea50513          	addi	a0,a0,1002 # 8001f7c8 <itable>
    800033e6:	ffffe097          	auipc	ra,0xffffe
    800033ea:	890080e7          	jalr	-1904(ra) # 80000c76 <release>
      return ip;
    800033ee:	8926                	mv	s2,s1
    800033f0:	a03d                	j	8000341e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033f2:	f7f9                	bnez	a5,800033c0 <iget+0x3c>
    800033f4:	8926                	mv	s2,s1
    800033f6:	b7e9                	j	800033c0 <iget+0x3c>
  if(empty == 0)
    800033f8:	02090c63          	beqz	s2,80003430 <iget+0xac>
  ip->dev = dev;
    800033fc:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003400:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003404:	4785                	li	a5,1
    80003406:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000340a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000340e:	0001c517          	auipc	a0,0x1c
    80003412:	3ba50513          	addi	a0,a0,954 # 8001f7c8 <itable>
    80003416:	ffffe097          	auipc	ra,0xffffe
    8000341a:	860080e7          	jalr	-1952(ra) # 80000c76 <release>
}
    8000341e:	854a                	mv	a0,s2
    80003420:	70a2                	ld	ra,40(sp)
    80003422:	7402                	ld	s0,32(sp)
    80003424:	64e2                	ld	s1,24(sp)
    80003426:	6942                	ld	s2,16(sp)
    80003428:	69a2                	ld	s3,8(sp)
    8000342a:	6a02                	ld	s4,0(sp)
    8000342c:	6145                	addi	sp,sp,48
    8000342e:	8082                	ret
    panic("iget: no inodes");
    80003430:	00005517          	auipc	a0,0x5
    80003434:	13850513          	addi	a0,a0,312 # 80008568 <syscalls+0x138>
    80003438:	ffffd097          	auipc	ra,0xffffd
    8000343c:	0f2080e7          	jalr	242(ra) # 8000052a <panic>

0000000080003440 <fsinit>:
fsinit(int dev) {
    80003440:	7179                	addi	sp,sp,-48
    80003442:	f406                	sd	ra,40(sp)
    80003444:	f022                	sd	s0,32(sp)
    80003446:	ec26                	sd	s1,24(sp)
    80003448:	e84a                	sd	s2,16(sp)
    8000344a:	e44e                	sd	s3,8(sp)
    8000344c:	1800                	addi	s0,sp,48
    8000344e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003450:	4585                	li	a1,1
    80003452:	00000097          	auipc	ra,0x0
    80003456:	98c080e7          	jalr	-1652(ra) # 80002dde <bread>
    8000345a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000345c:	0001c997          	auipc	s3,0x1c
    80003460:	34c98993          	addi	s3,s3,844 # 8001f7a8 <sb>
    80003464:	02000613          	li	a2,32
    80003468:	05850593          	addi	a1,a0,88
    8000346c:	854e                	mv	a0,s3
    8000346e:	ffffe097          	auipc	ra,0xffffe
    80003472:	8ac080e7          	jalr	-1876(ra) # 80000d1a <memmove>
  brelse(bp);
    80003476:	8526                	mv	a0,s1
    80003478:	00000097          	auipc	ra,0x0
    8000347c:	a96080e7          	jalr	-1386(ra) # 80002f0e <brelse>
  if(sb.magic != FSMAGIC)
    80003480:	0009a703          	lw	a4,0(s3)
    80003484:	102037b7          	lui	a5,0x10203
    80003488:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000348c:	02f71263          	bne	a4,a5,800034b0 <fsinit+0x70>
  initlog(dev, &sb);
    80003490:	0001c597          	auipc	a1,0x1c
    80003494:	31858593          	addi	a1,a1,792 # 8001f7a8 <sb>
    80003498:	854a                	mv	a0,s2
    8000349a:	00001097          	auipc	ra,0x1
    8000349e:	c82080e7          	jalr	-894(ra) # 8000411c <initlog>
}
    800034a2:	70a2                	ld	ra,40(sp)
    800034a4:	7402                	ld	s0,32(sp)
    800034a6:	64e2                	ld	s1,24(sp)
    800034a8:	6942                	ld	s2,16(sp)
    800034aa:	69a2                	ld	s3,8(sp)
    800034ac:	6145                	addi	sp,sp,48
    800034ae:	8082                	ret
    panic("invalid file system");
    800034b0:	00005517          	auipc	a0,0x5
    800034b4:	0c850513          	addi	a0,a0,200 # 80008578 <syscalls+0x148>
    800034b8:	ffffd097          	auipc	ra,0xffffd
    800034bc:	072080e7          	jalr	114(ra) # 8000052a <panic>

00000000800034c0 <iinit>:
{
    800034c0:	7179                	addi	sp,sp,-48
    800034c2:	f406                	sd	ra,40(sp)
    800034c4:	f022                	sd	s0,32(sp)
    800034c6:	ec26                	sd	s1,24(sp)
    800034c8:	e84a                	sd	s2,16(sp)
    800034ca:	e44e                	sd	s3,8(sp)
    800034cc:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800034ce:	00005597          	auipc	a1,0x5
    800034d2:	0c258593          	addi	a1,a1,194 # 80008590 <syscalls+0x160>
    800034d6:	0001c517          	auipc	a0,0x1c
    800034da:	2f250513          	addi	a0,a0,754 # 8001f7c8 <itable>
    800034de:	ffffd097          	auipc	ra,0xffffd
    800034e2:	654080e7          	jalr	1620(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    800034e6:	0001c497          	auipc	s1,0x1c
    800034ea:	30a48493          	addi	s1,s1,778 # 8001f7f0 <itable+0x28>
    800034ee:	0001e997          	auipc	s3,0x1e
    800034f2:	d9298993          	addi	s3,s3,-622 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800034f6:	00005917          	auipc	s2,0x5
    800034fa:	0a290913          	addi	s2,s2,162 # 80008598 <syscalls+0x168>
    800034fe:	85ca                	mv	a1,s2
    80003500:	8526                	mv	a0,s1
    80003502:	00001097          	auipc	ra,0x1
    80003506:	f7c080e7          	jalr	-132(ra) # 8000447e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000350a:	08848493          	addi	s1,s1,136
    8000350e:	ff3498e3          	bne	s1,s3,800034fe <iinit+0x3e>
}
    80003512:	70a2                	ld	ra,40(sp)
    80003514:	7402                	ld	s0,32(sp)
    80003516:	64e2                	ld	s1,24(sp)
    80003518:	6942                	ld	s2,16(sp)
    8000351a:	69a2                	ld	s3,8(sp)
    8000351c:	6145                	addi	sp,sp,48
    8000351e:	8082                	ret

0000000080003520 <ialloc>:
{
    80003520:	715d                	addi	sp,sp,-80
    80003522:	e486                	sd	ra,72(sp)
    80003524:	e0a2                	sd	s0,64(sp)
    80003526:	fc26                	sd	s1,56(sp)
    80003528:	f84a                	sd	s2,48(sp)
    8000352a:	f44e                	sd	s3,40(sp)
    8000352c:	f052                	sd	s4,32(sp)
    8000352e:	ec56                	sd	s5,24(sp)
    80003530:	e85a                	sd	s6,16(sp)
    80003532:	e45e                	sd	s7,8(sp)
    80003534:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003536:	0001c717          	auipc	a4,0x1c
    8000353a:	27e72703          	lw	a4,638(a4) # 8001f7b4 <sb+0xc>
    8000353e:	4785                	li	a5,1
    80003540:	04e7fa63          	bgeu	a5,a4,80003594 <ialloc+0x74>
    80003544:	8aaa                	mv	s5,a0
    80003546:	8bae                	mv	s7,a1
    80003548:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000354a:	0001ca17          	auipc	s4,0x1c
    8000354e:	25ea0a13          	addi	s4,s4,606 # 8001f7a8 <sb>
    80003552:	00048b1b          	sext.w	s6,s1
    80003556:	0044d793          	srli	a5,s1,0x4
    8000355a:	018a2583          	lw	a1,24(s4)
    8000355e:	9dbd                	addw	a1,a1,a5
    80003560:	8556                	mv	a0,s5
    80003562:	00000097          	auipc	ra,0x0
    80003566:	87c080e7          	jalr	-1924(ra) # 80002dde <bread>
    8000356a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000356c:	05850993          	addi	s3,a0,88
    80003570:	00f4f793          	andi	a5,s1,15
    80003574:	079a                	slli	a5,a5,0x6
    80003576:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003578:	00099783          	lh	a5,0(s3)
    8000357c:	c785                	beqz	a5,800035a4 <ialloc+0x84>
    brelse(bp);
    8000357e:	00000097          	auipc	ra,0x0
    80003582:	990080e7          	jalr	-1648(ra) # 80002f0e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003586:	0485                	addi	s1,s1,1
    80003588:	00ca2703          	lw	a4,12(s4)
    8000358c:	0004879b          	sext.w	a5,s1
    80003590:	fce7e1e3          	bltu	a5,a4,80003552 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003594:	00005517          	auipc	a0,0x5
    80003598:	00c50513          	addi	a0,a0,12 # 800085a0 <syscalls+0x170>
    8000359c:	ffffd097          	auipc	ra,0xffffd
    800035a0:	f8e080e7          	jalr	-114(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    800035a4:	04000613          	li	a2,64
    800035a8:	4581                	li	a1,0
    800035aa:	854e                	mv	a0,s3
    800035ac:	ffffd097          	auipc	ra,0xffffd
    800035b0:	712080e7          	jalr	1810(ra) # 80000cbe <memset>
      dip->type = type;
    800035b4:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800035b8:	854a                	mv	a0,s2
    800035ba:	00001097          	auipc	ra,0x1
    800035be:	dde080e7          	jalr	-546(ra) # 80004398 <log_write>
      brelse(bp);
    800035c2:	854a                	mv	a0,s2
    800035c4:	00000097          	auipc	ra,0x0
    800035c8:	94a080e7          	jalr	-1718(ra) # 80002f0e <brelse>
      return iget(dev, inum);
    800035cc:	85da                	mv	a1,s6
    800035ce:	8556                	mv	a0,s5
    800035d0:	00000097          	auipc	ra,0x0
    800035d4:	db4080e7          	jalr	-588(ra) # 80003384 <iget>
}
    800035d8:	60a6                	ld	ra,72(sp)
    800035da:	6406                	ld	s0,64(sp)
    800035dc:	74e2                	ld	s1,56(sp)
    800035de:	7942                	ld	s2,48(sp)
    800035e0:	79a2                	ld	s3,40(sp)
    800035e2:	7a02                	ld	s4,32(sp)
    800035e4:	6ae2                	ld	s5,24(sp)
    800035e6:	6b42                	ld	s6,16(sp)
    800035e8:	6ba2                	ld	s7,8(sp)
    800035ea:	6161                	addi	sp,sp,80
    800035ec:	8082                	ret

00000000800035ee <iupdate>:
{
    800035ee:	1101                	addi	sp,sp,-32
    800035f0:	ec06                	sd	ra,24(sp)
    800035f2:	e822                	sd	s0,16(sp)
    800035f4:	e426                	sd	s1,8(sp)
    800035f6:	e04a                	sd	s2,0(sp)
    800035f8:	1000                	addi	s0,sp,32
    800035fa:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800035fc:	415c                	lw	a5,4(a0)
    800035fe:	0047d79b          	srliw	a5,a5,0x4
    80003602:	0001c597          	auipc	a1,0x1c
    80003606:	1be5a583          	lw	a1,446(a1) # 8001f7c0 <sb+0x18>
    8000360a:	9dbd                	addw	a1,a1,a5
    8000360c:	4108                	lw	a0,0(a0)
    8000360e:	fffff097          	auipc	ra,0xfffff
    80003612:	7d0080e7          	jalr	2000(ra) # 80002dde <bread>
    80003616:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003618:	05850793          	addi	a5,a0,88
    8000361c:	40c8                	lw	a0,4(s1)
    8000361e:	893d                	andi	a0,a0,15
    80003620:	051a                	slli	a0,a0,0x6
    80003622:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003624:	04449703          	lh	a4,68(s1)
    80003628:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000362c:	04649703          	lh	a4,70(s1)
    80003630:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003634:	04849703          	lh	a4,72(s1)
    80003638:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000363c:	04a49703          	lh	a4,74(s1)
    80003640:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003644:	44f8                	lw	a4,76(s1)
    80003646:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003648:	03400613          	li	a2,52
    8000364c:	05048593          	addi	a1,s1,80
    80003650:	0531                	addi	a0,a0,12
    80003652:	ffffd097          	auipc	ra,0xffffd
    80003656:	6c8080e7          	jalr	1736(ra) # 80000d1a <memmove>
  log_write(bp);
    8000365a:	854a                	mv	a0,s2
    8000365c:	00001097          	auipc	ra,0x1
    80003660:	d3c080e7          	jalr	-708(ra) # 80004398 <log_write>
  brelse(bp);
    80003664:	854a                	mv	a0,s2
    80003666:	00000097          	auipc	ra,0x0
    8000366a:	8a8080e7          	jalr	-1880(ra) # 80002f0e <brelse>
}
    8000366e:	60e2                	ld	ra,24(sp)
    80003670:	6442                	ld	s0,16(sp)
    80003672:	64a2                	ld	s1,8(sp)
    80003674:	6902                	ld	s2,0(sp)
    80003676:	6105                	addi	sp,sp,32
    80003678:	8082                	ret

000000008000367a <idup>:
{
    8000367a:	1101                	addi	sp,sp,-32
    8000367c:	ec06                	sd	ra,24(sp)
    8000367e:	e822                	sd	s0,16(sp)
    80003680:	e426                	sd	s1,8(sp)
    80003682:	1000                	addi	s0,sp,32
    80003684:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003686:	0001c517          	auipc	a0,0x1c
    8000368a:	14250513          	addi	a0,a0,322 # 8001f7c8 <itable>
    8000368e:	ffffd097          	auipc	ra,0xffffd
    80003692:	534080e7          	jalr	1332(ra) # 80000bc2 <acquire>
  ip->ref++;
    80003696:	449c                	lw	a5,8(s1)
    80003698:	2785                	addiw	a5,a5,1
    8000369a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000369c:	0001c517          	auipc	a0,0x1c
    800036a0:	12c50513          	addi	a0,a0,300 # 8001f7c8 <itable>
    800036a4:	ffffd097          	auipc	ra,0xffffd
    800036a8:	5d2080e7          	jalr	1490(ra) # 80000c76 <release>
}
    800036ac:	8526                	mv	a0,s1
    800036ae:	60e2                	ld	ra,24(sp)
    800036b0:	6442                	ld	s0,16(sp)
    800036b2:	64a2                	ld	s1,8(sp)
    800036b4:	6105                	addi	sp,sp,32
    800036b6:	8082                	ret

00000000800036b8 <ilock>:
{
    800036b8:	1101                	addi	sp,sp,-32
    800036ba:	ec06                	sd	ra,24(sp)
    800036bc:	e822                	sd	s0,16(sp)
    800036be:	e426                	sd	s1,8(sp)
    800036c0:	e04a                	sd	s2,0(sp)
    800036c2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800036c4:	c115                	beqz	a0,800036e8 <ilock+0x30>
    800036c6:	84aa                	mv	s1,a0
    800036c8:	451c                	lw	a5,8(a0)
    800036ca:	00f05f63          	blez	a5,800036e8 <ilock+0x30>
  acquiresleep(&ip->lock);
    800036ce:	0541                	addi	a0,a0,16
    800036d0:	00001097          	auipc	ra,0x1
    800036d4:	de8080e7          	jalr	-536(ra) # 800044b8 <acquiresleep>
  if(ip->valid == 0){
    800036d8:	40bc                	lw	a5,64(s1)
    800036da:	cf99                	beqz	a5,800036f8 <ilock+0x40>
}
    800036dc:	60e2                	ld	ra,24(sp)
    800036de:	6442                	ld	s0,16(sp)
    800036e0:	64a2                	ld	s1,8(sp)
    800036e2:	6902                	ld	s2,0(sp)
    800036e4:	6105                	addi	sp,sp,32
    800036e6:	8082                	ret
    panic("ilock");
    800036e8:	00005517          	auipc	a0,0x5
    800036ec:	ed050513          	addi	a0,a0,-304 # 800085b8 <syscalls+0x188>
    800036f0:	ffffd097          	auipc	ra,0xffffd
    800036f4:	e3a080e7          	jalr	-454(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036f8:	40dc                	lw	a5,4(s1)
    800036fa:	0047d79b          	srliw	a5,a5,0x4
    800036fe:	0001c597          	auipc	a1,0x1c
    80003702:	0c25a583          	lw	a1,194(a1) # 8001f7c0 <sb+0x18>
    80003706:	9dbd                	addw	a1,a1,a5
    80003708:	4088                	lw	a0,0(s1)
    8000370a:	fffff097          	auipc	ra,0xfffff
    8000370e:	6d4080e7          	jalr	1748(ra) # 80002dde <bread>
    80003712:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003714:	05850593          	addi	a1,a0,88
    80003718:	40dc                	lw	a5,4(s1)
    8000371a:	8bbd                	andi	a5,a5,15
    8000371c:	079a                	slli	a5,a5,0x6
    8000371e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003720:	00059783          	lh	a5,0(a1)
    80003724:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003728:	00259783          	lh	a5,2(a1)
    8000372c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003730:	00459783          	lh	a5,4(a1)
    80003734:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003738:	00659783          	lh	a5,6(a1)
    8000373c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003740:	459c                	lw	a5,8(a1)
    80003742:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003744:	03400613          	li	a2,52
    80003748:	05b1                	addi	a1,a1,12
    8000374a:	05048513          	addi	a0,s1,80
    8000374e:	ffffd097          	auipc	ra,0xffffd
    80003752:	5cc080e7          	jalr	1484(ra) # 80000d1a <memmove>
    brelse(bp);
    80003756:	854a                	mv	a0,s2
    80003758:	fffff097          	auipc	ra,0xfffff
    8000375c:	7b6080e7          	jalr	1974(ra) # 80002f0e <brelse>
    ip->valid = 1;
    80003760:	4785                	li	a5,1
    80003762:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003764:	04449783          	lh	a5,68(s1)
    80003768:	fbb5                	bnez	a5,800036dc <ilock+0x24>
      panic("ilock: no type");
    8000376a:	00005517          	auipc	a0,0x5
    8000376e:	e5650513          	addi	a0,a0,-426 # 800085c0 <syscalls+0x190>
    80003772:	ffffd097          	auipc	ra,0xffffd
    80003776:	db8080e7          	jalr	-584(ra) # 8000052a <panic>

000000008000377a <iunlock>:
{
    8000377a:	1101                	addi	sp,sp,-32
    8000377c:	ec06                	sd	ra,24(sp)
    8000377e:	e822                	sd	s0,16(sp)
    80003780:	e426                	sd	s1,8(sp)
    80003782:	e04a                	sd	s2,0(sp)
    80003784:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003786:	c905                	beqz	a0,800037b6 <iunlock+0x3c>
    80003788:	84aa                	mv	s1,a0
    8000378a:	01050913          	addi	s2,a0,16
    8000378e:	854a                	mv	a0,s2
    80003790:	00001097          	auipc	ra,0x1
    80003794:	dc2080e7          	jalr	-574(ra) # 80004552 <holdingsleep>
    80003798:	cd19                	beqz	a0,800037b6 <iunlock+0x3c>
    8000379a:	449c                	lw	a5,8(s1)
    8000379c:	00f05d63          	blez	a5,800037b6 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800037a0:	854a                	mv	a0,s2
    800037a2:	00001097          	auipc	ra,0x1
    800037a6:	d6c080e7          	jalr	-660(ra) # 8000450e <releasesleep>
}
    800037aa:	60e2                	ld	ra,24(sp)
    800037ac:	6442                	ld	s0,16(sp)
    800037ae:	64a2                	ld	s1,8(sp)
    800037b0:	6902                	ld	s2,0(sp)
    800037b2:	6105                	addi	sp,sp,32
    800037b4:	8082                	ret
    panic("iunlock");
    800037b6:	00005517          	auipc	a0,0x5
    800037ba:	e1a50513          	addi	a0,a0,-486 # 800085d0 <syscalls+0x1a0>
    800037be:	ffffd097          	auipc	ra,0xffffd
    800037c2:	d6c080e7          	jalr	-660(ra) # 8000052a <panic>

00000000800037c6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800037c6:	715d                	addi	sp,sp,-80
    800037c8:	e486                	sd	ra,72(sp)
    800037ca:	e0a2                	sd	s0,64(sp)
    800037cc:	fc26                	sd	s1,56(sp)
    800037ce:	f84a                	sd	s2,48(sp)
    800037d0:	f44e                	sd	s3,40(sp)
    800037d2:	f052                	sd	s4,32(sp)
    800037d4:	ec56                	sd	s5,24(sp)
    800037d6:	e85a                	sd	s6,16(sp)
    800037d8:	e45e                	sd	s7,8(sp)
    800037da:	e062                	sd	s8,0(sp)
    800037dc:	0880                	addi	s0,sp,80
    800037de:	89aa                	mv	s3,a0
  // so that it can handle doubly indrect inode.
  int i, j, k;
  struct buf *bp, *bp2;
  uint *a, *a2;

  for(i = 0; i < NDIRECT; i++){
    800037e0:	05050493          	addi	s1,a0,80
    800037e4:	06850913          	addi	s2,a0,104
    800037e8:	a021                	j	800037f0 <itrunc+0x2a>
    800037ea:	0491                	addi	s1,s1,4
    800037ec:	01248d63          	beq	s1,s2,80003806 <itrunc+0x40>
    if(ip->addrs[i]){
    800037f0:	408c                	lw	a1,0(s1)
    800037f2:	dde5                	beqz	a1,800037ea <itrunc+0x24>
      bfree(ip->dev, ip->addrs[i]);
    800037f4:	0009a503          	lw	a0,0(s3)
    800037f8:	00000097          	auipc	ra,0x0
    800037fc:	82c080e7          	jalr	-2004(ra) # 80003024 <bfree>
      ip->addrs[i] = 0;
    80003800:	0004a023          	sw	zero,0(s1)
    80003804:	b7dd                	j	800037ea <itrunc+0x24>
    80003806:	06898a13          	addi	s4,s3,104
    8000380a:	08098b13          	addi	s6,s3,128
    8000380e:	a83d                	j	8000384c <itrunc+0x86>
  }
  for(i = NDIRECT; i < NDIRECT + N_SNDIRECT_BLOCK; i++){
    if(ip->addrs[i]){
      bp = bread(ip->dev, ip->addrs[i]);
      a = (uint*)bp->data;
      for(j = 0; j < PTRS_PER_BLOCK; j++){
    80003810:	0491                	addi	s1,s1,4
    80003812:	01248b63          	beq	s1,s2,80003828 <itrunc+0x62>
        if(a[j])
    80003816:	408c                	lw	a1,0(s1)
    80003818:	dde5                	beqz	a1,80003810 <itrunc+0x4a>
          bfree(ip->dev, a[j]);
    8000381a:	0009a503          	lw	a0,0(s3)
    8000381e:	00000097          	auipc	ra,0x0
    80003822:	806080e7          	jalr	-2042(ra) # 80003024 <bfree>
    80003826:	b7ed                	j	80003810 <itrunc+0x4a>
      }
      brelse(bp);
    80003828:	855e                	mv	a0,s7
    8000382a:	fffff097          	auipc	ra,0xfffff
    8000382e:	6e4080e7          	jalr	1764(ra) # 80002f0e <brelse>
      bfree(ip->dev, ip->addrs[i]);
    80003832:	000aa583          	lw	a1,0(s5)
    80003836:	0009a503          	lw	a0,0(s3)
    8000383a:	fffff097          	auipc	ra,0xfffff
    8000383e:	7ea080e7          	jalr	2026(ra) # 80003024 <bfree>
      ip->addrs[i] = 0;
    80003842:	000aa023          	sw	zero,0(s5)
  for(i = NDIRECT; i < NDIRECT + N_SNDIRECT_BLOCK; i++){
    80003846:	0a11                	addi	s4,s4,4
    80003848:	036a0263          	beq	s4,s6,8000386c <itrunc+0xa6>
    if(ip->addrs[i]){
    8000384c:	8ad2                	mv	s5,s4
    8000384e:	000a2583          	lw	a1,0(s4)
    80003852:	d9f5                	beqz	a1,80003846 <itrunc+0x80>
      bp = bread(ip->dev, ip->addrs[i]);
    80003854:	0009a503          	lw	a0,0(s3)
    80003858:	fffff097          	auipc	ra,0xfffff
    8000385c:	586080e7          	jalr	1414(ra) # 80002dde <bread>
    80003860:	8baa                	mv	s7,a0
      for(j = 0; j < PTRS_PER_BLOCK; j++){
    80003862:	05850493          	addi	s1,a0,88
    80003866:	45850913          	addi	s2,a0,1112
    8000386a:	b775                	j	80003816 <itrunc+0x50>
    }
  }

  //modified
  if(ip->addrs[NDIRECT + N_SNDIRECT_BLOCK]) {
    8000386c:	0809a583          	lw	a1,128(s3)
    80003870:	e585                	bnez	a1,80003898 <itrunc+0xd2>
    // finally free the doubly-indirect block itself
    bfree(ip->dev, ip->addrs[NDIRECT + N_SNDIRECT_BLOCK]);
    ip->addrs[NDIRECT + N_SNDIRECT_BLOCK] = 0;
  }

  ip->size = 0;
    80003872:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003876:	854e                	mv	a0,s3
    80003878:	00000097          	auipc	ra,0x0
    8000387c:	d76080e7          	jalr	-650(ra) # 800035ee <iupdate>
}
    80003880:	60a6                	ld	ra,72(sp)
    80003882:	6406                	ld	s0,64(sp)
    80003884:	74e2                	ld	s1,56(sp)
    80003886:	7942                	ld	s2,48(sp)
    80003888:	79a2                	ld	s3,40(sp)
    8000388a:	7a02                	ld	s4,32(sp)
    8000388c:	6ae2                	ld	s5,24(sp)
    8000388e:	6b42                	ld	s6,16(sp)
    80003890:	6ba2                	ld	s7,8(sp)
    80003892:	6c02                	ld	s8,0(sp)
    80003894:	6161                	addi	sp,sp,80
    80003896:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT + N_SNDIRECT_BLOCK]);
    80003898:	0009a503          	lw	a0,0(s3)
    8000389c:	fffff097          	auipc	ra,0xfffff
    800038a0:	542080e7          	jalr	1346(ra) # 80002dde <bread>
    800038a4:	8c2a                	mv	s8,a0
    for(j = 0; j < PTRS_PER_BLOCK; j++){
    800038a6:	05850a13          	addi	s4,a0,88
    800038aa:	45850b13          	addi	s6,a0,1112
    800038ae:	a82d                	j	800038e8 <itrunc+0x122>
        for(k = 0; k < PTRS_PER_BLOCK; k++){
    800038b0:	0491                	addi	s1,s1,4
    800038b2:	01248b63          	beq	s1,s2,800038c8 <itrunc+0x102>
          if(a2[k]) {
    800038b6:	408c                	lw	a1,0(s1)
    800038b8:	dde5                	beqz	a1,800038b0 <itrunc+0xea>
            bfree(ip->dev, a2[k]);
    800038ba:	0009a503          	lw	a0,0(s3)
    800038be:	fffff097          	auipc	ra,0xfffff
    800038c2:	766080e7          	jalr	1894(ra) # 80003024 <bfree>
    800038c6:	b7ed                	j	800038b0 <itrunc+0xea>
        brelse(bp2);
    800038c8:	855e                	mv	a0,s7
    800038ca:	fffff097          	auipc	ra,0xfffff
    800038ce:	644080e7          	jalr	1604(ra) # 80002f0e <brelse>
        bfree(ip->dev, a[j]);
    800038d2:	000aa583          	lw	a1,0(s5)
    800038d6:	0009a503          	lw	a0,0(s3)
    800038da:	fffff097          	auipc	ra,0xfffff
    800038de:	74a080e7          	jalr	1866(ra) # 80003024 <bfree>
    for(j = 0; j < PTRS_PER_BLOCK; j++){
    800038e2:	0a11                	addi	s4,s4,4
    800038e4:	036a0263          	beq	s4,s6,80003908 <itrunc+0x142>
      if(a[j]) {
    800038e8:	8ad2                	mv	s5,s4
    800038ea:	000a2583          	lw	a1,0(s4)
    800038ee:	d9f5                	beqz	a1,800038e2 <itrunc+0x11c>
        bp2 = bread(ip->dev, a[j]);
    800038f0:	0009a503          	lw	a0,0(s3)
    800038f4:	fffff097          	auipc	ra,0xfffff
    800038f8:	4ea080e7          	jalr	1258(ra) # 80002dde <bread>
    800038fc:	8baa                	mv	s7,a0
        for(k = 0; k < PTRS_PER_BLOCK; k++){
    800038fe:	05850493          	addi	s1,a0,88
    80003902:	45850913          	addi	s2,a0,1112
    80003906:	bf45                	j	800038b6 <itrunc+0xf0>
    brelse(bp);
    80003908:	8562                	mv	a0,s8
    8000390a:	fffff097          	auipc	ra,0xfffff
    8000390e:	604080e7          	jalr	1540(ra) # 80002f0e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT + N_SNDIRECT_BLOCK]);
    80003912:	0809a583          	lw	a1,128(s3)
    80003916:	0009a503          	lw	a0,0(s3)
    8000391a:	fffff097          	auipc	ra,0xfffff
    8000391e:	70a080e7          	jalr	1802(ra) # 80003024 <bfree>
    ip->addrs[NDIRECT + N_SNDIRECT_BLOCK] = 0;
    80003922:	0809a023          	sw	zero,128(s3)
    80003926:	b7b1                	j	80003872 <itrunc+0xac>

0000000080003928 <iput>:
{
    80003928:	1101                	addi	sp,sp,-32
    8000392a:	ec06                	sd	ra,24(sp)
    8000392c:	e822                	sd	s0,16(sp)
    8000392e:	e426                	sd	s1,8(sp)
    80003930:	e04a                	sd	s2,0(sp)
    80003932:	1000                	addi	s0,sp,32
    80003934:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003936:	0001c517          	auipc	a0,0x1c
    8000393a:	e9250513          	addi	a0,a0,-366 # 8001f7c8 <itable>
    8000393e:	ffffd097          	auipc	ra,0xffffd
    80003942:	284080e7          	jalr	644(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003946:	4498                	lw	a4,8(s1)
    80003948:	4785                	li	a5,1
    8000394a:	02f70363          	beq	a4,a5,80003970 <iput+0x48>
  ip->ref--;
    8000394e:	449c                	lw	a5,8(s1)
    80003950:	37fd                	addiw	a5,a5,-1
    80003952:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003954:	0001c517          	auipc	a0,0x1c
    80003958:	e7450513          	addi	a0,a0,-396 # 8001f7c8 <itable>
    8000395c:	ffffd097          	auipc	ra,0xffffd
    80003960:	31a080e7          	jalr	794(ra) # 80000c76 <release>
}
    80003964:	60e2                	ld	ra,24(sp)
    80003966:	6442                	ld	s0,16(sp)
    80003968:	64a2                	ld	s1,8(sp)
    8000396a:	6902                	ld	s2,0(sp)
    8000396c:	6105                	addi	sp,sp,32
    8000396e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003970:	40bc                	lw	a5,64(s1)
    80003972:	dff1                	beqz	a5,8000394e <iput+0x26>
    80003974:	04a49783          	lh	a5,74(s1)
    80003978:	fbf9                	bnez	a5,8000394e <iput+0x26>
    acquiresleep(&ip->lock);
    8000397a:	01048913          	addi	s2,s1,16
    8000397e:	854a                	mv	a0,s2
    80003980:	00001097          	auipc	ra,0x1
    80003984:	b38080e7          	jalr	-1224(ra) # 800044b8 <acquiresleep>
    release(&itable.lock);
    80003988:	0001c517          	auipc	a0,0x1c
    8000398c:	e4050513          	addi	a0,a0,-448 # 8001f7c8 <itable>
    80003990:	ffffd097          	auipc	ra,0xffffd
    80003994:	2e6080e7          	jalr	742(ra) # 80000c76 <release>
    itrunc(ip);
    80003998:	8526                	mv	a0,s1
    8000399a:	00000097          	auipc	ra,0x0
    8000399e:	e2c080e7          	jalr	-468(ra) # 800037c6 <itrunc>
    ip->type = 0;
    800039a2:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039a6:	8526                	mv	a0,s1
    800039a8:	00000097          	auipc	ra,0x0
    800039ac:	c46080e7          	jalr	-954(ra) # 800035ee <iupdate>
    ip->valid = 0;
    800039b0:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039b4:	854a                	mv	a0,s2
    800039b6:	00001097          	auipc	ra,0x1
    800039ba:	b58080e7          	jalr	-1192(ra) # 8000450e <releasesleep>
    acquire(&itable.lock);
    800039be:	0001c517          	auipc	a0,0x1c
    800039c2:	e0a50513          	addi	a0,a0,-502 # 8001f7c8 <itable>
    800039c6:	ffffd097          	auipc	ra,0xffffd
    800039ca:	1fc080e7          	jalr	508(ra) # 80000bc2 <acquire>
    800039ce:	b741                	j	8000394e <iput+0x26>

00000000800039d0 <iunlockput>:
{
    800039d0:	1101                	addi	sp,sp,-32
    800039d2:	ec06                	sd	ra,24(sp)
    800039d4:	e822                	sd	s0,16(sp)
    800039d6:	e426                	sd	s1,8(sp)
    800039d8:	1000                	addi	s0,sp,32
    800039da:	84aa                	mv	s1,a0
  iunlock(ip);
    800039dc:	00000097          	auipc	ra,0x0
    800039e0:	d9e080e7          	jalr	-610(ra) # 8000377a <iunlock>
  iput(ip);
    800039e4:	8526                	mv	a0,s1
    800039e6:	00000097          	auipc	ra,0x0
    800039ea:	f42080e7          	jalr	-190(ra) # 80003928 <iput>
}
    800039ee:	60e2                	ld	ra,24(sp)
    800039f0:	6442                	ld	s0,16(sp)
    800039f2:	64a2                	ld	s1,8(sp)
    800039f4:	6105                	addi	sp,sp,32
    800039f6:	8082                	ret

00000000800039f8 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039f8:	1141                	addi	sp,sp,-16
    800039fa:	e422                	sd	s0,8(sp)
    800039fc:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039fe:	411c                	lw	a5,0(a0)
    80003a00:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a02:	415c                	lw	a5,4(a0)
    80003a04:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a06:	04451783          	lh	a5,68(a0)
    80003a0a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a0e:	04a51783          	lh	a5,74(a0)
    80003a12:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a16:	04c56783          	lwu	a5,76(a0)
    80003a1a:	e99c                	sd	a5,16(a1)
}
    80003a1c:	6422                	ld	s0,8(sp)
    80003a1e:	0141                	addi	sp,sp,16
    80003a20:	8082                	ret

0000000080003a22 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a22:	457c                	lw	a5,76(a0)
    80003a24:	0ed7e963          	bltu	a5,a3,80003b16 <readi+0xf4>
{
    80003a28:	7159                	addi	sp,sp,-112
    80003a2a:	f486                	sd	ra,104(sp)
    80003a2c:	f0a2                	sd	s0,96(sp)
    80003a2e:	eca6                	sd	s1,88(sp)
    80003a30:	e8ca                	sd	s2,80(sp)
    80003a32:	e4ce                	sd	s3,72(sp)
    80003a34:	e0d2                	sd	s4,64(sp)
    80003a36:	fc56                	sd	s5,56(sp)
    80003a38:	f85a                	sd	s6,48(sp)
    80003a3a:	f45e                	sd	s7,40(sp)
    80003a3c:	f062                	sd	s8,32(sp)
    80003a3e:	ec66                	sd	s9,24(sp)
    80003a40:	e86a                	sd	s10,16(sp)
    80003a42:	e46e                	sd	s11,8(sp)
    80003a44:	1880                	addi	s0,sp,112
    80003a46:	8baa                	mv	s7,a0
    80003a48:	8c2e                	mv	s8,a1
    80003a4a:	8ab2                	mv	s5,a2
    80003a4c:	84b6                	mv	s1,a3
    80003a4e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a50:	9f35                	addw	a4,a4,a3
    return 0;
    80003a52:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a54:	0ad76063          	bltu	a4,a3,80003af4 <readi+0xd2>
  if(off + n > ip->size)
    80003a58:	00e7f463          	bgeu	a5,a4,80003a60 <readi+0x3e>
    n = ip->size - off;
    80003a5c:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a60:	0a0b0963          	beqz	s6,80003b12 <readi+0xf0>
    80003a64:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a66:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a6a:	5cfd                	li	s9,-1
    80003a6c:	a82d                	j	80003aa6 <readi+0x84>
    80003a6e:	020a1d93          	slli	s11,s4,0x20
    80003a72:	020ddd93          	srli	s11,s11,0x20
    80003a76:	05890793          	addi	a5,s2,88
    80003a7a:	86ee                	mv	a3,s11
    80003a7c:	963e                	add	a2,a2,a5
    80003a7e:	85d6                	mv	a1,s5
    80003a80:	8562                	mv	a0,s8
    80003a82:	fffff097          	auipc	ra,0xfffff
    80003a86:	9a2080e7          	jalr	-1630(ra) # 80002424 <either_copyout>
    80003a8a:	05950d63          	beq	a0,s9,80003ae4 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a8e:	854a                	mv	a0,s2
    80003a90:	fffff097          	auipc	ra,0xfffff
    80003a94:	47e080e7          	jalr	1150(ra) # 80002f0e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a98:	013a09bb          	addw	s3,s4,s3
    80003a9c:	009a04bb          	addw	s1,s4,s1
    80003aa0:	9aee                	add	s5,s5,s11
    80003aa2:	0569f763          	bgeu	s3,s6,80003af0 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003aa6:	000ba903          	lw	s2,0(s7)
    80003aaa:	00a4d59b          	srliw	a1,s1,0xa
    80003aae:	855e                	mv	a0,s7
    80003ab0:	fffff097          	auipc	ra,0xfffff
    80003ab4:	722080e7          	jalr	1826(ra) # 800031d2 <bmap>
    80003ab8:	0005059b          	sext.w	a1,a0
    80003abc:	854a                	mv	a0,s2
    80003abe:	fffff097          	auipc	ra,0xfffff
    80003ac2:	320080e7          	jalr	800(ra) # 80002dde <bread>
    80003ac6:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ac8:	3ff4f613          	andi	a2,s1,1023
    80003acc:	40cd07bb          	subw	a5,s10,a2
    80003ad0:	413b073b          	subw	a4,s6,s3
    80003ad4:	8a3e                	mv	s4,a5
    80003ad6:	2781                	sext.w	a5,a5
    80003ad8:	0007069b          	sext.w	a3,a4
    80003adc:	f8f6f9e3          	bgeu	a3,a5,80003a6e <readi+0x4c>
    80003ae0:	8a3a                	mv	s4,a4
    80003ae2:	b771                	j	80003a6e <readi+0x4c>
      brelse(bp);
    80003ae4:	854a                	mv	a0,s2
    80003ae6:	fffff097          	auipc	ra,0xfffff
    80003aea:	428080e7          	jalr	1064(ra) # 80002f0e <brelse>
      tot = -1;
    80003aee:	59fd                	li	s3,-1
  }
  return tot;
    80003af0:	0009851b          	sext.w	a0,s3
}
    80003af4:	70a6                	ld	ra,104(sp)
    80003af6:	7406                	ld	s0,96(sp)
    80003af8:	64e6                	ld	s1,88(sp)
    80003afa:	6946                	ld	s2,80(sp)
    80003afc:	69a6                	ld	s3,72(sp)
    80003afe:	6a06                	ld	s4,64(sp)
    80003b00:	7ae2                	ld	s5,56(sp)
    80003b02:	7b42                	ld	s6,48(sp)
    80003b04:	7ba2                	ld	s7,40(sp)
    80003b06:	7c02                	ld	s8,32(sp)
    80003b08:	6ce2                	ld	s9,24(sp)
    80003b0a:	6d42                	ld	s10,16(sp)
    80003b0c:	6da2                	ld	s11,8(sp)
    80003b0e:	6165                	addi	sp,sp,112
    80003b10:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b12:	89da                	mv	s3,s6
    80003b14:	bff1                	j	80003af0 <readi+0xce>
    return 0;
    80003b16:	4501                	li	a0,0
}
    80003b18:	8082                	ret

0000000080003b1a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b1a:	457c                	lw	a5,76(a0)
    80003b1c:	10d7e963          	bltu	a5,a3,80003c2e <writei+0x114>
{
    80003b20:	7159                	addi	sp,sp,-112
    80003b22:	f486                	sd	ra,104(sp)
    80003b24:	f0a2                	sd	s0,96(sp)
    80003b26:	eca6                	sd	s1,88(sp)
    80003b28:	e8ca                	sd	s2,80(sp)
    80003b2a:	e4ce                	sd	s3,72(sp)
    80003b2c:	e0d2                	sd	s4,64(sp)
    80003b2e:	fc56                	sd	s5,56(sp)
    80003b30:	f85a                	sd	s6,48(sp)
    80003b32:	f45e                	sd	s7,40(sp)
    80003b34:	f062                	sd	s8,32(sp)
    80003b36:	ec66                	sd	s9,24(sp)
    80003b38:	e86a                	sd	s10,16(sp)
    80003b3a:	e46e                	sd	s11,8(sp)
    80003b3c:	1880                	addi	s0,sp,112
    80003b3e:	8b2a                	mv	s6,a0
    80003b40:	8c2e                	mv	s8,a1
    80003b42:	8ab2                	mv	s5,a2
    80003b44:	8936                	mv	s2,a3
    80003b46:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003b48:	9f35                	addw	a4,a4,a3
    80003b4a:	0ed76463          	bltu	a4,a3,80003c32 <writei+0x118>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b4e:	041827b7          	lui	a5,0x4182
    80003b52:	80078793          	addi	a5,a5,-2048 # 4181800 <_entry-0x7be7e800>
    80003b56:	0ee7e063          	bltu	a5,a4,80003c36 <writei+0x11c>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b5a:	0c0b8863          	beqz	s7,80003c2a <writei+0x110>
    80003b5e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b60:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b64:	5cfd                	li	s9,-1
    80003b66:	a091                	j	80003baa <writei+0x90>
    80003b68:	02099d93          	slli	s11,s3,0x20
    80003b6c:	020ddd93          	srli	s11,s11,0x20
    80003b70:	05848793          	addi	a5,s1,88
    80003b74:	86ee                	mv	a3,s11
    80003b76:	8656                	mv	a2,s5
    80003b78:	85e2                	mv	a1,s8
    80003b7a:	953e                	add	a0,a0,a5
    80003b7c:	fffff097          	auipc	ra,0xfffff
    80003b80:	8fe080e7          	jalr	-1794(ra) # 8000247a <either_copyin>
    80003b84:	07950263          	beq	a0,s9,80003be8 <writei+0xce>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b88:	8526                	mv	a0,s1
    80003b8a:	00001097          	auipc	ra,0x1
    80003b8e:	80e080e7          	jalr	-2034(ra) # 80004398 <log_write>
    brelse(bp);
    80003b92:	8526                	mv	a0,s1
    80003b94:	fffff097          	auipc	ra,0xfffff
    80003b98:	37a080e7          	jalr	890(ra) # 80002f0e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b9c:	01498a3b          	addw	s4,s3,s4
    80003ba0:	0129893b          	addw	s2,s3,s2
    80003ba4:	9aee                	add	s5,s5,s11
    80003ba6:	057a7663          	bgeu	s4,s7,80003bf2 <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003baa:	000b2483          	lw	s1,0(s6)
    80003bae:	00a9559b          	srliw	a1,s2,0xa
    80003bb2:	855a                	mv	a0,s6
    80003bb4:	fffff097          	auipc	ra,0xfffff
    80003bb8:	61e080e7          	jalr	1566(ra) # 800031d2 <bmap>
    80003bbc:	0005059b          	sext.w	a1,a0
    80003bc0:	8526                	mv	a0,s1
    80003bc2:	fffff097          	auipc	ra,0xfffff
    80003bc6:	21c080e7          	jalr	540(ra) # 80002dde <bread>
    80003bca:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bcc:	3ff97513          	andi	a0,s2,1023
    80003bd0:	40ad07bb          	subw	a5,s10,a0
    80003bd4:	414b873b          	subw	a4,s7,s4
    80003bd8:	89be                	mv	s3,a5
    80003bda:	2781                	sext.w	a5,a5
    80003bdc:	0007069b          	sext.w	a3,a4
    80003be0:	f8f6f4e3          	bgeu	a3,a5,80003b68 <writei+0x4e>
    80003be4:	89ba                	mv	s3,a4
    80003be6:	b749                	j	80003b68 <writei+0x4e>
      brelse(bp);
    80003be8:	8526                	mv	a0,s1
    80003bea:	fffff097          	auipc	ra,0xfffff
    80003bee:	324080e7          	jalr	804(ra) # 80002f0e <brelse>
  }

  if(off > ip->size)
    80003bf2:	04cb2783          	lw	a5,76(s6)
    80003bf6:	0127f463          	bgeu	a5,s2,80003bfe <writei+0xe4>
    ip->size = off;
    80003bfa:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003bfe:	855a                	mv	a0,s6
    80003c00:	00000097          	auipc	ra,0x0
    80003c04:	9ee080e7          	jalr	-1554(ra) # 800035ee <iupdate>

  return tot;
    80003c08:	000a051b          	sext.w	a0,s4
}
    80003c0c:	70a6                	ld	ra,104(sp)
    80003c0e:	7406                	ld	s0,96(sp)
    80003c10:	64e6                	ld	s1,88(sp)
    80003c12:	6946                	ld	s2,80(sp)
    80003c14:	69a6                	ld	s3,72(sp)
    80003c16:	6a06                	ld	s4,64(sp)
    80003c18:	7ae2                	ld	s5,56(sp)
    80003c1a:	7b42                	ld	s6,48(sp)
    80003c1c:	7ba2                	ld	s7,40(sp)
    80003c1e:	7c02                	ld	s8,32(sp)
    80003c20:	6ce2                	ld	s9,24(sp)
    80003c22:	6d42                	ld	s10,16(sp)
    80003c24:	6da2                	ld	s11,8(sp)
    80003c26:	6165                	addi	sp,sp,112
    80003c28:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c2a:	8a5e                	mv	s4,s7
    80003c2c:	bfc9                	j	80003bfe <writei+0xe4>
    return -1;
    80003c2e:	557d                	li	a0,-1
}
    80003c30:	8082                	ret
    return -1;
    80003c32:	557d                	li	a0,-1
    80003c34:	bfe1                	j	80003c0c <writei+0xf2>
    return -1;
    80003c36:	557d                	li	a0,-1
    80003c38:	bfd1                	j	80003c0c <writei+0xf2>

0000000080003c3a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c3a:	1141                	addi	sp,sp,-16
    80003c3c:	e406                	sd	ra,8(sp)
    80003c3e:	e022                	sd	s0,0(sp)
    80003c40:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c42:	4639                	li	a2,14
    80003c44:	ffffd097          	auipc	ra,0xffffd
    80003c48:	152080e7          	jalr	338(ra) # 80000d96 <strncmp>
}
    80003c4c:	60a2                	ld	ra,8(sp)
    80003c4e:	6402                	ld	s0,0(sp)
    80003c50:	0141                	addi	sp,sp,16
    80003c52:	8082                	ret

0000000080003c54 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c54:	7139                	addi	sp,sp,-64
    80003c56:	fc06                	sd	ra,56(sp)
    80003c58:	f822                	sd	s0,48(sp)
    80003c5a:	f426                	sd	s1,40(sp)
    80003c5c:	f04a                	sd	s2,32(sp)
    80003c5e:	ec4e                	sd	s3,24(sp)
    80003c60:	e852                	sd	s4,16(sp)
    80003c62:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c64:	04451703          	lh	a4,68(a0)
    80003c68:	4785                	li	a5,1
    80003c6a:	00f71a63          	bne	a4,a5,80003c7e <dirlookup+0x2a>
    80003c6e:	892a                	mv	s2,a0
    80003c70:	89ae                	mv	s3,a1
    80003c72:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c74:	457c                	lw	a5,76(a0)
    80003c76:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c78:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c7a:	e79d                	bnez	a5,80003ca8 <dirlookup+0x54>
    80003c7c:	a8a5                	j	80003cf4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c7e:	00005517          	auipc	a0,0x5
    80003c82:	95a50513          	addi	a0,a0,-1702 # 800085d8 <syscalls+0x1a8>
    80003c86:	ffffd097          	auipc	ra,0xffffd
    80003c8a:	8a4080e7          	jalr	-1884(ra) # 8000052a <panic>
      panic("dirlookup read");
    80003c8e:	00005517          	auipc	a0,0x5
    80003c92:	96250513          	addi	a0,a0,-1694 # 800085f0 <syscalls+0x1c0>
    80003c96:	ffffd097          	auipc	ra,0xffffd
    80003c9a:	894080e7          	jalr	-1900(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c9e:	24c1                	addiw	s1,s1,16
    80003ca0:	04c92783          	lw	a5,76(s2)
    80003ca4:	04f4f763          	bgeu	s1,a5,80003cf2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ca8:	4741                	li	a4,16
    80003caa:	86a6                	mv	a3,s1
    80003cac:	fc040613          	addi	a2,s0,-64
    80003cb0:	4581                	li	a1,0
    80003cb2:	854a                	mv	a0,s2
    80003cb4:	00000097          	auipc	ra,0x0
    80003cb8:	d6e080e7          	jalr	-658(ra) # 80003a22 <readi>
    80003cbc:	47c1                	li	a5,16
    80003cbe:	fcf518e3          	bne	a0,a5,80003c8e <dirlookup+0x3a>
    if(de.inum == 0)
    80003cc2:	fc045783          	lhu	a5,-64(s0)
    80003cc6:	dfe1                	beqz	a5,80003c9e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cc8:	fc240593          	addi	a1,s0,-62
    80003ccc:	854e                	mv	a0,s3
    80003cce:	00000097          	auipc	ra,0x0
    80003cd2:	f6c080e7          	jalr	-148(ra) # 80003c3a <namecmp>
    80003cd6:	f561                	bnez	a0,80003c9e <dirlookup+0x4a>
      if(poff)
    80003cd8:	000a0463          	beqz	s4,80003ce0 <dirlookup+0x8c>
        *poff = off;
    80003cdc:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ce0:	fc045583          	lhu	a1,-64(s0)
    80003ce4:	00092503          	lw	a0,0(s2)
    80003ce8:	fffff097          	auipc	ra,0xfffff
    80003cec:	69c080e7          	jalr	1692(ra) # 80003384 <iget>
    80003cf0:	a011                	j	80003cf4 <dirlookup+0xa0>
  return 0;
    80003cf2:	4501                	li	a0,0
}
    80003cf4:	70e2                	ld	ra,56(sp)
    80003cf6:	7442                	ld	s0,48(sp)
    80003cf8:	74a2                	ld	s1,40(sp)
    80003cfa:	7902                	ld	s2,32(sp)
    80003cfc:	69e2                	ld	s3,24(sp)
    80003cfe:	6a42                	ld	s4,16(sp)
    80003d00:	6121                	addi	sp,sp,64
    80003d02:	8082                	ret

0000000080003d04 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name, int depth)
{
    80003d04:	7151                	addi	sp,sp,-240
    80003d06:	f586                	sd	ra,232(sp)
    80003d08:	f1a2                	sd	s0,224(sp)
    80003d0a:	eda6                	sd	s1,216(sp)
    80003d0c:	e9ca                	sd	s2,208(sp)
    80003d0e:	e5ce                	sd	s3,200(sp)
    80003d10:	e1d2                	sd	s4,192(sp)
    80003d12:	fd56                	sd	s5,184(sp)
    80003d14:	f95a                	sd	s6,176(sp)
    80003d16:	f55e                	sd	s7,168(sp)
    80003d18:	f162                	sd	s8,160(sp)
    80003d1a:	ed66                	sd	s9,152(sp)
    80003d1c:	e96a                	sd	s10,144(sp)
    80003d1e:	1980                	addi	s0,sp,240
    80003d20:	84aa                	mv	s1,a0
    80003d22:	8b2e                	mv	s6,a1
    80003d24:	8a32                	mv	s4,a2
    80003d26:	8c36                	mv	s8,a3
  // TODO: Symbolic Link to Directories
  // Modify this function to deal with symbolic links to directories.
  struct inode *ip, *next;

  if(*path == '/')
    80003d28:	00054703          	lbu	a4,0(a0)
    80003d2c:	02f00793          	li	a5,47
    80003d30:	02f70463          	beq	a4,a5,80003d58 <namex+0x54>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d34:	ffffe097          	auipc	ra,0xffffe
    80003d38:	c8c080e7          	jalr	-884(ra) # 800019c0 <myproc>
    80003d3c:	15053503          	ld	a0,336(a0)
    80003d40:	00000097          	auipc	ra,0x0
    80003d44:	93a080e7          	jalr	-1734(ra) # 8000367a <idup>
    80003d48:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d4a:	02f00913          	li	s2,47
  len = path - s;
    80003d4e:	4a81                	li	s5,0
  if(len >= DIRSIZ)
    80003d50:	4bb5                	li	s7,13
      }
      iunlockput(ip);

      // open the target inode
      char name[DIRSIZ];
      if ((ip = namex(target, 0, name, depth + 1)) == 0) {
    80003d52:	001c0c9b          	addiw	s9,s8,1
    80003d56:	a235                	j	80003e82 <namex+0x17e>
    ip = iget(ROOTDEV, ROOTINO);
    80003d58:	4585                	li	a1,1
    80003d5a:	4505                	li	a0,1
    80003d5c:	fffff097          	auipc	ra,0xfffff
    80003d60:	628080e7          	jalr	1576(ra) # 80003384 <iget>
    80003d64:	89aa                	mv	s3,a0
    80003d66:	b7d5                	j	80003d4a <namex+0x46>
      if (depth >= 10) {
    80003d68:	47a5                	li	a5,9
    80003d6a:	0587c563          	blt	a5,s8,80003db4 <namex+0xb0>
      if (readi(ip, 0, (uint64)target, 0, MAXPATH) < 0) {
    80003d6e:	08000713          	li	a4,128
    80003d72:	86d6                	mv	a3,s5
    80003d74:	f2040613          	addi	a2,s0,-224
    80003d78:	85d6                	mv	a1,s5
    80003d7a:	854e                	mv	a0,s3
    80003d7c:	00000097          	auipc	ra,0x0
    80003d80:	ca6080e7          	jalr	-858(ra) # 80003a22 <readi>
    80003d84:	04054d63          	bltz	a0,80003dde <namex+0xda>
      iunlockput(ip);
    80003d88:	854e                	mv	a0,s3
    80003d8a:	00000097          	auipc	ra,0x0
    80003d8e:	c46080e7          	jalr	-954(ra) # 800039d0 <iunlockput>
      if ((ip = namex(target, 0, name, depth + 1)) == 0) {
    80003d92:	86e6                	mv	a3,s9
    80003d94:	f1040613          	addi	a2,s0,-240
    80003d98:	85d6                	mv	a1,s5
    80003d9a:	f2040513          	addi	a0,s0,-224
    80003d9e:	00000097          	auipc	ra,0x0
    80003da2:	f66080e7          	jalr	-154(ra) # 80003d04 <namex>
    80003da6:	89aa                	mv	s3,a0
    80003da8:	c919                	beqz	a0,80003dbe <namex+0xba>
        return 0;
      }
      ilock(ip);
    80003daa:	00000097          	auipc	ra,0x0
    80003dae:	90e080e7          	jalr	-1778(ra) # 800036b8 <ilock>
    80003db2:	a879                	j	80003e50 <namex+0x14c>
        iunlockput(ip);
    80003db4:	854e                	mv	a0,s3
    80003db6:	00000097          	auipc	ra,0x0
    80003dba:	c1a080e7          	jalr	-998(ra) # 800039d0 <iunlockput>
        return 0;
    80003dbe:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003dc0:	854e                	mv	a0,s3
    80003dc2:	70ae                	ld	ra,232(sp)
    80003dc4:	740e                	ld	s0,224(sp)
    80003dc6:	64ee                	ld	s1,216(sp)
    80003dc8:	694e                	ld	s2,208(sp)
    80003dca:	69ae                	ld	s3,200(sp)
    80003dcc:	6a0e                	ld	s4,192(sp)
    80003dce:	7aea                	ld	s5,184(sp)
    80003dd0:	7b4a                	ld	s6,176(sp)
    80003dd2:	7baa                	ld	s7,168(sp)
    80003dd4:	7c0a                	ld	s8,160(sp)
    80003dd6:	6cea                	ld	s9,152(sp)
    80003dd8:	6d4a                	ld	s10,144(sp)
    80003dda:	616d                	addi	sp,sp,240
    80003ddc:	8082                	ret
        iunlockput(ip);
    80003dde:	854e                	mv	a0,s3
    80003de0:	00000097          	auipc	ra,0x0
    80003de4:	bf0080e7          	jalr	-1040(ra) # 800039d0 <iunlockput>
        return 0;
    80003de8:	bfd9                	j	80003dbe <namex+0xba>
      iunlockput(ip);
    80003dea:	854e                	mv	a0,s3
    80003dec:	00000097          	auipc	ra,0x0
    80003df0:	be4080e7          	jalr	-1052(ra) # 800039d0 <iunlockput>
      return 0;
    80003df4:	4981                	li	s3,0
    80003df6:	b7e9                	j	80003dc0 <namex+0xbc>
      iunlock(ip);
    80003df8:	854e                	mv	a0,s3
    80003dfa:	00000097          	auipc	ra,0x0
    80003dfe:	980080e7          	jalr	-1664(ra) # 8000377a <iunlock>
      return ip;
    80003e02:	bf7d                	j	80003dc0 <namex+0xbc>
      iunlockput(ip);
    80003e04:	854e                	mv	a0,s3
    80003e06:	00000097          	auipc	ra,0x0
    80003e0a:	bca080e7          	jalr	-1078(ra) # 800039d0 <iunlockput>
      return 0;
    80003e0e:	89ea                	mv	s3,s10
    80003e10:	bf45                	j	80003dc0 <namex+0xbc>
  len = path - s;
    80003e12:	40b48633          	sub	a2,s1,a1
    80003e16:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003e1a:	09abda63          	bge	s7,s10,80003eae <namex+0x1aa>
    memmove(name, s, DIRSIZ);
    80003e1e:	4639                	li	a2,14
    80003e20:	8552                	mv	a0,s4
    80003e22:	ffffd097          	auipc	ra,0xffffd
    80003e26:	ef8080e7          	jalr	-264(ra) # 80000d1a <memmove>
  while(*path == '/')
    80003e2a:	0004c783          	lbu	a5,0(s1)
    80003e2e:	01279763          	bne	a5,s2,80003e3c <namex+0x138>
    path++;
    80003e32:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e34:	0004c783          	lbu	a5,0(s1)
    80003e38:	ff278de3          	beq	a5,s2,80003e32 <namex+0x12e>
    ilock(ip);
    80003e3c:	854e                	mv	a0,s3
    80003e3e:	00000097          	auipc	ra,0x0
    80003e42:	87a080e7          	jalr	-1926(ra) # 800036b8 <ilock>
    if (ip->type == T_SYMLINK) {
    80003e46:	04499703          	lh	a4,68(s3)
    80003e4a:	4791                	li	a5,4
    80003e4c:	f0f70ee3          	beq	a4,a5,80003d68 <namex+0x64>
    if(ip->type != T_DIR){
    80003e50:	04499703          	lh	a4,68(s3)
    80003e54:	4785                	li	a5,1
    80003e56:	f8f71ae3          	bne	a4,a5,80003dea <namex+0xe6>
    if(nameiparent && *path == '\0'){
    80003e5a:	000b0563          	beqz	s6,80003e64 <namex+0x160>
    80003e5e:	0004c783          	lbu	a5,0(s1)
    80003e62:	dbd9                	beqz	a5,80003df8 <namex+0xf4>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e64:	8656                	mv	a2,s5
    80003e66:	85d2                	mv	a1,s4
    80003e68:	854e                	mv	a0,s3
    80003e6a:	00000097          	auipc	ra,0x0
    80003e6e:	dea080e7          	jalr	-534(ra) # 80003c54 <dirlookup>
    80003e72:	8d2a                	mv	s10,a0
    80003e74:	d941                	beqz	a0,80003e04 <namex+0x100>
    iunlockput(ip);
    80003e76:	854e                	mv	a0,s3
    80003e78:	00000097          	auipc	ra,0x0
    80003e7c:	b58080e7          	jalr	-1192(ra) # 800039d0 <iunlockput>
    ip = next;
    80003e80:	89ea                	mv	s3,s10
  while(*path == '/')
    80003e82:	0004c783          	lbu	a5,0(s1)
    80003e86:	05279763          	bne	a5,s2,80003ed4 <namex+0x1d0>
    path++;
    80003e8a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e8c:	0004c783          	lbu	a5,0(s1)
    80003e90:	ff278de3          	beq	a5,s2,80003e8a <namex+0x186>
  if(*path == 0)
    80003e94:	c79d                	beqz	a5,80003ec2 <namex+0x1be>
    path++;
    80003e96:	85a6                	mv	a1,s1
  len = path - s;
    80003e98:	8d56                	mv	s10,s5
    80003e9a:	8656                	mv	a2,s5
  while(*path != '/' && *path != 0)
    80003e9c:	01278963          	beq	a5,s2,80003eae <namex+0x1aa>
    80003ea0:	dbad                	beqz	a5,80003e12 <namex+0x10e>
    path++;
    80003ea2:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003ea4:	0004c783          	lbu	a5,0(s1)
    80003ea8:	ff279ce3          	bne	a5,s2,80003ea0 <namex+0x19c>
    80003eac:	b79d                	j	80003e12 <namex+0x10e>
    memmove(name, s, len);
    80003eae:	2601                	sext.w	a2,a2
    80003eb0:	8552                	mv	a0,s4
    80003eb2:	ffffd097          	auipc	ra,0xffffd
    80003eb6:	e68080e7          	jalr	-408(ra) # 80000d1a <memmove>
    name[len] = 0;
    80003eba:	9d52                	add	s10,s10,s4
    80003ebc:	000d0023          	sb	zero,0(s10)
    80003ec0:	b7ad                	j	80003e2a <namex+0x126>
  if(nameiparent){
    80003ec2:	ee0b0fe3          	beqz	s6,80003dc0 <namex+0xbc>
    iput(ip);
    80003ec6:	854e                	mv	a0,s3
    80003ec8:	00000097          	auipc	ra,0x0
    80003ecc:	a60080e7          	jalr	-1440(ra) # 80003928 <iput>
    return 0;
    80003ed0:	4981                	li	s3,0
    80003ed2:	b5fd                	j	80003dc0 <namex+0xbc>
  if(*path == 0)
    80003ed4:	d7fd                	beqz	a5,80003ec2 <namex+0x1be>
  while(*path != '/' && *path != 0)
    80003ed6:	0004c783          	lbu	a5,0(s1)
    80003eda:	85a6                	mv	a1,s1
    80003edc:	b7d1                	j	80003ea0 <namex+0x19c>

0000000080003ede <dirlink>:
{
    80003ede:	7139                	addi	sp,sp,-64
    80003ee0:	fc06                	sd	ra,56(sp)
    80003ee2:	f822                	sd	s0,48(sp)
    80003ee4:	f426                	sd	s1,40(sp)
    80003ee6:	f04a                	sd	s2,32(sp)
    80003ee8:	ec4e                	sd	s3,24(sp)
    80003eea:	e852                	sd	s4,16(sp)
    80003eec:	0080                	addi	s0,sp,64
    80003eee:	892a                	mv	s2,a0
    80003ef0:	8a2e                	mv	s4,a1
    80003ef2:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ef4:	4601                	li	a2,0
    80003ef6:	00000097          	auipc	ra,0x0
    80003efa:	d5e080e7          	jalr	-674(ra) # 80003c54 <dirlookup>
    80003efe:	e93d                	bnez	a0,80003f74 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f00:	04c92483          	lw	s1,76(s2)
    80003f04:	c49d                	beqz	s1,80003f32 <dirlink+0x54>
    80003f06:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f08:	4741                	li	a4,16
    80003f0a:	86a6                	mv	a3,s1
    80003f0c:	fc040613          	addi	a2,s0,-64
    80003f10:	4581                	li	a1,0
    80003f12:	854a                	mv	a0,s2
    80003f14:	00000097          	auipc	ra,0x0
    80003f18:	b0e080e7          	jalr	-1266(ra) # 80003a22 <readi>
    80003f1c:	47c1                	li	a5,16
    80003f1e:	06f51163          	bne	a0,a5,80003f80 <dirlink+0xa2>
    if(de.inum == 0)
    80003f22:	fc045783          	lhu	a5,-64(s0)
    80003f26:	c791                	beqz	a5,80003f32 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f28:	24c1                	addiw	s1,s1,16
    80003f2a:	04c92783          	lw	a5,76(s2)
    80003f2e:	fcf4ede3          	bltu	s1,a5,80003f08 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f32:	4639                	li	a2,14
    80003f34:	85d2                	mv	a1,s4
    80003f36:	fc240513          	addi	a0,s0,-62
    80003f3a:	ffffd097          	auipc	ra,0xffffd
    80003f3e:	e98080e7          	jalr	-360(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80003f42:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f46:	4741                	li	a4,16
    80003f48:	86a6                	mv	a3,s1
    80003f4a:	fc040613          	addi	a2,s0,-64
    80003f4e:	4581                	li	a1,0
    80003f50:	854a                	mv	a0,s2
    80003f52:	00000097          	auipc	ra,0x0
    80003f56:	bc8080e7          	jalr	-1080(ra) # 80003b1a <writei>
    80003f5a:	872a                	mv	a4,a0
    80003f5c:	47c1                	li	a5,16
  return 0;
    80003f5e:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f60:	02f71863          	bne	a4,a5,80003f90 <dirlink+0xb2>
}
    80003f64:	70e2                	ld	ra,56(sp)
    80003f66:	7442                	ld	s0,48(sp)
    80003f68:	74a2                	ld	s1,40(sp)
    80003f6a:	7902                	ld	s2,32(sp)
    80003f6c:	69e2                	ld	s3,24(sp)
    80003f6e:	6a42                	ld	s4,16(sp)
    80003f70:	6121                	addi	sp,sp,64
    80003f72:	8082                	ret
    iput(ip);
    80003f74:	00000097          	auipc	ra,0x0
    80003f78:	9b4080e7          	jalr	-1612(ra) # 80003928 <iput>
    return -1;
    80003f7c:	557d                	li	a0,-1
    80003f7e:	b7dd                	j	80003f64 <dirlink+0x86>
      panic("dirlink read");
    80003f80:	00004517          	auipc	a0,0x4
    80003f84:	68050513          	addi	a0,a0,1664 # 80008600 <syscalls+0x1d0>
    80003f88:	ffffc097          	auipc	ra,0xffffc
    80003f8c:	5a2080e7          	jalr	1442(ra) # 8000052a <panic>
    panic("dirlink");
    80003f90:	00004517          	auipc	a0,0x4
    80003f94:	78050513          	addi	a0,a0,1920 # 80008710 <syscalls+0x2e0>
    80003f98:	ffffc097          	auipc	ra,0xffffc
    80003f9c:	592080e7          	jalr	1426(ra) # 8000052a <panic>

0000000080003fa0 <namei>:

struct inode*
namei(char *path)
{
    80003fa0:	1101                	addi	sp,sp,-32
    80003fa2:	ec06                	sd	ra,24(sp)
    80003fa4:	e822                	sd	s0,16(sp)
    80003fa6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name, 0);
    80003fa8:	4681                	li	a3,0
    80003faa:	fe040613          	addi	a2,s0,-32
    80003fae:	4581                	li	a1,0
    80003fb0:	00000097          	auipc	ra,0x0
    80003fb4:	d54080e7          	jalr	-684(ra) # 80003d04 <namex>
}
    80003fb8:	60e2                	ld	ra,24(sp)
    80003fba:	6442                	ld	s0,16(sp)
    80003fbc:	6105                	addi	sp,sp,32
    80003fbe:	8082                	ret

0000000080003fc0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003fc0:	1141                	addi	sp,sp,-16
    80003fc2:	e406                	sd	ra,8(sp)
    80003fc4:	e022                	sd	s0,0(sp)
    80003fc6:	0800                	addi	s0,sp,16
    80003fc8:	862e                	mv	a2,a1
  return namex(path, 1, name, 0);
    80003fca:	4681                	li	a3,0
    80003fcc:	4585                	li	a1,1
    80003fce:	00000097          	auipc	ra,0x0
    80003fd2:	d36080e7          	jalr	-714(ra) # 80003d04 <namex>
    80003fd6:	60a2                	ld	ra,8(sp)
    80003fd8:	6402                	ld	s0,0(sp)
    80003fda:	0141                	addi	sp,sp,16
    80003fdc:	8082                	ret

0000000080003fde <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fde:	1101                	addi	sp,sp,-32
    80003fe0:	ec06                	sd	ra,24(sp)
    80003fe2:	e822                	sd	s0,16(sp)
    80003fe4:	e426                	sd	s1,8(sp)
    80003fe6:	e04a                	sd	s2,0(sp)
    80003fe8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fea:	0001d917          	auipc	s2,0x1d
    80003fee:	28690913          	addi	s2,s2,646 # 80021270 <log>
    80003ff2:	01892583          	lw	a1,24(s2)
    80003ff6:	02892503          	lw	a0,40(s2)
    80003ffa:	fffff097          	auipc	ra,0xfffff
    80003ffe:	de4080e7          	jalr	-540(ra) # 80002dde <bread>
    80004002:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004004:	02c92683          	lw	a3,44(s2)
    80004008:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000400a:	02d05763          	blez	a3,80004038 <write_head+0x5a>
    8000400e:	0001d797          	auipc	a5,0x1d
    80004012:	29278793          	addi	a5,a5,658 # 800212a0 <log+0x30>
    80004016:	05c50713          	addi	a4,a0,92
    8000401a:	36fd                	addiw	a3,a3,-1
    8000401c:	1682                	slli	a3,a3,0x20
    8000401e:	9281                	srli	a3,a3,0x20
    80004020:	068a                	slli	a3,a3,0x2
    80004022:	0001d617          	auipc	a2,0x1d
    80004026:	28260613          	addi	a2,a2,642 # 800212a4 <log+0x34>
    8000402a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000402c:	4390                	lw	a2,0(a5)
    8000402e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004030:	0791                	addi	a5,a5,4
    80004032:	0711                	addi	a4,a4,4
    80004034:	fed79ce3          	bne	a5,a3,8000402c <write_head+0x4e>
  }
  bwrite(buf);
    80004038:	8526                	mv	a0,s1
    8000403a:	fffff097          	auipc	ra,0xfffff
    8000403e:	e96080e7          	jalr	-362(ra) # 80002ed0 <bwrite>
  brelse(buf);
    80004042:	8526                	mv	a0,s1
    80004044:	fffff097          	auipc	ra,0xfffff
    80004048:	eca080e7          	jalr	-310(ra) # 80002f0e <brelse>
}
    8000404c:	60e2                	ld	ra,24(sp)
    8000404e:	6442                	ld	s0,16(sp)
    80004050:	64a2                	ld	s1,8(sp)
    80004052:	6902                	ld	s2,0(sp)
    80004054:	6105                	addi	sp,sp,32
    80004056:	8082                	ret

0000000080004058 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004058:	0001d797          	auipc	a5,0x1d
    8000405c:	2447a783          	lw	a5,580(a5) # 8002129c <log+0x2c>
    80004060:	0af05d63          	blez	a5,8000411a <install_trans+0xc2>
{
    80004064:	7139                	addi	sp,sp,-64
    80004066:	fc06                	sd	ra,56(sp)
    80004068:	f822                	sd	s0,48(sp)
    8000406a:	f426                	sd	s1,40(sp)
    8000406c:	f04a                	sd	s2,32(sp)
    8000406e:	ec4e                	sd	s3,24(sp)
    80004070:	e852                	sd	s4,16(sp)
    80004072:	e456                	sd	s5,8(sp)
    80004074:	e05a                	sd	s6,0(sp)
    80004076:	0080                	addi	s0,sp,64
    80004078:	8b2a                	mv	s6,a0
    8000407a:	0001da97          	auipc	s5,0x1d
    8000407e:	226a8a93          	addi	s5,s5,550 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004082:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004084:	0001d997          	auipc	s3,0x1d
    80004088:	1ec98993          	addi	s3,s3,492 # 80021270 <log>
    8000408c:	a00d                	j	800040ae <install_trans+0x56>
    brelse(lbuf);
    8000408e:	854a                	mv	a0,s2
    80004090:	fffff097          	auipc	ra,0xfffff
    80004094:	e7e080e7          	jalr	-386(ra) # 80002f0e <brelse>
    brelse(dbuf);
    80004098:	8526                	mv	a0,s1
    8000409a:	fffff097          	auipc	ra,0xfffff
    8000409e:	e74080e7          	jalr	-396(ra) # 80002f0e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040a2:	2a05                	addiw	s4,s4,1
    800040a4:	0a91                	addi	s5,s5,4
    800040a6:	02c9a783          	lw	a5,44(s3)
    800040aa:	04fa5e63          	bge	s4,a5,80004106 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040ae:	0189a583          	lw	a1,24(s3)
    800040b2:	014585bb          	addw	a1,a1,s4
    800040b6:	2585                	addiw	a1,a1,1
    800040b8:	0289a503          	lw	a0,40(s3)
    800040bc:	fffff097          	auipc	ra,0xfffff
    800040c0:	d22080e7          	jalr	-734(ra) # 80002dde <bread>
    800040c4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800040c6:	000aa583          	lw	a1,0(s5)
    800040ca:	0289a503          	lw	a0,40(s3)
    800040ce:	fffff097          	auipc	ra,0xfffff
    800040d2:	d10080e7          	jalr	-752(ra) # 80002dde <bread>
    800040d6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040d8:	40000613          	li	a2,1024
    800040dc:	05890593          	addi	a1,s2,88
    800040e0:	05850513          	addi	a0,a0,88
    800040e4:	ffffd097          	auipc	ra,0xffffd
    800040e8:	c36080e7          	jalr	-970(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    800040ec:	8526                	mv	a0,s1
    800040ee:	fffff097          	auipc	ra,0xfffff
    800040f2:	de2080e7          	jalr	-542(ra) # 80002ed0 <bwrite>
    if(recovering == 0)
    800040f6:	f80b1ce3          	bnez	s6,8000408e <install_trans+0x36>
      bunpin(dbuf);
    800040fa:	8526                	mv	a0,s1
    800040fc:	fffff097          	auipc	ra,0xfffff
    80004100:	eec080e7          	jalr	-276(ra) # 80002fe8 <bunpin>
    80004104:	b769                	j	8000408e <install_trans+0x36>
}
    80004106:	70e2                	ld	ra,56(sp)
    80004108:	7442                	ld	s0,48(sp)
    8000410a:	74a2                	ld	s1,40(sp)
    8000410c:	7902                	ld	s2,32(sp)
    8000410e:	69e2                	ld	s3,24(sp)
    80004110:	6a42                	ld	s4,16(sp)
    80004112:	6aa2                	ld	s5,8(sp)
    80004114:	6b02                	ld	s6,0(sp)
    80004116:	6121                	addi	sp,sp,64
    80004118:	8082                	ret
    8000411a:	8082                	ret

000000008000411c <initlog>:
{
    8000411c:	7179                	addi	sp,sp,-48
    8000411e:	f406                	sd	ra,40(sp)
    80004120:	f022                	sd	s0,32(sp)
    80004122:	ec26                	sd	s1,24(sp)
    80004124:	e84a                	sd	s2,16(sp)
    80004126:	e44e                	sd	s3,8(sp)
    80004128:	1800                	addi	s0,sp,48
    8000412a:	892a                	mv	s2,a0
    8000412c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000412e:	0001d497          	auipc	s1,0x1d
    80004132:	14248493          	addi	s1,s1,322 # 80021270 <log>
    80004136:	00004597          	auipc	a1,0x4
    8000413a:	4da58593          	addi	a1,a1,1242 # 80008610 <syscalls+0x1e0>
    8000413e:	8526                	mv	a0,s1
    80004140:	ffffd097          	auipc	ra,0xffffd
    80004144:	9f2080e7          	jalr	-1550(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004148:	0149a583          	lw	a1,20(s3)
    8000414c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000414e:	0109a783          	lw	a5,16(s3)
    80004152:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004154:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004158:	854a                	mv	a0,s2
    8000415a:	fffff097          	auipc	ra,0xfffff
    8000415e:	c84080e7          	jalr	-892(ra) # 80002dde <bread>
  log.lh.n = lh->n;
    80004162:	4d34                	lw	a3,88(a0)
    80004164:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004166:	02d05563          	blez	a3,80004190 <initlog+0x74>
    8000416a:	05c50793          	addi	a5,a0,92
    8000416e:	0001d717          	auipc	a4,0x1d
    80004172:	13270713          	addi	a4,a4,306 # 800212a0 <log+0x30>
    80004176:	36fd                	addiw	a3,a3,-1
    80004178:	1682                	slli	a3,a3,0x20
    8000417a:	9281                	srli	a3,a3,0x20
    8000417c:	068a                	slli	a3,a3,0x2
    8000417e:	06050613          	addi	a2,a0,96
    80004182:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004184:	4390                	lw	a2,0(a5)
    80004186:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004188:	0791                	addi	a5,a5,4
    8000418a:	0711                	addi	a4,a4,4
    8000418c:	fed79ce3          	bne	a5,a3,80004184 <initlog+0x68>
  brelse(buf);
    80004190:	fffff097          	auipc	ra,0xfffff
    80004194:	d7e080e7          	jalr	-642(ra) # 80002f0e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004198:	4505                	li	a0,1
    8000419a:	00000097          	auipc	ra,0x0
    8000419e:	ebe080e7          	jalr	-322(ra) # 80004058 <install_trans>
  log.lh.n = 0;
    800041a2:	0001d797          	auipc	a5,0x1d
    800041a6:	0e07ad23          	sw	zero,250(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    800041aa:	00000097          	auipc	ra,0x0
    800041ae:	e34080e7          	jalr	-460(ra) # 80003fde <write_head>
}
    800041b2:	70a2                	ld	ra,40(sp)
    800041b4:	7402                	ld	s0,32(sp)
    800041b6:	64e2                	ld	s1,24(sp)
    800041b8:	6942                	ld	s2,16(sp)
    800041ba:	69a2                	ld	s3,8(sp)
    800041bc:	6145                	addi	sp,sp,48
    800041be:	8082                	ret

00000000800041c0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800041c0:	1101                	addi	sp,sp,-32
    800041c2:	ec06                	sd	ra,24(sp)
    800041c4:	e822                	sd	s0,16(sp)
    800041c6:	e426                	sd	s1,8(sp)
    800041c8:	e04a                	sd	s2,0(sp)
    800041ca:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800041cc:	0001d517          	auipc	a0,0x1d
    800041d0:	0a450513          	addi	a0,a0,164 # 80021270 <log>
    800041d4:	ffffd097          	auipc	ra,0xffffd
    800041d8:	9ee080e7          	jalr	-1554(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    800041dc:	0001d497          	auipc	s1,0x1d
    800041e0:	09448493          	addi	s1,s1,148 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041e4:	4979                	li	s2,30
    800041e6:	a039                	j	800041f4 <begin_op+0x34>
      sleep(&log, &log.lock);
    800041e8:	85a6                	mv	a1,s1
    800041ea:	8526                	mv	a0,s1
    800041ec:	ffffe097          	auipc	ra,0xffffe
    800041f0:	e94080e7          	jalr	-364(ra) # 80002080 <sleep>
    if(log.committing){
    800041f4:	50dc                	lw	a5,36(s1)
    800041f6:	fbed                	bnez	a5,800041e8 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041f8:	509c                	lw	a5,32(s1)
    800041fa:	0017871b          	addiw	a4,a5,1
    800041fe:	0007069b          	sext.w	a3,a4
    80004202:	0027179b          	slliw	a5,a4,0x2
    80004206:	9fb9                	addw	a5,a5,a4
    80004208:	0017979b          	slliw	a5,a5,0x1
    8000420c:	54d8                	lw	a4,44(s1)
    8000420e:	9fb9                	addw	a5,a5,a4
    80004210:	00f95963          	bge	s2,a5,80004222 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004214:	85a6                	mv	a1,s1
    80004216:	8526                	mv	a0,s1
    80004218:	ffffe097          	auipc	ra,0xffffe
    8000421c:	e68080e7          	jalr	-408(ra) # 80002080 <sleep>
    80004220:	bfd1                	j	800041f4 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004222:	0001d517          	auipc	a0,0x1d
    80004226:	04e50513          	addi	a0,a0,78 # 80021270 <log>
    8000422a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000422c:	ffffd097          	auipc	ra,0xffffd
    80004230:	a4a080e7          	jalr	-1462(ra) # 80000c76 <release>
      break;
    }
  }
}
    80004234:	60e2                	ld	ra,24(sp)
    80004236:	6442                	ld	s0,16(sp)
    80004238:	64a2                	ld	s1,8(sp)
    8000423a:	6902                	ld	s2,0(sp)
    8000423c:	6105                	addi	sp,sp,32
    8000423e:	8082                	ret

0000000080004240 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004240:	7139                	addi	sp,sp,-64
    80004242:	fc06                	sd	ra,56(sp)
    80004244:	f822                	sd	s0,48(sp)
    80004246:	f426                	sd	s1,40(sp)
    80004248:	f04a                	sd	s2,32(sp)
    8000424a:	ec4e                	sd	s3,24(sp)
    8000424c:	e852                	sd	s4,16(sp)
    8000424e:	e456                	sd	s5,8(sp)
    80004250:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004252:	0001d497          	auipc	s1,0x1d
    80004256:	01e48493          	addi	s1,s1,30 # 80021270 <log>
    8000425a:	8526                	mv	a0,s1
    8000425c:	ffffd097          	auipc	ra,0xffffd
    80004260:	966080e7          	jalr	-1690(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004264:	509c                	lw	a5,32(s1)
    80004266:	37fd                	addiw	a5,a5,-1
    80004268:	0007891b          	sext.w	s2,a5
    8000426c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000426e:	50dc                	lw	a5,36(s1)
    80004270:	e7b9                	bnez	a5,800042be <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004272:	04091e63          	bnez	s2,800042ce <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004276:	0001d497          	auipc	s1,0x1d
    8000427a:	ffa48493          	addi	s1,s1,-6 # 80021270 <log>
    8000427e:	4785                	li	a5,1
    80004280:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004282:	8526                	mv	a0,s1
    80004284:	ffffd097          	auipc	ra,0xffffd
    80004288:	9f2080e7          	jalr	-1550(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000428c:	54dc                	lw	a5,44(s1)
    8000428e:	06f04763          	bgtz	a5,800042fc <end_op+0xbc>
    acquire(&log.lock);
    80004292:	0001d497          	auipc	s1,0x1d
    80004296:	fde48493          	addi	s1,s1,-34 # 80021270 <log>
    8000429a:	8526                	mv	a0,s1
    8000429c:	ffffd097          	auipc	ra,0xffffd
    800042a0:	926080e7          	jalr	-1754(ra) # 80000bc2 <acquire>
    log.committing = 0;
    800042a4:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042a8:	8526                	mv	a0,s1
    800042aa:	ffffe097          	auipc	ra,0xffffe
    800042ae:	f62080e7          	jalr	-158(ra) # 8000220c <wakeup>
    release(&log.lock);
    800042b2:	8526                	mv	a0,s1
    800042b4:	ffffd097          	auipc	ra,0xffffd
    800042b8:	9c2080e7          	jalr	-1598(ra) # 80000c76 <release>
}
    800042bc:	a03d                	j	800042ea <end_op+0xaa>
    panic("log.committing");
    800042be:	00004517          	auipc	a0,0x4
    800042c2:	35a50513          	addi	a0,a0,858 # 80008618 <syscalls+0x1e8>
    800042c6:	ffffc097          	auipc	ra,0xffffc
    800042ca:	264080e7          	jalr	612(ra) # 8000052a <panic>
    wakeup(&log);
    800042ce:	0001d497          	auipc	s1,0x1d
    800042d2:	fa248493          	addi	s1,s1,-94 # 80021270 <log>
    800042d6:	8526                	mv	a0,s1
    800042d8:	ffffe097          	auipc	ra,0xffffe
    800042dc:	f34080e7          	jalr	-204(ra) # 8000220c <wakeup>
  release(&log.lock);
    800042e0:	8526                	mv	a0,s1
    800042e2:	ffffd097          	auipc	ra,0xffffd
    800042e6:	994080e7          	jalr	-1644(ra) # 80000c76 <release>
}
    800042ea:	70e2                	ld	ra,56(sp)
    800042ec:	7442                	ld	s0,48(sp)
    800042ee:	74a2                	ld	s1,40(sp)
    800042f0:	7902                	ld	s2,32(sp)
    800042f2:	69e2                	ld	s3,24(sp)
    800042f4:	6a42                	ld	s4,16(sp)
    800042f6:	6aa2                	ld	s5,8(sp)
    800042f8:	6121                	addi	sp,sp,64
    800042fa:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800042fc:	0001da97          	auipc	s5,0x1d
    80004300:	fa4a8a93          	addi	s5,s5,-92 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004304:	0001da17          	auipc	s4,0x1d
    80004308:	f6ca0a13          	addi	s4,s4,-148 # 80021270 <log>
    8000430c:	018a2583          	lw	a1,24(s4)
    80004310:	012585bb          	addw	a1,a1,s2
    80004314:	2585                	addiw	a1,a1,1
    80004316:	028a2503          	lw	a0,40(s4)
    8000431a:	fffff097          	auipc	ra,0xfffff
    8000431e:	ac4080e7          	jalr	-1340(ra) # 80002dde <bread>
    80004322:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004324:	000aa583          	lw	a1,0(s5)
    80004328:	028a2503          	lw	a0,40(s4)
    8000432c:	fffff097          	auipc	ra,0xfffff
    80004330:	ab2080e7          	jalr	-1358(ra) # 80002dde <bread>
    80004334:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004336:	40000613          	li	a2,1024
    8000433a:	05850593          	addi	a1,a0,88
    8000433e:	05848513          	addi	a0,s1,88
    80004342:	ffffd097          	auipc	ra,0xffffd
    80004346:	9d8080e7          	jalr	-1576(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    8000434a:	8526                	mv	a0,s1
    8000434c:	fffff097          	auipc	ra,0xfffff
    80004350:	b84080e7          	jalr	-1148(ra) # 80002ed0 <bwrite>
    brelse(from);
    80004354:	854e                	mv	a0,s3
    80004356:	fffff097          	auipc	ra,0xfffff
    8000435a:	bb8080e7          	jalr	-1096(ra) # 80002f0e <brelse>
    brelse(to);
    8000435e:	8526                	mv	a0,s1
    80004360:	fffff097          	auipc	ra,0xfffff
    80004364:	bae080e7          	jalr	-1106(ra) # 80002f0e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004368:	2905                	addiw	s2,s2,1
    8000436a:	0a91                	addi	s5,s5,4
    8000436c:	02ca2783          	lw	a5,44(s4)
    80004370:	f8f94ee3          	blt	s2,a5,8000430c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004374:	00000097          	auipc	ra,0x0
    80004378:	c6a080e7          	jalr	-918(ra) # 80003fde <write_head>
    install_trans(0); // Now install writes to home locations
    8000437c:	4501                	li	a0,0
    8000437e:	00000097          	auipc	ra,0x0
    80004382:	cda080e7          	jalr	-806(ra) # 80004058 <install_trans>
    log.lh.n = 0;
    80004386:	0001d797          	auipc	a5,0x1d
    8000438a:	f007ab23          	sw	zero,-234(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000438e:	00000097          	auipc	ra,0x0
    80004392:	c50080e7          	jalr	-944(ra) # 80003fde <write_head>
    80004396:	bdf5                	j	80004292 <end_op+0x52>

0000000080004398 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004398:	1101                	addi	sp,sp,-32
    8000439a:	ec06                	sd	ra,24(sp)
    8000439c:	e822                	sd	s0,16(sp)
    8000439e:	e426                	sd	s1,8(sp)
    800043a0:	e04a                	sd	s2,0(sp)
    800043a2:	1000                	addi	s0,sp,32
    800043a4:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800043a6:	0001d917          	auipc	s2,0x1d
    800043aa:	eca90913          	addi	s2,s2,-310 # 80021270 <log>
    800043ae:	854a                	mv	a0,s2
    800043b0:	ffffd097          	auipc	ra,0xffffd
    800043b4:	812080e7          	jalr	-2030(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800043b8:	02c92603          	lw	a2,44(s2)
    800043bc:	47f5                	li	a5,29
    800043be:	06c7c563          	blt	a5,a2,80004428 <log_write+0x90>
    800043c2:	0001d797          	auipc	a5,0x1d
    800043c6:	eca7a783          	lw	a5,-310(a5) # 8002128c <log+0x1c>
    800043ca:	37fd                	addiw	a5,a5,-1
    800043cc:	04f65e63          	bge	a2,a5,80004428 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800043d0:	0001d797          	auipc	a5,0x1d
    800043d4:	ec07a783          	lw	a5,-320(a5) # 80021290 <log+0x20>
    800043d8:	06f05063          	blez	a5,80004438 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800043dc:	4781                	li	a5,0
    800043de:	06c05563          	blez	a2,80004448 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800043e2:	44cc                	lw	a1,12(s1)
    800043e4:	0001d717          	auipc	a4,0x1d
    800043e8:	ebc70713          	addi	a4,a4,-324 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043ec:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800043ee:	4314                	lw	a3,0(a4)
    800043f0:	04b68c63          	beq	a3,a1,80004448 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800043f4:	2785                	addiw	a5,a5,1
    800043f6:	0711                	addi	a4,a4,4
    800043f8:	fef61be3          	bne	a2,a5,800043ee <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043fc:	0621                	addi	a2,a2,8
    800043fe:	060a                	slli	a2,a2,0x2
    80004400:	0001d797          	auipc	a5,0x1d
    80004404:	e7078793          	addi	a5,a5,-400 # 80021270 <log>
    80004408:	963e                	add	a2,a2,a5
    8000440a:	44dc                	lw	a5,12(s1)
    8000440c:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000440e:	8526                	mv	a0,s1
    80004410:	fffff097          	auipc	ra,0xfffff
    80004414:	b9c080e7          	jalr	-1124(ra) # 80002fac <bpin>
    log.lh.n++;
    80004418:	0001d717          	auipc	a4,0x1d
    8000441c:	e5870713          	addi	a4,a4,-424 # 80021270 <log>
    80004420:	575c                	lw	a5,44(a4)
    80004422:	2785                	addiw	a5,a5,1
    80004424:	d75c                	sw	a5,44(a4)
    80004426:	a835                	j	80004462 <log_write+0xca>
    panic("too big a transaction");
    80004428:	00004517          	auipc	a0,0x4
    8000442c:	20050513          	addi	a0,a0,512 # 80008628 <syscalls+0x1f8>
    80004430:	ffffc097          	auipc	ra,0xffffc
    80004434:	0fa080e7          	jalr	250(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004438:	00004517          	auipc	a0,0x4
    8000443c:	20850513          	addi	a0,a0,520 # 80008640 <syscalls+0x210>
    80004440:	ffffc097          	auipc	ra,0xffffc
    80004444:	0ea080e7          	jalr	234(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004448:	00878713          	addi	a4,a5,8
    8000444c:	00271693          	slli	a3,a4,0x2
    80004450:	0001d717          	auipc	a4,0x1d
    80004454:	e2070713          	addi	a4,a4,-480 # 80021270 <log>
    80004458:	9736                	add	a4,a4,a3
    8000445a:	44d4                	lw	a3,12(s1)
    8000445c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000445e:	faf608e3          	beq	a2,a5,8000440e <log_write+0x76>
  }
  release(&log.lock);
    80004462:	0001d517          	auipc	a0,0x1d
    80004466:	e0e50513          	addi	a0,a0,-498 # 80021270 <log>
    8000446a:	ffffd097          	auipc	ra,0xffffd
    8000446e:	80c080e7          	jalr	-2036(ra) # 80000c76 <release>
}
    80004472:	60e2                	ld	ra,24(sp)
    80004474:	6442                	ld	s0,16(sp)
    80004476:	64a2                	ld	s1,8(sp)
    80004478:	6902                	ld	s2,0(sp)
    8000447a:	6105                	addi	sp,sp,32
    8000447c:	8082                	ret

000000008000447e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000447e:	1101                	addi	sp,sp,-32
    80004480:	ec06                	sd	ra,24(sp)
    80004482:	e822                	sd	s0,16(sp)
    80004484:	e426                	sd	s1,8(sp)
    80004486:	e04a                	sd	s2,0(sp)
    80004488:	1000                	addi	s0,sp,32
    8000448a:	84aa                	mv	s1,a0
    8000448c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000448e:	00004597          	auipc	a1,0x4
    80004492:	1d258593          	addi	a1,a1,466 # 80008660 <syscalls+0x230>
    80004496:	0521                	addi	a0,a0,8
    80004498:	ffffc097          	auipc	ra,0xffffc
    8000449c:	69a080e7          	jalr	1690(ra) # 80000b32 <initlock>
  lk->name = name;
    800044a0:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044a4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044a8:	0204a423          	sw	zero,40(s1)
}
    800044ac:	60e2                	ld	ra,24(sp)
    800044ae:	6442                	ld	s0,16(sp)
    800044b0:	64a2                	ld	s1,8(sp)
    800044b2:	6902                	ld	s2,0(sp)
    800044b4:	6105                	addi	sp,sp,32
    800044b6:	8082                	ret

00000000800044b8 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800044b8:	1101                	addi	sp,sp,-32
    800044ba:	ec06                	sd	ra,24(sp)
    800044bc:	e822                	sd	s0,16(sp)
    800044be:	e426                	sd	s1,8(sp)
    800044c0:	e04a                	sd	s2,0(sp)
    800044c2:	1000                	addi	s0,sp,32
    800044c4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044c6:	00850913          	addi	s2,a0,8
    800044ca:	854a                	mv	a0,s2
    800044cc:	ffffc097          	auipc	ra,0xffffc
    800044d0:	6f6080e7          	jalr	1782(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    800044d4:	409c                	lw	a5,0(s1)
    800044d6:	cb89                	beqz	a5,800044e8 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044d8:	85ca                	mv	a1,s2
    800044da:	8526                	mv	a0,s1
    800044dc:	ffffe097          	auipc	ra,0xffffe
    800044e0:	ba4080e7          	jalr	-1116(ra) # 80002080 <sleep>
  while (lk->locked) {
    800044e4:	409c                	lw	a5,0(s1)
    800044e6:	fbed                	bnez	a5,800044d8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044e8:	4785                	li	a5,1
    800044ea:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044ec:	ffffd097          	auipc	ra,0xffffd
    800044f0:	4d4080e7          	jalr	1236(ra) # 800019c0 <myproc>
    800044f4:	591c                	lw	a5,48(a0)
    800044f6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044f8:	854a                	mv	a0,s2
    800044fa:	ffffc097          	auipc	ra,0xffffc
    800044fe:	77c080e7          	jalr	1916(ra) # 80000c76 <release>
}
    80004502:	60e2                	ld	ra,24(sp)
    80004504:	6442                	ld	s0,16(sp)
    80004506:	64a2                	ld	s1,8(sp)
    80004508:	6902                	ld	s2,0(sp)
    8000450a:	6105                	addi	sp,sp,32
    8000450c:	8082                	ret

000000008000450e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000450e:	1101                	addi	sp,sp,-32
    80004510:	ec06                	sd	ra,24(sp)
    80004512:	e822                	sd	s0,16(sp)
    80004514:	e426                	sd	s1,8(sp)
    80004516:	e04a                	sd	s2,0(sp)
    80004518:	1000                	addi	s0,sp,32
    8000451a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000451c:	00850913          	addi	s2,a0,8
    80004520:	854a                	mv	a0,s2
    80004522:	ffffc097          	auipc	ra,0xffffc
    80004526:	6a0080e7          	jalr	1696(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    8000452a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000452e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004532:	8526                	mv	a0,s1
    80004534:	ffffe097          	auipc	ra,0xffffe
    80004538:	cd8080e7          	jalr	-808(ra) # 8000220c <wakeup>
  release(&lk->lk);
    8000453c:	854a                	mv	a0,s2
    8000453e:	ffffc097          	auipc	ra,0xffffc
    80004542:	738080e7          	jalr	1848(ra) # 80000c76 <release>
}
    80004546:	60e2                	ld	ra,24(sp)
    80004548:	6442                	ld	s0,16(sp)
    8000454a:	64a2                	ld	s1,8(sp)
    8000454c:	6902                	ld	s2,0(sp)
    8000454e:	6105                	addi	sp,sp,32
    80004550:	8082                	ret

0000000080004552 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004552:	7179                	addi	sp,sp,-48
    80004554:	f406                	sd	ra,40(sp)
    80004556:	f022                	sd	s0,32(sp)
    80004558:	ec26                	sd	s1,24(sp)
    8000455a:	e84a                	sd	s2,16(sp)
    8000455c:	e44e                	sd	s3,8(sp)
    8000455e:	1800                	addi	s0,sp,48
    80004560:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004562:	00850913          	addi	s2,a0,8
    80004566:	854a                	mv	a0,s2
    80004568:	ffffc097          	auipc	ra,0xffffc
    8000456c:	65a080e7          	jalr	1626(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004570:	409c                	lw	a5,0(s1)
    80004572:	ef99                	bnez	a5,80004590 <holdingsleep+0x3e>
    80004574:	4481                	li	s1,0
  release(&lk->lk);
    80004576:	854a                	mv	a0,s2
    80004578:	ffffc097          	auipc	ra,0xffffc
    8000457c:	6fe080e7          	jalr	1790(ra) # 80000c76 <release>
  return r;
}
    80004580:	8526                	mv	a0,s1
    80004582:	70a2                	ld	ra,40(sp)
    80004584:	7402                	ld	s0,32(sp)
    80004586:	64e2                	ld	s1,24(sp)
    80004588:	6942                	ld	s2,16(sp)
    8000458a:	69a2                	ld	s3,8(sp)
    8000458c:	6145                	addi	sp,sp,48
    8000458e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004590:	0284a983          	lw	s3,40(s1)
    80004594:	ffffd097          	auipc	ra,0xffffd
    80004598:	42c080e7          	jalr	1068(ra) # 800019c0 <myproc>
    8000459c:	5904                	lw	s1,48(a0)
    8000459e:	413484b3          	sub	s1,s1,s3
    800045a2:	0014b493          	seqz	s1,s1
    800045a6:	bfc1                	j	80004576 <holdingsleep+0x24>

00000000800045a8 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045a8:	1141                	addi	sp,sp,-16
    800045aa:	e406                	sd	ra,8(sp)
    800045ac:	e022                	sd	s0,0(sp)
    800045ae:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800045b0:	00004597          	auipc	a1,0x4
    800045b4:	0c058593          	addi	a1,a1,192 # 80008670 <syscalls+0x240>
    800045b8:	0001d517          	auipc	a0,0x1d
    800045bc:	e0050513          	addi	a0,a0,-512 # 800213b8 <ftable>
    800045c0:	ffffc097          	auipc	ra,0xffffc
    800045c4:	572080e7          	jalr	1394(ra) # 80000b32 <initlock>
}
    800045c8:	60a2                	ld	ra,8(sp)
    800045ca:	6402                	ld	s0,0(sp)
    800045cc:	0141                	addi	sp,sp,16
    800045ce:	8082                	ret

00000000800045d0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045d0:	1101                	addi	sp,sp,-32
    800045d2:	ec06                	sd	ra,24(sp)
    800045d4:	e822                	sd	s0,16(sp)
    800045d6:	e426                	sd	s1,8(sp)
    800045d8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045da:	0001d517          	auipc	a0,0x1d
    800045de:	dde50513          	addi	a0,a0,-546 # 800213b8 <ftable>
    800045e2:	ffffc097          	auipc	ra,0xffffc
    800045e6:	5e0080e7          	jalr	1504(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045ea:	0001d497          	auipc	s1,0x1d
    800045ee:	de648493          	addi	s1,s1,-538 # 800213d0 <ftable+0x18>
    800045f2:	0001e717          	auipc	a4,0x1e
    800045f6:	d7e70713          	addi	a4,a4,-642 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    800045fa:	40dc                	lw	a5,4(s1)
    800045fc:	cf99                	beqz	a5,8000461a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045fe:	02848493          	addi	s1,s1,40
    80004602:	fee49ce3          	bne	s1,a4,800045fa <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004606:	0001d517          	auipc	a0,0x1d
    8000460a:	db250513          	addi	a0,a0,-590 # 800213b8 <ftable>
    8000460e:	ffffc097          	auipc	ra,0xffffc
    80004612:	668080e7          	jalr	1640(ra) # 80000c76 <release>
  return 0;
    80004616:	4481                	li	s1,0
    80004618:	a819                	j	8000462e <filealloc+0x5e>
      f->ref = 1;
    8000461a:	4785                	li	a5,1
    8000461c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000461e:	0001d517          	auipc	a0,0x1d
    80004622:	d9a50513          	addi	a0,a0,-614 # 800213b8 <ftable>
    80004626:	ffffc097          	auipc	ra,0xffffc
    8000462a:	650080e7          	jalr	1616(ra) # 80000c76 <release>
}
    8000462e:	8526                	mv	a0,s1
    80004630:	60e2                	ld	ra,24(sp)
    80004632:	6442                	ld	s0,16(sp)
    80004634:	64a2                	ld	s1,8(sp)
    80004636:	6105                	addi	sp,sp,32
    80004638:	8082                	ret

000000008000463a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000463a:	1101                	addi	sp,sp,-32
    8000463c:	ec06                	sd	ra,24(sp)
    8000463e:	e822                	sd	s0,16(sp)
    80004640:	e426                	sd	s1,8(sp)
    80004642:	1000                	addi	s0,sp,32
    80004644:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004646:	0001d517          	auipc	a0,0x1d
    8000464a:	d7250513          	addi	a0,a0,-654 # 800213b8 <ftable>
    8000464e:	ffffc097          	auipc	ra,0xffffc
    80004652:	574080e7          	jalr	1396(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004656:	40dc                	lw	a5,4(s1)
    80004658:	02f05263          	blez	a5,8000467c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000465c:	2785                	addiw	a5,a5,1
    8000465e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004660:	0001d517          	auipc	a0,0x1d
    80004664:	d5850513          	addi	a0,a0,-680 # 800213b8 <ftable>
    80004668:	ffffc097          	auipc	ra,0xffffc
    8000466c:	60e080e7          	jalr	1550(ra) # 80000c76 <release>
  return f;
}
    80004670:	8526                	mv	a0,s1
    80004672:	60e2                	ld	ra,24(sp)
    80004674:	6442                	ld	s0,16(sp)
    80004676:	64a2                	ld	s1,8(sp)
    80004678:	6105                	addi	sp,sp,32
    8000467a:	8082                	ret
    panic("filedup");
    8000467c:	00004517          	auipc	a0,0x4
    80004680:	ffc50513          	addi	a0,a0,-4 # 80008678 <syscalls+0x248>
    80004684:	ffffc097          	auipc	ra,0xffffc
    80004688:	ea6080e7          	jalr	-346(ra) # 8000052a <panic>

000000008000468c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000468c:	7139                	addi	sp,sp,-64
    8000468e:	fc06                	sd	ra,56(sp)
    80004690:	f822                	sd	s0,48(sp)
    80004692:	f426                	sd	s1,40(sp)
    80004694:	f04a                	sd	s2,32(sp)
    80004696:	ec4e                	sd	s3,24(sp)
    80004698:	e852                	sd	s4,16(sp)
    8000469a:	e456                	sd	s5,8(sp)
    8000469c:	0080                	addi	s0,sp,64
    8000469e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046a0:	0001d517          	auipc	a0,0x1d
    800046a4:	d1850513          	addi	a0,a0,-744 # 800213b8 <ftable>
    800046a8:	ffffc097          	auipc	ra,0xffffc
    800046ac:	51a080e7          	jalr	1306(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    800046b0:	40dc                	lw	a5,4(s1)
    800046b2:	06f05163          	blez	a5,80004714 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800046b6:	37fd                	addiw	a5,a5,-1
    800046b8:	0007871b          	sext.w	a4,a5
    800046bc:	c0dc                	sw	a5,4(s1)
    800046be:	06e04363          	bgtz	a4,80004724 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800046c2:	0004a903          	lw	s2,0(s1)
    800046c6:	0094ca83          	lbu	s5,9(s1)
    800046ca:	0104ba03          	ld	s4,16(s1)
    800046ce:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046d2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046d6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046da:	0001d517          	auipc	a0,0x1d
    800046de:	cde50513          	addi	a0,a0,-802 # 800213b8 <ftable>
    800046e2:	ffffc097          	auipc	ra,0xffffc
    800046e6:	594080e7          	jalr	1428(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    800046ea:	4785                	li	a5,1
    800046ec:	04f90d63          	beq	s2,a5,80004746 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046f0:	3979                	addiw	s2,s2,-2
    800046f2:	4785                	li	a5,1
    800046f4:	0527e063          	bltu	a5,s2,80004734 <fileclose+0xa8>
    begin_op();
    800046f8:	00000097          	auipc	ra,0x0
    800046fc:	ac8080e7          	jalr	-1336(ra) # 800041c0 <begin_op>
    iput(ff.ip);
    80004700:	854e                	mv	a0,s3
    80004702:	fffff097          	auipc	ra,0xfffff
    80004706:	226080e7          	jalr	550(ra) # 80003928 <iput>
    end_op();
    8000470a:	00000097          	auipc	ra,0x0
    8000470e:	b36080e7          	jalr	-1226(ra) # 80004240 <end_op>
    80004712:	a00d                	j	80004734 <fileclose+0xa8>
    panic("fileclose");
    80004714:	00004517          	auipc	a0,0x4
    80004718:	f6c50513          	addi	a0,a0,-148 # 80008680 <syscalls+0x250>
    8000471c:	ffffc097          	auipc	ra,0xffffc
    80004720:	e0e080e7          	jalr	-498(ra) # 8000052a <panic>
    release(&ftable.lock);
    80004724:	0001d517          	auipc	a0,0x1d
    80004728:	c9450513          	addi	a0,a0,-876 # 800213b8 <ftable>
    8000472c:	ffffc097          	auipc	ra,0xffffc
    80004730:	54a080e7          	jalr	1354(ra) # 80000c76 <release>
  }
}
    80004734:	70e2                	ld	ra,56(sp)
    80004736:	7442                	ld	s0,48(sp)
    80004738:	74a2                	ld	s1,40(sp)
    8000473a:	7902                	ld	s2,32(sp)
    8000473c:	69e2                	ld	s3,24(sp)
    8000473e:	6a42                	ld	s4,16(sp)
    80004740:	6aa2                	ld	s5,8(sp)
    80004742:	6121                	addi	sp,sp,64
    80004744:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004746:	85d6                	mv	a1,s5
    80004748:	8552                	mv	a0,s4
    8000474a:	00000097          	auipc	ra,0x0
    8000474e:	34c080e7          	jalr	844(ra) # 80004a96 <pipeclose>
    80004752:	b7cd                	j	80004734 <fileclose+0xa8>

0000000080004754 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004754:	715d                	addi	sp,sp,-80
    80004756:	e486                	sd	ra,72(sp)
    80004758:	e0a2                	sd	s0,64(sp)
    8000475a:	fc26                	sd	s1,56(sp)
    8000475c:	f84a                	sd	s2,48(sp)
    8000475e:	f44e                	sd	s3,40(sp)
    80004760:	0880                	addi	s0,sp,80
    80004762:	84aa                	mv	s1,a0
    80004764:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004766:	ffffd097          	auipc	ra,0xffffd
    8000476a:	25a080e7          	jalr	602(ra) # 800019c0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000476e:	409c                	lw	a5,0(s1)
    80004770:	37f9                	addiw	a5,a5,-2
    80004772:	4705                	li	a4,1
    80004774:	04f76763          	bltu	a4,a5,800047c2 <filestat+0x6e>
    80004778:	892a                	mv	s2,a0
    ilock(f->ip);
    8000477a:	6c88                	ld	a0,24(s1)
    8000477c:	fffff097          	auipc	ra,0xfffff
    80004780:	f3c080e7          	jalr	-196(ra) # 800036b8 <ilock>
    stati(f->ip, &st);
    80004784:	fb840593          	addi	a1,s0,-72
    80004788:	6c88                	ld	a0,24(s1)
    8000478a:	fffff097          	auipc	ra,0xfffff
    8000478e:	26e080e7          	jalr	622(ra) # 800039f8 <stati>
    iunlock(f->ip);
    80004792:	6c88                	ld	a0,24(s1)
    80004794:	fffff097          	auipc	ra,0xfffff
    80004798:	fe6080e7          	jalr	-26(ra) # 8000377a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000479c:	46e1                	li	a3,24
    8000479e:	fb840613          	addi	a2,s0,-72
    800047a2:	85ce                	mv	a1,s3
    800047a4:	05093503          	ld	a0,80(s2)
    800047a8:	ffffd097          	auipc	ra,0xffffd
    800047ac:	ed8080e7          	jalr	-296(ra) # 80001680 <copyout>
    800047b0:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800047b4:	60a6                	ld	ra,72(sp)
    800047b6:	6406                	ld	s0,64(sp)
    800047b8:	74e2                	ld	s1,56(sp)
    800047ba:	7942                	ld	s2,48(sp)
    800047bc:	79a2                	ld	s3,40(sp)
    800047be:	6161                	addi	sp,sp,80
    800047c0:	8082                	ret
  return -1;
    800047c2:	557d                	li	a0,-1
    800047c4:	bfc5                	j	800047b4 <filestat+0x60>

00000000800047c6 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800047c6:	7179                	addi	sp,sp,-48
    800047c8:	f406                	sd	ra,40(sp)
    800047ca:	f022                	sd	s0,32(sp)
    800047cc:	ec26                	sd	s1,24(sp)
    800047ce:	e84a                	sd	s2,16(sp)
    800047d0:	e44e                	sd	s3,8(sp)
    800047d2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047d4:	00854783          	lbu	a5,8(a0)
    800047d8:	c3d5                	beqz	a5,8000487c <fileread+0xb6>
    800047da:	84aa                	mv	s1,a0
    800047dc:	89ae                	mv	s3,a1
    800047de:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047e0:	411c                	lw	a5,0(a0)
    800047e2:	4705                	li	a4,1
    800047e4:	04e78963          	beq	a5,a4,80004836 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047e8:	470d                	li	a4,3
    800047ea:	04e78d63          	beq	a5,a4,80004844 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047ee:	4709                	li	a4,2
    800047f0:	06e79e63          	bne	a5,a4,8000486c <fileread+0xa6>
    ilock(f->ip);
    800047f4:	6d08                	ld	a0,24(a0)
    800047f6:	fffff097          	auipc	ra,0xfffff
    800047fa:	ec2080e7          	jalr	-318(ra) # 800036b8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047fe:	874a                	mv	a4,s2
    80004800:	5094                	lw	a3,32(s1)
    80004802:	864e                	mv	a2,s3
    80004804:	4585                	li	a1,1
    80004806:	6c88                	ld	a0,24(s1)
    80004808:	fffff097          	auipc	ra,0xfffff
    8000480c:	21a080e7          	jalr	538(ra) # 80003a22 <readi>
    80004810:	892a                	mv	s2,a0
    80004812:	00a05563          	blez	a0,8000481c <fileread+0x56>
      f->off += r;
    80004816:	509c                	lw	a5,32(s1)
    80004818:	9fa9                	addw	a5,a5,a0
    8000481a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000481c:	6c88                	ld	a0,24(s1)
    8000481e:	fffff097          	auipc	ra,0xfffff
    80004822:	f5c080e7          	jalr	-164(ra) # 8000377a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004826:	854a                	mv	a0,s2
    80004828:	70a2                	ld	ra,40(sp)
    8000482a:	7402                	ld	s0,32(sp)
    8000482c:	64e2                	ld	s1,24(sp)
    8000482e:	6942                	ld	s2,16(sp)
    80004830:	69a2                	ld	s3,8(sp)
    80004832:	6145                	addi	sp,sp,48
    80004834:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004836:	6908                	ld	a0,16(a0)
    80004838:	00000097          	auipc	ra,0x0
    8000483c:	3c0080e7          	jalr	960(ra) # 80004bf8 <piperead>
    80004840:	892a                	mv	s2,a0
    80004842:	b7d5                	j	80004826 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004844:	02451783          	lh	a5,36(a0)
    80004848:	03079693          	slli	a3,a5,0x30
    8000484c:	92c1                	srli	a3,a3,0x30
    8000484e:	4725                	li	a4,9
    80004850:	02d76863          	bltu	a4,a3,80004880 <fileread+0xba>
    80004854:	0792                	slli	a5,a5,0x4
    80004856:	0001d717          	auipc	a4,0x1d
    8000485a:	ac270713          	addi	a4,a4,-1342 # 80021318 <devsw>
    8000485e:	97ba                	add	a5,a5,a4
    80004860:	639c                	ld	a5,0(a5)
    80004862:	c38d                	beqz	a5,80004884 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004864:	4505                	li	a0,1
    80004866:	9782                	jalr	a5
    80004868:	892a                	mv	s2,a0
    8000486a:	bf75                	j	80004826 <fileread+0x60>
    panic("fileread");
    8000486c:	00004517          	auipc	a0,0x4
    80004870:	e2450513          	addi	a0,a0,-476 # 80008690 <syscalls+0x260>
    80004874:	ffffc097          	auipc	ra,0xffffc
    80004878:	cb6080e7          	jalr	-842(ra) # 8000052a <panic>
    return -1;
    8000487c:	597d                	li	s2,-1
    8000487e:	b765                	j	80004826 <fileread+0x60>
      return -1;
    80004880:	597d                	li	s2,-1
    80004882:	b755                	j	80004826 <fileread+0x60>
    80004884:	597d                	li	s2,-1
    80004886:	b745                	j	80004826 <fileread+0x60>

0000000080004888 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004888:	715d                	addi	sp,sp,-80
    8000488a:	e486                	sd	ra,72(sp)
    8000488c:	e0a2                	sd	s0,64(sp)
    8000488e:	fc26                	sd	s1,56(sp)
    80004890:	f84a                	sd	s2,48(sp)
    80004892:	f44e                	sd	s3,40(sp)
    80004894:	f052                	sd	s4,32(sp)
    80004896:	ec56                	sd	s5,24(sp)
    80004898:	e85a                	sd	s6,16(sp)
    8000489a:	e45e                	sd	s7,8(sp)
    8000489c:	e062                	sd	s8,0(sp)
    8000489e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800048a0:	00954783          	lbu	a5,9(a0)
    800048a4:	10078663          	beqz	a5,800049b0 <filewrite+0x128>
    800048a8:	892a                	mv	s2,a0
    800048aa:	8aae                	mv	s5,a1
    800048ac:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800048ae:	411c                	lw	a5,0(a0)
    800048b0:	4705                	li	a4,1
    800048b2:	02e78263          	beq	a5,a4,800048d6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048b6:	470d                	li	a4,3
    800048b8:	02e78663          	beq	a5,a4,800048e4 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800048bc:	4709                	li	a4,2
    800048be:	0ee79163          	bne	a5,a4,800049a0 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800048c2:	0ac05d63          	blez	a2,8000497c <filewrite+0xf4>
    int i = 0;
    800048c6:	4981                	li	s3,0
    800048c8:	6b05                	lui	s6,0x1
    800048ca:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800048ce:	6b85                	lui	s7,0x1
    800048d0:	c00b8b9b          	addiw	s7,s7,-1024
    800048d4:	a861                	j	8000496c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800048d6:	6908                	ld	a0,16(a0)
    800048d8:	00000097          	auipc	ra,0x0
    800048dc:	22e080e7          	jalr	558(ra) # 80004b06 <pipewrite>
    800048e0:	8a2a                	mv	s4,a0
    800048e2:	a045                	j	80004982 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048e4:	02451783          	lh	a5,36(a0)
    800048e8:	03079693          	slli	a3,a5,0x30
    800048ec:	92c1                	srli	a3,a3,0x30
    800048ee:	4725                	li	a4,9
    800048f0:	0cd76263          	bltu	a4,a3,800049b4 <filewrite+0x12c>
    800048f4:	0792                	slli	a5,a5,0x4
    800048f6:	0001d717          	auipc	a4,0x1d
    800048fa:	a2270713          	addi	a4,a4,-1502 # 80021318 <devsw>
    800048fe:	97ba                	add	a5,a5,a4
    80004900:	679c                	ld	a5,8(a5)
    80004902:	cbdd                	beqz	a5,800049b8 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004904:	4505                	li	a0,1
    80004906:	9782                	jalr	a5
    80004908:	8a2a                	mv	s4,a0
    8000490a:	a8a5                	j	80004982 <filewrite+0xfa>
    8000490c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004910:	00000097          	auipc	ra,0x0
    80004914:	8b0080e7          	jalr	-1872(ra) # 800041c0 <begin_op>
      ilock(f->ip);
    80004918:	01893503          	ld	a0,24(s2)
    8000491c:	fffff097          	auipc	ra,0xfffff
    80004920:	d9c080e7          	jalr	-612(ra) # 800036b8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004924:	8762                	mv	a4,s8
    80004926:	02092683          	lw	a3,32(s2)
    8000492a:	01598633          	add	a2,s3,s5
    8000492e:	4585                	li	a1,1
    80004930:	01893503          	ld	a0,24(s2)
    80004934:	fffff097          	auipc	ra,0xfffff
    80004938:	1e6080e7          	jalr	486(ra) # 80003b1a <writei>
    8000493c:	84aa                	mv	s1,a0
    8000493e:	00a05763          	blez	a0,8000494c <filewrite+0xc4>
        f->off += r;
    80004942:	02092783          	lw	a5,32(s2)
    80004946:	9fa9                	addw	a5,a5,a0
    80004948:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000494c:	01893503          	ld	a0,24(s2)
    80004950:	fffff097          	auipc	ra,0xfffff
    80004954:	e2a080e7          	jalr	-470(ra) # 8000377a <iunlock>
      end_op();
    80004958:	00000097          	auipc	ra,0x0
    8000495c:	8e8080e7          	jalr	-1816(ra) # 80004240 <end_op>

      if(r != n1){
    80004960:	009c1f63          	bne	s8,s1,8000497e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004964:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004968:	0149db63          	bge	s3,s4,8000497e <filewrite+0xf6>
      int n1 = n - i;
    8000496c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004970:	84be                	mv	s1,a5
    80004972:	2781                	sext.w	a5,a5
    80004974:	f8fb5ce3          	bge	s6,a5,8000490c <filewrite+0x84>
    80004978:	84de                	mv	s1,s7
    8000497a:	bf49                	j	8000490c <filewrite+0x84>
    int i = 0;
    8000497c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000497e:	013a1f63          	bne	s4,s3,8000499c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004982:	8552                	mv	a0,s4
    80004984:	60a6                	ld	ra,72(sp)
    80004986:	6406                	ld	s0,64(sp)
    80004988:	74e2                	ld	s1,56(sp)
    8000498a:	7942                	ld	s2,48(sp)
    8000498c:	79a2                	ld	s3,40(sp)
    8000498e:	7a02                	ld	s4,32(sp)
    80004990:	6ae2                	ld	s5,24(sp)
    80004992:	6b42                	ld	s6,16(sp)
    80004994:	6ba2                	ld	s7,8(sp)
    80004996:	6c02                	ld	s8,0(sp)
    80004998:	6161                	addi	sp,sp,80
    8000499a:	8082                	ret
    ret = (i == n ? n : -1);
    8000499c:	5a7d                	li	s4,-1
    8000499e:	b7d5                	j	80004982 <filewrite+0xfa>
    panic("filewrite");
    800049a0:	00004517          	auipc	a0,0x4
    800049a4:	d0050513          	addi	a0,a0,-768 # 800086a0 <syscalls+0x270>
    800049a8:	ffffc097          	auipc	ra,0xffffc
    800049ac:	b82080e7          	jalr	-1150(ra) # 8000052a <panic>
    return -1;
    800049b0:	5a7d                	li	s4,-1
    800049b2:	bfc1                	j	80004982 <filewrite+0xfa>
      return -1;
    800049b4:	5a7d                	li	s4,-1
    800049b6:	b7f1                	j	80004982 <filewrite+0xfa>
    800049b8:	5a7d                	li	s4,-1
    800049ba:	b7e1                	j	80004982 <filewrite+0xfa>

00000000800049bc <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800049bc:	7179                	addi	sp,sp,-48
    800049be:	f406                	sd	ra,40(sp)
    800049c0:	f022                	sd	s0,32(sp)
    800049c2:	ec26                	sd	s1,24(sp)
    800049c4:	e84a                	sd	s2,16(sp)
    800049c6:	e44e                	sd	s3,8(sp)
    800049c8:	e052                	sd	s4,0(sp)
    800049ca:	1800                	addi	s0,sp,48
    800049cc:	84aa                	mv	s1,a0
    800049ce:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049d0:	0005b023          	sd	zero,0(a1)
    800049d4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049d8:	00000097          	auipc	ra,0x0
    800049dc:	bf8080e7          	jalr	-1032(ra) # 800045d0 <filealloc>
    800049e0:	e088                	sd	a0,0(s1)
    800049e2:	c551                	beqz	a0,80004a6e <pipealloc+0xb2>
    800049e4:	00000097          	auipc	ra,0x0
    800049e8:	bec080e7          	jalr	-1044(ra) # 800045d0 <filealloc>
    800049ec:	00aa3023          	sd	a0,0(s4)
    800049f0:	c92d                	beqz	a0,80004a62 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049f2:	ffffc097          	auipc	ra,0xffffc
    800049f6:	0e0080e7          	jalr	224(ra) # 80000ad2 <kalloc>
    800049fa:	892a                	mv	s2,a0
    800049fc:	c125                	beqz	a0,80004a5c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049fe:	4985                	li	s3,1
    80004a00:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a04:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a08:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a0c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a10:	00004597          	auipc	a1,0x4
    80004a14:	ca058593          	addi	a1,a1,-864 # 800086b0 <syscalls+0x280>
    80004a18:	ffffc097          	auipc	ra,0xffffc
    80004a1c:	11a080e7          	jalr	282(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80004a20:	609c                	ld	a5,0(s1)
    80004a22:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a26:	609c                	ld	a5,0(s1)
    80004a28:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a2c:	609c                	ld	a5,0(s1)
    80004a2e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a32:	609c                	ld	a5,0(s1)
    80004a34:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a38:	000a3783          	ld	a5,0(s4)
    80004a3c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a40:	000a3783          	ld	a5,0(s4)
    80004a44:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a48:	000a3783          	ld	a5,0(s4)
    80004a4c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a50:	000a3783          	ld	a5,0(s4)
    80004a54:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a58:	4501                	li	a0,0
    80004a5a:	a025                	j	80004a82 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a5c:	6088                	ld	a0,0(s1)
    80004a5e:	e501                	bnez	a0,80004a66 <pipealloc+0xaa>
    80004a60:	a039                	j	80004a6e <pipealloc+0xb2>
    80004a62:	6088                	ld	a0,0(s1)
    80004a64:	c51d                	beqz	a0,80004a92 <pipealloc+0xd6>
    fileclose(*f0);
    80004a66:	00000097          	auipc	ra,0x0
    80004a6a:	c26080e7          	jalr	-986(ra) # 8000468c <fileclose>
  if(*f1)
    80004a6e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a72:	557d                	li	a0,-1
  if(*f1)
    80004a74:	c799                	beqz	a5,80004a82 <pipealloc+0xc6>
    fileclose(*f1);
    80004a76:	853e                	mv	a0,a5
    80004a78:	00000097          	auipc	ra,0x0
    80004a7c:	c14080e7          	jalr	-1004(ra) # 8000468c <fileclose>
  return -1;
    80004a80:	557d                	li	a0,-1
}
    80004a82:	70a2                	ld	ra,40(sp)
    80004a84:	7402                	ld	s0,32(sp)
    80004a86:	64e2                	ld	s1,24(sp)
    80004a88:	6942                	ld	s2,16(sp)
    80004a8a:	69a2                	ld	s3,8(sp)
    80004a8c:	6a02                	ld	s4,0(sp)
    80004a8e:	6145                	addi	sp,sp,48
    80004a90:	8082                	ret
  return -1;
    80004a92:	557d                	li	a0,-1
    80004a94:	b7fd                	j	80004a82 <pipealloc+0xc6>

0000000080004a96 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a96:	1101                	addi	sp,sp,-32
    80004a98:	ec06                	sd	ra,24(sp)
    80004a9a:	e822                	sd	s0,16(sp)
    80004a9c:	e426                	sd	s1,8(sp)
    80004a9e:	e04a                	sd	s2,0(sp)
    80004aa0:	1000                	addi	s0,sp,32
    80004aa2:	84aa                	mv	s1,a0
    80004aa4:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004aa6:	ffffc097          	auipc	ra,0xffffc
    80004aaa:	11c080e7          	jalr	284(ra) # 80000bc2 <acquire>
  if(writable){
    80004aae:	02090d63          	beqz	s2,80004ae8 <pipeclose+0x52>
    pi->writeopen = 0;
    80004ab2:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ab6:	21848513          	addi	a0,s1,536
    80004aba:	ffffd097          	auipc	ra,0xffffd
    80004abe:	752080e7          	jalr	1874(ra) # 8000220c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ac2:	2204b783          	ld	a5,544(s1)
    80004ac6:	eb95                	bnez	a5,80004afa <pipeclose+0x64>
    release(&pi->lock);
    80004ac8:	8526                	mv	a0,s1
    80004aca:	ffffc097          	auipc	ra,0xffffc
    80004ace:	1ac080e7          	jalr	428(ra) # 80000c76 <release>
    kfree((char*)pi);
    80004ad2:	8526                	mv	a0,s1
    80004ad4:	ffffc097          	auipc	ra,0xffffc
    80004ad8:	f02080e7          	jalr	-254(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80004adc:	60e2                	ld	ra,24(sp)
    80004ade:	6442                	ld	s0,16(sp)
    80004ae0:	64a2                	ld	s1,8(sp)
    80004ae2:	6902                	ld	s2,0(sp)
    80004ae4:	6105                	addi	sp,sp,32
    80004ae6:	8082                	ret
    pi->readopen = 0;
    80004ae8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004aec:	21c48513          	addi	a0,s1,540
    80004af0:	ffffd097          	auipc	ra,0xffffd
    80004af4:	71c080e7          	jalr	1820(ra) # 8000220c <wakeup>
    80004af8:	b7e9                	j	80004ac2 <pipeclose+0x2c>
    release(&pi->lock);
    80004afa:	8526                	mv	a0,s1
    80004afc:	ffffc097          	auipc	ra,0xffffc
    80004b00:	17a080e7          	jalr	378(ra) # 80000c76 <release>
}
    80004b04:	bfe1                	j	80004adc <pipeclose+0x46>

0000000080004b06 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b06:	711d                	addi	sp,sp,-96
    80004b08:	ec86                	sd	ra,88(sp)
    80004b0a:	e8a2                	sd	s0,80(sp)
    80004b0c:	e4a6                	sd	s1,72(sp)
    80004b0e:	e0ca                	sd	s2,64(sp)
    80004b10:	fc4e                	sd	s3,56(sp)
    80004b12:	f852                	sd	s4,48(sp)
    80004b14:	f456                	sd	s5,40(sp)
    80004b16:	f05a                	sd	s6,32(sp)
    80004b18:	ec5e                	sd	s7,24(sp)
    80004b1a:	e862                	sd	s8,16(sp)
    80004b1c:	1080                	addi	s0,sp,96
    80004b1e:	84aa                	mv	s1,a0
    80004b20:	8aae                	mv	s5,a1
    80004b22:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b24:	ffffd097          	auipc	ra,0xffffd
    80004b28:	e9c080e7          	jalr	-356(ra) # 800019c0 <myproc>
    80004b2c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b2e:	8526                	mv	a0,s1
    80004b30:	ffffc097          	auipc	ra,0xffffc
    80004b34:	092080e7          	jalr	146(ra) # 80000bc2 <acquire>
  while(i < n){
    80004b38:	0b405363          	blez	s4,80004bde <pipewrite+0xd8>
  int i = 0;
    80004b3c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b3e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b40:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b44:	21c48b93          	addi	s7,s1,540
    80004b48:	a089                	j	80004b8a <pipewrite+0x84>
      release(&pi->lock);
    80004b4a:	8526                	mv	a0,s1
    80004b4c:	ffffc097          	auipc	ra,0xffffc
    80004b50:	12a080e7          	jalr	298(ra) # 80000c76 <release>
      return -1;
    80004b54:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b56:	854a                	mv	a0,s2
    80004b58:	60e6                	ld	ra,88(sp)
    80004b5a:	6446                	ld	s0,80(sp)
    80004b5c:	64a6                	ld	s1,72(sp)
    80004b5e:	6906                	ld	s2,64(sp)
    80004b60:	79e2                	ld	s3,56(sp)
    80004b62:	7a42                	ld	s4,48(sp)
    80004b64:	7aa2                	ld	s5,40(sp)
    80004b66:	7b02                	ld	s6,32(sp)
    80004b68:	6be2                	ld	s7,24(sp)
    80004b6a:	6c42                	ld	s8,16(sp)
    80004b6c:	6125                	addi	sp,sp,96
    80004b6e:	8082                	ret
      wakeup(&pi->nread);
    80004b70:	8562                	mv	a0,s8
    80004b72:	ffffd097          	auipc	ra,0xffffd
    80004b76:	69a080e7          	jalr	1690(ra) # 8000220c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b7a:	85a6                	mv	a1,s1
    80004b7c:	855e                	mv	a0,s7
    80004b7e:	ffffd097          	auipc	ra,0xffffd
    80004b82:	502080e7          	jalr	1282(ra) # 80002080 <sleep>
  while(i < n){
    80004b86:	05495d63          	bge	s2,s4,80004be0 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004b8a:	2204a783          	lw	a5,544(s1)
    80004b8e:	dfd5                	beqz	a5,80004b4a <pipewrite+0x44>
    80004b90:	0289a783          	lw	a5,40(s3)
    80004b94:	fbdd                	bnez	a5,80004b4a <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b96:	2184a783          	lw	a5,536(s1)
    80004b9a:	21c4a703          	lw	a4,540(s1)
    80004b9e:	2007879b          	addiw	a5,a5,512
    80004ba2:	fcf707e3          	beq	a4,a5,80004b70 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ba6:	4685                	li	a3,1
    80004ba8:	01590633          	add	a2,s2,s5
    80004bac:	faf40593          	addi	a1,s0,-81
    80004bb0:	0509b503          	ld	a0,80(s3)
    80004bb4:	ffffd097          	auipc	ra,0xffffd
    80004bb8:	b58080e7          	jalr	-1192(ra) # 8000170c <copyin>
    80004bbc:	03650263          	beq	a0,s6,80004be0 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004bc0:	21c4a783          	lw	a5,540(s1)
    80004bc4:	0017871b          	addiw	a4,a5,1
    80004bc8:	20e4ae23          	sw	a4,540(s1)
    80004bcc:	1ff7f793          	andi	a5,a5,511
    80004bd0:	97a6                	add	a5,a5,s1
    80004bd2:	faf44703          	lbu	a4,-81(s0)
    80004bd6:	00e78c23          	sb	a4,24(a5)
      i++;
    80004bda:	2905                	addiw	s2,s2,1
    80004bdc:	b76d                	j	80004b86 <pipewrite+0x80>
  int i = 0;
    80004bde:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004be0:	21848513          	addi	a0,s1,536
    80004be4:	ffffd097          	auipc	ra,0xffffd
    80004be8:	628080e7          	jalr	1576(ra) # 8000220c <wakeup>
  release(&pi->lock);
    80004bec:	8526                	mv	a0,s1
    80004bee:	ffffc097          	auipc	ra,0xffffc
    80004bf2:	088080e7          	jalr	136(ra) # 80000c76 <release>
  return i;
    80004bf6:	b785                	j	80004b56 <pipewrite+0x50>

0000000080004bf8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bf8:	715d                	addi	sp,sp,-80
    80004bfa:	e486                	sd	ra,72(sp)
    80004bfc:	e0a2                	sd	s0,64(sp)
    80004bfe:	fc26                	sd	s1,56(sp)
    80004c00:	f84a                	sd	s2,48(sp)
    80004c02:	f44e                	sd	s3,40(sp)
    80004c04:	f052                	sd	s4,32(sp)
    80004c06:	ec56                	sd	s5,24(sp)
    80004c08:	e85a                	sd	s6,16(sp)
    80004c0a:	0880                	addi	s0,sp,80
    80004c0c:	84aa                	mv	s1,a0
    80004c0e:	892e                	mv	s2,a1
    80004c10:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c12:	ffffd097          	auipc	ra,0xffffd
    80004c16:	dae080e7          	jalr	-594(ra) # 800019c0 <myproc>
    80004c1a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c1c:	8526                	mv	a0,s1
    80004c1e:	ffffc097          	auipc	ra,0xffffc
    80004c22:	fa4080e7          	jalr	-92(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c26:	2184a703          	lw	a4,536(s1)
    80004c2a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c2e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c32:	02f71463          	bne	a4,a5,80004c5a <piperead+0x62>
    80004c36:	2244a783          	lw	a5,548(s1)
    80004c3a:	c385                	beqz	a5,80004c5a <piperead+0x62>
    if(pr->killed){
    80004c3c:	028a2783          	lw	a5,40(s4)
    80004c40:	ebc1                	bnez	a5,80004cd0 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c42:	85a6                	mv	a1,s1
    80004c44:	854e                	mv	a0,s3
    80004c46:	ffffd097          	auipc	ra,0xffffd
    80004c4a:	43a080e7          	jalr	1082(ra) # 80002080 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c4e:	2184a703          	lw	a4,536(s1)
    80004c52:	21c4a783          	lw	a5,540(s1)
    80004c56:	fef700e3          	beq	a4,a5,80004c36 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c5a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c5c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c5e:	05505363          	blez	s5,80004ca4 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004c62:	2184a783          	lw	a5,536(s1)
    80004c66:	21c4a703          	lw	a4,540(s1)
    80004c6a:	02f70d63          	beq	a4,a5,80004ca4 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c6e:	0017871b          	addiw	a4,a5,1
    80004c72:	20e4ac23          	sw	a4,536(s1)
    80004c76:	1ff7f793          	andi	a5,a5,511
    80004c7a:	97a6                	add	a5,a5,s1
    80004c7c:	0187c783          	lbu	a5,24(a5)
    80004c80:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c84:	4685                	li	a3,1
    80004c86:	fbf40613          	addi	a2,s0,-65
    80004c8a:	85ca                	mv	a1,s2
    80004c8c:	050a3503          	ld	a0,80(s4)
    80004c90:	ffffd097          	auipc	ra,0xffffd
    80004c94:	9f0080e7          	jalr	-1552(ra) # 80001680 <copyout>
    80004c98:	01650663          	beq	a0,s6,80004ca4 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c9c:	2985                	addiw	s3,s3,1
    80004c9e:	0905                	addi	s2,s2,1
    80004ca0:	fd3a91e3          	bne	s5,s3,80004c62 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004ca4:	21c48513          	addi	a0,s1,540
    80004ca8:	ffffd097          	auipc	ra,0xffffd
    80004cac:	564080e7          	jalr	1380(ra) # 8000220c <wakeup>
  release(&pi->lock);
    80004cb0:	8526                	mv	a0,s1
    80004cb2:	ffffc097          	auipc	ra,0xffffc
    80004cb6:	fc4080e7          	jalr	-60(ra) # 80000c76 <release>
  return i;
}
    80004cba:	854e                	mv	a0,s3
    80004cbc:	60a6                	ld	ra,72(sp)
    80004cbe:	6406                	ld	s0,64(sp)
    80004cc0:	74e2                	ld	s1,56(sp)
    80004cc2:	7942                	ld	s2,48(sp)
    80004cc4:	79a2                	ld	s3,40(sp)
    80004cc6:	7a02                	ld	s4,32(sp)
    80004cc8:	6ae2                	ld	s5,24(sp)
    80004cca:	6b42                	ld	s6,16(sp)
    80004ccc:	6161                	addi	sp,sp,80
    80004cce:	8082                	ret
      release(&pi->lock);
    80004cd0:	8526                	mv	a0,s1
    80004cd2:	ffffc097          	auipc	ra,0xffffc
    80004cd6:	fa4080e7          	jalr	-92(ra) # 80000c76 <release>
      return -1;
    80004cda:	59fd                	li	s3,-1
    80004cdc:	bff9                	j	80004cba <piperead+0xc2>

0000000080004cde <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004cde:	de010113          	addi	sp,sp,-544
    80004ce2:	20113c23          	sd	ra,536(sp)
    80004ce6:	20813823          	sd	s0,528(sp)
    80004cea:	20913423          	sd	s1,520(sp)
    80004cee:	21213023          	sd	s2,512(sp)
    80004cf2:	ffce                	sd	s3,504(sp)
    80004cf4:	fbd2                	sd	s4,496(sp)
    80004cf6:	f7d6                	sd	s5,488(sp)
    80004cf8:	f3da                	sd	s6,480(sp)
    80004cfa:	efde                	sd	s7,472(sp)
    80004cfc:	ebe2                	sd	s8,464(sp)
    80004cfe:	e7e6                	sd	s9,456(sp)
    80004d00:	e3ea                	sd	s10,448(sp)
    80004d02:	ff6e                	sd	s11,440(sp)
    80004d04:	1400                	addi	s0,sp,544
    80004d06:	892a                	mv	s2,a0
    80004d08:	dea43423          	sd	a0,-536(s0)
    80004d0c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d10:	ffffd097          	auipc	ra,0xffffd
    80004d14:	cb0080e7          	jalr	-848(ra) # 800019c0 <myproc>
    80004d18:	84aa                	mv	s1,a0

  begin_op();
    80004d1a:	fffff097          	auipc	ra,0xfffff
    80004d1e:	4a6080e7          	jalr	1190(ra) # 800041c0 <begin_op>

  if((ip = namei(path)) == 0){
    80004d22:	854a                	mv	a0,s2
    80004d24:	fffff097          	auipc	ra,0xfffff
    80004d28:	27c080e7          	jalr	636(ra) # 80003fa0 <namei>
    80004d2c:	c93d                	beqz	a0,80004da2 <exec+0xc4>
    80004d2e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d30:	fffff097          	auipc	ra,0xfffff
    80004d34:	988080e7          	jalr	-1656(ra) # 800036b8 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d38:	04000713          	li	a4,64
    80004d3c:	4681                	li	a3,0
    80004d3e:	e4840613          	addi	a2,s0,-440
    80004d42:	4581                	li	a1,0
    80004d44:	8556                	mv	a0,s5
    80004d46:	fffff097          	auipc	ra,0xfffff
    80004d4a:	cdc080e7          	jalr	-804(ra) # 80003a22 <readi>
    80004d4e:	04000793          	li	a5,64
    80004d52:	00f51a63          	bne	a0,a5,80004d66 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d56:	e4842703          	lw	a4,-440(s0)
    80004d5a:	464c47b7          	lui	a5,0x464c4
    80004d5e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d62:	04f70663          	beq	a4,a5,80004dae <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d66:	8556                	mv	a0,s5
    80004d68:	fffff097          	auipc	ra,0xfffff
    80004d6c:	c68080e7          	jalr	-920(ra) # 800039d0 <iunlockput>
    end_op();
    80004d70:	fffff097          	auipc	ra,0xfffff
    80004d74:	4d0080e7          	jalr	1232(ra) # 80004240 <end_op>
  }
  return -1;
    80004d78:	557d                	li	a0,-1
}
    80004d7a:	21813083          	ld	ra,536(sp)
    80004d7e:	21013403          	ld	s0,528(sp)
    80004d82:	20813483          	ld	s1,520(sp)
    80004d86:	20013903          	ld	s2,512(sp)
    80004d8a:	79fe                	ld	s3,504(sp)
    80004d8c:	7a5e                	ld	s4,496(sp)
    80004d8e:	7abe                	ld	s5,488(sp)
    80004d90:	7b1e                	ld	s6,480(sp)
    80004d92:	6bfe                	ld	s7,472(sp)
    80004d94:	6c5e                	ld	s8,464(sp)
    80004d96:	6cbe                	ld	s9,456(sp)
    80004d98:	6d1e                	ld	s10,448(sp)
    80004d9a:	7dfa                	ld	s11,440(sp)
    80004d9c:	22010113          	addi	sp,sp,544
    80004da0:	8082                	ret
    end_op();
    80004da2:	fffff097          	auipc	ra,0xfffff
    80004da6:	49e080e7          	jalr	1182(ra) # 80004240 <end_op>
    return -1;
    80004daa:	557d                	li	a0,-1
    80004dac:	b7f9                	j	80004d7a <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004dae:	8526                	mv	a0,s1
    80004db0:	ffffd097          	auipc	ra,0xffffd
    80004db4:	cd4080e7          	jalr	-812(ra) # 80001a84 <proc_pagetable>
    80004db8:	8b2a                	mv	s6,a0
    80004dba:	d555                	beqz	a0,80004d66 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dbc:	e6842783          	lw	a5,-408(s0)
    80004dc0:	e8045703          	lhu	a4,-384(s0)
    80004dc4:	c735                	beqz	a4,80004e30 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004dc6:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dc8:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004dcc:	6a05                	lui	s4,0x1
    80004dce:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004dd2:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004dd6:	6d85                	lui	s11,0x1
    80004dd8:	7d7d                	lui	s10,0xfffff
    80004dda:	ac1d                	j	80005010 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ddc:	00004517          	auipc	a0,0x4
    80004de0:	8dc50513          	addi	a0,a0,-1828 # 800086b8 <syscalls+0x288>
    80004de4:	ffffb097          	auipc	ra,0xffffb
    80004de8:	746080e7          	jalr	1862(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004dec:	874a                	mv	a4,s2
    80004dee:	009c86bb          	addw	a3,s9,s1
    80004df2:	4581                	li	a1,0
    80004df4:	8556                	mv	a0,s5
    80004df6:	fffff097          	auipc	ra,0xfffff
    80004dfa:	c2c080e7          	jalr	-980(ra) # 80003a22 <readi>
    80004dfe:	2501                	sext.w	a0,a0
    80004e00:	1aa91863          	bne	s2,a0,80004fb0 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004e04:	009d84bb          	addw	s1,s11,s1
    80004e08:	013d09bb          	addw	s3,s10,s3
    80004e0c:	1f74f263          	bgeu	s1,s7,80004ff0 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004e10:	02049593          	slli	a1,s1,0x20
    80004e14:	9181                	srli	a1,a1,0x20
    80004e16:	95e2                	add	a1,a1,s8
    80004e18:	855a                	mv	a0,s6
    80004e1a:	ffffc097          	auipc	ra,0xffffc
    80004e1e:	274080e7          	jalr	628(ra) # 8000108e <walkaddr>
    80004e22:	862a                	mv	a2,a0
    if(pa == 0)
    80004e24:	dd45                	beqz	a0,80004ddc <exec+0xfe>
      n = PGSIZE;
    80004e26:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004e28:	fd49f2e3          	bgeu	s3,s4,80004dec <exec+0x10e>
      n = sz - i;
    80004e2c:	894e                	mv	s2,s3
    80004e2e:	bf7d                	j	80004dec <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e30:	4481                	li	s1,0
  iunlockput(ip);
    80004e32:	8556                	mv	a0,s5
    80004e34:	fffff097          	auipc	ra,0xfffff
    80004e38:	b9c080e7          	jalr	-1124(ra) # 800039d0 <iunlockput>
  end_op();
    80004e3c:	fffff097          	auipc	ra,0xfffff
    80004e40:	404080e7          	jalr	1028(ra) # 80004240 <end_op>
  p = myproc();
    80004e44:	ffffd097          	auipc	ra,0xffffd
    80004e48:	b7c080e7          	jalr	-1156(ra) # 800019c0 <myproc>
    80004e4c:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004e4e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e52:	6785                	lui	a5,0x1
    80004e54:	17fd                	addi	a5,a5,-1
    80004e56:	94be                	add	s1,s1,a5
    80004e58:	77fd                	lui	a5,0xfffff
    80004e5a:	8fe5                	and	a5,a5,s1
    80004e5c:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e60:	6609                	lui	a2,0x2
    80004e62:	963e                	add	a2,a2,a5
    80004e64:	85be                	mv	a1,a5
    80004e66:	855a                	mv	a0,s6
    80004e68:	ffffc097          	auipc	ra,0xffffc
    80004e6c:	5c8080e7          	jalr	1480(ra) # 80001430 <uvmalloc>
    80004e70:	8c2a                	mv	s8,a0
  ip = 0;
    80004e72:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e74:	12050e63          	beqz	a0,80004fb0 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e78:	75f9                	lui	a1,0xffffe
    80004e7a:	95aa                	add	a1,a1,a0
    80004e7c:	855a                	mv	a0,s6
    80004e7e:	ffffc097          	auipc	ra,0xffffc
    80004e82:	7d0080e7          	jalr	2000(ra) # 8000164e <uvmclear>
  stackbase = sp - PGSIZE;
    80004e86:	7afd                	lui	s5,0xfffff
    80004e88:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e8a:	df043783          	ld	a5,-528(s0)
    80004e8e:	6388                	ld	a0,0(a5)
    80004e90:	c925                	beqz	a0,80004f00 <exec+0x222>
    80004e92:	e8840993          	addi	s3,s0,-376
    80004e96:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004e9a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e9c:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e9e:	ffffc097          	auipc	ra,0xffffc
    80004ea2:	fa4080e7          	jalr	-92(ra) # 80000e42 <strlen>
    80004ea6:	0015079b          	addiw	a5,a0,1
    80004eaa:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004eae:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004eb2:	13596363          	bltu	s2,s5,80004fd8 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004eb6:	df043d83          	ld	s11,-528(s0)
    80004eba:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004ebe:	8552                	mv	a0,s4
    80004ec0:	ffffc097          	auipc	ra,0xffffc
    80004ec4:	f82080e7          	jalr	-126(ra) # 80000e42 <strlen>
    80004ec8:	0015069b          	addiw	a3,a0,1
    80004ecc:	8652                	mv	a2,s4
    80004ece:	85ca                	mv	a1,s2
    80004ed0:	855a                	mv	a0,s6
    80004ed2:	ffffc097          	auipc	ra,0xffffc
    80004ed6:	7ae080e7          	jalr	1966(ra) # 80001680 <copyout>
    80004eda:	10054363          	bltz	a0,80004fe0 <exec+0x302>
    ustack[argc] = sp;
    80004ede:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ee2:	0485                	addi	s1,s1,1
    80004ee4:	008d8793          	addi	a5,s11,8
    80004ee8:	def43823          	sd	a5,-528(s0)
    80004eec:	008db503          	ld	a0,8(s11)
    80004ef0:	c911                	beqz	a0,80004f04 <exec+0x226>
    if(argc >= MAXARG)
    80004ef2:	09a1                	addi	s3,s3,8
    80004ef4:	fb3c95e3          	bne	s9,s3,80004e9e <exec+0x1c0>
  sz = sz1;
    80004ef8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004efc:	4a81                	li	s5,0
    80004efe:	a84d                	j	80004fb0 <exec+0x2d2>
  sp = sz;
    80004f00:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f02:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f04:	00349793          	slli	a5,s1,0x3
    80004f08:	f9040713          	addi	a4,s0,-112
    80004f0c:	97ba                	add	a5,a5,a4
    80004f0e:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80004f12:	00148693          	addi	a3,s1,1
    80004f16:	068e                	slli	a3,a3,0x3
    80004f18:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f1c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f20:	01597663          	bgeu	s2,s5,80004f2c <exec+0x24e>
  sz = sz1;
    80004f24:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f28:	4a81                	li	s5,0
    80004f2a:	a059                	j	80004fb0 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f2c:	e8840613          	addi	a2,s0,-376
    80004f30:	85ca                	mv	a1,s2
    80004f32:	855a                	mv	a0,s6
    80004f34:	ffffc097          	auipc	ra,0xffffc
    80004f38:	74c080e7          	jalr	1868(ra) # 80001680 <copyout>
    80004f3c:	0a054663          	bltz	a0,80004fe8 <exec+0x30a>
  p->trapframe->a1 = sp;
    80004f40:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004f44:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f48:	de843783          	ld	a5,-536(s0)
    80004f4c:	0007c703          	lbu	a4,0(a5)
    80004f50:	cf11                	beqz	a4,80004f6c <exec+0x28e>
    80004f52:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f54:	02f00693          	li	a3,47
    80004f58:	a039                	j	80004f66 <exec+0x288>
      last = s+1;
    80004f5a:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004f5e:	0785                	addi	a5,a5,1
    80004f60:	fff7c703          	lbu	a4,-1(a5)
    80004f64:	c701                	beqz	a4,80004f6c <exec+0x28e>
    if(*s == '/')
    80004f66:	fed71ce3          	bne	a4,a3,80004f5e <exec+0x280>
    80004f6a:	bfc5                	j	80004f5a <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f6c:	4641                	li	a2,16
    80004f6e:	de843583          	ld	a1,-536(s0)
    80004f72:	158b8513          	addi	a0,s7,344
    80004f76:	ffffc097          	auipc	ra,0xffffc
    80004f7a:	e9a080e7          	jalr	-358(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f7e:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004f82:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004f86:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f8a:	058bb783          	ld	a5,88(s7)
    80004f8e:	e6043703          	ld	a4,-416(s0)
    80004f92:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f94:	058bb783          	ld	a5,88(s7)
    80004f98:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f9c:	85ea                	mv	a1,s10
    80004f9e:	ffffd097          	auipc	ra,0xffffd
    80004fa2:	b82080e7          	jalr	-1150(ra) # 80001b20 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004fa6:	0004851b          	sext.w	a0,s1
    80004faa:	bbc1                	j	80004d7a <exec+0x9c>
    80004fac:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004fb0:	df843583          	ld	a1,-520(s0)
    80004fb4:	855a                	mv	a0,s6
    80004fb6:	ffffd097          	auipc	ra,0xffffd
    80004fba:	b6a080e7          	jalr	-1174(ra) # 80001b20 <proc_freepagetable>
  if(ip){
    80004fbe:	da0a94e3          	bnez	s5,80004d66 <exec+0x88>
  return -1;
    80004fc2:	557d                	li	a0,-1
    80004fc4:	bb5d                	j	80004d7a <exec+0x9c>
    80004fc6:	de943c23          	sd	s1,-520(s0)
    80004fca:	b7dd                	j	80004fb0 <exec+0x2d2>
    80004fcc:	de943c23          	sd	s1,-520(s0)
    80004fd0:	b7c5                	j	80004fb0 <exec+0x2d2>
    80004fd2:	de943c23          	sd	s1,-520(s0)
    80004fd6:	bfe9                	j	80004fb0 <exec+0x2d2>
  sz = sz1;
    80004fd8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fdc:	4a81                	li	s5,0
    80004fde:	bfc9                	j	80004fb0 <exec+0x2d2>
  sz = sz1;
    80004fe0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fe4:	4a81                	li	s5,0
    80004fe6:	b7e9                	j	80004fb0 <exec+0x2d2>
  sz = sz1;
    80004fe8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fec:	4a81                	li	s5,0
    80004fee:	b7c9                	j	80004fb0 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004ff0:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ff4:	e0843783          	ld	a5,-504(s0)
    80004ff8:	0017869b          	addiw	a3,a5,1
    80004ffc:	e0d43423          	sd	a3,-504(s0)
    80005000:	e0043783          	ld	a5,-512(s0)
    80005004:	0387879b          	addiw	a5,a5,56
    80005008:	e8045703          	lhu	a4,-384(s0)
    8000500c:	e2e6d3e3          	bge	a3,a4,80004e32 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005010:	2781                	sext.w	a5,a5
    80005012:	e0f43023          	sd	a5,-512(s0)
    80005016:	03800713          	li	a4,56
    8000501a:	86be                	mv	a3,a5
    8000501c:	e1040613          	addi	a2,s0,-496
    80005020:	4581                	li	a1,0
    80005022:	8556                	mv	a0,s5
    80005024:	fffff097          	auipc	ra,0xfffff
    80005028:	9fe080e7          	jalr	-1538(ra) # 80003a22 <readi>
    8000502c:	03800793          	li	a5,56
    80005030:	f6f51ee3          	bne	a0,a5,80004fac <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80005034:	e1042783          	lw	a5,-496(s0)
    80005038:	4705                	li	a4,1
    8000503a:	fae79de3          	bne	a5,a4,80004ff4 <exec+0x316>
    if(ph.memsz < ph.filesz)
    8000503e:	e3843603          	ld	a2,-456(s0)
    80005042:	e3043783          	ld	a5,-464(s0)
    80005046:	f8f660e3          	bltu	a2,a5,80004fc6 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000504a:	e2043783          	ld	a5,-480(s0)
    8000504e:	963e                	add	a2,a2,a5
    80005050:	f6f66ee3          	bltu	a2,a5,80004fcc <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005054:	85a6                	mv	a1,s1
    80005056:	855a                	mv	a0,s6
    80005058:	ffffc097          	auipc	ra,0xffffc
    8000505c:	3d8080e7          	jalr	984(ra) # 80001430 <uvmalloc>
    80005060:	dea43c23          	sd	a0,-520(s0)
    80005064:	d53d                	beqz	a0,80004fd2 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80005066:	e2043c03          	ld	s8,-480(s0)
    8000506a:	de043783          	ld	a5,-544(s0)
    8000506e:	00fc77b3          	and	a5,s8,a5
    80005072:	ff9d                	bnez	a5,80004fb0 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005074:	e1842c83          	lw	s9,-488(s0)
    80005078:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000507c:	f60b8ae3          	beqz	s7,80004ff0 <exec+0x312>
    80005080:	89de                	mv	s3,s7
    80005082:	4481                	li	s1,0
    80005084:	b371                	j	80004e10 <exec+0x132>

0000000080005086 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005086:	7179                	addi	sp,sp,-48
    80005088:	f406                	sd	ra,40(sp)
    8000508a:	f022                	sd	s0,32(sp)
    8000508c:	ec26                	sd	s1,24(sp)
    8000508e:	e84a                	sd	s2,16(sp)
    80005090:	1800                	addi	s0,sp,48
    80005092:	892e                	mv	s2,a1
    80005094:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005096:	fdc40593          	addi	a1,s0,-36
    8000509a:	ffffe097          	auipc	ra,0xffffe
    8000509e:	9d6080e7          	jalr	-1578(ra) # 80002a70 <argint>
    800050a2:	04054063          	bltz	a0,800050e2 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050a6:	fdc42703          	lw	a4,-36(s0)
    800050aa:	47bd                	li	a5,15
    800050ac:	02e7ed63          	bltu	a5,a4,800050e6 <argfd+0x60>
    800050b0:	ffffd097          	auipc	ra,0xffffd
    800050b4:	910080e7          	jalr	-1776(ra) # 800019c0 <myproc>
    800050b8:	fdc42703          	lw	a4,-36(s0)
    800050bc:	01a70793          	addi	a5,a4,26
    800050c0:	078e                	slli	a5,a5,0x3
    800050c2:	953e                	add	a0,a0,a5
    800050c4:	611c                	ld	a5,0(a0)
    800050c6:	c395                	beqz	a5,800050ea <argfd+0x64>
    return -1;
  if(pfd)
    800050c8:	00090463          	beqz	s2,800050d0 <argfd+0x4a>
    *pfd = fd;
    800050cc:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050d0:	4501                	li	a0,0
  if(pf)
    800050d2:	c091                	beqz	s1,800050d6 <argfd+0x50>
    *pf = f;
    800050d4:	e09c                	sd	a5,0(s1)
}
    800050d6:	70a2                	ld	ra,40(sp)
    800050d8:	7402                	ld	s0,32(sp)
    800050da:	64e2                	ld	s1,24(sp)
    800050dc:	6942                	ld	s2,16(sp)
    800050de:	6145                	addi	sp,sp,48
    800050e0:	8082                	ret
    return -1;
    800050e2:	557d                	li	a0,-1
    800050e4:	bfcd                	j	800050d6 <argfd+0x50>
    return -1;
    800050e6:	557d                	li	a0,-1
    800050e8:	b7fd                	j	800050d6 <argfd+0x50>
    800050ea:	557d                	li	a0,-1
    800050ec:	b7ed                	j	800050d6 <argfd+0x50>

00000000800050ee <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050ee:	1101                	addi	sp,sp,-32
    800050f0:	ec06                	sd	ra,24(sp)
    800050f2:	e822                	sd	s0,16(sp)
    800050f4:	e426                	sd	s1,8(sp)
    800050f6:	1000                	addi	s0,sp,32
    800050f8:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050fa:	ffffd097          	auipc	ra,0xffffd
    800050fe:	8c6080e7          	jalr	-1850(ra) # 800019c0 <myproc>
    80005102:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005104:	0d050793          	addi	a5,a0,208
    80005108:	4501                	li	a0,0
    8000510a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000510c:	6398                	ld	a4,0(a5)
    8000510e:	cb19                	beqz	a4,80005124 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005110:	2505                	addiw	a0,a0,1
    80005112:	07a1                	addi	a5,a5,8
    80005114:	fed51ce3          	bne	a0,a3,8000510c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005118:	557d                	li	a0,-1
}
    8000511a:	60e2                	ld	ra,24(sp)
    8000511c:	6442                	ld	s0,16(sp)
    8000511e:	64a2                	ld	s1,8(sp)
    80005120:	6105                	addi	sp,sp,32
    80005122:	8082                	ret
      p->ofile[fd] = f;
    80005124:	01a50793          	addi	a5,a0,26
    80005128:	078e                	slli	a5,a5,0x3
    8000512a:	963e                	add	a2,a2,a5
    8000512c:	e204                	sd	s1,0(a2)
      return fd;
    8000512e:	b7f5                	j	8000511a <fdalloc+0x2c>

0000000080005130 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005130:	715d                	addi	sp,sp,-80
    80005132:	e486                	sd	ra,72(sp)
    80005134:	e0a2                	sd	s0,64(sp)
    80005136:	fc26                	sd	s1,56(sp)
    80005138:	f84a                	sd	s2,48(sp)
    8000513a:	f44e                	sd	s3,40(sp)
    8000513c:	f052                	sd	s4,32(sp)
    8000513e:	ec56                	sd	s5,24(sp)
    80005140:	0880                	addi	s0,sp,80
    80005142:	89ae                	mv	s3,a1
    80005144:	8ab2                	mv	s5,a2
    80005146:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005148:	fb040593          	addi	a1,s0,-80
    8000514c:	fffff097          	auipc	ra,0xfffff
    80005150:	e74080e7          	jalr	-396(ra) # 80003fc0 <nameiparent>
    80005154:	892a                	mv	s2,a0
    80005156:	12050e63          	beqz	a0,80005292 <create+0x162>
    return 0;

  ilock(dp);
    8000515a:	ffffe097          	auipc	ra,0xffffe
    8000515e:	55e080e7          	jalr	1374(ra) # 800036b8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005162:	4601                	li	a2,0
    80005164:	fb040593          	addi	a1,s0,-80
    80005168:	854a                	mv	a0,s2
    8000516a:	fffff097          	auipc	ra,0xfffff
    8000516e:	aea080e7          	jalr	-1302(ra) # 80003c54 <dirlookup>
    80005172:	84aa                	mv	s1,a0
    80005174:	c921                	beqz	a0,800051c4 <create+0x94>
    iunlockput(dp);
    80005176:	854a                	mv	a0,s2
    80005178:	fffff097          	auipc	ra,0xfffff
    8000517c:	858080e7          	jalr	-1960(ra) # 800039d0 <iunlockput>
    ilock(ip);
    80005180:	8526                	mv	a0,s1
    80005182:	ffffe097          	auipc	ra,0xffffe
    80005186:	536080e7          	jalr	1334(ra) # 800036b8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000518a:	2981                	sext.w	s3,s3
    8000518c:	4789                	li	a5,2
    8000518e:	02f99463          	bne	s3,a5,800051b6 <create+0x86>
    80005192:	0444d783          	lhu	a5,68(s1)
    80005196:	37f9                	addiw	a5,a5,-2
    80005198:	17c2                	slli	a5,a5,0x30
    8000519a:	93c1                	srli	a5,a5,0x30
    8000519c:	4705                	li	a4,1
    8000519e:	00f76c63          	bltu	a4,a5,800051b6 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800051a2:	8526                	mv	a0,s1
    800051a4:	60a6                	ld	ra,72(sp)
    800051a6:	6406                	ld	s0,64(sp)
    800051a8:	74e2                	ld	s1,56(sp)
    800051aa:	7942                	ld	s2,48(sp)
    800051ac:	79a2                	ld	s3,40(sp)
    800051ae:	7a02                	ld	s4,32(sp)
    800051b0:	6ae2                	ld	s5,24(sp)
    800051b2:	6161                	addi	sp,sp,80
    800051b4:	8082                	ret
    iunlockput(ip);
    800051b6:	8526                	mv	a0,s1
    800051b8:	fffff097          	auipc	ra,0xfffff
    800051bc:	818080e7          	jalr	-2024(ra) # 800039d0 <iunlockput>
    return 0;
    800051c0:	4481                	li	s1,0
    800051c2:	b7c5                	j	800051a2 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800051c4:	85ce                	mv	a1,s3
    800051c6:	00092503          	lw	a0,0(s2)
    800051ca:	ffffe097          	auipc	ra,0xffffe
    800051ce:	356080e7          	jalr	854(ra) # 80003520 <ialloc>
    800051d2:	84aa                	mv	s1,a0
    800051d4:	c521                	beqz	a0,8000521c <create+0xec>
  ilock(ip);
    800051d6:	ffffe097          	auipc	ra,0xffffe
    800051da:	4e2080e7          	jalr	1250(ra) # 800036b8 <ilock>
  ip->major = major;
    800051de:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800051e2:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800051e6:	4a05                	li	s4,1
    800051e8:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800051ec:	8526                	mv	a0,s1
    800051ee:	ffffe097          	auipc	ra,0xffffe
    800051f2:	400080e7          	jalr	1024(ra) # 800035ee <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051f6:	2981                	sext.w	s3,s3
    800051f8:	03498a63          	beq	s3,s4,8000522c <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800051fc:	40d0                	lw	a2,4(s1)
    800051fe:	fb040593          	addi	a1,s0,-80
    80005202:	854a                	mv	a0,s2
    80005204:	fffff097          	auipc	ra,0xfffff
    80005208:	cda080e7          	jalr	-806(ra) # 80003ede <dirlink>
    8000520c:	06054b63          	bltz	a0,80005282 <create+0x152>
  iunlockput(dp);
    80005210:	854a                	mv	a0,s2
    80005212:	ffffe097          	auipc	ra,0xffffe
    80005216:	7be080e7          	jalr	1982(ra) # 800039d0 <iunlockput>
  return ip;
    8000521a:	b761                	j	800051a2 <create+0x72>
    panic("create: ialloc");
    8000521c:	00003517          	auipc	a0,0x3
    80005220:	4bc50513          	addi	a0,a0,1212 # 800086d8 <syscalls+0x2a8>
    80005224:	ffffb097          	auipc	ra,0xffffb
    80005228:	306080e7          	jalr	774(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    8000522c:	04a95783          	lhu	a5,74(s2)
    80005230:	2785                	addiw	a5,a5,1
    80005232:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005236:	854a                	mv	a0,s2
    80005238:	ffffe097          	auipc	ra,0xffffe
    8000523c:	3b6080e7          	jalr	950(ra) # 800035ee <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005240:	40d0                	lw	a2,4(s1)
    80005242:	00003597          	auipc	a1,0x3
    80005246:	4a658593          	addi	a1,a1,1190 # 800086e8 <syscalls+0x2b8>
    8000524a:	8526                	mv	a0,s1
    8000524c:	fffff097          	auipc	ra,0xfffff
    80005250:	c92080e7          	jalr	-878(ra) # 80003ede <dirlink>
    80005254:	00054f63          	bltz	a0,80005272 <create+0x142>
    80005258:	00492603          	lw	a2,4(s2)
    8000525c:	00003597          	auipc	a1,0x3
    80005260:	49458593          	addi	a1,a1,1172 # 800086f0 <syscalls+0x2c0>
    80005264:	8526                	mv	a0,s1
    80005266:	fffff097          	auipc	ra,0xfffff
    8000526a:	c78080e7          	jalr	-904(ra) # 80003ede <dirlink>
    8000526e:	f80557e3          	bgez	a0,800051fc <create+0xcc>
      panic("create dots");
    80005272:	00003517          	auipc	a0,0x3
    80005276:	48650513          	addi	a0,a0,1158 # 800086f8 <syscalls+0x2c8>
    8000527a:	ffffb097          	auipc	ra,0xffffb
    8000527e:	2b0080e7          	jalr	688(ra) # 8000052a <panic>
    panic("create: dirlink");
    80005282:	00003517          	auipc	a0,0x3
    80005286:	48650513          	addi	a0,a0,1158 # 80008708 <syscalls+0x2d8>
    8000528a:	ffffb097          	auipc	ra,0xffffb
    8000528e:	2a0080e7          	jalr	672(ra) # 8000052a <panic>
    return 0;
    80005292:	84aa                	mv	s1,a0
    80005294:	b739                	j	800051a2 <create+0x72>

0000000080005296 <sys_dup>:
{
    80005296:	7179                	addi	sp,sp,-48
    80005298:	f406                	sd	ra,40(sp)
    8000529a:	f022                	sd	s0,32(sp)
    8000529c:	ec26                	sd	s1,24(sp)
    8000529e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052a0:	fd840613          	addi	a2,s0,-40
    800052a4:	4581                	li	a1,0
    800052a6:	4501                	li	a0,0
    800052a8:	00000097          	auipc	ra,0x0
    800052ac:	dde080e7          	jalr	-546(ra) # 80005086 <argfd>
    return -1;
    800052b0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052b2:	02054363          	bltz	a0,800052d8 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052b6:	fd843503          	ld	a0,-40(s0)
    800052ba:	00000097          	auipc	ra,0x0
    800052be:	e34080e7          	jalr	-460(ra) # 800050ee <fdalloc>
    800052c2:	84aa                	mv	s1,a0
    return -1;
    800052c4:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052c6:	00054963          	bltz	a0,800052d8 <sys_dup+0x42>
  filedup(f);
    800052ca:	fd843503          	ld	a0,-40(s0)
    800052ce:	fffff097          	auipc	ra,0xfffff
    800052d2:	36c080e7          	jalr	876(ra) # 8000463a <filedup>
  return fd;
    800052d6:	87a6                	mv	a5,s1
}
    800052d8:	853e                	mv	a0,a5
    800052da:	70a2                	ld	ra,40(sp)
    800052dc:	7402                	ld	s0,32(sp)
    800052de:	64e2                	ld	s1,24(sp)
    800052e0:	6145                	addi	sp,sp,48
    800052e2:	8082                	ret

00000000800052e4 <sys_read>:
{
    800052e4:	7179                	addi	sp,sp,-48
    800052e6:	f406                	sd	ra,40(sp)
    800052e8:	f022                	sd	s0,32(sp)
    800052ea:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052ec:	fe840613          	addi	a2,s0,-24
    800052f0:	4581                	li	a1,0
    800052f2:	4501                	li	a0,0
    800052f4:	00000097          	auipc	ra,0x0
    800052f8:	d92080e7          	jalr	-622(ra) # 80005086 <argfd>
    return -1;
    800052fc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052fe:	04054163          	bltz	a0,80005340 <sys_read+0x5c>
    80005302:	fe440593          	addi	a1,s0,-28
    80005306:	4509                	li	a0,2
    80005308:	ffffd097          	auipc	ra,0xffffd
    8000530c:	768080e7          	jalr	1896(ra) # 80002a70 <argint>
    return -1;
    80005310:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005312:	02054763          	bltz	a0,80005340 <sys_read+0x5c>
    80005316:	fd840593          	addi	a1,s0,-40
    8000531a:	4505                	li	a0,1
    8000531c:	ffffd097          	auipc	ra,0xffffd
    80005320:	776080e7          	jalr	1910(ra) # 80002a92 <argaddr>
    return -1;
    80005324:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005326:	00054d63          	bltz	a0,80005340 <sys_read+0x5c>
  return fileread(f, p, n);
    8000532a:	fe442603          	lw	a2,-28(s0)
    8000532e:	fd843583          	ld	a1,-40(s0)
    80005332:	fe843503          	ld	a0,-24(s0)
    80005336:	fffff097          	auipc	ra,0xfffff
    8000533a:	490080e7          	jalr	1168(ra) # 800047c6 <fileread>
    8000533e:	87aa                	mv	a5,a0
}
    80005340:	853e                	mv	a0,a5
    80005342:	70a2                	ld	ra,40(sp)
    80005344:	7402                	ld	s0,32(sp)
    80005346:	6145                	addi	sp,sp,48
    80005348:	8082                	ret

000000008000534a <sys_write>:
{
    8000534a:	7179                	addi	sp,sp,-48
    8000534c:	f406                	sd	ra,40(sp)
    8000534e:	f022                	sd	s0,32(sp)
    80005350:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005352:	fe840613          	addi	a2,s0,-24
    80005356:	4581                	li	a1,0
    80005358:	4501                	li	a0,0
    8000535a:	00000097          	auipc	ra,0x0
    8000535e:	d2c080e7          	jalr	-724(ra) # 80005086 <argfd>
    return -1;
    80005362:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005364:	04054163          	bltz	a0,800053a6 <sys_write+0x5c>
    80005368:	fe440593          	addi	a1,s0,-28
    8000536c:	4509                	li	a0,2
    8000536e:	ffffd097          	auipc	ra,0xffffd
    80005372:	702080e7          	jalr	1794(ra) # 80002a70 <argint>
    return -1;
    80005376:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005378:	02054763          	bltz	a0,800053a6 <sys_write+0x5c>
    8000537c:	fd840593          	addi	a1,s0,-40
    80005380:	4505                	li	a0,1
    80005382:	ffffd097          	auipc	ra,0xffffd
    80005386:	710080e7          	jalr	1808(ra) # 80002a92 <argaddr>
    return -1;
    8000538a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000538c:	00054d63          	bltz	a0,800053a6 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005390:	fe442603          	lw	a2,-28(s0)
    80005394:	fd843583          	ld	a1,-40(s0)
    80005398:	fe843503          	ld	a0,-24(s0)
    8000539c:	fffff097          	auipc	ra,0xfffff
    800053a0:	4ec080e7          	jalr	1260(ra) # 80004888 <filewrite>
    800053a4:	87aa                	mv	a5,a0
}
    800053a6:	853e                	mv	a0,a5
    800053a8:	70a2                	ld	ra,40(sp)
    800053aa:	7402                	ld	s0,32(sp)
    800053ac:	6145                	addi	sp,sp,48
    800053ae:	8082                	ret

00000000800053b0 <sys_close>:
{
    800053b0:	1101                	addi	sp,sp,-32
    800053b2:	ec06                	sd	ra,24(sp)
    800053b4:	e822                	sd	s0,16(sp)
    800053b6:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053b8:	fe040613          	addi	a2,s0,-32
    800053bc:	fec40593          	addi	a1,s0,-20
    800053c0:	4501                	li	a0,0
    800053c2:	00000097          	auipc	ra,0x0
    800053c6:	cc4080e7          	jalr	-828(ra) # 80005086 <argfd>
    return -1;
    800053ca:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053cc:	02054463          	bltz	a0,800053f4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053d0:	ffffc097          	auipc	ra,0xffffc
    800053d4:	5f0080e7          	jalr	1520(ra) # 800019c0 <myproc>
    800053d8:	fec42783          	lw	a5,-20(s0)
    800053dc:	07e9                	addi	a5,a5,26
    800053de:	078e                	slli	a5,a5,0x3
    800053e0:	97aa                	add	a5,a5,a0
    800053e2:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053e6:	fe043503          	ld	a0,-32(s0)
    800053ea:	fffff097          	auipc	ra,0xfffff
    800053ee:	2a2080e7          	jalr	674(ra) # 8000468c <fileclose>
  return 0;
    800053f2:	4781                	li	a5,0
}
    800053f4:	853e                	mv	a0,a5
    800053f6:	60e2                	ld	ra,24(sp)
    800053f8:	6442                	ld	s0,16(sp)
    800053fa:	6105                	addi	sp,sp,32
    800053fc:	8082                	ret

00000000800053fe <sys_fstat>:
{
    800053fe:	1101                	addi	sp,sp,-32
    80005400:	ec06                	sd	ra,24(sp)
    80005402:	e822                	sd	s0,16(sp)
    80005404:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005406:	fe840613          	addi	a2,s0,-24
    8000540a:	4581                	li	a1,0
    8000540c:	4501                	li	a0,0
    8000540e:	00000097          	auipc	ra,0x0
    80005412:	c78080e7          	jalr	-904(ra) # 80005086 <argfd>
    return -1;
    80005416:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005418:	02054563          	bltz	a0,80005442 <sys_fstat+0x44>
    8000541c:	fe040593          	addi	a1,s0,-32
    80005420:	4505                	li	a0,1
    80005422:	ffffd097          	auipc	ra,0xffffd
    80005426:	670080e7          	jalr	1648(ra) # 80002a92 <argaddr>
    return -1;
    8000542a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000542c:	00054b63          	bltz	a0,80005442 <sys_fstat+0x44>
  return filestat(f, st);
    80005430:	fe043583          	ld	a1,-32(s0)
    80005434:	fe843503          	ld	a0,-24(s0)
    80005438:	fffff097          	auipc	ra,0xfffff
    8000543c:	31c080e7          	jalr	796(ra) # 80004754 <filestat>
    80005440:	87aa                	mv	a5,a0
}
    80005442:	853e                	mv	a0,a5
    80005444:	60e2                	ld	ra,24(sp)
    80005446:	6442                	ld	s0,16(sp)
    80005448:	6105                	addi	sp,sp,32
    8000544a:	8082                	ret

000000008000544c <sys_link>:
{
    8000544c:	7169                	addi	sp,sp,-304
    8000544e:	f606                	sd	ra,296(sp)
    80005450:	f222                	sd	s0,288(sp)
    80005452:	ee26                	sd	s1,280(sp)
    80005454:	ea4a                	sd	s2,272(sp)
    80005456:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005458:	08000613          	li	a2,128
    8000545c:	ed040593          	addi	a1,s0,-304
    80005460:	4501                	li	a0,0
    80005462:	ffffd097          	auipc	ra,0xffffd
    80005466:	652080e7          	jalr	1618(ra) # 80002ab4 <argstr>
    return -1;
    8000546a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000546c:	10054e63          	bltz	a0,80005588 <sys_link+0x13c>
    80005470:	08000613          	li	a2,128
    80005474:	f5040593          	addi	a1,s0,-176
    80005478:	4505                	li	a0,1
    8000547a:	ffffd097          	auipc	ra,0xffffd
    8000547e:	63a080e7          	jalr	1594(ra) # 80002ab4 <argstr>
    return -1;
    80005482:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005484:	10054263          	bltz	a0,80005588 <sys_link+0x13c>
  begin_op();
    80005488:	fffff097          	auipc	ra,0xfffff
    8000548c:	d38080e7          	jalr	-712(ra) # 800041c0 <begin_op>
  if((ip = namei(old)) == 0){
    80005490:	ed040513          	addi	a0,s0,-304
    80005494:	fffff097          	auipc	ra,0xfffff
    80005498:	b0c080e7          	jalr	-1268(ra) # 80003fa0 <namei>
    8000549c:	84aa                	mv	s1,a0
    8000549e:	c551                	beqz	a0,8000552a <sys_link+0xde>
  ilock(ip);
    800054a0:	ffffe097          	auipc	ra,0xffffe
    800054a4:	218080e7          	jalr	536(ra) # 800036b8 <ilock>
  if(ip->type == T_DIR){
    800054a8:	04449703          	lh	a4,68(s1)
    800054ac:	4785                	li	a5,1
    800054ae:	08f70463          	beq	a4,a5,80005536 <sys_link+0xea>
  ip->nlink++;
    800054b2:	04a4d783          	lhu	a5,74(s1)
    800054b6:	2785                	addiw	a5,a5,1
    800054b8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054bc:	8526                	mv	a0,s1
    800054be:	ffffe097          	auipc	ra,0xffffe
    800054c2:	130080e7          	jalr	304(ra) # 800035ee <iupdate>
  iunlock(ip);
    800054c6:	8526                	mv	a0,s1
    800054c8:	ffffe097          	auipc	ra,0xffffe
    800054cc:	2b2080e7          	jalr	690(ra) # 8000377a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054d0:	fd040593          	addi	a1,s0,-48
    800054d4:	f5040513          	addi	a0,s0,-176
    800054d8:	fffff097          	auipc	ra,0xfffff
    800054dc:	ae8080e7          	jalr	-1304(ra) # 80003fc0 <nameiparent>
    800054e0:	892a                	mv	s2,a0
    800054e2:	c935                	beqz	a0,80005556 <sys_link+0x10a>
  ilock(dp);
    800054e4:	ffffe097          	auipc	ra,0xffffe
    800054e8:	1d4080e7          	jalr	468(ra) # 800036b8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054ec:	00092703          	lw	a4,0(s2)
    800054f0:	409c                	lw	a5,0(s1)
    800054f2:	04f71d63          	bne	a4,a5,8000554c <sys_link+0x100>
    800054f6:	40d0                	lw	a2,4(s1)
    800054f8:	fd040593          	addi	a1,s0,-48
    800054fc:	854a                	mv	a0,s2
    800054fe:	fffff097          	auipc	ra,0xfffff
    80005502:	9e0080e7          	jalr	-1568(ra) # 80003ede <dirlink>
    80005506:	04054363          	bltz	a0,8000554c <sys_link+0x100>
  iunlockput(dp);
    8000550a:	854a                	mv	a0,s2
    8000550c:	ffffe097          	auipc	ra,0xffffe
    80005510:	4c4080e7          	jalr	1220(ra) # 800039d0 <iunlockput>
  iput(ip);
    80005514:	8526                	mv	a0,s1
    80005516:	ffffe097          	auipc	ra,0xffffe
    8000551a:	412080e7          	jalr	1042(ra) # 80003928 <iput>
  end_op();
    8000551e:	fffff097          	auipc	ra,0xfffff
    80005522:	d22080e7          	jalr	-734(ra) # 80004240 <end_op>
  return 0;
    80005526:	4781                	li	a5,0
    80005528:	a085                	j	80005588 <sys_link+0x13c>
    end_op();
    8000552a:	fffff097          	auipc	ra,0xfffff
    8000552e:	d16080e7          	jalr	-746(ra) # 80004240 <end_op>
    return -1;
    80005532:	57fd                	li	a5,-1
    80005534:	a891                	j	80005588 <sys_link+0x13c>
    iunlockput(ip);
    80005536:	8526                	mv	a0,s1
    80005538:	ffffe097          	auipc	ra,0xffffe
    8000553c:	498080e7          	jalr	1176(ra) # 800039d0 <iunlockput>
    end_op();
    80005540:	fffff097          	auipc	ra,0xfffff
    80005544:	d00080e7          	jalr	-768(ra) # 80004240 <end_op>
    return -1;
    80005548:	57fd                	li	a5,-1
    8000554a:	a83d                	j	80005588 <sys_link+0x13c>
    iunlockput(dp);
    8000554c:	854a                	mv	a0,s2
    8000554e:	ffffe097          	auipc	ra,0xffffe
    80005552:	482080e7          	jalr	1154(ra) # 800039d0 <iunlockput>
  ilock(ip);
    80005556:	8526                	mv	a0,s1
    80005558:	ffffe097          	auipc	ra,0xffffe
    8000555c:	160080e7          	jalr	352(ra) # 800036b8 <ilock>
  ip->nlink--;
    80005560:	04a4d783          	lhu	a5,74(s1)
    80005564:	37fd                	addiw	a5,a5,-1
    80005566:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000556a:	8526                	mv	a0,s1
    8000556c:	ffffe097          	auipc	ra,0xffffe
    80005570:	082080e7          	jalr	130(ra) # 800035ee <iupdate>
  iunlockput(ip);
    80005574:	8526                	mv	a0,s1
    80005576:	ffffe097          	auipc	ra,0xffffe
    8000557a:	45a080e7          	jalr	1114(ra) # 800039d0 <iunlockput>
  end_op();
    8000557e:	fffff097          	auipc	ra,0xfffff
    80005582:	cc2080e7          	jalr	-830(ra) # 80004240 <end_op>
  return -1;
    80005586:	57fd                	li	a5,-1
}
    80005588:	853e                	mv	a0,a5
    8000558a:	70b2                	ld	ra,296(sp)
    8000558c:	7412                	ld	s0,288(sp)
    8000558e:	64f2                	ld	s1,280(sp)
    80005590:	6952                	ld	s2,272(sp)
    80005592:	6155                	addi	sp,sp,304
    80005594:	8082                	ret

0000000080005596 <sys_unlink>:
{
    80005596:	7151                	addi	sp,sp,-240
    80005598:	f586                	sd	ra,232(sp)
    8000559a:	f1a2                	sd	s0,224(sp)
    8000559c:	eda6                	sd	s1,216(sp)
    8000559e:	e9ca                	sd	s2,208(sp)
    800055a0:	e5ce                	sd	s3,200(sp)
    800055a2:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055a4:	08000613          	li	a2,128
    800055a8:	f3040593          	addi	a1,s0,-208
    800055ac:	4501                	li	a0,0
    800055ae:	ffffd097          	auipc	ra,0xffffd
    800055b2:	506080e7          	jalr	1286(ra) # 80002ab4 <argstr>
    800055b6:	18054163          	bltz	a0,80005738 <sys_unlink+0x1a2>
  begin_op();
    800055ba:	fffff097          	auipc	ra,0xfffff
    800055be:	c06080e7          	jalr	-1018(ra) # 800041c0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055c2:	fb040593          	addi	a1,s0,-80
    800055c6:	f3040513          	addi	a0,s0,-208
    800055ca:	fffff097          	auipc	ra,0xfffff
    800055ce:	9f6080e7          	jalr	-1546(ra) # 80003fc0 <nameiparent>
    800055d2:	84aa                	mv	s1,a0
    800055d4:	c979                	beqz	a0,800056aa <sys_unlink+0x114>
  ilock(dp);
    800055d6:	ffffe097          	auipc	ra,0xffffe
    800055da:	0e2080e7          	jalr	226(ra) # 800036b8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055de:	00003597          	auipc	a1,0x3
    800055e2:	10a58593          	addi	a1,a1,266 # 800086e8 <syscalls+0x2b8>
    800055e6:	fb040513          	addi	a0,s0,-80
    800055ea:	ffffe097          	auipc	ra,0xffffe
    800055ee:	650080e7          	jalr	1616(ra) # 80003c3a <namecmp>
    800055f2:	14050a63          	beqz	a0,80005746 <sys_unlink+0x1b0>
    800055f6:	00003597          	auipc	a1,0x3
    800055fa:	0fa58593          	addi	a1,a1,250 # 800086f0 <syscalls+0x2c0>
    800055fe:	fb040513          	addi	a0,s0,-80
    80005602:	ffffe097          	auipc	ra,0xffffe
    80005606:	638080e7          	jalr	1592(ra) # 80003c3a <namecmp>
    8000560a:	12050e63          	beqz	a0,80005746 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000560e:	f2c40613          	addi	a2,s0,-212
    80005612:	fb040593          	addi	a1,s0,-80
    80005616:	8526                	mv	a0,s1
    80005618:	ffffe097          	auipc	ra,0xffffe
    8000561c:	63c080e7          	jalr	1596(ra) # 80003c54 <dirlookup>
    80005620:	892a                	mv	s2,a0
    80005622:	12050263          	beqz	a0,80005746 <sys_unlink+0x1b0>
  ilock(ip);
    80005626:	ffffe097          	auipc	ra,0xffffe
    8000562a:	092080e7          	jalr	146(ra) # 800036b8 <ilock>
  if(ip->nlink < 1)
    8000562e:	04a91783          	lh	a5,74(s2)
    80005632:	08f05263          	blez	a5,800056b6 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005636:	04491703          	lh	a4,68(s2)
    8000563a:	4785                	li	a5,1
    8000563c:	08f70563          	beq	a4,a5,800056c6 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005640:	4641                	li	a2,16
    80005642:	4581                	li	a1,0
    80005644:	fc040513          	addi	a0,s0,-64
    80005648:	ffffb097          	auipc	ra,0xffffb
    8000564c:	676080e7          	jalr	1654(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005650:	4741                	li	a4,16
    80005652:	f2c42683          	lw	a3,-212(s0)
    80005656:	fc040613          	addi	a2,s0,-64
    8000565a:	4581                	li	a1,0
    8000565c:	8526                	mv	a0,s1
    8000565e:	ffffe097          	auipc	ra,0xffffe
    80005662:	4bc080e7          	jalr	1212(ra) # 80003b1a <writei>
    80005666:	47c1                	li	a5,16
    80005668:	0af51563          	bne	a0,a5,80005712 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000566c:	04491703          	lh	a4,68(s2)
    80005670:	4785                	li	a5,1
    80005672:	0af70863          	beq	a4,a5,80005722 <sys_unlink+0x18c>
  iunlockput(dp);
    80005676:	8526                	mv	a0,s1
    80005678:	ffffe097          	auipc	ra,0xffffe
    8000567c:	358080e7          	jalr	856(ra) # 800039d0 <iunlockput>
  ip->nlink--;
    80005680:	04a95783          	lhu	a5,74(s2)
    80005684:	37fd                	addiw	a5,a5,-1
    80005686:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000568a:	854a                	mv	a0,s2
    8000568c:	ffffe097          	auipc	ra,0xffffe
    80005690:	f62080e7          	jalr	-158(ra) # 800035ee <iupdate>
  iunlockput(ip);
    80005694:	854a                	mv	a0,s2
    80005696:	ffffe097          	auipc	ra,0xffffe
    8000569a:	33a080e7          	jalr	826(ra) # 800039d0 <iunlockput>
  end_op();
    8000569e:	fffff097          	auipc	ra,0xfffff
    800056a2:	ba2080e7          	jalr	-1118(ra) # 80004240 <end_op>
  return 0;
    800056a6:	4501                	li	a0,0
    800056a8:	a84d                	j	8000575a <sys_unlink+0x1c4>
    end_op();
    800056aa:	fffff097          	auipc	ra,0xfffff
    800056ae:	b96080e7          	jalr	-1130(ra) # 80004240 <end_op>
    return -1;
    800056b2:	557d                	li	a0,-1
    800056b4:	a05d                	j	8000575a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056b6:	00003517          	auipc	a0,0x3
    800056ba:	06250513          	addi	a0,a0,98 # 80008718 <syscalls+0x2e8>
    800056be:	ffffb097          	auipc	ra,0xffffb
    800056c2:	e6c080e7          	jalr	-404(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056c6:	04c92703          	lw	a4,76(s2)
    800056ca:	02000793          	li	a5,32
    800056ce:	f6e7f9e3          	bgeu	a5,a4,80005640 <sys_unlink+0xaa>
    800056d2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056d6:	4741                	li	a4,16
    800056d8:	86ce                	mv	a3,s3
    800056da:	f1840613          	addi	a2,s0,-232
    800056de:	4581                	li	a1,0
    800056e0:	854a                	mv	a0,s2
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	340080e7          	jalr	832(ra) # 80003a22 <readi>
    800056ea:	47c1                	li	a5,16
    800056ec:	00f51b63          	bne	a0,a5,80005702 <sys_unlink+0x16c>
    if(de.inum != 0)
    800056f0:	f1845783          	lhu	a5,-232(s0)
    800056f4:	e7a1                	bnez	a5,8000573c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056f6:	29c1                	addiw	s3,s3,16
    800056f8:	04c92783          	lw	a5,76(s2)
    800056fc:	fcf9ede3          	bltu	s3,a5,800056d6 <sys_unlink+0x140>
    80005700:	b781                	j	80005640 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005702:	00003517          	auipc	a0,0x3
    80005706:	02e50513          	addi	a0,a0,46 # 80008730 <syscalls+0x300>
    8000570a:	ffffb097          	auipc	ra,0xffffb
    8000570e:	e20080e7          	jalr	-480(ra) # 8000052a <panic>
    panic("unlink: writei");
    80005712:	00003517          	auipc	a0,0x3
    80005716:	03650513          	addi	a0,a0,54 # 80008748 <syscalls+0x318>
    8000571a:	ffffb097          	auipc	ra,0xffffb
    8000571e:	e10080e7          	jalr	-496(ra) # 8000052a <panic>
    dp->nlink--;
    80005722:	04a4d783          	lhu	a5,74(s1)
    80005726:	37fd                	addiw	a5,a5,-1
    80005728:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000572c:	8526                	mv	a0,s1
    8000572e:	ffffe097          	auipc	ra,0xffffe
    80005732:	ec0080e7          	jalr	-320(ra) # 800035ee <iupdate>
    80005736:	b781                	j	80005676 <sys_unlink+0xe0>
    return -1;
    80005738:	557d                	li	a0,-1
    8000573a:	a005                	j	8000575a <sys_unlink+0x1c4>
    iunlockput(ip);
    8000573c:	854a                	mv	a0,s2
    8000573e:	ffffe097          	auipc	ra,0xffffe
    80005742:	292080e7          	jalr	658(ra) # 800039d0 <iunlockput>
  iunlockput(dp);
    80005746:	8526                	mv	a0,s1
    80005748:	ffffe097          	auipc	ra,0xffffe
    8000574c:	288080e7          	jalr	648(ra) # 800039d0 <iunlockput>
  end_op();
    80005750:	fffff097          	auipc	ra,0xfffff
    80005754:	af0080e7          	jalr	-1296(ra) # 80004240 <end_op>
  return -1;
    80005758:	557d                	li	a0,-1
}
    8000575a:	70ae                	ld	ra,232(sp)
    8000575c:	740e                	ld	s0,224(sp)
    8000575e:	64ee                	ld	s1,216(sp)
    80005760:	694e                	ld	s2,208(sp)
    80005762:	69ae                	ld	s3,200(sp)
    80005764:	616d                	addi	sp,sp,240
    80005766:	8082                	ret

0000000080005768 <sys_open>:

uint64
sys_open(void)
{
    80005768:	7155                	addi	sp,sp,-208
    8000576a:	e586                	sd	ra,200(sp)
    8000576c:	e1a2                	sd	s0,192(sp)
    8000576e:	fd26                	sd	s1,184(sp)
    80005770:	f94a                	sd	s2,176(sp)
    80005772:	f54e                	sd	s3,168(sp)
    80005774:	f152                	sd	s4,160(sp)
    80005776:	ed56                	sd	s5,152(sp)
    80005778:	0980                	addi	s0,sp,208
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000577a:	08000613          	li	a2,128
    8000577e:	f4040593          	addi	a1,s0,-192
    80005782:	4501                	li	a0,0
    80005784:	ffffd097          	auipc	ra,0xffffd
    80005788:	330080e7          	jalr	816(ra) # 80002ab4 <argstr>
    return -1;
    8000578c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000578e:	12054c63          	bltz	a0,800058c6 <sys_open+0x15e>
    80005792:	f3c40593          	addi	a1,s0,-196
    80005796:	4505                	li	a0,1
    80005798:	ffffd097          	auipc	ra,0xffffd
    8000579c:	2d8080e7          	jalr	728(ra) # 80002a70 <argint>
    800057a0:	12054363          	bltz	a0,800058c6 <sys_open+0x15e>

  begin_op();
    800057a4:	fffff097          	auipc	ra,0xfffff
    800057a8:	a1c080e7          	jalr	-1508(ra) # 800041c0 <begin_op>

  if(omode & O_CREATE){
    800057ac:	f3c42983          	lw	s3,-196(s0)
    800057b0:	2009f793          	andi	a5,s3,512
    800057b4:	efa5                	bnez	a5,8000582c <sys_open+0xc4>
      return -1;
    }
  } else {
    //mp4
    // check if it is symbolic link
    if((omode & O_NOFOLLOW) == 0) {
    800057b6:	0049f993          	andi	s3,s3,4
    800057ba:	14099363          	bnez	s3,80005900 <sys_open+0x198>
          end_op();
          return -1;
        }
        ilock(ip);

        if(ip->type == T_SYMLINK) {
    800057be:	4a11                	li	s4,4
      while (depth < 11) {
    800057c0:	4aad                	li	s5,11
        if((ip = namei(path)) == 0){
    800057c2:	f4040513          	addi	a0,s0,-192
    800057c6:	ffffe097          	auipc	ra,0xffffe
    800057ca:	7da080e7          	jalr	2010(ra) # 80003fa0 <namei>
    800057ce:	84aa                	mv	s1,a0
    800057d0:	10050a63          	beqz	a0,800058e4 <sys_open+0x17c>
        ilock(ip);
    800057d4:	ffffe097          	auipc	ra,0xffffe
    800057d8:	ee4080e7          	jalr	-284(ra) # 800036b8 <ilock>
        if(ip->type == T_SYMLINK) {
    800057dc:	04449783          	lh	a5,68(s1)
    800057e0:	11479863          	bne	a5,s4,800058f0 <sys_open+0x188>
          struct buf *b = bread(ip->dev, ip->addrs[0]);
    800057e4:	48ac                	lw	a1,80(s1)
    800057e6:	4088                	lw	a0,0(s1)
    800057e8:	ffffd097          	auipc	ra,0xffffd
    800057ec:	5f6080e7          	jalr	1526(ra) # 80002dde <bread>
    800057f0:	892a                	mv	s2,a0
          memmove(path, b->data, MAXPATH);
    800057f2:	08000613          	li	a2,128
    800057f6:	05850593          	addi	a1,a0,88
    800057fa:	f4040513          	addi	a0,s0,-192
    800057fe:	ffffb097          	auipc	ra,0xffffb
    80005802:	51c080e7          	jalr	1308(ra) # 80000d1a <memmove>
          brelse(b);
    80005806:	854a                	mv	a0,s2
    80005808:	ffffd097          	auipc	ra,0xffffd
    8000580c:	706080e7          	jalr	1798(ra) # 80002f0e <brelse>
        else {
          iunlockput(ip);
          break;
        }

        iunlockput(ip);
    80005810:	8526                	mv	a0,s1
    80005812:	ffffe097          	auipc	ra,0xffffe
    80005816:	1be080e7          	jalr	446(ra) # 800039d0 <iunlockput>
        depth++;
    8000581a:	2985                	addiw	s3,s3,1
      while (depth < 11) {
    8000581c:	fb5993e3          	bne	s3,s5,800057c2 <sys_open+0x5a>
      }

      if(depth >= 10){
        end_op();
    80005820:	fffff097          	auipc	ra,0xfffff
    80005824:	a20080e7          	jalr	-1504(ra) # 80004240 <end_op>
        return -1;
    80005828:	54fd                	li	s1,-1
    8000582a:	a871                	j	800058c6 <sys_open+0x15e>
    ip = create(path, T_FILE, 0, 0);
    8000582c:	4681                	li	a3,0
    8000582e:	4601                	li	a2,0
    80005830:	4589                	li	a1,2
    80005832:	f4040513          	addi	a0,s0,-192
    80005836:	00000097          	auipc	ra,0x0
    8000583a:	8fa080e7          	jalr	-1798(ra) # 80005130 <create>
    8000583e:	892a                	mv	s2,a0
    if(ip == 0){
    80005840:	cd49                	beqz	a0,800058da <sys_open+0x172>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005842:	04491703          	lh	a4,68(s2)
    80005846:	478d                	li	a5,3
    80005848:	00f71763          	bne	a4,a5,80005856 <sys_open+0xee>
    8000584c:	04695703          	lhu	a4,70(s2)
    80005850:	47a5                	li	a5,9
    80005852:	0ee7ec63          	bltu	a5,a4,8000594a <sys_open+0x1e2>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005856:	fffff097          	auipc	ra,0xfffff
    8000585a:	d7a080e7          	jalr	-646(ra) # 800045d0 <filealloc>
    8000585e:	89aa                	mv	s3,a0
    80005860:	12050263          	beqz	a0,80005984 <sys_open+0x21c>
    80005864:	00000097          	auipc	ra,0x0
    80005868:	88a080e7          	jalr	-1910(ra) # 800050ee <fdalloc>
    8000586c:	84aa                	mv	s1,a0
    8000586e:	10054663          	bltz	a0,8000597a <sys_open+0x212>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005872:	04491703          	lh	a4,68(s2)
    80005876:	478d                	li	a5,3
    80005878:	0ef70463          	beq	a4,a5,80005960 <sys_open+0x1f8>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000587c:	4789                	li	a5,2
    8000587e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005882:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005886:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000588a:	f3c42783          	lw	a5,-196(s0)
    8000588e:	0017c713          	xori	a4,a5,1
    80005892:	8b05                	andi	a4,a4,1
    80005894:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005898:	0037f713          	andi	a4,a5,3
    8000589c:	00e03733          	snez	a4,a4
    800058a0:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800058a4:	4007f793          	andi	a5,a5,1024
    800058a8:	c791                	beqz	a5,800058b4 <sys_open+0x14c>
    800058aa:	04491703          	lh	a4,68(s2)
    800058ae:	4789                	li	a5,2
    800058b0:	0af70f63          	beq	a4,a5,8000596e <sys_open+0x206>
    itrunc(ip);
  }

  iunlock(ip);
    800058b4:	854a                	mv	a0,s2
    800058b6:	ffffe097          	auipc	ra,0xffffe
    800058ba:	ec4080e7          	jalr	-316(ra) # 8000377a <iunlock>
  end_op();
    800058be:	fffff097          	auipc	ra,0xfffff
    800058c2:	982080e7          	jalr	-1662(ra) # 80004240 <end_op>

  return fd;
}
    800058c6:	8526                	mv	a0,s1
    800058c8:	60ae                	ld	ra,200(sp)
    800058ca:	640e                	ld	s0,192(sp)
    800058cc:	74ea                	ld	s1,184(sp)
    800058ce:	794a                	ld	s2,176(sp)
    800058d0:	79aa                	ld	s3,168(sp)
    800058d2:	7a0a                	ld	s4,160(sp)
    800058d4:	6aea                	ld	s5,152(sp)
    800058d6:	6169                	addi	sp,sp,208
    800058d8:	8082                	ret
      end_op();
    800058da:	fffff097          	auipc	ra,0xfffff
    800058de:	966080e7          	jalr	-1690(ra) # 80004240 <end_op>
      return -1;
    800058e2:	b7d5                	j	800058c6 <sys_open+0x15e>
          end_op();
    800058e4:	fffff097          	auipc	ra,0xfffff
    800058e8:	95c080e7          	jalr	-1700(ra) # 80004240 <end_op>
          return -1;
    800058ec:	54fd                	li	s1,-1
    800058ee:	bfe1                	j	800058c6 <sys_open+0x15e>
          iunlockput(ip);
    800058f0:	8526                	mv	a0,s1
    800058f2:	ffffe097          	auipc	ra,0xffffe
    800058f6:	0de080e7          	jalr	222(ra) # 800039d0 <iunlockput>
      if(depth >= 10){
    800058fa:	47a5                	li	a5,9
    800058fc:	f337c2e3          	blt	a5,s3,80005820 <sys_open+0xb8>
    if((ip = namei(path)) == 0){
    80005900:	f4040513          	addi	a0,s0,-192
    80005904:	ffffe097          	auipc	ra,0xffffe
    80005908:	69c080e7          	jalr	1692(ra) # 80003fa0 <namei>
    8000590c:	892a                	mv	s2,a0
    8000590e:	c905                	beqz	a0,8000593e <sys_open+0x1d6>
    ilock(ip);
    80005910:	ffffe097          	auipc	ra,0xffffe
    80005914:	da8080e7          	jalr	-600(ra) # 800036b8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005918:	04491703          	lh	a4,68(s2)
    8000591c:	4785                	li	a5,1
    8000591e:	f2f712e3          	bne	a4,a5,80005842 <sys_open+0xda>
    80005922:	f3c42783          	lw	a5,-196(s0)
    80005926:	db85                	beqz	a5,80005856 <sys_open+0xee>
      iunlockput(ip);
    80005928:	854a                	mv	a0,s2
    8000592a:	ffffe097          	auipc	ra,0xffffe
    8000592e:	0a6080e7          	jalr	166(ra) # 800039d0 <iunlockput>
      end_op();
    80005932:	fffff097          	auipc	ra,0xfffff
    80005936:	90e080e7          	jalr	-1778(ra) # 80004240 <end_op>
      return -1;
    8000593a:	54fd                	li	s1,-1
    8000593c:	b769                	j	800058c6 <sys_open+0x15e>
      end_op();
    8000593e:	fffff097          	auipc	ra,0xfffff
    80005942:	902080e7          	jalr	-1790(ra) # 80004240 <end_op>
      return -1;
    80005946:	54fd                	li	s1,-1
    80005948:	bfbd                	j	800058c6 <sys_open+0x15e>
    iunlockput(ip);
    8000594a:	854a                	mv	a0,s2
    8000594c:	ffffe097          	auipc	ra,0xffffe
    80005950:	084080e7          	jalr	132(ra) # 800039d0 <iunlockput>
    end_op();
    80005954:	fffff097          	auipc	ra,0xfffff
    80005958:	8ec080e7          	jalr	-1812(ra) # 80004240 <end_op>
    return -1;
    8000595c:	54fd                	li	s1,-1
    8000595e:	b7a5                	j	800058c6 <sys_open+0x15e>
    f->type = FD_DEVICE;
    80005960:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005964:	04691783          	lh	a5,70(s2)
    80005968:	02f99223          	sh	a5,36(s3)
    8000596c:	bf29                	j	80005886 <sys_open+0x11e>
    itrunc(ip);
    8000596e:	854a                	mv	a0,s2
    80005970:	ffffe097          	auipc	ra,0xffffe
    80005974:	e56080e7          	jalr	-426(ra) # 800037c6 <itrunc>
    80005978:	bf35                	j	800058b4 <sys_open+0x14c>
      fileclose(f);
    8000597a:	854e                	mv	a0,s3
    8000597c:	fffff097          	auipc	ra,0xfffff
    80005980:	d10080e7          	jalr	-752(ra) # 8000468c <fileclose>
    iunlockput(ip);
    80005984:	854a                	mv	a0,s2
    80005986:	ffffe097          	auipc	ra,0xffffe
    8000598a:	04a080e7          	jalr	74(ra) # 800039d0 <iunlockput>
    end_op();
    8000598e:	fffff097          	auipc	ra,0xfffff
    80005992:	8b2080e7          	jalr	-1870(ra) # 80004240 <end_op>
    return -1;
    80005996:	54fd                	li	s1,-1
    80005998:	b73d                	j	800058c6 <sys_open+0x15e>

000000008000599a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000599a:	7175                	addi	sp,sp,-144
    8000599c:	e506                	sd	ra,136(sp)
    8000599e:	e122                	sd	s0,128(sp)
    800059a0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059a2:	fffff097          	auipc	ra,0xfffff
    800059a6:	81e080e7          	jalr	-2018(ra) # 800041c0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800059aa:	08000613          	li	a2,128
    800059ae:	f7040593          	addi	a1,s0,-144
    800059b2:	4501                	li	a0,0
    800059b4:	ffffd097          	auipc	ra,0xffffd
    800059b8:	100080e7          	jalr	256(ra) # 80002ab4 <argstr>
    800059bc:	02054963          	bltz	a0,800059ee <sys_mkdir+0x54>
    800059c0:	4681                	li	a3,0
    800059c2:	4601                	li	a2,0
    800059c4:	4585                	li	a1,1
    800059c6:	f7040513          	addi	a0,s0,-144
    800059ca:	fffff097          	auipc	ra,0xfffff
    800059ce:	766080e7          	jalr	1894(ra) # 80005130 <create>
    800059d2:	cd11                	beqz	a0,800059ee <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059d4:	ffffe097          	auipc	ra,0xffffe
    800059d8:	ffc080e7          	jalr	-4(ra) # 800039d0 <iunlockput>
  end_op();
    800059dc:	fffff097          	auipc	ra,0xfffff
    800059e0:	864080e7          	jalr	-1948(ra) # 80004240 <end_op>
  return 0;
    800059e4:	4501                	li	a0,0
}
    800059e6:	60aa                	ld	ra,136(sp)
    800059e8:	640a                	ld	s0,128(sp)
    800059ea:	6149                	addi	sp,sp,144
    800059ec:	8082                	ret
    end_op();
    800059ee:	fffff097          	auipc	ra,0xfffff
    800059f2:	852080e7          	jalr	-1966(ra) # 80004240 <end_op>
    return -1;
    800059f6:	557d                	li	a0,-1
    800059f8:	b7fd                	j	800059e6 <sys_mkdir+0x4c>

00000000800059fa <sys_mknod>:

uint64
sys_mknod(void)
{
    800059fa:	7135                	addi	sp,sp,-160
    800059fc:	ed06                	sd	ra,152(sp)
    800059fe:	e922                	sd	s0,144(sp)
    80005a00:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a02:	ffffe097          	auipc	ra,0xffffe
    80005a06:	7be080e7          	jalr	1982(ra) # 800041c0 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a0a:	08000613          	li	a2,128
    80005a0e:	f7040593          	addi	a1,s0,-144
    80005a12:	4501                	li	a0,0
    80005a14:	ffffd097          	auipc	ra,0xffffd
    80005a18:	0a0080e7          	jalr	160(ra) # 80002ab4 <argstr>
    80005a1c:	04054a63          	bltz	a0,80005a70 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a20:	f6c40593          	addi	a1,s0,-148
    80005a24:	4505                	li	a0,1
    80005a26:	ffffd097          	auipc	ra,0xffffd
    80005a2a:	04a080e7          	jalr	74(ra) # 80002a70 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a2e:	04054163          	bltz	a0,80005a70 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a32:	f6840593          	addi	a1,s0,-152
    80005a36:	4509                	li	a0,2
    80005a38:	ffffd097          	auipc	ra,0xffffd
    80005a3c:	038080e7          	jalr	56(ra) # 80002a70 <argint>
     argint(1, &major) < 0 ||
    80005a40:	02054863          	bltz	a0,80005a70 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a44:	f6841683          	lh	a3,-152(s0)
    80005a48:	f6c41603          	lh	a2,-148(s0)
    80005a4c:	458d                	li	a1,3
    80005a4e:	f7040513          	addi	a0,s0,-144
    80005a52:	fffff097          	auipc	ra,0xfffff
    80005a56:	6de080e7          	jalr	1758(ra) # 80005130 <create>
     argint(2, &minor) < 0 ||
    80005a5a:	c919                	beqz	a0,80005a70 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a5c:	ffffe097          	auipc	ra,0xffffe
    80005a60:	f74080e7          	jalr	-140(ra) # 800039d0 <iunlockput>
  end_op();
    80005a64:	ffffe097          	auipc	ra,0xffffe
    80005a68:	7dc080e7          	jalr	2012(ra) # 80004240 <end_op>
  return 0;
    80005a6c:	4501                	li	a0,0
    80005a6e:	a031                	j	80005a7a <sys_mknod+0x80>
    end_op();
    80005a70:	ffffe097          	auipc	ra,0xffffe
    80005a74:	7d0080e7          	jalr	2000(ra) # 80004240 <end_op>
    return -1;
    80005a78:	557d                	li	a0,-1
}
    80005a7a:	60ea                	ld	ra,152(sp)
    80005a7c:	644a                	ld	s0,144(sp)
    80005a7e:	610d                	addi	sp,sp,160
    80005a80:	8082                	ret

0000000080005a82 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a82:	7135                	addi	sp,sp,-160
    80005a84:	ed06                	sd	ra,152(sp)
    80005a86:	e922                	sd	s0,144(sp)
    80005a88:	e526                	sd	s1,136(sp)
    80005a8a:	e14a                	sd	s2,128(sp)
    80005a8c:	1100                	addi	s0,sp,160
  // You can modify this to cd into a symbolic link
  // The modification may not be necessary,
  // depending on you implementation.
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a8e:	ffffc097          	auipc	ra,0xffffc
    80005a92:	f32080e7          	jalr	-206(ra) # 800019c0 <myproc>
    80005a96:	892a                	mv	s2,a0
  
  begin_op();
    80005a98:	ffffe097          	auipc	ra,0xffffe
    80005a9c:	728080e7          	jalr	1832(ra) # 800041c0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005aa0:	08000613          	li	a2,128
    80005aa4:	f6040593          	addi	a1,s0,-160
    80005aa8:	4501                	li	a0,0
    80005aaa:	ffffd097          	auipc	ra,0xffffd
    80005aae:	00a080e7          	jalr	10(ra) # 80002ab4 <argstr>
    80005ab2:	04054b63          	bltz	a0,80005b08 <sys_chdir+0x86>
    80005ab6:	f6040513          	addi	a0,s0,-160
    80005aba:	ffffe097          	auipc	ra,0xffffe
    80005abe:	4e6080e7          	jalr	1254(ra) # 80003fa0 <namei>
    80005ac2:	84aa                	mv	s1,a0
    80005ac4:	c131                	beqz	a0,80005b08 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ac6:	ffffe097          	auipc	ra,0xffffe
    80005aca:	bf2080e7          	jalr	-1038(ra) # 800036b8 <ilock>
  if(ip->type != T_DIR){
    80005ace:	04449703          	lh	a4,68(s1)
    80005ad2:	4785                	li	a5,1
    80005ad4:	04f71063          	bne	a4,a5,80005b14 <sys_chdir+0x92>
  //     end_op();
  //     return -1;
  //   }
  // }
  //mp4
  iunlock(ip);
    80005ad8:	8526                	mv	a0,s1
    80005ada:	ffffe097          	auipc	ra,0xffffe
    80005ade:	ca0080e7          	jalr	-864(ra) # 8000377a <iunlock>
  iput(p->cwd);
    80005ae2:	15093503          	ld	a0,336(s2)
    80005ae6:	ffffe097          	auipc	ra,0xffffe
    80005aea:	e42080e7          	jalr	-446(ra) # 80003928 <iput>
  end_op();
    80005aee:	ffffe097          	auipc	ra,0xffffe
    80005af2:	752080e7          	jalr	1874(ra) # 80004240 <end_op>
  p->cwd = ip;
    80005af6:	14993823          	sd	s1,336(s2)
  return 0;
    80005afa:	4501                	li	a0,0
}
    80005afc:	60ea                	ld	ra,152(sp)
    80005afe:	644a                	ld	s0,144(sp)
    80005b00:	64aa                	ld	s1,136(sp)
    80005b02:	690a                	ld	s2,128(sp)
    80005b04:	610d                	addi	sp,sp,160
    80005b06:	8082                	ret
    end_op();
    80005b08:	ffffe097          	auipc	ra,0xffffe
    80005b0c:	738080e7          	jalr	1848(ra) # 80004240 <end_op>
    return -1;
    80005b10:	557d                	li	a0,-1
    80005b12:	b7ed                	j	80005afc <sys_chdir+0x7a>
    iunlockput(ip);
    80005b14:	8526                	mv	a0,s1
    80005b16:	ffffe097          	auipc	ra,0xffffe
    80005b1a:	eba080e7          	jalr	-326(ra) # 800039d0 <iunlockput>
    end_op();
    80005b1e:	ffffe097          	auipc	ra,0xffffe
    80005b22:	722080e7          	jalr	1826(ra) # 80004240 <end_op>
    return -1;
    80005b26:	557d                	li	a0,-1
    80005b28:	bfd1                	j	80005afc <sys_chdir+0x7a>

0000000080005b2a <sys_exec>:

uint64
sys_exec(void)
{
    80005b2a:	7145                	addi	sp,sp,-464
    80005b2c:	e786                	sd	ra,456(sp)
    80005b2e:	e3a2                	sd	s0,448(sp)
    80005b30:	ff26                	sd	s1,440(sp)
    80005b32:	fb4a                	sd	s2,432(sp)
    80005b34:	f74e                	sd	s3,424(sp)
    80005b36:	f352                	sd	s4,416(sp)
    80005b38:	ef56                	sd	s5,408(sp)
    80005b3a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b3c:	08000613          	li	a2,128
    80005b40:	f4040593          	addi	a1,s0,-192
    80005b44:	4501                	li	a0,0
    80005b46:	ffffd097          	auipc	ra,0xffffd
    80005b4a:	f6e080e7          	jalr	-146(ra) # 80002ab4 <argstr>
    return -1;
    80005b4e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b50:	0c054a63          	bltz	a0,80005c24 <sys_exec+0xfa>
    80005b54:	e3840593          	addi	a1,s0,-456
    80005b58:	4505                	li	a0,1
    80005b5a:	ffffd097          	auipc	ra,0xffffd
    80005b5e:	f38080e7          	jalr	-200(ra) # 80002a92 <argaddr>
    80005b62:	0c054163          	bltz	a0,80005c24 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b66:	10000613          	li	a2,256
    80005b6a:	4581                	li	a1,0
    80005b6c:	e4040513          	addi	a0,s0,-448
    80005b70:	ffffb097          	auipc	ra,0xffffb
    80005b74:	14e080e7          	jalr	334(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b78:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b7c:	89a6                	mv	s3,s1
    80005b7e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b80:	02000a13          	li	s4,32
    80005b84:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b88:	00391793          	slli	a5,s2,0x3
    80005b8c:	e3040593          	addi	a1,s0,-464
    80005b90:	e3843503          	ld	a0,-456(s0)
    80005b94:	953e                	add	a0,a0,a5
    80005b96:	ffffd097          	auipc	ra,0xffffd
    80005b9a:	e40080e7          	jalr	-448(ra) # 800029d6 <fetchaddr>
    80005b9e:	02054a63          	bltz	a0,80005bd2 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005ba2:	e3043783          	ld	a5,-464(s0)
    80005ba6:	c3b9                	beqz	a5,80005bec <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ba8:	ffffb097          	auipc	ra,0xffffb
    80005bac:	f2a080e7          	jalr	-214(ra) # 80000ad2 <kalloc>
    80005bb0:	85aa                	mv	a1,a0
    80005bb2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005bb6:	cd11                	beqz	a0,80005bd2 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005bb8:	6605                	lui	a2,0x1
    80005bba:	e3043503          	ld	a0,-464(s0)
    80005bbe:	ffffd097          	auipc	ra,0xffffd
    80005bc2:	e6a080e7          	jalr	-406(ra) # 80002a28 <fetchstr>
    80005bc6:	00054663          	bltz	a0,80005bd2 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005bca:	0905                	addi	s2,s2,1
    80005bcc:	09a1                	addi	s3,s3,8
    80005bce:	fb491be3          	bne	s2,s4,80005b84 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bd2:	10048913          	addi	s2,s1,256
    80005bd6:	6088                	ld	a0,0(s1)
    80005bd8:	c529                	beqz	a0,80005c22 <sys_exec+0xf8>
    kfree(argv[i]);
    80005bda:	ffffb097          	auipc	ra,0xffffb
    80005bde:	dfc080e7          	jalr	-516(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005be2:	04a1                	addi	s1,s1,8
    80005be4:	ff2499e3          	bne	s1,s2,80005bd6 <sys_exec+0xac>
  return -1;
    80005be8:	597d                	li	s2,-1
    80005bea:	a82d                	j	80005c24 <sys_exec+0xfa>
      argv[i] = 0;
    80005bec:	0a8e                	slli	s5,s5,0x3
    80005bee:	fc040793          	addi	a5,s0,-64
    80005bf2:	9abe                	add	s5,s5,a5
    80005bf4:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005bf8:	e4040593          	addi	a1,s0,-448
    80005bfc:	f4040513          	addi	a0,s0,-192
    80005c00:	fffff097          	auipc	ra,0xfffff
    80005c04:	0de080e7          	jalr	222(ra) # 80004cde <exec>
    80005c08:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c0a:	10048993          	addi	s3,s1,256
    80005c0e:	6088                	ld	a0,0(s1)
    80005c10:	c911                	beqz	a0,80005c24 <sys_exec+0xfa>
    kfree(argv[i]);
    80005c12:	ffffb097          	auipc	ra,0xffffb
    80005c16:	dc4080e7          	jalr	-572(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c1a:	04a1                	addi	s1,s1,8
    80005c1c:	ff3499e3          	bne	s1,s3,80005c0e <sys_exec+0xe4>
    80005c20:	a011                	j	80005c24 <sys_exec+0xfa>
  return -1;
    80005c22:	597d                	li	s2,-1
}
    80005c24:	854a                	mv	a0,s2
    80005c26:	60be                	ld	ra,456(sp)
    80005c28:	641e                	ld	s0,448(sp)
    80005c2a:	74fa                	ld	s1,440(sp)
    80005c2c:	795a                	ld	s2,432(sp)
    80005c2e:	79ba                	ld	s3,424(sp)
    80005c30:	7a1a                	ld	s4,416(sp)
    80005c32:	6afa                	ld	s5,408(sp)
    80005c34:	6179                	addi	sp,sp,464
    80005c36:	8082                	ret

0000000080005c38 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c38:	7139                	addi	sp,sp,-64
    80005c3a:	fc06                	sd	ra,56(sp)
    80005c3c:	f822                	sd	s0,48(sp)
    80005c3e:	f426                	sd	s1,40(sp)
    80005c40:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c42:	ffffc097          	auipc	ra,0xffffc
    80005c46:	d7e080e7          	jalr	-642(ra) # 800019c0 <myproc>
    80005c4a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c4c:	fd840593          	addi	a1,s0,-40
    80005c50:	4501                	li	a0,0
    80005c52:	ffffd097          	auipc	ra,0xffffd
    80005c56:	e40080e7          	jalr	-448(ra) # 80002a92 <argaddr>
    return -1;
    80005c5a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c5c:	0e054063          	bltz	a0,80005d3c <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c60:	fc840593          	addi	a1,s0,-56
    80005c64:	fd040513          	addi	a0,s0,-48
    80005c68:	fffff097          	auipc	ra,0xfffff
    80005c6c:	d54080e7          	jalr	-684(ra) # 800049bc <pipealloc>
    return -1;
    80005c70:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c72:	0c054563          	bltz	a0,80005d3c <sys_pipe+0x104>
  fd0 = -1;
    80005c76:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c7a:	fd043503          	ld	a0,-48(s0)
    80005c7e:	fffff097          	auipc	ra,0xfffff
    80005c82:	470080e7          	jalr	1136(ra) # 800050ee <fdalloc>
    80005c86:	fca42223          	sw	a0,-60(s0)
    80005c8a:	08054c63          	bltz	a0,80005d22 <sys_pipe+0xea>
    80005c8e:	fc843503          	ld	a0,-56(s0)
    80005c92:	fffff097          	auipc	ra,0xfffff
    80005c96:	45c080e7          	jalr	1116(ra) # 800050ee <fdalloc>
    80005c9a:	fca42023          	sw	a0,-64(s0)
    80005c9e:	06054863          	bltz	a0,80005d0e <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ca2:	4691                	li	a3,4
    80005ca4:	fc440613          	addi	a2,s0,-60
    80005ca8:	fd843583          	ld	a1,-40(s0)
    80005cac:	68a8                	ld	a0,80(s1)
    80005cae:	ffffc097          	auipc	ra,0xffffc
    80005cb2:	9d2080e7          	jalr	-1582(ra) # 80001680 <copyout>
    80005cb6:	02054063          	bltz	a0,80005cd6 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005cba:	4691                	li	a3,4
    80005cbc:	fc040613          	addi	a2,s0,-64
    80005cc0:	fd843583          	ld	a1,-40(s0)
    80005cc4:	0591                	addi	a1,a1,4
    80005cc6:	68a8                	ld	a0,80(s1)
    80005cc8:	ffffc097          	auipc	ra,0xffffc
    80005ccc:	9b8080e7          	jalr	-1608(ra) # 80001680 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005cd0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cd2:	06055563          	bgez	a0,80005d3c <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005cd6:	fc442783          	lw	a5,-60(s0)
    80005cda:	07e9                	addi	a5,a5,26
    80005cdc:	078e                	slli	a5,a5,0x3
    80005cde:	97a6                	add	a5,a5,s1
    80005ce0:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005ce4:	fc042503          	lw	a0,-64(s0)
    80005ce8:	0569                	addi	a0,a0,26
    80005cea:	050e                	slli	a0,a0,0x3
    80005cec:	9526                	add	a0,a0,s1
    80005cee:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005cf2:	fd043503          	ld	a0,-48(s0)
    80005cf6:	fffff097          	auipc	ra,0xfffff
    80005cfa:	996080e7          	jalr	-1642(ra) # 8000468c <fileclose>
    fileclose(wf);
    80005cfe:	fc843503          	ld	a0,-56(s0)
    80005d02:	fffff097          	auipc	ra,0xfffff
    80005d06:	98a080e7          	jalr	-1654(ra) # 8000468c <fileclose>
    return -1;
    80005d0a:	57fd                	li	a5,-1
    80005d0c:	a805                	j	80005d3c <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d0e:	fc442783          	lw	a5,-60(s0)
    80005d12:	0007c863          	bltz	a5,80005d22 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d16:	01a78513          	addi	a0,a5,26
    80005d1a:	050e                	slli	a0,a0,0x3
    80005d1c:	9526                	add	a0,a0,s1
    80005d1e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d22:	fd043503          	ld	a0,-48(s0)
    80005d26:	fffff097          	auipc	ra,0xfffff
    80005d2a:	966080e7          	jalr	-1690(ra) # 8000468c <fileclose>
    fileclose(wf);
    80005d2e:	fc843503          	ld	a0,-56(s0)
    80005d32:	fffff097          	auipc	ra,0xfffff
    80005d36:	95a080e7          	jalr	-1702(ra) # 8000468c <fileclose>
    return -1;
    80005d3a:	57fd                	li	a5,-1
}
    80005d3c:	853e                	mv	a0,a5
    80005d3e:	70e2                	ld	ra,56(sp)
    80005d40:	7442                	ld	s0,48(sp)
    80005d42:	74a2                	ld	s1,40(sp)
    80005d44:	6121                	addi	sp,sp,64
    80005d46:	8082                	ret

0000000080005d48 <sys_symlink>:

uint64
sys_symlink(void)
{
    80005d48:	712d                	addi	sp,sp,-288
    80005d4a:	ee06                	sd	ra,280(sp)
    80005d4c:	ea22                	sd	s0,272(sp)
    80005d4e:	e626                	sd	s1,264(sp)
    80005d50:	1200                	addi	s0,sp,288
  // TODO: symbolic link
  // You should implement this symlink system call.
  char target[MAXPATH], path[MAXPATH];
  struct inode *ip;

  if(argstr(0, target, MAXPATH) < 0 || argstr(1, path, MAXPATH) < 0)
    80005d52:	08000613          	li	a2,128
    80005d56:	f6040593          	addi	a1,s0,-160
    80005d5a:	4501                	li	a0,0
    80005d5c:	ffffd097          	auipc	ra,0xffffd
    80005d60:	d58080e7          	jalr	-680(ra) # 80002ab4 <argstr>
    return -1;
    80005d64:	57fd                	li	a5,-1
  if(argstr(0, target, MAXPATH) < 0 || argstr(1, path, MAXPATH) < 0)
    80005d66:	06054563          	bltz	a0,80005dd0 <sys_symlink+0x88>
    80005d6a:	08000613          	li	a2,128
    80005d6e:	ee040593          	addi	a1,s0,-288
    80005d72:	4505                	li	a0,1
    80005d74:	ffffd097          	auipc	ra,0xffffd
    80005d78:	d40080e7          	jalr	-704(ra) # 80002ab4 <argstr>
    return -1;
    80005d7c:	57fd                	li	a5,-1
  if(argstr(0, target, MAXPATH) < 0 || argstr(1, path, MAXPATH) < 0)
    80005d7e:	04054963          	bltz	a0,80005dd0 <sys_symlink+0x88>
  
  begin_op();
    80005d82:	ffffe097          	auipc	ra,0xffffe
    80005d86:	43e080e7          	jalr	1086(ra) # 800041c0 <begin_op>

  ip = create(path, T_SYMLINK, 0, 0);
    80005d8a:	4681                	li	a3,0
    80005d8c:	4601                	li	a2,0
    80005d8e:	4591                	li	a1,4
    80005d90:	ee040513          	addi	a0,s0,-288
    80005d94:	fffff097          	auipc	ra,0xfffff
    80005d98:	39c080e7          	jalr	924(ra) # 80005130 <create>
    80005d9c:	84aa                	mv	s1,a0
  if(ip==0){
    80005d9e:	cd1d                	beqz	a0,80005ddc <sys_symlink+0x94>
    end_op();
    return -1;
  }

  if(writei(ip, 0, (uint64)target, 0, MAXPATH) != MAXPATH){
    80005da0:	08000713          	li	a4,128
    80005da4:	4681                	li	a3,0
    80005da6:	f6040613          	addi	a2,s0,-160
    80005daa:	4581                	li	a1,0
    80005dac:	ffffe097          	auipc	ra,0xffffe
    80005db0:	d6e080e7          	jalr	-658(ra) # 80003b1a <writei>
    80005db4:	08000793          	li	a5,128
    80005db8:	02f51863          	bne	a0,a5,80005de8 <sys_symlink+0xa0>
    iunlockput(ip);
    end_op();
    return -1;
  }

  iunlockput(ip);
    80005dbc:	8526                	mv	a0,s1
    80005dbe:	ffffe097          	auipc	ra,0xffffe
    80005dc2:	c12080e7          	jalr	-1006(ra) # 800039d0 <iunlockput>

  end_op();
    80005dc6:	ffffe097          	auipc	ra,0xffffe
    80005dca:	47a080e7          	jalr	1146(ra) # 80004240 <end_op>
  return 0;
    80005dce:	4781                	li	a5,0
    80005dd0:	853e                	mv	a0,a5
    80005dd2:	60f2                	ld	ra,280(sp)
    80005dd4:	6452                	ld	s0,272(sp)
    80005dd6:	64b2                	ld	s1,264(sp)
    80005dd8:	6115                	addi	sp,sp,288
    80005dda:	8082                	ret
    end_op();
    80005ddc:	ffffe097          	auipc	ra,0xffffe
    80005de0:	464080e7          	jalr	1124(ra) # 80004240 <end_op>
    return -1;
    80005de4:	57fd                	li	a5,-1
    80005de6:	b7ed                	j	80005dd0 <sys_symlink+0x88>
    iunlockput(ip);
    80005de8:	8526                	mv	a0,s1
    80005dea:	ffffe097          	auipc	ra,0xffffe
    80005dee:	be6080e7          	jalr	-1050(ra) # 800039d0 <iunlockput>
    end_op();
    80005df2:	ffffe097          	auipc	ra,0xffffe
    80005df6:	44e080e7          	jalr	1102(ra) # 80004240 <end_op>
    return -1;
    80005dfa:	57fd                	li	a5,-1
    80005dfc:	bfd1                	j	80005dd0 <sys_symlink+0x88>
	...

0000000080005e00 <kernelvec>:
    80005e00:	7111                	addi	sp,sp,-256
    80005e02:	e006                	sd	ra,0(sp)
    80005e04:	e40a                	sd	sp,8(sp)
    80005e06:	e80e                	sd	gp,16(sp)
    80005e08:	ec12                	sd	tp,24(sp)
    80005e0a:	f016                	sd	t0,32(sp)
    80005e0c:	f41a                	sd	t1,40(sp)
    80005e0e:	f81e                	sd	t2,48(sp)
    80005e10:	fc22                	sd	s0,56(sp)
    80005e12:	e0a6                	sd	s1,64(sp)
    80005e14:	e4aa                	sd	a0,72(sp)
    80005e16:	e8ae                	sd	a1,80(sp)
    80005e18:	ecb2                	sd	a2,88(sp)
    80005e1a:	f0b6                	sd	a3,96(sp)
    80005e1c:	f4ba                	sd	a4,104(sp)
    80005e1e:	f8be                	sd	a5,112(sp)
    80005e20:	fcc2                	sd	a6,120(sp)
    80005e22:	e146                	sd	a7,128(sp)
    80005e24:	e54a                	sd	s2,136(sp)
    80005e26:	e94e                	sd	s3,144(sp)
    80005e28:	ed52                	sd	s4,152(sp)
    80005e2a:	f156                	sd	s5,160(sp)
    80005e2c:	f55a                	sd	s6,168(sp)
    80005e2e:	f95e                	sd	s7,176(sp)
    80005e30:	fd62                	sd	s8,184(sp)
    80005e32:	e1e6                	sd	s9,192(sp)
    80005e34:	e5ea                	sd	s10,200(sp)
    80005e36:	e9ee                	sd	s11,208(sp)
    80005e38:	edf2                	sd	t3,216(sp)
    80005e3a:	f1f6                	sd	t4,224(sp)
    80005e3c:	f5fa                	sd	t5,232(sp)
    80005e3e:	f9fe                	sd	t6,240(sp)
    80005e40:	a63fc0ef          	jal	ra,800028a2 <kerneltrap>
    80005e44:	6082                	ld	ra,0(sp)
    80005e46:	6122                	ld	sp,8(sp)
    80005e48:	61c2                	ld	gp,16(sp)
    80005e4a:	7282                	ld	t0,32(sp)
    80005e4c:	7322                	ld	t1,40(sp)
    80005e4e:	73c2                	ld	t2,48(sp)
    80005e50:	7462                	ld	s0,56(sp)
    80005e52:	6486                	ld	s1,64(sp)
    80005e54:	6526                	ld	a0,72(sp)
    80005e56:	65c6                	ld	a1,80(sp)
    80005e58:	6666                	ld	a2,88(sp)
    80005e5a:	7686                	ld	a3,96(sp)
    80005e5c:	7726                	ld	a4,104(sp)
    80005e5e:	77c6                	ld	a5,112(sp)
    80005e60:	7866                	ld	a6,120(sp)
    80005e62:	688a                	ld	a7,128(sp)
    80005e64:	692a                	ld	s2,136(sp)
    80005e66:	69ca                	ld	s3,144(sp)
    80005e68:	6a6a                	ld	s4,152(sp)
    80005e6a:	7a8a                	ld	s5,160(sp)
    80005e6c:	7b2a                	ld	s6,168(sp)
    80005e6e:	7bca                	ld	s7,176(sp)
    80005e70:	7c6a                	ld	s8,184(sp)
    80005e72:	6c8e                	ld	s9,192(sp)
    80005e74:	6d2e                	ld	s10,200(sp)
    80005e76:	6dce                	ld	s11,208(sp)
    80005e78:	6e6e                	ld	t3,216(sp)
    80005e7a:	7e8e                	ld	t4,224(sp)
    80005e7c:	7f2e                	ld	t5,232(sp)
    80005e7e:	7fce                	ld	t6,240(sp)
    80005e80:	6111                	addi	sp,sp,256
    80005e82:	10200073          	sret
    80005e86:	00000013          	nop
    80005e8a:	00000013          	nop
    80005e8e:	0001                	nop

0000000080005e90 <timervec>:
    80005e90:	34051573          	csrrw	a0,mscratch,a0
    80005e94:	e10c                	sd	a1,0(a0)
    80005e96:	e510                	sd	a2,8(a0)
    80005e98:	e914                	sd	a3,16(a0)
    80005e9a:	6d0c                	ld	a1,24(a0)
    80005e9c:	7110                	ld	a2,32(a0)
    80005e9e:	6194                	ld	a3,0(a1)
    80005ea0:	96b2                	add	a3,a3,a2
    80005ea2:	e194                	sd	a3,0(a1)
    80005ea4:	4589                	li	a1,2
    80005ea6:	14459073          	csrw	sip,a1
    80005eaa:	6914                	ld	a3,16(a0)
    80005eac:	6510                	ld	a2,8(a0)
    80005eae:	610c                	ld	a1,0(a0)
    80005eb0:	34051573          	csrrw	a0,mscratch,a0
    80005eb4:	30200073          	mret
	...

0000000080005eba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005eba:	1141                	addi	sp,sp,-16
    80005ebc:	e422                	sd	s0,8(sp)
    80005ebe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ec0:	0c0007b7          	lui	a5,0xc000
    80005ec4:	4705                	li	a4,1
    80005ec6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ec8:	c3d8                	sw	a4,4(a5)
}
    80005eca:	6422                	ld	s0,8(sp)
    80005ecc:	0141                	addi	sp,sp,16
    80005ece:	8082                	ret

0000000080005ed0 <plicinithart>:

void
plicinithart(void)
{
    80005ed0:	1141                	addi	sp,sp,-16
    80005ed2:	e406                	sd	ra,8(sp)
    80005ed4:	e022                	sd	s0,0(sp)
    80005ed6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ed8:	ffffc097          	auipc	ra,0xffffc
    80005edc:	abc080e7          	jalr	-1348(ra) # 80001994 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ee0:	0085171b          	slliw	a4,a0,0x8
    80005ee4:	0c0027b7          	lui	a5,0xc002
    80005ee8:	97ba                	add	a5,a5,a4
    80005eea:	40200713          	li	a4,1026
    80005eee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ef2:	00d5151b          	slliw	a0,a0,0xd
    80005ef6:	0c2017b7          	lui	a5,0xc201
    80005efa:	953e                	add	a0,a0,a5
    80005efc:	00052023          	sw	zero,0(a0)
}
    80005f00:	60a2                	ld	ra,8(sp)
    80005f02:	6402                	ld	s0,0(sp)
    80005f04:	0141                	addi	sp,sp,16
    80005f06:	8082                	ret

0000000080005f08 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f08:	1141                	addi	sp,sp,-16
    80005f0a:	e406                	sd	ra,8(sp)
    80005f0c:	e022                	sd	s0,0(sp)
    80005f0e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f10:	ffffc097          	auipc	ra,0xffffc
    80005f14:	a84080e7          	jalr	-1404(ra) # 80001994 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f18:	00d5179b          	slliw	a5,a0,0xd
    80005f1c:	0c201537          	lui	a0,0xc201
    80005f20:	953e                	add	a0,a0,a5
  return irq;
}
    80005f22:	4148                	lw	a0,4(a0)
    80005f24:	60a2                	ld	ra,8(sp)
    80005f26:	6402                	ld	s0,0(sp)
    80005f28:	0141                	addi	sp,sp,16
    80005f2a:	8082                	ret

0000000080005f2c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f2c:	1101                	addi	sp,sp,-32
    80005f2e:	ec06                	sd	ra,24(sp)
    80005f30:	e822                	sd	s0,16(sp)
    80005f32:	e426                	sd	s1,8(sp)
    80005f34:	1000                	addi	s0,sp,32
    80005f36:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f38:	ffffc097          	auipc	ra,0xffffc
    80005f3c:	a5c080e7          	jalr	-1444(ra) # 80001994 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f40:	00d5151b          	slliw	a0,a0,0xd
    80005f44:	0c2017b7          	lui	a5,0xc201
    80005f48:	97aa                	add	a5,a5,a0
    80005f4a:	c3c4                	sw	s1,4(a5)
}
    80005f4c:	60e2                	ld	ra,24(sp)
    80005f4e:	6442                	ld	s0,16(sp)
    80005f50:	64a2                	ld	s1,8(sp)
    80005f52:	6105                	addi	sp,sp,32
    80005f54:	8082                	ret

0000000080005f56 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f56:	1141                	addi	sp,sp,-16
    80005f58:	e406                	sd	ra,8(sp)
    80005f5a:	e022                	sd	s0,0(sp)
    80005f5c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f5e:	479d                	li	a5,7
    80005f60:	06a7c963          	blt	a5,a0,80005fd2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005f64:	0001d797          	auipc	a5,0x1d
    80005f68:	09c78793          	addi	a5,a5,156 # 80023000 <disk>
    80005f6c:	00a78733          	add	a4,a5,a0
    80005f70:	6789                	lui	a5,0x2
    80005f72:	97ba                	add	a5,a5,a4
    80005f74:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f78:	e7ad                	bnez	a5,80005fe2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f7a:	00451793          	slli	a5,a0,0x4
    80005f7e:	0001f717          	auipc	a4,0x1f
    80005f82:	08270713          	addi	a4,a4,130 # 80025000 <disk+0x2000>
    80005f86:	6314                	ld	a3,0(a4)
    80005f88:	96be                	add	a3,a3,a5
    80005f8a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f8e:	6314                	ld	a3,0(a4)
    80005f90:	96be                	add	a3,a3,a5
    80005f92:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005f96:	6314                	ld	a3,0(a4)
    80005f98:	96be                	add	a3,a3,a5
    80005f9a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005f9e:	6318                	ld	a4,0(a4)
    80005fa0:	97ba                	add	a5,a5,a4
    80005fa2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005fa6:	0001d797          	auipc	a5,0x1d
    80005faa:	05a78793          	addi	a5,a5,90 # 80023000 <disk>
    80005fae:	97aa                	add	a5,a5,a0
    80005fb0:	6509                	lui	a0,0x2
    80005fb2:	953e                	add	a0,a0,a5
    80005fb4:	4785                	li	a5,1
    80005fb6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005fba:	0001f517          	auipc	a0,0x1f
    80005fbe:	05e50513          	addi	a0,a0,94 # 80025018 <disk+0x2018>
    80005fc2:	ffffc097          	auipc	ra,0xffffc
    80005fc6:	24a080e7          	jalr	586(ra) # 8000220c <wakeup>
}
    80005fca:	60a2                	ld	ra,8(sp)
    80005fcc:	6402                	ld	s0,0(sp)
    80005fce:	0141                	addi	sp,sp,16
    80005fd0:	8082                	ret
    panic("free_desc 1");
    80005fd2:	00002517          	auipc	a0,0x2
    80005fd6:	78650513          	addi	a0,a0,1926 # 80008758 <syscalls+0x328>
    80005fda:	ffffa097          	auipc	ra,0xffffa
    80005fde:	550080e7          	jalr	1360(ra) # 8000052a <panic>
    panic("free_desc 2");
    80005fe2:	00002517          	auipc	a0,0x2
    80005fe6:	78650513          	addi	a0,a0,1926 # 80008768 <syscalls+0x338>
    80005fea:	ffffa097          	auipc	ra,0xffffa
    80005fee:	540080e7          	jalr	1344(ra) # 8000052a <panic>

0000000080005ff2 <virtio_disk_init>:
{
    80005ff2:	1101                	addi	sp,sp,-32
    80005ff4:	ec06                	sd	ra,24(sp)
    80005ff6:	e822                	sd	s0,16(sp)
    80005ff8:	e426                	sd	s1,8(sp)
    80005ffa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005ffc:	00002597          	auipc	a1,0x2
    80006000:	77c58593          	addi	a1,a1,1916 # 80008778 <syscalls+0x348>
    80006004:	0001f517          	auipc	a0,0x1f
    80006008:	12450513          	addi	a0,a0,292 # 80025128 <disk+0x2128>
    8000600c:	ffffb097          	auipc	ra,0xffffb
    80006010:	b26080e7          	jalr	-1242(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006014:	100017b7          	lui	a5,0x10001
    80006018:	4398                	lw	a4,0(a5)
    8000601a:	2701                	sext.w	a4,a4
    8000601c:	747277b7          	lui	a5,0x74727
    80006020:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006024:	0ef71163          	bne	a4,a5,80006106 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006028:	100017b7          	lui	a5,0x10001
    8000602c:	43dc                	lw	a5,4(a5)
    8000602e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006030:	4705                	li	a4,1
    80006032:	0ce79a63          	bne	a5,a4,80006106 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006036:	100017b7          	lui	a5,0x10001
    8000603a:	479c                	lw	a5,8(a5)
    8000603c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000603e:	4709                	li	a4,2
    80006040:	0ce79363          	bne	a5,a4,80006106 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006044:	100017b7          	lui	a5,0x10001
    80006048:	47d8                	lw	a4,12(a5)
    8000604a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000604c:	554d47b7          	lui	a5,0x554d4
    80006050:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006054:	0af71963          	bne	a4,a5,80006106 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006058:	100017b7          	lui	a5,0x10001
    8000605c:	4705                	li	a4,1
    8000605e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006060:	470d                	li	a4,3
    80006062:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006064:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006066:	c7ffe737          	lui	a4,0xc7ffe
    8000606a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000606e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006070:	2701                	sext.w	a4,a4
    80006072:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006074:	472d                	li	a4,11
    80006076:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006078:	473d                	li	a4,15
    8000607a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000607c:	6705                	lui	a4,0x1
    8000607e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006080:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006084:	5bdc                	lw	a5,52(a5)
    80006086:	2781                	sext.w	a5,a5
  if(max == 0)
    80006088:	c7d9                	beqz	a5,80006116 <virtio_disk_init+0x124>
  if(max < NUM)
    8000608a:	471d                	li	a4,7
    8000608c:	08f77d63          	bgeu	a4,a5,80006126 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006090:	100014b7          	lui	s1,0x10001
    80006094:	47a1                	li	a5,8
    80006096:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006098:	6609                	lui	a2,0x2
    8000609a:	4581                	li	a1,0
    8000609c:	0001d517          	auipc	a0,0x1d
    800060a0:	f6450513          	addi	a0,a0,-156 # 80023000 <disk>
    800060a4:	ffffb097          	auipc	ra,0xffffb
    800060a8:	c1a080e7          	jalr	-998(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800060ac:	0001d717          	auipc	a4,0x1d
    800060b0:	f5470713          	addi	a4,a4,-172 # 80023000 <disk>
    800060b4:	00c75793          	srli	a5,a4,0xc
    800060b8:	2781                	sext.w	a5,a5
    800060ba:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800060bc:	0001f797          	auipc	a5,0x1f
    800060c0:	f4478793          	addi	a5,a5,-188 # 80025000 <disk+0x2000>
    800060c4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800060c6:	0001d717          	auipc	a4,0x1d
    800060ca:	fba70713          	addi	a4,a4,-70 # 80023080 <disk+0x80>
    800060ce:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800060d0:	0001e717          	auipc	a4,0x1e
    800060d4:	f3070713          	addi	a4,a4,-208 # 80024000 <disk+0x1000>
    800060d8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800060da:	4705                	li	a4,1
    800060dc:	00e78c23          	sb	a4,24(a5)
    800060e0:	00e78ca3          	sb	a4,25(a5)
    800060e4:	00e78d23          	sb	a4,26(a5)
    800060e8:	00e78da3          	sb	a4,27(a5)
    800060ec:	00e78e23          	sb	a4,28(a5)
    800060f0:	00e78ea3          	sb	a4,29(a5)
    800060f4:	00e78f23          	sb	a4,30(a5)
    800060f8:	00e78fa3          	sb	a4,31(a5)
}
    800060fc:	60e2                	ld	ra,24(sp)
    800060fe:	6442                	ld	s0,16(sp)
    80006100:	64a2                	ld	s1,8(sp)
    80006102:	6105                	addi	sp,sp,32
    80006104:	8082                	ret
    panic("could not find virtio disk");
    80006106:	00002517          	auipc	a0,0x2
    8000610a:	68250513          	addi	a0,a0,1666 # 80008788 <syscalls+0x358>
    8000610e:	ffffa097          	auipc	ra,0xffffa
    80006112:	41c080e7          	jalr	1052(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006116:	00002517          	auipc	a0,0x2
    8000611a:	69250513          	addi	a0,a0,1682 # 800087a8 <syscalls+0x378>
    8000611e:	ffffa097          	auipc	ra,0xffffa
    80006122:	40c080e7          	jalr	1036(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006126:	00002517          	auipc	a0,0x2
    8000612a:	6a250513          	addi	a0,a0,1698 # 800087c8 <syscalls+0x398>
    8000612e:	ffffa097          	auipc	ra,0xffffa
    80006132:	3fc080e7          	jalr	1020(ra) # 8000052a <panic>

0000000080006136 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006136:	7119                	addi	sp,sp,-128
    80006138:	fc86                	sd	ra,120(sp)
    8000613a:	f8a2                	sd	s0,112(sp)
    8000613c:	f4a6                	sd	s1,104(sp)
    8000613e:	f0ca                	sd	s2,96(sp)
    80006140:	ecce                	sd	s3,88(sp)
    80006142:	e8d2                	sd	s4,80(sp)
    80006144:	e4d6                	sd	s5,72(sp)
    80006146:	e0da                	sd	s6,64(sp)
    80006148:	fc5e                	sd	s7,56(sp)
    8000614a:	f862                	sd	s8,48(sp)
    8000614c:	f466                	sd	s9,40(sp)
    8000614e:	f06a                	sd	s10,32(sp)
    80006150:	ec6e                	sd	s11,24(sp)
    80006152:	0100                	addi	s0,sp,128
    80006154:	8aaa                	mv	s5,a0
    80006156:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006158:	00c52c83          	lw	s9,12(a0)
    8000615c:	001c9c9b          	slliw	s9,s9,0x1
    80006160:	1c82                	slli	s9,s9,0x20
    80006162:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006166:	0001f517          	auipc	a0,0x1f
    8000616a:	fc250513          	addi	a0,a0,-62 # 80025128 <disk+0x2128>
    8000616e:	ffffb097          	auipc	ra,0xffffb
    80006172:	a54080e7          	jalr	-1452(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006176:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006178:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000617a:	0001dc17          	auipc	s8,0x1d
    8000617e:	e86c0c13          	addi	s8,s8,-378 # 80023000 <disk>
    80006182:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006184:	4b0d                	li	s6,3
    80006186:	a0ad                	j	800061f0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006188:	00fc0733          	add	a4,s8,a5
    8000618c:	975e                	add	a4,a4,s7
    8000618e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006192:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006194:	0207c563          	bltz	a5,800061be <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006198:	2905                	addiw	s2,s2,1
    8000619a:	0611                	addi	a2,a2,4
    8000619c:	19690d63          	beq	s2,s6,80006336 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    800061a0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800061a2:	0001f717          	auipc	a4,0x1f
    800061a6:	e7670713          	addi	a4,a4,-394 # 80025018 <disk+0x2018>
    800061aa:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800061ac:	00074683          	lbu	a3,0(a4)
    800061b0:	fee1                	bnez	a3,80006188 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800061b2:	2785                	addiw	a5,a5,1
    800061b4:	0705                	addi	a4,a4,1
    800061b6:	fe979be3          	bne	a5,s1,800061ac <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800061ba:	57fd                	li	a5,-1
    800061bc:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800061be:	01205d63          	blez	s2,800061d8 <virtio_disk_rw+0xa2>
    800061c2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800061c4:	000a2503          	lw	a0,0(s4)
    800061c8:	00000097          	auipc	ra,0x0
    800061cc:	d8e080e7          	jalr	-626(ra) # 80005f56 <free_desc>
      for(int j = 0; j < i; j++)
    800061d0:	2d85                	addiw	s11,s11,1
    800061d2:	0a11                	addi	s4,s4,4
    800061d4:	ffb918e3          	bne	s2,s11,800061c4 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061d8:	0001f597          	auipc	a1,0x1f
    800061dc:	f5058593          	addi	a1,a1,-176 # 80025128 <disk+0x2128>
    800061e0:	0001f517          	auipc	a0,0x1f
    800061e4:	e3850513          	addi	a0,a0,-456 # 80025018 <disk+0x2018>
    800061e8:	ffffc097          	auipc	ra,0xffffc
    800061ec:	e98080e7          	jalr	-360(ra) # 80002080 <sleep>
  for(int i = 0; i < 3; i++){
    800061f0:	f8040a13          	addi	s4,s0,-128
{
    800061f4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800061f6:	894e                	mv	s2,s3
    800061f8:	b765                	j	800061a0 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800061fa:	0001f697          	auipc	a3,0x1f
    800061fe:	e066b683          	ld	a3,-506(a3) # 80025000 <disk+0x2000>
    80006202:	96ba                	add	a3,a3,a4
    80006204:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006208:	0001d817          	auipc	a6,0x1d
    8000620c:	df880813          	addi	a6,a6,-520 # 80023000 <disk>
    80006210:	0001f697          	auipc	a3,0x1f
    80006214:	df068693          	addi	a3,a3,-528 # 80025000 <disk+0x2000>
    80006218:	6290                	ld	a2,0(a3)
    8000621a:	963a                	add	a2,a2,a4
    8000621c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006220:	0015e593          	ori	a1,a1,1
    80006224:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006228:	f8842603          	lw	a2,-120(s0)
    8000622c:	628c                	ld	a1,0(a3)
    8000622e:	972e                	add	a4,a4,a1
    80006230:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006234:	20050593          	addi	a1,a0,512
    80006238:	0592                	slli	a1,a1,0x4
    8000623a:	95c2                	add	a1,a1,a6
    8000623c:	577d                	li	a4,-1
    8000623e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006242:	00461713          	slli	a4,a2,0x4
    80006246:	6290                	ld	a2,0(a3)
    80006248:	963a                	add	a2,a2,a4
    8000624a:	03078793          	addi	a5,a5,48
    8000624e:	97c2                	add	a5,a5,a6
    80006250:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006252:	629c                	ld	a5,0(a3)
    80006254:	97ba                	add	a5,a5,a4
    80006256:	4605                	li	a2,1
    80006258:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000625a:	629c                	ld	a5,0(a3)
    8000625c:	97ba                	add	a5,a5,a4
    8000625e:	4809                	li	a6,2
    80006260:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006264:	629c                	ld	a5,0(a3)
    80006266:	973e                	add	a4,a4,a5
    80006268:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000626c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006270:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006274:	6698                	ld	a4,8(a3)
    80006276:	00275783          	lhu	a5,2(a4)
    8000627a:	8b9d                	andi	a5,a5,7
    8000627c:	0786                	slli	a5,a5,0x1
    8000627e:	97ba                	add	a5,a5,a4
    80006280:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006284:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006288:	6698                	ld	a4,8(a3)
    8000628a:	00275783          	lhu	a5,2(a4)
    8000628e:	2785                	addiw	a5,a5,1
    80006290:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006294:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006298:	100017b7          	lui	a5,0x10001
    8000629c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062a0:	004aa783          	lw	a5,4(s5)
    800062a4:	02c79163          	bne	a5,a2,800062c6 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    800062a8:	0001f917          	auipc	s2,0x1f
    800062ac:	e8090913          	addi	s2,s2,-384 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800062b0:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800062b2:	85ca                	mv	a1,s2
    800062b4:	8556                	mv	a0,s5
    800062b6:	ffffc097          	auipc	ra,0xffffc
    800062ba:	dca080e7          	jalr	-566(ra) # 80002080 <sleep>
  while(b->disk == 1) {
    800062be:	004aa783          	lw	a5,4(s5)
    800062c2:	fe9788e3          	beq	a5,s1,800062b2 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800062c6:	f8042903          	lw	s2,-128(s0)
    800062ca:	20090793          	addi	a5,s2,512
    800062ce:	00479713          	slli	a4,a5,0x4
    800062d2:	0001d797          	auipc	a5,0x1d
    800062d6:	d2e78793          	addi	a5,a5,-722 # 80023000 <disk>
    800062da:	97ba                	add	a5,a5,a4
    800062dc:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800062e0:	0001f997          	auipc	s3,0x1f
    800062e4:	d2098993          	addi	s3,s3,-736 # 80025000 <disk+0x2000>
    800062e8:	00491713          	slli	a4,s2,0x4
    800062ec:	0009b783          	ld	a5,0(s3)
    800062f0:	97ba                	add	a5,a5,a4
    800062f2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800062f6:	854a                	mv	a0,s2
    800062f8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800062fc:	00000097          	auipc	ra,0x0
    80006300:	c5a080e7          	jalr	-934(ra) # 80005f56 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006304:	8885                	andi	s1,s1,1
    80006306:	f0ed                	bnez	s1,800062e8 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006308:	0001f517          	auipc	a0,0x1f
    8000630c:	e2050513          	addi	a0,a0,-480 # 80025128 <disk+0x2128>
    80006310:	ffffb097          	auipc	ra,0xffffb
    80006314:	966080e7          	jalr	-1690(ra) # 80000c76 <release>
}
    80006318:	70e6                	ld	ra,120(sp)
    8000631a:	7446                	ld	s0,112(sp)
    8000631c:	74a6                	ld	s1,104(sp)
    8000631e:	7906                	ld	s2,96(sp)
    80006320:	69e6                	ld	s3,88(sp)
    80006322:	6a46                	ld	s4,80(sp)
    80006324:	6aa6                	ld	s5,72(sp)
    80006326:	6b06                	ld	s6,64(sp)
    80006328:	7be2                	ld	s7,56(sp)
    8000632a:	7c42                	ld	s8,48(sp)
    8000632c:	7ca2                	ld	s9,40(sp)
    8000632e:	7d02                	ld	s10,32(sp)
    80006330:	6de2                	ld	s11,24(sp)
    80006332:	6109                	addi	sp,sp,128
    80006334:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006336:	f8042503          	lw	a0,-128(s0)
    8000633a:	20050793          	addi	a5,a0,512
    8000633e:	0792                	slli	a5,a5,0x4
  if(write)
    80006340:	0001d817          	auipc	a6,0x1d
    80006344:	cc080813          	addi	a6,a6,-832 # 80023000 <disk>
    80006348:	00f80733          	add	a4,a6,a5
    8000634c:	01a036b3          	snez	a3,s10
    80006350:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006354:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006358:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000635c:	7679                	lui	a2,0xffffe
    8000635e:	963e                	add	a2,a2,a5
    80006360:	0001f697          	auipc	a3,0x1f
    80006364:	ca068693          	addi	a3,a3,-864 # 80025000 <disk+0x2000>
    80006368:	6298                	ld	a4,0(a3)
    8000636a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000636c:	0a878593          	addi	a1,a5,168
    80006370:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006372:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006374:	6298                	ld	a4,0(a3)
    80006376:	9732                	add	a4,a4,a2
    80006378:	45c1                	li	a1,16
    8000637a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000637c:	6298                	ld	a4,0(a3)
    8000637e:	9732                	add	a4,a4,a2
    80006380:	4585                	li	a1,1
    80006382:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006386:	f8442703          	lw	a4,-124(s0)
    8000638a:	628c                	ld	a1,0(a3)
    8000638c:	962e                	add	a2,a2,a1
    8000638e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006392:	0712                	slli	a4,a4,0x4
    80006394:	6290                	ld	a2,0(a3)
    80006396:	963a                	add	a2,a2,a4
    80006398:	058a8593          	addi	a1,s5,88
    8000639c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000639e:	6294                	ld	a3,0(a3)
    800063a0:	96ba                	add	a3,a3,a4
    800063a2:	40000613          	li	a2,1024
    800063a6:	c690                	sw	a2,8(a3)
  if(write)
    800063a8:	e40d19e3          	bnez	s10,800061fa <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800063ac:	0001f697          	auipc	a3,0x1f
    800063b0:	c546b683          	ld	a3,-940(a3) # 80025000 <disk+0x2000>
    800063b4:	96ba                	add	a3,a3,a4
    800063b6:	4609                	li	a2,2
    800063b8:	00c69623          	sh	a2,12(a3)
    800063bc:	b5b1                	j	80006208 <virtio_disk_rw+0xd2>

00000000800063be <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800063be:	1101                	addi	sp,sp,-32
    800063c0:	ec06                	sd	ra,24(sp)
    800063c2:	e822                	sd	s0,16(sp)
    800063c4:	e426                	sd	s1,8(sp)
    800063c6:	e04a                	sd	s2,0(sp)
    800063c8:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063ca:	0001f517          	auipc	a0,0x1f
    800063ce:	d5e50513          	addi	a0,a0,-674 # 80025128 <disk+0x2128>
    800063d2:	ffffa097          	auipc	ra,0xffffa
    800063d6:	7f0080e7          	jalr	2032(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063da:	10001737          	lui	a4,0x10001
    800063de:	533c                	lw	a5,96(a4)
    800063e0:	8b8d                	andi	a5,a5,3
    800063e2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800063e4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800063e8:	0001f797          	auipc	a5,0x1f
    800063ec:	c1878793          	addi	a5,a5,-1000 # 80025000 <disk+0x2000>
    800063f0:	6b94                	ld	a3,16(a5)
    800063f2:	0207d703          	lhu	a4,32(a5)
    800063f6:	0026d783          	lhu	a5,2(a3)
    800063fa:	06f70163          	beq	a4,a5,8000645c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063fe:	0001d917          	auipc	s2,0x1d
    80006402:	c0290913          	addi	s2,s2,-1022 # 80023000 <disk>
    80006406:	0001f497          	auipc	s1,0x1f
    8000640a:	bfa48493          	addi	s1,s1,-1030 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000640e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006412:	6898                	ld	a4,16(s1)
    80006414:	0204d783          	lhu	a5,32(s1)
    80006418:	8b9d                	andi	a5,a5,7
    8000641a:	078e                	slli	a5,a5,0x3
    8000641c:	97ba                	add	a5,a5,a4
    8000641e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006420:	20078713          	addi	a4,a5,512
    80006424:	0712                	slli	a4,a4,0x4
    80006426:	974a                	add	a4,a4,s2
    80006428:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000642c:	e731                	bnez	a4,80006478 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000642e:	20078793          	addi	a5,a5,512
    80006432:	0792                	slli	a5,a5,0x4
    80006434:	97ca                	add	a5,a5,s2
    80006436:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006438:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000643c:	ffffc097          	auipc	ra,0xffffc
    80006440:	dd0080e7          	jalr	-560(ra) # 8000220c <wakeup>

    disk.used_idx += 1;
    80006444:	0204d783          	lhu	a5,32(s1)
    80006448:	2785                	addiw	a5,a5,1
    8000644a:	17c2                	slli	a5,a5,0x30
    8000644c:	93c1                	srli	a5,a5,0x30
    8000644e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006452:	6898                	ld	a4,16(s1)
    80006454:	00275703          	lhu	a4,2(a4)
    80006458:	faf71be3          	bne	a4,a5,8000640e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000645c:	0001f517          	auipc	a0,0x1f
    80006460:	ccc50513          	addi	a0,a0,-820 # 80025128 <disk+0x2128>
    80006464:	ffffb097          	auipc	ra,0xffffb
    80006468:	812080e7          	jalr	-2030(ra) # 80000c76 <release>
}
    8000646c:	60e2                	ld	ra,24(sp)
    8000646e:	6442                	ld	s0,16(sp)
    80006470:	64a2                	ld	s1,8(sp)
    80006472:	6902                	ld	s2,0(sp)
    80006474:	6105                	addi	sp,sp,32
    80006476:	8082                	ret
      panic("virtio_disk_intr status");
    80006478:	00002517          	auipc	a0,0x2
    8000647c:	37050513          	addi	a0,a0,880 # 800087e8 <syscalls+0x3b8>
    80006480:	ffffa097          	auipc	ra,0xffffa
    80006484:	0aa080e7          	jalr	170(ra) # 8000052a <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
