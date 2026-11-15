import SwiftUI
import Observation

/// Solo para medir la fluidez sin que nadie toque el iPhone (`-autopiloto YES`, DEBUG):
/// cambia de página, desliza Ajustes y Tareas y abre hojas, marcando cada fase en el medidor.
@MainActor @Observable
final class Autopiloto {
    static let compartido = Autopiloto()
    /// Cada cambio pide a la página visible deslizarse: par = hacia abajo, impar = hacia arriba.
    var desplazar = 0

    static var activo: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: "autopiloto")
        #else
        false
        #endif
    }
}

extension View {
    /// Deja que el autopiloto deslice esta lista de arriba abajo (ids "zeno.arriba" y "zeno.abajo").
    func deslizablePorAutopiloto(_ lector: ScrollViewProxy) -> some View {
        onChange(of: Autopiloto.compartido.desplazar) { _, n in
            withAnimation(.easeInOut(duration: 1.6)) {
                lector.scrollTo(n.isMultiple(of: 2) ? "zeno.abajo" : "zeno.arriba", anchor: n.isMultiple(of: 2) ? .bottom : .top)
            }
        }
    }
}

/// Marcas invisibles de principio y fin de una lista.
struct MarcaDeLista: View {
    let id: String
    var body: some View { Color.clear.frame(height: 0).id(id) }
}
