; ==============================================================================
; SmartCare-32: Module Integration (Modules 1-10)
; File: main.s
; ==============================================================================

        PRESERVE8
        THUMB
        AREA    main_code, CODE, READONLY

        IMPORT  patient_record_initialization
        IMPORT  acquire_vital_signs
        IMPORT  check_vital_thresholds
        IMPORT  medicine_administration_scheduler
        IMPORT  compute_treatment_cost
        IMPORT  compute_room_cost
        IMPORT  medicine_billing_module
        IMPORT  aggregate_total_bill
        IMPORT  sort_patients_by_criticality
        IMPORT  patient_array              ; IMPORT, not EXPORT
        IMPORT  patient1_name
        IMPORT  patient2_name
        IMPORT  patient3_name
        IMPORT  SENSOR_HR
        IMPORT  SENSOR_O2
        IMPORT  SENSOR_SBP
        IMPORT  SENSOR_DBP
        IMPORT  system_clock
        IMPORT  medicine_list_p1
        IMPORT  medicine_list_p2
        IMPORT  medicine_list_p3
		IMPORT  check_sensor_malfunction
        IMPORT  check_invalid_dosage
        IMPORT  check_memory_overflow
        
        ; MODULE 10: Import from module10.s
        IMPORT  Generate_All_Patient_Reports

        EXPORT  main                   ; Only export main

PATIENT_SIZE            EQU     412
PATIENT_ID_OFF          EQU     0x00
ALERT_COUNT_OFF         EQU     0x15

main    PROC
        MOVW    R11, #0x0001
        
        LDR     R0, =system_clock
        MOVW    R1, #0
        MOVT    R1, #0
        STR     R1, [R0]
        
        ; ======================================================================
        ; Initialize Patient 1
        ; ======================================================================
        MOV     R0, #7
        PUSH    {R0}                  ; stay_days = 7
        MOV     R0, #3
        PUSH    {R0}                  ; medicine_count = 3
        LDR     R0, =medicine_list_p1
        PUSH    {R0}                  ; medicine_list_ptr
        MOVW    R0, #2000
        PUSH    {R0}                  ; room_rate = 2000
        MOV     R0, #5
        PUSH    {R0}                  ; treatment_code = 5
        MOVW    R0, #101
        PUSH    {R0}                  ; ward = 101
        
        LDR     R0, =patient_array
        MOVW    R1, #1001
        LDR     R2, =patient1_name
        MOV     R3, #45
        BL      patient_record_initialization
        ADD     SP, SP, #24
        
        MOVW    R11, #0x0002
        
        LDR     R0, =patient_array
        BL      compute_treatment_cost
        MOVW    R11, #0x0003
        
        LDR     R0, =patient_array
        BL      compute_room_cost
        MOVW    R11, #0x0004
        
        LDR     R0, =patient_array
        BL      medicine_billing_module
        MOVW    R11, #0x0005
        
        LDR     R0, =patient_array
        BL      aggregate_total_bill
        MOVW    R11, #0x0006
		
	
        
        ; ======================================================================
        ; Initialize Patient 2
        ; ======================================================================
        MOV     R0, #12
        PUSH    {R0}
        MOV     R0, #2
        PUSH    {R0}
        LDR     R0, =medicine_list_p2
        PUSH    {R0}
        MOVW    R0, #5000
        PUSH    {R0}
        MOV     R0, #2
        PUSH    {R0}
        MOVW    R0, #102
        PUSH    {R0}
        
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        ADD     R0, R0, R10
        MOVW    R1, #1002
        LDR     R2, =patient2_name
        MOV     R3, #32
        BL      patient_record_initialization
        ADD     SP, SP, #24
        
        MOVW    R11, #0x0007
        
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        ADD     R0, R0, R10
        BL      compute_treatment_cost
        MOVW    R11, #0x0008
        
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        ADD     R0, R0, R10
        BL      compute_room_cost
        MOVW    R11, #0x0009
        
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        ADD     R0, R0, R10
        BL      medicine_billing_module
        MOVW    R11, #0x000A
        
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        ADD     R0, R0, R10
        BL      aggregate_total_bill
        MOVW    R11, #0x000B
        
        ; ======================================================================
        ; Initialize Patient 3
        ; ======================================================================
        MOV     R0, #5
        PUSH    {R0}
        MOV     R0, #1
        PUSH    {R0}
        LDR     R0, =medicine_list_p3
        PUSH    {R0}
        MOVW    R0, #3000
        PUSH    {R0}
        MOV     R0, #6
        PUSH    {R0}
        MOVW    R0, #201
        PUSH    {R0}
        
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        LSL     R10, R10, #1
        ADD     R0, R0, R10
        MOVW    R1, #1003
        LDR     R2, =patient3_name
        MOV     R3, #67
        BL      patient_record_initialization
        ADD     SP, SP, #24
        
        MOVW    R11, #0x000C
        
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        LSL     R10, R10, #1
        ADD     R0, R0, R10
        BL      compute_treatment_cost
        MOVW    R11, #0x000D
        
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        LSL     R10, R10, #1
        ADD     R0, R0, R10
        BL      compute_room_cost
        MOVW    R11, #0x000E
        
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        LSL     R10, R10, #1
        ADD     R0, R0, R10
        BL      medicine_billing_module
        MOVW    R11, #0x000F
        
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        LSL     R10, R10, #1
        ADD     R0, R0, R10
        BL      aggregate_total_bill
        MOVW    R11, #0x0010
                ; ======================================================================
        ; Vitals for Patient 1 (Acquire 10 times to build sensor history)
        ; ======================================================================
        MOVS    R12, #0                 ; Loop counter for 10 readings
        
vitals_loop_p1
        LDR     R0, =SENSOR_HR
        MOV     R1, #125
        STRB    R1, [R0]
        LDR     R0, =SENSOR_O2
        MOV     R1, #88
        STRB    R1, [R0]
        LDR     R0, =SENSOR_SBP
        MOV     R1, #135
        STRB    R1, [R0]
        LDR     R0, =SENSOR_DBP
        MOV     R1, #85
        STRB    R1, [R0]
        
        LDR     R0, =patient_array
        BL      acquire_vital_signs
        
        ; MODULE 11a: Check sensor malfunction after each reading
        MOV     R0, #0                  ; patient index 0
        BL      check_sensor_malfunction
        
        ; Simulate time passing
        LDR     R0, =system_clock
        LDR     R1, [R0]
        ADD     R1, R1, #300            ; Add 5 minutes
        STR     R1, [R0]
        
        ADD     R12, R12, #1
        CMP     R12, #10
        BLT     vitals_loop_p1
        
        MOVW    R11, #0x0011
 
        LDR     R0, =patient_array
        BL      check_vital_thresholds
        MOVW    R11, #0x0012
        
        LDR     R0, =patient_array
        BL      medicine_administration_scheduler
        MOVW    R11, #0x0013
		
		
		 ; MODULE 11b: Check invalid dosage (Patient 0)
        LDR     R0, =patient_array
        MOV     R1, #0                  ; patient index
        BL      check_invalid_dosage
        MOVW    R11, #0x0020
        
        ; ======================================================================
        ; Vitals for Patient 2
        ; ======================================================================
        LDR     R0, =SENSOR_HR
        MOV     R1, #78
        STRB    R1, [R0]
        LDR     R0, =SENSOR_O2
        MOV     R1, #98
        STRB    R1, [R0]
        LDR     R0, =SENSOR_SBP
        MOV     R1, #120
        STRB    R1, [R0]
        LDR     R0, =SENSOR_DBP
        MOV     R1, #80
        STRB    R1, [R0]
        
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        ADD     R0, R0, R10
        BL      acquire_vital_signs
        MOVW    R11, #0x0014
		
		; MODULE 11a: Check sensor malfunction (Patient 0)
        MOV     R0, #1                  ; patient index 0
        BL      check_sensor_malfunction
        ;MOVW    R11, #0x0020   
        
        
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        ADD     R0, R0, R10
        BL      check_vital_thresholds
        MOVW    R11, #0x0015
        
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        ADD     R0, R0, R10
        BL      medicine_administration_scheduler
        MOVW    R11, #0x0016
		
		; MODULE 11b: Check dosage Patient 2
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        ADD     R0, R0, R10
        MOV     R1, #1
        BL      check_invalid_dosage
        MOVW    R11, #0x0021
        
        ; ======================================================================
        ; Vitals for Patient 3
        ; ======================================================================
        LDR     R0, =SENSOR_HR
        MOV     R1, #165
        STRB    R1, [R0]
        LDR     R0, =SENSOR_O2
        MOV     R1, #85
        STRB    R1, [R0]
        LDR     R0, =SENSOR_SBP
        MOV     R1, #170
        STRB    R1, [R0]
        LDR     R0, =SENSOR_DBP
        MOV     R1, #95
        STRB    R1, [R0]
        
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        LSL     R10, R10, #1
        ADD     R0, R0, R10
        BL      acquire_vital_signs
        MOVW    R11, #0x0017
        
		; MODULE 11a: Check sensor for Patient 3
        MOV     R0, #2
        BL      check_sensor_malfunction
        
		
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        LSL     R10, R10, #1
        ADD     R0, R0, R10
        BL      check_vital_thresholds
        MOVW    R11, #0x0018
        
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        LSL     R10, R10, #1
        ADD     R0, R0, R10
        BL      medicine_administration_scheduler
        MOVW    R11, #0x0019
        
		; MODULE 11b: Check dosage Patient 3
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        LSL     R10, R10, #1
        ADD     R0, R0, R10
        MOV     R1, #2
        BL      check_invalid_dosage
        MOVW    R11, #0x0022
		
		; ======================================================================
        ; MODULE 11c: Check memory overflow for ALL patients
        ; ======================================================================
        LDR     R0, =patient_array
        MOV     R1, #0
        BL      check_memory_overflow
        
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        ADD     R0, R0, R10
        MOV     R1, #1
        BL      check_memory_overflow
        
        LDR     R0, =patient_array
        MOVW    R10, #PATIENT_SIZE
        LSL     R10, R10, #1
        ADD     R0, R0, R10
        MOV     R1, #2
        BL      check_memory_overflow
        MOVW    R11, #0x0023
		
        ; ======================================================================
        ; MODULE 9: Sort patients by criticality
        ; ======================================================================
        LDR     R0, =patient_array
        MOV     R1, #3
        BL      sort_patients_by_criticality
        MOVW    R11, #0x001A
        
        ; ======================================================================
        ; MODULE 10: Generate UART Summary Reports
        ; Calls module10.s which bridges to main.c
        ; ======================================================================
        MOVW    R11, #0x001B          ; Module 10 start marker
        
        BL      Generate_All_Patient_Reports  ; Call module10.s function
        
        MOVW    R11, #0x001C          ; Module 10 completed
        
        ; Success indicator
        MOVW    R0, #0xDEAD
        MOVT    R0, #0xBEEF
        
infinite_loop
        NOP
        B       infinite_loop
        
        ENDP
        ALIGN

        END
