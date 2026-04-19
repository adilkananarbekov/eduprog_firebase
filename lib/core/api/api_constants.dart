/// API constants for EduOps backend integration
class ApiConstants {
  static const String remoteBackendUrl = 'http://136.116.64.6';
  static String? _runtimeBaseUrlOverride;

  static String get baseUrl {
    final runtimeBaseUrlOverride = _runtimeBaseUrlOverride;
    if (runtimeBaseUrlOverride != null && runtimeBaseUrlOverride.isNotEmpty) {
      return runtimeBaseUrlOverride;
    }

    const configuredBaseUrl = String.fromEnvironment('EDUOPS_BASE_URL');
    if (configuredBaseUrl.isNotEmpty) {
      return _trimTrailingSlash(configuredBaseUrl);
    }

    return remoteBackendUrl;
  }

  static String get apiPrefix {
    const configuredApiPrefix = String.fromEnvironment('EDUOPS_API_PREFIX');
    if (configuredApiPrefix.isNotEmpty) {
      return _normalizeApiPrefix(configuredApiPrefix);
    }

    return '/api/v1';
  }

  static String get baseApiUrl => '$baseUrl$apiPrefix';

  // Timeout configuration
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration remoteAuthTimeout = Duration(seconds: 40);

  // Authentication endpoints
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String register = '/auth/register';
  static const String registerInitial = register;

  // Admin endpoints
  static const String users = '/admin/users';
  static const String students = '/admin/students';
  static const String studentsUnassigned = '/admin/students/unassigned';
  static String studentsByClass(int classGroupId) =>
      '/students/group/$classGroupId';
  static String updateStudentClass(int studentId) =>
      '/admin/students/$studentId/group';
  static const String studentsBulkAssign = '/admin/bulk-assign';
  static const String teachers = '/teachers';
  static String updateTeacherSubjects(int teacherId) =>
      '/teacher/teachers/$teacherId/subjects';
  static const String classGroups = '/student-groups';
  static const String adminClassGroups = '/admin/student-groups';
  static String classGroup(int id) => '/admin/student-groups/$id';
  static const String subjects = '/admin/subjects';

  // Announcement endpoints
  static const String announcements = '/announcements';
  static const String announcementsAll = '/announcements/all';
  static const String announcementsAdmin = '/admin/announcements';
  static String announcementById(int id) => '/admin/announcements/$id';

  // Attendance endpoints
  static const String attendance = '/attendance';
  static const String teacherAttendance = '/teacher/attendance';
  static const String attendanceRange = '/attendance/range';
  static const String attendanceStats = '/attendance/stats';
  static String attendanceByStudent(int studentId) =>
      '/attendance/student/$studentId';
  static String attendanceBySchedule(int scheduleId) =>
      '/teacher/attendance/schedule/$scheduleId';

  // Grade endpoints
  static const String grades = '/grades';
  static const String teacherGrades = '/teacher/grades';
  static String gradesBySubject(int subjectId) => '/grades/subject/$subjectId';
  static const String gradesAverages = '/grades/averages';
  static String gradesByStudent(int studentId) =>
      '/teacher/grades/student/$studentId';
  static String gradeById(int id) => '/teacher/grades/$id';

  // Schedule endpoints
  static const String scheduleWeek = '/schedule/week';
  static String scheduleByClass(int classGroupId) =>
      '/schedule/class/$classGroupId';
  static String scheduleByTeacher(int teacherId) =>
      '/schedule/teacher/$teacherId';
  static const String schedule = '/admin/schedule';
  static const String scheduleGenerate = '/admin/schedule/generate';
  static String scheduleById(int id) => '/admin/schedule/$id';

  // Headers
  static const String authorizationHeader = 'Authorization';
  static const String contentTypeHeader = 'Content-Type';
  static const String contentTypeJson = 'application/json';

  // Token prefix
  static const String bearerPrefix = 'Bearer ';

  static void setRuntimeBaseUrlOverride(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      _runtimeBaseUrlOverride = null;
      return;
    }
    _runtimeBaseUrlOverride = _trimTrailingSlash(trimmed);
  }

  static void clearRuntimeBaseUrlOverride() {
    _runtimeBaseUrlOverride = null;
  }

  static String _trimTrailingSlash(String value) {
    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }

  static String _normalizeApiPrefix(String value) {
    final trimmed = _trimTrailingSlash(value);
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }
}
