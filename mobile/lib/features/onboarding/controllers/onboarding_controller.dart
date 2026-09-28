import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/session/session_service.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/genre_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/titles_service.dart';
import '../../../data/services/user_service.dart';
import '../../swipe/controllers/swipe_controller.dart';

class OnboardingController extends GetxController {
  final TitlesService _titlesService = TitlesService();
  final UserService _userService = UserService();
  final SessionService _session = Get.find();

  final RxList<GenreModel> genres = <GenreModel>[].obs;
  final RxSet<int> selectedGenreIds = <int>{}.obs;
  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;

  static const minSelection = 3;

  /// Opened from the profile ("Tür Tercihlerim") rather than after sign-up:
  /// pre-selects the saved genres and returns to the previous screen on save.
  /// Pass `arguments: {'edit': true}` when navigating.
  late final bool isEditing =
      Get.arguments is Map && (Get.arguments as Map)['edit'] == true;

  @override
  void onInit() {
    super.onInit();
    _loadGenres();
  }

  Future<void> _loadGenres() async {
    isLoading.value = true;
    try {
      final userId = _session.userId.value;
      final results = await Future.wait([
        _titlesService.getGenres(MediaType.movie),
        if (isEditing && userId != null) _userService.getById(userId),
      ]);
      genres.value = results[0] as List<GenreModel>;
      if (results.length > 1) {
        selectedGenreIds.addAll((results[1] as UserModel).preferredGenreIds);
      }
    } finally {
      isLoading.value = false;
    }
  }

  void toggleGenre(int id) {
    if (selectedGenreIds.contains(id)) {
      selectedGenreIds.remove(id);
    } else {
      selectedGenreIds.add(id);
    }
  }

  bool get canContinue => selectedGenreIds.length >= minSelection && !isSubmitting.value;

  Future<void> completeOnboarding() async {
    if (!canContinue) return;
    isSubmitting.value = true;
    try {
      var userId = _session.userId.value;
      if (userId == null) {
        // Fallback for reaching onboarding without registering first.
        final deviceTag = DateTime.now().microsecondsSinceEpoch;
        final user = await _userService.createOrGet(
          'device-$deviceTag@neizlesem.local',
          'Misafir Kullanıcı',
          'misafir$deviceTag',
        );
        userId = user.id;
        await _session.setUserId(userId);
      }
      await _userService.updatePreferredGenres(userId, selectedGenreIds.toList());
      if (isEditing) {
        // New genres should show up in Swipe right away, not next launch.
        if (Get.isRegistered<SwipeController>()) {
          Get.find<SwipeController>().reload();
        }
        Get.back();
        Get.snackbar('Kaydedildi', 'Tür tercihlerin güncellendi.');
      } else {
        Get.offAllNamed(AppRoutes.root);
      }
    } catch (_) {
      Get.snackbar('Olmadı', 'Tercihlerin kaydedilemedi, tekrar dene.');
    } finally {
      isSubmitting.value = false;
    }
  }
}
