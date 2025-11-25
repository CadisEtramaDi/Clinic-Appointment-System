import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth/auth_service.dart';
import 'auth/login_page.dart';
import 'patient/patient_dashboard.dart';
import 'doctor/doctor_dashboard.dart';
import 'admin/admin_dashboard.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => AuthService(), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClinicFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      home: Consumer<AuthService>(
        builder: (context, auth, _) {
          if (!auth.isAuthenticated) {
            return const LoginPage();
          }

          // Route to specific dashboard based on user role
          switch (auth.userRole) {
            case UserRole.patient:
              return const PatientDashboard();
            case UserRole.doctor:
              return const DoctorDashboard();
            case UserRole.admin:
              return const AdminDashboard();
            default:
              return const LoginPage();
          }
        },
      ),
    );
  }
}
