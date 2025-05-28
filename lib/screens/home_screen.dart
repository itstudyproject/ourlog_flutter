import 'package:flutter/material.dart';
import 'package:ourlog/widgets/artwork_slider.dart';
import 'package:ourlog/widgets/bulletin_board.dart';
import 'package:ourlog/widgets/main_banner.dart';

import '../constants/theme.dart';
import '../widgets/footer.dart';
import '../widgets/header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  final PageController _pageController = PageController();
  final PageController _artistPageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadArtworks();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _artistPageController.dispose();
    super.dispose();
  }

  void _loadArtworks() {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
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
                        children: const [
                          MainBanner(),
                          ArtworkSlider(),
                          BulletinBoard(),
                          Footer(),
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
