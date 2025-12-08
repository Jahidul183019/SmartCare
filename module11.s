; ==============================================================================
; SmartCare-32: Module 11 - System Error Detection & Logging
; File       : module11.s
; Target     : ARM Cortex-M4 (Keil uVision)
;
; Responsibilities:
;   - Detect sensor malfunction (stuck values)
;   - Detect invalid medicine dosage (zero price / zero quantity)
;   - Detect memory / billing overflow conditions
;   - Log structured error records in an "error_log_buffer"
;   - Maintain global error_flag and error_count
;   - Print a human-readable error log over ITM (UART-like)
; ==============================================================================

        PRESERVE8
        THUMB
        
; ==============================================================================
; DATA SECTION - Error Printing Strings
; ==============================================================================
        AREA    Module11Data, DATA, READWRITE

; Line break for error output
nl_err      DCB     0x0A, 0

; Error log headers
err_hdr1    DCB     "==================================================", 0
err_hdr2    DCB     "           SYSTEM ERROR LOG", 0

; Summary labels
err_total   DCB     "Total Errors: ", 0
err_div     DCB     "--------------------------------------------------", 0
err_no      DCB     "Error #", 0
err_type_l  DCB     "  Type: ", 0

; Error type names
err_sensor  DCB     "SENSOR MALFUNCTION", 0
err_dosage  DCB     "INVALID DOSAGE", 0
err_memory  DCB     "MEMORY OVERFLOW", 0

; Sensor-related labels and names
err_sens_l  DCB     "  Sensor: ", 0
sens_hr     DCB     "Heart Rate", 0
sens_o2     DCB     "Oxygen", 0
sens_bp     DCB     "Blood Pressure", 0

; Value / issue labels
err_val_l   DCB     "  Stuck Value: ", 0
err_issue   DCB     "  Issue: ", 0
iss_price   DCB     "Zero Unit Price", 0
iss_qty     DCB     "Zero Quantity", 0
err_med_l   DCB     "  Medicine Index: ", 0

; Memory error labels
err_code_l  DCB     "  Code: ", 0
code_addr   DCB     "Address Boundary", 0
code_bill   DCB     "Billing Overflow", 0
err_val2_l  DCB     "  Value: 0x", 0

; Common metadata labels
err_pid_l   DCB     "  Patient ID: ", 0
err_time_l  DCB     "  Timestamp: ", 0
err_sec     DCB     " sec", 0

; No-error message
no_err_msg  DCB     "[NO ERRORS DETECTED]", 0

; Scratch buffer for integer printing
int_buf     DCB     "                      ", 0


; ==============================================================================
; CODE SECTION
; ==============================================================================
        AREA    Module11Code, CODE, READONLY
        
        EXPORT  check_sensor_malfunction
        EXPORT  check_invalid_dosage
        EXPORT  check_memory_overflow
        EXPORT  log_error_to_flash
        EXPORT  get_error_count
        EXPORT  Print_Error_Log

; ==============================================================================
; IMPORTS
; ==============================================================================
        IMPORT  system_clock
        IMPORT  error_flag
        IMPORT  error_log_buffer
        IMPORT  error_count
        IMPORT  sensor_history
        IMPORT  sensor_history_index
        IMPORT  SENSOR_HR
        IMPORT  SENSOR_O2
        IMPORT  SENSOR_SBP
        IMPORT  SENSOR_DBP
        IMPORT  patient_array
        IMPORT  ITM_SendChar_C

; ==============================================================================
; CONSTANTS
; ==============================================================================
ERROR_SENSOR_MALFUNCTION    EQU     0x01
ERROR_INVALID_DOSAGE        EQU     0x02
ERROR_MEMORY_OVERFLOW       EQU     0x03

ERROR_RECORD_SIZE           EQU     16
MAX_ERROR_RECORDS           EQU     50

; Patient medicine layout
MEDICINE_LIST_PTR_OFF       EQU     0x10
MEDICINE_COUNT_OFF          EQU     0x14
UNIT_PRICE_OFF              EQU     0x08
QUANTITY_OFF                EQU     0x0C
MEDICINE_SIZE               EQU     0x10

; Patient bounds & billing
PATIENT_ARRAY_MAX           EQU     0x20000100
BILLING_OFF                 EQU     0x184
TOTAL_BILL_OFF              EQU     0x10
PATIENT_ID_OFF              EQU     0x00


; ==============================================================================
; FUNCTION: check_sensor_malfunction
;   R0 = patient_index (0..2)
;   Returns:
;       R0 = 1 if malfunction detected & logged
;       R0 = 0 otherwise
;
;   Sensor history model:
;       sensor_history is grouped in blocks of 10 bytes per sensor:
;         [0..9]   : HR history
;         [10..19] : O2 history
;         [20..29] : SBP history
;       sensor_history_index holds write index (0..9).
;   If all 10 values in a sensor history are equal ? malfunction.
; ==============================================================================
check_sensor_malfunction PROC
        PUSH    {R4-R11, LR}
        
        MOV     R10, R0                    ; R10 = patient_index
        
        ; Read current sensor values (bytes)
        LDR     R0, =SENSOR_HR
        LDRB    R4, [R0]                   ; HR
        
        LDR     R0, =SENSOR_O2
        LDRB    R5, [R0]                   ; O2
        
        LDR     R0, =SENSOR_SBP
        LDRB    R6, [R0]                   ; SBP
        
        LDR     R0, =SENSOR_DBP
        LDRB    R7, [R0]                   ; DBP
        
        ; Update sensor history ring buffer
        LDR     R8, =sensor_history_index
        LDRB    R9, [R8]                   ; current index
        
        LDR     R0, =sensor_history
        STRB    R4, [R0, R9]               ; HR history
        ADD     R0, R0, #10
        STRB    R5, [R0, R9]               ; O2 history
        ADD     R0, R0, #10
        STRB    R6, [R0, R9]               ; SBP history
        ADD     R0, R0, #10
        STRB    R7, [R0, R9]               ; DBP history
        
        ; Increment index (mod 10)
        ADD     R9, R9, #1
        CMP     R9, #10
        IT      HS
        MOVHS   R9, #0
        STRB    R9, [R8]
        
        ; ---------------- HR malfunction check ----------------
        LDR     R0, =sensor_history
        LDRB    R1, [R0]                   ; reference value
        MOV     R2, #1
        
check_hr_loop
        CMP     R2, #10
        BGE     hr_malfunction             ; all 10 equal
        
        LDRB    R3, [R0, R2]
        CMP     R1, R3
        BNE     check_o2                   ; mismatch ? no HR malfunction
        
        ADD     R2, R2, #1
        B       check_hr_loop
        
hr_malfunction
        ; Log HR sensor malfunction
        MOV     R0, #ERROR_SENSOR_MALFUNCTION
        MOV     R1, R10                    ; patient_index
        MOV     R2, #1                     ; sensor_code = HR
        MOV     R3, R4                     ; stuck value
        BL      log_error_to_flash
        MOV     R0, #1
        B       csm_done
        
        ; ---------------- O2 malfunction check ----------------
check_o2
        LDR     R0, =sensor_history
        ADD     R0, R0, #10                ; O2 history block
        LDRB    R1, [R0]
        MOV     R2, #1
        
check_o2_loop
        CMP     R2, #10
        BGE     o2_malfunction
        
        LDRB    R3, [R0, R2]
        CMP     R1, R3
        BNE     check_sbp
        
        ADD     R2, R2, #1
        B       check_o2_loop
        
o2_malfunction
        MOV     R0, #ERROR_SENSOR_MALFUNCTION
        MOV     R1, R10                    ; patient_index
        MOV     R2, #2                     ; sensor_code = O2
        MOV     R3, R5                     ; stuck value
        BL      log_error_to_flash
        MOV     R0, #1
        B       csm_done
        
        ; --------------- SBP malfunction check ----------------
check_sbp
        LDR     R0, =sensor_history
        ADD     R0, R0, #20                ; SBP block
        LDRB    R1, [R0]
        MOV     R2, #1
        
check_sbp_loop
        CMP     R2, #10
        BGE     sbp_malfunction
        
        LDRB    R3, [R0, R2]
        CMP     R1, R3
        BNE     no_malfunction
        
        ADD     R2, R2, #1
        B       check_sbp_loop
        
sbp_malfunction
        MOV     R0, #ERROR_SENSOR_MALFUNCTION
        MOV     R1, R10                    ; patient_index
        MOV     R2, #3                     ; sensor_code = BP
        MOV     R3, R6                     ; stuck value
        BL      log_error_to_flash
        MOV     R0, #1
        B       csm_done
        
no_malfunction
        MOV     R0, #0                     ; no error
        
csm_done
        POP     {R4-R11, PC}
        LTORG
        ENDP


; ==============================================================================
; FUNCTION: check_invalid_dosage
;   R0 = pointer to Patient structure
;   R1 = patient_index
;   Returns:
;       R0 = 1 if invalid dosage found & logged
;       R0 = 0 otherwise
;
;   Checks each medicine entry:
;       - Unit price == 0  ? issue_code 1 (Zero Unit Price)
;       - Quantity == 0    ? issue_code 2 (Zero Quantity)
; ==============================================================================
check_invalid_dosage PROC
        PUSH    {R4-R9, LR}
        
        MOV     R8, R0                    ; patient*
        MOV     R9, R1                    ; patient_index
        
        ; medicine_count
        LDRB    R4, [R8, #MEDICINE_COUNT_OFF]
        CMP     R4, #0
        BEQ     cid_no_error
        
        ; medicine_list pointer
        LDR     R5, [R8, #MEDICINE_LIST_PTR_OFF]
        CMP     R5, #0
        BEQ     cid_no_error
        
        MOV     R6, #0                    ; medicine index
        
cid_loop
        ; R7 = &medicine_list[i]
        MOV     R0, R6
        MOV     R1, #MEDICINE_SIZE
        MUL     R0, R0, R1
        ADD     R7, R5, R0
        
        ; Check unit price == 0
        LDR     R0, [R7, #UNIT_PRICE_OFF]
        CMP     R0, #0
        BEQ     cid_invalid_price
        
        ; Check quantity == 0
        LDRH    R1, [R7, #QUANTITY_OFF]
        CMP     R1, #0
        BEQ     cid_invalid_quantity
        
        ; Next medicine
        ADD     R6, R6, #1
        CMP     R6, R4
        BLT     cid_loop
        B       cid_no_error
        
cid_invalid_price
        MOV     R0, #ERROR_INVALID_DOSAGE
        MOV     R1, R9                    ; patient_index
        MOV     R2, #1                    ; issue_code = price
        MOV     R3, R6                    ; medicine_index
        BL      log_error_to_flash
        MOV     R0, #1
        B       cid_done
        
cid_invalid_quantity
        MOV     R0, #ERROR_INVALID_DOSAGE
        MOV     R1, R9                    ; patient_index
        MOV     R2, #2                    ; issue_code = quantity
        MOV     R3, R6                    ; medicine_index
        BL      log_error_to_flash
        MOV     R0, #1
        B       cid_done
        
cid_no_error
        MOV     R0, #0
        
cid_done
        POP     {R4-R9, PC}
        ENDP


; ==============================================================================
; FUNCTION: check_memory_overflow
;   R0 = pointer to Patient structure
;   R1 = patient_index
;   Returns:
;       R0 = 1 if error & logged
;       R0 = 0 otherwise
;
;   Two checks:
;     - If patient pointer >= PATIENT_ARRAY_MAX ? address boundary error
;     - If total_bill >= 0xF0000000 ? billing overflow error
; ==============================================================================
check_memory_overflow PROC
        PUSH    {R4-R6, LR}
        
        MOV     R4, R0                    ; patient*
        MOV     R5, R1                    ; patient_index
        
        ; Address boundary check
        LDR     R6, =PATIENT_ARRAY_MAX
        CMP     R4, R6
        BHS     cmo_overflow
        
        ; Billing overflow check: total_bill at patient + BILLING_OFF + TOTAL_BILL_OFF
        ADD     R0, R4, #BILLING_OFF
        ADD     R0, R0, #TOTAL_BILL_OFF
        LDR     R1, [R0]                  ; total_bill
        
        LDR     R2, =0xF0000000
        CMP     R1, R2
        BHS     cmo_billing_overflow
        
        MOV     R0, #0
        B       cmo_done
        
cmo_overflow
        MOV     R0, #ERROR_MEMORY_OVERFLOW
        MOV     R1, R5                    ; patient_index
        MOV     R2, #1                    ; code = address boundary
        MOV     R3, R4                    ; offending address
        BL      log_error_to_flash
        MOV     R0, #1
        B       cmo_done
        
cmo_billing_overflow
        MOV     R0, #ERROR_MEMORY_OVERFLOW
        MOV     R1, R5                    ; patient_index
        MOV     R2, #2                    ; code = billing overflow
        MOV     R3, R1                    ; offending value
        BL      log_error_to_flash
        MOV     R0, #1
        
cmo_done
        POP     {R4-R6, PC}
        LTORG
        ENDP


; ==============================================================================
; FUNCTION: log_error_to_flash
;   R0 = error_type (1,2,3)
;   R1 = patient_index
;   R2 = subtype / sensor / issue code
;   R3 = extra data (stuck value, med index, address, etc.)
;
;   Side effects:
;   - Sets error_flag = 1
;   - Appends record to error_log_buffer if error_count < MAX_ERROR_RECORDS
;   - Record layout (16 bytes):
;       +0 : error_type (byte)
;       +1 : patient_index (byte)
;       +2 : sub_code (byte)
;       +3 : reserved
;       +4 : timestamp (system_clock, 4 bytes)
;       +8 : extra_data (4 bytes)
;       +12: patient_id (4 bytes)
; ==============================================================================
log_error_to_flash PROC
        PUSH    {R4-R8, LR}
        
        ; Preserve arguments
        MOV     R4, R0                    ; error_type
        MOV     R5, R1                    ; patient_index
        MOV     R6, R2                    ; code
        MOV     R7, R3                    ; extra
        
        ; Set global error_flag = 1
        LDR     R0, =error_flag
        MOV     R1, #1
        STR     R1, [R0]
        
        ; Load current error_count
        LDR     R0, =error_count
        LDR     R1, [R0]
        CMP     R1, #MAX_ERROR_RECORDS
        BGE     letf_full                 ; buffer full ? ignore
        
        ; Compute record address
        MOV     R2, #ERROR_RECORD_SIZE
        MUL     R3, R1, R2
        LDR     R8, =error_log_buffer
        ADD     R8, R8, R3
        
        ; Fill record header bytes
        STRB    R4, [R8, #0]              ; error_type
        STRB    R5, [R8, #1]              ; patient_index
        STRB    R6, [R8, #2]              ; sub_code
        
        ; Timestamp from system_clock at offset +4
        LDR     R2, =system_clock
        LDR     R2, [R2]
        STR     R2, [R8, #4]
        
        ; Extra data at offset +8
        STR     R7, [R8, #8]
        
        ; Patient ID at offset +12
        LDR     R2, =patient_array
        MOV     R3, #412
        MUL     R3, R5, R3
        ADD     R2, R2, R3
        LDR     R2, [R2, #PATIENT_ID_OFF]
        STR     R2, [R8, #12]
        
        ; Increment error_count
        ADD     R1, R1, #1
        STR     R1, [R0]
        
letf_full
        POP     {R4-R8, PC}
        LTORG
        ENDP


; ==============================================================================
; FUNCTION: get_error_count
;   Returns:
;       R0 = current error_count
; ==============================================================================
get_error_count PROC
        LDR     R0, =error_count
        LDR     R0, [R0]
        BX      LR
        LTORG
        ENDP


; ==============================================================================
; FUNCTION: Print_Error_Log
;   Prints all logged errors over ITM in a formatted way.
;   Uses:
;       PrintErrString, PrintErrInt helpers
; ==============================================================================
Print_Error_Log PROC
        PUSH    {r4-r7, lr}
        PUSH    {r9-r11}
        
        ; Load error_count into r10
        LDR     r0, =error_count
        LDR     r10, [r0]
        
        ; If no errors ? print "[NO ERRORS DETECTED]"
        CMP     r10, #0
        BEQ.W   no_errors_detected
        
        ; Print header
        LDR     r0, =nl_err
        BL      PrintErrString
        LDR     r0, =nl_err
        BL      PrintErrString
        
        LDR     r0, =err_hdr1
        BL      PrintErrString
        LDR     r0, =nl_err
        BL      PrintErrString
        
        LDR     r0, =err_hdr2
        BL      PrintErrString
        LDR     r0, =nl_err
        BL      PrintErrString
        
        LDR     r0, =err_hdr1
        BL      PrintErrString
        LDR     r0, =nl_err
        BL      PrintErrString
        
        ; Print "Total Errors: N"
        LDR     r0, =err_total
        BL      PrintErrString
        MOV     r0, r10
        BL      PrintErrInt
        LDR     r0, =nl_err
        BL      PrintErrString
        LDR     r0, =nl_err
        BL      PrintErrString
        
        MOVS    r12, #0                   ; loop index
        LTORG

error_loop
        CMP     r12, r10
        BGE.W   error_done
        
        ; r9 = &error_log_buffer[r12]
        LDR     r0, =error_log_buffer
        MOVS    r1, #16
        MUL     r2, r12, r1
        ADD     r9, r0, r2
        
        ; Divider & error number
        LDR     r0, =err_div
        BL      PrintErrString
        LDR     r0, =nl_err
        BL      PrintErrString
        
        LDR     r0, =err_no
        BL      PrintErrString
        MOV     r0, r12
        ADDS    r0, #1
        BL      PrintErrInt
        LDR     r0, =nl_err
        BL      PrintErrString
        
        ; Extract fields from record
        LDRB    r4, [r9, #0]              ; error_type
        LDRB    r5, [r9, #2]              ; sub_code / sensor / issue
        LDR     r6, [r9, #8]              ; extra value
        LDR     r7, [r9, #12]             ; patient_id
        
        ; Print "Type: <name>"
        LDR     r0, =err_type_l
        BL      PrintErrString
        
        CMP     r4, #ERROR_SENSOR_MALFUNCTION
        BEQ     print_sensor_err
        
        CMP     r4, #ERROR_INVALID_DOSAGE
        BEQ     print_dosage_err
        
        ; Memory error
        LDR     r0, =err_memory
        B       print_err_type
        
print_dosage_err
        LDR     r0, =err_dosage
        B       print_err_type
        
print_sensor_err
        LDR     r0, =err_sensor
        
print_err_type
        BL      PrintErrString
        LDR     r0, =nl_err
        BL      PrintErrString
        
        ; Branch to detailed handlers by error_type
        CMP     r4, #ERROR_SENSOR_MALFUNCTION
        BEQ     handle_sensor
        
        CMP     r4, #ERROR_INVALID_DOSAGE
        BEQ     handle_dosage
        
        B       handle_memory
        LTORG

; ---------------- Sensor malfunction details ----------------
handle_sensor
        ; "  Sensor: <name>"
        LDR     r0, =err_sens_l
        BL      PrintErrString
        
        CMP     r5, #1
        BEQ     sens_hr_s
        
        CMP     r5, #2
        BEQ     sens_o2_s
        
        LDR     r0, =sens_bp
        B       print_sensor
        
sens_o2_s
        LDR     r0, =sens_o2
        B       print_sensor
        
sens_hr_s
        LDR     r0, =sens_hr
        
print_sensor
        BL      PrintErrString
        LDR     r0, =nl_err
        BL      PrintErrString
        
        ; "  Stuck Value: N"
        LDR     r0, =err_val_l
        BL      PrintErrString
        
        MOV     r0, r6
        BL      PrintErrInt
        
        B       print_common
        LTORG

; ---------------- Invalid dosage details --------------------
handle_dosage
        ; "  Issue: Zero Unit Price / Zero Quantity"
        LDR     r0, =err_issue
        BL      PrintErrString
        
        CMP     r5, #1
        BEQ     iss_pr
        
        LDR     r0, =iss_qty
        B       print_issue
        
iss_pr
        LDR     r0, =iss_price
        
print_issue
        BL      PrintErrString
        LDR     r0, =nl_err
        BL      PrintErrString
        
        ; "  Medicine Index: N"
        LDR     r0, =err_med_l
        BL      PrintErrString
        
        MOV     r0, r6
        BL      PrintErrInt
        
        B       print_common
        LTORG

; ---------------- Memory error details ----------------------
handle_memory
        ; "  Code: Address Boundary / Billing Overflow"
        LDR     r0, =err_code_l
        BL      PrintErrString
        
        CMP     r5, #1
        BEQ     code_ad
        
        LDR     r0, =code_bill
        B       print_code
        
code_ad
        LDR     r0, =code_addr
        
print_code
        BL      PrintErrString
        LDR     r0, =nl_err
        BL      PrintErrString
        
        ; "  Value: 0xN"
        LDR     r0, =err_val2_l
        BL      PrintErrString
        
        MOV     r0, r6
        BL      PrintErrInt
        LTORG

; ---------------- Common footer for all errors --------------
print_common
        ; "  Patient ID: N"
        LDR     r0, =nl_err
        BL      PrintErrString
        
        LDR     r0, =err_pid_l
        BL      PrintErrString
        
        MOV     r0, r7
        BL      PrintErrInt
        LDR     r0, =nl_err
        BL      PrintErrString
        
        ; "  Timestamp: T sec"
        LDR     r0, =err_time_l
        BL      PrintErrString
        
        LDR     r0, [r9, #4]             ; timestamp field
        BL      PrintErrInt
        
        LDR     r0, =err_sec
        BL      PrintErrString
        LDR     r0, =nl_err
        BL      PrintErrString
        
        ; Closing divider
        LDR     r0, =err_div
        BL      PrintErrString
        LDR     r0, =nl_err
        BL      PrintErrString
        
        ; Next error record
        ADDS    r12, #1
        B       error_loop
        LTORG

; ---------------- No errors case ----------------------------
no_errors_detected
        LDR     r0, =nl_err
        BL      PrintErrString
        
        LDR     r0, =no_err_msg
        BL      PrintErrString
        
        LDR     r0, =nl_err
        BL      PrintErrString
        LTORG

; ---------------- Finished printing all errors --------------
error_done
        LDR     r0, =err_hdr1
        BL      PrintErrString
        LDR     r0, =nl_err
        BL      PrintErrString
        
        ; Extra blank lines
        LDR     r0, =nl_err
        BL      PrintErrString
        LDR     r0, =nl_err
        BL      PrintErrString
        
        POP     {r9-r11}
        POP     {r4-r7, pc}
        ENDP


; ==============================================================================
; Helper Functions for ITM Error Printing
; ==============================================================================
; PrintErrString
;   R0 = pointer to 0-terminated string
;   Sends characters one by one via ITM_SendChar_C.
; ==============================================================================
PrintErrString PROC
        PUSH    {r4, lr}
pes_loop
        LDRB    r1, [r0]
        CMP     r1, #0
        BEQ     pes_done
        
        MOV     r4, r0
        MOV     r0, r1
        BL      ITM_SendChar_C
        MOV     r0, r4
        ADDS    r0, #1
        B       pes_loop
        
pes_done
        POP     {r4, pc}
        ENDP


; PrintErrInt
;   R0 = unsigned integer to print in decimal
;   Uses int_buf as temporary reversed buffer.
; ==============================================================================
PrintErrInt PROC
        PUSH    {r4-r7, lr}
        
        MOV     r4, r0                ; value
        LDR     r5, =int_buf          ; buffer
        MOVS    r6, #0                ; length
        
        CMP     r4, #0
        BNE     pei_loop
        
        ; value = 0 ? print "0"
        MOVS    r0, #48
        BL      ITM_SendChar_C
        POP     {r4-r7, pc}
        
pei_loop
        CMP     r4, #0
        BEQ     pei_print
        
        MOVS    r7, #10
        UDIV    r1, r4, r7            ; quotient
        MUL     r2, r1, r7
        SUBS    r2, r4, r2            ; remainder
        ADDS    r2, #48               ; '0' + remainder
        STRB    r2, [r5, r6]
        MOV     r4, r1                ; value = quotient
        ADDS    r6, #1
        B       pei_loop
        
pei_print
        SUBS    r6, #1
        
pei_print_loop
        CMP     r6, #0
        BLT     pei_done
        
        LDRB    r0, [r5, r6]
        BL      ITM_SendChar_C
        SUBS    r6, #1
        B       pei_print_loop
        
pei_done
        POP     {r4-r7, pc}
        LTORG
        ENDP

        ALIGN
        END
