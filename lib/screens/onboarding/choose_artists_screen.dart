import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/track.dart';
import '../../services/deezer_api_service.dart';
import '../../services/preferences_service.dart';
import '../../theme/app_theme.dart';
import 'choose_podcasts_screen.dart';

class ChooseArtistsScreen extends StatefulWidget {
  const ChooseArtistsScreen({super.key});

  @override
  State<ChooseArtistsScreen> createState() => _ChooseArtistsScreenState();
}

class _ChooseArtistsScreenState extends State<ChooseArtistsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  List<Track> _searchResults = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeezerApiService>().fetchChart();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearch(String value) async {
    setState(() => _query = value);
    if (value.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    final results = await context.read<DeezerApiService>().search(value);
    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _searching = false;
    });
  }

  List<String> _artists(List<Track> chart) {
    final source = _query.trim().isEmpty ? chart : _searchResults;
    return {for (final track in source) track.artist}.where((artist) => artist.trim().isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesService>();
    final chart = context.watch<DeezerApiService>().chartTracks;
    final artists = _artists(chart);
    final selected = prefs.selectedArtists;
    final canContinue = selected.length >= 3;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                'Choose 3 or more artists you like.',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search artists',
                  hintStyle: const TextStyle(color: Color(0xFFB3B3B3)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFB3B3B3)),
                  filled: true,
                  fillColor: const Color(0xFF242424),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _searching || artists.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.musikAccent))
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: artists.length,
                      itemBuilder: (context, i) {
                        final artist = artists[i];
                        final isSelected = selected.contains(artist);
                        return _ArtistTile(
                          name: artist,
                          isSelected: isSelected,
                          onTap: () => prefs.toggleArtist(artist),
                        );
                      },
                    ),
            ),
            if (canContinue)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ChoosePodcastsScreen()),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.musikAccent,
                      foregroundColor: Colors.black,
                      shape: const StadiumBorder(),
                    ),
                    child: Text('Continue (${selected.length})'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ArtistTile extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _ArtistTile({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.surfaceHighlight,
                    border: isSelected ? Border.all(color: AppColors.musikAccent, width: 3) : null,
                    boxShadow: isSelected
                        ? [BoxShadow(color: AppColors.musikAccent.withValues(alpha: 0.4), blurRadius: 12)]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white70),
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: AppColors.musikAccent, shape: BoxShape.circle),
                      child: const Icon(Icons.check, size: 16, color: Colors.black),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.musikAccent : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}


