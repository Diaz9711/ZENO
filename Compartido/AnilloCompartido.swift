import Foundation
import ActivityKit
import AppIntents

/// Lo que comparten la app y la extensión de widgets para el anillo de tiempo en vivo
/// (Isla Dinámica y pantalla bloqueada). La app lo empieza y lo termina; la extensión lo dibuja.
struct AtributosDelAnillo: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var inicio: Date
        var fin: Date
    }
    /// El texto de la tarea. Solo se muestra en la Isla Dinámica abierta, nunca en la pantalla
    /// bloqueada (decisión de Diaz, 14 nov 2026).
    var titulo: String
    /// El idioma elegido dentro de ZENO, para que el anillo hable igual que la app.
    var idioma: String = "es"
}

/// "Terminé" desde la Isla Dinámica o la pantalla bloqueada. iOS lo corre dentro de la app
/// (aunque esté cerrada), así que guarda en la misma base de datos de siempre.
struct TerminarTareaIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Terminé"
    static var description = IntentDescription("Marca como terminada la tarea en curso.")
    static var isDiscoverable = false

    init() {}

    func perform() async throws -> some IntentResult {
        #if !WIDGET
        await AccionesDeTarea.terminarLaEnCurso()
        #endif
        return .result()
    }
}

/// Las direcciones con las que el widget y el anillo abren ZENO.
enum EnlaceZeno {
    static let hoy = URL(string: "zeno://hoy")!
    static let escribir = URL(string: "zeno://escribir")!
}
