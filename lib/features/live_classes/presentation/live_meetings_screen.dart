import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/core/utils/keyboard_dismissal.dart';
import 'package:nts_psc_app/features/live_classes/data/live_session_repository.dart';
import 'package:nts_psc_app/features/notifications/presentation/controllers/local_reminder_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

final _savingMeetingProvider = StateProvider.autoDispose.family<bool, Object>(
  (ref, key) => false,
);
final _meetingDateProvider = StateProvider.autoDispose
    .family<DateTime?, Object>((ref, key) => null);
final _meetingCourseProvider = StateProvider.autoDispose
    .family<String?, Object>((ref, key) => null);

class LiveMeetingsScreen extends ConsumerWidget {
  const LiveMeetingsScreen({super.key, this.teacher = false});
  final bool teacher;

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppScaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('Live classes')),
    floatingActionButton: teacher
        ? FloatingActionButton(
            tooltip: 'Schedule class',
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => const _ScheduleMeetingForm(),
            ),
            child: const Icon(Icons.add),
          )
        : null,
    body: SafeArea(
      child: ref
          .watch(liveMeetingsProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry loading live classes'),
                onPressed: () => ref.invalidate(liveMeetingsProvider),
              ),
            ),
            data: (meetings) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(liveMeetingsProvider);
                await ref.read(liveMeetingsProvider.future);
              },
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 96.h),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: meetings.isEmpty ? 1 : meetings.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  if (meetings.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.h),
                      child: Text(
                        'No live classes scheduled.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.interRegular16,
                      ),
                    );
                  }
                  final meeting = meetings[index];
                  final reminderKey = 'live-class:${meeting.id}';
                  final hasReminder =
                      ref
                          .watch(localRemindersProvider)
                          .value
                          ?.contains(reminderKey) ??
                      false;
                  final localDate = MaterialLocalizations.of(
                    context,
                  ).formatMediumDate(meeting.startsAt);
                  final time = TimeOfDay.fromDateTime(
                    meeting.startsAt,
                  ).format(context);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meeting.title, style: AppTextStyles.interSemiBold16),
                      SizedBox(height: 4.h),
                      Text(
                        meeting.courseTitle,
                        style: AppTextStyles.interRegular14,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '$localDate, $time • ${meeting.minutes} min',
                        style: AppTextStyles.interRegular14,
                      ),
                      if (meeting.cancelled || meeting.ended)
                        Text(
                          meeting.cancelled ? 'Cancelled' : 'Ended',
                          style: AppTextStyles.interRegular14,
                        )
                      else
                        Wrap(
                          spacing: 12.w,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Join meeting'),
                              onPressed: () async {
                                try {
                                  await ref
                                      .read(liveSessionRepositoryProvider)
                                      .join(meeting);
                                } catch (_) {
                                  if (context.mounted) {
                                    CustomToast.showError(
                                      context,
                                      message:
                                          'Meeting unavailable. Refresh and retry.',
                                    );
                                  }
                                }
                              },
                            ),
                            if (teacher)
                              TextButton(
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Cancel this class?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => ctx.pop(false),
                                          child: const Text('Keep class'),
                                        ),
                                        TextButton(
                                          onPressed: () => ctx.pop(true),
                                          child: const Text('Cancel class'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed != true || !context.mounted) {
                                    return;
                                  }
                                  try {
                                    await ref
                                        .read(liveSessionRepositoryProvider)
                                        .cancel(meeting.id);
                                    ref.invalidate(liveMeetingsProvider);
                                  } catch (_) {
                                    if (context.mounted) {
                                      CustomToast.showError(
                                        context,
                                        message: 'Could not cancel class.',
                                      );
                                    }
                                  }
                                },
                                child: const Text('Cancel class'),
                              ),
                            if (!teacher)
                              TextButton.icon(
                                icon: Icon(
                                  hasReminder
                                      ? Icons.notifications_active
                                      : Icons.notifications_none,
                                ),
                                label: Text(
                                  hasReminder ? 'Reminder set' : 'Remind me',
                                ),
                                onPressed: () async {
                                  try {
                                    await ref
                                        .read(localRemindersProvider.notifier)
                                        .setLiveClassReminder(
                                          sessionId: meeting.id,
                                          courseTitle: meeting.courseTitle,
                                          sessionTitle: meeting.title,
                                          startsAt: meeting.startsAt,
                                          enabled: !hasReminder,
                                        );
                                    if (context.mounted) {
                                      CustomToast.showSuccess(
                                        context,
                                        message: hasReminder
                                            ? 'Reminder removed'
                                            : 'Reminder set for 15 minutes before class',
                                      );
                                    }
                                  } catch (error) {
                                    if (context.mounted) {
                                      CustomToast.showError(
                                        context,
                                        message: error is StateError
                                            ? error.message
                                            : 'Could not update reminder',
                                      );
                                    }
                                  }
                                },
                              ),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
    ),
  );
}

class _ScheduleMeetingForm extends ConsumerStatefulWidget {
  const _ScheduleMeetingForm();
  @override
  ConsumerState<_ScheduleMeetingForm> createState() =>
      _ScheduleMeetingFormState();
}

class _ScheduleMeetingFormState extends ConsumerState<_ScheduleMeetingForm> {
  final _key = Object();
  final _title = TextEditingController();
  final _url = TextEditingController();
  final _duration = TextEditingController(text: '60');
  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    _duration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(_savingMeetingProvider(_key));
    final date = ref.watch(_meetingDateProvider(_key));
    final course = ref.watch(_meetingCourseProvider(_key));
    final courses = ref.watch(teacherControllerProvider);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24.w,
        24.h,
        24.w,
        24.h + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Schedule class', style: AppTextStyles.interBold24),
          SizedBox(height: 16.h),
          courses.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => TextButton(
              onPressed: () => ref.invalidate(teacherControllerProvider),
              child: const Text('Retry courses'),
            ),
            data: (state) => DropdownButtonFormField<String>(
              initialValue: course,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Course'),
              items: state.courses
                  .map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.title, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: saving
                  ? null
                  : (v) =>
                        ref.read(_meetingCourseProvider(_key).notifier).state =
                            v,
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            onTapOutside: dismissKeyboardOnTapOutside,
            controller: _title,
            textInputAction: TextInputAction.next,
            maxLength: 200,
            decoration: const InputDecoration(labelText: 'Class title'),
          ),
          SizedBox(height: 12.h),
          TextField(
            onTapOutside: dismissKeyboardOnTapOutside,
            controller: _url,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(labelText: 'HTTPS meeting link'),
          ),
          SizedBox(height: 12.h),
          TextField(
            onTapOutside: dismissKeyboardOnTapOutside,
            controller: _duration,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Duration (minutes)'),
          ),
          SizedBox(height: 12.h),
          OutlinedButton.icon(
            icon: const Icon(Icons.event),
            label: Text(
              date == null
                  ? 'Select date and time'
                  : '${MaterialLocalizations.of(context).formatMediumDate(date)}, ${TimeOfDay.fromDateTime(date).format(context)}',
            ),
            onPressed: saving
                ? null
                : () async {
                    final now = DateTime.now();
                    final day = await showDatePicker(
                      context: context,
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 365)),
                      initialDate: date ?? now,
                    );
                    if (day == null || !context.mounted) return;
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(date ?? now),
                    );
                    if (time != null && mounted) {
                      ref
                          .read(_meetingDateProvider(_key).notifier)
                          .state = DateTime(
                        day.year,
                        day.month,
                        day.day,
                        time.hour,
                        time.minute,
                      );
                    }
                  },
          ),
          SizedBox(height: 20.h),
          FilledButton(
            onPressed: saving || course == null || date == null
                ? null
                : () async {
                    ref.read(_savingMeetingProvider(_key).notifier).state =
                        true;
                    try {
                      await ref
                          .read(liveSessionRepositoryProvider)
                          .schedule(
                            courseId: course,
                            title: _title.text,
                            url: _url.text,
                            startsAt: date,
                            minutes: int.tryParse(_duration.text) ?? 0,
                          );
                      if (!context.mounted) return;
                      ref.invalidate(liveMeetingsProvider);
                      CustomToast.showSuccess(
                        context,
                        message: 'Live class scheduled.',
                      );
                      context.pop();
                    } catch (error) {
                      if (context.mounted) {
                        CustomToast.showError(
                          context,
                          message: error is ArgumentError
                              ? error.message.toString()
                              : 'Could not schedule class. Please retry.',
                        );
                      }
                    } finally {
                      if (mounted) {
                        ref.read(_savingMeetingProvider(_key).notifier).state =
                            false;
                      }
                    }
                  },
            child: Text(saving ? 'Saving...' : 'Schedule class'),
          ),
        ],
      ),
    );
  }
}
