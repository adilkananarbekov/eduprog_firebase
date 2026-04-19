import { createBrowserRouter } from "react-router";
import Login from "./pages/Login";
import AdminDashboard from "./pages/AdminDashboard";
import StudentsList from "./pages/StudentsList";
import AttendanceMarking from "./pages/AttendanceMarking";
import ParentDashboard from "./pages/ParentDashboard";
import Groups from "./pages/Groups";
import Schedule from "./pages/Schedule";
import Billing from "./pages/Billing";
import Reports from "./pages/Reports";
import Settings from "./pages/Settings";
import MobileSchedule from "./pages/MobileSchedule";
import MobileBilling from "./pages/MobileBilling";
import MobileAnnouncements from "./pages/MobileAnnouncements";
import NotFound from "./pages/NotFound";
import WeekSchedule from "./pages/WeekSchedule";
import StudentProfile from "./pages/StudentProfile";
import ParentSettings from "./pages/ParentSettings";

export const router = createBrowserRouter([
  {
    path: "/",
    Component: Login,
  },
  {
    path: "/admin",
    Component: AdminDashboard,
  },
  {
    path: "/students",
    Component: StudentsList,
  },
  {
    path: "/students/:id",
    Component: StudentProfile,
  },
  {
    path: "/groups",
    Component: Groups,
  },
  {
    path: "/schedule",
    Component: Schedule,
  },
  {
    path: "/attendance",
    Component: Schedule,
  },
  {
    path: "/attendance/:sessionId",
    Component: AttendanceMarking,
  },
  {
    path: "/billing",
    Component: Billing,
  },
  {
    path: "/reports",
    Component: Reports,
  },
  {
    path: "/settings",
    Component: Settings,
  },
  {
    path: "/parent",
    Component: ParentDashboard,
  },
  {
    path: "/parent/settings",
    Component: ParentSettings,
  },
  {
    path: "/parent/schedule",
    Component: MobileSchedule,
  },
  {
    path: "/parent/billing",
    Component: MobileBilling,
  },
  {
    path: "/parent/announcements",
    Component: MobileAnnouncements,
  },
  {
    path: "*",
    Component: NotFound,
  },
]);