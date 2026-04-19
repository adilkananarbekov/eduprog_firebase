import { useState } from "react";
import Layout from "../components/Layout";
import { Button } from "../components/ui/button";
import { Card, CardContent } from "../components/ui/card";
import { Calendar, Clock, MapPin, LayoutGrid, List } from "lucide-react";

const schedule = [
  { id: 1, day: "Monday", time: "08:00 - 09:30", group: "Chemistry Grade 10", room: "Lab 2", teacher: "Aijamal Kadyrova" },
  { id: 2, day: "Monday", time: "10:00 - 11:30", group: "English A1", room: "Room 101", teacher: "Gulnara Ibraimova" },
  { id: 3, day: "Monday", time: "16:00 - 17:30", group: "Russian B2", room: "Room 205", teacher: "Ainura Kadyrova" },
  { id: 4, day: "Tuesday", time: "09:00 - 10:30", group: "Biology Grade 9", room: "Lab 1", teacher: "Nazira Sultanbekova" },
  { id: 5, day: "Tuesday", time: "11:00 - 12:30", group: "Physics Grade 11", room: "Lab 3", teacher: "Bektur Osmonov" },
  { id: 6, day: "Tuesday", time: "14:00 - 15:30", group: "Math Grade 7", room: "Room 103", teacher: "Asan Toktomushev" },
  { id: 7, day: "Tuesday", time: "16:00 - 17:30", group: "Math Grade 8", room: "Room 104", teacher: "Asan Toktomushev" },
  { id: 8, day: "Wednesday", time: "10:00 - 11:30", group: "English A1", room: "Room 101", teacher: "Gulnara Ibraimova" },
  { id: 9, day: "Wednesday", time: "13:00 - 14:30", group: "English A2", room: "Room 102", teacher: "Gulnara Ibraimova" },
  { id: 10, day: "Wednesday", time: "15:00 - 16:30", group: "English B1", room: "Room 101", teacher: "Meerim Asanova" },
  { id: 11, day: "Thursday", time: "08:00 - 09:30", group: "Literature Grade 9", room: "Room 103", teacher: "Cholpon Kadyrova" },
  { id: 12, day: "Thursday", time: "10:00 - 11:30", group: "Geography Grade 8", room: "Room 201", teacher: "Aibek Toktosunov" },
  { id: 13, day: "Thursday", time: "13:00 - 14:30", group: "Music Grade 7", room: "Music Hall", teacher: "Asel Nurbekova" },
  { id: 14, day: "Thursday", time: "14:00 - 15:30", group: "Math Grade 7", room: "Room 103", teacher: "Asan Toktomushev" },
  { id: 15, day: "Thursday", time: "15:00 - 16:30", group: "Computer Science", room: "Lab 4", teacher: "Nursultan Tashiev" },
  { id: 16, day: "Thursday", time: "17:00 - 18:30", group: "Robotics Club", room: "Lab 4", teacher: "Nursultan Tashiev" },
  { id: 17, day: "Friday", time: "10:00 - 11:30", group: "English A1", room: "Room 101", teacher: "Gulnara Ibraimova" },
  { id: 18, day: "Friday", time: "12:00 - 13:30", group: "History Grade 10", room: "Room 204", teacher: "Marat Osmonov" },
  { id: 19, day: "Friday", time: "14:00 - 15:30", group: "Math Grade 7", room: "Room 103", teacher: "Asan Toktomushev" },
  { id: 20, day: "Saturday", time: "10:00 - 11:30", group: "Kyrgyz Language", room: "Room 106", teacher: "Kanykei Sydykova" },
  { id: 21, day: "Saturday", time: "12:00 - 13:30", group: "Art Workshop", room: "Art Studio", teacher: "Jyldyz Asanova" },
  // Sunday has no sessions
];

const daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];

export default function Schedule() {
  const [viewMode, setViewMode] = useState<"day" | "week">("week");

  // Group sessions by day for week view
  const sessionsByDay = daysOfWeek.map((day) => ({
    day,
    sessions: schedule.filter((s) => s.day === day),
  }));

  return (
    <Layout>
      <div className="border-b border-border bg-white px-4 sm:px-8 py-4 sm:py-6">
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl sm:text-3xl font-semibold text-foreground">Schedule</h1>
            <p className="text-muted-foreground mt-1 text-sm sm:text-base">Manage class schedules</p>
          </div>
          <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 w-full sm:w-auto">
            <div className="flex items-center gap-2 border border-border rounded-lg p-1">
              <Button
                variant={viewMode === "day" ? "default" : "ghost"}
                size="sm"
                onClick={() => setViewMode("day")}
                className={viewMode === "day" ? "bg-primary" : ""}
              >
                <List className="w-4 h-4 sm:mr-2" />
                <span className="hidden sm:inline">Day View</span>
              </Button>
              <Button
                variant={viewMode === "week" ? "default" : "ghost"}
                size="sm"
                onClick={() => setViewMode("week")}
                className={viewMode === "week" ? "bg-primary" : ""}
              >
                <LayoutGrid className="w-4 h-4 sm:mr-2" />
                <span className="hidden sm:inline">Week View</span>
              </Button>
            </div>
            <Button className="bg-accent hover:bg-accent/90 w-full sm:w-auto">
              <Calendar className="w-4 h-4 mr-2" />
              Generate Sessions
            </Button>
          </div>
        </div>
      </div>
      <div className="flex-1 overflow-auto p-4 sm:p-8 bg-white">
        <div className="max-w-7xl mx-auto">
          {/* Day View */}
          {viewMode === "day" && (
            <div className="space-y-4 sm:space-y-6">
              {["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"].map((day) => {
                const daySessions = schedule.filter((s) => s.day === day);
                return (
                  <div key={day}>
                    <h2 className="text-lg sm:text-xl font-semibold text-foreground mb-3 sm:mb-4">{day}</h2>
                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 sm:gap-4">
                      {daySessions.length > 0 ? (
                        daySessions.map((session) => (
                          <Card key={session.id} className="border-border hover:shadow-md transition-shadow">
                            <CardContent className="p-4 sm:p-5 space-y-2 sm:space-y-3">
                              <div className="flex items-start justify-between">
                                <h3 className="font-semibold text-foreground text-base sm:text-lg">{session.group}</h3>
                                <Clock className="w-4 h-4 text-accent mt-1 flex-shrink-0" />
                              </div>
                              <div className="space-y-1.5 sm:space-y-2 text-sm">
                                <div className="flex items-center gap-2 text-muted-foreground">
                                  <Clock className="w-4 h-4 flex-shrink-0" />
                                  <span>{session.time}</span>
                                </div>
                                <div className="flex items-center gap-2 text-muted-foreground">
                                  <MapPin className="w-4 h-4 flex-shrink-0" />
                                  <span>{session.room}</span>
                                </div>
                                <div className="text-foreground font-medium">{session.teacher}</div>
                              </div>
                            </CardContent>
                          </Card>
                        ))
                      ) : (
                        <p className="text-muted-foreground text-sm col-span-full">No sessions scheduled</p>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          )}

          {/* Week View */}
          {viewMode === "week" && (
            <div className="overflow-x-auto -mx-4 sm:mx-0 px-4 sm:px-0">
              <div className="grid grid-cols-7 gap-2 sm:gap-4 min-w-[700px] sm:min-w-[900px] lg:min-w-[1200px]">
                {sessionsByDay.map((dayData, index) => (
                  <div key={index} className="flex flex-col">
                    {/* Day Header */}
                    <div className="bg-primary text-white p-3 sm:p-4 rounded-t-lg text-center">
                      <div className="text-base sm:text-lg font-bold">{dayData.day}</div>
                      <div className="text-xs sm:text-sm opacity-90 mt-1">
                        {dayData.sessions.length} {dayData.sessions.length === 1 ? "session" : "sessions"}
                      </div>
                    </div>

                    {/* Sessions Container */}
                    <div className="flex-1 bg-muted/30 rounded-b-lg border border-border border-t-0 p-2 sm:p-3 space-y-2 sm:space-y-3 min-h-[400px] sm:min-h-[500px]">
                      {dayData.sessions.length > 0 ? (
                        dayData.sessions.map((session) => (
                          <Card
                            key={session.id}
                            className="border-border bg-white hover:shadow-md transition-shadow"
                          >
                            <CardContent className="p-3 sm:p-4 space-y-1.5 sm:space-y-2">
                              <div className="flex items-start justify-between gap-2">
                                <h4 className="text-xs sm:text-sm font-bold text-foreground leading-tight">
                                  {session.group}
                                </h4>
                                <Clock className="w-3.5 h-3.5 sm:w-4 sm:h-4 text-accent flex-shrink-0" />
                              </div>
                              <div className="flex items-center gap-1.5 text-[10px] sm:text-xs text-muted-foreground">
                                <Clock className="w-3 h-3 sm:w-3.5 sm:h-3.5 flex-shrink-0" />
                                <span className="font-semibold">{session.time}</span>
                              </div>
                              <div className="flex items-center gap-1.5 text-[10px] sm:text-xs text-muted-foreground">
                                <MapPin className="w-3 h-3 sm:w-3.5 sm:h-3.5 flex-shrink-0" />
                                <span>{session.room}</span>
                              </div>
                              <div className="text-[10px] sm:text-xs font-medium text-foreground pt-1 border-t border-border">
                                {session.teacher}
                              </div>
                            </CardContent>
                          </Card>
                        ))
                      ) : (
                        <div className="flex items-center justify-center h-full text-xs sm:text-sm text-muted-foreground py-8 sm:py-12">
                          No sessions scheduled
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </Layout>
  );
}