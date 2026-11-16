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
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "medirFluidez") { MedidorDeTirones.compartido.empezar() }
        // `-probarIA YES`: comprobación de la fase IA (PASS/FAIL en la consola), también en el iPhone.
        if UserDefaults.standard.bool(forKey: "probarIA") { Task { await PruebaDeIA.correr() } }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if UserDefaults.standard.bool(forKey: "generarIcono") {
                IconoDeLaApp()
            } else {
                RaizDeZeno()
            }
            #else
            RaizDeZeno()
            #endif
        }
        // Todo se guarda en el teléfono. Sin cuentas ni servidor.
        // Un solo contenedor, el mismo que usan Siri y el "Terminé" de la pantalla bloqueada.
        .modelContainer(Almacen.contenedor)
    }
}

/// El universo en el idioma que la persona eligió (la primera vez, el de su teléfono).
/// Cambiarlo en Ajustes cambia todos los textos al momento, sin reiniciar ni perder a Lumi.
struct RaizDeZeno: View {
    @AppStorage(Idioma.clave) private var idioma = Idioma.actual.rawValue

    var body: some View {
        UniversoView()
            .environment(\.locale, (Idioma(rawValue: idioma) ?? .espanol).locale)
            .preferredColorScheme(.dark)
    }
}
