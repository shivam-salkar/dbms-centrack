import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const bool enableDemoLogin = true; // Toggle for development demo helper

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _showError = false;
  String _errorMessage = 'Invalid credentials. Try again.';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillDemoCredentials({required String email, required String password}) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
      _showError = false;
    });
  }

  void _handleLogin() async {
    setState(() {
      _showError = false;
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final officer = await SupabaseService.signIn(
      email: email,
      password: password,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (officer != null) {
      context.read<AppState>().login(officer);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      setState(() {
        _showError = true;
        _errorMessage = 'Invalid credentials or connection issue. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().isDarkMode;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: size.height - MediaQuery.of(context).padding.top),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),

                    // Emblem
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.08),
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: const Icon(
                        Icons.account_balance,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // App Name
                    Text(
                      'Census Tracker',
                      style: GoogleFonts.notoSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'National Population Register System (Jangana)',
                      style: GoogleFonts.notoSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),
                    Container(
                      height: 3,
                      width: 60,
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 24),

                    // Error Banner
                    if (_showError)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.error),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: GoogleFonts.notoSans(
                                  fontSize: 13,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email Address',
                            style: GoogleFonts.notoSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.notoSans(fontSize: 14),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.email_outlined, size: 20),
                              hintText: 'Enter your email',
                            ),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Password',
                            style: GoogleFonts.notoSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: GoogleFonts.notoSans(fontSize: 14),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock_outline, size: 20),
                              hintText: 'Enter your password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                            onFieldSubmitted: (_) => _handleLogin(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Login Securely',
                                style: GoogleFonts.notoSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    // ── Development Quick Demo Login ──
                    if (enableDemoLogin) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF222222) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.flash_on, size: 14, color: AppColors.accent),
                                const SizedBox(width: 4),
                                Text(
                                  'Quick Demo Login (Academic Demo)',
                                  style: GoogleFonts.notoSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                ActionChip(
                                  label: Text(
                                    'Admin',
                                    style: GoogleFonts.notoSans(fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                  avatar: const Icon(Icons.admin_panel_settings, size: 14),
                                  onPressed: () => _fillDemoCredentials(
                                    email: 'admin.demo@janganatest.local',
                                    password: 'JanganaDemo@2026',
                                  ),
                                ),
                                ActionChip(
                                  label: Text(
                                    'Enumerator 1',
                                    style: GoogleFonts.notoSans(fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                  avatar: const Icon(Icons.person, size: 14),
                                  onPressed: () => _fillDemoCredentials(
                                    email: 'enumerator1.demo@janganatest.local',
                                    password: 'JanganaEnum@2026',
                                  ),
                                ),
                                ActionChip(
                                  label: Text(
                                    'Enumerator 2',
                                    style: GoogleFonts.notoSans(fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                  avatar: const Icon(Icons.person_outline, size: 14),
                                  onPressed: () => _fillDemoCredentials(
                                    email: 'enumerator2.demo@janganatest.local',
                                    password: 'JanganaEnum2@2026',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Dark mode toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isDark ? Icons.light_mode : Icons.dark_mode,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isDark ? 'Light Mode' : 'Dark Mode',
                          style: GoogleFonts.notoSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Switch(
                          value: isDark,
                          onChanged: (_) => context.read<AppState>().toggleDarkMode(),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Footer
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Strictly Confidential | Government of India | Ministry of Home Affairs',
                      style: GoogleFonts.notoSans(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
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
