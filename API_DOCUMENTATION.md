# EduPage API Documentation
**Server:** http://136.116.64.6
**API Version:** 1.0

---

## AUTHENTICATION ENDPOINTS

### POST /api/auth/login
**Operation:** login
**Request Body:** LoginRequest
`json
{
  "email": "string" (required),
  "password": "string" (required)
}
`
**Response:** AuthResponse
`json
{
  "token": "string",
  "type": "string",
  "userId": int64,
  "email": "string",
  "firstName": "string",
  "lastName": "string",
  "role": "STUDENT|TEACHER|ADMIN|ACCOUNTANT",
  "profileId": int64,
  "classGroupId": int64
}
`

### POST /api/auth/register
**Operation:** register (Admin only)
**Request Body:** RegisterRequest
`json
{
  "email": "string" (required),
  "password": "string (min 6 chars)" (required),
  "firstName": "string" (required),
  "lastName": "string" (required),
  "role": "STUDENT|TEACHER|ADMIN|ACCOUNTANT" (required),
  "classGroupId": int64 (optional, for students),
  "subjectIds": [int64] (optional, for teachers)
}
`

### POST /api/auth/register/initial
**Operation:** registerInitialAdmin (Public, first-time setup)
**Request Body:** Same as /api/auth/register but role fixed to ADMIN

### POST /api/auth/forgot-password
**Query Parameters:**
- email (string, required)

### POST /api/auth/reset-password
**Query Parameters:**
- token (string, required)
- password (string, required)
- confirmPassword (string, required)

---

## ADMIN ENDPOINTS

### GET /api/admin/users
**Returns:** List of UserDTO

### GET /api/admin/students
**Returns:** List of StudentDTO
`json
[{
  "id": int64,
  "userId": int64,
  "name": "string",
  "email": "string",
  "classGroupId": int64,
  "classGroupName": "string",
  "studentNumber": "string",
  "accountNumber": "string"
}]
`

### GET /api/admin/students/unassigned
**Returns:** Students without class group assignment

### GET /api/admin/students/class/{classGroupId}
**Path Parameter:** classGroupId (int64)
**Returns:** List of StudentDTO for that class

### PUT /api/admin/students/{studentId}/class
**Path Parameter:** studentId (int64)
**Request Body:** UpdateStudentClassRequest
`json
{
  "classGroupId": int64
}
`

### PUT /api/admin/students/bulk-assign
**Request Body:** BulkAssignRequest
`json
{
  "studentIds": [int64],
  "classGroupId": int64
}
`

### GET /api/admin/teachers
**Returns:** List of TeacherDTO
`json
[{
  "id": int64,
  "userId": int64,
  "name": "string",
  "email": "string",
  "subjects": ["string"],
  "employeeNumber": "string"
}]
`

### PUT /api/admin/teachers/{teacherId}/subjects
**Path Parameter:** teacherId (int64)
**Request Body:** UpdateTeacherSubjectsRequest
`json
{
  "subjectIds": [int64]
}
`

### GET /api/admin/class-groups
**Returns:** List of ClassGroupDTO
`json
[{
  "id": int64,
  "name": "string",
  "grade": int32,
  "monthlyFee": int32,
  "studentCount": int64
}]
`

### POST /api/admin/class-groups
**Request Body:** CreateClassGroupRequest
`json
{
  "name": "string",
  "grade": int32,
  "monthlyFee": int32
}
`

### PUT /api/admin/class-groups/{id}
**Path Parameter:** id (int64)
**Request Body:** CreateClassGroupRequest (same as POST)

### DELETE /api/admin/class-groups/{id}
**Path Parameter:** id (int64)

### GET /api/admin/subjects
**Returns:** List of SubjectDTO
`json
[{
  "id": int64,
  "name": "string",
  "description": "string",
  "hoursPerWeek": int32
}]
`

---

## SCHEDULE ENDPOINTS

### GET /api/schedule/week
**Returns:** User's weekly schedule (ScheduleDTO[])

### GET /api/schedule/class/{classGroupId}
**Path Parameter:** classGroupId (int64)
**Returns:** Schedule for class group

### GET /api/schedule/teacher/{teacherId}
**Path Parameter:** teacherId (int64)
**Returns:** Schedule for teacher

### POST /api/schedule
**Request Body:** CreateScheduleRequest
`json
{
  "classGroupId": int64 (required),
  "teacherId": int64 (required),
  "subjectId": int64 (required),
  "dayOfWeek": "MONDAY|TUESDAY|..." (required),
  "startTime": {"hour": int, "minute": int} (required),
  "endTime": {"hour": int, "minute": int} (required),
  "room": "string",
  "lessonNumber": int32
}
`

### POST /api/schedule/generate
**Request Body:** GenerateScheduleRequest
`json
{
  "classGroupIds": [int64] (required),
  "teacherSubjectMappings": [{
    "teacherId": int64,
    "subjectId": int64,
    "classGroupIds": [int64]
  }] (required),
  "dayStartTime": {"hour": int, "minute": int},
  "dayEndTime": {"hour": int, "minute": int},
  "lessonDurationMinutes": int32,
  "breakDurationMinutes": int32
}
`

### DELETE /api/schedule/{id}
**Path Parameter:** id (int64)

---

## ATTENDANCE ENDPOINTS

### GET /api/attendance
**Returns:** Current user's attendance records

### GET /api/attendance/student/{studentId}
**Path Parameter:** studentId (int64)
**Returns:** Student's attendance records

### GET /api/attendance/schedule/{scheduleId}
**Path Parameter:** scheduleId (int64)
**Query Parameter:** date (date format)
**Returns:** Attendance for specific schedule and date

### GET /api/attendance/range
**Query Parameters:**
- startDate (date, required)
- endDate (date, required)
**Returns:** Attendance in date range

### GET /api/attendance/stats
**Returns:** Attendance statistics

### POST /api/attendance
**Request Body:** MarkAttendanceRequest
`json
{
  "scheduleId": int64 (required),
  "date": "2024-01-15" (required),
  "attendanceRecords": [{
    "studentId": int64 (required),
    "status": "PRESENT|ABSENT|LATE|EXCUSED" (required),
    "notes": "string"
  }] (required)
}
`

---

## GRADES ENDPOINTS

### GET /api/grades
**Returns:** Current user's grades

### GET /api/grades/student/{studentId}
**Path Parameter:** studentId (int64)
**Returns:** Student's grades

### GET /api/grades/subject/{subjectId}
**Path Parameter:** subjectId (int64)
**Returns:** User's grades for subject

### GET /api/grades/averages
**Returns:** Grade averages by subject

### POST /api/grades
**Request Body:** CreateGradeRequest
`json
{
  "studentId": int64 (required),
  "subjectId": int64 (required),
  "value": double (required),
  "maxValue": double,
  "gradeType": "string",
  "description": "string",
  "date": "2024-01-15" (required)
}
`

### DELETE /api/grades/{id}
**Path Parameter:** id (int64)

---

## INVOICE ENDPOINTS

### GET /api/invoices/student/{studentId}
**Path Parameter:** studentId (int64)
**Returns:** List of Invoice
`json
[{
  "id": int64,
  "student": {...},
  "amountDue": int32,
  "amountPaid": int32,
  "dueDate": "2024-01-15",
  "status": "UNPAID|PARTIALLY_PAID|PAID|OVERDUE|CANCELLED",
  "year": int32,
  "month": int32,
  "createdAt": "datetime",
  "updatedAt": "datetime"
}]
`

### GET /api/invoices/search
**Query Parameter:** accountNumber (string)
**Returns:** Invoices matching account number

### GET /api/invoices/debt/{studentId}
**Path Parameter:** studentId (int64)
**Returns:** Debt summary (map of month/year to amount)

### POST /api/invoices/generate/student
**Query Parameters:**
- studentId (int64, required)
- year (int32, required)
- month (int32, required)
**Returns:** Generated invoice

### POST /api/invoices/generate/group
**Query Parameters:**
- groupId (int64, required)
- year (int32, required)
- month (int32, required)
**Returns:** List of generated invoices

---

## PAYMENT ENDPOINTS

### GET /api/payment/pending
**Returns:** Pending payments

### GET /api/payment/search
**Query Parameter:** accountNumber (string)
**Returns:** Payments for account

### POST /api/payment/submit
**Request Body:** PaymentRequest
`json
{
  "accountNumber": "string",
  "amount": int32,
  "receiptNumber": "string"
}
`

### POST /api/payment/{id}/approve
**Path Parameter:** id (int64)
**Returns:** Updated payment

### POST /api/payment/{id}/reject
**Path Parameter:** id (int64)
**Returns:** Updated payment

---

## ANNOUNCEMENT ENDPOINTS

### GET /api/announcements
**Returns:** User's announcements

### GET /api/announcements/all
**Returns:** All announcements

### POST /api/announcements
**Request Body:** CreateAnnouncementRequest
`json
{
  "title": "string" (required),
  "content": "string" (required),
  "targetRole": "STUDENT|TEACHER|ADMIN|ACCOUNTANT",
  "targetClassGroupId": int64,
  "important": boolean,
  "expiresAt": "datetime"
}
`

### DELETE /api/announcements/{id}
**Path Parameter:** id (int64)

