import { useState } from "react";
import Layout from "../components/Layout";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import { Badge } from "../components/ui/badge";
import { Bell, User, Filter } from "lucide-react";
import { Button } from "../components/ui/button";

const announcementsData = [
  {
    id: 1,
    sender: "Admin",
    senderType: "admin",
    date: "2 hours ago",
    content: "Reminder: School will be closed on Monday for the national holiday. Classes will resume on Tuesday.",
    category: "school",
    isImportant: true,
  },
  {
    id: 2,
    sender: "Gulnara Ibraimova",
    senderType: "teacher",
    date: "5 hours ago",
    content: "English A1 group: Please complete Chapter 5 exercises for our next class on Wednesday.",
    category: "group",
    isImportant: false,
  },
  {
    id: 3,
    sender: "Admin",
    senderType: "admin",
    date: "1 day ago",
    content: "New online payment system is now available. You can pay tuition fees through Mbank or O! Pay.",
    category: "school",
    isImportant: false,
  },
  {
    id: 4,
    sender: "Asan Toktomushev",
    senderType: "teacher",
    date: "2 days ago",
    content: "Math group: Great work on the recent test! Average score was 85%. Keep it up!",
    category: "group",
    isImportant: false,
  },
  {
    id: 5,
    sender: "Admin",
    senderType: "admin",
    date: "3 days ago",
    content: "Parent-Teacher conference scheduled for February 28th. Please check your email for time slots.",
    category: "school",
    isImportant: true,
  },
  {
    id: 6,
    sender: "Gulnara Ibraimova",
    senderType: "teacher",
    date: "1 week ago",
    content: "English speaking club will be held every Friday at 16:00. All students are welcome to join!",
    category: "group",
    isImportant: false,
  },
];

export default function MobileAnnouncements() {
  const [activeTab, setActiveTab] = useState<"school" | "group">("school");

  const filteredAnnouncements = announcementsData.filter((item) => item.category === activeTab);

  return (
    <Layout userRole="parent">
      {/* Header */}
      <header className="border-b border-border bg-white px-8 py-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-semibold text-foreground">Announcements</h1>
            <p className="text-muted-foreground mt-1">Stay updated with school news and group messages</p>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 overflow-auto bg-white">
        <div className="max-w-5xl mx-auto">{/* Filter Tabs */}
          <div className="sticky top-0 z-10 bg-white border-b border-border">
            <div className="flex items-center px-8">
              <button
                onClick={() => setActiveTab("school")}
                className={`flex-1 py-4 px-4 text-sm font-semibold transition-colors ${
                  activeTab === "school"
                    ? "text-primary border-b-2 border-primary"
                    : "text-muted-foreground hover:text-foreground"
                }`}
              >
                School News
              </button>
              <button
                onClick={() => setActiveTab("group")}
                className={`flex-1 py-4 px-4 text-sm font-semibold transition-colors ${
                  activeTab === "group"
                    ? "text-primary border-b-2 border-primary"
                    : "text-muted-foreground hover:text-foreground"
                }`}
              >
                My Group
              </button>
            </div>
          </div>

          {/* Message Feed */}
          <div className="p-8 space-y-4">
            {filteredAnnouncements.map((announcement) => (
              <Card
                key={announcement.id}
                className={`border-border ${
                  announcement.isImportant ? "border-l-4 border-l-primary" : ""
                }`}
              >
                <CardContent className="p-4">
                  <div className="flex items-start gap-3">
                    {/* Avatar */}
                    <div
                      className={`flex-shrink-0 w-10 h-10 rounded-full flex items-center justify-center ${
                        announcement.senderType === "admin" ? "bg-primary" : "bg-accent"
                      }`}
                    >
                      {announcement.senderType === "admin" ? (
                        <Bell className="w-5 h-5 text-white" />
                      ) : (
                        <User className="w-5 h-5 text-white" />
                      )}
                    </div>

                    {/* Content */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between mb-1">
                        <h3 className="font-semibold text-foreground text-sm">{announcement.sender}</h3>
                        {announcement.isImportant && (
                          <Badge variant="outline" className="bg-red-50 text-primary border-red-200 text-xs">
                            Important
                          </Badge>
                        )}
                      </div>
                      <p className="text-xs text-muted-foreground mb-2">{announcement.date}</p>
                      <p className="text-sm text-foreground leading-relaxed">{announcement.content}</p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}

            {filteredAnnouncements.length === 0 && (
              <div className="text-center py-12">
                <p className="text-muted-foreground">No announcements yet</p>
              </div>
            )}
          </div>
        </div>
      </main>
    </Layout>
  );
}