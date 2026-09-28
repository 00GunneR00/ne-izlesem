import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/person_model.dart';
import '../../../data/models/title_model.dart';
import '../../../data/services/people_service.dart';
import '../widgets/title_poster_card.dart';

/// A person's filmography (movies + shows), reached by tapping a search
/// result in the "Oyuncu" search mode. Loads its own data — no shared
/// controller needed since it's a one-off destination.
class PersonFilmographyView extends StatefulWidget {
  const PersonFilmographyView({required this.person, super.key});

  final PersonModel person;

  @override
  State<PersonFilmographyView> createState() => _PersonFilmographyViewState();
}

class _PersonFilmographyViewState extends State<PersonFilmographyView> {
  final _peopleService = PeopleService();
  final RxList<TitleModel> _credits = <TitleModel>[].obs;
  final RxBool _isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _isLoading.value = true;
    try {
      _credits.value = await _peopleService.getCredits(widget.person.tmdbId);
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.person.name)),
      body: SafeArea(
        child: Obx(() {
          if (_isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (_credits.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Bu oyuncu için film/dizi bulunamadı.',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.62,
            ),
            itemCount: _credits.length,
            itemBuilder: (context, index) =>
                TitlePosterCard(title: _credits[index]),
          );
        }),
      ),
    );
  }
}
