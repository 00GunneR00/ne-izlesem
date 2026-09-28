enum MediaType {
  movie,
  show;

  String get apiValue => name == 'movie' ? 'Movie' : 'Show';

  static MediaType fromApi(String value) =>
      value.toLowerCase() == 'movie' ? MediaType.movie : MediaType.show;
}

enum LibraryStatus {
  toWatch,
  watched;

  String get apiValue => name == 'toWatch' ? 'ToWatch' : 'Watched';

  static LibraryStatus fromApi(String value) =>
      value.toLowerCase() == 'towatch' ? LibraryStatus.toWatch : LibraryStatus.watched;
}

enum SwipeDirection {
  pass,
  like;

  String get apiValue => name == 'pass' ? 'Pass' : 'Like';
}
