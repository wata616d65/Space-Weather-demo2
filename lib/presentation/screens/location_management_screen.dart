import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/user_location.dart';
import '../providers/providers.dart';
import 'location_search_screen.dart';

class LocationManagementScreen extends ConsumerStatefulWidget {
  const LocationManagementScreen({super.key});

  @override
  ConsumerState<LocationManagementScreen> createState() =>
      _LocationManagementScreenState();
}

class _LocationManagementScreenState
    extends ConsumerState<LocationManagementScreen> {
  List<UserLocation> _locations = [];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  void _loadLocations() {
    final repository = ref.read(locationRepositoryProvider);
    setState(() {
      _locations = repository.getLocations();
    });
  }

  Future<void> _updateLocations(List<UserLocation> updatedLocations) async {
    setState(() {
      _locations = updatedLocations;
    });
    final repository = ref.read(locationRepositoryProvider);
    await repository.reorderLocations(updatedLocations);
  }

  Future<void> _deleteLocation(UserLocation location) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('地点の削除'),
        content: Text('${location.name}を削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repository = ref.read(locationRepositoryProvider);
      await repository.removeLocation(location.id);
      _loadLocations();

      // もし選択中の地点を削除した場合は、有効な地点が存在すればそれを選択
      final currentSelected = ref.read(selectedLocationProvider);
      if (currentSelected?.id == location.id) {
        final remaining = repository.getLocations();
        if (remaining.isNotEmpty) {
          ref
              .read(selectedLocationProvider.notifier)
              .selectLocation(remaining.first.id);
        } else {
          // 残りがない場合はnullセット（プロバイダー側で処理される想定）
          // 実際にはStateNotifierのメソッドが必要
          ref.invalidate(selectedLocationProvider);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '地点管理',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.accentColor),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LocationSearchScreen(),
                ),
              );
              _loadLocations(); // 戻ってきたら再読み込み
            },
          ),
        ],
      ),
      body: _locations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_off_outlined,
                    size: 64,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '登録された地点はありません',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LocationSearchScreen(),
                        ),
                      );
                      _loadLocations();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('地点を追加'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _locations.length,
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final item = _locations.removeAt(oldIndex);
                final updatedLocations = List<UserLocation>.from(_locations)
                  ..insert(newIndex, item);
                _updateLocations(updatedLocations);
              },
              itemBuilder: (context, index) {
                final location = _locations[index];
                return Card(
                  key: ValueKey(location.id),
                  margin: const EdgeInsets.only(bottom: 12),
                  color: AppTheme.surfaceColor,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: const Icon(
                      Icons.drag_handle,
                      color: AppTheme.textMuted,
                    ),
                    title: Text(
                      location.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      location.isCurrentLocation
                          ? '現在地・${location.coordinateString}'
                          : location.coordinateString,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppTheme.textMuted,
                      ),
                      onPressed: () => _deleteLocation(location),
                    ),
                    onTap: () {
                      // 選択して戻る
                      ref
                          .read(selectedLocationProvider.notifier)
                          .selectLocation(location.id);
                      Navigator.of(context).pop();
                    },
                  ),
                );
              },
            ),
    );
  }
}
