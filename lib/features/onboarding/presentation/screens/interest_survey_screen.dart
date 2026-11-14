import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/onboarding/data/learning_preferences_repository.dart';
import 'package:nts_psc_app/features/onboarding/domain/learning_preferences.dart';
import 'package:nts_psc_app/presentation/widgets/app_choice_chip.dart';
import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';

class InterestSurveyScreen extends ConsumerStatefulWidget {
  const InterestSurveyScreen({
    super.key,
    required this.owner,
    required this.initial,
    this.onboarding = false,
  });
  final String owner;
  final LearningPreferences initial;
  final bool onboarding;

  @override
  ConsumerState<InterestSurveyScreen> createState() =>
      _InterestSurveyScreenState();
}

class _InterestSurveyScreenState extends ConsumerState<InterestSurveyScreen> {
  late final _categories = widget.initial.categories.toSet();
  late final _interests = widget.initial.interests.toSet();
  late final _skills = widget.initial.skills.toSet();
  late final _addedSkills = widget.initial.skills.toSet();
  final _autoSkills = <String>{};
  bool _saving = false;
  String? _error;

  Set<String> get _availableSkills => {
    ...LearningPreferences.defaultSkills,
    ...LearningPreferences.suggestedSkills(_interests),
    ..._addedSkills,
    ..._skills,
  };

  void _pruneSuggestions() {
    final relevant = LearningPreferences.suggestedSkills(_interests).toSet();
    _skills.removeWhere(
      (skill) => _autoSkills.contains(skill) && !relevant.contains(skill),
    );
    _autoSkills.removeWhere((skill) => !relevant.contains(skill));
  }

  Future<void> _save() async {
    if (_saving) return;
    final preferences = LearningPreferences(
      categories: _categories.toList(),
      interests: _interests.toList(),
      skills: _skills.toList(),
    );
    try {
      preferences.validate();
    } on FormatException catch (error) {
      setState(() => _error = error.message);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(learningPreferencesRepositoryProvider)
          .save(widget.owner, preferences);
      if (!mounted ||
          ref.read(authControllerProvider).value?.user?.id != widget.owner) {
        return;
      }
      ref.invalidate(learningPreferencesProvider(widget.owner));
      if (!widget.onboarding) context.pop();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not save your interests. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addSkills() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => _SkillPicker(
        initial: _skills,
        suggestions: _availableSkills.toList(),
      ),
    );
    if (mounted && result != null) {
      setState(() {
        _skills.clear();
        _skills.addAll(result);
        _addedSkills.addAll(result);
        _autoSkills.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !widget.onboarding && !_saving,
    child: AppScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.onboarding,
        title: Text(
          widget.onboarding ? 'Your interests' : 'Learning preferences',
          style: AppTextStyles.interSemiBold16.copyWith(fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'What would you like to learn?',
              style: AppTextStyles.interBold24,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose your categories and interests to personalize course recommendations.',
              style: AppTextStyles.interRegular14,
            ),
            const SizedBox(height: 24),
            Text('Categories', style: AppTextStyles.interSemiBold16),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in LearningPreferences.interestOptions.keys)
                  AppChoiceChip(
                    label: Text(category),
                    labelStyle: AppTextStyles.interRegular14,
                    selected: _categories.contains(category),
                    onSelected: _saving
                        ? null
                        : (value) => setState(() {
                            if (value) {
                              _categories.add(category);
                            } else {
                              _categories.remove(category);
                              final allowed = {
                                for (final item in _categories)
                                  ...LearningPreferences.interestOptions[item]!,
                              };
                              _interests.removeWhere(
                                (item) => !allowed.contains(item),
                              );
                              _pruneSuggestions();
                            }
                          }),
                  ),
              ],
            ),
            if (_categories.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Interests', style: AppTextStyles.interSemiBold16),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final interest in {
                    for (final category in _categories)
                      ...LearningPreferences.interestOptions[category]!,
                  })
                    AppChoiceChip(
                      label: Text(interest),
                      labelStyle: AppTextStyles.interRegular14,
                      selected: _interests.contains(interest),
                      onSelected: _saving
                          ? null
                          : (value) => setState(() {
                              if (value) {
                                _interests.add(interest);
                                for (final skill
                                    in LearningPreferences.suggestedSkills([
                                      interest,
                                    ]).take(2)) {
                                  if (_skills.length < 30 &&
                                      _skills.add(skill)) {
                                    _autoSkills.add(skill);
                                  }
                                }
                              } else {
                                _interests.remove(interest);
                                _pruneSuggestions();
                              }
                            }),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text('Skills', style: AppTextStyles.interSemiBold16),
                ),
                TextButton.icon(
                  onPressed: _saving ? null : _addSkills,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            Text(
              'Select your skills. Suggestions also reflect your interests.',
              style: AppTextStyles.interRegular14,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final skill in _availableSkills)
                  AppChoiceChip(
                    label: Text(skill),
                    labelStyle: AppTextStyles.interRegular14,
                    selected: _skills.contains(skill),
                    onSelected: _saving
                        ? null
                        : (selected) => setState(() {
                            if (selected && _skills.length >= 30) {
                              _error = 'You can add up to 30 skills.';
                              return;
                            }
                            _autoSkills.remove(skill);
                            if (selected) {
                              _skills.add(skill);
                            } else {
                              _skills.remove(skill);
                            }
                          }),
                  ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 32),
            IgnorePointer(
              ignoring: _saving,
              child: CustomButton(
                text: _saving
                    ? 'Saving…'
                    : widget.onboarding
                    ? 'Continue'
                    : 'Save preferences',
                height: 52,
                onPressed: _save,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}

class _SkillPicker extends StatefulWidget {
  const _SkillPicker({required this.initial, required this.suggestions});
  final Set<String> initial;
  final List<String> suggestions;

  @override
  State<_SkillPicker> createState() => _SkillPickerState();
}

class _SkillPickerState extends State<_SkillPicker> {
  final _controller = TextEditingController();
  late final _selected = {...widget.initial};
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String>? _values() {
    final values = LearningPreferences.clean([..._selected, _controller.text]);
    if (values.length > 30 || values.any((value) => value.length > 60)) {
      setState(
        () => _error = 'Add up to 30 skills, with at most 60 characters each.',
      );
      return null;
    }
    return values;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add skills',
              style: AppTextStyles.interSemiBold16.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final skill in {...widget.suggestions, ..._selected})
                  AppChoiceChip(
                    label: Text(skill),
                    labelStyle: AppTextStyles.interRegular14,
                    selected: _selected.contains(skill),
                    onSelected: (value) => setState(() {
                      if (!value) {
                        _selected.remove(skill);
                      } else if (_selected.length < 30) {
                        _selected.add(skill);
                      } else {
                        _error = 'You can add up to 30 skills.';
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLength: 60,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Another skill',
                hintText: 'e.g. Essay Writing',
                errorText: _error,
              ),
              onSubmitted: (_) {
                final values = _values();
                if (values == null) return;
                setState(() {
                  _selected.clear();
                  _selected.addAll(values);
                  _controller.clear();
                  _error = null;
                });
              },
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Add skills',
              height: 52,
              onPressed: () {
                final values = _values();
                if (values != null) Navigator.of(context).pop(values);
              },
            ),
          ],
        ),
      ),
    ),
  );
}
