import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/location_repository.dart';
import '../../domain/entities/user_location.dart';
import '../providers/providers.dart';
import '../widgets/location_card.dart';

/// 地点登録・検索画面
class LocationSearchScreen extends ConsumerStatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  ConsumerState<LocationSearchScreen> createState() =>
      _LocationSearchScreenState();
}

class _LocationSearchScreenState extends ConsumerState<LocationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserLocation> _searchResults = [];
  bool _isSearching = false;
  bool _isGettingLocation = false;
  String? _errorMessage;

  // オートコンプリート用
  Timer? _debounceTimer;
  bool _showSuggestions = false;
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// テキスト変更時のデバウンス処理
  void _onSearchTextChanged() {
    _debounceTimer?.cancel();
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSuggestions = false;
        _errorMessage = null;
      });
      return;
    }

    // 2文字以上で検索開始
    if (query.length >= 2) {
      _debounceTimer = Timer(_debounceDuration, () {
        _searchLocation(showSuggestions: true);
      });
    }
  }

  Future<void> _searchLocation({bool showSuggestions = false}) async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(locationRepositoryProvider);
      final results = await repository.searchByName(query);
      setState(() {
        _searchResults = results;
        _showSuggestions = showSuggestions && results.isNotEmpty;
        _isSearching = false;
      });
    } on LocationException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _showSuggestions = false;
        _isSearching = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(locationRepositoryProvider);
      final location = await repository.getCurrentLocation();
      await _addLocation(location);
    } on LocationException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  Future<void> _addLocation(UserLocation location) async {
    final added = await ref
        .read(locationsProvider.notifier)
        .addLocation(location);
    if (added) {
      ref.read(selectedLocationProvider.notifier).selectLocation(location.id);
      ref.read(selectedLocationProvider.notifier).refresh();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      setState(() {
        _errorMessage = '同じ地点が既に登録されています';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locations = ref.watch(locationsProvider);
    final selectedLocation = ref.watch(selectedLocationProvider);
    final isDarkMode = ref.watch(themeProvider);

    // テーマに応じた色
    final bgColor = isDarkMode
        ? AppTheme.backgroundColor
        : AppTheme.lightBackgroundColor;
    final surfaceColor = isDarkMode
        ? AppTheme.surfaceColor
        : AppTheme.lightSurfaceColor;
    final textPrimary = isDarkMode
        ? AppTheme.textPrimary
        : AppTheme.lightTextPrimary;
    final textMuted = isDarkMode ? AppTheme.textMuted : AppTheme.lightTextMuted;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '地点を管理',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // 検索バー
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 検索入力
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: textMuted.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            hintText: '都市名を入力（例: 東京、大阪）',
                            hintStyle: TextStyle(color: textMuted),
                            prefixIcon: Icon(Icons.search, color: textMuted),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            filled: true,
                            fillColor: surfaceColor,
                          ),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _searchLocation(),
                        ),
                      ),
                      if (_isSearching)
                        const Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        )
                      else
                        IconButton(
                          onPressed: _searchLocation,
                          icon: const Icon(
                            Icons.arrow_forward,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                    ],
                  ),
                ),

                // オートコンプリート候補ドロップダウン
                if (_showSuggestions && _searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final location = _searchResults[index];
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _showSuggestions = false;
                            });
                            _addLocation(location);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: index < _searchResults.length - 1
                                  ? Border(
                                      bottom: BorderSide(
                                        color: AppTheme.textMuted.withValues(
                                          alpha: 0.1,
                                        ),
                                        width: 1,
                                      ),
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: AppTheme.primaryColor,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        location.name,
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        location.coordinateString,
                                        style: const TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.add_circle_outline,
                                  color: AppTheme.accentColor,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 12),

                // 現在地取得ボタン
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isGettingLocation ? null : _getCurrentLocation,
                    icon: _isGettingLocation
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.accentColor,
                            ),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(_isGettingLocation ? '位置情報を取得中...' : '現在地を使用'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentColor,
                      side: const BorderSide(color: AppTheme.accentColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                // エラーメッセージ
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.dangerColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppTheme.dangerColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 検索結果
          if (_searchResults.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppTheme.textMuted, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '検索結果（${_searchResults.length}件）',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final location = _searchResults[index];
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 12),
                    child: LocationCard(
                      location: location,
                      onTap: () => _addLocation(location),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 登録済み地点
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.bookmark, color: AppTheme.textMuted, size: 16),
                const SizedBox(width: 8),
                Text(
                  '登録済みの地点（${locations.length}件）',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: locations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_location_alt_outlined,
                          size: 64,
                          color: AppTheme.textMuted.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '地点が登録されていません',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '上の検索バーから地点を追加してください',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: locations.length,
                    itemBuilder: (context, index) {
                      final location = locations[index];
                      final isSelected = selectedLocation?.id == location.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: LocationCard(
                          location: location,
                          isSelected: isSelected,
                          onTap: () {
                            ref
                                .read(selectedLocationProvider.notifier)
                                .selectLocation(location.id);
                            Navigator.of(context).pop();
                          },
                          onDelete: locations.length > 1
                              ? () => _confirmDelete(location)
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(UserLocation location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          '地点を削除',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          '「${location.name}」を削除しますか？',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(locationsProvider.notifier).removeLocation(location.id);
              ref.read(selectedLocationProvider.notifier).refresh();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}
