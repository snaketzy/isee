import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../content/domain/entities/video_content.dart';
import '../repositories/admin_mock_repository.dart';

final adminContentListProvider =
    StateNotifierProvider<AdminContentListNotifier, List<VideoContent>>((ref) {
  return AdminContentListNotifier();
});

class AdminContentListNotifier extends StateNotifier<List<VideoContent>> {
  AdminContentListNotifier()
      : super(AdminMockRepository.instance.getAllContent());

  void refresh() {
    state = AdminMockRepository.instance.getAllContent();
  }

  void upsert(VideoContent content) {
    AdminMockRepository.instance.upsertContent(content);
    state = AdminMockRepository.instance.getAllContent();
  }

  void delete(String id) {
    AdminMockRepository.instance.deleteContent(id);
    state = AdminMockRepository.instance.getAllContent();
  }

  void updateStatus(List<String> ids, ContentStatus status) {
    AdminMockRepository.instance.updateContentStatus(ids, status);
    state = AdminMockRepository.instance.getAllContent();
  }

  VideoContent? getById(String id) {
    return AdminMockRepository.instance.getContentById(id);
  }
}

final adminCategoriesProvider =
    StateNotifierProvider<AdminCategoriesNotifier, List<VideoCategory>>((ref) {
  return AdminCategoriesNotifier();
});

class AdminCategoriesNotifier extends StateNotifier<List<VideoCategory>> {
  AdminCategoriesNotifier()
      : super(AdminMockRepository.instance.getAllCategories());

  void refresh() {
    state = AdminMockRepository.instance.getAllCategories();
  }

  void update(VideoCategory category) {
    AdminMockRepository.instance.updateCategory(category);
    state = AdminMockRepository.instance.getAllCategories();
  }

  void reorder(int oldIndex, int newIndex) {
    AdminMockRepository.instance.reorderCategories(oldIndex, newIndex);
    state = AdminMockRepository.instance.getAllCategories();
  }
}
