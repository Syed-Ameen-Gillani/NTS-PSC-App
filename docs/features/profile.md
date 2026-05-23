# Profile Feature Memory

## Overview
The Profile feature in the NTS-PSC-App handles user settings, account management, legal information, and application preferences. It is built using a Clean Architecture, Feature-First approach with Riverpod for state management.

## Screens & Components
1. **ProfileScreen (`profile_screen.dart`)**
   - The main landing page for the profile tab.
   - Contains a header with user avatar, name, and email.
   - Displays a structured list of navigation tiles for: Edit Profile, Payment Methods, Notifications, Security, App Language, About Us.

2. **EditProfileScreen (`edit_profile_screen.dart`)**
   - Allows users to modify their Full Name, Email Address, Phone Number, and Location.
   - Includes an avatar upload UI.
   - Uses `CustomTextFormField` and `CustomButton` with a `CustomSnackBar` for success validation.

3. **Payment Methods (`payment_methods_screen.dart`, `add_card_screen.dart`, `add_wallet_screen.dart`)**
   - **List Screen**: Shows saved Credit/Debit cards (Mastercard, Visa) and Mobile Wallets (Easypaisa, JazzCash). Includes a customized 3-dot dropdown menu to edit or delete methods.
   - **Add Card**: A form with validation for Card Number, Expiry Date (validates against past dates), CVV, and Cardholder Name. Uses `CustomToast` on success.
   - **Add Wallet**: A tabbed view to select between Easypaisa and JazzCash, requiring phone number input. Uses `CustomToast` on success.

4. **Account Settings (`account_settings_screen.dart`)**
   - Grouped list of settings separated into Security, Preferences, and Privacy & Data.
   - Certain sensitive options (like Change Password, 2FA, Theme, Download Data) are currently hidden/commented out based on product requirements.

5. **Notifications (`notifications_screen.dart`)**
   - Managed via `notifications_provider.dart`.
   - Allows toggling Delivery Methods (Push, Email) and Notification Types (Course Updates, Messages, Exam Results, Promotions) using `CupertinoSwitch`.
   - SMS Notifications are currently disabled/hidden.

6. **Delete Account (`delete_account_screen.dart`)**
   - A destructive, permanent action flow.
   - Requires users to explicitly type "DELETE" into a text field to enable the final confirmation button.
   - Uses `CustomConfirmationDialog` and triggers a `CustomToast` upon successful deletion.

7. **About Us & Legal (`about_us_screen.dart`, `terms_of_service_screen.dart`, `privacy_policy_screen.dart`, `rate_app_screen.dart`)**
   - **About Us**: Displays app version and links to sub-screens.
   - **Terms & Privacy**: Static, cleanly formatted typography screens detailing legal agreements, ending with "Contact Us" cards.
   - **Rate App**: Interactive 5-star rating system with a multiline feedback field. Triggers a custom error SnackBar if submitted without a rating, and animates into a success state upon completion.

## Design & UI Rules Followed
- **Responsiveness**: Everything is wrapped in `SafeArea` and utilizes `flutter_screenutil` (`.w`, `.h`, `.sp`, `.r`).
- **Theming**: Consistently applies `AppColors` and typography from `AppTextStyles` (Inter font family).
- **Feedback**: Standardized error/success states using `CustomSnackBar` and `CustomToast`.
