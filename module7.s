; ==============================================================================
; SmartCare-32: Module 7 — Medicine Billing Module
; File: module7.s
; ==============================================================================
;
; void medicine_billing_module(Patient *patient)
;   R0 = pointer to Patient structure
;
; For each medicine:
;   total += unit_price * quantity * stay_days
; Stores result in patient->billing.medicine_cost
; ==============================================================================

        PRESERVE8
        THUMB

        AREA    Module7_Code, CODE, READONLY
        EXPORT  medicine_billing_module

; ---------------------------
; Offsets from data.s
; ---------------------------

; Medicine layout (16 bytes)
MED_ID_OFF             EQU     0x00
DOSAGE_INTERVAL_OFF    EQU     0x01
LAST_ADMIN_TIME_OFF    EQU     0x04   ; 4-byte aligned
UNIT_PRICE_OFF         EQU     0x08   ; 4-byte aligned
QUANTITY_OFF           EQU     0x0C
MED_PADDING_OFF        EQU     0x0E
MEDICINE_SIZE          EQU     0x10   ; 16 bytes total

; Patient structure fields
MEDICINE_LIST_PTR_OFF  EQU     0x10
MEDICINE_COUNT_OFF     EQU     0x14
STAY_DAYS_OFF          EQU     0x16

; Billing structure
BILLING_OFF            EQU     0x184
MEDICINE_COST_OFF      EQU     0x08   ; billing.medicine_cost


; ------------------------------------------------------------------------------
; FUNCTION: medicine_billing_module
;   R0 = Patient*
; ------------------------------------------------------------------------------
medicine_billing_module PROC
        PUSH    {r4-r7, lr}

        ; R0 = patient*
        LDRB    r1, [r0, #MEDICINE_COUNT_OFF]   ; r1 = medicine_count
        CMP     r1, #0
        BEQ     mb_zero                         ; no medicines ? cost = 0

        LDR     r2, [r0, #MEDICINE_LIST_PTR_OFF] ; r2 = med list base
        LDRH    r3, [r0, #STAY_DAYS_OFF]         ; r3 = stay_days

        MOVS    r4, #0                           ; r4 = total_cost
        MOVS    r5, #0                           ; r5 = index (i)

mb_loop
        ; r6 = med_ptr = base + i * MEDICINE_SIZE (16 bytes)
        MOV     r6, r5
        LSLS    r6, r6, #4                        ; i * 16
        ADDS    r6, r6, r2                        ; med_ptr

        ; Load unit_price (u32) and quantity (u16)
        LDR     r7, [r6, #UNIT_PRICE_OFF]         ; r7 = unit_price
        LDRH    r6, [r6, #QUANTITY_OFF]           ; r6 = quantity

        ; cost_for_med = unit_price * quantity * stay_days
        MUL     r7, r7, r6                        ; unit_price * qty
        MUL     r7, r7, r3                        ; * stay_days

        ADDS    r4, r4, r7                        ; total_cost += med_cost

        ADDS    r5, r5, #1
        CMP     r5, r1
        BLT     mb_loop

        ; Store total_cost into billing.medicine_cost
        ADD     r6, r0, #BILLING_OFF
        STR     r4, [r6, #MEDICINE_COST_OFF]

        POP     {r4-r7, pc}

mb_zero
        ; If no medicines, store 0 in billing.medicine_cost
        ADD     r6, r0, #BILLING_OFF
        MOVS    r4, #0
        STR     r4, [r6, #MEDICINE_COST_OFF]
        POP     {r4-r7, pc}
        ENDP

        ALIGN
        END
