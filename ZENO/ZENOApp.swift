import SwiftUI
import SwiftData

/// Punto de entrada de ZENO.
/// En la Fase 1 la app abre directamente el laboratorio de Lumi.
@main
struct ZENOApp: App {
    var body: some Scene {
        WindowGroup {
            LaboratorioView()
                .fontDesign(.rounded)
                .preferredColorScheme(.dark)
        }
        // Todo se guarda en el teléfono. Sin cuentas ni servidor.
        .modelContainer(for: [Persona.self, Tarea.self, EventoDeEnergia.self])
    }
}
