.global _boot
.text

_boot:

loop1:
    beq x0, x0, loop2 # Jump unconditionally to loop2

loop2:
    beq x0, x0, loop1 # Jump unconditionally to loop1

.data
variable:
    .word 0xdeadbeef
