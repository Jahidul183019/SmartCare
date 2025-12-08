; ==============================================================================
; SmartCare-32: Module 5 - Treatment Cost Computation
; File: module5.s
; ==============================================================================

        PRESERVE8
        THUMB

        AREA    Module5_Code, CODE, READONLY

        EXPORT  compute_treatment_cost
        IMPORT  treatment_cost_table

; ------------------------------------------------------------------------------
; Offsets (must match data.s)
; ------------------------------------------------------------------------------
TREATMENT_CODE_OFF      EQU     0x09    ; Patient.treatment_code (u8)
BILLING_OFF             EQU     0x184   ; Patient.billing
TREATMENT_COST_OFF      EQU     0x00    ; Billing.treatment_cost (u32)

; ------------------------------------------------------------------------------
; void compute_treatment_cost(Patient *patient)
;   R0 = pointer to Patient structure
; ------------------------------------------------------------------------------
compute_treatment_cost PROC
        PUSH    {r4, lr}

        MOV     r4, r0                      ; r4 = patient pointer

        ; --- read treatment_code (0..15) from patient ---
        LDRB    r1, [r4, #TREATMENT_CODE_OFF]

        ; if (code >= 16) -> cost = 0
        CMP     r1, #16
        BHS     invalid_code

        ; cost = treatment_cost_table[code]
        LDR     r0, =treatment_cost_table
        LSL     r2, r1, #2                  ; code * 4
        ADD     r0, r0, r2
        LDR     r3, [r0]                    ; r3 = cost
        B       store_cost

invalid_code
        MOVS    r3, #0                      ; invalid code ? cost = 0

store_cost
        ; patient->billing.treatment_cost = cost
        ADD     r0, r4, #BILLING_OFF
        STR     r3, [r0, #TREATMENT_COST_OFF]

        POP     {r4, pc}
        ENDP

        ALIGN
        END
