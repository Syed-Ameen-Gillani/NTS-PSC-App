class OnboardingContent {
  final String imageAsset;
  final String title;
  final String description;

  const OnboardingContent({
    required this.imageAsset,
    required this.title,
    required this.description,
  });
}

const List<OnboardingContent> onboardingData = [
  //  Style 1 Slides (White Container)
  OnboardingContent(
    imageAsset: 'assets/images/onboarding_1.png',
    title: 'Learn Online From Your Home',
    description:
        'Amet minim mollit non deserunt ullamco est sit aliqua dolor do amet sint. Velit officia consequat duis enim velit mollit.',
  ),
  OnboardingContent(
    imageAsset: 'assets/images/onboarding_2.png',
    title: 'The Best Platform For Online Learning',
    description:
        'Amet minim mollit non deserunt ullamco est sit aliqua dolor do amet sint. Velit officia consequat duis enim velit mollit.',
  ),

  // Style 2 Slides (Full Background, Skip Button, Different Layout)
  OnboardingContent(
    imageAsset: 'assets/images/onboarding_3.png',
    title: 'Numerous free trial courses',
    description: 'Free courses for you to find your way to learning',
  ),
  OnboardingContent(
    imageAsset: 'assets/images/onboarding_4.png',
    title: 'Quick and easy learning',
    description:
        'Easy and fast learning at any time to help you improve various skills',
  ),
  // Style 2, but with custom buttons (handled by index in main screen)
  OnboardingContent(
    imageAsset: 'assets/images/onboarding_5.png',
    title: 'Create your own study plan',
    description:
        'Study according to the study plan, make study more motivated.',
  ),
];
