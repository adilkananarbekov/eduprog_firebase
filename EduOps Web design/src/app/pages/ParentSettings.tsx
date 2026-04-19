import Layout from "../components/Layout";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { Avatar, AvatarFallback } from "../components/ui/avatar";
import { User, Mail, Phone, Lock, LogOut } from "lucide-react";

export default function ParentSettings() {
  return (
    <Layout userRole="parent">
      {/* Header */}
      <header className="border-b border-border bg-white px-8 py-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-semibold text-foreground">Settings</h1>
            <p className="text-muted-foreground mt-1">Manage your account and preferences</p>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 overflow-auto bg-white p-8">
        <div className="max-w-4xl mx-auto space-y-6">
          {/* Profile Section */}
          <Card className="border-border">
            <CardHeader>
              <CardTitle>Profile Information</CardTitle>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="flex items-center gap-4">
                <Avatar className="w-20 h-20">
                  <AvatarFallback className="bg-primary text-white text-2xl">AB</AvatarFallback>
                </Avatar>
                <div>
                  <h3 className="text-lg font-semibold text-foreground">Alina Beknazarova</h3>
                  <p className="text-sm text-muted-foreground">Student</p>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="name">Full Name</Label>
                  <Input id="name" defaultValue="Alina Beknazarova" />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="email">Email Address</Label>
                  <Input id="email" type="email" defaultValue="alina.b@example.com" />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="phone">Phone Number</Label>
                  <Input id="phone" type="tel" defaultValue="+996 555 123 456" />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="parentPhone">Parent Phone</Label>
                  <Input id="parentPhone" type="tel" defaultValue="+996 555 654 321" />
                </div>
              </div>

              <div className="flex justify-end gap-3 pt-4 border-t border-border">
                <Button variant="outline">Cancel</Button>
                <Button className="bg-primary hover:bg-primary/90">Save Changes</Button>
              </div>
            </CardContent>
          </Card>

          {/* Security Section */}
          <Card className="border-border">
            <CardHeader>
              <CardTitle>Security</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="currentPassword">Current Password</Label>
                <Input id="currentPassword" type="password" placeholder="Enter current password" />
              </div>
              <div className="space-y-2">
                <Label htmlFor="newPassword">New Password</Label>
                <Input id="newPassword" type="password" placeholder="Enter new password" />
              </div>
              <div className="space-y-2">
                <Label htmlFor="confirmPassword">Confirm New Password</Label>
                <Input id="confirmPassword" type="password" placeholder="Confirm new password" />
              </div>

              <div className="flex justify-end gap-3 pt-4 border-t border-border">
                <Button variant="outline">Cancel</Button>
                <Button className="bg-primary hover:bg-primary/90">
                  <Lock className="w-4 h-4 mr-2" />
                  Update Password
                </Button>
              </div>
            </CardContent>
          </Card>

          {/* Notifications Section */}
          <Card className="border-border">
            <CardHeader>
              <CardTitle>Notification Preferences</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between py-3 border-b border-border">
                <div>
                  <h4 className="font-medium text-foreground">Attendance Alerts</h4>
                  <p className="text-sm text-muted-foreground">Get notified about attendance status</p>
                </div>
                <input type="checkbox" defaultChecked className="w-5 h-5 text-primary" />
              </div>
              <div className="flex items-center justify-between py-3 border-b border-border">
                <div>
                  <h4 className="font-medium text-foreground">Payment Reminders</h4>
                  <p className="text-sm text-muted-foreground">Receive reminders for upcoming payments</p>
                </div>
                <input type="checkbox" defaultChecked className="w-5 h-5 text-primary" />
              </div>
              <div className="flex items-center justify-between py-3 border-b border-border">
                <div>
                  <h4 className="font-medium text-foreground">Announcements</h4>
                  <p className="text-sm text-muted-foreground">Get notified about school announcements</p>
                </div>
                <input type="checkbox" defaultChecked className="w-5 h-5 text-primary" />
              </div>
              <div className="flex items-center justify-between py-3">
                <div>
                  <h4 className="font-medium text-foreground">Schedule Changes</h4>
                  <p className="text-sm text-muted-foreground">Be informed about schedule updates</p>
                </div>
                <input type="checkbox" defaultChecked className="w-5 h-5 text-primary" />
              </div>
            </CardContent>
          </Card>

          {/* Logout Section */}
          <Card className="border-primary bg-red-50">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <h4 className="font-semibold text-foreground">Sign Out</h4>
                  <p className="text-sm text-muted-foreground mt-1">Sign out from your account</p>
                </div>
                <Button variant="outline" className="border-primary text-primary hover:bg-primary hover:text-white">
                  <LogOut className="w-4 h-4 mr-2" />
                  Sign Out
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      </main>
    </Layout>
  );
}
