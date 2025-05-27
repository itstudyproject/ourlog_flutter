import 'package:flutter/material.dart';
import 'package:ourlog/widgets/artwork_slider.dart';
import 'package:ourlog/widgets/bulletin_board.dart';
import 'package:ourlog/widgets/main_banner.dart';
import '../models/artwork.dart';
import '../services/artwork_service.dart';
import '../constants/theme.dart';
import '../widgets/header.dart';
import '../widgets/footer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Artwork> _artworks;
  bool _isLoading = true;
  int _currentSlideIndex = 0;
  int _currentArtistSlideIndex = 0;
  final PageController _pageController = PageController();
  final PageController _artistPageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadArtworks();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _nextSlide();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _artistPageController.dispose();
    super.dispose();
  }

  void _nextSlide() {
    if (!mounted) return;

    setState(() {
      _currentSlideIndex =
          (_currentSlideIndex + 1) % (_artworks.length > 3 ? 3 : _artworks.length);
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentSlideIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _nextSlide();
      }
    });
  }

  void _loadArtworks() {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      _artworks = ArtworkService.getArtworks();
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
              : SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Header(key: Key('header')),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      _loadArtworks();
                    },
                    color: AppTheme.primaryColor,
                    backgroundColor: Colors.black,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const MainBanner(),
                          ArtworkSlider(artwork: []),
                          const BulletinBoard(),
                          const Footer(),
                        ],
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
