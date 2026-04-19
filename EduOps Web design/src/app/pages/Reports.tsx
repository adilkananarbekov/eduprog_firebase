import Layout from "../components/Layout";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { BarChart, Download, TrendingUp, Users } from "lucide-react";

const groupStats = [
  { group: "English A1", attendance: 92, revenue: 60000, students: 12 },
  { group: "Math Grade 7", attendance: 88, revenue: 108000, students: 18 },
  { group: "Russian B2", attendance: 95, revenue: 55000, students: 10 },
  { group: "Physics Grade 11", attendance: 85, revenue: 105000, students: 15 },
];

export default function Reports() {
  return (
    <Layout>
      <div className="border-b border-border bg-white px-8 py-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-semibold text-foreground">Reports</h1>
            <p className="text-muted-foreground mt-1">View attendance and revenue reports</p>
          </div>
          <Button className="bg-accent hover:bg-accent/90">
            <Download className="w-4 h-4 mr-2" />
            Export Report
          </Button>
        </div>
      </div>
      <div className="flex-1 overflow-auto p-8 bg-white">
        <div className="max-w-7xl mx-auto space-y-6">
          {/* Summary Cards */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <Card className="border-border">
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">Overall Attendance</CardTitle>
                <TrendingUp className="w-5 h-5 text-accent" />
              </CardHeader>
              <CardContent>
                <div className="text-3xl font-semibold text-accent">90%</div>
                <p className="text-sm text-muted-foreground mt-1">This month</p>
              </CardContent>
            </Card>
            <Card className="border-border">
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">Total Revenue</CardTitle>
                <BarChart className="w-5 h-5 text-accent" />
              </CardHeader>
              <CardContent>
                <div className="text-3xl font-semibold text-foreground">328,000 KGS</div>
                <p className="text-sm text-muted-foreground mt-1">January 2026</p>
              </CardContent>
            </Card>
            <Card className="border-border">
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">Active Students</CardTitle>
                <Users className="w-5 h-5 text-accent" />
              </CardHeader>
              <CardContent>
                <div className="text-3xl font-semibold text-foreground">55</div>
                <p className="text-sm text-muted-foreground mt-1">Across 4 groups</p>
              </CardContent>
            </Card>
          </div>

          {/* Group Performance */}
          <Card className="border-border">
            <CardHeader>
              <CardTitle>Group Performance</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-6">
                {groupStats.map((stat) => (
                  <div key={stat.group} className="space-y-2">
                    <div className="flex items-center justify-between">
                      <div>
                        <h3 className="font-semibold text-foreground">{stat.group}</h3>
                        <p className="text-sm text-muted-foreground">{stat.students} students</p>
                      </div>
                      <div className="text-right">
                        <div className="text-sm font-medium text-accent">{stat.attendance}% attendance</div>
                        <div className="text-sm text-muted-foreground">{stat.revenue.toLocaleString()} KGS revenue</div>
                      </div>
                    </div>
                    <div className="w-full bg-muted rounded-full h-2">
                      <div
                        className="bg-accent h-2 rounded-full transition-all"
                        style={{ width: `${stat.attendance}%` }}
                      />
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </Layout>
  );
}