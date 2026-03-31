import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case english = "English"
    case spanish = "Español"

    var id: String { rawValue }

    var code: String {
        switch self {
        case .english: return "en"
        case .spanish: return "es"
        }
    }
}

/// Centralized localization. All UI strings go through here.
/// Access via `L10n.someKey`.
enum L10n {
    private static var lang: AppLanguage {
        SettingsStore.shared.appLanguage
    }

    // MARK: - Navigation

    static var home: String { s("Home", "Inicio") }
    static var explore: String { s("Explore", "Explorar") }
    static var library: String { s("Library", "Biblioteca") }

    // MARK: - Categories

    static var categories: String { s("LiveWall Categories", "Categorías LiveWall") }
    static var browseByCategory: String { s("Browse wallpapers by category", "Explora fondos por categoría") }

    // MARK: - Explore (GitHub)

    static var exploreTitle: String { s("Explore", "Explorar") }
    static var exploreSubtitle: String { s("Download wallpapers from GitHub repositories", "Descarga fondos desde repositorios de GitHub") }
    static var fetch: String { s("Fetch", "Obtener") }
    static var downloadAll: String { s("Download All", "Descargar Todo") }
    static var downloading: String { s("Downloading...", "Descargando...") }
    static var downloaded: String { s("Downloaded", "Descargado") }
    static var wallpapersAvailable: String { s("wallpapers available", "fondos disponibles") }
    static var fetchingRepo: String { s("Fetching repository contents...", "Obteniendo contenido del repositorio...") }
    static var enterGitHubRepo: String { s("Enter a GitHub Repository", "Introduce un Repositorio de GitHub") }
    static var repoFormatHint: String { s(
        "Format: owner/repo\nThe repo should contain MP4 files,\noptionally organized in category folders.",
        "Formato: propietario/repo\nEl repo debe contener archivos MP4,\nopcionalmente organizados en carpetas de categorías."
    ) }

    // MARK: - Library

    static var libraryTitle: String { s("Library", "Biblioteca") }
    static var librarySubtitle: String { s("Favorites and recently used", "Favoritos y recientes") }
    static var allWallpapers: String { s("All Wallpapers", "Todos los Fondos") }
    static var favorites: String { s("Favorites", "Favoritos") }
    static var recent: String { s("Recent", "Recientes") }
    static var vertical: String { s("Vertical", "Vertical") }

    static func wallpaperCount(_ count: Int) -> String {
        s("\(count) wallpaper\(count == 1 ? "" : "s")", "\(count) fondo\(count == 1 ? "" : "s")")
    }

    // MARK: - Card Actions

    static var setWallpaper: String { s("Set Wallpaper", "Poner Fondo") }
    static var setAllDisplays: String { s("Set as Wallpaper (All Displays)", "Poner en Todas las Pantallas") }
    static func setOnDisplay(_ name: String) -> String { s("Set on \(name)", "Poner en \(name)") }
    static var addToFavorites: String { s("Add to Favorites", "Añadir a Favoritos") }
    static var removeFromFavorites: String { s("Remove from Favorites", "Quitar de Favoritos") }
    static var category: String { s("Category", "Categoría") }
    static var scaling: String { s("Scaling", "Escalado") }
    static var showInFinder: String { s("Show in Finder", "Mostrar en Finder") }
    static var delete: String { s("Delete", "Eliminar") }
    static var deleteWallpaper: String { s("Delete Wallpaper", "Eliminar Fondo") }
    static var deleteConfirmation: String { s("Are you sure you want to remove this wallpaper from your library?", "¿Seguro que quieres eliminar este fondo de tu biblioteca?") }
    static var cancel: String { s("Cancel", "Cancelar") }
    static var none: String { s("None", "Ninguna") }
    static var active: String { s("ACTIVE", "ACTIVO") }

    // MARK: - Empty State

    static var noWallpapers: String { s("No Wallpapers Yet", "Aún No Hay Fondos") }
    static var emptyImportHint: String { s(
        "Import MP4 videos to get started.\nDrag and drop or click below.",
        "Importa vídeos MP4 para empezar.\nArrastra y suelta o pulsa abajo."
    ) }
    static var importWallpapers: String { s("Import Wallpapers", "Importar Fondos") }
    static var importing: String { s("Importing...", "Importando...") }

    // MARK: - Sorting

    static var sort: String { s("Sort", "Ordenar") }
    static var dateAdded: String { s("Date Added", "Fecha de Adición") }
    static var title: String { s("Title", "Título") }
    static var duration: String { s("Duration", "Duración") }
    static var resolution: String { s("Resolution", "Resolución") }
    static var favoritesFirst: String { s("Favorites First", "Favoritos Primero") }
    static var mostUsed: String { s("Most Used", "Más Usados") }

    // MARK: - Menu Bar

    static var wallpaperActive: String { s("Wallpaper Active", "Fondo Activo") }
    static var wallpaperPaused: String { s("Wallpaper Paused", "Fondo Pausado") }
    static var pauseAll: String { s("Pause All", "Pausar Todo") }
    static var resumeAll: String { s("Resume All", "Reanudar Todo") }
    static var startEngine: String { s("Start Engine", "Iniciar Motor") }
    static var openApp: String { s("Open LiveWall Pro", "Abrir LiveWall Pro") }
    static var settings: String { s("Settings...", "Ajustes...") }
    static var resourceUsage: String { s("Resource Usage", "Uso de Recursos") }
    static var quitApp: String { s("Quit LiveWall Pro", "Salir de LiveWall Pro") }

    // MARK: - Settings

    static var appearance: String { s("Appearance", "Apariencia") }
    static var general: String { s("General", "General") }
    static var playback: String { s("Playback", "Reproducción") }
    static var performance: String { s("Performance", "Rendimiento") }
    static var displays: String { s("Displays", "Pantallas") }
    static var language: String { s("Language", "Idioma") }
    static var theme: String { s("Theme", "Tema") }
    static var chooseTheme: String { s("Choose a gradient theme for the app background", "Elige un tema de gradiente para el fondo de la app") }
    static var preview: String { s("Preview", "Vista Previa") }
    static var startup: String { s("Startup", "Inicio") }
    static var launchAtLogin: String { s("Launch at Login", "Abrir al Iniciar Sesión") }
    static var showInMenuBar: String { s("Show in Menu Bar", "Mostrar en Barra de Menú") }
    static var showInDock: String { s("Show in Dock", "Mostrar en Dock") }
    static var engine: String { s("Engine", "Motor") }
    static var status: String { s("Status", "Estado") }
    static var running: String { s("Running", "Activo") }
    static var stopped: String { s("Stopped", "Detenido") }
    static var stopEngine: String { s("Stop Engine", "Detener Motor") }

    // MARK: - Power

    static var fullQuality: String { s("Full Quality", "Calidad Máxima") }
    static var balanced: String { s("Balanced", "Equilibrado") }
    static var lowPower: String { s("Low Power", "Bajo Consumo") }
    static var pausedSavingPower: String { s("Paused (Saving Power)", "Pausado (Ahorrando Energía)") }

    // MARK: - Helpers

    private static func s(_ en: String, _ es: String) -> String {
        lang == .spanish ? es : en
    }
}
