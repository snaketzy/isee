import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/mock_data.dart';
import '../../domain/entities/video_content.dart';

final homeCategoriesProvider = Provider<List<VideoCategory>>((ref) {
  return MockData.categories;
});

final allVideosProvider = Provider<List<VideoContent>>((ref) {
  return MockData.getAllVideos();
});

final videoByIdProvider = Provider.family<VideoContent?, String>((ref, id) {
  return MockData.getVideoById(id);
});

final heroBannerProvider = Provider<VideoContent>((ref) {
  final trending = MockData.categories.firstWhere((c) => c.id == 'cat_trending').videos;
  return trending.first;
});

final topTenProvider = Provider<List<VideoContent>>((ref) {
  final top = MockData.categories.firstWhere((c) => c.id == 'cat_top10').videos;
  return top..sort((a, b) => (a.topTenRank ?? 99).compareTo(b.topTenRank ?? 99));
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = Provider<List<VideoContent>>((ref) {
  final query = ref.watch(searchQueryProvider);
  return MockData.searchVideos(query);
});

final episodeByIndexProvider = Provider.family<Episode?, (String, int)>((ref, params) {
  final (videoId, index) = params;
  return MockData.findEpisode(videoId, index);
});
