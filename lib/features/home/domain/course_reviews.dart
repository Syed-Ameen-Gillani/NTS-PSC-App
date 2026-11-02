typedef CourseReviewsKey = ({String courseId, int? rating});

class CourseReviewsPage {
  const CourseReviewsPage({
    required this.items,
    required this.count,
    required this.average,
    required this.distribution,
    required this.canReview,
    this.ownReview,
    this.hasMore = false,
    this.loadingMore = false,
    this.error,
  });
  final List<Map<String, dynamic>> items;
  final int count;
  final double average;
  final List<int> distribution;
  final bool canReview;
  final Map<String, dynamic>? ownReview;
  final bool hasMore;
  final bool loadingMore;
  final String? error;
  factory CourseReviewsPage.fromJson(Map<String, dynamic> data) =>
      CourseReviewsPage(
        items: (data['items'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        count: (data['count'] as num).toInt(),
        average: (data['average'] as num).toDouble(),
        distribution: (data['distribution'] as List)
            .map((e) => (e as num).toInt())
            .toList(),
        canReview: data['can_review'] == true,
        ownReview: data['own_review'] == null
            ? null
            : Map<String, dynamic>.from(data['own_review'] as Map),
        hasMore: (data['items'] as List).length == 20,
      );
  CourseReviewsPage withItems(
    List<Map<String, dynamic>> values, {
    bool? more,
    bool loading = false,
    String? error,
  }) => CourseReviewsPage(
    items: values,
    count: count,
    average: average,
    distribution: distribution,
    canReview: canReview,
    ownReview: ownReview,
    hasMore: more ?? hasMore,
    loadingMore: loading,
    error: error,
  );
}
