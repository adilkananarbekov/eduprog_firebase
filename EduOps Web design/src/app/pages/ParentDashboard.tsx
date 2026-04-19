import Layout from "../components/Layout";
import { Card, CardContent } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { AlertCircle, TrendingUp, Clock, MapPin } from "lucide-react";
import { Badge } from "../components/ui/badge";
import { Link } from "react-router";

export default function ParentDashboard() {
  const studentName = "Alina";
  const hasDebt = true;
  const debtAmount = 3200;
  const attendanceRate = 88;

  return (
    <Layout userRole="parent">
      {/* Header */}
      <header className="border-b border-border bg-white px-4 sm:px-8 py-4 sm:py-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl sm:text-3xl font-semibold text-foreground">Welcome back, {studentName}</h1>
            <p className="text-muted-foreground mt-1 text-sm sm:text-base">Here's your overview for today</p>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 overflow-auto bg-white p-4 sm:p-8">
        <div className="max-w-7xl mx-auto space-y-4 sm:space-y-6">
          {/* Priority Card - Debt */}
          {hasDebt && (
            <Card className="border-2 border-primary bg-red-50">
              <CardContent className="p-4 sm:p-5">
                <div className="flex items-start gap-3 mb-4">
                  <div className="p-2 bg-primary rounded-full">
                    <AlertCircle className="w-4 h-4 sm:w-5 sm:h-5 text-white" />
                  </div>
                  <div className="flex-1">
                    <h3 className="font-semibold text-foreground text-sm mb-1">Outstanding Balance</h3>
                    <p className="text-xl sm:text-2xl font-bold text-primary">{debtAmount.toLocaleString()} KGS</p>
                  </div>
                </div>
                <Button className="w-full bg-primary hover:bg-primary/90 h-10 sm:h-12 text-sm sm:text-base font-semibold">
                  Pay Now
                </Button>
              </CardContent>
            </Card>
          )}

          {/* Progress Card - Attendance */}
          <Card className="border-border">
            <CardContent className="p-4 sm:p-5">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-accent/10 rounded-full">
                    <TrendingUp className="w-4 h-4 sm:w-5 sm:h-5 text-accent" />
                  </div>
                  <div>
                    <h3 className="font-semibold text-foreground text-sm sm:text-base">Attendance</h3>
                    <p className="text-xl sm:text-2xl font-bold text-foreground mt-1">{attendanceRate}%</p>
                  </div>
                </div>
              </div>
              <div className="w-full bg-muted rounded-full h-2.5 sm:h-3">
                <div
                  className="bg-primary h-2.5 sm:h-3 rounded-full transition-all"
                  style={{ width: `${attendanceRate}%` }}
                />
              </div>
              <p className="text-sm text-muted-foreground mt-2">This month</p>
            </CardContent>
          </Card>

          {/* Schedule Preview */}
          <Card className="border-border">
            <CardContent className="p-4 sm:p-5">
              <h3 className="font-semibold text-foreground mb-4 text-sm sm:text-base">Next Class</h3>
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-base sm:text-lg font-bold text-foreground">Mathematics</span>
                  <span className="text-xs sm:text-sm font-medium text-muted-foreground">Today</span>
                </div>
                <div className="flex flex-col sm:flex-row items-start sm:items-center gap-2 sm:gap-4 text-sm text-muted-foreground">
                  <div className="flex items-center gap-2">
                    <Clock className="w-4 h-4" />
                    <span>14:00 - 15:30</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <MapPin className="w-4 h-4" />
                    <span>Room 302</span>
                  </div>
                </div>
                <div className="pt-2 border-t border-border">
                  <p className="text-sm text-muted-foreground">
                    Teacher: <span className="text-foreground font-medium">Asan Toktomushev</span>
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Quick Stats */}
          <div className="grid grid-cols-2 gap-3 sm:gap-4">
            <Card className="border-border">
              <CardContent className="p-3 sm:p-4 text-center">
                <p className="text-xl sm:text-2xl font-bold text-foreground">4</p>
                <p className="text-xs sm:text-sm text-muted-foreground mt-1">Classes/Week</p>
              </CardContent>
            </Card>
            <Card className="border-border">
              <CardContent className="p-3 sm:p-4 text-center">
                <p className="text-xl sm:text-2xl font-bold text-foreground">2</p>
                <p className="text-xs sm:text-sm text-muted-foreground mt-1">Active Groups</p>
              </CardContent>
            </Card>
          </div>
        </div>
      </main>
    </Layout>
  );
}