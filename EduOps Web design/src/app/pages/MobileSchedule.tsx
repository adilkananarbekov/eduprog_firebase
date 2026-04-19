import { useState } from "react";
import Layout from "../components/Layout";
import { Card, CardContent } from "../components/ui/card";
import { Badge } from "../components/ui/badge";
import { Clock, MapPin, User, ChevronLeft, ChevronRight, Calendar, LayoutGrid, List } from "lucide-react";
import { Button } from "../components/ui/button";

const daysOfWeek = ["M", "T", "W", "T", "F", "S", "S"];
const fullDays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];

const sessionsData = [
  {
    id: 1,
    day: "Monday",
    time: "08:00 - 09:30",
    subject: "Chemistry",
    teacher: "Aijamal Kadyrova",
    room: "Lab 2",
    status: "present",
    isPast: true,
  },
  {
    id: 2,
    day: "Monday",
    time: "10:00 - 11:30",
    subject: "English A1",
    teacher: "Gulnara Ibraimova",
    room: "Room 101",
    status: "present",
    isPast: true,
  },
  {
    id: 3,
    day: "Monday",
    time: "12:00 - 13:30",
    subject: "History",
    teacher: "Marat Osmonov",
    room: "Room 204",
    status: "present",
    isPast: true,
  },
  {
    id: 4,
    day: "Monday",
    time: "14:00 - 15:30",
    subject: "Mathematics",
    teacher: "Asan Toktomushev",
    room: "Room 302",
    status: "present",
    isPast: true,
  },
  {
    id: 5,
    day: "Monday",
    time: "16:00 - 17:30",
    subject: "Physical Education",
    teacher: "Bektur Asanov",
    room: "Gym",
    status: "present",
    isPast: true,
  },
  {
    id: 6,
    day: "Tuesday",
    time: "09:00 - 10:30",
    subject: "Biology",
    teacher: "Nazira Sultanbekova",
    room: "Lab 1",
    status: null,
    isPast: false,
  },
  {
    id: 7,
    day: "Tuesday",
    time: "11:00 - 12:30",
    subject: "Russian B2",
    teacher: "Ainura Kadyrova",
    room: "Room 205",
    status: null,
    isPast: false,
  },
  {
    id: 8,
    day: "Tuesday",
    time: "14:00 - 15:30",
    subject: "Physics",
    teacher: "Eldiyar Mamatov",
    room: "Lab 3",
    status: null,
    isPast: false,
  },
  {
    id: 9,
    day: "Wednesday",
    time: "10:00 - 11:30",
    subject: "English A1",
    teacher: "Gulnara Ibraimova",
    room: "Room 101",
    status: null,
    isPast: false,
  },
  {
    id: 10,
    day: "Wednesday",
    time: "14:00 - 15:30",
    subject: "Mathematics",
    teacher: "Asan Toktomushev",
    room: "Room 302",
    status: null,
    isPast: false,
  },
  {
    id: 11,
    day: "Thursday",
    time: "08:00 - 09:30",
    subject: "Literature",
    teacher: "Cholpon Kadyrova",
    room: "Room 103",
    status: null,
    isPast: false,
  },
  {
    id: 12,
    day: "Thursday",
    time: "10:00 - 11:30",
    subject: "Geography",
    teacher: "Aibek Toktosunov",
    room: "Room 201",
    status: null,
    isPast: false,
  },
  {
    id: 13,
    day: "Thursday",
    time: "13:00 - 14:30",
    subject: "Music",
    teacher: "Asel Nurbekova",
    room: "Music Hall",
    status: null,
    isPast: false,
  },
  {
    id: 14,
    day: "Thursday",
    time: "15:00 - 16:30",
    subject: "Computer Science",
    teacher: "Nursultan Tashiev",
    room: "Lab 4",
    status: null,
    isPast: false,
  },
  {
    id: 15,
    day: "Friday",
    time: "10:00 - 11:30",
    subject: "English A1",
    teacher: "Gulnara Ibraimova",
    room: "Room 101",
    status: null,
    isPast: false,
  },
  {
    id: 16,
    day: "Friday",
    time: "14:00 - 15:30",
    subject: "Mathematics",
    teacher: "Asan Toktomushev",
    room: "Room 302",
    status: null,
    isPast: false,
  },
  {
    id: 17,
    day: "Friday",
    time: "16:00 - 17:30",
    subject: "Art",
    teacher: "Jyldyz Asanova",
    room: "Art Studio",
    status: null,
    isPast: false,
  },
  {
    id: 18,
    day: "Saturday",
    time: "10:00 - 11:30",
    subject: "Kyrgyz Language",
    teacher: "Kanykei Sydykova",
    room: "Room 106",
    status: null,
    isPast: false,
  },
  // Sunday has no classes (demonstrating 0 lessons)
];

export default function MobileSchedule() {
  const [selectedDay, setSelectedDay] = useState(0); // Monday
  const [currentWeek, setCurrentWeek] = useState("Feb 17 - Feb 23, 2026");
  const [viewMode, setViewMode] = useState<"day" | "week">("week"); // Default to week view

  const filteredSessions = sessionsData.filter((session) => session.day === fullDays[selectedDay]);

  // Group sessions by day for week view
  const sessionsByDay = fullDays.map((day) => ({
    day,
    sessions: sessionsData.filter((session) => session.day === day),
  }));

  return (
    <Layout userRole="parent">
      {/* Header */}
      <header className="border-b border-border bg-white px-4 sm:px-8 py-4 sm:py-6">
        <div className="flex flex-col gap-4">
          <div>
            <h1 className="text-2xl sm:text-3xl font-semibold text-foreground">My Schedule</h1>
            <p className="text-muted-foreground mt-1 text-sm sm:text-base">View your weekly class schedule</p>
          </div>
          <div className="flex items-center gap-2 sm:gap-4 overflow-x-auto pb-2">
            <Button variant="outline" size="sm" className="flex-shrink-0">
              <ChevronLeft className="w-4 h-4 sm:mr-2" />
              <span className="hidden sm:inline">Previous Week</span>
            </Button>
            <div className="flex items-center gap-2 px-3 sm:px-4 py-2 bg-muted rounded-lg flex-shrink-0">
              <Calendar className="w-4 h-4 text-muted-foreground" />
              <span className="font-semibold text-foreground text-sm sm:text-base">{currentWeek}</span>
            </div>
            <Button variant="outline" size="sm" className="flex-shrink-0">
              <span className="hidden sm:inline">Next Week</span>
              <ChevronRight className="w-4 h-4 sm:ml-2" />
            </Button>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 overflow-auto bg-white p-4 sm:p-8">
        <div className="max-w-7xl mx-auto space-y-4 sm:space-y-6">
          {/* View Toggle */}
          <div className="flex items-center justify-center gap-2">
            <Button
              variant={viewMode === "day" ? "default" : "outline"}
              size="sm"
              onClick={() => setViewMode("day")}
              className={viewMode === "day" ? "bg-primary" : ""}
            >
              <List className="w-4 h-4 sm:mr-2" />
              <span className="hidden sm:inline">Day View</span>
            </Button>
            <Button
              variant={viewMode === "week" ? "default" : "outline"}
              size="sm"
              onClick={() => setViewMode("week")}
              className={viewMode === "week" ? "bg-primary" : ""}
            >
              <LayoutGrid className="w-4 h-4 sm:mr-2" />
              <span className="hidden sm:inline">Week View</span>
            </Button>
          </div>

          {/* Day View */}
          {viewMode === "day" && (
            <>
              {/* Weekly Date Picker */}
              <div className="flex items-center justify-between gap-2 sm:gap-4">
                {daysOfWeek.map((day, index) => (
                  <button
                    key={index}
                    onClick={() => setSelectedDay(index)}
                    className={`flex-1 py-3 sm:py-4 rounded-lg flex flex-col items-center justify-center font-semibold transition-all ${
                      selectedDay === index
                        ? "bg-primary text-white shadow-md"
                        : "bg-muted text-muted-foreground hover:bg-muted/80"
                    }`}
                  >
                    <span className="text-xs sm:text-sm mb-1">{day}</span>
                    <span className="text-base sm:text-lg">{17 + index}</span>
                  </button>
                ))}
              </div>

              {/* Selected Day Label */}
              <div className="text-center py-3 sm:py-4">
                <h2 className="text-xl sm:text-2xl font-semibold text-foreground">{fullDays[selectedDay]}</h2>
                <p className="text-muted-foreground mt-1 text-sm sm:text-base">February {17 + selectedDay}, 2026</p>
              </div>

              {/* Session Cards */}
              <div className="space-y-3 sm:space-y-4">
                {filteredSessions.length > 0 ? (
                  filteredSessions.map((session) => (
                    <Card
                      key={session.id}
                      className={`border-border ${
                        session.isPast ? "bg-muted/30" : "bg-white shadow-sm"
                      }`}
                    >
                      <CardContent className="p-4">
                        <div className="flex items-start justify-between mb-3">
                          <div className="flex-1">
                            <h3
                              className={`text-base sm:text-lg font-bold mb-1 ${
                                session.isPast ? "text-muted-foreground" : "text-foreground"
                              }`}
                            >
                              {session.subject}
                            </h3>
                            <div className="flex items-center gap-2 text-sm text-muted-foreground">
                              <Clock className="w-4 h-4" />
                              <span className={session.isPast ? "" : "font-semibold text-foreground"}>
                                {session.time}
                              </span>
                            </div>
                          </div>
                          {session.status && (
                            <Badge
                              variant="outline"
                              className={
                                session.status === "present"
                                  ? "bg-green-50 text-green-700 border-green-200"
                                  : "bg-red-50 text-primary border-red-200"
                              }
                            >
                              {session.status === "present" ? "Present" : "Absent"}
                            </Badge>
                          )}
                        </div>
                        <div className="space-y-2">
                          <div className="flex items-center gap-2 text-sm text-muted-foreground">
                            <User className="w-4 h-4" />
                            <span className={session.isPast ? "" : "font-medium text-foreground"}>
                              {session.teacher}
                            </span>
                          </div>
                          <div className="flex items-center gap-2 text-sm text-muted-foreground">
                            <MapPin className="w-4 h-4" />
                            <span>{session.room}</span>
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  ))
                ) : (
                  <div className="text-center py-12">
                    <p className="text-muted-foreground">No classes scheduled for this day</p>
                  </div>
                )}
              </div>
            </>
          )}

          {/* Week View */}
          {viewMode === "week" && (
            <div className="overflow-x-auto -mx-4 sm:mx-0 px-4 sm:px-0">
              <div className="grid grid-cols-7 gap-2 sm:gap-4 min-w-[700px] sm:min-w-[900px] lg:min-w-[1200px]">
                {sessionsByDay.map((dayData, index) => (
                  <div key={index} className="flex flex-col">
                    {/* Day Header */}
                    <div className="bg-primary text-white p-2 sm:p-3 rounded-t-lg text-center">
                      <div className="text-xs sm:text-sm font-semibold">{daysOfWeek[index]}</div>
                      <div className="text-base sm:text-lg font-bold">{17 + index}</div>
                      <div className="text-[10px] sm:text-xs opacity-90 hidden sm:block">{dayData.day}</div>
                    </div>

                    {/* Sessions Container */}
                    <div className="flex-1 bg-muted/30 rounded-b-lg border border-border border-t-0 p-1.5 sm:p-2 space-y-1.5 sm:space-y-2 min-h-[300px] sm:min-h-[400px]">
                      {dayData.sessions.length > 0 ? (
                        dayData.sessions.map((session) => (
                          <Card
                            key={session.id}
                            className={`border-border ${
                              session.isPast ? "bg-muted/50" : "bg-white"
                            } hover:shadow-md transition-shadow`}
                          >
                            <CardContent className="p-2 sm:p-3 space-y-1.5 sm:space-y-2">
                              <div className="flex items-start justify-between gap-1 sm:gap-2">
                                <h4
                                  className={`text-[10px] sm:text-sm font-bold leading-tight ${
                                    session.isPast ? "text-muted-foreground" : "text-foreground"
                                  }`}
                                >
                                  {session.subject}
                                </h4>
                                {session.status && (
                                  <Badge
                                    variant="outline"
                                    className={`text-[8px] sm:text-xs py-0 px-1 sm:px-1.5 h-4 sm:h-5 ${
                                      session.status === "present"
                                        ? "bg-green-50 text-green-700 border-green-200"
                                        : "bg-red-50 text-primary border-red-200"
                                    }`}
                                  >
                                    {session.status === "present" ? "✓" : "✗"}
                                  </Badge>
                                )}
                              </div>
                              <div className="flex items-center gap-1 sm:gap-1.5 text-[10px] sm:text-xs text-muted-foreground">
                                <Clock className="w-2.5 h-2.5 sm:w-3 sm:h-3" />
                                <span className={session.isPast ? "" : "font-semibold text-foreground"}>
                                  {session.time}
                                </span>
                              </div>
                              <div className="flex items-center gap-1 sm:gap-1.5 text-[10px] sm:text-xs text-muted-foreground">
                                <User className="w-2.5 h-2.5 sm:w-3 sm:h-3" />
                                <span className="truncate" title={session.teacher}>
                                  {session.teacher}
                                </span>
                              </div>
                              <div className="flex items-center gap-1 sm:gap-1.5 text-[10px] sm:text-xs text-muted-foreground">
                                <MapPin className="w-2.5 h-2.5 sm:w-3 sm:h-3" />
                                <span>{session.room}</span>
                              </div>
                            </CardContent>
                          </Card>
                        ))
                      ) : (
                        <div className="flex items-center justify-center h-full text-[10px] sm:text-xs text-muted-foreground py-6 sm:py-8">
                          No classes
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </main>
    </Layout>
  );
}