import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:lenslifeapp/widgets/esp32_ble_connection_card.dart';
import 'package:lenslifeapp/services/live_sensor_store.dart';

void main() {
  runApp(const LensLifeApp());
}

class AppAssets {
  static const String logo = 'assets/lenslife_logo.png';
}

class UserAccount {
  final String fullName;
  final String email;
  final String password;

  UserAccount({
    required this.fullName,
    required this.email,
    required this.password,
  });
}

class AuthStore {
  static final Map<String, UserAccount> accounts = {};
}

enum LensType {
  daily,
  biweekly,
  monthly,
}

class LensSettings {
  LensType type;
  int daysUsed;

  LensSettings({
    this.type = LensType.monthly,
    this.daysUsed = 9,
  });

  int get limitDays {
    switch (type) {
      case LensType.daily:
        return 1;
      case LensType.biweekly:
        return 14;
      case LensType.monthly:
        return 30;
    }
  }

  String get typeLabel {
    switch (type) {
      case LensType.daily:
        return 'Daily';
      case LensType.biweekly:
        return 'Biweekly';
      case LensType.monthly:
        return 'Monthly';
    }
  }

  int get daysRemaining => (limitDays - daysUsed).clamp(0, limitDays);

  double get percentUsed => (daysUsed / limitDays).clamp(0.0, 1.0);

  String get replaceText {
    if (daysRemaining == 0) return 'Replace now';
    if (daysRemaining == 1) return '1 day left';
    return '$daysRemaining days left';
  }

  String get lensAgeText => '$daysUsed / $limitDays days';
}

class AppSessionData {
  static final LensSettings lensSettings = LensSettings();

  static final List<double> wearTimeLast30Days = [
    10.2, 11.0, 9.8, 12.1, 10.5, 8.7, 11.4, 10.9, 9.6, 12.3,
    11.2, 10.1, 8.9, 9.7, 11.8, 12.0, 10.6, 9.5, 11.1, 10.8,
    12.4, 9.9, 10.2, 11.7, 10.4, 8.8, 9.4, 11.3, 12.2, 11.2,
  ];
}

enum LensType {
  daily,
  biweekly,
  monthly,
}

class LensSettings {
  LensType type;
  int daysUsed;

  LensSettings({
    this.type = LensType.monthly,
    this.daysUsed = 9,
  });

  int get limitDays {
    switch (type) {
      case LensType.daily:
        return 1;
      case LensType.biweekly:
        return 14;
      case LensType.monthly:
        return 30;
    }
  }

  String get typeLabel {
    switch (type) {
      case LensType.daily:
        return 'Daily';
      case LensType.biweekly:
        return 'Biweekly';
      case LensType.monthly:
        return 'Monthly';
    }
  }

  int get daysRemaining => (limitDays - daysUsed).clamp(0, limitDays);

  double get percentUsed => (daysUsed / limitDays).clamp(0.0, 1.0);

  String get replaceText {
    if (daysRemaining == 0) return 'Replace now';
    if (daysRemaining == 1) return '1 day left';
    return '$daysRemaining days left';
  }

  String get lensAgeText => '$daysUsed / $limitDays days';
}

class SubscriptionPlanSelection {
  final String title;
  final String price;
  final String delivery;
  final DateTime selectedAt;

  SubscriptionPlanSelection({
    required this.title,
    required this.price,
    required this.delivery,
    required this.selectedAt,
  });
}

class BookedAppointment {
  final String providerName;
  final String slot;
  final String specialty;
  final DateTime bookedAt;

  BookedAppointment({
    required this.providerName,
    required this.slot,
    required this.specialty,
    required this.bookedAt,
  });
}

class AppSessionData {
  static final LensSettings lensSettings = LensSettings();

  static SubscriptionPlanSelection? selectedSubscription;
  static BookedAppointment? bookedAppointment;
  static final List<BookedAppointment> appointmentHistory = [];

  static final ValueNotifier<int> cleaningStreakNotifier = ValueNotifier<int>(12);
  static int bestCleaningStreak = 18;

  static final List<String> notifications = [
    'Clean your lenses tonight to keep your streak active.',
    'Lens replacement countdown is based on your current lens setup.',
    'Book an eye care appointment if irritation risk stays elevated.',
  ];

  static final List<double> wearTimeLast30Days = [
    10.2, 11.0, 9.8, 12.1, 10.5, 8.7, 11.4, 10.9, 9.6, 12.3,
    11.2, 10.1, 8.9, 9.7, 11.8, 12.0, 10.6, 9.5, 11.1, 10.8,
    12.4, 9.9, 10.2, 11.7, 10.4, 8.8, 9.4, 11.3, 12.2, 11.2,
  ];
}

class LensLifeApp extends StatelessWidget {
  const LensLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LensLife',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFBFAF7),
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB97812)),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF111111),
          contentTextStyle: TextStyle(color: Colors.white, fontSize: 15),
        ),
      ),
      home: const SplashPage(),
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> fade;
  late final Animation<double> scale;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    fade = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
    scale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
    );
    controller.forward();

    Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: const AuthPage(),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'LensLife welcome screen. Loading the app.',
      liveRegion: true,
      child: Scaffold(
        backgroundColor: const Color(0xFFFBFAF7),
        body: Center(
          child: FadeTransition(
            opacity: fade,
            child: ScaleTransition(
              scale: scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  AppLogo(size: 320),
                  SizedBox(height: 8),
                  Text(
                    'Smarter lens care, clearer routines.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF444444),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 26),
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Color(0xFFB97812),
                      backgroundColor: Color(0xFFE8DED1),
                      semanticsLabel: 'Loading LensLife',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = false;
  bool hidePassword = true;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final nameFocus = FocusNode();
  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();

  String? nameError;
  String? emailError;
  String? passwordError;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    nameFocus.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Semantics(
          liveRegion: true,
          label: message,
          child: Text(message),
        ),
      ),
    );
  }

  bool validateCreateAccount() {
    final name = nameController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text.trim();

    setState(() {
      nameError = null;
      emailError = null;
      passwordError = null;

      if (name.isEmpty) nameError = 'Enter your full name.';

      if (email.isEmpty) {
        emailError = 'Enter your email address.';
      } else if (!email.contains('@') || !email.contains('.')) {
        emailError = 'Enter a valid email address.';
      } else if (AuthStore.accounts.containsKey(email)) {
        emailError = 'This email already has an account. Log in instead.';
      }

      if (password.isEmpty) {
        passwordError = 'Enter a password.';
      } else if (password.length < 4) {
        passwordError = 'Use at least 4 characters.';
      }
    });

    if (nameError != null) {
      nameFocus.requestFocus();
      showMessage('Full name is required.');
      return false;
    }
    if (emailError != null) {
      emailFocus.requestFocus();
      showMessage(emailError!);
      return false;
    }
    if (passwordError != null) {
      passwordFocus.requestFocus();
      showMessage(passwordError!);
      return false;
    }
    return true;
  }

  bool validateLogin() {
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text.trim();

    setState(() {
      emailError = null;
      passwordError = null;
      if (email.isEmpty) emailError = 'Enter your email address.';
      if (password.isEmpty) passwordError = 'Enter your password.';
    });

    if (emailError != null) {
      emailFocus.requestFocus();
      showMessage(emailError!);
      return false;
    }
    if (passwordError != null) {
      passwordFocus.requestFocus();
      showMessage(passwordError!);
      return false;
    }
    return true;
  }

  void createAccount() {
    if (!validateCreateAccount()) return;

    final account = UserAccount(
      fullName: nameController.text.trim(),
      email: emailController.text.trim().toLowerCase(),
      password: passwordController.text.trim(),
    );
    AuthStore.accounts[account.email] = account;
    showMessage('Account created. Opening your LensLife dashboard.');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => DashboardPage(account: account)),
    );
  }

  void login() {
    if (!validateLogin()) return;

    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text.trim();
    final account = AuthStore.accounts[email];

    if (account == null || account.password != password) {
      setState(() {
        emailError = 'Check your email.';
        passwordError = 'Check your password.';
      });
      emailFocus.requestFocus();
      showMessage('Incorrect email or password. Try again or create an account.');
      return;
    }

    showMessage('Login successful. Opening your LensLife dashboard.');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => DashboardPage(account: account)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FocusTraversalGroup(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PremiumLogo(),
                    const SizedBox(height: 26),
                    Text(
                      isLogin ? 'Welcome back' : 'Create account',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.2,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Smarter contact lens care starts here.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isLogin
                          ? 'Log in to monitor your lens health, case readings, and cleaning habits.'
                          : 'Track solution quality, cleaning routines, and lens health insights from one simple dashboard.',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF444444),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFFE8E2D8)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 30,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (!isLogin)
                            AccessibleAuthField(
                              controller: nameController,
                              focusNode: nameFocus,
                              label: 'Full name',
                              hintText: 'Enter your full name',
                              icon: Icons.person_rounded,
                              textInputAction: TextInputAction.next,
                              errorText: nameError,
                            ),
                          if (!isLogin) const SizedBox(height: 12),
                          AccessibleAuthField(
                            controller: emailController,
                            focusNode: emailFocus,
                            label: 'Email',
                            hintText: 'Enter your email address',
                            icon: Icons.email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            errorText: emailError,
                          ),
                          const SizedBox(height: 12),
                          Semantics(
                            label: 'Password input field',
                            textField: true,
                            child: TextField(
                              controller: passwordController,
                              focusNode: passwordFocus,
                              obscureText: hidePassword,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) =>
                                  isLogin ? login() : createAccount(),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_rounded),
                                suffixIcon: IconButton(
                                  tooltip: hidePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  onPressed: () {
                                    setState(() => hidePassword = !hidePassword);
                                  },
                                  icon: Icon(
                                    hidePassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                  ),
                                ),
                                labelText: 'Password',
                                hintText: 'Enter your password',
                                errorText: passwordError,
                                filled: true,
                                fillColor: const Color(0xFFF4F1EB),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF111111),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: Semantics(
                              button: true,
                              label: isLogin
                                  ? 'Log in to LensLife'
                                  : 'Create LensLife account',
                              child: ElevatedButton(
                                onPressed: isLogin ? login : createAccount,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF151515),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  isLogin ? 'Log In' : 'Create Account',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            isLogin = !isLogin;
                            nameError = null;
                            emailError = null;
                            passwordError = null;
                          });
                        },
                        child: Text(
                          isLogin
                              ? "Don't have an account? Create one"
                              : 'Already have an account? Log in',
                          style: const TextStyle(
                            color: Color(0xFF875000),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        'Prototype note: accounts stay saved while the app is running.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF555555),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PremiumLogo extends StatelessWidget {
  const PremiumLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'LensLife logo. Your smart lens-care companion.',
      image: true,
      child: Center(
        child: Column(
          children: [
            AppLogo(size: 250),
            SizedBox(height: 10),
            Text(
              'Your smart lens-care companion.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF444444),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'LensLife logo',
      image: true,
      child: Image.asset(
        AppAssets.logo,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              borderRadius: BorderRadius.circular(size * 0.28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.visibility_rounded,
              color: const Color(0xFFFFC46B),
              size: size * 0.52,
            ),
          );
        },
      ),
    );
  }
}

class AccessibleAuthField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? errorText;

  const AccessibleAuthField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label input field',
      textField: true,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          hintText: hintText,
          errorText: errorText,
          filled: true,
          fillColor: const Color(0xFFF4F1EB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: Color(0xFF111111),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
class DashboardPage extends StatefulWidget {
  final UserAccount account;

  const DashboardPage({super.key, required this.account});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedTab = 0;

  LensSettings get lensSettings => AppSessionData.lensSettings;

  void updateLensSettings(LensType type, int daysUsed) {
    setState(() {
      lensSettings.type = type;
      lensSettings.daysUsed = daysUsed.clamp(0, type == LensType.daily ? 1 : type == LensType.biweekly ? 14 : 30);
    });
  }

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedTab = 0;

  LensSettings get lensSettings => AppSessionData.lensSettings;

  void updateLensSettings(LensType type, int daysUsed) {
    setState(() {
      lensSettings.type = type;
      lensSettings.daysUsed = daysUsed.clamp(0, type == LensType.daily ? 1 : type == LensType.biweekly ? 14 : 30);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      LensDashboardTab(
        account: widget.account,
        lensSettings: lensSettings,
        onEditLens: () => showLensSetupSheet(
          context: context,
          current: lensSettings,
          onSave: updateLensSettings,
        ),
      ),
      const LinersSubscriptionTab(),
      const OptometristTab(),
    ];

    final pages = [
      LensDashboardTab(
        account: widget.account,
        lensSettings: lensSettings,
        onEditLens: () => showLensSetupSheet(
          context: context,
          current: lensSettings,
          onSave: updateLensSettings,
        ),
      ),
      const LinersSubscriptionTab(),
      const OptometristTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFBFAF7),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: pages[selectedTab],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Container(
              height: 64,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.96),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE8E2D8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  PremiumTabButton(
                    label: 'Home',
                    icon: Icons.dashboard_outlined,
                    selectedIcon: Icons.dashboard_rounded,
                    selected: selectedTab == 0,
                    onTap: () => setState(() => selectedTab = 0),
                  ),
                  PremiumTabButton(
                    label: 'Shop',
                    icon: Icons.inventory_2_outlined,
                    selectedIcon: Icons.inventory_2_rounded,
                    selected: selectedTab == 1,
                    onTap: () => setState(() => selectedTab = 1),
                  ),
                  PremiumTabButton(
                    label: 'Care',
                    icon: Icons.local_hospital_outlined,
                    selectedIcon: Icons.local_hospital_rounded,
                    selected: selectedTab == 2,
                    onTap: () => setState(() => selectedTab = 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class PremiumTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  const PremiumTabButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF151515) : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  size: 21,
                  color: selected ? Colors.white : const Color(0xFF5C5146),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LensDashboardTab extends StatelessWidget {
  final UserAccount account;
  final LensSettings lensSettings;
  final VoidCallback onEditLens;

  const LensDashboardTab({
    super.key,
    required this.account,
    required this.lensSettings,
    required this.onEditLens,
  });

  @override
  Widget build(BuildContext context) {
    final averageWearTime = AppSessionData.wearTimeLast30Days.reduce((a, b) => a + b) /
        AppSessionData.wearTimeLast30Days.length;

    return FocusTraversalGroup(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 8, bottom: 12),
                child: AppLogo(size: 165),
              ),
            ),
            AccountHeader(account: account),
            const SizedBox(height: 18),
            const Text(
              'Today’s Lens Check',
              style: TextStyle(
                fontSize: 31,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.9,
                color: Color(0xFF151515),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Lens health, buildup, and solution quality at a glance.',
              style: TextStyle(
                color: Color(0xFF444444),
                fontSize: 15,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            const BleConnectionCard(),
            const SizedBox(height: 18),
            const WearStatusCard(),
            const SizedBox(height: 18),
            DynamicDashboardRings(
              lensAgeDays: lensSettings.daysUsed,
              lensLimitDays: lensSettings.limitDays,
              lensTypeLabel: lensSettings.typeLabel,
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;
                return GridView.count(
                  crossAxisCount: isNarrow ? 1 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: isNarrow ? 2.15 : 1.22,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    const MetricTile(
                      icon: Icons.filter_alt_outlined,
                      title: 'Deposit Level',
                      value: 'Moderate',
                      detail: 'Signal loss vs baseline',
                      cueLabel: 'Orange bar means monitor closely.',
                      progress: 0.47,
                    ),
                    MetricTile(
                      icon: Icons.event_available_outlined,
                      title: 'Replace In',
                      value: lensSettings.replaceText,
                      detail: '${lensSettings.typeLabel} lenses • ${lensSettings.lensAgeText}',
                      cueLabel: 'Replacement estimate based on user-entered lens age.',
                      progress: null,
                    ),
                    MetricTile(
                      icon: Icons.visibility_outlined,
                      title: 'Lens Type',
                      value: lensSettings.typeLabel,
                      detail: 'Tap Edit Lens Setup to update age or replacement cycle',
                      cueLabel: 'Lens type is ${lensSettings.typeLabel}.',
                      progress: null,
                    ),
                    MetricTile(
                      icon: Icons.schedule_outlined,
                      title: 'Wear Time',
                      value: '${averageWearTime.toStringAsFixed(1)} hrs',
                      detail: '30-day average. Hardware reset will be added when case detection is connected.',
                      cueLabel: 'Average wear time from last 30 days.',
                      progress: null,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onEditLens,
                icon: const Icon(Icons.edit_calendar_rounded),
                label: const Text('Edit Lens Setup'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF151515),
                  side: const BorderSide(color: Color(0xFF151515)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 18),
            WearTimeHistoryCard(
              values: AppSessionData.wearTimeLast30Days,
              averageWearTime: averageWearTime,
            ),
            const SizedBox(height: 18),
            const AccessibleAlertCard(),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: SectionTitle(title: 'Stored Readings'),
                ),
                Semantics(
                  button: true,
                  label: 'View all stored readings',
                  child: TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Stored readings list will open in a future version.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history_rounded, size: 18),
                    label: const Text('View All'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF875000),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StoredReadingsCard(lensSettings: lensSettings),
          ],
        ),
      ),
    );
  }
}

Future<void> showLensSetupSheet({
  required BuildContext context,
  required LensSettings current,
  required void Function(LensType type, int daysUsed) onSave,
}) async {
  LensType selectedType = current.type;
  final daysController = TextEditingController(text: current.daysUsed.toString());

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFFBFAF7),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          int limitFor(LensType type) {
            switch (type) {
              case LensType.daily:
                return 1;
              case LensType.biweekly:
                return 14;
              case LensType.monthly:
                return 30;
            }
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lens Setup',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF151515),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tell LensLife how long you have had this pair so the lens age ring and replacement estimate update automatically.',
                  style: TextStyle(
                    color: Color(0xFF444444),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Lens replacement cycle',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Daily'),
                      selected: selectedType == LensType.daily,
                      onSelected: (_) {
                        setModalState(() {
                          selectedType = LensType.daily;
                          daysController.text = '1';
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Biweekly'),
                      selected: selectedType == LensType.biweekly,
                      onSelected: (_) {
                        setModalState(() => selectedType = LensType.biweekly);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Monthly'),
                      selected: selectedType == LensType.monthly,
                      onSelected: (_) {
                        setModalState(() => selectedType = LensType.monthly);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: daysController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Days you have had this lens pair',
                    helperText: 'Max for ${selectedType == LensType.daily ? 'daily' : selectedType == LensType.biweekly ? 'biweekly' : 'monthly'} lenses: ${limitFor(selectedType)} days',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFE5DED3)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final entered = int.tryParse(daysController.text.trim()) ?? 0;
                      final safeDays = entered.clamp(0, limitFor(selectedType));
                      onSave(selectedType, safeDays);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Save Lens Setup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF151515),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );

}

class DynamicDashboardRings extends StatelessWidget {
  final int lensAgeDays;
  final int lensLimitDays;
  final String lensTypeLabel;

  const DynamicDashboardRings({
    super.key,
    required this.lensAgeDays,
    required this.lensLimitDays,
    required this.lensTypeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final lensPercent = (lensAgeDays / lensLimitDays).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final rings = [
          const RingMetric(
            title: 'Cleanliness',
            centerText: '63%',
            subText: 'clean',
            percent: 0.63,
            semanticLabel: 'Cleanliness is 63 percent clean.',
          ),
          const RingMetric(
            title: 'Eye Safety',
            centerText: 'Caution',
            subText: 'Irritation risk',
            percent: 0.42,
            semanticLabel: 'Eye safety status is caution due to irritation risk.',
          ),
          RingMetric(
            title: 'Lens Age',
            centerText: '$lensAgeDays',
            subText: '/ $lensLimitDays days',
            percent: lensPercent,
            semanticLabel: '$lensTypeLabel lens age is $lensAgeDays out of $lensLimitDays days.',
            accentColor: const Color(0xFF2F86DE),
          ),
        ];

        if (constraints.maxWidth < 360) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: rings,
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: rings,
        );
      },
    );
  }
}

class WearTimeHistoryCard extends StatelessWidget {
  final List<double> values;
  final double averageWearTime;

  const WearTimeHistoryCard({
    super.key,
    required this.values,
    required this.averageWearTime,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5DED3)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WEAR TIME HISTORY',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF555555),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${averageWearTime.toStringAsFixed(1)} hrs average',
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: Color(0xFF151515),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Last 30 days. This is sample history for now; once case detection is connected, wear time can reset when lenses are placed in the case at night.',
            style: TextStyle(
              color: Color(0xFF444444),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: CustomPaint(
              painter: WearTimeChartPainter(values),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Low ${minValue.toStringAsFixed(1)}h',
                style: const TextStyle(fontSize: 12, color: Color(0xFF555555)),
              ),
              const Spacer(),
              Text(
                'High ${maxValue.toStringAsFixed(1)}h',
                style: const TextStyle(fontSize: 12, color: Color(0xFF555555)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WearTimeChartPainter extends CustomPainter {
  final List<double> values;

  WearTimeChartPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final axisPaint = Paint()
      ..color = const Color(0xFFE8E2D8)
      ..strokeWidth = 1;

    final barPaint = Paint()
      ..color = const Color(0xFFB97812)
      ..style = PaintingStyle.fill;

    final maxValue = math.max(1.0, values.reduce((a, b) => a > b ? a : b));
    final barGap = 2.0;
    final barWidth = (size.width - (values.length - 1) * barGap) / values.length;

    for (int i = 0; i < 4; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), axisPaint);
    }

    for (int i = 0; i < values.length; i++) {
      final normalized = (values[i] / maxValue).clamp(0.0, 1.0);
      final barHeight = size.height * normalized;
      final x = i * (barWidth + barGap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - barHeight, barWidth, barHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant WearTimeChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

class LinersSubscriptionTab extends StatelessWidget {
  const LinersSubscriptionTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: AppLogo(size: 165)),
          const SizedBox(height: 18),
          const Text(
            'LensLife Liners',
            style: TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.9,
              color: Color(0xFF151515),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Disposable case liners help keep the sensing chamber consistent. Choose a liner-only starter kit or a refill plan with saline solution included.',
            style: TextStyle(
              color: Color(0xFF444444),
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          const LinerPlanCard(
            title: 'Monthly Liner Refill',
            price: '\$5.99 / month',
            badge: 'Recommended',
            details: 'Includes one bottle of saline solution and one fresh set of LensLife liners delivered monthly.',
            icon: Icons.autorenew_rounded,
          ),
          const SizedBox(height: 12),
          const LinerPlanCard(
            title: '3-Month Pack',
            price: '\$14.99',
            badge: 'Best value',
            details: 'Includes three bottles of saline solution and three sets of LensLife liners for a 3-month supply.',
            icon: Icons.inventory_2_rounded,
          ),
          const SizedBox(height: 12),
          const LinerPlanCard(
            title: 'Starter Kit',
            price: '\$2.99',
            badge: 'Liners only',
            details: 'Starter liner-only kit with six sets of LensLife liners. Saline solution not included.',
            icon: Icons.shopping_bag_rounded,
          ),
        ],
      ),
    );
  }
}

class LinerPlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String badge;
  final String details;
  final IconData icon;

  const LinerPlanCard({
    super.key,
    required this.title,
    required this.price,
    required this.badge,
    required this.details,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5DED3)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFFFF1D6),
                child: Icon(icon, color: const Color(0xFF875000)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Color(0xFF151515),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1D6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Color(0xFF875000),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            price,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF151515),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            details,
            style: const TextStyle(
              color: Color(0xFF444444),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$title checkout will be added later.')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF151515),
                foregroundColor: Colors.white,
              ),
              child: const Text('Choose Plan'),
            ),
          ),
        ],
      ),
    );
  }
}

class OptometristTab extends StatelessWidget {
  const OptometristTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: AppLogo(size: 165)),
          const SizedBox(height: 18),
          const Text(
            'Eye Care Appointments',
            style: TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.9,
              color: Color(0xFF151515),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Book with an optometrist nearby when LensLife notices frequent irritation risk, dirty readings, or replacement reminders.',
            style: TextStyle(
              color: Color(0xFF444444),
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E8),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD69A34)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF875000)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Prototype note: nearby providers are sample cards for now. Later this can connect to location services or a provider API.',
                    style: TextStyle(
                      color: Color(0xFF3D3D3D),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const AppointmentCard(
            name: 'Campus Vision Care',
            distance: '0.8 mi away',
            nextSlot: 'Today, 4:30 PM',
            specialty: 'Contact lens fitting • irritation check',
          ),
          const SizedBox(height: 12),
          const AppointmentCard(
            name: 'ClearView Optometry',
            distance: '1.6 mi away',
            nextSlot: 'Tomorrow, 10:15 AM',
            specialty: 'Routine exam • dry eye support',
          ),
          const SizedBox(height: 12),
          const AppointmentCard(
            name: 'Coastal Eye Clinic',
            distance: '2.4 mi away',
            nextSlot: 'Friday, 2:00 PM',
            specialty: 'Lens replacement consultation',
          ),
        ],
      ),
    );
  }
}

class AppointmentCard extends StatelessWidget {
  final String name;
  final String distance;
  final String nextSlot;
  final String specialty;

  const AppointmentCard({
    super.key,
    required this.name,
    required this.distance,
    required this.nextSlot,
    required this.specialty,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5DED3)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFEAF3FF),
                child: Icon(Icons.local_hospital_rounded, color: Color(0xFF2F86DE)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Color(0xFF151515),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            distance,
            style: const TextStyle(
              color: Color(0xFF555555),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            specialty,
            style: const TextStyle(
              color: Color(0xFF444444),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF875000)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Next available: $nextSlot',
                  style: const TextStyle(
                    color: Color(0xFF875000),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Appointment request for $name will be added later.')),
                );
              },
              icon: const Icon(Icons.event_available_rounded),
              label: const Text('Request Appointment'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF151515),
                side: const BorderSide(color: Color(0xFF151515)),
              ),
            ),
          ),
        ],
      ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: pages[selectedTab],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Container(
              height: 64,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.96),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE8E2D8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  PremiumTabButton(
                    label: 'Home',
                    icon: Icons.dashboard_outlined,
                    selectedIcon: Icons.dashboard_rounded,
                    selected: selectedTab == 0,
                    onTap: () => setState(() => selectedTab = 0),
                  ),
                  PremiumTabButton(
                    label: 'Shop',
                    icon: Icons.inventory_2_outlined,
                    selectedIcon: Icons.inventory_2_rounded,
                    selected: selectedTab == 1,
                    onTap: () => setState(() => selectedTab = 1),
                  ),
                  PremiumTabButton(
                    label: 'Care',
                    icon: Icons.local_hospital_outlined,
                    selectedIcon: Icons.local_hospital_rounded,
                    selected: selectedTab == 2,
                    onTap: () => setState(() => selectedTab = 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class PremiumTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  const PremiumTabButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF151515) : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  size: 21,
                  color: selected ? Colors.white : const Color(0xFF5C5146),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LensDashboardTab extends StatelessWidget {
  final UserAccount account;
  final LensSettings lensSettings;
  final VoidCallback onEditLens;

  const LensDashboardTab({
    super.key,
    required this.account,
    required this.lensSettings,
    required this.onEditLens,
  });

  @override
  Widget build(BuildContext context) {
    final averageWearTime = AppSessionData.wearTimeLast30Days.reduce((a, b) => a + b) /
        AppSessionData.wearTimeLast30Days.length;

    return FocusTraversalGroup(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 8, bottom: 12),
                child: AppLogo(size: 165),
              ),
            ),
            AccountHeader(account: account),
            const SizedBox(height: 18),
            const Text(
              'Today’s Lens Check',
              style: TextStyle(
                fontSize: 31,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.9,
                color: Color(0xFF151515),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Lens health, buildup, and solution quality at a glance.',
              style: TextStyle(
                color: Color(0xFF444444),
                fontSize: 15,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            const Esp32BleConnectionCard(),
            const SizedBox(height: 18),
            ValueListenableBuilder<LiveSensorReading?>(
              valueListenable: lensLiveReadingNotifier,
              builder: (context, reading, _) => WearStatusCard(reading: reading),
            ),
            const SizedBox(height: 18),
            ValueListenableBuilder<LiveSensorReading?>(
              valueListenable: lensLiveReadingNotifier,
              builder: (context, reading, _) => DynamicDashboardRings(
                lensAgeDays: lensSettings.daysUsed,
                lensLimitDays: lensSettings.limitDays,
                lensTypeLabel: lensSettings.typeLabel,
                reading: reading,
              ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;
                return GridView.count(
                  crossAxisCount: isNarrow ? 1 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: isNarrow ? 2.15 : 1.22,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    ValueListenableBuilder<LiveSensorReading?>(
                      valueListenable: lensLiveReadingNotifier,
                      builder: (context, reading, _) => MetricTile(
                        icon: Icons.filter_alt_outlined,
                        title: 'Deposit Level',
                        value: reading?.depositLevel ?? 'Waiting',
                        detail: reading?.detailText ?? 'Waiting for ESP32 reading',
                        cueLabel: 'Deposit level from IR signal versus clean baseline.',
                        progress: reading?.foulingRatio,
                      ),
                    ),
                    MetricTile(
                      icon: Icons.event_available_outlined,
                      title: 'Replace In',
                      value: lensSettings.replaceText,
                      detail: '${lensSettings.typeLabel} lenses • ${lensSettings.lensAgeText}',
                      cueLabel: 'Replacement estimate based on user-entered lens age.',
                      progress: null,
                    ),
                    MetricTile(
                      icon: Icons.visibility_outlined,
                      title: 'Lens Type',
                      value: lensSettings.typeLabel,
                      detail: 'Tap Edit Lens Setup to update age or replacement cycle',
                      cueLabel: 'Lens type is ${lensSettings.typeLabel}.',
                      progress: null,
                    ),
                    MetricTile(
                      icon: Icons.schedule_outlined,
                      title: 'Wear Time',
                      value: '${averageWearTime.toStringAsFixed(1)} hrs',
                      detail: '30-day average. Hardware reset will be added when case detection is connected.',
                      cueLabel: 'Average wear time from last 30 days.',
                      progress: null,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onEditLens,
                icon: const Icon(Icons.edit_calendar_rounded),
                label: const Text('Edit Lens Setup'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF151515),
                  side: const BorderSide(color: Color(0xFF151515)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 18),
            LensReplacementCountdownCard(lensSettings: lensSettings),
            const SizedBox(height: 18),
            const CleaningStreakCard(),
            const SizedBox(height: 18),
            NotificationCenterCard(lensSettings: lensSettings),
            const SizedBox(height: 18),
            ValueListenableBuilder<LiveSensorReading?>(
              valueListenable: lensLiveReadingNotifier,
              builder: (context, reading, _) => SmartRecommendationsCard(reading: reading),
            ),
            const SizedBox(height: 18),
            ValueListenableBuilder<LiveSensorReading?>(
              valueListenable: lensLiveReadingNotifier,
              builder: (context, reading, _) => LensHealthHistoryCard(reading: reading),
            ),
            const SizedBox(height: 18),
            WearTimeHistoryCard(
              values: AppSessionData.wearTimeLast30Days,
              averageWearTime: averageWearTime,
            ),
            const SizedBox(height: 18),
            const AccessibleAlertCard(),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: SectionTitle(title: 'Stored Readings'),
                ),
                Semantics(
                  button: true,
                  label: 'View all stored readings',
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StoredReadingsPage(
                            lensSettings: lensSettings,
                            reading: lensLiveReadingNotifier.value,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history_rounded, size: 18),
                    label: const Text('View All'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF875000),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<LiveSensorReading?>(
              valueListenable: lensLiveReadingNotifier,
              builder: (context, reading, _) => StoredReadingsCard(
                lensSettings: lensSettings,
                reading: reading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showLensSetupSheet({
  required BuildContext context,
  required LensSettings current,
  required void Function(LensType type, int daysUsed) onSave,
}) async {
  LensType selectedType = current.type;
  final daysController = TextEditingController(text: current.daysUsed.toString());

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFFBFAF7),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          int limitFor(LensType type) {
            switch (type) {
              case LensType.daily:
                return 1;
              case LensType.biweekly:
                return 14;
              case LensType.monthly:
                return 30;
            }
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lens Setup',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF151515),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tell LensLife how long you have had this pair so the lens age ring and replacement estimate update automatically.',
                  style: TextStyle(
                    color: Color(0xFF444444),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Lens replacement cycle',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Daily'),
                      selected: selectedType == LensType.daily,
                      onSelected: (_) {
                        setModalState(() {
                          selectedType = LensType.daily;
                          daysController.text = '1';
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Biweekly'),
                      selected: selectedType == LensType.biweekly,
                      onSelected: (_) {
                        setModalState(() => selectedType = LensType.biweekly);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Monthly'),
                      selected: selectedType == LensType.monthly,
                      onSelected: (_) {
                        setModalState(() => selectedType = LensType.monthly);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: daysController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Days you have had this lens pair',
                    helperText: 'Max for ${selectedType == LensType.daily ? 'daily' : selectedType == LensType.biweekly ? 'biweekly' : 'monthly'} lenses: ${limitFor(selectedType)} days',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFE5DED3)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final entered = int.tryParse(daysController.text.trim()) ?? 0;
                      final safeDays = entered.clamp(0, limitFor(selectedType));
                      onSave(selectedType, safeDays);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Save Lens Setup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF151515),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );

}

class DynamicDashboardRings extends StatelessWidget {
  final int lensAgeDays;
  final int lensLimitDays;
  final String lensTypeLabel;
  final LiveSensorReading? reading;

  const DynamicDashboardRings({
    super.key,
    required this.lensAgeDays,
    required this.lensLimitDays,
    required this.lensTypeLabel,
    this.reading,
  });

  @override
  Widget build(BuildContext context) {
    final lensPercent = (lensAgeDays / lensLimitDays).clamp(0.0, 1.0).toDouble();

    final cleanlinessText = reading?.cleanlinessText ?? '--';
    final cleanlinessPercent = reading?.cleanlinessPercent ?? 0.0;
    // Keep the cleanliness ring focused on the percent only. The low/medium/high
    // risk wording is handled in Smart Recommendations instead.
    final cleanlinessSubText = reading == null ? 'waiting' : '';

    final hasReading = reading != null;
    final score = healthScoreFromReading(reading);
    final eyeSafetyText = hasReading ? riskShortLabelForScore(score) : '--';
    final eyeSafetySubText = hasReading ? riskLabelForScore(score) : 'Waiting';
    // Full ring so the entire circle changes color based on risk.
    final eyeSafetyPercent = hasReading ? 1.0 : 0.0;
    final eyeSafetyColor = hasReading
        ? riskColorForScore(score)
        : const Color(0xFFE2DFDA);

    return LayoutBuilder(
      builder: (context, constraints) {
        final rings = [
          RingMetric(
            title: 'Cleanliness',
            centerText: cleanlinessText,
            subText: cleanlinessSubText,
            percent: cleanlinessPercent,
            semanticLabel: 'Cleanliness is $cleanlinessText.',
          ),
          RingMetric(
            title: 'Eye Safety',
            centerText: eyeSafetyText,
            subText: eyeSafetySubText,
            percent: eyeSafetyPercent,
            semanticLabel: 'Eye safety status is $eyeSafetyText.',
            accentColor: eyeSafetyColor,
          ),
          RingMetric(
            title: 'Lens Age',
            centerText: '$lensAgeDays',
            subText: '/ $lensLimitDays days',
            percent: lensPercent,
            semanticLabel: '$lensTypeLabel lens age is $lensAgeDays out of $lensLimitDays days.',
            accentColor: const Color(0xFF2F86DE),
          ),
        ];

        if (constraints.maxWidth < 360) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: rings,
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: rings,
        );
      },
    );
  }
}



int healthScoreFromReading(LiveSensorReading? reading) {
  if (reading == null) return 0;

  final match = RegExp(r'\d+').firstMatch(reading.cleanlinessText);
  if (match != null) {
    return (int.tryParse(match.group(0) ?? '0') ?? 0).clamp(0, 100);
  }

  return (reading.cleanlinessPercent * 100).round().clamp(0, 100);
}

String riskLabelForScore(int score) {
  if (score >= 75) return 'Low risk';
  if (score >= 40) return 'Medium risk';
  return 'High risk';
}

String riskShortLabelForScore(int score) {
  if (score >= 75) return 'Good';
  if (score >= 40) return 'Caution';
  return 'High';
}

Color riskColorForScore(int score) {
  if (score >= 75) return const Color(0xFF2EAD4F); // green
  if (score >= 40) return const Color(0xFFB97812); // yellow/gold
  return const Color(0xFFD93A2F); // red
}

String riskMessageForScore(int score) {
  if (score >= 75) {
    return 'Your latest reading looks safe. Keep your normal cleaning routine and replace solution on schedule.';
  }
  if (score >= 40) {
    return 'Some buildup or solution change may be forming. Clean lenses tonight and check again before long wear.';
  }
  return 'High risk reading detected. Replace solution immediately and consider replacing the lens pair before wearing again.';
}

class SmartRecommendationsCard extends StatelessWidget {
  final LiveSensorReading? reading;

  const SmartRecommendationsCard({super.key, this.reading});

  @override
  Widget build(BuildContext context) {
    final hasReading = reading != null;
    final score = healthScoreFromReading(reading);
    final riskLabel = hasReading ? riskLabelForScore(score) : 'Waiting for reading';
    final message = hasReading
        ? riskMessageForScore(score)
        : 'Connect the LensLife case or use demo readings to generate a recommendation.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5DED3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SMART RECOMMENDATION',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF555555),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: hasReading
                    ? riskColorForScore(score).withOpacity(0.12)
                    : const Color(0xFFFFF1D6),
                child: Icon(
                  score >= 75
                      ? Icons.check_circle_outline_rounded
                      : score >= 40
                          ? Icons.warning_amber_rounded
                          : Icons.error_outline_rounded,
                  color: hasReading
                      ? riskColorForScore(score)
                      : const Color(0xFF875000),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      riskLabel,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF151515),
                      ),
                    ),
                    Text(
                      hasReading ? 'Health score: $score%' : 'No score yet',
                      style: const TextStyle(
                        color: Color(0xFF555555),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: hasReading ? score / 100 : 0,
              minHeight: 8,
              color: hasReading ? riskColorForScore(score) : const Color(0xFFB97812),
              backgroundColor: const Color(0xFFEAE5DC),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF3D3D3D),
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class LensHealthHistoryCard extends StatelessWidget {
  final LiveSensorReading? reading;

  const LensHealthHistoryCard({super.key, this.reading});

  @override
  Widget build(BuildContext context) {
    final currentScore = reading == null ? null : healthScoreFromReading(reading);
    final entries = <_HealthHistoryEntry>[
      if (currentScore != null)
        _HealthHistoryEntry('Now', currentScore, riskLabelForScore(currentScore)),
      const _HealthHistoryEntry('Yesterday', 82, 'Low risk'),
      const _HealthHistoryEntry('2 days ago', 71, 'Medium risk'),
      const _HealthHistoryEntry('3 days ago', 78, 'Low risk'),
      const _HealthHistoryEntry('4 days ago', 63, 'Medium risk'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5DED3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'LENS HEALTH HISTORY',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF555555),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StoredReadingsPage(
                        lensSettings: AppSessionData.lensSettings,
                        reading: reading,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Recent lens health trend using sample history plus the latest live reading.',
            style: TextStyle(color: Color(0xFF444444), height: 1.3),
          ),
          const SizedBox(height: 12),
          ...entries.take(4).map((entry) => _HealthHistoryRow(entry: entry)),
        ],
      ),
    );
  }
}

class _HealthHistoryEntry {
  final String label;
  final int score;
  final String risk;

  const _HealthHistoryEntry(this.label, this.score, this.risk);
}

class _HealthHistoryRow extends StatelessWidget {
  final _HealthHistoryEntry entry;

  const _HealthHistoryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: Text(
              entry.label,
              style: const TextStyle(
                color: Color(0xFF555555),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: entry.score / 100,
                minHeight: 7,
                color: const Color(0xFFB97812),
                backgroundColor: const Color(0xFFEAE5DC),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 78,
            child: Text(
              '${entry.score}%\n${entry.risk}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF151515),
                fontWeight: FontWeight.w800,
                fontSize: 12,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StoredReadingsPage extends StatelessWidget {
  final LensSettings lensSettings;
  final LiveSensorReading? reading;

  const StoredReadingsPage({
    super.key,
    required this.lensSettings,
    this.reading,
  });

  @override
  Widget build(BuildContext context) {
    final score = reading == null ? null : healthScoreFromReading(reading);
    final rows = [
      _StoredReadingRow(
        title: 'Latest Health Score',
        value: score == null ? '--' : '$score%',
        detail: score == null ? 'Waiting for live reading' : riskLabelForScore(score),
      ),
      _StoredReadingRow(
        title: 'Deposit Level',
        value: reading?.depositLevel ?? '--',
        detail: reading?.detailText ?? 'Waiting for ESP32 reading',
      ),
      _StoredReadingRow(
        title: 'Solution pH',
        value: reading?.phText ?? '--',
        detail: 'Latest pH estimate from sensor payload',
      ),
      _StoredReadingRow(
        title: 'Cleanliness',
        value: reading?.cleanlinessText ?? '--',
        detail: 'Cleanliness score from current reading',
      ),
      _StoredReadingRow(
        title: 'Eye Safety',
        value: reading?.eyeSafetyText ?? '--',
        detail: reading?.eyeSafetySubText ?? 'Waiting for risk classification',
      ),
      _StoredReadingRow(
        title: 'Lens Age',
        value: lensSettings.lensAgeText,
        detail: '${lensSettings.typeLabel} replacement cycle',
      ),
    ];

    final history = <_HealthHistoryEntry>[
      if (score != null) _HealthHistoryEntry('Now', score, riskLabelForScore(score)),
      const _HealthHistoryEntry('Yesterday', 82, 'Low risk'),
      const _HealthHistoryEntry('2 days ago', 71, 'Medium risk'),
      const _HealthHistoryEntry('3 days ago', 78, 'Low risk'),
      const _HealthHistoryEntry('4 days ago', 63, 'Medium risk'),
      const _HealthHistoryEntry('5 days ago', 38, 'High risk'),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFBFAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFAF7),
        title: const Text('Stored Readings'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                const Text(
                  'Stored Readings',
                  style: TextStyle(
                    fontSize: 31,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.9,
                    color: Color(0xFF151515),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'This screen shows the latest live values plus sample history for the demo.',
                  style: TextStyle(color: Color(0xFF444444), height: 1.35),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5DED3)),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < rows.length; i++) ...[
                        _StoredReadingTile(row: rows[i]),
                        if (i != rows.length - 1) const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5DED3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HEALTH HISTORY',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF555555),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...history.map((entry) => _HealthHistoryRow(entry: entry)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoredReadingRow {
  final String title;
  final String value;
  final String detail;

  const _StoredReadingRow({
    required this.title,
    required this.value,
    required this.detail,
  });
}

class _StoredReadingTile extends StatelessWidget {
  final _StoredReadingRow row;

  const _StoredReadingTile({required this.row});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        row.title,
        style: const TextStyle(
          color: Color(0xFF111111),
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        row.detail,
        style: const TextStyle(color: Color(0xFF555555)),
      ),
      trailing: Text(
        row.value,
        textAlign: TextAlign.right,
        style: const TextStyle(
          color: Color(0xFF111111),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class LensReplacementCountdownCard extends StatelessWidget {
  final LensSettings lensSettings;

  const LensReplacementCountdownCard({super.key, required this.lensSettings});

  @override
  Widget build(BuildContext context) {
    final percentRemaining = (lensSettings.daysRemaining / lensSettings.limitDays).clamp(0.0, 1.0).toDouble();
    final percentUsed = lensSettings.percentUsed;
    final isUrgent = lensSettings.daysRemaining <= 2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5DED3)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LENS REPLACEMENT COUNTDOWN',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF555555),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  lensSettings.replaceText,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: isUrgent ? const Color(0xFF9B1C1C) : const Color(0xFF151515),
                  ),
                ),
              ),
              Text(
                '${(percentRemaining * 100).round()}% left',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF555555),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percentUsed,
              minHeight: 12,
              color: isUrgent ? const Color(0xFF9B1C1C) : const Color(0xFFB97812),
              backgroundColor: const Color(0xFFEAE5DC),
              semanticsLabel: 'Lens replacement countdown bar',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${lensSettings.typeLabel} lenses • ${lensSettings.lensAgeText} used',
            style: const TextStyle(
              color: Color(0xFF444444),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class CleaningStreakCard extends StatelessWidget {
  const CleaningStreakCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppSessionData.cleaningStreakNotifier,
      builder: (context, streak, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE5DED3)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CLEANING STREAK',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF555555),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFFFF1D6),
                    child: Icon(Icons.local_fire_department_rounded, color: Color(0xFF875000)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$streak days',
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF151515),
                          ),
                        ),
                        Text(
                          'Best streak: ${AppSessionData.bestCleaningStreak} days',
                          style: const TextStyle(color: Color(0xFF555555), fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final next = AppSessionData.cleaningStreakNotifier.value + 1;
                    AppSessionData.cleaningStreakNotifier.value = next;
                    if (next > AppSessionData.bestCleaningStreak) {
                      AppSessionData.bestCleaningStreak = next;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Cleaning logged. Streak is now $next days.')),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Log Cleaning Today'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF151515),
                    side: const BorderSide(color: Color(0xFF151515)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class NotificationCenterCard extends StatefulWidget {
  final LensSettings lensSettings;

  const NotificationCenterCard({super.key, required this.lensSettings});

  @override
  State<NotificationCenterCard> createState() => _NotificationCenterCardState();
}

class _NotificationCenterCardState extends State<NotificationCenterCard> {
  final Set<int> dismissed = {};

  @override
  Widget build(BuildContext context) {
    final messages = [
      if (widget.lensSettings.daysRemaining <= 3)
        'Lens replacement is coming up soon: ${widget.lensSettings.replaceText}.'
      else
        'Lens replacement countdown: ${widget.lensSettings.replaceText}.',
      ...AppSessionData.notifications,
    ];
    final visible = <MapEntry<int, String>>[];
    for (int i = 0; i < messages.length; i++) {
      if (!dismissed.contains(i)) visible.add(MapEntry(i, messages[i]));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5DED3)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'NOTIFICATION CENTER',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF555555),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1D6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${visible.length} new',
                  style: const TextStyle(
                    color: Color(0xFF875000),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (visible.isEmpty)
            const Text(
              'You are all caught up.',
              style: TextStyle(color: Color(0xFF444444), fontWeight: FontWeight.w700),
            )
          else
            ...visible.take(3).map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notifications_active_outlined, size: 18, color: Color(0xFF875000)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(color: Color(0xFF3D3D3D), height: 1.25),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Dismiss notification',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => dismissed.add(entry.key)),
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class WearTimeHistoryCard extends StatelessWidget {
  final List<double> values;
  final double averageWearTime;

  const WearTimeHistoryCard({
    super.key,
    required this.values,
    required this.averageWearTime,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5DED3)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WEAR TIME HISTORY',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF555555),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${averageWearTime.toStringAsFixed(1)} hrs average',
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: Color(0xFF151515),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Last 30 days. This is sample history for now; once case detection is connected, wear time can reset when lenses are placed in the case at night.',
            style: TextStyle(
              color: Color(0xFF444444),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: CustomPaint(
              painter: WearTimeChartPainter(values),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Low ${minValue.toStringAsFixed(1)}h',
                style: const TextStyle(fontSize: 12, color: Color(0xFF555555)),
              ),
              const Spacer(),
              Text(
                'High ${maxValue.toStringAsFixed(1)}h',
                style: const TextStyle(fontSize: 12, color: Color(0xFF555555)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WearTimeChartPainter extends CustomPainter {
  final List<double> values;

  WearTimeChartPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final axisPaint = Paint()
      ..color = const Color(0xFFE8E2D8)
      ..strokeWidth = 1;

    final barPaint = Paint()
      ..color = const Color(0xFFB97812)
      ..style = PaintingStyle.fill;

    final maxValue = math.max(1.0, values.reduce((a, b) => a > b ? a : b));
    final barGap = 2.0;
    final barWidth = (size.width - (values.length - 1) * barGap) / values.length;

    for (int i = 0; i < 4; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), axisPaint);
    }

    for (int i = 0; i < values.length; i++) {
      final normalized = (values[i] / maxValue).clamp(0.0, 1.0);
      final barHeight = size.height * normalized;
      final x = i * (barWidth + barGap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - barHeight, barWidth, barHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant WearTimeChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

class LinersSubscriptionTab extends StatefulWidget {
  const LinersSubscriptionTab({super.key});

  @override
  State<LinersSubscriptionTab> createState() => _LinersSubscriptionTabState();
}

class _LinersSubscriptionTabState extends State<LinersSubscriptionTab> {
  void choosePlan({
    required String title,
    required String price,
    required String delivery,
  }) {
    setState(() {
      AppSessionData.selectedSubscription = SubscriptionPlanSelection(
        title: title,
        price: price,
        delivery: delivery,
        selectedAt: DateTime.now(),
      );
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFBFAF7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFFFFF1D6),
                child: Icon(Icons.check_rounded, color: Color(0xFF875000), size: 32),
              ),
              const SizedBox(height: 14),
              Text(
                '$title selected',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF151515),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fake checkout complete. Your demo subscription is now active for $price.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF444444),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF151515),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = AppSessionData.selectedSubscription;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: AppLogo(size: 165)),
          const SizedBox(height: 18),
          const Text(
            'LensLife Liners',
            style: TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.9,
              color: Color(0xFF151515),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Disposable case liners help keep the sensing chamber consistent. Choose a liner-only starter kit or a refill plan with saline solution included.',
            style: TextStyle(
              color: Color(0xFF444444),
              fontSize: 15,
              height: 1.4,
            ),
          ),
          if (selected != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD69A34)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, color: Color(0xFF875000)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Active demo plan: ${selected.title} • ${selected.price}\n${selected.delivery}',
                      style: const TextStyle(
                        color: Color(0xFF3D3D3D),
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          LinerPlanCard(
            title: 'Monthly Liner Refill',
            price: '\$5.99 / month',
            badge: 'Recommended',
            details: 'Includes one bottle of saline solution and one fresh set of LensLife liners delivered monthly.',
            icon: Icons.autorenew_rounded,
            selected: selected?.title == 'Monthly Liner Refill',
            onChoose: () => choosePlan(
              title: 'Monthly Liner Refill',
              price: '\$5.99 / month',
              delivery: 'Next refill ships in 30 days.',
            ),
          ),
          const SizedBox(height: 12),
          LinerPlanCard(
            title: '3-Month Pack',
            price: '\$14.99',
            badge: 'Best value',
            details: 'Includes three bottles of saline solution and three sets of LensLife liners for a 3-month supply.',
            icon: Icons.inventory_2_rounded,
            selected: selected?.title == '3-Month Pack',
            onChoose: () => choosePlan(
              title: '3-Month Pack',
              price: '\$14.99',
              delivery: 'Estimated delivery: 3–5 business days.',
            ),
          ),
          const SizedBox(height: 12),
          LinerPlanCard(
            title: 'Starter Kit',
            price: '\$2.99',
            badge: 'Liners only',
            details: 'Starter liner-only kit with six sets of LensLife liners. Saline solution not included.',
            icon: Icons.shopping_bag_rounded,
            selected: selected?.title == 'Starter Kit',
            onChoose: () => choosePlan(
              title: 'Starter Kit',
              price: '\$2.99',
              delivery: 'Estimated delivery: 3–5 business days.',
            ),
          ),
        ],
      ),
    );
  }
}

class LinerPlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String badge;
  final String details;
  final IconData icon;
  final bool selected;
  final VoidCallback onChoose;

  const LinerPlanCard({
    super.key,
    required this.title,
    required this.price,
    required this.badge,
    required this.details,
    required this.icon,
    required this.selected,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFFF7E8) : Colors.white,
        border: Border.all(
          color: selected ? const Color(0xFFB97812) : const Color(0xFFE5DED3),
          width: selected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFFFF1D6),
                child: Icon(icon, color: const Color(0xFF875000)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Color(0xFF151515),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF151515) : const Color(0xFFFFF1D6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  selected ? 'Active' : badge,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF875000),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            price,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF151515),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            details,
            style: const TextStyle(
              color: Color(0xFF444444),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onChoose,
              icon: Icon(selected ? Icons.check_rounded : Icons.shopping_cart_checkout_rounded),
              label: Text(selected ? 'Selected' : 'Choose Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF151515),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OptometristTab extends StatefulWidget {
  const OptometristTab({super.key});

  @override
  State<OptometristTab> createState() => _OptometristTabState();
}

class _OptometristTabState extends State<OptometristTab> {
  void requestAppointment({
    required String name,
    required String nextSlot,
    required String specialty,
  }) {
    setState(() {
      final appointment = BookedAppointment(
        providerName: name,
        slot: nextSlot,
        specialty: specialty,
        bookedAt: DateTime.now(),
      );
      AppSessionData.bookedAppointment = appointment;
      AppSessionData.appointmentHistory.removeWhere(
        (item) => item.providerName == appointment.providerName && item.slot == appointment.slot,
      );
      AppSessionData.appointmentHistory.insert(0, appointment);
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text('Appointment requested'),
          content: Text(
            'Fake booking confirmed with $name for $nextSlot.\n\nReason: $specialty',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final booked = AppSessionData.bookedAppointment;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: AppLogo(size: 165)),
          const SizedBox(height: 18),
          const Text(
            'Eye Care Appointments',
            style: TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.9,
              color: Color(0xFF151515),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Book with an optometrist nearby when LensLife notices frequent irritation risk, dirty readings, or replacement reminders.',
            style: TextStyle(
              color: Color(0xFF444444),
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E8),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD69A34)),
            ),
            child: Row(
              children: [
                Icon(
                  booked == null ? Icons.info_outline_rounded : Icons.event_available_rounded,
                  color: const Color(0xFF875000),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    booked == null
                        ? 'Prototype note: nearby providers are sample cards for now. Tap Request Appointment to create a fake booking.'
                        : 'Booked demo appointment: ${booked.providerName} • ${booked.slot}',
                    style: const TextStyle(
                      color: Color(0xFF3D3D3D),
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const SizedBox(height: 14),
          AppointmentCard(
            name: 'Campus Vision Care',
            distance: '0.8 mi away',
            nextSlot: 'Today, 4:30 PM',
            specialty: 'Contact lens fitting • irritation check',
            selected: booked?.providerName == 'Campus Vision Care',
            onRequest: () => requestAppointment(
              name: 'Campus Vision Care',
              nextSlot: 'Today, 4:30 PM',
              specialty: 'Contact lens fitting • irritation check',
            ),
          ),
          const SizedBox(height: 12),
          AppointmentCard(
            name: 'ClearView Optometry',
            distance: '1.6 mi away',
            nextSlot: 'Tomorrow, 10:15 AM',
            specialty: 'Routine exam • dry eye support',
            selected: booked?.providerName == 'ClearView Optometry',
            onRequest: () => requestAppointment(
              name: 'ClearView Optometry',
              nextSlot: 'Tomorrow, 10:15 AM',
              specialty: 'Routine exam • dry eye support',
            ),
          ),
          const SizedBox(height: 12),
          AppointmentCard(
            name: 'Coastal Eye Clinic',
            distance: '2.4 mi away',
            nextSlot: 'Friday, 2:00 PM',
            specialty: 'Lens replacement consultation',
            selected: booked?.providerName == 'Coastal Eye Clinic',
            onRequest: () => requestAppointment(
              name: 'Coastal Eye Clinic',
              nextSlot: 'Friday, 2:00 PM',
              specialty: 'Lens replacement consultation',
            ),
          ),
        ],
      ),
    );
  }
}


class AppointmentBookingHistoryCard extends StatelessWidget {
  const AppointmentBookingHistoryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final history = AppSessionData.appointmentHistory;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5DED3)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'APPOINTMENT HISTORY',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF555555),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          if (history.isEmpty)
            const Text(
              'No appointments requested yet. Tap Request Appointment below to create a fake booking.',
              style: TextStyle(color: Color(0xFF444444), height: 1.3),
            )
          else
            ...history.take(3).map(
              (appointment) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.event_available_rounded, color: Color(0xFF2F86DE)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.providerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF151515),
                            ),
                          ),
                          Text(
                            '${appointment.slot} • ${appointment.specialty}',
                            style: const TextStyle(
                              color: Color(0xFF444444),
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AppointmentCard extends StatelessWidget {
  final String name;
  final String distance;
  final String nextSlot;
  final String specialty;
  final bool selected;
  final VoidCallback onRequest;

  const AppointmentCard({
    super.key,
    required this.name,
    required this.distance,
    required this.nextSlot,
    required this.specialty,
    required this.selected,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEAF3FF) : Colors.white,
        border: Border.all(
          color: selected ? const Color(0xFF2F86DE) : const Color(0xFFE5DED3),
          width: selected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFEAF3FF),
                child: Icon(Icons.local_hospital_rounded, color: Color(0xFF2F86DE)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Color(0xFF151515),
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, color: Color(0xFF2F86DE)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            distance,
            style: const TextStyle(
              color: Color(0xFF555555),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            specialty,
            style: const TextStyle(
              color: Color(0xFF444444),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF875000)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selected ? 'Requested: $nextSlot' : 'Next available: $nextSlot',
                  style: const TextStyle(
                    color: Color(0xFF875000),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRequest,
              icon: Icon(selected ? Icons.check_rounded : Icons.event_available_rounded),
              label: Text(selected ? 'Requested' : 'Request Appointment'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF151515),
                side: const BorderSide(color: Color(0xFF151515)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AccountHeader extends StatelessWidget {
  final UserAccount account;

  const AccountHeader({super.key, required this.account});

  String get firstInitial => account.fullName.isNotEmpty
      ? account.fullName.trim()[0].toUpperCase()
      : 'A';

  String get firstName {
    final parts = account.fullName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : account.fullName;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Account header for $firstName, email ${account.email}',
      child: Row(
        children: [
          ExcludeSemantics(
            child: CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF151515),
              child: Text(
                firstInitial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning, $firstName',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111111),
                  ),
                ),
                Text(
                  account.email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF444444),
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: 'Log out of LensLife',
            child: IconButton(
              tooltip: 'Log out',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthPage()),
                );
              },
              icon: const Icon(Icons.logout_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class WearStatusCard extends StatelessWidget {
  final LiveSensorReading? reading;

  const WearStatusCard({super.key, this.reading});

  @override
  Widget build(BuildContext context) {
    final chipLabel = reading?.statusChipLabel ?? 'Waiting for reading';
    final title = reading?.wearStatusTitle ?? 'No live reading yet';
    final message = reading?.wearStatusMessage ??
        'Connect to the LensLife case and enter measurement mode to update this card.';

    return Semantics(
      label: 'Wear status $chipLabel. $title. $message',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5DED3)),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WEAR STATUS',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF555555),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 9),
            StatusChip(icon: Icons.visibility_outlined, label: chipLabel),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                color: Color(0xFF151515),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                height: 1.36,
                color: Color(0xFF3B3B3B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const StatusChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Status: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1D6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4B264)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(icon, size: 15, color: const Color(0xFF875000)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF875000),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardRings extends StatelessWidget {
  const DashboardRings({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return const Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              RingMetric(
                title: 'Cleanliness',
                centerText: '63%',
                subText: 'clean',
                percent: 0.63,
                semanticLabel: 'Cleanliness is 63 percent clean.',
              ),
              RingMetric(
                title: 'Eye Safety',
                centerText: 'Caution',
                subText: 'Irritation risk',
                percent: 0.42,
                semanticLabel: 'Eye safety status is caution due to irritation risk.',
              ),
              RingMetric(
                title: 'Lens Age',
                centerText: '9',
                subText: '/ 30 days',
                percent: 0.30,
                semanticLabel: 'Lens age is 9 out of 30 days.',
                accentColor: Color(0xFF2F86DE),
              ),
            ],
          );
        }

        return const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RingMetric(
              title: 'Cleanliness',
              centerText: '63%',
              subText: 'clean',
              percent: 0.63,
              semanticLabel: 'Cleanliness is 63 percent clean.',
            ),
            RingMetric(
              title: 'Eye Safety',
              centerText: 'Caution',
              subText: 'Irritation risk',
              percent: 0.42,
              semanticLabel: 'Eye safety status is caution due to irritation risk.',
            ),
            RingMetric(
              title: 'Lens Age',
              centerText: '9',
              subText: '/ 30 days',
              percent: 0.30,
              semanticLabel: 'Lens age is 9 out of 30 days.',
              accentColor: Color(0xFF2F86DE),
            ),
          ],
        );
      },
    );
  }
}

class RingMetric extends StatelessWidget {
  final String title;
  final String centerText;
  final String subText;
  final double percent;
  final String semanticLabel;
  final Color accentColor;

  const RingMetric({
    super.key,
    required this.title,
    required this.centerText,
    required this.subText,
    required this.percent,
    required this.semanticLabel,
    this.accentColor = const Color(0xFFB97812),
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: Column(
        children: [
          SizedBox(
            width: 104,
            height: 104,
            child: CustomPaint(
              painter: RingPainter(
                percent,
                accentColor: accentColor,
                backgroundColor: const Color(0xFFE2DFDA),
                strokeWidth: 8,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      centerText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF151515),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subText.isNotEmpty)
                      Text(
                        subText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: subText.length > 10 ? 9 : 11,
                          color: const Color(0xFF555555),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF555555),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class RingPainter extends CustomPainter {
  final double percent;
  final Color accentColor;
  final Color backgroundColor;
  final double strokeWidth;

  RingPainter(
    this.percent, {
    required this.accentColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 2.25;

    final bg = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final progress = Paint()
      ..color = accentColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * percent,
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class MetricTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String detail;
  final String cueLabel;
  final double? progress;

  const MetricTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
    required this.cueLabel,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title. $value. $detail. $cueLabel',
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5DED3)),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(icon, color: const Color(0xFF3B3B3B), size: 23),
            ),
            const SizedBox(height: 10),
            Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF555555),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: title == 'Replace In'
                    ? const Color(0xFF875000)
                    : const Color(0xFF151515),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress!.clamp(0.0, 1.0),
                  minHeight: 6,
                  color: const Color(0xFFB97812),
                  backgroundColor: const Color(0xFFEAE5DC),
                  semanticsLabel: cueLabel,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.1,
                    color: Color(0xFF3D3D3D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AccessibleAlertCard extends StatelessWidget {
  const AccessibleAlertCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Important cleaning alert. Clean your lenses tonight. This alert includes icon, label, text, and border so it can be understood without relying only on color.',
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7E8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD69A34), width: 1.4),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFF875000),
                size: 28,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cleaning recommended tonight',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF151515),
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Deposit level and pH trend suggest an enzyme clean before your next wear.',
                    style: TextStyle(
                      color: Color(0xFF3D3D3D),
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StoredReadingsCard extends StatelessWidget {
  final LensSettings lensSettings;

  const StoredReadingsCard({
    super.key,
    required this.lensSettings,
  });
  final LensSettings lensSettings;
  final LiveSensorReading? reading;

  const StoredReadingsCard({
    super.key,
    required this.lensSettings,
    this.reading,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Stored readings list with deposit level moderate, solution pH 6.6, cleanliness 63 percent, and lens age ${lensSettings.lensAgeText}.',
          'Stored readings list with latest live values and lens age ${lensSettings.lensAgeText}.',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5DED3)),
        ),
        child: Column(
        child: Column(
          children: [
            const ReadingTile(title: 'Deposit Level', value: 'Moderate', time: 'Today'),
            const Divider(height: 1),
            const ReadingTile(title: 'Solution pH', value: '6.6', time: 'Today'),
            const Divider(height: 1),
            const ReadingTile(title: 'Cleanliness', value: '63%', time: 'Today'),
            const Divider(height: 1),
            ReadingTile(title: 'Lens Age', value: lensSettings.lensAgeText, time: lensSettings.typeLabel),
            ReadingTile(title: 'Deposit Level', value: reading?.depositLevel ?? '--', time: 'Live'),
            const Divider(height: 1),
            ReadingTile(title: 'Solution pH', value: reading?.phText ?? '--', time: 'Live'),
            const Divider(height: 1),
            ReadingTile(title: 'Cleanliness', value: reading?.cleanlinessText ?? '--', time: 'Live'),
            const Divider(height: 1),
            ReadingTile(title: 'Lens Age', value: lensSettings.lensAgeText, time: lensSettings.typeLabel),
          ],
        ),
      ),
    );
  }
}

class ReadingTile extends StatelessWidget {
  final String title;
  final String value;
  final String time;

  const ReadingTile({
    super.key,
    required this.title,
    required this.value,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF111111),
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        time,
        style: const TextStyle(color: Color(0xFF555555)),
      ),
      trailing: Text(
        value,
        style: const TextStyle(
          color: Color(0xFF111111),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        color: Color(0xFF111111),
        fontSize: 17,
      ),
    );
  }
}