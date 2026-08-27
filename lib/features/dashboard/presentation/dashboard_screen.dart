import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/request_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final todayAttendance = ref.watch(todayAttendanceProvider);
    final tasksState = ref.watch(employeeTasksProvider);
    final requestsState = ref.watch(requestsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: ClipOval(
                child: Image.network(
                  user.photoUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back 👋',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                Text(
                  user.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Attendance Logging Section
          todayAttendance.when(
            data: (attendance) {
              final isCheckedIn = attendance?.checkInTime != null;
              final isCheckedOut = attendance?.checkOutTime != null;

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Daily Work Clock',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Icon(
                            Icons.timer_outlined,
                            color: isCheckedIn ? Colors.green : Colors.grey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (isCheckedOut)
                        Text(
                          'You have clocked out for today. Great work!',
                          style: GoogleFonts.plusJakartaSans(color: Colors.green, fontWeight: FontWeight.w600),
                        )
                      else if (isCheckedIn)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Checked in at ${DateFormat('hh:mm a').format(attendance!.checkInTime!)}',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.statusRejected,
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                ref.read(todayAttendanceProvider.notifier).checkOut();
                              },
                              icon: const Icon(Icons.logout_rounded, color: Colors.white),
                              label: const Text('Clock Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'You are currently clocked out. Check in to log your presence.',
                              style: GoogleFonts.plusJakartaSans(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                ref.read(todayAttendanceProvider.notifier).checkIn();
                              },
                              icon: const Icon(Icons.login_rounded, color: Colors.white),
                              label: const Text('Clock In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => Center(child: Text('Error: $err')),
          ),
          const SizedBox(height: 20),

          // Request Summary Statistics
          if (requestsState.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Request Center',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard('Pending', requestsState.pendingCount.toString(), Colors.orange),
                    const SizedBox(width: 10),
                    _buildStatCard('Approved', requestsState.approvedCount.toString(), Colors.green),
                    const SizedBox(width: 10),
                    _buildStatCard('Rejected', requestsState.rejectedCount.toString(), Colors.red),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 24),

          // Assigned Tasks Section
          Text(
            'My Tasks & Action Items',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          tasksState.when(
            data: (tasks) {
              if (tasks.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text('No active tasks assigned to you.', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                  ),
                );
              }

              return Column(
                children: tasks.map((task) {
                  final isCompleted = task.status == 'Completed';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: CheckboxListTile(
                      activeColor: AppColors.primary,
                      title: Text(
                        task.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                          color: isCompleted ? Colors.grey : null,
                        ),
                      ),
                      subtitle: Text(
                        '${task.description}\nDue: ${DateFormat('yyyy-MM-dd').format(task.dueDate)}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[500]),
                      ),
                      value: isCompleted,
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(employeeTasksProvider.notifier).updateTaskStatus(
                                task.id,
                                val ? 'Completed' : 'Pending',
                              );
                        }
                      },
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => Center(child: Text('Error loading tasks: $err')),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
