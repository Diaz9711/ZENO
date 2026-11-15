import AppIntents
import SwiftData
import Observation

/// "Oye Siri, agrega una tarea a ZENO": Siri pregunta qué tarea y la guarda sin abrir la app.
/// (Las frases de Siri no pueden llevar texto libre dentro; por eso Siri pregunta después.)
struct AgregarTareaIntent: AppIntent {
    static var title: LocalizedStringResource = "Agregar una tarea"
    static var description = IntentDescription("Guarda una tarea en ZENO sin abrir la app.")
    static var openAppWhenRun = false

    @Parameter(title: "Tarea", requestValueDialog: IntentDialog("¿Qué quieres hacer?"))
    var tarea: String

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let texto = tarea.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !texto.isEmpty else { throw $tarea.needsValueError(IntentDialog("¿Qué quieres hacer?")) }
        let contexto = Almacen.contenedor.mainContext
        guard ((try? contexto.fetchCount(FetchDescriptor<Persona>())) ?? 0) > 0 else {
            return .result(dialog: IntentDialog("Primero abre ZENO y conoce a Lumi."))
        }
        // El tamaño lo decide ZENO, igual que al escribirla en la app.
        let tamano = ClasificadorDeTamano.tamano(de: texto)
        contexto.insert(Tarea(titulo: texto, tamano: tamano))
        try? contexto.save()
        // Con la sesión cerrada no se programa ningún aviso (lo promete "Cerrar sesión").
        if UserDefaults.standard.object(forKey: Sesion.clave) as? Bool ?? true {
            await AvisosDeTareas.sincronizar(contexto)
        }
        if tamano == .grande {
            return .result(dialog: IntentDialog("Guardada. Es grande: en ZENO puedes elegir su primer paso de dos minutos."))
        }
        return .result(dialog: IntentDialog("Guardada. Lumi te la propone en el momento justo."))
    }
}

/// Abre ZENO directo en "escribir una tarea". Se puede poner en el botón de Acción del iPhone.
struct EscribirTareaIntent: AppIntent {
    static var title: LocalizedStringResource = "Escribir una tarea"
    static var description = IntentDescription("Abre ZENO listo para escribir o dictar una tarea.")
    static var openAppWhenRun = true

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        PuenteDeAtajos.compartido.pedirEscribir()
        return .result()
    }
}

/// Une los atajos con la pantalla: `UniversoView` lo mira y abre la escritura en Hoy.
@MainActor @Observable
final class PuenteDeAtajos {
    static let compartido = PuenteDeAtajos()
    /// Pedidos aún sin atender (si la app arranca en frío, espera a que exista la pantalla).
    var pedidosDeEscribir = 0

    func pedirEscribir() { pedidosDeEscribir += 1 }
}

/// Las frases que Siri entiende sin configurar nada, y las que aparecen en Atajos
/// y en Ajustes → Botón de Acción → Atajo.
struct AtajosDeZeno: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: AgregarTareaIntent(),
                    phrases: ["Agrega una tarea a \(.applicationName)",
                              "Agrega a \(.applicationName)",
                              "Añade una tarea en \(.applicationName)",
                              "Nueva tarea en \(.applicationName)"],
                    shortTitle: "Agregar tarea",
                    systemImageName: "plus.circle")
        AppShortcut(intent: EscribirTareaIntent(),
                    phrases: ["Escribe una tarea en \(.applicationName)",
                              "Abre \(.applicationName) para escribir"],
                    shortTitle: "Escribir tarea",
                    systemImageName: "square.and.pencil")
    }

    static var shortcutTileColor: ShortcutTileColor = .navy
}
