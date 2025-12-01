import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;

  late AnimationController _bgController;
  late Animation<Alignment> _bgAlignmentAnimation;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _bgAlignmentAnimation = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: Alignment.bottomRight,
          end: Alignment.topRight,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: AlignmentTween(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        weight: 1,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _bgController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(message),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showError('رجاءً أدخل بريدًا إلكترونيًا صحيحًا');
      return;
    }
    if (pass.length < 6) {
      _showError('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: pass,
        );
      } else {
        await _auth.createUserWithEmailAndPassword(
          email: email,
          password: pass,
        );
      }
      // عند النجاح RootScreen سيتعامل مع الانتقال لباقي التطبيق
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? e.code);
    } catch (_) {
      _showError('حدث خطأ غير متوقع، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedBuilder(
        animation: _bgAlignmentAnimation,
        builder: (context, _) {
          return Scaffold(
            body: Stack(
              children: [
                // خلفية متدرجة متحركة خفيفة
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: _bgAlignmentAnimation.value,
                      end: Alignment.centerRight,
                      colors: const [
                        Color(0xff2f80ed),
                        Color(0xff6c5ce7),
                        Color(0xfffd79a8),
                      ],
                    ),
                  ),
                ),

                // طبقة شفافة خفيفة فوق الخلفية
                Container(
                  color: Colors.white.withOpacity(0.08),
                ),

                // محتوى الشاشة (الكارد الزجاجي)
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 18,
                          sigmaY: 18,
                        ),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            color: Colors.white.withOpacity(0.20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // شعار mem في الأعلى
                              const Text(
                                'mem',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 3,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _isLoginMode
                                    ? 'مرحباً بعودتك 👋'
                                    : 'أنشئ حساباً جديداً وابدأ الدردشة',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // تبويب (تسجيل دخول / إنشاء حساب)
                              _buildAuthTabs(),

                              const SizedBox(height: 20),

                              // حقول الإدخال (إيميل + كلمة مرور)
                              _buildForm(),

                              const SizedBox(height: 18),

                              // زر الإرسال
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _submit,
                                  icon: const Icon(
                                    Icons.mail_outline_rounded,
                                    size: 22,
                                  ),
                                  label: Text(
                                    _isLoginMode
                                        ? 'تسجيل الدخول'
                                        : 'إنشاء حساب جديد',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                    backgroundColor:
                                        Colors.white.withOpacity(0.18),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              if (_isLoading)
                                const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),

                              const SizedBox(height: 8),

                              // تبديل بين تسجيل الدخول وإنشاء حساب
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        setState(
                                          () => _isLoginMode = !_isLoginMode,
                                        );
                                      },
                                child: Text(
                                  _isLoginMode
                                      ? 'ما عندك حساب؟ أنشئ حساب الآن'
                                      : 'عندك حساب مسبقاً؟ سجّل الدخول',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.9),
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
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAuthTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _GlassTabButton(
            title: 'تسجيل الدخول',
            isActive: _isLoginMode,
            onTap: () {
              if (!_isLoginMode) {
                setState(() => _isLoginMode = true);
              }
            },
          ),
          _GlassTabButton(
            title: 'إنشاء حساب',
            isActive: !_isLoginMode,
            onTap: () {
              if (_isLoginMode) {
                setState(() => _isLoginMode = false);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'البريد الإلكتروني',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        _GlassTextField(
          controller: _emailController,
          hintText: 'example@email.com',
          keyboardType: TextInputType.emailAddress,
          icon: Icons.alternate_email_rounded,
        ),
        const SizedBox(height: 14),
        const Text(
          'كلمة المرور',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        _GlassTextField(
          controller: _passwordController,
          hintText: '••••••••',
          obscure: true,
          icon: Icons.lock_rounded,
        ),
      ],
    );
  }
}

class _GlassTabButton extends StatelessWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _GlassTabButton({
    required this.title,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isActive
                ? Colors.white.withOpacity(0.4)
                : Colors.transparent,
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? const Color(0xff2d3436)
                    : Colors.white.withOpacity(0.9),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;

  const _GlassTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 13,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.16),
        prefixIcon: Icon(
          icon,
          color: Colors.white.withOpacity(0.9),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30), // شكل دائري (pill)
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}