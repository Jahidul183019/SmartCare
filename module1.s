; ==============================================================================
; SmartCare-32: Module 1 - Patient Record Initialization
; File : module1.s
; Role : Initialize *dynamic* parts of a patient record
;        (vital buffer, alert buffer, flags, billing totals)
;
; NOTE:
;   - Static fields (ID, name_ptr, age, ward, treatment_code,
;     room_daily_rate, medicine_list_ptr, medicine_count, stay_days)
;     are taken from data.s (patient_array) and are NOT modified here.
;   - main.s still pushes many parameters before calling this function,
;     but we safely ignore them and only use R0 = base address of patient.
; ==============================================================================

        PRESERVE8
        THUMB

        AREA    Module1_Code, CODE, READONLY
        EXPORT  patient_record_initialization

; ------------------------------------------------------------------------------
; Patient structure offsets (must match data.s)
; ------------------------------------------------------------------------------
PATIENT_ID_OFF          EQU     0x00
NAME_PTR_OFF            EQU     0x04
AGE_OFF                 EQU     0x08
TREATMENT_CODE_OFF      EQU     0x09
WARD_NUMBER_OFF         EQU     0x0A
ROOM_DAILY_RATE_OFF     EQU     0x0C
MEDICINE_LIST_PTR_OFF   EQU     0x10
MEDICINE_COUNT_OFF      EQU     0x14
ALERT_COUNT_OFF         EQU     0x15
STAY_DAYS_OFF           EQU     0x16
VITAL_BUFFER_OFF        EQU     0x18
VITAL_BUFFER_INDEX_OFF  EQU     0x40
ALERT_FLAG_OFF          EQU     0x41
DOSAGE_DUE_FLAG_OFF     EQU     0x42
ALERT_BUFFER_OFF        EQU     0x44
BILLING_OFF             EQU     0x184

; Vital / Alert / Billing structure info (must match data.s)
VITAL_COUNT             EQU     10      ; 10 entries × 4 bytes = 40 bytes
ALERT_BUFFER_WORDS      EQU     80      ; 320 bytes / 4 = 80 words

TREATMENT_COST_OFF      EQU     0x00
ROOM_COST_OFF           EQU     0x04
MEDICINE_COST_OFF       EQU     0x08
LAB_TEST_COST_OFF       EQU     0x0C   ; we DO NOT modify this (pre-filled in data.s)
TOTAL_BILL_OFF          EQU     0x10
OVERFLOW_FLAG_OFF       EQU     0x14

; ==============================================================================
; FUNCTION: patient_record_initialization
;
; Prototype (as used by main.s):
;   void patient_record_initialization(
;       Patient* base,          ; R0
;       uint32_t id,           ; R1 (unused here)
;       char* name_ptr,        ; R2 (unused)
;       uint8_t age,           ; R3 (unused)
;       uint16_t ward,         ; [SP] etc. (unused)
;       uint8_t treatment,
;       uint32_t room_rate,
;       Medicine* med_list,
;       uint8_t med_count,
;       uint16_t stay_days
;   );
;
; We ONLY use R0 (patient base) and ignore the rest, so data.s remains
; the single source of truth for static fields.
; ==============================================================================
patient_record_initialization PROC
        PUSH    {R4-R7, LR}

        ; R0 = base address of this patient's record in patient_array

        ; ----------------------------------------------------------------------
        ; 1. Initialize per-patient flags/counters (DO NOT touch alert_count)
        ; ----------------------------------------------------------------------
        MOVS    R1, #0

        ; keep ALERT_COUNT_OFF as set in data.s for criticality
        ; STRB  R1, [R0, #ALERT_COUNT_OFF]   ; <-- intentionally commented out

        STRB    R1, [R0, #VITAL_BUFFER_INDEX_OFF]
        STRB    R1, [R0, #ALERT_FLAG_OFF]
        STRB    R1, [R0, #DOSAGE_DUE_FLAG_OFF]

        ; ----------------------------------------------------------------------
        ; 2. Zero billing structure except lab_test_cost
        ; ----------------------------------------------------------------------
        ADD     R2, R0, #BILLING_OFF
        MOVS    R3, #0

        ; treatment_cost, room_cost, medicine_cost
        STR     R3, [R2, #TREATMENT_COST_OFF]
        STR     R3, [R2, #ROOM_COST_OFF]
        STR     R3, [R2, #MEDICINE_COST_OFF]

        ; DO NOT modify LAB_TEST_COST_OFF (pre-filled in data.s)

        ; total_bill, overflow_flag
        STR     R3, [R2, #TOTAL_BILL_OFF]
        STR     R3, [R2, #OVERFLOW_FLAG_OFF]

        ; ----------------------------------------------------------------------
        ; 3. Zero vital_buffer (40 bytes = 10 × 4-byte entries)
        ; ----------------------------------------------------------------------
        ADD     R2, R0, #VITAL_BUFFER_OFF
        MOVS    R1, #VITAL_COUNT
zero_vitals
        STR     R3, [R2], #4            ; store 0 and post-increment
        SUBS    R1, R1, #1
        BNE     zero_vitals

        ; ----------------------------------------------------------------------
        ; 4. Zero alert_buffer (320 bytes = 80 × 4-byte words)
        ; ----------------------------------------------------------------------
        ADD     R2, R0, #ALERT_BUFFER_OFF
        MOVS    R1, #ALERT_BUFFER_WORDS
zero_alerts
        STR     R3, [R2], #4
        SUBS    R1, R1, #1
        BNE     zero_alerts

        ; Done
        POP     {R4-R7, PC}
        ENDP

        ALIGN
        END
