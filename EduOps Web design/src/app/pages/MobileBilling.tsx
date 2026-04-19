import { useState } from "react";
import Layout from "../components/Layout";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";
import { ChevronDown, ChevronUp, CreditCard } from "lucide-react";

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
  },
  {
    id: 4,
    period: "January 2026",
    course: "Math Course",
    amount: 6000,
    status: "paid",
    paymentMethod: "Cash",
  },
  {
    id: 5,
    period: "December 2025",
    course: "English Course",
    amount: 5000,
    status: "paid",
    paymentMethod: "Mbank",
  },
];

export default function MobileBilling() {
  const [expandedId, setExpandedId] = useState<number | null>(null);

  const totalPaid = invoicesData
    .filter((inv) => inv.status === "paid")
    .reduce((sum, inv) => sum + inv.amount, 0);

  const currentDebt = invoicesData
    .filter((inv) => inv.status === "unpaid")
    .reduce((sum, inv) => sum + inv.amount, 0);

  const toggleExpand = (id: number) => {
    setExpandedId(expandedId === id ? null : id);
  };

  return (
    <Layout userRole="parent">
      {/* Header */}
      <header className="border-b border-border bg-white px-8 py-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-semibold text-foreground">Billing & Payments</h1>
            <p className="text-muted-foreground mt-1">Manage your invoices and payments</p>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 overflow-auto bg-white p-8">
        <div className="max-w-5xl mx-auto space-y-6">
          {/* Summary Section */}
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
                <p className="text-3xl font-bold text-primary">{currentDebt.toLocaleString()}</p>
                <p className="text-sm text-muted-foreground mt-1">KGS</p>
              </CardContent>
            </Card>
          </div>

          {/* Invoice List */}
          <Card className="border-border">
            <CardHeader>
              <CardTitle>Payment History</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              {invoicesData.map((invoice) => (
                <Card
                  key={invoice.id}
                  className="border-border cursor-pointer hover:shadow-md transition-shadow"
                  onClick={() => toggleExpand(invoice.id)}
                >
                  <CardContent className="p-4">
                    <div className="flex items-center justify-between">
                      <div className="flex-1">
                        <p className="font-semibold text-foreground">
                          {invoice.period} - {invoice.course}
                        </p>
                        <p className="text-2xl font-bold text-foreground mt-1">
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
                        {expandedId === invoice.id ? (
                          <ChevronUp className="w-5 h-5 text-muted-foreground" />
                        ) : (
                          <ChevronDown className="w-5 h-5 text-muted-foreground" />
                        )}
                      </div>
                    </div>

                    {/* Expanded Content */}
                    {expandedId === invoice.id && (
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
                          <div className="flex justify-between text-sm">
                            <span className="text-muted-foreground">Payment Method:</span>
                            <span className="text-foreground font-medium">{invoice.paymentMethod}</span>
                          </div>
                        )}
                        {invoice.status === "unpaid" && (
                          <button className="w-full mt-3 bg-primary hover:bg-primary/90 text-white font-semibold py-3 rounded-lg transition-colors">
                            Pay Now
                          </button>
                        )}
                      </div>
                    )}
                  </CardContent>
                </Card>
              ))}
            </CardContent>
          </Card>
        </div>
      </main>
    </Layout>
  );
}