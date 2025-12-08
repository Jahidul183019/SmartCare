;===============================================================================
; SmartCare-32: Module 10 — Patient Report Generator (All Logic in Assembly)
; File        : module10.s
; Description :
;   Generates a detailed textual summary report for each patient and sends it
;   through ITM (acting as UART) using ITM_SendChar_C.
;
;   Follows module10_report.s pattern with minimal C dependency.
;   For each patient:
;       - Prints patient info (ID, Age, Ward)
;       - Prints latest vitals (HR, BP, SpO2)
;       - Prints alert summary and status
;       - Prints billing summary (total bill)
;
; External dependencies:
;   - ITM_Init_C      : Initialize ITM / SWO
;   - ITM_SendChar_C  : Send one byte over ITM
;   - patient_array   : Base of patient structures
;   - Print_Error_Log : Module 11 error log printer
;
; NOTE: Logic and instructions are preserved exactly from the user's version.
;       Only formatting and comments have been improved.
;===============================================================================

        THUMB

;===============================================================================
; DATA AREA: Formatting buffers, report templates & strings
;===============================================================================
        AREA    module10_data, DATA, READWRITE

; Utility buffers
nl          DCB     0x0A, 0                   ; newline "\n"
int_dum     DCB     "                      ", 0
line        DCB     "                                        ", 0

; Report Header Strings
hdr1        DCB     "==================================================", 0
hdr2        DCB     "    PATIENT SUMMARY REPORT", 0
hdr3        DCB     "    SmartCare-32: Healthcare Monitoring System", 0

; Patient Info Section
info_hdr    DCB     "PATIENT INFORMATION:", 0
divider     DCB     "--------------------------------------------------", 0
pid_lbl     DCB     "  Patient ID       : ", 0
pid_str     DCB     "  Patient ID       :                    ", 0
age_lbl     DCB     "  Age              : ", 0
age_str     DCB     "  Age              :                     years", 0
ward_lbl    DCB     "  Ward Number      : ", 0
ward_str    DCB     "  Ward Number      :                    ", 0

; Vitals Section
vital_hdr   DCB     "LATEST VITAL SIGNS:", 0
hr_lbl      DCB     "  Heart Rate       : ", 0
hr_str      DCB     "  Heart Rate       :                     bpm", 0
bp_lbl      DCB     "  Blood Pressure   : ", 0
bp_str      DCB     "  Blood Pressure   :           /            mmHg", 0
o2_lbl      DCB     "  SpO2 (Oxygen)    : ", 0
o2_str      DCB     "  SpO2 (Oxygen)    :                     %", 0

; Alert Section
alert_hdr   DCB     "ALERT SUMMARY:", 0
alert_lbl   DCB     "  Total Alerts     : ", 0
alert_str   DCB     "  Total Alerts     :                    ", 0
status_ok   DCB     " (Patient Stable)", 0
status_warn DCB     " (Attention Required)", 0
status_crit DCB     " (Critical condition)", 0

; Billing Section
bill_hdr    DCB     "BILLING SUMMARY:", 0
bill_lbl    DCB     "  Total Bill       : $", 0
bill_str    DCB     "  Total Bill       : $                  USD", 0

; Report Footer
end_rpt     DCB     "    End of Report", 0

; Templates used by reset_templates
pid_tmpl    DCB     "  Patient ID       :                    ", 0
age_tmpl    DCB     "  Age              :                     years", 0
ward_tmpl   DCB     "  Ward Number      :                    ", 0
hr_tmpl     DCB     "  Heart Rate       :                     bpm", 0
bp_tmpl     DCB     "  Blood Pressure   :           /            mmHg", 0
o2_tmpl     DCB     "  SpO2 (Oxygen)    :                     %", 0
alert_tmpl  DCB     "  Total Alerts     :                    ", 0
bill_tmpl   DCB     "  Total Bill       : $                  USD", 0


;===============================================================================
; CODE AREA
;===============================================================================
        AREA    |.text|, CODE, READONLY

        EXPORT  Generate_Summary_Report
        EXPORT  Generate_All_Patient_Reports

        IMPORT  ITM_SendChar_C
        IMPORT  ITM_Init_C
        IMPORT  patient_array
        IMPORT  Print_Error_Log

; Patient structure layout (must match data.s)
PATIENT_SIZE    EQU     412
PATIENT_ID_OFF  EQU     0x00
AGE_OFF         EQU     0x08
WARD_OFF        EQU     0x0A
VITALS_OFF      EQU     0x18        ; start of first vital entry
ALERT_CNT_OFF   EQU     0x15
TOTAL_BILL_OFF  EQU     0x194       ; 0x184 + 0x10 (billing + total_bill offset)


;===============================================================================
; Generate_All_Patient_Reports
;   Simple alias to Generate_Summary_Report
;===============================================================================
Generate_All_Patient_Reports PROC
        B       Generate_Summary_Report
        ENDP


;===============================================================================
; Generate_Summary_Report
;   - Initializes ITM
;   - Prints error log (from Module 11)
;   - Iterates over 3 patients and prints full summary for each
;===============================================================================
Generate_Summary_Report PROC
        PUSH    {r4-r7, lr}
        PUSH    {r9-r11}
        
        ; Initialize ITM (SWO)
        BL      ITM_Init_C
        
        ; Print error log FIRST (Module 11)
        BL      Print_Error_Log
        
        ; r9  = &patient_array
        ; r10 = number of patients (hardcoded 3)
        ; r11 = PATIENT_SIZE
        ; r12 = current index (0..2)
        LDR     r9, =patient_array
        MOVS    r10, #3
        LDR     r11, =PATIENT_SIZE
        MOVS    r12, #0
        
        B       check_loop

;-------------------------------------
; print_patient: prints one full report for patient[index]
;-------------------------------------
print_patient
        BL      reset_templates
        
        ; Calculate patient pointer:
        ;   r5 = &patient_array[index]
        MOV     r5, r12
        MUL     r5, r11, r5
        ADD     r5, r5, r9
        
        ; ---------------- HEADER ----------------
        LDR     r0, =hdr1
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        LDR     r0, =hdr2
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        LDR     r0, =hdr3
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        LDR     r0, =hdr1
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        ; ----------- PATIENT INFORMATION ----------
        LDR     r0, =info_hdr
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        LDR     r0, =divider
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        ; Patient ID
        BL      reset_int_dum
        LDR     r2, [r5, #PATIENT_ID_OFF]
        LDR     r0, =int_dum
        MOVS    r7, #0
        BL      push_integer
        
        LDR     r0, =pid_str
        LDR     r2, =int_dum
        MOVS    r8, r7
        SUBS    r8, #1
        MOVS    r7, #21
        BL      push_string_rev
        
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        ; Age
        BL      reset_int_dum
        LDRB    r2, [r5, #AGE_OFF]
        LDR     r0, =int_dum
        MOVS    r7, #0
        BL      push_integer
        
        LDR     r0, =age_str
        LDR     r2, =int_dum
        MOVS    r8, r7
        SUBS    r8, #1
        MOVS    r7, #21
        BL      push_string_rev
        
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        ; Ward
        BL      reset_int_dum
        LDRH    r2, [r5, #WARD_OFF]
        LDR     r0, =int_dum
        MOVS    r7, #0
        BL      push_integer
        
        LDR     r0, =ward_str
        LDR     r2, =int_dum
        MOVS    r8, r7
        SUBS    r8, #1
        MOVS    r7, #21
        BL      push_string_rev
        
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        ; --------------- VITALS HEADER ----------
        LDR     r0, =divider
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        LDR     r0, =vital_hdr
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        LDR     r0, =divider
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        ; Heart Rate (byte at VITALS_OFF)
        BL      reset_int_dum
        LDRB    r2, [r5, #VITALS_OFF]
        LDR     r0, =int_dum
        MOVS    r7, #0
        BL      push_integer
        
        LDR     r0, =hr_str
        LDR     r2, =int_dum
        MOVS    r8, r7
        SUBS    r8, #1
        MOVS    r7, #21
        BL      push_string_rev
        
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        ; Blood Pressure (two bytes from VITALS_OFF+1 and +2)
        BL      reset_int_dum
        ADD     r6, r5, #VITALS_OFF
        LDRB    r2, [r6, #1]
        LDR     r0, =int_dum
        MOVS    r7, #0
        BL      push_integer
        
        LDR     r0, =bp_str
        LDR     r2, =int_dum
        MOVS    r8, r7
        SUBS    r8, #1
        MOVS    r7, #21
        BL      push_string_rev
        
        ; Insert "/" separator into BP string
        MOVS    r1, #0x2F              ; '/'
        STRB    r1, [r0, #24]
        
        ; DBP
        BL      reset_int_dum
        LDRB    r2, [r6, #2]
        LDR     r0, =int_dum
        MOVS    r7, #0
        BL      push_integer
        
        LDR     r0, =bp_str
        LDR     r2, =int_dum
        MOVS    r8, r7
        SUBS    r8, #1
        MOVS    r7, #26
        BL      push_string_rev
        
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        ; SpO2 (Oxygen)
        BL      reset_int_dum
        LDRB    r2, [r6, #3]
        LDR     r0, =int_dum
        MOVS    r7, #0
        BL      push_integer
        
        LDR     r0, =o2_str
        LDR     r2, =int_dum
        MOVS    r8, r7
        SUBS    r8, #1
        MOVS    r7, #21
        BL      push_string_rev
        
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        ; --------------- ALERT SUMMARY ----------
        LDR     r0, =divider
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        LDR     r0, =alert_hdr
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        LDR     r0, =divider
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        ; Alert count
        BL      reset_int_dum
        LDRB    r2, [r5, #ALERT_CNT_OFF]
        MOV     r6, r2
        LDR     r0, =int_dum
        MOVS    r7, #0
        BL      push_integer
        
        LDR     r0, =alert_str
        LDR     r2, =int_dum
        MOVS    r8, r7
        SUBS    r8, #1
        MOVS    r7, #21
        BL      push_string_rev
        
        BL      PrintByteString
        
        ; Choose status string based on alert count
        CMP     r6, #0
        BEQ     print_stable
        
        CMP     r6, #3
        BLT     print_attention
        
        LDR     r0, =status_crit
        B       print_status
        
print_attention
        LDR     r0, =status_warn
        B       print_status
        
print_stable
        LDR     r0, =status_ok
        
print_status
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        ; --------------- BILLING SUMMARY --------
        LDR     r0, =divider
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        LDR     r0, =bill_hdr
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        LDR     r0, =divider
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        ; Total Bill
        BL      reset_int_dum
        LDR     r2, [r5, #TOTAL_BILL_OFF]
        LDR     r0, =int_dum
        MOVS    r7, #0
        BL      push_integer
        
        LDR     r0, =bill_str
        LDR     r2, =int_dum
        MOVS    r8, r7
        SUBS    r8, #1
        MOVS    r7, #23
        BL      push_string_rev
        
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        ; ---------------- FOOTER ----------------
        LDR     r0, =hdr1
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        LDR     r0, =end_rpt
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        LDR     r0, =hdr1
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        ; Blank lines between patients
        LDR     r0, =nl
        BL      PrintByteString
        LDR     r0, =nl
        BL      PrintByteString
        
        ; Next patient
        ADDS    r12, #1
        B       check_loop
        
        LTORG

;-------------------------------------
; Loop condition for patient iteration
;-------------------------------------
check_loop
        CMP     r12, r10
        BEQ     finish
        B       print_patient

finish
        POP     {r9-r11}
        POP     {r4-r7, pc}
        ENDP


;===============================================================================
; Helper Functions (unchanged logic, better documented)
;===============================================================================

;-------------------------------------
; reset_templates
;   Copies the fixed templates back
;   into the working strings for each field.
;-------------------------------------
reset_templates PROC
        PUSH    {r0-r2, lr}
        
        LDR     r0, =pid_tmpl
        LDR     r1, =pid_str
        MOVS    r2, #40
        BL      copy_bytes
        
        LDR     r0, =age_tmpl
        LDR     r1, =age_str
        MOVS    r2, #45
        BL      copy_bytes
        
        LDR     r0, =ward_tmpl
        LDR     r1, =ward_str
        MOVS    r2, #40
        BL      copy_bytes
        
        LDR     r0, =hr_tmpl
        LDR     r1, =hr_str
        MOVS    r2, #43
        BL      copy_bytes
        
        LDR     r0, =bp_tmpl
        LDR     r1, =bp_str
        MOVS    r2, #48
        BL      copy_bytes
        
        LDR     r0, =o2_tmpl
        LDR     r1, =o2_str
        MOVS    r2, #41
        BL      copy_bytes
        
        LDR     r0, =alert_tmpl
        LDR     r1, =alert_str
        MOVS    r2, #40
        BL      copy_bytes
        
        LDR     r0, =bill_tmpl
        LDR     r1, =bill_str
        MOVS    r2, #45
        BL      copy_bytes
        
        POP     {r0-r2, pc}
        ENDP


;-------------------------------------
; copy_bytes
;   r0 = src, r1 = dst, r2 = count
;-------------------------------------
copy_bytes PROC
cb_loop
        CMP     r2, #0
        BXEQ    lr
        
        LDRB    r3, [r0]
        STRB    r3, [r1]
        
        ADDS    r0, #1
        ADDS    r1, #1
        SUBS    r2, #1
        B       cb_loop
        ENDP


;-------------------------------------
; reset_int_dum
;   Fills int_dum buffer with spaces.
;-------------------------------------
reset_int_dum PROC
        PUSH    {r0-r2, lr}
        
        LDR     r0, =int_dum
        MOVS    r1, #0x20              ; ' '
        MOVS    r2, #22
        
rid_loop
        CMP     r2, #0
        BEQ     rid_done
        
        STRB    r1, [r0]
        ADDS    r0, #1
        SUBS    r2, #1
        B       rid_loop
        
rid_done
        POP     {r0-r2, pc}
        ENDP


;-------------------------------------
; push_integer
;   r2 = integer value
;   r0 = pointer to int_dum
;   r7 = current output index into int_dum
;   Writes digits in reverse (LSB-first) order.
;-------------------------------------
push_integer PROC
        PUSH    {r4, lr}
        
        CMP     r2, #0
        BNE     pi_nonzero
        
        ; Special case: value = 0
        MOVS    r1, #48                ; '0'
        STRB    r1, [r0, r7]
        ADDS    r7, #1
        POP     {r4, pc}
        
pi_nonzero
pi_loop
        CMP     r2, #0
        BEQ     pi_done
        
        MOVS    r4, #10
        UDIV    r1, r2, r4
        MUL     r3, r1, r4
        SUBS    r1, r2, r3
        ADDS    r1, #48
        STRB    r1, [r0, r7]
        UDIV    r2, r4
        ADDS    r7, #1
        B       pi_loop
        
pi_done
        POP     {r4, pc}
        ENDP


;-------------------------------------
; push_string_rev
;   Copies string from int_dum (in reverse digit order)
;   into the target field, right-aligned with spaces.
;
;   Inputs:
;     r0 = destination string (e.g., pid_str)
;     r2 = source string (int_dum)
;     r7 = destination start index
;     r8 = last index in source to copy from
;-------------------------------------
push_string_rev PROC
        PUSH    {r4, lr}
        
psr_loop
        CMP     r8, #0
        BLT     psr_done
        
        LDRB    r1, [r2, r8]
        STRB    r1, [r0, r7]
        
        SUBS    r8, #1
        ADDS    r7, #1
        B       psr_loop
        
psr_done
        MOVS    r1, #0x20              ; fill remainder with spaces
        
psr_fill
        CMP     r7, #38
        BGE     psr_end
        
        STRB    r1, [r0, r7]
        ADDS    r7, #1
        B       psr_fill
        
psr_end
        POP     {r4, pc}
        ENDP


;-------------------------------------
; PrintByteString
;   r0 = pointer to 0-terminated string
;   Sends each byte via ITM_SendChar_C.
;-------------------------------------
PrintByteString PROC
        PUSH    {r4-r7, lr}
        PUSH    {r9-r12}
        
loop_pbs
        LDRB    r1, [r0]
        CMP     r1, #0
        BEQ     done_pbs
        
        MOV     r4, r0         ; save pointer
        MOV     r0, r1         ; char ? r0 for ITM_SendChar_C
        BL      ITM_SendChar_C
        MOV     r0, r4
        ADD     r0, r0, #1
        B       loop_pbs
        
done_pbs
        POP     {r9-r12}
        POP     {r4-r7, pc}
        ENDP


        END
