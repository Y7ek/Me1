import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../controllers/theme_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loggingIn = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          textAlign: TextAlign.center,
        ),
        backgroundColor: error ? Colors.red : Colors.black87,
      ),
    );
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showSnack('رجاءً أدخل بريدًا إلكترونيًا صالحًا', error: true);
      return;
    }
    if (pass.length < 6) {
      _showSnack('كلمة المرور يجب أن تكون 6 أحرف على الأقل', error: true);
      return;
    }

    setState(() => _loggingIn = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      // لا نحتاج Navigation هنا لو عندك Root يعتمد على authStateChanges
      // مجرد نجاح تسجيل الدخول يكفي، StreamBuilder في main.dart راح ينقلك للشاشة التالية.
    } on FirebaseAuthException catch (e) {
      String message = 'فشل تسجيل الدخول';
      if (e.code == 'user-not-found') {
        message = 'لا يوجد حساب بهذا البريد';
      } else if (e.code == 'wrong-password') {
        message = 'كلمة المرور غير صحيحة';
      } else if (e.code == 'invalid-email') {
        message = 'بريد إلكتروني غير صالح';
      }
      _showSnack(message, error: true);
    } catch (_) {
      _showSnack('حدث خطأ غير متوقع', error: true);
    } finally {
      if (mounted) setState(() => _loggingIn = false);
    }
  }

  /// اختياري: إنشاء حساب جديد بنفس البريد/الباس (يساعدك في التجربة)
  Future<void> _register() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showSnack('رجاءً أدخل بريدًا إلكترونيًا صالحًا', error: true);
      return;
    }
    if (pass.length < 6) {
      _showSnack('كلمة المرور يجب أن تكون 6 أحرف على الأقل', error: true);
      return;
    }

    setState(() => _loggingIn = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );
      _showSnack('تم إنشاء الحساب وتسجيل الدخول بنجاح');
    } on FirebaseAuthException catch (e) {
      String message = 'فشل إنشاء الحساب';
      if (e.code == 'email-already-in-use') {
        message = 'هذا البريد مستخدم بالفعل';
      } else if (e.code == 'weak-password') {
        message = 'كلمة المرور ضعيفة، اختر كلمة أقوى';
      }
      _showSnack(message, error: true);
    } catch (_) {
      _showSnack('حدث خطأ غير متوقع', error: true);
    } finally {
      if (mounted) setState(() => _loggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    final isDark = theme.isDark;

    final gradientColors = isDark
        ? const [Color(0xFF020617), Color(0xFF111827)]
        : const [Color(0xFFEEF2FF), Color(0xFFE0ECFF)];

    final cardColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.white.withOpacity(0.96);

    final borderColor = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.06);

    final labelColor = isDark
        ? Colors.white.withOpacity(0.9)
        : Colors.black.withOpacity(0.8);

    final hintColor = isDark
        ? Colors.white.withOpacity(0.5)
        : Colors.black.withOpacity(0.35);

    final inputFill = isDark
        ? Colors.white.withOpacity(0.04)
        : Colors.black.withOpacity(0.02);

    final titleColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // شريط علوي فيه زر تبديل الثيم فقط
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      const Spacer(),
                      IconButton(
                        onPressed: theme.toggleTheme,
                        icon: Icon(
                          isDark ? Icons.dark_mode : Icons.light_mode,
                          color: isDark ? Colors.white : Colors.black87,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // اسم التطبيق Mem بخط إنستغرامي بسيط (مائل وناعم)
                  Text(
                    'Mem',
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 42,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'قم بتسجيل الدخول باستخدام بريدك الإلكتروني',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withOpacity(0.8)
                          : Colors.black.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // البطاقة الرئيسية
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 22,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // البريد الإلكتروني
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'البريد الإلكتروني',
                            style: TextStyle(
                              color: labelColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            hintText: 'example@mail.com',
                            hintStyle: TextStyle(color: hintColor),
                            filled: true,
                            fillColor: inputFill,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF2563EB),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // كلمة المرور
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'كلمة المرور',
                            style: TextStyle(
                              color: labelColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            hintStyle: TextStyle(color: hintColor),
                            filled: true,
                            fillColor: inputFill,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 18,
                                color: hintColor,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF2563EB),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              _showSnack('نسيت كلمة المرور؟ فعّل reset من Firebase Console أو أضف زر لاحقاً.');
                            },
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 0),
                              minimumSize: const Size(0, 0),
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'هل نسيت كلمة المرور؟',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white.withOpacity(0.8)
                                    : const Color(0xFF2563EB),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        // زر تسجيل الدخول
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loggingIn ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _loggingIn
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation(
                                              Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'تسجيل الدخول',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // زر إنشاء حساب جديد (اختياري لكنه مفيد جداً بالتجربة)
                        TextButton(
                          onPressed: _loggingIn ? null : _register,
                          style: TextButton.styleFrom(
                            foregroundColor: isDark
                                ? Colors.white
                                : const Color(0xFF2563EB),
                          ),
                          child: const Text(
                            'إنشاء حساب جديد باستخدام نفس البيانات',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'هذه شاشة حقيقية تستخدم FirebaseAuth (بريد + كلمة مرور).\nباقي التطبيق يحدد أين تذهب بعد تسجيل الدخول.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withOpacity(0.7)
                          : Colors.black.withOpacity(0.6),
                      fontSize: 11,
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