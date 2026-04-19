import Layout from "../components/Layout";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Plus, Users } from "lucide-react";

const groups = [
  { id: 1, name: "English A1", students: 12, teacher: "Gulnara Ibraimova", schedule: "Mon, Wed, Fri 10:00" },
  { id: 2, name: "Math Grade 7", students: 18, teacher: "Asan Toktomushev", schedule: "Tue, Thu 14:00" },
  { id: 3, name: "Russian B2", students: 10, teacher: "Ainura Kadyrova", schedule: "Mon, Wed 16:00" },
  { id: 4, name: "Physics Grade 11", students: 15, teacher: "Bektur Osmonov", schedule: "Tue, Thu, Fri 11:00" },
];

export default function Groups() {
  return (
    <Layout>
      <div className="border-b border-border bg-white px-8 py-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-semibold text-foreground">Groups</h1>
            <p className="text-muted-foreground mt-1">Manage classes and cohorts</p>
          </div>
          <Button className="bg-accent hover:bg-accent/90">
            <Plus className="w-4 h-4 mr-2" />
            Create New Group
          </Button>
        </div>
      </div>
      <div className="flex-1 overflow-auto p-8 bg-white">
        <div className="max-w-7xl mx-auto">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {groups.map((group) => (
              <Card key={group.id} className="border-border hover:shadow-md transition-shadow cursor-pointer">
                <CardHeader>
                  <CardTitle className="flex items-center justify-between">
                    <span>{group.name}</span>
                    <div className="flex items-center gap-2 text-muted-foreground text-sm font-normal">
                      <Users className="w-4 h-4" />
                      <span>{group.students} students</span>
                    </div>
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-3">
                  <div className="flex justify-between text-sm">
                    <span className="text-muted-foreground">Teacher:</span>
                    <span className="text-foreground font-medium">{group.teacher}</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-muted-foreground">Schedule:</span>
                    <span className="text-foreground font-medium">{group.schedule}</span>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      </div>
    </Layout>
  );
}