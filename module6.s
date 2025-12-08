; ==============================================================================
; SmartCare-32: Module 6 — Daily Room Rent Calculation
; File: module6.s
; ==============================================================================

        PRESERVE8
        THUMB

        AREA    Module6_Code, CODE, READONLY
        EXPORT  compute_room_cost

; Offsets from data.s
ROOM_DAILY_RATE_OFF     EQU     0x0C
STAY_DAYS_OFF           EQU     0x16
BILLING_OFF             EQU     0x184
ROOM_COST_OFF           EQU     0x04      ; billing.room_cost

; Constants
DISCOUNT_THRESHOLD      EQU     10
DISCOUNT_PERCENT        EQU     95        ; multiply by 95 then /100

; ------------------------------------------------------------------------------
; void compute_room_cost(Patient *patient)
;    R0 = patient pointer
; ------------------------------------------------------------------------------
compute_room_cost PROC
        PUSH    {lr}

        ; Load daily room rate (u32)
        LDR     r1, [r0, #ROOM_DAILY_RATE_OFF]

        ; Load stay_days (u16)
        LDRH    r2, [r0, #STAY_DAYS_OFF]

        ; cost = rate * days
        MUL     r3, r1, r2

        ; if days <= 10 ? skip discount
        CMP     r2, #DISCOUNT_THRESHOLD
        BLE     no_discount

        ; Apply 5% discount ? cost = cost * 95 / 100
        MOVS    r1, #DISCOUNT_PERCENT
        MUL     r3, r3, r1
        MOVS    r1, #100
        UDIV    r3, r3, r1

no_discount
        ; Store in billing.room_cost
        ADD     r1, r0, #BILLING_OFF
        STR     r3, [r1, #ROOM_COST_OFF]

        POP     {pc}
        ENDP

        ALIGN
        END
