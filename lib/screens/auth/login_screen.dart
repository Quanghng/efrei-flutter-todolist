import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../home_screen.dart';
import '../landing_page.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();

      final success = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        // Redirection vers la page HomeScreen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connexion réussie ! Bienvenue 👋'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Erreur de connexion'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: AppColors.accentCream,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
            ),
          ),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                // AppBar with back button
                if (isDesktop)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            PhosphorIconsBold.arrowLeft,
                            color: AppColors.primaryRose,
                            size: 24,
                          ),
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LandingPage()),
                              (route) => false,
                            );
                          },
                          tooltip: 'Retour',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Main content
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: isDesktop ? const NeverScrollableScrollPhysics() : null,
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 32 : 24,
                        vertical: isDesktop ? 0 : 24,
                      ),
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: 480,
                          minHeight: isDesktop ? screenHeight - 120 : 0,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Back button mobile
                            if (!isDesktop) ...[
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      PhosphorIconsBold.arrowLeft,
                                      color: AppColors.primaryRose,
                                      size: 24,
                                    ),
                                    onPressed: () {
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(builder: (context) => const LandingPage()),
                                        (route) => false,
                                      );
                                    },
                                    tooltip: 'Retour',
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            // Logo
                            Container(
                              width: isDesktop ? 100 : 80,
                              height: isDesktop ? 100 : 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: AppTheme.mediumShadow,
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Image.asset(
                                'assets/images/Taskip_logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            SizedBox(height: isDesktop ? 32 : 24),

                            // Card
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: AppTheme.mediumShadow,
                              ),
                              padding: EdgeInsets.all(isDesktop ? 48 : 32),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Titre
                                    Text(
                                      'Bon retour !',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: isDesktop ? 36 : 32,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryRose,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Connectez-vous à votre compte Taskip',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppColors.grey600,
                                      ),
                                    ),
                                    SizedBox(height: isDesktop ? 40 : 32),

                                    // Email
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      style: TextStyle(
                                        color: AppColors.black,
                                        fontSize: 16,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        hintText: 'exemple@email.com',
                                        prefixIcon: Icon(
                                          PhosphorIconsBold.envelope,
                                          color: AppColors.primaryRose,
                                        ),
                                        filled: true,
                                        fillColor: AppColors.grey100,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: AppColors.grey200,
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: AppColors.primaryRose,
                                            width: 2,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: AppColors.error,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Veuillez saisir votre email';
                                        }
                                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                          return 'Format d\'email invalide';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    // Mot de passe
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      style: TextStyle(
                                        color: AppColors.black,
                                        fontSize: 16,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Mot de passe',
                                        hintText: '••••••••',
                                        prefixIcon: Icon(
                                          PhosphorIconsBold.lock,
                                          color: AppColors.primaryRose,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword 
                                                ? PhosphorIconsBold.eye 
                                                : PhosphorIconsBold.eyeSlash,
                                            color: AppColors.grey600,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword = !_obscurePassword;
                                            });
                                          },
                                        ),
                                        filled: true,
                                        fillColor: AppColors.grey100,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: AppColors.grey200,
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: AppColors.primaryRose,
                                            width: 2,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: AppColors.error,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Veuillez saisir votre mot de passe';
                                        }
                                        if (value.length < 6) {
                                          return 'Le mot de passe doit contenir au moins 6 caractères';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: isDesktop ? 32 : 24),

                                    // Bouton de connexion
                                    Consumer<AuthProvider>(
                                      builder: (context, authProvider, _) {
                                        return Container(
                                          height: 56,
                                          decoration: BoxDecoration(
                                            gradient: AppTheme.primaryGradient,
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: AppTheme.softShadow,
                                          ),
                                          child: ElevatedButton(
                                            onPressed: authProvider.isLoading ? null : _handleLogin,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              foregroundColor: Colors.white,
                                              shadowColor: Colors.transparent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: authProvider.isLoading
                                                ? SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2.5,
                                                    ),
                                                  )
                                                : Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        PhosphorIconsBold.signIn,
                                                        size: 22,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Text(
                                                        'Se connecter',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        );
                                      },
                                    ),
                                    SizedBox(height: isDesktop ? 24 : 20),

                                    // Divider
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: AppColors.grey300,
                                            thickness: 1,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Text(
                                            'ou',
                                            style: TextStyle(
                                              color: AppColors.grey600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: AppColors.grey300,
                                            thickness: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: isDesktop ? 24 : 20),

                                    // Lien vers l'inscription
                                    OutlinedButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => const RegisterScreen(),
                                          ),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primaryRose,
                                        side: BorderSide(
                                          color: AppColors.primaryRose,
                                          width: 2,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            PhosphorIconsBold.userPlus,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Pas de compte ? S\'inscrire',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (!isDesktop) ...[
                              const SizedBox(height: 24),
                              
                              // Footer mobile uniquement
                              Text(
                                '© 2024 Taskip - Tous droits réservés',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grey600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
