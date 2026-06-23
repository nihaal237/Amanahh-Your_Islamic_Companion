import 'package:flutter/material.dart';
import '../services/api_service.dart';

// ───────────────────────────────────────────────────────────
// Design tokens — kept in one place so the theme is consistent
// and easy to tweak later.
// ───────────────────────────────────────────────────────────
class _Palette {
  static const bg = Color(0xff0a0a0a);
  static const surface = Color(0xff151515);
  static const card = Color(0xfff7f7f7);
  static const primary = Color(0xff0da672);
  static const primaryDark = Color(0xff067a53);
  static const danger = Color(0xffe05a4f);
  static const warn = Color(0xffd6a437);
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ApiService apiService = ApiService();
  late Future<Map<String, dynamic>> calendarData;

  late int _currentMonth;
  late int _currentYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = now.month;
    _currentYear = now.year;
    _fetchCalendar();
  }

  void _fetchCalendar() {
    setState(() {
      calendarData = apiService.fetchCalendarData(
        month: _currentMonth,
        year: _currentYear,
      );
    });
  }

  Future<void> _refresh() => apiService
      .fetchCalendarData(month: _currentMonth, year: _currentYear)
      .then((data) => setState(() => calendarData = Future.value(data)));

  void _goToPreviousMonth() {
    setState(() {
      if (_currentMonth == 1) {
        _currentMonth = 12;
        _currentYear--;
      } else {
        _currentMonth--;
      }
    });
    _fetchCalendar();
  }

  void _goToNextMonth() {
    setState(() {
      if (_currentMonth == 12) {
        _currentMonth = 1;
        _currentYear++;
      } else {
        _currentMonth++;
      }
    });
    _fetchCalendar();
  }

  void _goToToday() {
    final now = DateTime.now();
    if (_currentMonth == now.month && _currentYear == now.year) return;
    setState(() {
      _currentMonth = now.month;
      _currentYear = now.year;
    });
    _fetchCalendar();
  }

  bool get _isOnCurrentMonth {
    final now = DateTime.now();
    return _currentMonth == now.month && _currentYear == now.year;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _Palette.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Calendar",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        actions: [
          AnimatedOpacity(
            opacity: _isOnCurrentMonth ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: _isOnCurrentMonth,
              child: TextButton(
                onPressed: _goToToday,
                child: const Text(
                  "Today",
                  style: TextStyle(
                    color: _Palette.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: calendarData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: _Palette.primary,
                strokeWidth: 2.5,
              ),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _buildErrorState(snapshot.error);
          }

          final data = snapshot.data!;
          final events = data['upcoming_events'] as List<dynamic>;
          final days = data['days'] as List<dynamic>;

          return RefreshIndicator(
            color: _Palette.primary,
            backgroundColor: _Palette.surface,
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 22),
                  _buildMonthNav(data),
                  const SizedBox(height: 18),
                  _buildCalendarCard(days),
                  const SizedBox(height: 28),
                  _buildEventsHeader(events.length),
                  const SizedBox(height: 12),
                  if (events.isEmpty)
                    _buildEmptyEvents()
                  else
                    ...events.map(
                      (e) => _buildEventCard(
                        e['title'],
                        e['date'],
                        e['days_left'],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _Palette.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.mosque_rounded, color: _Palette.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Islamic Calendar",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Let the Islamic calendar guide your days and عبادات",
                style: TextStyle(color: Colors.grey[500], fontSize: 12.5, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Month navigator ───────────────────────────────────────
  Widget _buildMonthNav(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavButton(Icons.chevron_left_rounded, _goToPreviousMonth),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.15), end: Offset.zero)
                      .animate(anim),
                  child: child,
                ),
              ),
              child: Column(
                key: ValueKey("$_currentMonth-$_currentYear"),
                children: [
                  Text(
                    data['hijri_header'],
                    style: const TextStyle(
                      color: _Palette.primary,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data['gregorian_sub'],
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          _buildNavButton(Icons.chevron_right_rounded, _goToNextMonth),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  // ── Calendar grid ──────────────────────────────────────────
  Widget _buildCalendarCard(List<dynamic> days) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 18, 10, 14),
      decoration: BoxDecoration(
        color: _Palette.card,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildWeekDaysHeader(),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 2,
              childAspectRatio: 0.82,
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              final bool isDummy = day['is_dummy'] ?? false;
              final bool isToday = day['is_today'] ?? false;

              if (isDummy) return const SizedBox.shrink();

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isToday ? _Palette.primaryDark : Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: isToday
                      ? [
                          BoxShadow(
                            color: _Palette.primaryDark.withOpacity(0.45),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${day['gregorian_day']}",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isToday ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      "${day['hijri_day']}",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: isToday ? Colors.white70 : _Palette.primaryDark,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDaysHeader() {
    const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days
          .map((d) => Text(
                d,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                  letterSpacing: 0.4,
                ),
              ))
          .toList(),
    );
  }

  // ── Events section ─────────────────────────────────────────
  Widget _buildEventsHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Upcoming Events",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: _Palette.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "$count",
              style: const TextStyle(
                color: _Palette.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyEvents() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Icon(Icons.event_available_rounded, color: Colors.grey[600], size: 30),
          const SizedBox(height: 8),
          Text(
            "No upcoming events this month",
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(String title, String dateStr, dynamic daysLeftRaw) {
    final int daysLeft = (daysLeftRaw is int)
        ? daysLeftRaw
        : int.tryParse(daysLeftRaw.toString()) ?? 0;

    final Color accent = daysLeft <= 3
        ? _Palette.danger
        : daysLeft <= 7
            ? _Palette.warn
            : _Palette.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _Palette.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 56,
            margin: const EdgeInsets.only(left: 2),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.calendar_month_rounded, color: accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      daysLeft == 0 ? "Today" : "$daysLeft d",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Error state ─────────────────────────────────────────────
  Widget _buildErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, color: Colors.grey[500], size: 38),
            const SizedBox(height: 14),
            const Text(
              "Failed to load calendar",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 6),
              Text(
                "$error",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _fetchCalendar,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _Palette.primaryDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}