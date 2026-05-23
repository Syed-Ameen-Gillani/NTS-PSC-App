import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';

enum WalletType { easypaisa, jazzcash }

class AddWalletScreen extends ConsumerStatefulWidget {
  final WalletType walletType;

  const AddWalletScreen({super.key, required this.walletType});

  @override
  ConsumerState<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends ConsumerState<AddWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _nameController = TextEditingController();

  AutovalidateMode _mobileAutoValidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    _mobileController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onConnectWallet() {
    if (_formKey.currentState!.validate()) {
      CustomToast.show(
        context,
        message: 'Wallet connected successfully',
        icon: Icons.check_circle_outline,
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEasypaisa = widget.walletType == WalletType.easypaisa;
    final brandName = isEasypaisa ? 'Easypaisa' : 'JazzCash';
    final brandColor = isEasypaisa ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final lightBrandColor = isEasypaisa ? const Color(0xFFEFFFF6) : const Color(0xFFFFF4E5);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.onBackground, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Add $brandName',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 20.sp,
            color: AppColors.onBackground,
          ),
        ),
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(
            color: const Color(0xFFE2E8F0),
            height: 1.h,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: lightBrandColor,
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48.w,
                        height: 48.w,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.phone_android, color: brandColor, size: 24.w),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Link $brandName Account',
                              style: AppTextStyles.interBold24.copyWith(
                                fontSize: 16.sp,
                                color: AppColors.onBackground,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Enter your registered mobile number.',
                              style: AppTextStyles.interRegular14.copyWith(
                                fontSize: 12.sp,
                                color: AppColors.grey500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),
                
                _buildFieldLabel('Mobile Number'),
                SizedBox(height: 8.h),
                CustomTextFormField(
                  controller: _mobileController,
                  hintText: '03XX XXXXXXX',
                  fillColor: const Color(0xFFF8F9FA),
                  borderColor: const Color(0xFFE2E8F0),
                  keyboardType: TextInputType.phone,
                  autovalidateMode: _mobileAutoValidate,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                    _MobileNumberFormatter(),
                  ],
                  onChanged: (val) {
                    final cleanNumber = val.replaceAll(' ', '');
                    if (cleanNumber.length == 11 && _mobileAutoValidate != AutovalidateMode.always) {
                      setState(() {
                        _mobileAutoValidate = AutovalidateMode.always;
                      });
                    }
                  },
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Mobile number is required';
                    final cleanNumber = val.replaceAll(' ', '');
                    if (cleanNumber.length != 11) return 'Must be exactly 11 digits long';
                    if (!cleanNumber.startsWith('03')) return 'Must start with 03';
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                
                _buildFieldLabel('Account Holder Name'),
                SizedBox(height: 8.h),
                CustomTextFormField(
                  controller: _nameController,
                  hintText: 'e.g. Ahmed Ali',
                  prefixIcon: Icons.person_outline,
                  fillColor: const Color(0xFFF8F9FA),
                  borderColor: const Color(0xFFE2E8F0),
                  keyboardType: TextInputType.name,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                  ],
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Account holder name is required';
                    return null;
                  },
                ),
                SizedBox(height: 24.h),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppColors.grey500, size: 20.w),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'You will receive a prompt on your $brandName app to authorize this connection. Make sure your app is installed and active.',
                        style: AppTextStyles.interRegular14.copyWith(
                          color: AppColors.grey500,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(24.w).copyWith(
          bottom: 24.h + MediaQuery.of(context).padding.bottom,
        ),
        child: CustomButton(
          text: 'Send Link Request',
          onPressed: _onConnectWallet, 
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.interMedium16.copyWith(
        fontSize: 14.sp,
        color: AppColors.onBackground,
      ),
    );
  }
}

class _MobileNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex == 4 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length));
  }
}
