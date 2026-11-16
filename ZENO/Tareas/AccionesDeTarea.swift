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

    /// "Terminé" con pasos (Divídemela): si quedan pasos, pasa al siguiente y devuelve false;
    /// con el último (o sin pasos) termina la tarea entera y devuelve true. Una estrella por tarea.
    @discardableResult
    static func completarPaso(_ tarea: Tarea, en contexto: ModelContext) -> Bool {
        let pasos = tarea.pasos
        if !pasos.isEmpty && tarea.pasoActual < pasos.count - 1 {
            tarea.pasoActual += 1
            tarea.empezadaEn = nil
            return false
        }
        terminar(tarea, en: contexto)
        return true
    }

    /// Desde fuera de la app (pantalla bloqueada): termina la tarea que está en marcha.
    static func terminarLaEnCurso() async {
        let contexto = Almacen.contenedor.mainContext
        let pendientes = (try? contexto.fetch(FetchDescriptor<Tarea>(predicate: #Predicate { $0.terminadaEn == nil }))) ?? []
        if let tarea = pendientes.first(where: \.estaEnCurso) {
            completarPaso(tarea, en: contexto)
            try? contexto.save()
            // Fuera de la app iOS puede dormirla pronto: se espera a que los avisos queden al día.
            await AvisosDeTareas.sincronizar(contexto)
        }
        await AnilloEnVivo.terminarTodo()
        Widgets.tareaTerminadaFuera()
    }
}
