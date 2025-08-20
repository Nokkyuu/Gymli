import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../utils/themes/themes.dart';
import 'calendar/constants/calendar_constants.dart';
import 'calendar/controllers/calendar_controller.dart';
import 'calendar/widgets/widgets.dart';
import 'calendar/widgets/calendar_popup_menu.dart';

ThemeColors themeColors = ThemeColors();

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late CalendarController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CalendarController();
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Helper methods
  DateTime _normalize(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              TableCalendar(
                headerVisible: true,
                headerStyle: const HeaderStyle(
                  titleCentered: false,
                  formatButtonVisible: false,
                  leftChevronVisible: true,
                  rightChevronVisible: true,
                  leftChevronIcon: Icon(null),
                  rightChevronIcon: Icon(null),
                ),
                firstDay: CalendarConstants.minDate,
                lastDay: CalendarConstants.maxDate,
                focusedDay: _controller.focusedDay,
                calendarFormat: CalendarFormat.month,
                startingDayOfWeek: StartingDayOfWeek.monday,
                selectedDayPredicate: (day) =>
                    _controller.selectedDay != null &&
                    _normalize(day) == _normalize(_controller.selectedDay!),
                onDaySelected: (selectedDay, focusedDay) {
                  _controller.selectDay(selectedDay, focusedDay);
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    return CalendarDayCell(
                      context: context,
                      day: day,
                      controller: _controller,
                      selected: false,
                      today: false,
                      onShowPopupMenu: (ctx, d, pos) => showDayPopupMenu(
                        context: ctx,
                        controller: _controller,
                        day: d,
                        position: pos,
                      ),
                    );
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    return CalendarDayCell(
                      context: context,
                      day: day,
                      controller: _controller,
                      selected: true,
                      today: false,
                      onShowPopupMenu: (ctx, d, pos) => showDayPopupMenu(
                        context: ctx,
                        controller: _controller,
                        day: d,
                        position: pos,
                      ),
                    );
                  },
                  todayBuilder: (context, day, focusedDay) {
                    return CalendarDayCell(
                      context: context,
                      day: day,
                      controller: _controller,
                      selected: false,
                      today: true,
                      onShowPopupMenu: (ctx, d, pos) => showDayPopupMenu(
                        context: ctx,
                        controller: _controller,
                        day: d,
                        position: pos,
                      ),
                    );
                  },
                ),
              ),
              const CalendarLegend(),
              const SizedBox(height: 10),
              const Divider(),
              if (_controller.selectedDay != null)
                CalendarDayDetails(
                  day: _normalize(_controller.selectedDay!),
                  controller: _controller,
                ),
              CalendarTabView(controller: _controller),
            ],
          );
        },
      ),
    );
  }
}
