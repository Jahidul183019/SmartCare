; ==============================================================================
; SmartCare-32: Module 3 — Vital Threshold Alert Module
; File: module3.s
; ==============================================================================

		AREA    Module3_code, CODE, READONLY
        ALIGN   2
        EXPORT  check_vital_thresholds
        THUMB
		IMPORT  system_clock

; Offsets (from your data.s)
VITAL_BUFFER_OFF        EQU     0x18
VITAL_BUFFER_INDEX_OFF  EQU     0x40
ALERT_COUNT_OFF         EQU     0x15
ALERT_FLAG_OFF          EQU     0x41
ALERT_BUFFER_OFF        EQU     0x44

; Alert record and limits
ALERT_RECORD_SIZE       EQU     16
ALERT_BUFFER_MAX        EQU     20      ; as per C code: alert_buffer[20]


        

; void check_vital_thresholds(Patient *patient)
; R0 = patient pointer
check_vital_thresholds
        PUSH    {LR}                ; preserve return address

        ; --- compute index of latest vital entry ---
        LDRB    R1, [R0, #VITAL_BUFFER_INDEX_OFF]    ; R1 = vital_buffer_index (byte)
        CMP     R1, #0
        BNE     index_nonzero
        MOVS    R1, #9
        B       got_index
index_nonzero
        SUBS    R1, R1, #1          ; index = index - 1
got_index

        ; compute base address of vital entry: patient + VITAL_BUFFER_OFF + index*4
        ; each VitalSign is 4 bytes
        LDR     R2, =VITAL_BUFFER_OFF
        LDR     R3, =VITAL_BUFFER_OFF    ; use for addition (we'll add to R0 later)
        ; compute index * 4
        MOV     R4, R1
        LSL     R4, R4, #2            ; R4 = index * 4
        ADD     R4, R4, #VITAL_BUFFER_OFF
        ADD     R4, R0, R4            ; R4 = &patient->vital_buffer[index]

        ; Load current vitals (bytes)
        LDRB    R5, [R4, #0]          ; heart_rate
        LDRB    R6, [R4, #1]          ; oxygen_level
        LDRB    R7, [R4, #2]          ; systolic_bp
        ; diastolic not needed for alerts

        ; Load system_clock into R12 (timestamp)
        LDR     R8, =system_clock
        LDR     R8, [R8]              ; R8 = system_clock

        ; -----------------------------
        ; CHECK HEART RATE > 120
        ; -----------------------------
        MOVS    R9, #0
        CMP     R5, #120
        BLE     check_o2
        ; prepare to create alert with vital_type=0, reading=R5
        MOVS    R9, #0                ; vital_type 0 = HR
        MOV     R10, R5               ; actual reading in R10
        BL      create_alert_record
        ; .create_alert_record returns with no registers guaranteed, continue

; -----------------------------
check_o2
        ; -----------------------------
        ; CHECK O2 < 92
        ; -----------------------------
        CMP     R6, #92
        BGE     check_sbp
        MOVS    R9, #1                ; vital_type = 1 (O2)
        MOV     R10, R6               ; actual reading
        BL      create_alert_record

; -----------------------------
check_sbp
        ; -----------------------------
        ; CHECK SBP > 160 or < 90
        ; -----------------------------
        CMP     R7, #160
        BGT     sbp_high
        CMP     R7, #90
        BGE     done_checks
        ; SBP < 90
sbp_low
        MOVS    R9, #2                ; vital_type = 2 (BP)
        MOV     R10, R7               ; actual reading
        BL      create_alert_record
        B       done_checks

sbp_high
        MOVS    R9, #2                ; vital_type = 2 (BP)
        MOV     R10, R7               ; actual reading
        BL      create_alert_record

done_checks
        ; finished checks
        POP     {PC}                  ; return (BX LR)

; ---------------------------------------------------------
; create_alert_record (internal)
; Inputs before call:
;   R0 = patient pointer (must be preserved across BL)
;   R8 = timestamp (system_clock)
;   R9 = vital_type (0/1/2)
;   R10 = actual reading (byte)
; Clobbers: R1-R7,R11 allowed caller-saved
; ---------------------------------------------------------
create_alert_record
        ; R0 is patient pointer; R9=type, R10=reading, R8=timestamp

        ; Set patient->alert_flag = 1
        MOVS    R11, #1
        STRB    R11, [R0, #ALERT_FLAG_OFF]

        ; Load current alert_count (byte)
        LDRB    R11, [R0, #ALERT_COUNT_OFF]   ; R11 = alert_count

        ; if (alert_count >= ALERT_BUFFER_MAX) return
        CMP     R11, #ALERT_BUFFER_MAX
        BCS     ret_from_create   ; BCS = unsigned >=

        ; compute record address: base + alert_count * ALERT_RECORD_SIZE
        ; compute offset = alert_count * 16 = alert_count << 4
        MOV     R12, R11
        LSL     R12, R12, #4             ; R12 = offset
        ADD     R12, R12, #ALERT_BUFFER_OFF
        ADD     R12, R0, R12             ; R12 = &patient->alert_buffer[alert_count]

        ; Zero first 16 bytes by storing zero words at offsets 0,4,8,12
        MOVS    R1, #0
        STR     R1, [R12, #0]
        STR     R1, [R12, #4]
        STR     R1, [R12, #8]
        STR     R1, [R12, #12]

        ; Store timestamp into bytes 4..7
        STR     R8, [R12, #4]

        ; Store vital_type (byte at offset 0)
        STRB    R9, [R12, #0]

        ; Store actual_reading (byte at offset 1)
        STRB    R10, [R12, #1]

        ; (padding and reserved already zeroed)

        ; increment alert_count and store back (as byte)
        ADDS    R11, R11, #1
        STRB    R11, [R0, #ALERT_COUNT_OFF]

ret_from_create
        BX      LR

        ALIGN   2
			
		

        END

		
