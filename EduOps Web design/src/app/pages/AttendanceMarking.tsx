import { useState } from "react";
import Layout from "../components/Layout";
import { Button } from "../components/ui/button";
import { Card, CardContent } from "../components/ui/card";
import { RadioGroup, RadioGroupItem } from "../components/ui/radio-group";
import { Label } from "../components/ui/label";
import { MessageSquare, ArrowLeft } from "lucide-react";
import { useNavigate } from "react-router";

interface Student {
  id: number;
  name: string;
  status: "present" | "absent" | "late" | "excused";
}

const initialStudents: Student[] = [
  { id: 1, name: "Alina Bekova", status: "present" },
  { id: 2, name: "Nursultan Karimov", status: "present" },
  { id: 3, name: "Timur Asanov", status: "present" },
  { id: 4, name: "Gulnara Ibraimova", status: "present" },
  { id: 5, name: "Bektur Osmonov", status: "present" },
  { id: 6, name: "Ainura Kadyrova", status: "present" },
  { id: 7, name: "Azamat Sultanov", status: "present" },
  { id: 8, name: "Aidana Toktosheva", status: "present" },
];

export default function AttendanceMarking() {
  const navigate = useNavigate();
  const [students, setStudents] = useState<Student[]>(initialStudents);

  const handleStatusChange = (studentId: number, status: string) => {
    setStudents(
      students.map((student) =>
        student.id === studentId
          ? { ...student, status: status as Student["status"] }
          : student
      )
    );
  };

  const handleSubmit = () => {
    // Mock submit
    alert("Attendance submitted successfully!");
    navigate("/admin");
  };

  return (
    <Layout>
      {/* Header */}
      <div className="border-b border-border bg-white px-8 py-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Button
              variant="ghost"
              size="icon"
              onClick={() => navigate("/admin")}
              className="text-muted-foreground hover:text-foreground"
            >
              <ArrowLeft className="w-5 h-5" />
            </Button>
            <div>
              <h1 className="text-3xl font-semibold text-foreground">Mark Attendance</h1>
              <p className="text-muted-foreground mt-1">
                Group: English A1 | Date: January 31, 2026, 10:00 AM
              </p>
            </div>
          </div>
          <Button onClick={handleSubmit} className="bg-primary hover:bg-primary/90 px-8">
            Submit Attendance
          </Button>
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 overflow-auto p-8 bg-white">
        <div className="max-w-4xl mx-auto space-y-4">
          {students.map((student) => (
            <Card key={student.id} className="border-border hover:shadow-sm transition-shadow">
              <CardContent className="p-6">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-4 flex-1">
                    <div className="w-12 h-12 rounded-full bg-muted flex items-center justify-center">
                      <span className="text-lg font-semibold text-foreground">
                        {student.name.split(" ").map((n) => n[0]).join("")}
                      </span>
                    </div>
                    <div>
                      <h3 className="text-lg font-medium text-foreground">{student.name}</h3>
                    </div>
                  </div>

                  <div className="flex items-center gap-6">
                    <RadioGroup
                      value={student.status}
                      onValueChange={(value) => handleStatusChange(student.id, value)}
                      className="flex gap-6"
                    >
                      <div className="flex items-center space-x-2">
                        <RadioGroupItem value="present" id={`present-${student.id}`} />
                        <Label
                          htmlFor={`present-${student.id}`}
                          className="cursor-pointer text-foreground"
                        >
                          Present
                        </Label>
                      </div>
                      <div className="flex items-center space-x-2">
                        <RadioGroupItem
                          value="absent"
                          id={`absent-${student.id}`}
                          className="border-primary data-[state=checked]:bg-primary data-[state=checked]:border-primary"
                        />
                        <Label
                          htmlFor={`absent-${student.id}`}
                          className={`cursor-pointer ${
                            student.status === "absent" ? "text-primary" : "text-foreground"
                          }`}
                        >
                          Absent
                        </Label>
                      </div>
                      <div className="flex items-center space-x-2">
                        <RadioGroupItem value="late" id={`late-${student.id}`} />
                        <Label
                          htmlFor={`late-${student.id}`}
                          className="cursor-pointer text-foreground"
                        >
                          Late
                        </Label>
                      </div>
                      <div className="flex items-center space-x-2">
                        <RadioGroupItem value="excused" id={`excused-${student.id}`} />
                        <Label
                          htmlFor={`excused-${student.id}`}
                          className="cursor-pointer text-foreground"
                        >
                          Excused
                        </Label>
                      </div>
                    </RadioGroup>

                    <Button
                      variant="ghost"
                      size="icon"
                      className="text-muted-foreground hover:text-foreground"
                    >
                      <MessageSquare className="w-5 h-5" />
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    </Layout>
  );
}
