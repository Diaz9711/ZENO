import Foundation
import SwiftData

/// Lo que pasa al terminar una tarea, en un solo lugar: lo usan Hoy, la vista del día
/// y el botón "Terminé" de la Isla Dinámica.
@MainActor
enum AccionesDeTarea {
    /// Guarda el evento (con cuánto tardó) y marca la tarea como terminada.
    /// Las vistas lo envuelven en su propia animación.
    static func terminar(_ tarea: Tarea, en contexto: ModelContext) {
        let segundos = tarea.empezadaEn.map { Date.now.timeIntervalSince($0) }
        let evento = EventoDeEnergia(tipo: .tareaTerminada, valor: segundos)
        contexto.insert(evento)
        evento.tarea = tarea
        evento.tamanoCrudo = tarea.tamanoCrudo
        tarea.terminadaEn = .now
        Task { await AvisosDeTareas.sincronizar(contexto) }
    }

    /// Desde fuera de la app (pantalla bloqueada): termina la tarea que está en marcha.
    static func terminarLaEnCurso() async {
        let contexto = Almacen.contenedor.mainContext
        let pendientes = (try? contexto.fetch(FetchDescriptor<Tarea>(predicate: #Predicate { $0.terminadaEn == nil }))) ?? []
        if let tarea = pendientes.first(where: \.estaEnCurso) {
            terminar(tarea, en: contexto)
            try? contexto.save()
        }
        await AnilloEnVivo.terminarTodo()
        Widgets.tareaTerminadaFuera()
    }
}
