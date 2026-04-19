import Layout from "../components/Layout";
import { Button } from "../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "../components/ui/select";
import { Save } from "lucide-react";

export default function Settings() {
  return (
    <Layout>
      <div className="border-b border-border bg-white px-8 py-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-semibold text-foreground">Settings</h1>
            <p className="text-muted-foreground mt-1">Manage organization settings</p>
          </div>
          <Button className="bg-accent hover:bg-accent/90">
            <Save className="w-4 h-4 mr-2" />
            Save Changes
          </Button>
        </div>
      </div>
      <div className="flex-1 overflow-auto p-8 bg-white">
        <div className="max-w-3xl mx-auto space-y-6">
          {/* Organization Settings */}
          <Card className="border-border">
            <CardHeader>
              <CardTitle>Organization Information</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="org-name">Organization Name</Label>
                <Input
                  id="org-name"
                  defaultValue="EduOps School"
                  className="border-border"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="timezone">Timezone</Label>
                <Select defaultValue="asia-bishkek">
                  <SelectTrigger id="timezone" className="border-border">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="asia-bishkek">Asia/Bishkek (GMT+6)</SelectItem>
                    <SelectItem value="asia-almaty">Asia/Almaty (GMT+5)</SelectItem>
                    <SelectItem value="asia-tashkent">Asia/Tashkent (GMT+5)</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label htmlFor="currency">Currency</Label>
                <Select defaultValue="kgs">
                  <SelectTrigger id="currency" className="border-border">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="kgs">Kyrgyzstani Som (KGS)</SelectItem>
                    <SelectItem value="usd">US Dollar (USD)</SelectItem>
                    <SelectItem value="eur">Euro (EUR)</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </CardContent>
          </Card>

          {/* Localization Settings */}
          <Card className="border-border">
            <CardHeader>
              <CardTitle>Localization</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="language">Default Language</Label>
                <Select defaultValue="ru">
                  <SelectTrigger id="language" className="border-border">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="ru">Русский (Russian)</SelectItem>
                    <SelectItem value="kg">Кыргызча (Kyrgyz)</SelectItem>
                    <SelectItem value="en">English</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </CardContent>
          </Card>

          {/* Attendance Settings */}
          <Card className="border-border">
            <CardHeader>
              <CardTitle>Attendance Settings</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="edit-window">Attendance Edit Window (hours)</Label>
                <Input
                  id="edit-window"
                  type="number"
                  defaultValue="24"
                  className="border-border"
                />
                <p className="text-sm text-muted-foreground">
                  Teachers can edit attendance within this time window after submission
                </p>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </Layout>
  );
}