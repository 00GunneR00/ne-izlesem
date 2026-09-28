/// A streaming platform pickable in the "Platforma göre ara" search mode.
/// TMDB provider ids/logos verified for the TR watch region
/// (`watch/providers/movie|tv?watch_region=TR`) — not guessed.
class WatchProvider {
  final int id;
  final String name;
  final String logoPath;

  const WatchProvider({
    required this.id,
    required this.name,
    required this.logoPath,
  });

  String get logoUrl => 'https://image.tmdb.org/t/p/w200$logoPath';
}

const List<WatchProvider> kWatchProviders = [
  WatchProvider(
    id: 8,
    name: 'Netflix',
    logoPath: '/pbpMk2JmcoNnQwx5JGpXngfoWtp.jpg',
  ),
  WatchProvider(
    id: 119,
    name: 'Amazon Prime Video',
    logoPath: '/pvske1MyAoymrs5bguRfVqYiM9a.jpg',
  ),
  WatchProvider(
    id: 337,
    name: 'Disney Plus',
    logoPath: '/97yvRBw1GzX7fXprcF80er19ot.jpg',
  ),
  WatchProvider(
    id: 1899,
    name: 'HBO Max',
    logoPath: '/jbe4gVSfRlbPTdESXhEKpornsfu.jpg',
  ),
  WatchProvider(
    id: 1791,
    name: 'Exxen',
    logoPath: '/sDihpCEJyBtH1pwVniZz2U3gcBz.jpg',
  ),
  WatchProvider(
    id: 342,
    name: 'puhutv',
    logoPath: '/ffvIywFtojPQnVwHVmTSZEdemdt.jpg',
  ),
  WatchProvider(
    id: 1826,
    name: 'TOD TV',
    logoPath: '/gaDNJ1xISHBBq9LQXwwe8PPSRHD.jpg',
  ),
  WatchProvider(
    id: 2235,
    name: 'tabii',
    logoPath: '/uWVpt3iJ2pLKtFZ69rAKP0EDVVx.jpg',
  ),
];
