DECLARE
    l_html           CLOB;
    l_total_present  NUMBER;
    l_total_absent   NUMBER;
    l_on_leave       NUMBER;
BEGIN
    -- Get today's stats
    SELECT COUNT(*) INTO l_total_present 
    FROM attendance 
    WHERE attendance_date = TRUNC(SYSDATE) 
    AND status = 'PRESENT';
    
    SELECT COUNT(*) INTO l_total_absent 
    FROM attendance 
    WHERE attendance_date = TRUNC(SYSDATE) 
    AND status = 'ABSENT';
    
    SELECT COUNT(*) INTO l_on_leave 
    FROM leave_requests 
    WHERE leave_date = TRUNC(SYSDATE) 
    AND approval_status = 'APPROVED';

    -- Build HTML
    l_html := '
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">

    <div class="dashboard">
        <h2 class="title">📊 Attendance Dashboard</h2>

        <div class="stats-container">
            <div class="stat-card present">
                <i class="fas fa-user-check icon"></i>
                <h3>Present</h3>
                <div class="stat-value">' || l_total_present || '</div>
            </div>

            <div class="stat-card absent">
                <i class="fas fa-user-times icon"></i>
                <h3>Absent</h3>
                <div class="stat-value">' || l_total_absent || '</div>
            </div>

            <div class="stat-card leave">
                <i class="fas fa-user-clock icon"></i>
                <h3>On Leave</h3>
                <div class="stat-value">' || l_on_leave || '</div>
            </div>
        </div>

        <div class="recent-activity">
            <h3>🕒 Recent Activity</h3>
            <table class="activity-table">
                <thead>
                    <tr>
                        <th>Code</th>
                        <th>Employee</th>
                        <th>In</th>
                        <th>Out</th>
                        <th>Total Time</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>';

    -- Loop for records
    FOR rec IN (
        SELECT 
            e.emp_code,
            e.emp_name,
            a.in_time,
            a.out_time,

            -- Total minutes
            ROUND(
                (CAST(a.out_time AS DATE) - CAST(a.in_time AS DATE)) * 1440,
                2
            ) AS total_minutes,

            -- Auto status logic
            CASE 
                WHEN a.out_time IS NULL OR a.in_time IS NULL THEN 'ABSENT'
                WHEN (CAST(a.out_time AS DATE) - CAST(a.in_time AS DATE)) * 1440 < 1 THEN 'ABSENT'
                ELSE 'PRESENT'
            END AS final_status

        FROM attendance a
        JOIN employees e ON a.emp_id = e.emp_id

        WHERE TRUNC(a.attendance_date) = TRUNC(SYSDATE)

        ORDER BY a.in_time DESC
        FETCH FIRST 10 ROWS ONLY
    ) LOOP

        l_html := l_html || '
        <tr>
            <td class="emp-code">' || rec.emp_code || '</td>

            <td>
                <div class="emp-info">
                    <div class="avatar">' || SUBSTR(rec.emp_name,1,1) || '</div>
                    <span>' || rec.emp_name || '</span>
                </div>
            </td>

            <td>' || NVL(TO_CHAR(rec.in_time, 'HH24:MI'), '--') || '</td>

            <td>' || NVL(TO_CHAR(rec.out_time, 'HH24:MI'), '--') || '</td>

            <td>' || NVL(rec.total_minutes,0) || ' min</td>

            <td>
                <span class="badge ' || LOWER(rec.final_status) || '">' || rec.final_status || '</span>
            </td>
        </tr>';

    END LOOP;

    -- Close HTML
    l_html := l_html || '
                </tbody>
            </table>
        </div>
    </div>';

    -- CSS Styling
    sys.htp.p('
    <style>
        body {
            font-family: "Segoe UI", sans-serif;
            background: linear-gradient(to right, #eef2f3, #ffffff);
            margin: 0;
            padding: 20px;
        }

        .title {
            margin-bottom: 15px;
            color: #2c3e50;
            text-align: center;
            font-size: 30px;
        }

        .stats-container {
            display: flex;
            gap: 20px;
            margin: 20px 0;
        }

        .stat-card {
            flex: 1;
            padding: 25px;
            border-radius: 15px;
            color: white;
            box-shadow: 0 10px 25px rgba(0,0,0,0.1);
            transition: all 0.3s ease;
        }

        .stat-card:hover {
            transform: scale(1.05);
        }

        .icon {
            font-size: 28px;
            margin-bottom: 10px;
        }

        .stat-value {
            font-size: 40px;
            font-weight: bold;
        }

        .present { background: linear-gradient(135deg, #00b09b, #96c93d); }
        .absent { background: linear-gradient(135deg, #ff416c, #ff4b2b); }
        .leave  { background: linear-gradient(135deg, #f7971e, #ffd200); color:black; }

        .recent-activity {
            background: white;
            padding: 20px;
            border-radius: 15px;
            box-shadow: 0 8px 20px rgba(0,0,0,0.08);
            font-size: 16px;
        }

        .activity-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 15px;
        }

        .activity-table thead {
            background: #f8f9fa;
        }

        .activity-table th {
            padding: 12px;
            text-align: left;
        }

        .activity-table td {
            padding: 12px;
            border-bottom: 1px solid #eee;
        }

        .activity-table tr:hover {
            background: #f5f7fa;
        }

        .emp-info {
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .avatar {
            width: 32px;
            height: 32px;
            border-radius: 50%;
            background: #6c5ce7;
            color: white;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
        }

        .emp-code {
            font-weight: bold;
            color: #555;
        }

        .badge {
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: bold;
        }

        .badge.present { background: #28a745; color: white; }
        .badge.absent { background: #dc3545; color: white; }
        .badge.half-day { background: #ffc107; color: black; }
    </style>');

    RETURN l_html;
END;