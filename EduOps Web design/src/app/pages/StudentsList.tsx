import Layout from "../components/Layout";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "../components/ui/table";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "../components/ui/select";
import { Badge } from "../components/ui/badge";
import { Upload, Plus, Search, Eye } from "lucide-react";
import { useNavigate } from "react-router";

const students = [
  {
    id: 1,
    name: "Alina Bekova",
    parentPhone: "+996 555 123 456",
    branch: "Bishkek",
    group: "English A1",
    status: "Active",
    balance: -4500,
  },
  {
    id: 2,
    name: "Nursultan Karimov",
    parentPhone: "+996 555 234 567",
    branch: "Bishkek",
    group: "Math Grade 7",
    status: "Active",
    balance: 0,
  },
  {
    id: 3,
    name: "Aizada Toktomusheva",
    parentPhone: "+996 555 345 678",
    branch: "Osh",
    group: "Russian B2",
    status: "Active",
    balance: -2000,
  },
  {
    id: 4,
    name: "Timur Asanov",
    parentPhone: "+996 555 456 789",
    branch: "Bishkek",
    group: "English A1",
    status: "Active",
    balance: 1000,
  },
  {
    id: 5,
    name: "Gulnara Ibraimova",
    parentPhone: "+996 555 567 890",
    branch: "Bishkek",
    group: "Chemistry Grade 10",
    status: "Active",
    balance: 0,
  },
  {
    id: 6,
    name: "Azamat Sultanov",
    parentPhone: "+996 555 678 901",
    branch: "Osh",
    group: "Physics Grade 11",
    status: "Active",
    balance: -7800,
  },
  {
    id: 7,
    name: "Ainura Kadyrova",
    parentPhone: "+996 555 789 012",
    branch: "Bishkek",
    group: "Math Grade 8",
    status: "Archived",
    balance: 0,
  },
  {
    id: 8,
    name: "Bektur Osmonov",
    parentPhone: "+996 555 890 123",
    branch: "Bishkek",
    group: "English A2",
    status: "Active",
    balance: -3500,
  },
];

export default function StudentsList() {
  const navigate = useNavigate();

  return (
    <Layout>
      {/* Header */}
      <div className="border-b border-border bg-white px-4 sm:px-8 py-4 sm:py-6">
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl sm:text-3xl font-semibold text-foreground">Students</h1>
            <p className="text-muted-foreground mt-1 text-sm sm:text-base">Manage student information</p>
          </div>
          <div className="flex gap-2 sm:gap-3 w-full sm:w-auto">
            <Button variant="outline" className="border-border flex-1 sm:flex-none">
              <Upload className="w-4 h-4 sm:mr-2" />
              <span className="hidden sm:inline">Import CSV</span>
            </Button>
            <Button className="bg-primary hover:bg-primary/90 flex-1 sm:flex-none">
              <Plus className="w-4 h-4 sm:mr-2" />
              <span className="sm:inline">New Student</span>
            </Button>
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="border-b border-border bg-white px-4 sm:px-8 py-4">
        <div className="flex flex-col sm:flex-row gap-3 sm:gap-4">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input
              placeholder="Search by name..."
              className="pl-10 border-border"
            />
          </div>
          <Select defaultValue="all-branches">
            <SelectTrigger className="w-full sm:w-48 border-border">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all-branches">All Branches</SelectItem>
              <SelectItem value="bishkek">Bishkek</SelectItem>
              <SelectItem value="osh">Osh</SelectItem>
            </SelectContent>
          </Select>
          <Select defaultValue="all-statuses">
            <SelectTrigger className="w-full sm:w-48 border-border">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all-statuses">All Statuses</SelectItem>
              <SelectItem value="active">Active</SelectItem>
              <SelectItem value="archived">Archived</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>

      {/* Students Table - Desktop */}
      <div className="hidden lg:block flex-1 overflow-auto p-4 sm:p-8 bg-white">
        <div className="max-w-7xl mx-auto">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Parent Phone</TableHead>
                <TableHead>Branch</TableHead>
                <TableHead>Group</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Balance</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {students.map((student) => (
                <TableRow key={student.id} className="cursor-pointer hover:bg-muted/50">
                  <TableCell className="font-medium">{student.name}</TableCell>
                  <TableCell className="text-muted-foreground">{student.parentPhone}</TableCell>
                  <TableCell className="text-muted-foreground">{student.branch}</TableCell>
                  <TableCell className="text-muted-foreground">{student.group}</TableCell>
                  <TableCell>
                    <Badge
                      variant="outline"
                      className={
                        student.status === "Active"
                          ? "bg-green-50 text-green-700 border-green-200"
                          : "bg-gray-50 text-gray-600 border-gray-200"
                      }
                    >
                      {student.status}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <span
                      className={`font-semibold ${
                        student.balance < 0
                          ? "text-primary"
                          : student.balance > 0
                          ? "text-green-600"
                          : "text-muted-foreground"
                      }`}
                    >
                      {student.balance !== 0 ? `${student.balance.toLocaleString()} KGS` : "0 KGS"}
                    </span>
                  </TableCell>
                  <TableCell className="text-right">
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => navigate(`/students/${student.id}`)}
                    >
                      <Eye className="w-4 h-4 mr-2" />
                      View
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      </div>

      {/* Students Cards - Mobile */}
      <div className="lg:hidden flex-1 overflow-auto p-4 bg-white">
        <div className="space-y-3">
          {students.map((student) => (
            <div
              key={student.id}
              onClick={() => navigate(`/students/${student.id}`)}
              className="border border-border rounded-lg p-4 bg-white hover:shadow-md transition-shadow cursor-pointer"
            >
              <div className="flex items-start justify-between mb-3">
                <div>
                  <h3 className="font-semibold text-foreground text-base">{student.name}</h3>
                  <p className="text-sm text-muted-foreground mt-0.5">{student.parentPhone}</p>
                </div>
                <Badge
                  variant="outline"
                  className={
                    student.status === "Active"
                      ? "bg-green-50 text-green-700 border-green-200"
                      : "bg-gray-50 text-gray-600 border-gray-200"
                  }
                >
                  {student.status}
                </Badge>
              </div>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Branch:</span>
                  <span className="font-medium text-foreground">{student.branch}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Group:</span>
                  <span className="font-medium text-foreground">{student.group}</span>
                </div>
                <div className="flex justify-between pt-2 border-t border-border">
                  <span className="text-muted-foreground">Balance:</span>
                  <span
                    className={`font-semibold ${
                      student.balance < 0
                        ? "text-primary"
                        : student.balance > 0
                        ? "text-green-600"
                        : "text-muted-foreground"
                    }`}
                  >
                    {student.balance !== 0 ? `${student.balance.toLocaleString()} KGS` : "0 KGS"}
                  </span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </Layout>
  );
}