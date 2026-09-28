import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/session/session_service.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/library_entry_model.dart';
import '../../../data/models/tracking_model.dart';
import '../../../data/services/library_service.dart';
import '../../../data/services/tracking_service.dart';

/// Takip tab: shows in progress, new/upcoming episodes, unreleased titles on
/// the watchlist, group matches. Refreshed whenever the tab is selected.
class TakipController extends GetxController {
  final TrackingService _trackingService = TrackingService();
  final LibraryService _libraryService = LibraryService();
  final SessionService _session = Get.find();

  final Rxn<TrackingModel> tracking = Rxn<TrackingModel>();
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;

  /// Entry ids with a "Sonraki" request in flight (disables the button).
  final RxSet<int> advancing = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload() async {
    final userId = _session.userId.value;
    if (userId == null) return;
    // Spinner only on the first load; later refreshes update in place.
    isLoading.value = tracking.value == null;
    try {
      tracking.value = await _trackingService.get(userId);
      hasError.value = false;
    } catch (_) {
      hasError.value = tracking.value == null;
    } finally {
      isLoading.value = false;
    }
  }

  /// "▶ Sonraki": logs the next episode server-side (which knows the season
  /// sizes) and offers to mark the show watched after the last aired one.
  Future<void> advanceEpisode(LibraryEntryModel entry) async {
    final userId = _session.userId.value;
    if (userId == null || !advancing.add(entry.id)) return;
    try {
      final result = await _libraryService.nextEpisode(entry.id, userId);
      _replaceContinue(entry.id, result.entry);
      if (result.finished) {
        Get.snackbar(
          'Diziyi bitirdin! 🎉',
          '${entry.title.name} için İzledim olarak işaretlemek ister misin?',
          duration: const Duration(seconds: 5),
          mainButton: TextButton(
            onPressed: () {
              Get.closeCurrentSnackbar();
              _markWatched(result.entry);
            },
            child: const Text('İşaretle'),
          ),
        );
      }
    } catch (_) {
      Get.snackbar('Olmadı', 'Bölüm kaydedilemedi, tekrar dene.');
    } finally {
      advancing.remove(entry.id);
    }
  }

  Future<void> _markWatched(LibraryEntryModel entry) async {
    try {
      await _libraryService.updateStatus(entry.id, LibraryStatus.watched);
      _replaceContinue(entry.id, null);
    } catch (_) {
      Get.snackbar('Olmadı', 'Kütüphane güncellenemedi, tekrar dene.');
    }
  }

  /// Swaps (or with null, drops) one "İzlemeye Devam Et" entry in place.
  void _replaceContinue(int entryId, LibraryEntryModel? replacement) {
    final current = tracking.value;
    if (current == null) return;
    tracking.value = TrackingModel(
      continueWatching: [
        for (final e in current.continueWatching)
          if (e.id != entryId) e else if (replacement != null) replacement,
      ],
      newEpisodes: current.newEpisodes,
      upcoming: current.upcoming,
      groupMatches: current.groupMatches,
    );
  }
}
