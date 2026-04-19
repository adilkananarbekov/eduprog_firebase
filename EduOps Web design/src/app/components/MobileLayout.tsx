import { Link, useLocation } from "react-router";
import { Home, Calendar, CreditCard, MessageSquare, Bell, User } from "lucide-react";
import logo from "../../assets/06ec834f803405bdc67336243d2c3f6e0f882eba.png";

interface MobileLayoutProps {
  children: React.ReactNode;
  title?: string;
  showHeader?: boolean;
}

const bottomNavigation = [
  { name: "Home", href: "/parent", icon: Home },
  { name: "Schedule", href: "/parent/schedule", icon: Calendar },
  { name: "Billing", href: "/parent/billing", icon: CreditCard },
  { name: "Feed", href: "/parent/announcements", icon: MessageSquare },
];

export default function MobileLayout({ children, title = "Dashboard", showHeader = true }: MobileLayoutProps) {
  const location = useLocation();

  return (
    <div className="flex flex-col min-h-[100dvh] bg-white">
      {/* Top Bar */}
      {showHeader && (
        <div className="sticky top-0 z-10 bg-white border-b border-border px-4 py-4 pt-[max(1rem,env(safe-area-inset-top))]">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <img src={logo} alt="Ala-Too University" className="w-8 h-8 object-contain" />
              <h1 className="text-xl font-semibold text-foreground">{title}</h1>
            </div>
            <div className="flex items-center gap-3">
              <button className="relative p-2 rounded-full hover:bg-muted transition-colors">
                <Bell className="w-5 h-5 text-muted-foreground" />
                <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-primary rounded-full"></span>
              </button>
              <button className="p-2 rounded-full hover:bg-muted transition-colors">
                <User className="w-5 h-5 text-muted-foreground" />
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Main Content */}
      <div className="flex-1 overflow-auto pb-[calc(88px+env(safe-area-inset-bottom))]">
        {children}
      </div>

      {/* Bottom Navigation */}
      <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-border pb-[max(0.5rem,env(safe-area-inset-bottom))]">
        <nav className="mx-auto flex w-full max-w-3xl items-center justify-around px-2 py-3">
          {bottomNavigation.map((item) => {
            const isActive = location.pathname === item.href;
            const Icon = item.icon;
            return (
              <Link
                key={item.name}
                to={item.href}
                className={`flex flex-col items-center gap-1 px-4 py-2 rounded-lg transition-colors ${
                  isActive
                    ? "text-primary"
                    : "text-muted-foreground"
                }`}
              >
                <Icon className={`w-6 h-6 ${isActive ? "stroke-[2.5]" : ""}`} />
                <span className="text-xs font-medium">{item.name}</span>
              </Link>
            );
          })}
        </nav>
      </div>
    </div>
  );
}