import { useState } from "react";
import { useNavigate, Link } from "react-router";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import logo from "../../assets/06ec834f803405bdc67336243d2c3f6e0f882eba.png";

export default function Login() {
  const navigate = useNavigate();
  const [phone, setPhone] = useState("");
  const [password, setPassword] = useState("");

  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault();
    // Mock login - redirect to admin dashboard
    navigate("/admin");
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-white">
      <div className="w-full max-w-md">
        <div className="bg-white border border-border rounded-lg shadow-sm p-8">
          {/* Logo and Brand */}
          <div className="text-center mb-8">
            <div className="inline-flex items-center justify-center w-20 h-20 mb-4">
              <img src={logo} alt="Ala-Too University" className="w-full h-full object-contain" />
            </div>
            <h1 className="text-3xl font-semibold text-foreground">EduOps</h1>
            <p className="text-muted-foreground mt-2">School Management System</p>
            <p className="text-sm text-muted-foreground mt-1">Ala-Too International University</p>
          </div>

          {/* Login Form */}
          <form onSubmit={handleLogin} className="space-y-6">
            <div className="space-y-2">
              <Label htmlFor="phone">Phone Number</Label>
              <Input
                id="phone"
                type="tel"
                placeholder="+996 XXX XXX XXX"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                className="border-border"
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="password">Password</Label>
              <Input
                id="password"
                type="password"
                placeholder="Enter your password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="border-border"
                required
              />
            </div>

            <Button type="submit" className="w-full bg-primary hover:bg-primary/90">
              Log In
            </Button>

            <div className="text-center">
              <a href="#" className="text-sm text-muted-foreground hover:text-foreground">
                Forgot Password?
              </a>
            </div>
          </form>

          {/* Demo Navigation */}
          <div className="mt-8 pt-6 border-t border-border">
            <p className="text-xs text-muted-foreground text-center mb-3">Quick Demo Navigation:</p>
            <div className="flex flex-wrap gap-2 justify-center">
              <Link to="/admin">
                <Button variant="outline" size="sm" className="text-xs">Admin Dashboard</Button>
              </Link>
              <Link to="/students">
                <Button variant="outline" size="sm" className="text-xs">Students List</Button>
              </Link>
              <Link to="/attendance/1">
                <Button variant="outline" size="sm" className="text-xs">Attendance</Button>
              </Link>
              <Link to="/parent">
                <Button variant="outline" size="sm" className="text-xs border-accent text-accent">Parent/Student View</Button>
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}