; ==============================================================================
; SmartCare-32: Module 4 - Medicine Administration Scheduler
; File: module4.s
; ==============================================================================

        PRESERVE8
        THUMB
        AREA    Module4_Code, CODE, READONLY

        EXPORT  medicine_administration_scheduler
        IMPORT  system_clock

; ----------------------------------------------------------------------
; Offsets (must match data.s)
; ----------------------------------------------------------------------
MEDICINE_LIST_PTR_OFF   EQU     0x10
MEDICINE_COUNT_OFF      EQU     0x14
DOSAGE_DUE_FLAG_OFF     EQU     0x42

DOSAGE_INTERVAL_OFF     EQU     0x01
LAST_ADMIN_TIME_OFF     EQU     0x04

MEDICINE_SIZE           EQU     16      ; one medicine entry = 16 bytes
SECONDS_PER_HOUR        EQU     3600    ; used for interval × 3600

; ----------------------------------------------------------------------
; void medicine_administration_scheduler(Patient *patient)
; R0 = patient pointer
; ----------------------------------------------------------------------
medicine_administration_scheduler PROC
        PUSH    {R4-R9, LR}

        ; =========================
        ; Load medicine count
        ; =========================
        LDRB    R1, [R0, #MEDICINE_COUNT_OFF]
        CMP     R1, #0
        BEQ     sched_done

        ; =========================
        ; Load medicine list pointer
        ; =========================
        LDR     R2, [R0, #MEDICINE_LIST_PTR_OFF]

        ; Clear DOSAGE_DUE_FLAG
        MOVS    R3, #0
        STRB    R3, [R0, #DOSAGE_DUE_FLAG_OFF]

        MOVS    R4, #0                  ; index = 0

sched_loop
        ; Compute medicine entry address: med_ptr = R2 + i * 16
        ADD     R5, R2, R4, LSL #4

        ; Load last_administered_time
        LDR     R6, [R5, #LAST_ADMIN_TIME_OFF]

        ; Load dosage interval (hours)
        LDRB    R7, [R5, #DOSAGE_INTERVAL_OFF]

        ; Compute next_due_time = last + interval * 3600
        LDR     R8, =SECONDS_PER_HOUR
        MUL     R9, R7, R8
        ADDS    R9, R6, R9

        ; Get current time
        LDR     R8, =system_clock
        LDR     R8, [R8]

        ; Check if current_time >= next_due_time
        CMP     R8, R9
        BLT     not_due

        ; Flag patient as needing medicine
        MOVS    R3, #1
        STRB    R3, [R0, #DOSAGE_DUE_FLAG_OFF]

        ; Update last_administered_time = now
        STR     R8, [R5, #LAST_ADMIN_TIME_OFF]

not_due
        ADDS    R4, R4, #1
        CMP     R4, R1
        BLT     sched_loop

sched_done
        POP     {R4-R9, PC}
        ENDP

        ALIGN
        END
