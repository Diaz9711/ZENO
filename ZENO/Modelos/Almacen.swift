import Foundation
import SwiftData
import SwiftUI

/// La única base de datos de ZENO. La usan la app, el "Terminé" de la pantalla bloqueada y Siri,
/// así todos ven lo mismo al instante. SwiftData la guarda en el contenedor del App Group
/// (`.../AppGroup/.../Library/Application Support/default.store`, comprobado en el simulador).
@MainActor
enum Almacen {
    /// Por qué no se pudo abrir la base de datos (nil = todo bien).
    private(set) static var fallo: String?

    /// Plan B (auditoría, 20 nov 2026): si la base de datos no abre, la app ya no se cierra en bucle.
    /// Se usa una base vacía solo en memoria para que nada se rompa, y la raíz muestra un aviso tranquilo
    /// en vez de la app: así nada (avisos, widget, registro) actúa sobre esa base vacía. Los datos de
    /// verdad no se mueven ni se borran. Prueba: `-fallarBaseDeDatos YES`.
    static let contenedor: ModelContainer = {
        #if DEBUG
        let forzar = UserDefaults.standard.bool(forKey: "fallarBaseDeDatos")
        #else
        let forzar = false
        #endif
        do {
            if forzar { throw NSError(domain: "ZENO.prueba", code: 1) }
            return try ModelContainer(for: Persona.self, Tarea.self, EventoDeEnergia.self)
        } catch {
            fallo = String(describing: error)
            do {
                return try ModelContainer(for: Persona.self, Tarea.self, EventoDeEnergia.self,
                                          configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            } catch {
                fatalError("No se pudo crear ni la base en memoria: \(error)")
            }
        }
    }()

    /// ¿Falló la base de datos? (Abre el contenedor si aún no estaba abierto.)
    static var falla: Bool {
        _ = contenedor
        return fallo != nil
    }
}

/// Lo que se ve si la base de datos no abre: calma, sin códigos de error ni culpa.
struct AvisoDeDatos: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.05, green: 0.06, blue: 0.16), Color(red: 0.02, green: 0.02, blue: 0.07)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                EtiquetaLujo("Tus datos")
                Text("Tus datos están a salvo")
                    .font(.zenoTitulo(.largeTitle))
                    .foregroundStyle(Lujo.marfil)
                Text("ZENO no pudo abrirlos esta vez. No se borró nada: siguen en tu iPhone. Cierra ZENO del todo y vuelve a abrirla. Si sigue igual, espera a la próxima actualización.")
                    .font(.zenoTexto(.body))
                    .foregroundStyle(Lujo.marfilSecundario)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Lujo.margen)
        }
    }
}
