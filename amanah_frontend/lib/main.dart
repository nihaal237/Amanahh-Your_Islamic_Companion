import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/calender_screen.dart';

void main() => runApp(const AmanahApp());

class AmanahApp extends StatefulWidget {
  const AmanahApp({super.key});

  @override
  State<AmanahApp> createState() => _AmanahAppState();
}

class _AmanahAppState extends State<AmanahApp> {
  // Global state variable holding theme setting
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xfff7f9f9),
        cardColor: Colors.white,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xff121212),
        cardColor: const Color(0xff1e1e1e),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
        ),
      ),
      home: DashboardScreen(onThemeToggle: toggleTheme, currentThemeMode: _themeMode),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final ThemeMode currentThemeMode;

  const DashboardScreen({
    super.key, 
    required this.onThemeToggle, 
    required this.currentThemeMode
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService apiService = ApiService();
  late Future<Map<String, dynamic>> dashboardData;

  @override
  void initState() {
    super.initState();
    dashboardData = apiService.fetchDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.currentThemeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Amanah', style: TextStyle(color: Color(0xff067a53), fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xff1e1e1e) : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode_outlined, 
              color: isDark ? Colors.orangeAccent : Colors.black54
            ), 
            onPressed: widget.onThemeToggle, // Triggers system re-render across the app tree
          ),
          IconButton(
  icon: Icon(Icons.calendar_month_outlined, color: isDark ? Colors.white70 : Colors.black54), 
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CalendarScreen()),
    );
  }, 
),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xff067a53)));
          } else if (snapshot.hasError) {
            return Center(child: Text('Connection error. Is backend server running?'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No server snapshot received'));
          }

          final data = snapshot.data!;
          final prayers = data['prayers_status'] as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("As-salamu alaykum,", style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600], fontSize: 16)),
                Text(data['username'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff067a53))),
                const SizedBox(height: 16),

                // Teal card matching image_43d662.jpg layout details
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xff067a53),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Next Prayer: ${data['next_prayer']}", style: const TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text(data['prayer_time'], style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text("Today, calculated real-time", style: TextStyle(color: Colors.white60, fontSize: 12)),
                        ],
                      ),
                      const Text("عصر", style: TextStyle(color: Colors.white24, fontSize: 64, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _buildGridCard(Icons.menu_book, "Read Quran", "Continue Surah Al-Kahf", context),
                    _buildGridCard(Icons.access_time, "Prayer Times", "5 prayers tracking", context),
                    _buildGridCard(Icons.tag, "Dhikr Counter", "Daily goal: 100", context),
                    _buildGridCard(Icons.emoji_emotions_outlined, "Mood Guidance", "How are you today?", context),
                  ],
                ),
                const SizedBox(height: 24),

                // Inside lib/main.dart where you call _buildPrayerRow:

const Text("Today's Prayers", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
const SizedBox(height: 12),

_buildPrayerRow("Fajr", data['prayer_list_times']['fajr'], prayers['fajr'] ?? false, data['next_prayer'] == 'Fajr', context),
_buildPrayerRow("Dhuhr", data['prayer_list_times']['dhuhr'], prayers['dhuhr'] ?? false, data['next_prayer'] == 'Dhuhr', context),
_buildPrayerRow("Asr", data['prayer_list_times']['asr'], prayers['asr'] ?? false, data['next_prayer'] == 'Asr', context),
_buildPrayerRow("Maghrib", data['prayer_list_times']['maghrib'], prayers['maghrib'] ?? false, data['next_prayer'] == 'Maghrib', context),
_buildPrayerRow("Isha", data['prayer_list_times']['isha'], prayers['isha'] ?? false, data['next_prayer'] == 'Isha', context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridCard(IconData icon, String title, String subtitle, BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xff067a53), size: 28),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(subtitle, style: TextStyle(color: theme.brightness == Brightness.dark ? Colors.white60 : Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPrayerRow(String name, String time, bool isDone, bool isCurrent, BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xff067a53) : theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: isCurrent ? Colors.white : theme.textTheme.bodyLarge?.color)),
          Row(
            children: [
              Text(time, style: TextStyle(color: isCurrent ? Colors.white70 : Colors.grey)),
              const SizedBox(width: 12),
              Icon(
                isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isCurrent ? Colors.white : (isDone ? const Color(0xff067a53) : Colors.grey[300]),
              )
            ],
          )
        ],
      ),
    );
  }
}