// OPDS catalogs that a new install starts with.
//
// Names and addresses are from the KOReader default list
// (koreader/plugins/opds.koplugin/main.lua, default_servers). Only public
// catalogs are here: no home server and no login data is built in.

class DefaultCatalog {
  const DefaultCatalog(this.title, this.url);

  final String title;
  final String url;
}

/// Added once, when the app creates its database. The user can edit or
/// delete each one; a deleted catalog does not come back.
const List<DefaultCatalog> kDefaultCatalogs = [
  DefaultCatalog('Project Gutenberg', 'https://m.gutenberg.org/ebooks.opds/?format=opds'),
  // Standard Ebooks asks for a login (HTTP 401); the app asks for it on first use.
  DefaultCatalog('Standard Ebooks', 'https://standardebooks.org/feeds/opds'),
  DefaultCatalog('ManyBooks', 'http://manybooks.net/opds/index.php'),
];
