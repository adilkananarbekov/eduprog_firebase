# Backend Structure Analysis
**Server:** http://136.116.64.6

## ✅ Backend is Properly Set Up

### 1. **Role-Based Access Control (RBAC)**
The backend implements 4 user roles:
- **STUDENT** - Can view their own grades, attendance, schedule, announcements
- **TEACHER** - Can view assigned classes, mark attendance, enter grades
- **ADMIN** - Full access to manage users, groups, schedules
- **ACCOUNTANT** - Access to billing and payment features

### 2. **Data Relationships**

```
┌─────────────┐
│    USER     │
│  (Auth)     │
└──────┬──────┘
       │
       ├─────────────┐
       │             │
       ▼             ▼
┌─────────┐    ┌──────────┐
│ STUDENT │    │ TEACHER  │
└────┬────┘    └────┬─────┘
     │              │
     │              │ subjects[]
     │ classGroup   │
     │              ▼
     │         ┌──────────┐
     │         │ SUBJECT  │
     │         └────┬─────┘
     │              │
     ▼              │
┌────────────┐      │
│ CLASSGROUP │◄─────┘
│  - grade   │
│  - fee     │
└──────┬─────┘
       │
       │ students[]
       ▼
  [Student List]
```

### 3. **Student Data Flow**

**When a student logs in:**
```
1. POST /api/auth/login → Returns AuthResponse
   {
     token: "JWT_TOKEN",
     userId: 123,
     role: "STUDENT",
     profileId: 456,  // studentId
     classGroupId: 789
   }

2. Student can access:
   - GET /api/grades → Their grades across all subjects
   - GET /api/attendance → Their attendance records
   - GET /api/schedule/week → Their weekly class schedule
   - GET /api/announcements → School announcements
   - GET /api/invoices/student/{studentId} → Their invoices
```

**Student Profile includes:**
- Personal info (name, email, studentNumber, accountNumber)
- Class group assignment
- Link to User account (for auth)

### 4. **Teacher Data Flow**

**When a teacher logs in:**
```
1. POST /api/auth/login → Returns AuthResponse
   {
     token: "JWT_TOKEN",
     userId: 123,
     role: "TEACHER",
     profileId: 456  // teacherId
   }

2. Teacher profile includes:
   - subjects: ["Mathematics", "Physics"]  ← Array of assigned subjects
   - employeeNumber
   
3. Teacher can:
   - GET /api/schedule/teacher/{teacherId} → Their teaching schedule
   - POST /api/grades → Enter grades for students
   - POST /api/attendance → Mark attendance for their classes
   - GET /api/schedule/week → View their weekly schedule
```

**Teacher-Subject Relationship:**
- Admin assigns subjects to teacher via:
  ```
  PUT /api/admin/teachers/{teacherId}/subjects
  Body: { subjectIds: [1, 2, 3] }
  ```
- Teacher can teach multiple subjects
- TeacherDTO returns `subjects` array with subject names

### 5. **Schedule System**

**Schedule connects everything:**
```
SCHEDULE
  ├─ classGroupId → Which class
  ├─ teacherId → Who teaches
  ├─ subjectId → What subject
  ├─ dayOfWeek → When (MONDAY, TUESDAY, ...)
  ├─ startTime → 08:00
  ├─ endTime → 09:30
  └─ room → "Room 101"
```

**Attendance is linked to Schedule:**
```
ATTENDANCE
  ├─ studentId → Who
  ├─ scheduleId → Which lesson (links to specific schedule entry)
  ├─ date → 2024-01-15
  └─ status → PRESENT|ABSENT|LATE|EXCUSED
```

**This means:**
- Attendance is marked per lesson (schedule entry)
- Each schedule entry represents a specific class-subject-teacher combination
- Students' attendance is tracked across all their scheduled lessons

### 6. **Invoice & Payment System**

**Invoice Generation:**
```
1. Admin generates invoice:
   POST /api/invoices/generate/student?studentId=123&year=2024&month=1
   
2. Backend creates invoice:
   {
     amountDue: classGroup.monthlyFee,
     amountPaid: 0,
     status: "UNPAID",
     year: 2024,
     month: 1
   }

3. Student/Parent can view:
   GET /api/invoices/student/123
```

**Payment Flow:**
```
1. Parent submits payment proof:
   POST /api/payment/submit
   {
     accountNumber: "student_account",
     amount: 50000,
     receiptNumber: "REC123"
   }

2. Payment status: PENDING

3. Admin/Accountant reviews:
   - POST /api/payment/{id}/approve → Updates invoice
   - POST /api/payment/{id}/reject → Rejects payment
```

### 7. **Authorization Matrix**

| Endpoint | Student | Teacher | Admin | Accountant |
|----------|---------|---------|-------|------------|
| GET /api/grades | ✅ Own | ✅ View | ✅ All | ❌ |
| POST /api/grades | ❌ | ✅ | ✅ | ❌ |
| GET /api/attendance | ✅ Own | ✅ View | ✅ All | ❌ |
| POST /api/attendance | ❌ | ✅ Mark | ✅ | ❌ |
| GET /api/schedule/week | ✅ | ✅ | ✅ | ❌ |
| GET /api/invoices/student/{id} | ✅ Own | ❌ | ✅ All | ✅ All |
| POST /api/payment/submit | ✅ | ❌ | ✅ | ❌ |
| POST /api/payment/approve | ❌ | ❌ | ✅ | ✅ |
| GET /api/admin/* | ❌ | ❌ | ✅ | ❌ |

## ⚠️ IMPORTANT: Flutter App Mismatches

Your Flutter app has these issues:

### Issue 1: ClassGroup Model
**Backend returns:**
```json
{
  "id": 1,
  "name": "Grade 10A",
  "grade": 10,
  "monthlyFee": 50000,
  "studentCount": 25
}
```

**Flutter expects:**
```dart
class ClassGroup {
  final String? description;  // ❌ Doesn't exist
  final int? capacity;        // ❌ Doesn't exist
  final int? currentStudents; // ❌ Should be 'studentCount'
}
```

### Issue 2: Invoice Model
**Backend returns:**
```json
{
  "id": 1,
  "student": { /* nested object */ },
  "amountDue": 50000,
  "amountPaid": 0,
  "status": "UNPAID",
  "year": 2024,
  "month": 1
}
```

**Flutter expects:**
```dart
class Invoice {
  final double amount;        // ❌ Should be 'amountDue'
  final bool isPaid;          // ❌ Should be 'status' enum
  final String? studentName;  // ❌ Nested in 'student' object
}
```

### Issue 3: Create Class Group
**Backend accepts:**
```json
{
  "name": "Grade 10A",
  "grade": 10,
  "monthlyFee": 50000
}
```

**Flutter sends:**
```dart
{
  "name": "Grade 10A",
  "description": "...",  // ❌ Not accepted
  "capacity": 30         // ❌ Not accepted
}
```

## 🎯 Next Steps

1. **Test with real credentials** - Login and verify data flow
2. **Fix Flutter models** - Match backend response schemas
3. **Fix API requests** - Send correct request bodies
4. **Test each role** - Verify student/teacher/admin access works

---

**Backend Status:** ✅ Properly structured with relationships
**Flutter App Status:** ⚠️ Needs model/API fixes to work with backend
