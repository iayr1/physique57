import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/announcements/data/announcement_repository.dart';
import '../features/announcements/domain/announcement_model.dart';

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepository();
});

final announcementsStreamProvider = StreamProvider<List<AnnouncementModel>>((ref) {
  final repo = ref.watch(announcementRepositoryProvider);
  return repo.getAnnouncementsStream();
});
