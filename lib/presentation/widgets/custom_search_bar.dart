import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/core/utils/keyboard_dismissal.dart';

TextStyle get _searchTextStyle => AppTextStyles.interRegular16.copyWith(
  fontSize: 14.sp,
  height: 1.4,
  color: AppColors.grey600,
);

/// One visual shell for both the Discover shortcut and editable searches.
/// InputDecorator must not add a second border, fill or icon/text inset.
class _SearchSurface extends StatelessWidget {
  const _SearchSurface({required this.child, this.trailing});
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final extra = MediaQuery.textScalerOf(context).scale(14.sp) - 14.sp;
    return Container(
      height: 52.h + (extra > 0 ? extra : 0),
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.grey300, width: 1.w),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: AppColors.grey600, size: 24.w),
          SizedBox(width: 8.w),
          Expanded(child: child),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class CustomSearchBar extends StatelessWidget {
  const CustomSearchBar({super.key, this.includePadding = true});
  final bool includePadding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: includePadding ? 24.w : 0),
    child: InkWell(
      onTap: () => context.pushNamed(AppRoute.courseSearch.name),
      borderRadius: BorderRadius.circular(8.r),
      child: _SearchSurface(
        child: Text(
          'Search courses, exams...',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _searchTextStyle,
        ),
      ),
    ),
  );
}

/// Editable search field that uses the same surface as the student home search.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    required this.onChanged,
    this.hintText = 'Search',
    this.initialValue = '',
    this.autofocus = false,
    this.controller,
  });

  final ValueChanged<String> onChanged;
  final String hintText;
  final String initialValue;
  final bool autofocus;
  final TextEditingController? controller;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller;
  final _focus = FocusNode();
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<TextEditingValue>(
    valueListenable: _controller,
    builder: (context, value, _) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _focus.requestFocus,
      child: _SearchSurface(
        trailing: value.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(width: 32.w, height: 32.w),
                icon: Icon(Icons.close, color: AppColors.grey600, size: 20.w),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                },
              ),
        child: TextField(
          focusNode: _focus,
          controller: _controller,
          autofocus: widget.autofocus,
          onTapOutside: dismissKeyboardOnTapOutside,
          onChanged: widget.onChanged,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
          textAlignVertical: TextAlignVertical.center,
          style: _searchTextStyle,
          decoration: InputDecoration(
            isCollapsed: true,
            contentPadding: EdgeInsets.zero,
            hintText: widget.hintText,
            hintStyle: _searchTextStyle,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
          ),
        ),
      ),
    ),
  );
}

/// Backwards-compatible course-search name.
class CourseSearchField extends AppSearchField {
  const CourseSearchField({
    super.key,
    required super.onChanged,
    super.hintText = 'Search courses',
    super.initialValue,
    super.autofocus,
    super.controller,
  });
}
