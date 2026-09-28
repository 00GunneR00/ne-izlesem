import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/session/session_service.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/genre_model.dart';
import '../../../data/services/titles_service.dart';
import '../../../data/services/user_service.dart';

class OnboardingController extends GetxController {
  final TitlesService _titlesService = TitlesService();
  final UserService _userService = UserService();
  final SessionService _session = Get.find();

  final RxList<GenreModel> genres = <GenreModel>[].obs;
  final RxSet<int> selectedGenreIds = <int>{}.obs;
  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;

  static const minSelection = 3;

  @override
  void onInit() {
    super.onInit();
    _loadGenres();
  }

  Future<void> _loadGenres() async {
    isLoading.value = true;
    try {
      genres.value = await _titlesService.getGenres(MediaType.movie);
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
      Get.offAllNamed(AppRoutes.root);
    } finally {
      isSubmitting.value = false;
    }
  }
}
