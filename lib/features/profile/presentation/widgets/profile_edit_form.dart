import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/services/app_image_picker_service.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/core/utils/app_image_provider.dart';
import 'package:nts_psc_app/core/utils/form_validators.dart';
import 'package:nts_psc_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';
import 'package:nts_psc_app/presentation/widgets/app_avatar.dart';

class ProfileEditForm extends ConsumerStatefulWidget {
  final UserModel user;
  final bool isTeacher;

  const ProfileEditForm({
    super.key,
    required this.user,
    required this.isTeacher,
  });

  @override
  ConsumerState<ProfileEditForm> createState() => _ProfileEditFormState();
}

class _ProfileEditFormState extends ConsumerState<ProfileEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _location;
  late final TextEditingController _subject;
  late final TextEditingController _qualification;
  late final TextEditingController _bio;
  final _phoneFocus = FocusNode();
  final _locationFocus = FocusNode();
  final _subjectFocus = FocusNode();
  final _qualificationFocus = FocusNode();
  final _bioFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.name);
    _email = TextEditingController(text: widget.user.email);
    _phone = TextEditingController(text: widget.user.phone ?? '');
    _location = TextEditingController(text: widget.user.location ?? '');
    _subject = TextEditingController(text: widget.user.subject ?? '');
    _qualification = TextEditingController(
      text: widget.user.qualification ?? '',
    );
    _bio = TextEditingController(text: widget.user.bio ?? '');
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _email,
      _phone,
      _location,
      _subject,
      _qualification,
      _bio,
    ]) {
      controller.dispose();
    }
    for (final focus in [
      _phoneFocus,
      _locationFocus,
      _subjectFocus,
      _qualificationFocus,
      _bioFocus,
    ]) {
      focus.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final saving = ref.read(editProfileSavingProvider);
    if (saving || !_formKey.currentState!.validate()) return;
    ref.read(editProfileSavingProvider.notifier).state = true;
    var saved = false;
    try {
      await ref
          .read(profileControllerProvider.notifier)
          .updateProfile(
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            location: _location.text.trim(),
            avatarBytes: ref.read(pendingProfilePhotoProvider(widget.user.id)),
            subject: widget.isTeacher ? _subject.text.trim() : null,
            qualification: widget.isTeacher ? _qualification.text.trim() : null,
            bio: widget.isTeacher ? _bio.text.trim() : null,
          );
      if (!mounted) return;
      CustomToast.showSuccess(context, message: 'Profile updated successfully');
      saved = true;
    } catch (error) {
      if (mounted) {
        CustomToast.showError(
          context,
          message: error is ArgumentError
              ? error.message.toString()
              : 'Could not update profile',
        );
      }
    } finally {
      if (mounted) {
        ref.read(editProfileSavingProvider.notifier).state = false;
      }
    }
    if (saved && mounted) {
      context.pop();
    }
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final image = await ref
          .read(appImagePickerServiceProvider)
          .pickAndCrop(
            context: context,
            preset: AppImageCropPreset.profilePhoto,
          );
      if (image == null || !mounted) return;
      ref.read(pendingProfilePhotoProvider(widget.user.id).notifier).state =
          image.bytes;
    } catch (error) {
      if (!mounted) return;
      CustomToast.showError(
        context,
        message: error is ArgumentError
            ? error.message.toString()
            : 'Could not open that image. Try another file.',
      );
    }
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    Widget? suffixIcon,
    bool readOnly = false,
    FocusNode? focusNode,
    ValueChanged<String>? onFieldSubmitted,
    TextInputAction? textInputAction,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.interSemiBold16.copyWith(
              fontSize: 14.sp,
              color: AppColors.grey900,
            ),
          ),
          SizedBox(height: 8.h),
          CustomTextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            maxLines: maxLines,
            suffixIcon: suffixIcon,
            readOnly: readOnly,
            focusNode: focusNode,
            onFieldSubmitted: onFieldSubmitted,
            fillColor: readOnly ? AppColors.grey200 : null,
            textInputAction:
                textInputAction ??
                (maxLines > 1 ? TextInputAction.newline : TextInputAction.next),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedPhoto = ref.watch(
      pendingProfilePhotoProvider(widget.user.id),
    );
    final ImageProvider<Object>? photoProvider = selectedPhoto != null
        ? MemoryImage(selectedPhoto)
        : widget.user.imagePath.trim().isEmpty
        ? null
        : appImageProvider(widget.user.imagePath);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AppAvatar(
                              size: 96.w,
                              imageProvider: photoProvider,
                              name: widget.user.name,
                            ),
                            Positioned(
                              right: -2.w,
                              bottom: -2.h,
                              child: Material(
                                color: AppColors.primary,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: _pickProfilePhoto,
                                  child: SizedBox.square(
                                    dimension: 34.w,
                                    child: Icon(
                                      Icons.camera_alt_outlined,
                                      size: 18.w,
                                      color: AppColors.onPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        // SizedBox(height: 10.h),
                        // TextButton(
                        //   onPressed: _pickProfilePhoto,
                        //   child: const Text('Change profile photo'),
                        // ),
                        // Text(
                        //   'JPEG, PNG or WebP up to 5 MB',
                        //   style: AppTextStyles.interRegular14.copyWith(
                        //     fontSize: 11.sp,
                        //     color: AppColors.grey500,
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                  SizedBox(height: 28.h),
                  _field(
                    'Full Name',
                    _name,
                    onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
                    validator: FormValidators.validateName,
                  ),
                  _field(
                    'Email Address',
                    _email,
                    keyboardType: TextInputType.emailAddress,
                    readOnly: true,
                    suffixIcon: Icon(
                      Icons.lock_outline,
                      color: AppColors.grey400,
                      size: 20.w,
                    ),
                  ),
                  _field(
                    'Phone Number',
                    _phone,
                    focusNode: _phoneFocus,
                    onFieldSubmitted: (_) => _locationFocus.requestFocus(),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      if (!RegExp(
                        r'^[+0-9 ()-]{7,20}$',
                      ).hasMatch(value.trim())) {
                        return 'Enter a valid phone number';
                      }
                      return null;
                    },
                    suffixIcon: Icon(
                      Icons.phone_outlined,
                      color: AppColors.grey400,
                      size: 20.w,
                    ),
                  ),
                  _field(
                    'Location',
                    _location,
                    focusNode: _locationFocus,
                    textInputAction: widget.isTeacher
                        ? TextInputAction.next
                        : TextInputAction.done,
                    onFieldSubmitted: widget.isTeacher
                        ? (_) => _subjectFocus.requestFocus()
                        : null,
                    suffixIcon: Icon(
                      Icons.location_on_outlined,
                      color: AppColors.grey400,
                      size: 20.w,
                    ),
                  ),
                  if (widget.isTeacher) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'TEACHING DETAILS',
                      style: AppTextStyles.interSemiBold16.copyWith(
                        fontSize: 12.sp,
                        color: AppColors.grey500,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _field(
                      'Subject / Specialization',
                      _subject,
                      focusNode: _subjectFocus,
                      onFieldSubmitted: (_) =>
                          _qualificationFocus.requestFocus(),
                    ),
                    _field(
                      'Qualification',
                      _qualification,
                      focusNode: _qualificationFocus,
                      onFieldSubmitted: (_) => _bioFocus.requestFocus(),
                    ),
                    _field('Bio', _bio, maxLines: 4, focusNode: _bioFocus),
                  ],
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 16.h),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(
              top: BorderSide(color: AppColors.grey300, width: 1.h),
            ),
          ),
          child: CustomButton(
            text: 'Save Changes',
            color: AppColors.primary,
            height: 56.h,
            borderRadius: 16.r,
            onPressed: _save,
          ),
        ),
      ],
    );
  }
}
