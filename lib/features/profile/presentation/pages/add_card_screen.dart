import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';

final saveCardProvider = StateProvider.autoDispose<bool>((ref) => true);
final cardTypeProvider = StateProvider.autoDispose<String>((ref) => 'unknown');

class AddCardScreen extends ConsumerStatefulWidget {
  const AddCardScreen({super.key});

  @override
  ConsumerState<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends ConsumerState<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardholderNameController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();

  AutovalidateMode _cardNumberAutoValidate = AutovalidateMode.disabled;
  AutovalidateMode _expiryAutoValidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardholderNameController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  String _getCardType(String number) {
    final cleanNumber = number.replaceAll(RegExp(r'\s+|-'), '');
    if (cleanNumber.isEmpty) return 'unknown';
    
    if (cleanNumber.startsWith('4')) {
      return 'visa';
    } else if (cleanNumber.length >= 2) {
      final prefix2 = int.tryParse(cleanNumber.substring(0, 2));
      if (prefix2 != null && prefix2 >= 51 && prefix2 <= 55) {
        return 'mastercard';
      }
    }
    if (cleanNumber.length >= 4) {
      final prefix4 = int.tryParse(cleanNumber.substring(0, 4));
      if (prefix4 != null && prefix4 >= 2221 && prefix4 <= 2720) {
        return 'mastercard';
      }
    }
    return 'unknown';
  }

  void _onSaveCard() {
    if (_formKey.currentState!.validate()) {
      CustomToast.show(
        context, 
        message: 'Card added successfully', 
        icon: Icons.check_circle_outline,
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final saveCard = ref.watch(saveCardProvider);
    final cardType = ref.watch(cardTypeProvider);

    Widget? cardSuffixIcon;
    if (cardType == 'visa') {
      cardSuffixIcon = Padding(
        padding: EdgeInsets.only(right: 16.w, top: 12.h, bottom: 12.h),
        child: _buildVisaIconSmall(),
      );
    } else if (cardType == 'mastercard') {
      cardSuffixIcon = Padding(
        padding: EdgeInsets.only(right: 16.w, top: 12.h, bottom: 12.h),
        child: _buildMastercardIconSmall(),
      );
    }

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
          'Add Card',
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
                Text(
                  'Enter Card Details',
                  style: AppTextStyles.interBold30.copyWith(
                    fontSize: 24.sp,
                    color: AppColors.onBackground,
                  ),
                ),
                SizedBox(height: 24.h),
                
                _buildFieldLabel('Card Number'),
                SizedBox(height: 8.h),
                CustomTextFormField(
                  controller: _cardNumberController,
                  hintText: '0000 0000 0000 0000',
                  fillColor: const Color(0xFFF8F9FA),
                  borderColor: const Color(0xFFE2E8F0),
                  keyboardType: TextInputType.number,
                  autovalidateMode: _cardNumberAutoValidate,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                    _CardNumberFormatter(),
                  ],
                  suffixIcon: cardSuffixIcon,
                  onChanged: (val) {
                    final type = _getCardType(val);
                    if (ref.read(cardTypeProvider) != type) {
                      ref.read(cardTypeProvider.notifier).state = type;
                    }
                    final cleanNumber = val.replaceAll(RegExp(r'\s+|-'), '');
                    if (cleanNumber.length == 16 && _cardNumberAutoValidate != AutovalidateMode.always) {
                      setState(() {
                        _cardNumberAutoValidate = AutovalidateMode.always;
                      });
                    }
                  },
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Card number is required';
                    final cleanNumber = val.replaceAll(RegExp(r'\s+|-'), '');
                    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
                      return 'Invalid card number length';
                    }
                    if (int.tryParse(cleanNumber) == null) {
                      return 'Must contain only digits';
                    }
                    if (_getCardType(val) == 'unknown') {
                      return 'Only Visa and Mastercard are supported';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                
                _buildFieldLabel('Cardholder Name'),
                SizedBox(height: 8.h),
                CustomTextFormField(
                  controller: _cardholderNameController,
                  hintText: 'e.g. Ahmed Ali',
                  fillColor: const Color(0xFFF8F9FA),
                  borderColor: const Color(0xFFE2E8F0),
                  keyboardType: TextInputType.name,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                  ],
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Cardholder name is required';
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Expiry Date'),
                          SizedBox(height: 8.h),
                          CustomTextFormField(
                            controller: _expiryDateController,
                            hintText: 'MM/YY',
                            fillColor: const Color(0xFFF8F9FA),
                            borderColor: const Color(0xFFE2E8F0),
                            keyboardType: TextInputType.datetime,
                            autovalidateMode: _expiryAutoValidate,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                              _ExpiryDateFormatter(),
                            ],
                            onChanged: (val) {
                              if (val.length == 5 && _expiryAutoValidate != AutovalidateMode.always) {
                                setState(() {
                                  _expiryAutoValidate = AutovalidateMode.always;
                                });
                              }
                            },
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Required';
                              final regex = RegExp(r'^(0[1-9]|1[0-2])\/?([0-9]{2}|[0-9]{4})$');
                              if (!regex.hasMatch(val)) return 'Invalid format';
                              
                              if (val.length == 5) {
                                final parts = val.split('/');
                                final month = int.tryParse(parts[0]);
                                final yearPart = int.tryParse(parts[1]);
                                
                                if (month != null && yearPart != null) {
                                  final now = DateTime.now();
                                  final currentYear = now.year % 100;
                                  final currentMonth = now.month;
                                  
                                  if (yearPart < currentYear || (yearPart == currentYear && month < currentMonth)) {
                                    return 'Card expired';
                                  }
                                }
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('CVV'),
                          SizedBox(height: 8.h),
                          CustomTextFormField(
                            controller: _cvvController,
                            hintText: '123',
                            fillColor: const Color(0xFFF8F9FA),
                            borderColor: const Color(0xFFE2E8F0),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            suffixIcon: Icon(Icons.help_outline, color: AppColors.grey500, size: 20.w),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Required';
                              if (val.length != 3) return 'Invalid CVV';
                              if (int.tryParse(val) == null) return 'Only digits';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24.w,
                      height: 24.w,
                      child: Checkbox(
                        value: saveCard,
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(saveCardProvider.notifier).state = val;
                          }
                        },
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        side: BorderSide(color: AppColors.grey300, width: 1.w),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Save this card for future payments. Your card information is encrypted and secure.',
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
          text: 'Save Card',
          onPressed: _onSaveCard, 
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

  Widget _buildVisaIconSmall() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(50.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'VISA',
            style: TextStyle(
              color: const Color(0xFF1A1F71),
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              fontSize: 10.sp,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMastercardIconSmall() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(50.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: const BoxDecoration(
              color: Color(0xFFEB001B),
              shape: BoxShape.circle,
            ),
          ),
          Transform.translate(
            offset: Offset(-4.w, 0),
            child: Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: const Color(0xFFF79E1B).withOpacity(0.9),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
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
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length));
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
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
      if (nonZeroIndex == 2 && nonZeroIndex != text.length) {
        buffer.write('/');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length));
  }
}
