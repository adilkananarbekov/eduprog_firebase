import Layout from "../components/Layout";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { ChevronLeft, ChevronRight, Calendar, Clock, User, MapPin } from "lucide-react";
import { useState } from "react";

const daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
const timeSlots = ["08:00", "09:00", "10:00", "11:00", "12:00", "13:00", "14:00", "15:00", "16:00", "17:00", "18:00"];

const weekScheduleData = {
  Monday: [
    {
      time: "10:00",
      duration: 90,
      subject: "English A1",
      teacher: "Gulnara Ibraimova",
      room: "Room 101",
      group: "Group A",
      status: "present",
    },
    {
      time: "14:00",
      duration: 90,
      subject: "Mathematics",
      teacher: "Asan Toktomushev",
      room: "Room 302",
      group: "Group B",
      status: "present",
    },
  ],
  Tuesday: [],
  Wednesday: [
    {
      time: "10:00",
      duration: 90,
      subject: "English A1",
      teacher: "Gulnara Ibraimova",
      room: "Room 101",
      group: "Group A",
      status: null,
    },
    {
      time: "14:00",
      duration: 90,
      subject: "Mathematics",
      teacher: "Asan Toktomushev",
      room: "Room 302",
      group: "Group B",
      status: null,
    },
  ],
  Thursday: [],
  Friday: [
    {
      time: "10:00",
      duration: 90,
      subject: "English A1",
      teacher: "Gulnara Ibraimova",
      room: "Room 101",
      group: "Group A",
      status: null,
    },
    {
      time: "14:00",
      duration: 90,
      subject: "Mathematics",
      teacher: "Asan Toktomushev",
      room: "Room 302",
      group: "Group B",
      status: null,
    },
  ],
  Saturday: [],
  Sunday: [],
};

export default function WeekSchedule() {
  const [currentWeek, setCurrentWeek] = useState("Feb 17 - Feb 23, 2026");

  const getTimeSlotHeight = (duration: number) => {
    return (duration / 60) * 60; // 60px per hour
  };

  const getTopPosition = (time: string) => {
    const [hours, minutes] = time.split(":").map(Number);
    const startHour = 8; // 08:00 is the start
    return ((hours - startHour) * 60 + minutes) + 40; // 40px for header
  };

  return (
    <Layout>
      {/* Header */}
      <header className="border-b border-border bg-white px-8 py-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-semibold text-foreground">Week Schedule</h1>
            <p className="text-muted-foreground mt-1">View your entire week at a glance</p>
          </div>
          <div className="flex items-center gap-4">
            <Button variant="outline" size="sm">
              <ChevronLeft className="w-4 h-4 mr-2" />
              Previous Week
            </Button>
            <div className="flex items-center gap-2 px-4 py-2 bg-muted rounded-lg">
              <Calendar className="w-4 h-4 text-muted-foreground" />
              <span className="font-semibold text-foreground">{currentWeek}</span>
            </div>
            <Button variant="outline" size="sm">
              Next Week
              <ChevronRight className="w-4 h-4 ml-2" />
            </Button>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 overflow-auto bg-white p-8">
        <Card className="border-border">
          <CardContent className="p-0">
            <div className="grid grid-cols-8 border-b border-border">
              {/* Time Column Header */}
              <div className="border-r border-border bg-muted/30 p-4">
                <span className="text-sm font-semibold text-muted-foreground">Time</span>
              </div>
              {/* Day Headers */}
              {daysOfWeek.map((day) => (
                <div key={day} className="border-r border-border last:border-r-0 p-4 text-center bg-muted/30">
                  <span className="text-sm font-semibold text-foreground">{day}</span>
                  <p className="text-xs text-muted-foreground mt-1">Feb {17 + daysOfWeek.indexOf(day)}</p>
                </div>
              ))}
            </div>

            {/* Schedule Grid */}
            <div className="grid grid-cols-8">
              {/* Time Column */}
              <div className="border-r border-border">
                {timeSlots.map((time) => (
                  <div key={time} className="h-[60px] border-b border-border p-2 bg-muted/10">
                    <span className="text-xs text-muted-foreground font-medium">{time}</span>
                  </div>
                ))}
              </div>

              {/* Day Columns */}
              {daysOfWeek.map((day) => (
                <div key={day} className="border-r border-border last:border-r-0 relative">
                  {timeSlots.map((time) => (
                    <div key={time} className="h-[60px] border-b border-border"></div>
                  ))}
                  
                  {/* Sessions */}
                  {weekScheduleData[day as keyof typeof weekScheduleData]?.map((session, idx) => (
                    <div
                      key={idx}
                      className={`absolute left-1 right-1 rounded-lg p-3 shadow-sm border transition-all hover:shadow-md ${
                        session.status === "present"
                          ? "bg-green-50 border-green-200"
                          : session.status === "absent"
                          ? "bg-red-50 border-red-200"
                          : "bg-accent/10 border-accent"
                      }`}
                      style={{
                        top: `${getTopPosition(session.time)}px`,
                        height: `${getTimeSlotHeight(session.duration)}px`,
                      }}
                    >
                      <div className="h-full flex flex-col justify-between">
                        <div>
                          <h4 className="font-bold text-sm text-foreground truncate">{session.subject}</h4>
                          <div className="flex items-center gap-1 mt-1">
                            <Clock className="w-3 h-3 text-muted-foreground" />
                            <span className="text-xs text-muted-foreground">
                              {session.time} ({session.duration}min)
                            </span>
                          </div>
                        </div>
                        <div className="space-y-1">
                          <div className="flex items-center gap-1 text-xs text-muted-foreground">
                            <User className="w-3 h-3" />
                            <span className="truncate">{session.teacher}</span>
                          </div>
                          <div className="flex items-center justify-between gap-2">
                            <div className="flex items-center gap-1 text-xs text-muted-foreground">
                              <MapPin className="w-3 h-3" />
                              <span>{session.room}</span>
                            </div>
                            {session.status && (
                              <Badge
                                variant="outline"
                                className={`text-xs ${
                                  session.status === "present"
                                    ? "bg-green-100 text-green-700 border-green-300"
                                    : "bg-red-100 text-primary border-red-300"
                                }`}
                              >
                                {session.status === "present" ? "P" : "A"}
                              </Badge>
                            )}
                          </div>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Legend */}
        <div className="mt-6 flex items-center gap-6">
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 rounded bg-accent/10 border border-accent"></div>
            <span className="text-sm text-muted-foreground">Upcoming Session</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 rounded bg-green-50 border border-green-200"></div>
            <span className="text-sm text-muted-foreground">Present</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 rounded bg-red-50 border border-red-200"></div>
            <span className="text-sm text-muted-foreground">Absent</span>
          </div>
        </div>
      </main>
    </Layout>
  );
}
