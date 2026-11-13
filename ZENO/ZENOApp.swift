import SwiftUI
import SwiftData
import UserNotifications

/// Punto de entrada de ZENO.
/// La app abre el universo: registro la primera vez, y después la casa de Lumi.
@main
struct ZENOApp: App {
    init() {
        // Antes de que termine el arranque: así no se pierde el toque que abre ZENO desde un aviso.
        UNUserNotificationCenter.current().delegate = CentroDeAvisos.compartido
    }

    var body: some Scene {
        WindowGroup {
            UniversoView()
                .preferredColorScheme(.dark)
        }
        // Todo se guarda en el teléfono. Sin cuentas ni servidor.
        .modelContainer(for: [Persona.self, Tarea.self, EventoDeEnergia.self])
    }
}
