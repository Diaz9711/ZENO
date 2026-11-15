import Foundation
import SwiftData

/// La única base de datos de ZENO. La usan la app, el "Terminé" de la pantalla bloqueada y Siri,
/// así todos ven lo mismo al instante. Está en el sitio de siempre (los datos viejos siguen ahí).
@MainActor
enum Almacen {
    static let contenedor: ModelContainer = {
        do {
            return try ModelContainer(for: Persona.self, Tarea.self, EventoDeEnergia.self)
        } catch {
            fatalError("No se pudo abrir la base de datos de ZENO: \(error)")
        }
    }()
}
