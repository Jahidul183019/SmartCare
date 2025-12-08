; ==============================================================================
; SmartCare-32: Module 9 - Sort Patients by Criticality
; File: module9.s
; ==============================================================================
        PRESERVE8
        THUMB

        AREA    Module9Code, CODE, READONLY
        ALIGN   4

        EXPORT  sort_patients_by_criticality

; ------------------------------------------------------------------------------
; CONSTANTS (must match data.s)
; ------------------------------------------------------------------------------
PATIENT_SIZE        EQU     412     ; Size of Patient structure in bytes
ALERT_COUNT_OFF     EQU     0x15    ; Offset to alert_count in Patient


; ==============================================================================
; void sort_patients_by_criticality(Patient *base, uint32_t count)
;   R0 = pointer to first Patient (patient_array)
;   R1 = count (number of patients)
; Sort order: descending by alert_count
; ==============================================================================
sort_patients_by_criticality PROC
        PUSH    {R4-R11, LR}            ; Preserve registers

        ; If count < 2, nothing to sort
        CMP     R1, #2
        BLT     sort_done

        MOV     R4, R0                  ; R4 = base pointer (patient_array)
        MOV     R5, R1                  ; R5 = count

; ------------------------------------------------------------------------------
; Outer loop (bubble sort)
; ------------------------------------------------------------------------------
outer_loop
        MOVS    R6, #0                  ; swapped flag = 0
        MOVS    R7, #0                  ; i = 0
        SUBS    R8, R5, #1              ; last index = count - 1

inner_loop
        CMP     R7, R8
        BGE     check_swapped           ; if (i >= last) break inner loop

        ; ----------------------------------------------------------
        ; Compute address of patients[i]  -> R9
        ; ----------------------------------------------------------
        MOV     R9, R7                  ; index i
        MOVW    R10, #PATIENT_SIZE      ; 412
        MUL     R9, R9, R10             ; i * 412
        ADD     R9, R4, R9              ; &patients[i]

        ; ----------------------------------------------------------
        ; Compute address of patients[i+1] -> R11
        ; ----------------------------------------------------------
        ADD     R11, R7, #1             ; i + 1
        MUL     R11, R11, R10           ; (i+1) * 412
        ADD     R11, R4, R11            ; &patients[i+1]

        ; ----------------------------------------------------------
        ; Compare alert_count of the two patients
        ; If patients[i].alert_count < patients[i+1].alert_count -> swap
        ; ----------------------------------------------------------
        LDRB    R0, [R9,  #ALERT_COUNT_OFF] ; alert_count(i)
        LDRB    R1, [R11, #ALERT_COUNT_OFF] ; alert_count(i+1)

        CMP     R0, R1
        BGE     no_swap                 ; already in correct order

        ; ----------------------------------------------------------
        ; SWAP entire 412-byte structures word-by-word (103 words)
        ; ----------------------------------------------------------
        PUSH    {R4-R8}                 ; save loop state

        MOVS    R2, #103                ; 412 / 4 = 103 words
        MOVS    R3, #0                  ; byte offset in steps of 4

swap_loop
        LDR     R4, [R9,  R3]           ; word from patients[i]
        LDR     R5, [R11, R3]           ; word from patients[i+1]
        STR     R5, [R9,  R3]           ; store into patients[i]
        STR     R4, [R11, R3]           ; store into patients[i+1]

        ADDS    R3, R3, #4              ; next word
        SUBS    R2, R2, #1
        BNE     swap_loop

        POP     {R4-R8}                 ; restore loop state

        MOVS    R6, #1                  ; swapped = 1

no_swap
        ADDS    R7, R7, #1              ; i++
        B       inner_loop

; ------------------------------------------------------------------------------
; If no swaps were done in this pass, array is sorted
; ------------------------------------------------------------------------------
check_swapped
        CMP     R6, #0
        BNE     outer_loop              ; if swapped != 0, another pass

sort_done
        POP     {R4-R11, PC}
        ENDP

        ALIGN
        END
