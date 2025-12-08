; ==============================================================================
; SmartCare-32: Module 8 — Patient Bill Aggregator
; File: module8.s
; ==============================================================================

        PRESERVE8
        THUMB

        AREA    Module8_Code, CODE, READONLY
        ALIGN   2

        EXPORT  aggregate_total_bill

; ------------------------------------------------------------------------------
; Offsets (must match data.s Billing layout)
; ------------------------------------------------------------------------------
BILLING_OFF             EQU     0x184   ; patient->billing
TREATMENT_COST_OFF      EQU     0x00   ; billing.treatment_cost
ROOM_COST_OFF           EQU     0x04   ; billing.room_cost
MEDICINE_COST_OFF       EQU     0x08   ; billing.medicine_cost
LAB_TEST_COST_OFF       EQU     0x0C   ; billing.lab_test_cost
TOTAL_BILL_OFF          EQU     0x10   ; billing.total_bill
OVERFLOW_FLAG_OFF       EQU     0x14   ; billing.overflow_flag (byte)

; ==============================================================================
; void aggregate_total_bill(Patient *patient)
;   R0 = pointer to Patient
; ==============================================================================
aggregate_total_bill PROC
        PUSH    {R4-R5, LR}

        ; Load billing fields (unsigned 32-bit)
        LDR     R1, [R0, #BILLING_OFF + TREATMENT_COST_OFF]   ; treatment_cost
        LDR     R2, [R0, #BILLING_OFF + ROOM_COST_OFF]        ; room_cost
        LDR     R3, [R0, #BILLING_OFF + MEDICINE_COST_OFF]    ; medicine_cost
        LDR     R4, [R0, #BILLING_OFF + LAB_TEST_COST_OFF]    ; lab_test_cost

        ; ---------------------------------------------------
        ; total = treatment + room (with overflow check)
        ; ---------------------------------------------------
        ADDS    R5, R1, R2            ; R5 = t + r   (ADDS sets flags)
        CMP     R5, R1                ; if result < operand -> overflow
        BCC     overflow_detected

        ; ---------------------------------------------------
        ; total += medicine
        ; ---------------------------------------------------
        ADDS    R5, R5, R3
        CMP     R5, R3
        BCC     overflow_detected

        ; ---------------------------------------------------
        ; total += lab tests
        ; ---------------------------------------------------
        ADDS    R5, R5, R4
        CMP     R5, R4
        BCC     overflow_detected

        ; ---------------------------------------------------
        ; No overflow: store total and clear overflow flag
        ; ---------------------------------------------------
        STR     R5, [R0, #BILLING_OFF + TOTAL_BILL_OFF]
        MOVS    R1, #0
        STRB    R1, [R0, #BILLING_OFF + OVERFLOW_FLAG_OFF]
        B       done

overflow_detected
        ; On overflow: total_bill = 0xFFFFFFFF, overflow_flag = 1
        LDR     R1, =0xFFFFFFFF
        STR     R1, [R0, #BILLING_OFF + TOTAL_BILL_OFF]
        MOVS    R1, #1
        STRB    R1, [R0, #BILLING_OFF + OVERFLOW_FLAG_OFF]

done
        POP     {R4-R5, PC}
        ENDP

        ALIGN   2
        END
