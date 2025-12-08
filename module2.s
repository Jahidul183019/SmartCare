; ==============================================================================
; SmartCare-32: Module 2 - Vital Sign Data Acquisition
; File: module2.s
; ==============================================================================

        PRESERVE8
        THUMB

        AREA    Module2_Code, CODE, READONLY
        
        EXPORT  acquire_vital_signs

; ==============================================================================
; IMPORTS (from data.s)
; ==============================================================================
        IMPORT  SENSOR_HR
        IMPORT  SENSOR_O2
        IMPORT  SENSOR_SBP
        IMPORT  SENSOR_DBP

; ==============================================================================
; CONSTANTS (must match data.s patient layout)
; ==============================================================================
VITAL_BUFFER_OFF        EQU     0x18    ; Offset to vital_buffer[] in Patient
VITAL_BUFFER_INDEX_OFF  EQU     0x40    ; Offset to vital_buffer_index
VITAL_SIZE              EQU     4       ; 4 bytes per VitalSign
VITAL_COUNT             EQU     10      ; 10 entries per buffer

; ==============================================================================
; FUNCTION: acquire_vital_signs
; Description:
;   - Reads simulated sensor values
;   - Stores into patient.vital_buffer as a circular buffer (10 entries)
;
; Parameters:
;   R0 = pointer to Patient structure (e.g., &patient_array[i])
;
; Clobbers:
;   R0-R7
; ==============================================================================
acquire_vital_signs PROC
        PUSH    {R4-R7, LR}             ; preserve caller-saved regs
        
        MOV     R4, R0                  ; R4 = patient pointer

        ; ----------------------------------------------------------------------
        ; STEP 1: Read sensor values
        ; ----------------------------------------------------------------------
        LDR     R0, =SENSOR_HR
        LDRB    R5, [R0]                ; R5 = HR

        LDR     R0, =SENSOR_O2
        LDRB    R6, [R0]                ; R6 = O2

        LDR     R0, =SENSOR_SBP
        LDRB    R7, [R0]                ; R7 = SBP

        LDR     R0, =SENSOR_DBP
        LDRB    R3, [R0]                ; R3 = DBP

        ; ----------------------------------------------------------------------
        ; STEP 2: Load current index
        ;   idx = patient->vital_buffer_index
        ; ----------------------------------------------------------------------
        ADD     R0, R4, #VITAL_BUFFER_INDEX_OFF
        LDRB    R1, [R0]                ; R1 = idx (0..9)

        ; ----------------------------------------------------------------------
        ; STEP 3: Compute address of vital_buffer[idx]
        ;   offset = VITAL_BUFFER_OFF + idx * VITAL_SIZE
        ; ----------------------------------------------------------------------
        LSL     R2, R1, #2              ; idx * 4
        ADD     R2, R2, #VITAL_BUFFER_OFF
        ADD     R0, R4, R2              ; R0 = &patient->vital_buffer[idx]

        ; ----------------------------------------------------------------------
        ; STEP 4: Store one VitalSign (4 bytes)
        ;   [0] = HR
        ;   [1] = O2
        ;   [2] = SBP
        ;   [3] = DBP
        ; ----------------------------------------------------------------------
        STRB    R5, [R0, #0]
        STRB    R6, [R0, #1]
        STRB    R7, [R0, #2]
        STRB    R3, [R0, #3]

        ; ----------------------------------------------------------------------
        ; STEP 5: idx = (idx + 1) % VITAL_COUNT
        ; ----------------------------------------------------------------------
        ADDS    R1, R1, #1
        CMP     R1, #VITAL_COUNT
        BLT     no_wrap
        MOVS    R1, #0
no_wrap
        ; ----------------------------------------------------------------------
        ; STEP 6: Write back updated index
        ; ----------------------------------------------------------------------
        ADD     R0, R4, #VITAL_BUFFER_INDEX_OFF
        STRB    R1, [R0]

        POP     {R4-R7, PC}
        ENDP

        ALIGN
        END
