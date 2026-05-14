import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

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

class DashboardPage extends StatelessWidget {
  final UserAccount account;

  const DashboardPage({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFAF7),
      body: SafeArea(
        child: FocusTraversalGroup(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
  const Center(
    child: Padding(
      padding: EdgeInsets.only(top: 8, bottom: 12),
      child: AppLogo(size: 140),
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
                    const WearStatusCard(),
                    const SizedBox(height: 18),
                    const DashboardRings(),
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
                          children: const [
                            MetricTile(
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
                              value: '~4 days',
                              detail: 'Based on current deposit buildup rate',
                              cueLabel: 'Replace estimate is four days.',
                              progress: null,
                            ),
                            MetricTile(
                              icon: Icons.science_outlined,
                              title: 'Solution pH',
                              value: '6.6',
                              detail: 'Slight bacterial activity detected',
                              cueLabel: 'pH is lower than ideal. Clean tonight.',
                              progress: null,
                            ),
                            MetricTile(
                              icon: Icons.schedule_outlined,
                              title: 'Wear Time',
                              value: '11.2 hrs',
                              detail: 'Today average',
                              cueLabel: 'Wear time is high for today.',
                              progress: null,
                            ),
                          ],
                        );
                      },
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
                    const StoredReadingsCard(),
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
  const WearStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Wear status monitor closely. Moderate buildup. Deposits have been accumulating since day one. Lenses are wearable, but an enzyme clean tonight will extend comfort and lens life.',
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
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WEAR STATUS',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF555555),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 9),
            StatusChip(icon: Icons.visibility_outlined, label: 'Monitor closely'),
            SizedBox(height: 12),
            Text(
              'Moderate buildup',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                color: Color(0xFF151515),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 7),
            Text(
              'Deposits accumulating since day 1. Lenses are wearable, but an enzyme clean tonight will extend comfort and lens life.',
              style: TextStyle(
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
            const SizedBox(height: 12),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF555555),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 6),
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
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  color: const Color(0xFFB97812),
                  backgroundColor: const Color(0xFFEAE5DC),
                  semanticsLabel: cueLabel,
                ),
              ),
            ],
            const Spacer(),
            Text(
              detail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                height: 1.2,
                color: Color(0xFF3D3D3D),
                fontWeight: FontWeight.w500,
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
  const StoredReadingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Stored readings list with deposit level moderate, solution pH 6.6, cleanliness 63 percent, and lens age 9 days.',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5DED3)),
        ),
        child: const Column(
          children: [
            ReadingTile(title: 'Deposit Level', value: 'Moderate', time: 'Today'),
            Divider(height: 1),
            ReadingTile(title: 'Solution pH', value: '6.6', time: 'Today'),
            Divider(height: 1),
            ReadingTile(title: 'Cleanliness', value: '63%', time: 'Today'),
            Divider(height: 1),
            ReadingTile(title: 'Lens Age', value: '9 days', time: 'Today'),
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
