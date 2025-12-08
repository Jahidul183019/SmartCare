; ================================================================================
; SmartCare-32: ARM-Based Healthcare Monitoring & Billing System
; File : data.s
; Role : Central data definitions, structure layouts, and global variables
;
;   - Defines patient structure layout and array (3 patients)
;   - Defines medicine structures and lists for each patient
;   - Simulated sensor addresses and system clock
;   - Treatment cost lookup table
;   - Error logging structures (Module 11)
; ================================================================================

        AREA    PatientData, DATA, READWRITE
        ALIGN   4

; ================================================================================
; EXPORT DECLARATIONS
; ================================================================================
        EXPORT  patient_array
        EXPORT  treatment_cost_table
        EXPORT  SENSOR_HR
        EXPORT  SENSOR_O2
        EXPORT  SENSOR_SBP
        EXPORT  SENSOR_DBP
        EXPORT  system_clock
        EXPORT  patient_count
        EXPORT  patient1_name
        EXPORT  patient2_name
        EXPORT  patient3_name
        EXPORT  medicine_list_p1
        EXPORT  medicine_list_p2
        EXPORT  medicine_list_p3

; (Module 11 exports are declared later at the bottom)


; ================================================================================
; STRUCTURE CONSTANTS
; ================================================================================

; ----------------------------------------------------------------------------
; Medicine structure layout (byte offsets)
; ----------------------------------------------------------------------------
; +0x00 : medicine_id              (1 byte)
; +0x01 : dosage_interval_hours    (1 byte)
; +0x02 : padding                  (2 bytes)
; +0x04 : last_administered_time   (4 bytes, aligned)
; +0x08 : unit_price               (4 bytes, aligned)
; +0x0C : quantity                 (2 bytes)
; +0x0E : padding                  (2 bytes)
; Total : 0x10 (= 16 bytes per medicine)
; ----------------------------------------------------------------------------
MED_ID_OFF             EQU     0x00
DOSAGE_INTERVAL_OFF    EQU     0x01
LAST_ADMIN_TIME_OFF    EQU     0x04
UNIT_PRICE_OFF         EQU     0x08
QUANTITY_OFF           EQU     0x0C
MED_PADDING_OFF        EQU     0x0E
MEDICINE_SIZE          EQU     0x10     ; 16 bytes


; ----------------------------------------------------------------------------
; Patient structure layout (byte offsets)
; ----------------------------------------------------------------------------
; +0x000 : patient_id              (4 bytes)
; +0x004 : name_ptr                (4 bytes)
; +0x008 : age                     (1 byte)
; +0x009 : treatment_code          (1 byte)
; +0x00A : ward_number             (2 bytes)
; +0x00C : room_daily_rate         (4 bytes)
; +0x010 : medicine_list_ptr       (4 bytes)
; +0x014 : medicine_count          (1 byte)
; +0x015 : alert_count             (1 byte)
; +0x016 : stay_days               (2 bytes)
; +0x018 : vital_buffer[10]        (40 bytes, 10 x 4-byte VitalSign)
; +0x040 : vital_buffer_index      (1 byte)
; +0x041 : alert_flag              (1 byte)
; +0x042 : dosage_due_flag         (1 byte)
; +0x043 : padding                 (1 byte)
; +0x044 : alert_buffer[20]        (320 bytes, 20 x 16-byte AlertRecord)
; +0x184 : billing structure       (24 bytes)
; Total : 0x19C (= 412 bytes per patient)
; ----------------------------------------------------------------------------

; --- Vital sign buffer info ---
VITAL_SIZE              EQU     4       ; bytes per vital record
VITAL_COUNT             EQU     10      ; entries per buffer

; --- Alert buffer info ---
ALERT_SIZE              EQU     16      ; bytes per alert record
ALERT_COUNT             EQU     20      ; entries per buffer

; --- Billing structure total size ---
BILLING_SIZE            EQU     24      ; bytes

; --- Patient structure offsets ---
PATIENT_SIZE            EQU     412

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

; --- Billing structure offsets (relative to BILLING_OFF) ---
TREATMENT_COST_OFF      EQU     0x00
ROOM_COST_OFF           EQU     0x04
MEDICINE_COST_OFF       EQU     0x08
LAB_TEST_COST_OFF       EQU     0x0C
TOTAL_BILL_OFF          EQU     0x10
OVERFLOW_FLAG_OFF       EQU     0x14


; ==============================================================================
; SIMULATED SENSOR MEMORY LOCATIONS
;   (used by Module 2 & Module 3)
; ==============================================================================
        ALIGN   4
SENSOR_HR       SPACE   1       ; Heart Rate (0–255 bpm)
        ALIGN   4
SENSOR_O2       SPACE   1       ; Oxygen saturation (0–100%)
        ALIGN   4
SENSOR_SBP      SPACE   1       ; Systolic Blood Pressure
        ALIGN   4
SENSOR_DBP      SPACE   1       ; Diastolic Blood Pressure
        ALIGN   4


; ==============================================================================
; SYSTEM CLOCK COUNTER
;   Global timestamp used for scheduling, logs, etc.
; ==============================================================================
system_clock    DCD     0       ; seconds (or arbitrary time unit)


; ==============================================================================
; PATIENT COUNT
; ==============================================================================
patient_count   DCD     3       ; Number of patients in the system


; ==============================================================================
; TREATMENT COST TABLE
;   Index = treatment_code, value = cost
; ==============================================================================
        ALIGN   4
treatment_cost_table
        DCD     5000            ; Code  0: Basic checkup
        DCD     15000           ; Code  1: Minor surgery
        DCD     50000           ; Code  2: Major surgery
        DCD     8000            ; Code  3: Diagnostic tests
        DCD     12000           ; Code  4: Physical therapy
        DCD     25000           ; Code  5: ICU admission
        DCD     30000           ; Code  6: Emergency care
        DCD     10000           ; Code  7: Consultation
        DCD     20000           ; Code  8: Imaging
        DCD     18000           ; Code  9: Laboratory
        DCD     22000           ; Code 10: Cardiology
        DCD     27000           ; Code 11: Neurology
        DCD     16000           ; Code 12: Orthopedics
        DCD     14000           ; Code 13: Pediatrics
        DCD     19000           ; Code 14: Oncology
        DCD     21000           ; Code 15: Radiology


; ==============================================================================
; PATIENT NAME STRINGS
; ==============================================================================
        ALIGN   4
patient1_name   DCB     "Abdullah Karim", 0
        ALIGN   4
patient2_name   DCB     "Nusrat Jahan", 0
        ALIGN   4
patient3_name   DCB     "Imran Hossain", 0
        ALIGN   4


; ==============================================================================
; MEDICINE LISTS
;   Each entry: 16 bytes (see MEDICINE_* OFFSETS above)
; ==============================================================================
; -----------------------------------------
; Patient 1 Medicines (3 items = 48 bytes)
; -----------------------------------------
        ALIGN   4
medicine_list_p1

; Medicine 1
        DCB     1                       ; +0x00: medicine_id
        DCB     6                       ; +0x01: dosage_interval_hours
        DCB     0, 0                    ; padding for alignment
        DCD     0                       ; +0x04: last_administered_time
        DCD     75                      ; +0x08: unit_price
        DCW     8                       ; +0x0C: quantity
        DCB     0, 0                    ; +0x0E: padding

; Medicine 2
        DCB     2                       ; +0x00: medicine_id
        DCB     8                       ; +0x01: dosage_interval_hours
        DCB     0, 0                    ; padding
        DCD     0                       ; +0x04: last_administered_time
        DCD     150                     ; +0x08: unit_price
        DCW     5                       ; +0x0C: quantity
        DCB     0, 0                    ; +0x0E: padding

; Medicine 3
        DCB     3                       ; +0x00: medicine_id
        DCB     12                      ; +0x01: dosage_interval_hours
        DCB     0, 0                    ; padding
        DCD     0                       ; +0x04: last_administered_time
        DCD     220                     ; +0x08: unit_price
        DCW     3                       ; +0x0C: quantity
        DCB     0, 0                    ; +0x0E: padding


; -----------------------------------------
; Patient 2 Medicines (2 items = 32 bytes)
; -----------------------------------------
        ALIGN   4
medicine_list_p2

; Medicine 1  (INTENTIONALLY INVALID: price=0, quantity=0 for error detection)
        DCB     4                       ; +0x00: medicine_id
        DCB     4                       ; +0x01: dosage_interval_hours
        DCB     0, 0                    ; padding
        DCD     0                       ; +0x04: last_administered_time
        DCD     0                       ; +0x08: unit_price (0 ? invalid)
        DCW     0                       ; +0x0C: quantity (0 ? invalid)
        DCB     0, 0                    ; +0x0E: padding

; Medicine 2
        DCB     5                       ; +0x00: medicine_id
        DCB     6                       ; +0x01: dosage_interval_hours
        DCB     0, 0                    ; padding
        DCD     0                       ; +0x04: last_administered_time
        DCD     180                     ; +0x08: unit_price
        DCW     4                       ; +0x0C: quantity
        DCB     0, 0                    ; +0x0E: padding


; -----------------------------------------
; Patient 3 Medicines (1 item = 16 bytes)
; -----------------------------------------
        ALIGN   4
medicine_list_p3

        DCB     6                       ; +0x00: medicine_id
        DCB     24                      ; +0x01: dosage_interval_hours
        DCB     0, 0                    ; padding
        DCD     0                       ; +0x04: last_administered_time
        DCD     320                     ; +0x08: unit_price
        DCW     2                       ; +0x0C: quantity
        DCB     0, 0                    ; +0x0E: padding


; ==============================================================================
; PATIENT ARRAY - 3 Patients
;   Each patient = 412 bytes (PATIENT_SIZE)
; ==============================================================================
        ALIGN   4
patient_array

; ------------------------------------------------------------------------------
; Patient 1: Abdullah Karim
;   Treatment code: 3 (Diagnostic tests)
;   Initial alert_count: 1
; ------------------------------------------------------------------------------
patient1
        DCD     2101                    ; +0x00: patient_id
        DCD     patient1_name           ; +0x04: name_ptr
        DCB     60                      ; +0x08: age
        DCB     3                       ; +0x09: treatment_code (Diagnostic tests)
        DCW     301                     ; +0x0A: ward_number
        DCD     3500                    ; +0x0C: room_daily_rate
        DCD     medicine_list_p1        ; +0x10: medicine_list_ptr
        DCB     3                       ; +0x14: medicine_count
        DCB     1                       ; +0x15: alert_count
        DCW     9                       ; +0x16: stay_days
        ; +0x18: vital_buffer[10] (40 bytes)
        SPACE   40
        DCB     0                       ; +0x40: vital_buffer_index
        DCB     0                       ; +0x41: alert_flag
        DCB     0                       ; +0x42: dosage_due_flag
        DCB     0                       ; +0x43: padding
        ; +0x44: alert_buffer[20] (320 bytes)
        SPACE   320
        ; +0x184: billing structure (24 bytes)
        DCD     0                       ; treatment_cost
        DCD     0                       ; room_cost
        DCD     0                       ; medicine_cost
        DCD     5000                    ; lab_test_cost
        DCD     0                       ; total_bill
        DCD     0                       ; overflow_flag (0 = no overflow)


; ------------------------------------------------------------------------------
; Patient 2: Nusrat Jahan
;   Treatment code: 8 (Imaging)
;   Initial alert_count: 0 (stable)
; ------------------------------------------------------------------------------
patient2
        DCD     2102                    ; +0x00: patient_id
        DCD     patient2_name           ; +0x04: name_ptr
        DCB     27                      ; +0x08: age
        DCB     8                       ; +0x09: treatment_code (Imaging)
        DCW     205                     ; +0x0A: ward_number
        DCD     2200                    ; +0x0C: room_daily_rate
        DCD     medicine_list_p2        ; +0x10: medicine_list_ptr
        DCB     2                       ; +0x14: medicine_count
        DCB     0                       ; +0x15: alert_count
        DCW     4                       ; +0x16: stay_days
        ; +0x18: vital_buffer[10]
        SPACE   40
        DCB     0                       ; +0x40: vital_buffer_index
        DCB     0                       ; +0x41: alert_flag
        DCB     0                       ; +0x42: dosage_due_flag
        DCB     0                       ; +0x43: padding
        ; +0x44: alert_buffer[20]
        SPACE   320
        ; +0x184: billing structure
        DCD     0                       ; treatment_cost
        DCD     0                       ; room_cost
        DCD     0                       ; medicine_cost
        DCD     6500                    ; lab_test_cost
        DCD     0                       ; total_bill
        DCD     0                       ; overflow_flag


; ------------------------------------------------------------------------------
; Patient 3: Imran Hossain
;   Treatment code: 11 (Neurology)
;   Initial alert_count: 4 (more critical)
; ------------------------------------------------------------------------------
patient3
        DCD     2103                    ; +0x00: patient_id
        DCD     patient3_name           ; +0x04: name_ptr
        DCB     73                      ; +0x08: age
        DCB     11                      ; +0x09: treatment_code (Neurology)
        DCW     110                     ; +0x0A: ward_number
        DCD     4500                    ; +0x0C: room_daily_rate
        DCD     medicine_list_p3        ; +0x10: medicine_list_ptr
        DCB     1                       ; +0x14: medicine_count
        DCB     4                       ; +0x15: alert_count
        DCW     15                      ; +0x16: stay_days ( >10 ? discount case)
        ; +0x18: vital_buffer[10]
        SPACE   40
        DCB     0                       ; +0x40: vital_buffer_index
        DCB     0                       ; +0x41: alert_flag
        DCB     0                       ; +0x42: dosage_due_flag
        DCB     0                       ; +0x43: padding
        ; +0x44: alert_buffer[20]
        SPACE   320
        ; +0x184: billing structure
        DCD     0                       ; treatment_cost
        DCD     0                       ; room_cost
        DCD     0                       ; medicine_cost
        DCD     12000                   ; lab_test_cost
        DCD     0                       ; total_bill
        DCD     0                       ; overflow_flag


; ==============================================================================
; MODULE 11: ERROR DETECTION DATA STRUCTURES
;   (shared with module11.s)
; ==============================================================================

; Error types
ERROR_SENSOR_MALFUNCTION    EQU     0x01
ERROR_INVALID_DOSAGE        EQU     0x02
ERROR_MEMORY_OVERFLOW       EQU     0x03

; Error record structure (16 bytes)
;   +0x00 : error_type      (1 byte)
;   +0x01 : patient_index   (1 byte)
;   +0x02 : error_code      (1 byte)
;   +0x03 : padding         (1 byte)
;   +0x04 : timestamp       (4 bytes)
;   +0x08 : error_value     (4 bytes)
;   +0x0C : patient_id      (4 bytes)
ERROR_RECORD_SIZE           EQU     16
MAX_ERROR_RECORDS           EQU     50

; Global error flag (set to 1 when any error is logged)
        ALIGN   4
error_flag      DCD     0

; Error log buffer (simulated Flash storage area)
        ALIGN   4
error_log_buffer
        SPACE   (ERROR_RECORD_SIZE * MAX_ERROR_RECORDS)

; Error count
        ALIGN   4
error_count     DCD     0

; Sensor value history for malfunction detection
        ALIGN   4
sensor_history
hr_history      SPACE   10
o2_history      SPACE   10
sbp_history     SPACE   10
dbp_history     SPACE   10

sensor_history_index    DCB     0
        ALIGN   4

; Export Module 11 symbols
        EXPORT  error_flag
        EXPORT  error_log_buffer
        EXPORT  error_count
        EXPORT  sensor_history
        EXPORT  sensor_history_index

        END
