[CmdletBinding()]
param(
  [string]$ProjectId = 'eduops-25a60',
  [string]$ApiKey = 'AIzaSyCm-wtRI2Q5sUndOH2tZP__dkA4kL8id58',
  [switch]$Apply
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Step([string]$Message) {
  Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] $Message"
}

function Ensure-WorkspacePath([string]$RelativePath) {
  $fullPath = Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')) $RelativePath
  $directory = Split-Path -Path $fullPath -Parent
  if ($directory -and -not (Test-Path $directory)) {
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
  }
  return $fullPath
}

function Get-SafeString($Value) {
  if ($null -eq $Value) {
    return ''
  }
  return [string]$Value
}

function Split-DisplayName([string]$DisplayName, [string]$Email) {
  $trimmed = (Get-SafeString $DisplayName).Trim()
  if ($trimmed.Length -eq 0) {
    $localPart = $Email.Split('@')[0]
    $parts = $localPart -split '[._\-]+' | Where-Object { $_.Trim().Length -gt 0 }
    if ($parts.Count -eq 0) {
      return @{
        FirstName = 'User'
        LastName = ''
      }
    }
    if ($parts.Count -eq 1) {
      return @{
        FirstName = (Get-Culture).TextInfo.ToTitleCase($parts[0])
        LastName = ''
      }
    }
    return @{
      FirstName = (Get-Culture).TextInfo.ToTitleCase($parts[0])
      LastName = (($parts | Select-Object -Skip 1) -join ' ')
    }
  }

  $tokens = $trimmed -split '\s+' | Where-Object { $_.Trim().Length -gt 0 }
  if ($tokens.Count -eq 1) {
    return @{
      FirstName = $tokens[0]
      LastName = ''
    }
  }

  return @{
    FirstName = $tokens[0]
    LastName = (($tokens | Select-Object -Skip 1) -join ' ')
  }
}

function ConvertTo-FirestoreValue($Value) {
  if ($null -eq $Value) {
    return @{ nullValue = $null }
  }

  if ($Value -is [string]) {
    return @{ stringValue = $Value }
  }

  if ($Value -is [bool]) {
    return @{ booleanValue = $Value }
  }

  if ($Value -is [datetime]) {
    return @{ timestampValue = $Value.ToUniversalTime().ToString('o') }
  }

  if ($Value -is [byte] -or
      $Value -is [int16] -or
      $Value -is [int32] -or
      $Value -is [int64] -or
      $Value -is [uint16] -or
      $Value -is [uint32] -or
      $Value -is [uint64]) {
    return @{ integerValue = "$Value" }
  }

  if ($Value -is [single] -or
      $Value -is [double] -or
      $Value -is [decimal]) {
    return @{ doubleValue = [double]$Value }
  }

  if ($Value -is [System.Collections.IDictionary]) {
    return @{
      mapValue = @{
        fields = ConvertTo-FirestoreFields $Value
      }
    }
  }

  if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
    $values = @()
    foreach ($item in $Value) {
      $values += ,(ConvertTo-FirestoreValue $item)
    }
    return @{
      arrayValue = @{
        values = $values
      }
    }
  }

  return @{ stringValue = $Value.ToString() }
}

function ConvertTo-FirestoreFields([System.Collections.IDictionary]$Data) {
  $fields = [ordered]@{}
  foreach ($key in $Data.Keys) {
    $fields[$key] = ConvertTo-FirestoreValue $Data[$key]
  }
  return $fields
}

function Refresh-AccessToken {
  & firebase projects:list --project $ProjectId --json | Out-Null
  $configPath = Join-Path $env:USERPROFILE '.config\configstore\firebase-tools.json'
  $config = Get-Content $configPath | ConvertFrom-Json
  return $config.tokens.access_token
}

$script:AccessToken = $null

function Get-AccessToken {
  if (-not $script:AccessToken) {
    $script:AccessToken = Refresh-AccessToken
  }
  return $script:AccessToken
}

function Invoke-GoogleJsonRequest {
  param(
    [string]$Method,
    [string]$Uri,
    $Body = $null
  )

  $attempt = 0
  while ($attempt -lt 2) {
    $attempt += 1
    try {
      $headers = @{
        Authorization = "Bearer $(Get-AccessToken)"
        'Content-Type' = 'application/json'
      }
      if ($null -ne $Body) {
        $json = $Body | ConvertTo-Json -Depth 100 -Compress
        return Invoke-RestMethod -Method $Method -Headers $headers -Uri $Uri -Body $json
      }
      return Invoke-RestMethod -Method $Method -Headers $headers -Uri $Uri
    } catch {
      if ($attempt -ge 2) {
        throw
      }
      $script:AccessToken = Refresh-AccessToken
    }
  }
}

function Get-CollectionIds {
  $uri = "https://firestore.googleapis.com/v1/projects/$ProjectId/databases/(default)/documents:listCollectionIds"
  $response = Invoke-GoogleJsonRequest -Method Post -Uri $uri -Body @{}
  return @($response.collectionIds)
}

function Get-CollectionDocuments([string]$CollectionId) {
  $documents = @()
  $pageToken = $null

  do {
    $uri = "https://firestore.googleapis.com/v1/projects/$ProjectId/databases/(default)/documents/$($CollectionId)?pageSize=200"
    if ($pageToken) {
      $uri += "&pageToken=$([uri]::EscapeDataString($pageToken))"
    }

    $response = Invoke-GoogleJsonRequest -Method Get -Uri $uri
    if ($null -ne $response -and $response.PSObject.Properties.Name -contains 'documents') {
      $documents += @($response.documents)
    }
    $pageToken = if ($null -ne $response -and $response.PSObject.Properties.Name -contains 'nextPageToken') {
      $response.nextPageToken
    } else {
      $null
    }
  } while ($pageToken)

  return $documents
}

function Backup-FirestoreCollections([string]$BackupDirectory) {
  Write-Step 'Backing up current Firestore collections'
  $collectionIds = Get-CollectionIds
  $collectionIds | ConvertTo-Json | Set-Content (Join-Path $BackupDirectory 'collection-ids.json')

  foreach ($collectionId in $collectionIds) {
    $documents = Get-CollectionDocuments -CollectionId $collectionId
    $documents |
      ConvertTo-Json -Depth 100 |
      Set-Content (Join-Path $BackupDirectory "$collectionId.json")
  }
}

function Export-AuthUsers([string]$OutputPath) {
  Write-Step 'Exporting Firebase Auth users backup'
  & firebase auth:export $OutputPath --format=json --project $ProjectId | Out-Null
}

function Invoke-IdentityToolkitRequest {
  param(
    [string]$Path,
    [hashtable]$Body
  )

  $uri = "https://identitytoolkit.googleapis.com/v1/projects/$ProjectId/$($Path)"
  return Invoke-GoogleJsonRequest -Method Post -Uri $uri -Body $Body
}

function Ensure-AuthUser {
  param(
    [hashtable]$Spec,
    [hashtable]$ExistingByEmail
  )

  $email = $Spec.email.ToLowerInvariant()
  $displayName = "$($Spec.firstName) $($Spec.lastName)".Trim()
  $existing = $ExistingByEmail[$email]

  if ($existing) {
    $response = Invoke-IdentityToolkitRequest -Path 'accounts:update' -Body @{
      localId = $existing.localId
      email = $email
      password = $Spec.password
      displayName = $displayName
      disableUser = $false
      emailVerified = $false
    }

    return @{
      uid = $response.localId
      email = $email
    }
  }

  $response = Invoke-IdentityToolkitRequest -Path 'accounts' -Body @{
    email = $email
    password = $Spec.password
    displayName = $displayName
    disabled = $false
    emailVerified = $false
  }

  return @{
    uid = $response.localId
    email = $email
  }
}

function Disable-ExtraAuthUsers {
  param(
    [array]$AuthUsers,
    [System.Collections.Generic.HashSet[string]]$AllowedEmails
  )

  foreach ($user in $AuthUsers) {
    $email = (Get-SafeString $user.email).ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($email)) {
      continue
    }

    if ($AllowedEmails.Contains($email)) {
      continue
    }

    Write-Step "Disabling extra auth user $email"
    Invoke-IdentityToolkitRequest -Path 'accounts:update' -Body @{
      localId = $user.localId
      disableUser = $true
    } | Out-Null
  }
}

function Remove-SeedCollections {
  $paths = @(
    'attendance',
    'announcements',
    'grades',
    'schedules',
    'subjects',
    'class_groups',
    'users',
    'metadata'
  )

  foreach ($path in $paths) {
    Write-Step "Deleting Firestore path $path"
    & firebase firestore:delete --project $ProjectId --recursive --force $path | Out-Null
  }
}

function Set-FirestoreDocument {
  param(
    [string]$CollectionId,
    [string]$DocumentId,
    [hashtable]$Data
  )

  $uri = "https://firestore.googleapis.com/v1/projects/$ProjectId/databases/(default)/documents/$CollectionId/$DocumentId"
  $body = @{
    fields = ConvertTo-FirestoreFields $Data
  }
  Invoke-GoogleJsonRequest -Method Patch -Uri $uri -Body $body | Out-Null
}

function Get-TeacherIdForSubject([int]$SubjectId) {
  switch ($SubjectId) {
    301 { return 101 }
    302 { return 102 }
    303 { return 103 }
    304 { return 104 }
    305 { return 105 }
    default { throw "Unknown subject id $SubjectId" }
  }
}

function Build-SeedSpecs([array]$AuthUsers) {
  $authByEmail = @{}
  foreach ($user in $AuthUsers) {
    if ($user.email) {
      $authByEmail[$user.email.ToLowerInvariant()] = $user
    }
  }

  $specs = @()

  $adminEmail = 'admin@eduops.kg'
  $specs += @{
    email = $adminEmail
    firstName = 'Admin'
    lastName = 'EduOps'
    password = 'Admin123!'
    role = 'ADMIN'
    id = 1
    classGroupId = $null
    classGroupName = $null
    subjectIds = @()
    subjects = @()
  }

  for ($index = 1; $index -le 5; $index++) {
    $email = "teacher$index@eduops.kg"
    $subjectId = 300 + $index
    $existing = $authByEmail[$email]
    $names = Split-DisplayName -DisplayName (Get-SafeString $existing.displayName) -Email $email
    $subjectName = switch ($subjectId) {
      301 { 'Mathematics' }
      302 { 'Computer Science' }
      303 { 'Physics' }
      304 { 'English Language' }
      305 { 'Database Systems' }
    }

    $specs += @{
      email = $email
      firstName = $names.FirstName
      lastName = $names.LastName
      password = 'Teacher123!'
      role = 'TEACHER'
      id = 100 + $index
      classGroupId = $null
      classGroupName = $null
      subjectIds = @($subjectId)
      subjects = @($subjectName)
    }
  }

  for ($index = 1; $index -le 20; $index++) {
    $email = "student$index@eduops.kg"
    $existing = $authByEmail[$email]
    $names = Split-DisplayName -DisplayName (Get-SafeString $existing.displayName) -Email $email

    $group = switch ($index) {
      { $_ -le 5 } { @{ id = 201; name = 'INF-23' } ; break }
      { $_ -le 10 } { @{ id = 202; name = 'COM-23' } ; break }
      { $_ -le 15 } { @{ id = 203; name = 'INF-24' } ; break }
      default { @{ id = 204; name = 'COM-24' } }
    }

    $specs += @{
      email = $email
      firstName = $names.FirstName
      lastName = $names.LastName
      password = 'Student123!'
      role = 'STUDENT'
      id = 1000 + $index
      classGroupId = $group.id
      classGroupName = $group.name
      subjectIds = @()
      subjects = @()
    }
  }

  return $specs
}

function Build-SeedData([array]$ResolvedUsers) {
  $subjects = @(
    @{ id = 301; code = 'MATH'; name = 'Mathematics'; description = 'Core math for upper secondary students.' }
    @{ id = 302; code = 'CS'; name = 'Computer Science'; description = 'Programming, algorithms, and applied computing.' }
    @{ id = 303; code = 'PHYS'; name = 'Physics'; description = 'Mechanics, electricity, and lab-based problem solving.' }
    @{ id = 304; code = 'ENG'; name = 'English Language'; description = 'Academic English communication and reading.' }
    @{ id = 305; code = 'DB'; name = 'Database Systems'; description = 'Relational modeling, SQL, and data management.' }
  )

  $groups = @(
    @{ id = 201; name = 'INF-23'; grade = 11; monthlyFee = 4800 }
    @{ id = 202; name = 'COM-23'; grade = 11; monthlyFee = 4800 }
    @{ id = 203; name = 'INF-24'; grade = 12; monthlyFee = 5200 }
    @{ id = 204; name = 'COM-24'; grade = 12; monthlyFee = 5200 }
  )

  $usersByEmail = @{}
  $usersById = @{}
  foreach ($user in $ResolvedUsers) {
    $usersByEmail[$user.email.ToLowerInvariant()] = $user
    $usersById[[string]$user.id] = $user
  }

  $teacherNameById = @{}
  foreach ($teacher in $ResolvedUsers | Where-Object { $_.role -eq 'TEACHER' }) {
    $teacherNameById[[string]$teacher.id] = "$($teacher.firstName) $($teacher.lastName)".Trim()
  }

  $groupSubjectPlans = @{
    'INF-23' = @(301, 302, 304, 303, 301, 305, 302, 304, 303, 305)
    'COM-23' = @(302, 301, 304, 303, 302, 305, 301, 304, 303, 305)
    'INF-24' = @(301, 305, 304, 303, 302, 301, 305, 304, 303, 302)
    'COM-24' = @(302, 305, 304, 303, 301, 302, 305, 304, 303, 301)
  }

  $scheduleSlots = @(
    @{ day = 'MONDAY'; lesson = 1; start = '08:00'; end = '08:45'; room = '101' }
    @{ day = 'MONDAY'; lesson = 2; start = '09:00'; end = '09:45'; room = 'Lab-1' }
    @{ day = 'TUESDAY'; lesson = 1; start = '08:00'; end = '08:45'; room = '301' }
    @{ day = 'TUESDAY'; lesson = 2; start = '09:00'; end = '09:45'; room = '201' }
    @{ day = 'WEDNESDAY'; lesson = 1; start = '08:00'; end = '08:45'; room = '101' }
    @{ day = 'WEDNESDAY'; lesson = 2; start = '09:00'; end = '09:45'; room = 'Lab-2' }
    @{ day = 'THURSDAY'; lesson = 1; start = '08:00'; end = '08:45'; room = '301' }
    @{ day = 'THURSDAY'; lesson = 2; start = '09:00'; end = '09:45'; room = '201' }
    @{ day = 'FRIDAY'; lesson = 1; start = '08:00'; end = '08:45'; room = '101' }
    @{ day = 'FRIDAY'; lesson = 2; start = '09:00'; end = '09:45'; room = 'Lab-1' }
  )

  $subjectsById = @{}
  foreach ($subject in $subjects) {
    $subjectsById[[string]$subject.id] = $subject
  }

  $schedules = @()
  $nextScheduleId = 4001
  foreach ($group in $groups) {
    $plan = $groupSubjectPlans[$group.name]
    for ($slotIndex = 0; $slotIndex -lt $scheduleSlots.Count; $slotIndex++) {
      $slot = $scheduleSlots[$slotIndex]
      $subjectId = $plan[$slotIndex]
      $subject = $subjectsById[[string]$subjectId]
      $teacherId = Get-TeacherIdForSubject -SubjectId $subjectId
      $teacherName = $teacherNameById[[string]$teacherId]

      $schedules += @{
        id = $nextScheduleId
        classGroupId = $group.id
        classGroupName = $group.name
        subjectId = $subjectId
        subjectName = $subject.name
        teacherId = $teacherId
        teacherName = $teacherName
        dayOfWeek = $slot.day
        startTime = $slot.start
        endTime = $slot.end
        room = $slot.room
      }
      $nextScheduleId += 1
    }
  }

  $grades = @()
  $nextGradeId = 5001
  foreach ($student in $ResolvedUsers | Where-Object { $_.role -eq 'STUDENT' }) {
    $plan = $groupSubjectPlans[$student.classGroupName]
    $uniqueSubjects = @()
    foreach ($subjectId in $plan) {
      if (-not $uniqueSubjects.Contains($subjectId)) {
        $uniqueSubjects += $subjectId
      }
      if ($uniqueSubjects.Count -eq 4) {
        break
      }
    }

    for ($gradeIndex = 0; $gradeIndex -lt $uniqueSubjects.Count; $gradeIndex++) {
      $subjectId = $uniqueSubjects[$gradeIndex]
      $subject = $subjectsById[[string]$subjectId]
      $teacherId = Get-TeacherIdForSubject -SubjectId $subjectId
      $teacherName = $teacherNameById[[string]$teacherId]
      $score = 68 + (($student.id + $subjectId + ($gradeIndex * 7)) % 29)
      $gradeType = @('QUIZ', 'HOMEWORK', 'MIDTERM', 'PROJECT')[$gradeIndex]
      $maxScore = if ($gradeType -eq 'MIDTERM') { 100 } else { 20 }
      if ($maxScore -eq 20) {
        $score = [math]::Round((8 + (($student.id + $subjectId + ($gradeIndex * 5)) % 11) + 0.5), 1)
      }

      $grades += @{
        id = $nextGradeId
        studentId = $student.id
        studentName = "$($student.firstName) $($student.lastName)".Trim()
        subjectId = $subjectId
        subjectName = $subject.name
        teacherId = $teacherId
        teacherName = $teacherName
        score = $score
        maxScore = $maxScore
        gradeType = $gradeType
        date = (Get-Date '2026-02-03').AddDays($gradeIndex)
        notes = "Seeded $gradeType score for $($subject.name)."
        createdAt = (Get-Date '2026-02-03').AddDays($gradeIndex).AddHours(10)
      }
      $nextGradeId += 1
    }
  }

  $schedulesByGroup = @{}
  foreach ($schedule in $schedules) {
    if (-not $schedulesByGroup.ContainsKey($schedule.classGroupName)) {
      $schedulesByGroup[$schedule.classGroupName] = @()
    }
    $schedulesByGroup[$schedule.classGroupName] += ,$schedule
  }

  $attendance = @()
  $nextAttendanceId = 6001
  foreach ($student in $ResolvedUsers | Where-Object { $_.role -eq 'STUDENT' }) {
    $studentSchedules = $schedulesByGroup[$student.classGroupName] | Select-Object -First 6
    foreach ($schedule in $studentSchedules) {
      $statusIndex = ($student.id + $schedule.id) % 10
      $status = if ($statusIndex -eq 0) {
        'ABSENT'
      } elseif ($statusIndex -eq 1) {
        'LATE'
      } elseif ($statusIndex -eq 2) {
        'EXCUSED'
      } else {
        'PRESENT'
      }
      $notes = switch ($status) {
        'LATE' { 'Arrived after the bell.' }
        'EXCUSED' { 'Excused by administration.' }
        'ABSENT' { 'No show recorded.' }
        default { $null }
      }

      $dayOffset = switch ($schedule.dayOfWeek) {
        'MONDAY' { 0 }
        'TUESDAY' { 1 }
        'WEDNESDAY' { 2 }
        'THURSDAY' { 3 }
        'FRIDAY' { 4 }
        default { 0 }
      }

      $attendanceDate = (Get-Date '2026-02-09').AddDays($dayOffset)

      $attendance += @{
        id = $nextAttendanceId
        studentId = $student.id
        studentName = "$($student.firstName) $($student.lastName)".Trim()
        scheduleId = $schedule.id
        subjectName = $schedule.subjectName
        date = $attendanceDate
        status = $status
        notes = $notes
        markedById = $schedule.teacherId
        markedByName = $schedule.teacherName
        markedAt = $attendanceDate.AddHours(11)
      }
      $nextAttendanceId += 1
    }
  }

  $announcements = @(
    @{
      id = 7001
      title = 'Welcome to the spring term'
      content = 'Timetables, attendance, and grades are now synchronized in Firebase for the demo dataset.'
      createdAt = (Get-Date '2026-02-02').AddHours(9)
      authorId = 1
      authorName = 'Admin EduOps'
      classGroupId = $null
      classGroupName = $null
      isGlobal = $true
    }
    @{
      id = 7002
      title = 'INF-23 lab reminder'
      content = 'Computer Science lab on Tuesday starts in Lab-1. Bring your notebook and charger.'
      createdAt = (Get-Date '2026-02-08').AddHours(15)
      authorId = 102
      authorName = $teacherNameById['102']
      classGroupId = 201
      classGroupName = 'INF-23'
      isGlobal = $false
    }
    @{
      id = 7003
      title = 'COM-24 database project'
      content = 'Database Systems project briefs were published. Review requirements before Friday.'
      createdAt = (Get-Date '2026-02-10').AddHours(11)
      authorId = 105
      authorName = $teacherNameById['105']
      classGroupId = 204
      classGroupName = 'COM-24'
      isGlobal = $false
    }
    @{
      id = 7004
      title = 'Attendance policy reminder'
      content = 'Late arrivals and excused absences are tracked separately. Families can review records in the app.'
      createdAt = (Get-Date '2026-02-11').AddHours(8)
      authorId = 1
      authorName = 'Admin EduOps'
      classGroupId = $null
      classGroupName = $null
      isGlobal = $true
    }
  )

  return @{
    subjects = $subjects
    groups = $groups
    schedules = $schedules
    grades = $grades
    attendance = $attendance
    announcements = $announcements
  }
}

function Seed-FirestoreData {
  param(
    [array]$ResolvedUsers,
    [hashtable]$SeedData
  )

  Write-Step 'Writing users collection'
  foreach ($user in $ResolvedUsers) {
    Set-FirestoreDocument -CollectionId 'users' -DocumentId $user.uid -Data @{
      id = $user.id
      uid = $user.uid
      email = $user.email
      firstName = $user.firstName
      lastName = $user.lastName
      role = $user.role
      isActive = $true
      classGroupId = $user.classGroupId
      classGroupName = $user.classGroupName
      subjectIds = $user.subjectIds
      subjects = $user.subjects
      createdAt = Get-Date
      updatedAt = Get-Date
    }
  }

  Write-Step 'Writing class_groups collection'
  foreach ($group in $SeedData.groups) {
    Set-FirestoreDocument -CollectionId 'class_groups' -DocumentId "group-$($group.id)" -Data @{
      id = $group.id
      name = $group.name
      grade = $group.grade
      monthlyFee = $group.monthlyFee
      createdAt = Get-Date
      updatedAt = Get-Date
    }
  }

  Write-Step 'Writing subjects collection'
  foreach ($subject in $SeedData.subjects) {
    Set-FirestoreDocument -CollectionId 'subjects' -DocumentId "subject-$($subject.id)" -Data @{
      id = $subject.id
      name = $subject.name
      code = $subject.code
      description = $subject.description
      createdAt = Get-Date
      updatedAt = Get-Date
    }
  }

  Write-Step 'Writing schedules collection'
  foreach ($schedule in $SeedData.schedules) {
    Set-FirestoreDocument -CollectionId 'schedules' -DocumentId "schedule-$($schedule.id)" -Data @{
      id = $schedule.id
      classGroupId = $schedule.classGroupId
      classGroupName = $schedule.classGroupName
      subjectId = $schedule.subjectId
      subjectName = $schedule.subjectName
      teacherId = $schedule.teacherId
      teacherName = $schedule.teacherName
      dayOfWeek = $schedule.dayOfWeek
      startTime = $schedule.startTime
      endTime = $schedule.endTime
      room = $schedule.room
      createdAt = Get-Date
      updatedAt = Get-Date
    }
  }

  Write-Step 'Writing grades collection'
  foreach ($grade in $SeedData.grades) {
    Set-FirestoreDocument -CollectionId 'grades' -DocumentId "grade-$($grade.id)" -Data @{
      id = $grade.id
      studentId = $grade.studentId
      studentName = $grade.studentName
      subjectId = $grade.subjectId
      subjectName = $grade.subjectName
      teacherId = $grade.teacherId
      teacherName = $grade.teacherName
      score = $grade.score
      maxScore = $grade.maxScore
      gradeType = $grade.gradeType
      date = $grade.date
      notes = $grade.notes
      createdAt = $grade.createdAt
    }
  }

  Write-Step 'Writing attendance collection'
  foreach ($record in $SeedData.attendance) {
    Set-FirestoreDocument -CollectionId 'attendance' -DocumentId "attendance-$($record.id)" -Data @{
      id = $record.id
      studentId = $record.studentId
      studentName = $record.studentName
      scheduleId = $record.scheduleId
      subjectName = $record.subjectName
      date = $record.date
      status = $record.status
      notes = $record.notes
      markedById = $record.markedById
      markedByName = $record.markedByName
      markedAt = $record.markedAt
    }
  }

  Write-Step 'Writing announcements collection'
  foreach ($announcement in $SeedData.announcements) {
    Set-FirestoreDocument -CollectionId 'announcements' -DocumentId "announcement-$($announcement.id)" -Data @{
      id = $announcement.id
      title = $announcement.title
      content = $announcement.content
      createdAt = $announcement.createdAt
      authorId = $announcement.authorId
      authorName = $announcement.authorName
      classGroupId = $announcement.classGroupId
      classGroupName = $announcement.classGroupName
      isGlobal = $announcement.isGlobal
      updatedAt = $announcement.createdAt
    }
  }

  Write-Step 'Writing metadata counters'
  Set-FirestoreDocument -CollectionId 'metadata' -DocumentId 'counters' -Data @{
    nextUserId = 1021
    nextClassGroupId = 205
    nextSubjectId = 306
    nextScheduleId = 4041
    nextGradeId = 5081
    nextAttendanceId = 6121
    nextAnnouncementId = 7005
    updatedAt = Get-Date
  }
}

$backupTimestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupDirectory = Ensure-WorkspacePath -RelativePath "tool/firebase-backups/$backupTimestamp"
New-Item -ItemType Directory -Path $backupDirectory -Force | Out-Null

Write-Step "Preparing Firebase data workflow for project $ProjectId"
Export-AuthUsers -OutputPath (Join-Path $backupDirectory 'auth-users.json')
Backup-FirestoreCollections -BackupDirectory $backupDirectory

$authExport = Get-Content (Join-Path $backupDirectory 'auth-users.json') | ConvertFrom-Json
$authUsers = @($authExport.users)
$seedSpecs = Build-SeedSpecs -AuthUsers $authUsers

$allowedEmails = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($spec in $seedSpecs) {
  $allowedEmails.Add($spec.email) | Out-Null
}

Write-Step 'Current live Firebase summary'
$currentCollections = Get-CollectionIds
Write-Host "Collections: $($currentCollections -join ', ')"
Write-Host "Auth users: $($authUsers.Count)"
Write-Host "Expected managed users after reseed: $($seedSpecs.Count)"

if (-not $Apply) {
  Write-Step "Inspection complete. Re-run with -Apply to back up, reset, and seed the project."
  exit 0
}

Disable-ExtraAuthUsers -AuthUsers $authUsers -AllowedEmails $allowedEmails

$resolvedUsers = @()
$existingByEmail = @{}
foreach ($user in $authUsers) {
  if ($user.email) {
    $existingByEmail[$user.email.ToLowerInvariant()] = $user
  }
}

Write-Step 'Normalizing auth accounts and setting known passwords'
foreach ($spec in $seedSpecs) {
  $resolved = Ensure-AuthUser -Spec $spec -ExistingByEmail $existingByEmail
  $resolvedUsers += @{
    uid = $resolved.uid
    email = $spec.email.ToLowerInvariant()
    firstName = $spec.firstName
    lastName = $spec.lastName
    role = $spec.role
    id = $spec.id
    classGroupId = $spec.classGroupId
    classGroupName = $spec.classGroupName
    subjectIds = $spec.subjectIds
    subjects = $spec.subjects
  }
}

Remove-SeedCollections
$seedData = Build-SeedData -ResolvedUsers $resolvedUsers
Seed-FirestoreData -ResolvedUsers $resolvedUsers -SeedData $seedData

$summary = @{
  users = $resolvedUsers.Count
  groups = $seedData.groups.Count
  subjects = $seedData.subjects.Count
  schedules = $seedData.schedules.Count
  grades = $seedData.grades.Count
  attendance = $seedData.attendance.Count
  announcements = $seedData.announcements.Count
  backupDirectory = $backupDirectory
  credentials = @{
    admin = @{
      email = 'admin@eduops.kg'
      password = 'Admin123!'
    }
    teacher = @{
      pattern = 'teacherN@eduops.kg'
      password = 'Teacher123!'
    }
    student = @{
      pattern = 'studentN@eduops.kg'
      password = 'Student123!'
    }
  }
}

$summary |
  ConvertTo-Json -Depth 20 |
  Set-Content (Join-Path $backupDirectory 'seed-summary.json')

Write-Step 'Firebase reseed complete'
Write-Host ($summary | ConvertTo-Json -Depth 20)
