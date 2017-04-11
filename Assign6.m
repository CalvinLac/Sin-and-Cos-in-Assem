  define(original_angle, d8)
  define(poly_v, d9)
  define(factorial_v, d10)
  define(angle_in_radian, d13)
  define(addorsub, w26)

  // Register equates for heavily used registers
  fdin_r    .req  w19
  fdout_r   .req  w20
  //Needs these for the file in and file out
  pnin_r    .req  x21
  pnout_r   .req  x22
  buf_base_r  .req  x23
  nread_r   .req  x24
  nwritten_r  .req  x25

  // Assembler equates
  buf_size  = 8
  alloc     = -(16 + buf_size) & -16
  dealloc   = -alloc
  buf_s     = 16
  AT_FDCWD  = -100

  .data
constant_m:  .double 0r1e-10
radianconversion_m: .double 0r3.1415926535897932384626433

  .text
fmt1: .string "Error opening file: %s\nAborting.\n"
fmt2: .string "Error reading from file: %s\nAborting.\n"
fmt3: .string "Error writing to file: %s\nAborting.\n"


  .balign 4
  .global main
main: 
  stp x29, x30, [sp, alloc]!
  mov x29, sp

  ldr pnin_r, [x1, 8]
  ldr pnout_r, [x1, 16]

openinput:
  mov x1, pnin_r
  mov w2, 0
  mov x3, 0
  mov x8, 56
  svc 0
  mov fdin_r, w0

errortest1:
  cmp fdin_r, 0
  b.ge opensuccess

errorinput:
  adrp x0, fmt1
  add x0, x0, :lo12:fmt1
  mov x1, pnin_r
  bl printf
  mov w0, -1
  b exit

opensuccess:
  add buf_base_r, x29, buf_s  //This is calculating the base address for the buffer

  //This is the reader loop
top:
  mov w0, fdin_r    // 1st arg (fd)
  mov x1, buf_base_r    // 2nd arg (buf)
  mov w2, buf_size    // 3rd arg (n)
  mov x8, 63      // read I/O request
  svc 0     // call system function
  mov nread_r, x0   // record $ of bytes actually read

  // 4.b: Error checking: reading from input file (exit condition)
  cmp nread_r, buf_size // if nread != 1, then
  b.ne  end     // read failed, so exit loop (EOF reached)

loadingreadvalue:
  ldr original_angle, [buf_base_r]
  mov addorsub, 1

sinroutine:
  fmov d11, 3.0  //This is the starting value of the equation
  adrp x0, radianconversion_m
  add x0, x0, :lo12:radianconversion_m
  ldr d15, [x0]
  fmul angle_in_radian, original_angle, d15
  fmov d15, 180.0
  fdiv angle_in_radian, angle_in_radian, d15
  fmov d16, angle_in_radian

callingthesubroutines:
  mov d0, d11
  mov d1, angle_in_radian
  bl tothepower
  mov poly_v, d0   //This is the calculated value of the to power function

  mov d0, d11
  bl factorial
  mov factorial_v, d0

  fdiv d12, poly_v, factorial_v

addorsubcheck:
  cmp addorsub, 1
  b.ne sinadd

  mov addorsub, 0
  fsub angle_in_radian, angle_in_radian, d12
  b  nextsin


sinadd:
  mov addorsub, 1
  fadd angle_in_radian, angle_in_radian, d12

nextsin:
  adrp x0, constant_m
  add x0, x0, :lo12:constant_m
  ldr d15, [x0]
  cmp angle_in_radian, d15
  b.le sinend
  fmov d15, 2.0
  fadd d11, d11, d15
  b callingthesubroutines

sinend:
  mov d11, angle_in_radian

/////////////////
///Start of the cosine part
////////////////
cosinestart:
  mov addorsub, 1
  fmov d11, 2.0  //This is the starting value of the equation
  fmov d12, d16  //d16 has the angle in radian saved from the sine part
  fmov angle_in_radian, 1.0

callingthecossubroutines:
  mov d0, d11
  mov d1, d12
  bl tothepower
  mov poly_v, d0   //This is the calculated value of the to power function

  mov d0, d11
  bl factorial
  mov factorial_v, d0

  fdiv d12, poly_v, factorial_v

addorsubcheck:
  cmp addorsub, 1
  b.ne sinadd

  mov addorsub, 0
  fsub angle_in_radian, angle_in_radian, d12
  b  nextcos


sinadd:
  mov addorsub, 1
  fadd angle_in_radian, angle_in_radian, d12

nextcos:
  adrp x0, constant_m
  add x0, x0, :lo12:constant_m
  ldr d15, [x0]
  cmp angle_in_radian, d15
  b.le cosend
  fmov d15, 2.0
  fadd d11, d11, d15
  b callingthesubroutines

cosend:
  fmov d12, angle_in_radian

printfunction:
  adrp x0, fmt4
  add x0, x0, :lo12:fmt4
  mov d0, d16
  mov d1, d11
  mov d2, d12
  bl printf

  b top

end
  ldrp x29, x30, [sp], 16
  ret








 






/////////////////
//This is the poly_v method
/////////////////
tothepower: 
  stp x29, x30, [sp, -16]!
  mov x29, sp
  mov d8, d0    //This will be the number of times d0 is powered to
  mov d9, d9    //This is the originial angle

toploop:
  fmul d9, d9, d9
  subs d8, d8, 1.0
  cmp d8, 1.0
  b.gt toploop

endofpower:
  mov d0, d9
  ldp x29, x30, [sp], 16
  ret 

/////////////////
//This is the factorial method
/////////////////
factorial:
  stp x29, x30, [sp, -16]!
  mov x29, sp
  fmov d8, d0    //This will be the number of times to multiply by
  fmov d9, d8

toploop:
  fmul d9, d9, d8
  fsub d8, d8, 1.0
  fcmp d8, 1.0
  b.gt toploop

endoffactorial:
  mov d0, d9
  ldp x29, x30, [sp], 16
  ret 
