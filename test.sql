CREATE OR REPLACE PACKAGE BODY pkg_attendance AS

    -- ===============================
    -- MARK ATTENDANCE IN (UPDATED WITH PHOTO)
    -- ===============================

    FUNCTION mark_attendance_in (
        p_emp_code      IN VARCHAR2,
        p_scan_type     IN VARCHAR2 DEFAULT 'QR',
        p_device_info   IN VARCHAR2 DEFAULT NULL,
        p_photo_blob    IN BLOB DEFAULT NULL,      -- NEW PARAMETER
        p_photo_name    IN VARCHAR2 DEFAULT NULL    -- NEW PARAMETER
    ) RETURN VARCHAR2 IS
        v_emp_id        employee.emp_id%TYPE;
        v_attendance_id attendance.attendance_id%TYPE;
        v_in_time       attendance.in_time%TYPE;
        v_current_time  TIMESTAMP := SYSTIMESTAMP AT TIME ZONE 'Asia/Karachi';
    BEGIN
        -- Get employee ID
        SELECT emp_id 
        INTO v_emp_id 
        FROM employee 
        WHERE emp_code = p_emp_code 
          AND is_active = 'Y';

        BEGIN
            -- Check if already checked in
            SELECT attendance_id, in_time 
            INTO v_attendance_id, v_in_time
            FROM attendance
            WHERE emp_id = v_emp_id 
              AND attendance_date = TRUNC(v_current_time)
              AND in_time IS NOT NULL
              AND ROWNUM = 1;

            RETURN 'Employee Already In ' 
                   || TO_CHAR(v_in_time, 'HH24:MI:SS');

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                -- Insert new attendance record with photo support
                INSERT INTO attendance (
                    attendance_id, emp_id, attendance_date, 
                    scan_type, in_time, in_scan_device, status,
                    in_photo, in_photo_name                    -- NEW COLUMNS
                ) VALUES (
                    seq_attendance_id.NEXTVAL, v_emp_id, TRUNC(v_current_time),
                    p_scan_type, v_current_time, p_device_info, 'PRESENT',
                    p_photo_blob, p_photo_name                 -- NEW VALUES
                ) RETURNING attendance_id INTO v_attendance_id;

                COMMIT;

                RETURN 'SUCCESS: WELCOME ' || TO_CHAR(v_current_time, 'HH24:MI:SS');
        END;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'Invalid employee code';
        WHEN OTHERS THEN
            RETURN 'ERROR: ' || SQLERRM;
    END mark_attendance_in;


    -- ===============================
    -- MARK ATTENDANCE OUT (UPDATED WITH PHOTO)
    -- ===============================

    FUNCTION mark_attendance_out (
        p_emp_code      IN VARCHAR2,
        p_scan_type     IN VARCHAR2 DEFAULT 'QR',
        p_device_info   IN VARCHAR2 DEFAULT NULL,
        p_photo_blob    IN BLOB DEFAULT NULL,      -- NEW PARAMETER
        p_photo_name    IN VARCHAR2 DEFAULT NULL    -- NEW PARAMETER
    ) RETURN VARCHAR2 IS
        v_emp_id        employee.emp_id%TYPE;
        v_attendance_id attendance.attendance_id%TYPE;
        v_in_time       TIMESTAMP;
        v_out_time      TIMESTAMP;
        v_current_time  TIMESTAMP := SYSTIMESTAMP AT TIME ZONE 'Asia/Karachi';
    BEGIN
        -- Get employee ID
        SELECT emp_id 
        INTO v_emp_id 
        FROM employee
        WHERE emp_code = p_emp_code 
          AND is_active = 'Y';

        -- Get today's record
        SELECT attendance_id, in_time, out_time
        INTO v_attendance_id, v_in_time, v_out_time
        FROM attendance
        WHERE emp_id = v_emp_id 
          AND attendance_date = TRUNC(SYSDATE)
          FETCH FIRST 1 ROW ONLY;

        -- Validations
        IF v_in_time IS NULL THEN
            RETURN 'ERROR: Please check-in first';
        ELSIF v_out_time IS NOT NULL THEN
            RETURN 'ERROR: Already checked out at ' 
                   || TO_CHAR(v_out_time, 'HH24:MI:SS');
        END IF;

        -- Update OUT time with photo support
        UPDATE attendance
        SET out_time = v_current_time,
            out_scan_device = p_device_info,
            out_photo = p_photo_blob,               -- NEW COLUMN
            out_photo_name = p_photo_name,          -- NEW COLUMN
            scan_type_out = p_scan_type             -- NEW COLUMN (if exists)
        WHERE attendance_id = v_attendance_id;

        -- Calculate hours
        calculate_daily_hours(v_attendance_id);

        COMMIT;

        RETURN 'SUCCESS: Check-out at ' || TO_CHAR(v_current_time, 'HH24:MI:SS');

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'ERROR: No check-in found for today';
        WHEN OTHERS THEN
            RETURN 'ERROR: ' || SQLERRM;
    END mark_attendance_out;


    -- ===============================
    -- MARK ATTENDANCE IN WITH BASE64 (NEW FUNCTION)
    -- ===============================
    FUNCTION mark_attendance_in_base64 (
        p_emp_code      IN VARCHAR2,
        p_scan_type     IN VARCHAR2 DEFAULT 'QR',
        p_device_info   IN VARCHAR2 DEFAULT NULL,
        p_photo_base64  IN CLOB DEFAULT NULL
    ) RETURN VARCHAR2 IS
        v_photo_blob BLOB;
        v_photo_name VARCHAR2(200);
    BEGIN
        -- Convert base64 to blob if provided
        IF p_photo_base64 IS NOT NULL THEN
            v_photo_blob := base64_to_blob(p_photo_base64);
            v_photo_name := 'CHECKIN_' || TO_CHAR(SYSTIMESTAMP, 'YYYYMMDD_HH24MISS') || '.jpg';
        END IF;
        
        RETURN mark_attendance_in(
            p_emp_code => p_emp_code,
            p_scan_type => p_scan_type,
            p_device_info => p_device_info,
            p_photo_blob => v_photo_blob,
            p_photo_name => v_photo_name
        );
    END mark_attendance_in_base64;


    -- ===============================
    -- MARK ATTENDANCE OUT WITH BASE64 (NEW FUNCTION)
    -- ===============================
    FUNCTION mark_attendance_out_base64 (
        p_emp_code      IN VARCHAR2,
        p_scan_type     IN VARCHAR2 DEFAULT 'QR',
        p_device_info   IN VARCHAR2 DEFAULT NULL,
        p_photo_base64  IN CLOB DEFAULT NULL
    ) RETURN VARCHAR2 IS
        v_photo_blob BLOB;
        v_photo_name VARCHAR2(200);
    BEGIN
        -- Convert base64 to blob if provided
        IF p_photo_base64 IS NOT NULL THEN
            v_photo_blob := base64_to_blob(p_photo_base64);
            v_photo_name := 'CHECKOUT_' || TO_CHAR(SYSTIMESTAMP, 'YYYYMMDD_HH24MISS') || '.jpg';
        END IF;
        
        RETURN mark_attendance_out(
            p_emp_code => p_emp_code,
            p_scan_type => p_scan_type,
            p_device_info => p_device_info,
            p_photo_blob => v_photo_blob,
            p_photo_name => v_photo_name
        );
    END mark_attendance_out_base64;


    -- ===============================
    -- BASE64 TO BLOB CONVERSION (NEW HELPER FUNCTION)
    -- ===============================
    FUNCTION base64_to_blob(p_base64 CLOB) RETURN BLOB IS
        v_blob BLOB;
        v_clob CLOB := p_base64;
        v_offset NUMBER := 1;
        v_temp VARCHAR2(32767);
        v_amount NUMBER;
    BEGIN
        -- Remove data URL prefix if present
        IF v_clob LIKE 'data:image/%' THEN
            v_clob := SUBSTR(v_clob, INSTR(v_clob, ',') + 1);
        END IF;
        
        DBMS_LOB.CREATETEMPORARY(v_blob, TRUE);
        
        FOR i IN 1..CEIL(DBMS_LOB.GETLENGTH(v_clob) / 32767) LOOP
            v_temp := DBMS_LOB.SUBSTR(v_clob, 32767, v_offset);
            v_amount := LENGTH(v_temp);
            v_blob := UTL_RAW.CAST_TO_BLOB(UTL_ENCODE.BASE64_DECODE(UTL_RAW.CAST_TO_RAW(v_temp)));
            v_offset := v_offset + v_amount;
        END LOOP;
        
        RETURN v_blob;
    END base64_to_blob;


    -- ===============================
    -- GET TODAY'S ATTENDANCE WITH PHOTO INFO (NEW FUNCTION)
    -- ===============================
    FUNCTION get_today_attendance_details (
        p_emp_code IN VARCHAR2
    ) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
        v_emp_id employee.emp_id%TYPE;
    BEGIN
        SELECT emp_id INTO v_emp_id
        FROM employee
        WHERE emp_code = p_emp_code
          AND is_active = 'Y';
        
        OPEN v_cursor FOR
            SELECT 
                a.attendance_id,
                TO_CHAR(a.in_time, 'HH24:MI:SS') AS in_time,
                TO_CHAR(a.out_time, 'HH24:MI:SS') AS out_time,
                a.total_hours,
                a.status,
                CASE WHEN a.in_photo IS NOT NULL THEN 'YES' ELSE 'NO' END AS has_in_photo,
                CASE WHEN a.out_photo IS NOT NULL THEN 'YES' ELSE 'NO' END AS has_out_photo,
                a.in_photo_name,
                a.out_photo_name,
                e.emp_name,
                e.department
            FROM attendance a
            JOIN employee e ON a.emp_id = e.emp_id
            WHERE a.emp_id = v_emp_id
              AND TRUNC(a.attendance_date) = TRUNC(SYSDATE);
              
        RETURN v_cursor;
    END get_today_attendance_details;


    -- ===============================
    -- GET PHOTO BY ATTENDANCE ID (NEW FUNCTION)
    -- ===============================
    FUNCTION get_photo_by_attendance (
        p_attendance_id IN NUMBER,
        p_photo_type    IN VARCHAR2 -- 'IN' or 'OUT'
    ) RETURN BLOB IS
        v_photo BLOB;
    BEGIN
        IF p_photo_type = 'IN' THEN
            SELECT in_photo INTO v_photo
            FROM attendance
            WHERE attendance_id = p_attendance_id;
        ELSE
            SELECT out_photo INTO v_photo
            FROM attendance
            WHERE attendance_id = p_attendance_id;
        END IF;
        
        RETURN v_photo;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END get_photo_by_attendance;


    -- ===============================
    -- GET TODAY STATUS (YOUR ORIGINAL FUNCTION - UNCHANGED)
    -- ===============================
    FUNCTION get_today_status (
        p_emp_code IN VARCHAR2
    ) RETURN VARCHAR2 IS
        v_status attendance.status%TYPE;
        v_emp_id employee.emp_id%TYPE;
    BEGIN
        SELECT emp_id INTO v_emp_id
        FROM employee
        WHERE emp_code = p_emp_code
          AND is_active = 'Y';

        SELECT status
        INTO v_status
        FROM attendance
        WHERE emp_id = v_emp_id
          AND attendance_date = TRUNC(SYSDATE)
          FETCH FIRST 1 ROW ONLY;

        RETURN 'STATUS: ' || v_status;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'No attendance marked today';
        WHEN OTHERS THEN
            RETURN 'ERROR: ' || SQLERRM;
    END get_today_status;


    -- ===============================
    -- CALCULATE DAILY HOURS (YOUR ORIGINAL PROCEDURE - UNCHANGED)
    -- ===============================
    PROCEDURE calculate_daily_hours (
        p_attendance_id IN NUMBER
    ) IS
    BEGIN
        UPDATE attendance
        SET total_hours = ROUND(
                (CAST(out_time AS DATE) - CAST(in_time AS DATE)) * 24,
                2
            ),
            status = CASE 
                WHEN (CAST(out_time AS DATE) - CAST(in_time AS DATE)) * 24 >= 8 THEN 'PRESENT'
                WHEN (CAST(out_time AS DATE) - CAST(in_time AS DATE)) * 24 >= 4 THEN 'HALF-DAY'
                ELSE 'ABSENT'
            END
        WHERE attendance_id = p_attendance_id
          AND in_time IS NOT NULL 
          AND out_time IS NOT NULL;
    END calculate_daily_hours;


    -- ===============================
    -- MARK ABSENT EMPLOYEES (YOUR ORIGINAL PROCEDURE - UNCHANGED)
    -- ===============================
    PROCEDURE mark_absent_employee IS
    BEGIN
        INSERT INTO attendance (
            attendance_id, emp_id, attendance_date, status, remarks
        )
        SELECT seq_attendance_id.NEXTVAL, e.emp_id, TRUNC(SYSDATE), 
               'ABSENT', 'Auto-marked absent'
        FROM employee e
        WHERE e.is_active = 'Y'
          AND NOT EXISTS (
              SELECT 1 
              FROM attendance a 
              WHERE a.emp_id = e.emp_id 
                AND a.attendance_date = TRUNC(SYSDATE)
          )
          AND TRUNC(SYSDATE) NOT IN (
              SELECT holiday_date FROM holidays
          );
    END mark_absent_employee;

END pkg_attendance;
