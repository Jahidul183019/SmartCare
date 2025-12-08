; ==============================================================================
; SmartCare-32: Module 3 — Vital Threshold Alert Module
; File: module3.s
; ==============================================================================

        PRESERVE8
        THUMB
        AREA    Module3_Code, CODE, READONLY

        EXPORT  check_vital_thresholds
        IMPORT  system_clock

; ----------------------------------------------------------------------
; Offsets (must match data.s)
; ----------------------------------------------------------------------
VITAL_BUFFER_OFF        EQU     0x18
VITAL_BUFFER_INDEX_OFF  EQU     0x40
ALERT_COUNT_OFF         EQU     0x15
ALERT_FLAG_OFF          EQU     0x41
ALERT_BUFFER_OFF        EQU     0x44

ALERT_RECORD_SIZE       EQU     16
ALERT_BUFFER_MAX        EQU     20

; ----------------------------------------------------------------------
; void check_vital_thresholds(Patient *patient)
; R0 = patient pointer
; ----------------------------------------------------------------------
check_vital_thresholds PROC
        PUSH    {LR}

        ; ----- Load latest buffer index -----
        LDRB    R1, [R0, #VITAL_BUFFER_INDEX_OFF]
        CMP     R1, #0
        BNE     use_prev
        MOVS    R1, #9
        B       ok_idx
use_prev
        SUBS    R1, R1, #1
ok_idx

        ; ----- Compute vital entry address -----
        LSL     R2, R1, #2                  ; index * 4
        ADD     R2, R2, #VITAL_BUFFER_OFF
        ADD     R4, R0, R2                  ; R4 = &patient->vital_buffer[index]

        ; ----- Load vital readings -----
        LDRB    R5, [R4, #0]                ; HR
        LDRB    R6, [R4, #1]                ; O2
        LDRB    R7, [R4, #2]                ; SBP

        ; ----- Load timestamp -----
        LDR     R8, =system_clock
        LDR     R8, [R8]

        ; ============================
        ; HEART RATE CHECK: HR > 120
        ; ============================
        CMP     R5, #120
        BLE     chk_o2
        MOVS    R9, #0                      ; vital_type: HR
        MOV     R10, R5
        BL      create_alert_record

chk_o2
        ; ============================
        ; OXYGEN CHECK: O2 < 92
        ; ============================
        CMP     R6, #92
        BGE     chk_sbp
        MOVS    R9, #1                      ; vital_type: O2
        MOV     R10, R6
        BL      create_alert_record

chk_sbp
        ; ============================
        ; SYSTOLIC BP CHECK
        ; >160   OR   <90
        ; ============================
        CMP     R7, #160
        BGT     sbp_alert
        CMP     R7, #90
        BGE     done
sbp_alert
        MOVS    R9, #2                      ; vital_type: BP
        MOV     R10, R7
        BL      create_alert_record

done
        POP     {PC}
        ENDP


; ----------------------------------------------------------------------
; INTERNAL FUNCTION: create_alert_record()
; Inputs:
;   R0 = patient pointer
;   R8 = timestamp
;   R9 = vital_type (0=HR, 1=O2, 2=BP)
;   R10 = reading
; ----------------------------------------------------------------------
create_alert_record PROC
        ; set alert flag = 1
        MOVS    R1, #1
        STRB    R1, [R0, #ALERT_FLAG_OFF]

        ; load alert_count
        LDRB    R11, [R0, #ALERT_COUNT_OFF]
        CMP     R11, #ALERT_BUFFER_MAX
        BCS     alert_ret                 ; full ? skip

        ; compute address: alert_buffer + count*16
        LSL     R12, R11, #4              ; *16
        ADD     R12, R12, #ALERT_BUFFER_OFF
        ADD     R12, R0, R12              ; R12 = record addr

        ; Zero record (16 bytes)
        MOVS    R1, #0
        STR     R1, [R12, #0]
        STR     R1, [R12, #4]
        STR     R1, [R12, #8]
        STR     R1, [R12, #12]

        ; Fill record
        STRB    R9,  [R12, #0]            ; vital_type
        STRB    R10, [R12, #1]            ; reading
        STR     R8,  [R12, #4]            ; timestamp

        ; increment alert count
        ADDS    R11, R11, #1
        STRB    R11, [R0, #ALERT_COUNT_OFF]

alert_ret
        BX      LR
        ENDP

        ALIGN
        END
