import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/talent_model.dart';
import '../data/repositories/talent_repository.dart';

final talentRepositoryProvider = Provider<TalentRepository>((ref) {
  return TalentRepository();
});

final talentsProvider =
    StateNotifierProvider<TalentNotifier, AsyncValue<List<Talent>>>(
  (ref) => TalentNotifier(ref),
);

final userTalentsProvider =
    Provider.family<AsyncValue<List<Talent>>, String>((ref, userId) {
  final talents = ref.watch(talentsProvider);

  return talents.when(
    data: (allTalents) {
      final userTalents =
          allTalents.where((talent) => talent.userId == userId).toList();
      return AsyncValue.data(userTalents);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

final talentProvider =
    Provider.family<AsyncValue<Talent?>, String>((ref, talentId) {
  final talents = ref.watch(talentsProvider);

  return talents.when(
    data: (allTalents) {
      try {
        final talent = allTalents.firstWhere((t) => t.id == talentId);
        return AsyncValue.data(talent);
      } catch (e) {
        return const AsyncValue.data(null);
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

class TalentNotifier extends StateNotifier<AsyncValue<List<Talent>>> {
  final Ref ref;
  late final TalentRepository _talentRepository;

  TalentNotifier(this.ref) : super(const AsyncValue.loading()) {
    _talentRepository = ref.read(talentRepositoryProvider);
    _loadTalents();
  }

  Future<void> _loadTalents() async {
    try {
      state = const AsyncValue.loading();
      final talents = await _talentRepository.getTalents();
      state = AsyncValue.data(talents);
    } catch (e) {
      print('⚠️ Failed to load talents from backend: $e');
      // Show empty list on initial load failure so the app remains usable
      if (state.value == null) {
        state = const AsyncValue.data([]);
      }
      // If we already had data, keep it
    }
  }

  /// Add a talent via multipart backend call
  Future<void> addTalent({
    required String title,
    required String description,
    required String category,
    required String level,
    required String userId,
    required String userName,
    required String userAvatar,
    required String institution,
    required List<String> tags,
    required List<Achievement> achievements,
    List<File> images = const [],
    List<Uint8List> imagesBytes = const [],
    List<File> certificates = const [],
    List<Uint8List> certificatesBytes = const [],
  }) async {
    try {
      await _talentRepository.addTalent(
        title: title,
        description: description,
        category: category,
        level: level,
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        institution: institution,
        tags: tags,
        achievements: achievements,
        images: images,
        imagesBytes: imagesBytes,
        certificates: certificates,
        certificatesBytes: certificatesBytes,
      );

      // Refresh talents list from backend after adding
      await _loadTalents();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refreshTalents() async {
    state = const AsyncValue.loading();
    await _loadTalents();
  }

  Future<void> deletePost(String talentId, String userId) async {
    try {
      await _talentRepository.deleteTalent(talentId, userId);
      // Update local state by removing the deleted talent
      state = AsyncValue.data(
        state.value?.where((t) => t.id != talentId).toList() ?? [],
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePost(
      String talentId, String userId, Map<String, dynamic> updateData) async {
    try {
      await _talentRepository.updateTalent(talentId, userId, updateData);
      // Refresh to get updated data
      await _loadTalents();
    } catch (e) {
      rethrow;
    }
  }
}