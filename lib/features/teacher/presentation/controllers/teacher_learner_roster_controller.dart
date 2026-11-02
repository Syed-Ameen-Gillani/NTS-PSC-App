import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/teacher/data/teacher_insights_repository_provider.dart';
import 'package:nts_psc_app/features/teacher/domain/models/teacher_insights_models.dart';

const teacherLearnerPageSize = 50;

class TeacherLearnerRosterState {
  const TeacherLearnerRosterState({
    this.items = const [],
    this.query = '',
    this.courseId,
    this.hasMore = false,
    this.isFiltering = false,
    this.filterFailed = false,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<TeacherLearnerEnrollment> items;
  final String query;
  final String? courseId;
  final bool hasMore;
  final bool isFiltering;
  final bool filterFailed;
  final bool isLoadingMore;
  final bool loadMoreFailed;
}

final teacherLearnerRosterProvider =
    AsyncNotifierProvider.autoDispose<
      TeacherLearnerRosterController,
      TeacherLearnerRosterState
    >(TeacherLearnerRosterController.new);

class TeacherLearnerRosterController
    extends AsyncNotifier<TeacherLearnerRosterState> {
  int _requestVersion = 0;

  @override
  Future<TeacherLearnerRosterState> build() async {
    final userId = ref.watch(
      authControllerProvider.select((value) => value.value?.user?.id),
    );
    if (userId == null) return const TeacherLearnerRosterState();
    return _firstPage('', null);
  }

  Future<TeacherLearnerRosterState> _firstPage(
    String query,
    String? courseId,
  ) async {
    final items = await ref
        .read(teacherInsightsRepositoryProvider)
        .getLearnerRoster(
          limit: teacherLearnerPageSize,
          offset: 0,
          query: query.isEmpty ? null : query,
          courseId: courseId,
        );
    return TeacherLearnerRosterState(
      items: items,
      query: query,
      courseId: courseId,
      hasMore: items.length == teacherLearnerPageSize,
    );
  }

  Future<void> setFilters({required String query, String? courseId}) async {
    final normalized = query.trim();
    final current = state.value;
    if (current != null &&
        current.query == normalized &&
        current.courseId == courseId &&
        !current.filterFailed) {
      return;
    }
    final version = ++_requestVersion;
    state = AsyncData(
      TeacherLearnerRosterState(
        query: normalized,
        courseId: courseId,
        isFiltering: true,
      ),
    );
    try {
      final next = await _firstPage(normalized, courseId);
      if (ref.mounted && version == _requestVersion) {
        state = AsyncData(next);
      }
    } catch (_) {
      if (ref.mounted && version == _requestVersion) {
        state = AsyncData(
          TeacherLearnerRosterState(
            query: normalized,
            courseId: courseId,
            filterFailed: true,
          ),
        );
      }
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    final version = _requestVersion;
    state = AsyncData(
      TeacherLearnerRosterState(
        items: current.items,
        query: current.query,
        courseId: current.courseId,
        hasMore: true,
        isLoadingMore: true,
      ),
    );
    try {
      final page = await ref
          .read(teacherInsightsRepositoryProvider)
          .getLearnerRoster(
            limit: teacherLearnerPageSize,
            offset: current.items.length,
            query: current.query.isEmpty ? null : current.query,
            courseId: current.courseId,
          );
      if (!ref.mounted || version != _requestVersion) return;
      final seen = current.items.map((item) => item.id).toSet();
      state = AsyncData(
        TeacherLearnerRosterState(
          items: [...current.items, ...page.where((item) => seen.add(item.id))],
          query: current.query,
          courseId: current.courseId,
          hasMore: page.length == teacherLearnerPageSize,
        ),
      );
    } catch (_) {
      if (!ref.mounted || version != _requestVersion) return;
      state = AsyncData(
        TeacherLearnerRosterState(
          items: current.items,
          query: current.query,
          courseId: current.courseId,
          hasMore: true,
          loadMoreFailed: true,
        ),
      );
    }
  }
}
