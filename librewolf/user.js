
// JoeOS update: the bookmarks bar slides in with the address bar instead of sitting on the new tab page
user_pref("browser.toolbars.bookmarks.visibility", "never");
// JoeOS LibreWolf settings: dark, glass, compact and uncluttered.
// Lives in: <your LibreWolf profile>/user.js  (read every time LibreWolf starts)

// let LibreWolf use the theme files in the "chrome" folder
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// see-through window so Hyprland's blur shows (the glass)
user_pref("browser.tabs.allow_transparent_browser", true);
user_pref("widget.transparent-windows", true);

// dark everywhere: menus, settings pages, and websites that have a dark mode
user_pref("ui.systemUsesDarkTheme", 1);
user_pref("browser.theme.toolbar-theme", 0);
user_pref("browser.theme.content-theme", 0);
user_pref("layout.css.prefers-color-scheme.content-override", 0);

// compact layout, no window buttons in the tab bar
user_pref("browser.compactmode.show", true);
user_pref("browser.uidensity", 1);
user_pref("browser.tabs.inTitlebar", 0);

// less clutter
user_pref("browser.tabs.firefox-view", false);
user_pref("browser.tabs.tabmanager.enabled", false);
user_pref("browser.toolbars.bookmarks.visibility", "newtab");   // bookmarks bar only on the new tab page
user_pref("browser.download.autohideButton", true);
user_pref("sidebar.revamp", false);
user_pref("sidebar.verticalTabs", false);
user_pref("browser.ml.chat.enabled", false);
user_pref("browser.ml.chat.sidebar", false);
user_pref("browser.translations.automaticallyPopup", false);
user_pref("browser.urlbar.suggest.trending", false);
user_pref("browser.urlbar.suggest.topsites", false);
user_pref("browser.urlbar.trimHttps", true);

// a clean new tab page
user_pref("browser.newtabpage.activity-stream.feeds.topsites", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.highlights", false);
user_pref("browser.newtabpage.activity-stream.showWeather", false);
user_pref("browser.newtabpage.activity-stream.feeds.weatherfeed", false);
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);

// JoeOS update: the bookmarks bar slides in with the address bar instead of sitting on the new tab page
user_pref("browser.toolbars.bookmarks.visibility", "never");

// JoeOS: reopen your tabs and windows when LibreWolf starts.
// (LibreWolf normally wipes history, cookies and open tabs every time it closes. This keeps them,
//  so you'll also stay logged in to sites.)
user_pref("browser.startup.page", 3);
user_pref("browser.sessionstore.resume_from_crash", true);
user_pref("privacy.sanitize.sanitizeOnShutdown", false);
user_pref("privacy.clearOnShutdown.history", false);
user_pref("privacy.clearOnShutdown.cookies", false);
user_pref("privacy.clearOnShutdown_v2.historyFormDataAndDownloads", false);
user_pref("privacy.clearOnShutdown_v2.browsingHistoryAndDownloads", false);
user_pref("privacy.clearOnShutdown_v2.cookiesAndStorage", false);
