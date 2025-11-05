import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/theme.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Récupérer le nombre total de tâches dans Firestore
  // Compte seulement les tâches publiques (accessibles sans auth)
  Future<int> _getTotalTasksCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('todos')
          .where('isPublic', isEqualTo: true)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('LandingPage: Erreur lors du comptage des tâches - $e');
      return 0;
    }
  }

  // Récupérer le nombre d'utilisateurs inscrits (via leurs tâches)
  Future<int> _getActiveUsersCount() async {
    try {
      // Compter les userId uniques dans toutes les tâches
      final snapshot = await FirebaseFirestore.instance
          .collection('todos')
          .get();
      
      final uniqueUsers = <String>{};
      for (var doc in snapshot.docs) {
        final userId = doc.data()['userId'] as String?;
        if (userId != null) {
          uniqueUsers.add(userId);
        }
      }
      
      return uniqueUsers.length;
    } catch (e) {
      print('LandingPage: Erreur lors du comptage des utilisateurs - $e');
      return 0;
    }
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        alignment: 0.0, // Aligner en haut
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                _buildHeroSection(context),
                _buildFeaturesSection(context),
                _buildAboutSection(context),
                _buildCTASection(context),
                _buildFooter(context),
              ],
            ),
          ),
          _buildNavBar(context),
        ],
      ),
    );
  }

  Widget _buildNavBar(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              // Logo + Nom
              InkWell(
                onTap: () => _scrollToSection(_heroKey),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/Taskip_logo.png',
                      height: 40,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          PhosphorIconsBold.checkSquare,
                          size: 40,
                          color: AppColors.primaryRose,
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Taskip',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.primaryRose,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Navigation Links
              if (MediaQuery.of(context).size.width > 768) ...[
                _buildNavLink(context, 'Accueil', () => _scrollToSection(_heroKey)),
                const SizedBox(width: 32),
                _buildNavLink(context, 'Fonctionnalités', () => _scrollToSection(_featuresKey)),
                const SizedBox(width: 32),
                _buildNavLink(context, 'À propos', () => _scrollToSection(_aboutKey)),
                const SizedBox(width: 32),
              ],
              
              // CTA Buttons
              if (MediaQuery.of(context).size.width > 600) ...[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text('Connexion'),
                ),
                const SizedBox(width: 12),
              ],
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
                icon: Icon(
                  PhosphorIconsBold.userPlus,
                  size: 18,
                ),
                label: const Text('Commencer'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavLink(BuildContext context, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.grey700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      key: _heroKey,
      height: screenHeight, // Prend toute la hauteur de l'écran
      padding: const EdgeInsets.only(
        top: 80, // Espace pour la navbar
        left: 24,
        right: 24,
        bottom: 40,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            children: [
              // Contenu gauche
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40), // Espace supplémentaire en haut du contenu
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accentCream,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIconsBold.sparkle,
                            size: 16,
                            color: AppColors.primaryRose,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Nouvelle expérience de productivité',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.primaryRose,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Titre principal
                    Text(
                      'Gérez vos tâches\navec élégance',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppColors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 56,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Sous-titre
                    Text(
                      'Taskip est votre compagnon de productivité quotidien.\nSimple, élégant et puissant.',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.grey600,
                        fontWeight: FontWeight.normal,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // CTA Buttons
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          icon: Icon(PhosphorIconsBold.rocketLaunch),
                          label: const Text('Commencer gratuitement'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 20,
                            ),
                            minimumSize: const Size(220, 60),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          icon: Icon(PhosphorIconsBold.signIn),
                          label: const Text('Se connecter'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 20,
                            ),
                            minimumSize: const Size(200, 60),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Stats avec compteurs chargés au refresh
                    FutureBuilder<List<int>>(
                      future: Future.wait([
                        _getActiveUsersCount(),
                        _getTotalTasksCount(),
                      ]),
                      builder: (context, snapshot) {
                        String usersCount = '...';
                        String tasksCount = '...';
                        
                        if (snapshot.connectionState == ConnectionState.done) {
                          if (snapshot.hasError) {
                            print('LandingPage: Erreur chargement stats - ${snapshot.error}');
                            usersCount = '0';
                            tasksCount = '0';
                          } else if (snapshot.hasData) {
                            usersCount = '${snapshot.data![0]}';
                            tasksCount = '${snapshot.data![1]}';
                          }
                        }
                        
                        return Row(
                          children: [
                            _buildStatItem(context, usersCount, 'Utilisateurs inscrits'),
                            const SizedBox(width: 48),
                            _buildStatItem(context, tasksCount, 'Tâches créées'),
                            const SizedBox(width: 48),
                            _buildStatItem(context, '4.9★', 'Note moyenne'),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                ),
              ),
              
              // Image/Illustration droite
              if (MediaQuery.of(context).size.width > 900)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Cercle de fond
                        Container(
                          width: 400,
                          height: 400,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.secondaryBeige.withOpacity(0.3),
                                AppColors.accentCream.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                        // Logo
                        Image.asset(
                          'assets/images/Taskip_logo.png',
                          height: 300,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              PhosphorIconsBold.checkSquare,
                              size: 300,
                              color: AppColors.primaryRose,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.primaryRose,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.grey600,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      key: _featuresKey,
      constraints: BoxConstraints(
        minHeight: screenHeight, // Hauteur minimale = écran complet
      ),
      padding: const EdgeInsets.only(
        top: 100, // Plus d'espace en haut pour compenser la navbar
        left: 24,
        right: 24,
        bottom: 80,
      ),
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Section header
              Text(
                'Tout ce dont vous avez besoin',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.black,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              Text(
                'Des fonctionnalités puissantes pour une productivité maximale',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.grey600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
              
              // Grid de features
              Wrap(
                spacing: 32,
                runSpacing: 32,
                alignment: WrapAlignment.center,
                children: [
                  _buildFeatureCard(
                    context,
                    icon: PhosphorIconsBold.cloudCheck,
                    title: 'Synchronisation Cloud',
                    description: 'Accédez à vos tâches partout, tout le temps grâce à Firebase',
                    color: AppColors.primaryRose,
                  ),
                  _buildFeatureCard(
                    context,
                    icon: PhosphorIconsBold.lightning,
                    title: 'Temps Réel',
                    description: 'Vos modifications sont instantanément synchronisées',
                    color: AppColors.warning,
                  ),
                  _buildFeatureCard(
                    context,
                    icon: PhosphorIconsBold.lockKey,
                    title: 'Sécurisé',
                    description: 'Vos données sont protégées avec Firebase Authentication',
                    color: AppColors.success,
                  ),
                  _buildFeatureCard(
                    context,
                    icon: PhosphorIconsBold.paintBrush,
                    title: 'Interface Élégante',
                    description: 'Un design moderne et intuitif pour une expérience agréable',
                    color: AppColors.tertiaryMauve,
                  ),
                  _buildFeatureCard(
                    context,
                    icon: PhosphorIconsBold.magnifyingGlass,
                    title: 'Recherche Avancée',
                    description: 'Trouvez rapidement n\'importe quelle tâche',
                    color: AppColors.info,
                  ),
                  _buildFeatureCard(
                    context,
                    icon: PhosphorIconsBold.funnel,
                    title: 'Filtres Intelligents',
                    description: 'Organisez vos tâches par statut et priorité',
                    color: AppColors.secondaryBeige,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      key: _aboutKey,
      constraints: BoxConstraints(
        minHeight: screenHeight, // Hauteur minimale = écran complet
      ),
      padding: const EdgeInsets.only(
        top: 100, // Plus d'espace en haut pour compenser la navbar
        left: 24,
        right: 24,
        bottom: 80,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentCream.withOpacity(0.3),
            AppColors.secondaryBeige.withOpacity(0.3),
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            children: [
              // Image/Illustration
              if (MediaQuery.of(context).size.width > 900)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    child: Icon(
                      PhosphorIconsBold.usersThree,
                      size: 300,
                      color: AppColors.primaryRose.withOpacity(0.3),
                    ),
                  ),
                ),
              
              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pourquoi Taskip ?',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      'Taskip a été conçu pour les étudiants et professionnels qui veulent maximiser leur productivité sans sacrifier l\'élégance.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.grey700,
                        height: 1.8,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    _buildAboutItem(
                      context,
                      icon: PhosphorIconsBold.trophy,
                      title: 'Projet EFREI M2',
                      description: 'Développé dans le cadre du cours de Flutter avec le professeur Jérôme Commaret',
                    ),
                    const SizedBox(height: 20),
                    
                    _buildAboutItem(
                      context,
                      icon: PhosphorIconsBold.code,
                      title: 'Technologies Modernes',
                      description: 'Flutter, Firebase, Provider pour une architecture robuste',
                    ),
                    const SizedBox(height: 20),
                    
                    _buildAboutItem(
                      context,
                      icon: PhosphorIconsBold.heart,
                      title: 'Fait avec passion',
                      description: 'Chaque détail a été pensé pour votre confort',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryRose.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 24,
            color: AppColors.primaryRose,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 48,
              color: color,
            ),
          ),
          const SizedBox(height: 20),
          
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.grey600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCTASection(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      constraints: BoxConstraints(
        minHeight: screenHeight, // Hauteur minimale = écran complet
      ),
      padding: const EdgeInsets.only(
        top: 100, // Plus d'espace en haut pour compenser la navbar
        left: 24,
        right: 24,
        bottom: 80,
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Icon(
            PhosphorIconsBold.rocketLaunch,
            size: 80,
            color: AppColors.primaryRose,
          ),
          const SizedBox(height: 24),
          
          Text(
            'Prêt à booster votre productivité ?',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppColors.black,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          Text(
            'Rejoignez des milliers d\'utilisateurs qui organisent leur vie avec Taskip',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.grey700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RegisterScreen(),
                ),
              );
            },
            icon: Icon(PhosphorIconsBold.arrowRight),
            label: const Text('Créer un compte gratuitement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRose,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 24,
              ),
              minimumSize: const Size(250, 70),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      color: AppColors.black,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIconsBold.checkSquare,
                color: AppColors.primaryRose,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                'Taskip',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Text(
            'EFREI M2 - Projet Flutter TodoList',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          
          Text(
            'Réalisé par Thibault DELATTRE, Quang HOANG, Jie FAN, Florent LELION',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          IconButton(
            onPressed: () async {
              final url = Uri.parse('https://github.com/Quanghng/efrei-flutter-todolist');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            icon: Icon(PhosphorIconsBold.githubLogo),
            color: Colors.white.withOpacity(0.7),
            iconSize: 32,
            tooltip: 'Voir le code sur GitHub',
          ),
          const SizedBox(height: 16),
          
          Text(
            '© 2025 Taskip. Tous droits réservés.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
