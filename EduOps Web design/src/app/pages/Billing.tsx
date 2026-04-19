import Layout from "../components/Layout";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "../components/ui/table";
import { Badge } from "../components/ui/badge";
import { DollarSign, FileText } from "lucide-react";

const invoices = [
  { id: 1, student: "Alina Bekova", group: "English A1", period: "January 2026", amount: 5000, paid: 500, status: "Partial" },
  { id: 2, student: "Nursultan Karimov", group: "Math Grade 7", period: "January 2026", amount: 6000, paid: 6000, status: "Paid" },
  { id: 3, student: "Azamat Sultanov", group: "Physics Grade 11", period: "January 2026", amount: 7000, paid: 0, status: "Unpaid" },
  { id: 4, student: "Ainura Kadyrova", group: "Russian B2", period: "January 2026", amount: 5500, paid: 5500, status: "Paid" },
  { id: 5, student: "Timur Asanov", group: "English A1", period: "January 2026", amount: 5000, paid: 2500, status: "Partial" },
];

export default function Billing() {
  return (
    <Layout>
      <div className="border-b border-border bg-white px-8 py-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-semibold text-foreground">Billing</h1>
            <p className="text-muted-foreground mt-1">Manage invoices and payments</p>
          </div>
          <Button className="bg-accent hover:bg-accent/90">
            <FileText className="w-4 h-4 mr-2" />
            Generate Monthly Invoices
          </Button>
        </div>
      </div>
      <div className="flex-1 overflow-auto p-8 bg-white">
        <div className="max-w-7xl mx-auto space-y-6">
          {/* Summary Cards */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <Card className="border-border">
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">Total Invoiced</CardTitle>
                <DollarSign className="w-5 h-5 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-3xl font-semibold text-foreground">28,500 KGS</div>
              </CardContent>
            </Card>
            <Card className="border-border">
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">Total Collected</CardTitle>
                <DollarSign className="w-5 h-5 text-accent" />
              </CardHeader>
              <CardContent>
                <div className="text-3xl font-semibold text-accent">14,500 KGS</div>
              </CardContent>
            </Card>
            <Card className="border-border">
              <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-sm font-medium text-muted-foreground">Outstanding Debt</CardTitle>
                <DollarSign className="w-5 h-5 text-primary" />
              </CardHeader>
              <CardContent>
                <div className="text-3xl font-semibold text-primary">14,000 KGS</div>
              </CardContent>
            </Card>
          </div>

          {/* Invoices Table */}
          <Card className="border-border">
            <CardHeader>
              <CardTitle>Recent Invoices</CardTitle>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow className="bg-muted/50 hover:bg-muted/50">
                    <TableHead className="font-semibold text-foreground">Student</TableHead>
                    <TableHead className="font-semibold text-foreground">Group</TableHead>
                    <TableHead className="font-semibold text-foreground">Period</TableHead>
                    <TableHead className="font-semibold text-foreground">Amount</TableHead>
                    <TableHead className="font-semibold text-foreground">Paid</TableHead>
                    <TableHead className="font-semibold text-foreground">Status</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {invoices.map((invoice) => (
                    <TableRow key={invoice.id} className="hover:bg-muted/20 cursor-pointer">
                      <TableCell className="font-medium">{invoice.student}</TableCell>
                      <TableCell className="text-muted-foreground">{invoice.group}</TableCell>
                      <TableCell className="text-muted-foreground">{invoice.period}</TableCell>
                      <TableCell className="text-foreground">{invoice.amount.toLocaleString()} KGS</TableCell>
                      <TableCell className="text-foreground">{invoice.paid.toLocaleString()} KGS</TableCell>
                      <TableCell>
                        {invoice.status === "Paid" ? (
                          <Badge variant="outline" className="bg-green-50 text-green-700 border-green-200">
                            Paid
                          </Badge>
                        ) : invoice.status === "Partial" ? (
                          <Badge variant="outline" className="bg-yellow-50 text-yellow-700 border-yellow-200">
                            Partial
                          </Badge>
                        ) : (
                          <Badge variant="outline" className="bg-red-50 text-primary border-red-200">
                            Unpaid
                          </Badge>
                        )}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </div>
      </div>
    </Layout>
  );
}