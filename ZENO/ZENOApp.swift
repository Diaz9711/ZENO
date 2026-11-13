import SwiftUI
import SwiftData

/// Punto de entrada de ZENO.
/// La app abre el universo: registro la primera vez, y después la casa de Lumi.
@main
struct ZENOApp: App {
    var body: some Scene {
        WindowGroup {
            UniversoView()
                .fontDesign(.rounded)
                .preferredColorScheme(.dark)
        }
        // Todo se guarda en el teléfono. Sin cuentas ni servidor.
        .modelContainer(for: [Persona.self, Tarea.self, EventoDeEnergia.self])
    }
}
