import { useParams, useNavigate } from "react-router";
import Layout from "../components/Layout";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "../components/ui/tabs";
import {
  ArrowLeft,
  Phone,
  Mail,
  Calendar,
  Clock,
  MapPin,
  User,
  CreditCard,
  ChevronDown,
  ChevronUp,
} from "lucide-react";
import { useState } from "react";
import { Avatar, AvatarFallback } from "../components/ui/avatar";

const studentData = {
  id: "1",
  name: "Alina Beknazarova",
  phone: "+996 555 123 456",
  email: "alina.b@example.com",
  groups: ["English A1", "Math Advanced"],
  status: "active",
  debtAmount: 3200,
};

const weekScheduleData = {
  Monday: [
    {
      time: "10:00",
      duration: 90,
      subject: "English A1",
      teacher: "Gulnara Ibraimova",
      room: "Room 101",
      status: "present",
    },
    {
      time: "14:00",
      duration: 90,
      subject: "Mathematics",
      teacher: "Asan Toktomushev",
      room: "Room 302",
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
      status: null,
    },
    {
      time: "14:00",
      duration: 90,
      subject: "Mathematics",
      teacher: "Asan Toktomushev",
      room: "Room 302",
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
      status: null,
    },
    {
      time: "14:00",
      duration: 90,
      subject: "Mathematics",
      teacher: "Asan Toktomushev",
      room: "Room 302",
      status: null,
    },
  ],
  Saturday: [],
  Sunday: [],
};

const invoicesData = [
  {
    id: 1,
    period: "February 2026",
    course: "English Course",
    amount: 5000,
    status: "unpaid",
    paymentMethod: null,
  },
  {
    id: 2,
    period: "February 2026",
    course: "Math Course",
    amount: 6000,
    status: "unpaid",
    paymentMethod: null,
  },
  {
    id: 3,
    period: "January 2026",
    course: "English Course",
    amount: 5000,
    status: "paid",
    paymentMethod: "Mbank",
    paidDate: "Jan 15, 2026",
  },
  {
    id: 4,
    period: "January 2026",
    course: "Math Course",
    amount: 6000,
    status: "paid",
    paymentMethod: "Cash",
    paidDate: "Jan 15, 2026",
  },
];

const daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
const timeSlots = ["08:00", "09:00", "10:00", "11:00", "12:00", "13:00", "14:00", "15:00", "16:00", "17:00", "18:00"];

export default function StudentProfile() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [expandedInvoice, setExpandedInvoice] = useState<number | null>(null);

  const getTimeSlotHeight = (duration: number) => {
    return (duration / 60) * 60; // 60px per hour
  };

  const getTopPosition = (time: string) => {
    const [hours, minutes] = time.split(":").map(Number);
    const startHour = 8;
    return ((hours - startHour) * 60 + minutes) + 40;
  };

  const totalPaid = invoicesData
    .filter((inv) => inv.status === "paid")
    .reduce((sum, inv) => sum + inv.amount, 0);

  return (
    <Layout>
      {/* Header */}
      <header className="border-b border-border bg-white px-8 py-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Button variant="ghost" size="sm" onClick={() => navigate("/students")}>
              <ArrowLeft className="w-4 h-4 mr-2" />
              Back to Students
            </Button>
            <div className="h-6 w-px bg-border"></div>
            <div className="flex items-center gap-4">
              <Avatar className="w-12 h-12">
                <AvatarFallback className="bg-accent text-white text-lg">
                  {studentData.name.split(" ").map(n => n[0]).join("")}
                </AvatarFallback>
              </Avatar>
              <div>
                <h1 className="text-2xl font-semibold text-foreground">{studentData.name}</h1>
                <div className="flex items-center gap-3 mt-1">
                  <Badge variant="outline" className="bg-green-50 text-green-700 border-green-200">
                    Active
                  </Badge>
                  {studentData.debtAmount > 0 && (
                    <Badge variant="outline" className="bg-red-50 text-primary border-red-200">
                      Debt: {studentData.debtAmount.toLocaleString()} KGS
                    </Badge>
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 overflow-auto bg-white p-8">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
          {/* Contact Info Card */}
          <Card className="border-border">
            <CardHeader>
              <CardTitle className="text-lg">Contact Information</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex items-center gap-3 text-sm">
                <Phone className="w-4 h-4 text-muted-foreground" />
                <span className="text-foreground">{studentData.phone}</span>
              </div>
              <div className="flex items-center gap-3 text-sm">
                <Mail className="w-4 h-4 text-muted-foreground" />
                <span className="text-foreground">{studentData.email}</span>
              </div>
            </CardContent>
          </Card>

          {/* Groups Card */}
          <Card className="border-border">
            <CardHeader>
              <CardTitle className="text-lg">Active Groups</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              {studentData.groups.map((group, idx) => (
                <div key={idx} className="px-3 py-2 bg-accent/10 rounded-lg text-sm font-medium text-foreground">
                  {group}
                </div>
              ))}
            </CardContent>
          </Card>

          {/* Quick Stats Card */}
          <Card className="border-border">
            <CardHeader>
              <CardTitle className="text-lg">Quick Stats</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex justify-between items-center">
                <span className="text-sm text-muted-foreground">Attendance Rate</span>
                <span className="text-lg font-bold text-foreground">88%</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-muted-foreground">Classes/Week</span>
                <span className="text-lg font-bold text-foreground">4</span>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Tabs */}
        <Tabs defaultValue="schedule" className="space-y-6">
          <TabsList className="bg-muted">
            <TabsTrigger value="schedule">Week Schedule</TabsTrigger>
            <TabsTrigger value="billing">Billing & Payments</TabsTrigger>
          </TabsList>

          {/* Schedule Tab */}
          <TabsContent value="schedule" className="space-y-4">
            <Card className="border-border">
              <CardContent className="p-0">
                <div className="grid grid-cols-8 border-b border-border">
                  <div className="border-r border-border bg-muted/30 p-4">
                    <span className="text-sm font-semibold text-muted-foreground">Time</span>
                  </div>
                  {daysOfWeek.map((day, idx) => (
                    <div key={day} className="border-r border-border last:border-r-0 p-4 text-center bg-muted/30">
                      <span className="text-sm font-semibold text-foreground">{day}</span>
                      <p className="text-xs text-muted-foreground mt-1">Feb {17 + idx}</p>
                    </div>
                  ))}
                </div>

                <div className="grid grid-cols-8">
                  <div className="border-r border-border">
                    {timeSlots.map((time) => (
                      <div key={time} className="h-[60px] border-b border-border p-2 bg-muted/10">
                        <span className="text-xs text-muted-foreground font-medium">{time}</span>
                      </div>
                    ))}
                  </div>

                  {daysOfWeek.map((day) => (
                    <div key={day} className="border-r border-border last:border-r-0 relative">
                      {timeSlots.map((time) => (
                        <div key={time} className="h-[60px] border-b border-border"></div>
                      ))}
                      
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
            <div className="flex items-center gap-6">
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
          </TabsContent>

          {/* Billing Tab */}
          <TabsContent value="billing" className="space-y-6">
            {/* Summary Cards */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <Card className="border-border">
                <CardContent className="p-6">
                  <div className="flex items-center gap-3 mb-2">
                    <CreditCard className="w-5 h-5 text-accent" />
                    <p className="text-sm text-muted-foreground font-medium">Total Paid (2026)</p>
                  </div>
                  <p className="text-3xl font-bold text-foreground">{totalPaid.toLocaleString()}</p>
                  <p className="text-sm text-muted-foreground mt-1">KGS</p>
                </CardContent>
              </Card>
              <Card className="border-2 border-primary bg-red-50">
                <CardContent className="p-6">
                  <div className="flex items-center gap-3 mb-2">
                    <CreditCard className="w-5 h-5 text-primary" />
                    <p className="text-sm text-muted-foreground font-medium">Current Debt</p>
                  </div>
                  <p className="text-3xl font-bold text-primary">{studentData.debtAmount.toLocaleString()}</p>
                  <p className="text-sm text-muted-foreground mt-1">KGS</p>
                </CardContent>
              </Card>
            </div>

            {/* Invoices */}
            <Card className="border-border">
              <CardHeader>
                <CardTitle>Payment History</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                {invoicesData.map((invoice) => (
                  <Card
                    key={invoice.id}
                    className="border-border cursor-pointer hover:shadow-md transition-shadow"
                    onClick={() => setExpandedInvoice(expandedInvoice === invoice.id ? null : invoice.id)}
                  >
                    <CardContent className="p-4">
                      <div className="flex items-center justify-between">
                        <div className="flex-1">
                          <p className="font-semibold text-foreground">
                            {invoice.period} - {invoice.course}
                          </p>
                          <p className="text-xl font-bold text-foreground mt-1">
                            {invoice.amount.toLocaleString()} KGS
                          </p>
                        </div>
                        <div className="flex flex-col items-end gap-2">
                          <Badge
                            variant="outline"
                            className={
                              invoice.status === "paid"
                                ? "bg-green-50 text-green-700 border-green-200"
                                : "bg-red-50 text-primary border-red-200"
                            }
                          >
                            {invoice.status === "paid" ? "Paid" : "Unpaid"}
                          </Badge>
                          {expandedInvoice === invoice.id ? (
                            <ChevronUp className="w-5 h-5 text-muted-foreground" />
                          ) : (
                            <ChevronDown className="w-5 h-5 text-muted-foreground" />
                          )}
                        </div>
                      </div>

                      {expandedInvoice === invoice.id && (
                        <div className="mt-4 pt-4 border-t border-border space-y-2">
                          <div className="flex justify-between text-sm">
                            <span className="text-muted-foreground">Invoice ID:</span>
                            <span className="text-foreground font-medium">INV-{invoice.id.toString().padStart(4, "0")}</span>
                          </div>
                          <div className="flex justify-between text-sm">
                            <span className="text-muted-foreground">Status:</span>
                            <span className="text-foreground font-medium capitalize">{invoice.status}</span>
                          </div>
                          {invoice.paymentMethod && (
                            <>
                              <div className="flex justify-between text-sm">
                                <span className="text-muted-foreground">Payment Method:</span>
                                <span className="text-foreground font-medium">{invoice.paymentMethod}</span>
                              </div>
                              <div className="flex justify-between text-sm">
                                <span className="text-muted-foreground">Paid Date:</span>
                                <span className="text-foreground font-medium">{invoice.paidDate}</span>
                              </div>
                            </>
                          )}
                          {invoice.status === "unpaid" && (
                            <Button className="w-full mt-3 bg-primary hover:bg-primary/90">
                              Record Payment
                            </Button>
                          )}
                        </div>
                      )}
                    </CardContent>
                  </Card>
                ))}
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </main>
    </Layout>
  );
}
