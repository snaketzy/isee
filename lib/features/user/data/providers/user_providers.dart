import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/mock_data.dart';
import '../../../../core/models/video_quality.dart';
import '../../domain/entities/user_profile.dart';

final currentUserProvider = StateProvider<UserProfile>((ref) {
  return MockData.buildMockUser();
});

final membershipPlansProvider = Provider<List<MembershipPlan>>((ref) {
  return MockData.membershipPlans;
});

final myListProvider = Provider<List<String>>((ref) {
  return ref.watch(currentUserProvider).myListIds;
});

final isInMyListProvider = Provider.family<bool, String>((ref, videoId) {
  final list = ref.watch(myListProvider);
  return list.contains(videoId);
});

final watchProgressProvider = Provider.family<double?, String>((ref, videoKey) {
  final user = ref.watch(currentUserProvider);
  return user.watchProgress[videoKey];
});

final toggleMyListProvider =
    StateNotifierProvider<_MyListNotifier, List<String>>((ref) {
  final initial = ref.read(currentUserProvider).myListIds;
  return _MyListNotifier(initial, ref);
});

class _MyListNotifier extends StateNotifier<List<String>> {
  final Ref ref;
  _MyListNotifier(super.state, this.ref);

  void toggle(String videoId) {
    final user = ref.read(currentUserProvider);
    if (state.contains(videoId)) {
      state = state.where((id) => id != videoId).toList();
    } else {
      state = [...state, videoId];
    }
    ref.read(currentUserProvider.notifier).state = user.copyWith(
      myListIds: state,
    );
  }
}

extension on UserProfile {
  UserProfile copyWith({
    String? displayName,
    String? avatarUrl,
    VideoQuality? preferredQuality,
    bool? autoplayNext,
    bool? autoplayTrailers,
    List<String>? myListIds,
    Map<String, double>? watchProgress,
  }) {
    return UserProfile(
      id: id,
      email: email,
      phone: phone,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      language: language,
      preferredQuality: preferredQuality ?? this.preferredQuality,
      autoplayNext: autoplayNext ?? this.autoplayNext,
      autoplayTrailers: autoplayTrailers ?? this.autoplayTrailers,
      myListIds: myListIds ?? this.myListIds,
      watchProgress: watchProgress ?? this.watchProgress,
      membership: membership,
    );
  }
}
