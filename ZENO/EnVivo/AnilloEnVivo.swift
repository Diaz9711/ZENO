import Foundation
import ActivityKit

/// El anillo de tiempo en la Isla Dinámica y en la pantalla bloqueada.
/// Regla simple: el estado manda. `UniversoView` llama a `sincronizar` cada vez que cambia
/// la tarea en curso (empezar, terminar, "Ahora no", borrar, borrar todo, cerrar sesión).
/// Sin alarma ni sonido: cuando el tiempo se acaba, el anillo solo queda vacío.
@MainActor
enum AnilloEnVivo {
    static func sincronizar(titulo: String?, inicio: Date?, minutos: Double) async {
        let actuales = Activity<AtributosDelAnillo>.activities
        guard let titulo, let inicio else {
            await terminarTodo()
            return
        }
        let estado = AtributosDelAnillo.ContentState(inicio: inicio, fin: inicio.addingTimeInterval(minutos * 60))
        let contenido = ActivityContent(state: estado, staleDate: nil)
        // La misma tarea: solo se actualiza. Otra: se cierra la vieja y se abre la nueva.
        if let igual = actuales.first(where: { $0.attributes.titulo == titulo && $0.activityState == .active }) {
            if igual.content.state != estado { await igual.update(contenido) }
            for otra in actuales where otra.id != igual.id { await otra.end(nil, dismissalPolicy: .immediate) }
            return
        }
        for vieja in actuales { await vieja.end(nil, dismissalPolicy: .immediate) }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        _ = try? Activity.request(attributes: AtributosDelAnillo(titulo: titulo), content: contenido, pushType: nil)
    }

    static func terminarTodo() async {
        for actividad in Activity<AtributosDelAnillo>.activities {
            await actividad.end(nil, dismissalPolicy: .immediate)
        }
    }
}
