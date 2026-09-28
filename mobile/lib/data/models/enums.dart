enum MediaType {
  movie,
  show;

  String get apiValue => name == 'movie' ? 'Movie' : 'Show';

  static MediaType fromApi(String value) =>
      value.toLowerCase() == 'movie' ? MediaType.movie : MediaType.show;
}

enum LibraryStatus {
  toWatch,
  watched,

  /// A show in progress ("İzliyorum").
  watching;

  String get apiValue => switch (this) {
        LibraryStatus.toWatch => 'ToWatch',
        LibraryStatus.watched => 'Watched',
        LibraryStatus.watching => 'Watching',
      };

  static LibraryStatus fromApi(String value) => switch (value.toLowerCase()) {
        'towatch' => LibraryStatus.toWatch,
        'watching' => LibraryStatus.watching,
        _ => LibraryStatus.watched,
      };
}

enum SwipeDirection {
  pass,
  like;

  String get apiValue => name == 'pass' ? 'Pass' : 'Like';
}
