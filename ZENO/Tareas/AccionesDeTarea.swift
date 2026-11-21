import Foundation
import SwiftData

/// Lo que pasa al terminar una tarea, en un solo lugar: lo usan Hoy, la vista del día
/// y el botón "Terminé" de la Isla Dinámica.
@MainActor
enum AccionesDeTarea {
    /// Guarda el evento (con cuánto tardó) y marca la tarea como terminada.
    /// Las vistas lo envuelven en su propia animación.
    static func terminar(_ tarea: Tarea, en contexto: ModelContext) {
        // Con pasos (Divídemela) solo se sabe cuánto duró el último paso: no se guarda duración,
        // para no enseñarle a ZENO que una tarea grande toma 5 minutos.
        let segundos = tarea.pasos.isEmpty ? tarea.empezadaEn.map { Date.now.timeIntervalSince($0) } : nil
        let evento = EventoDeEnergia(tipo: .tareaTerminada, valor: segundos)
        contexto.insert(evento)
        evento.tarea = tarea
        evento.tamanoCrudo = tarea.tamanoCrudo
        evento.tipoDeTareaCrudo = TipoDeTarea.de(tarea.titulo)?.rawValue
        tarea.terminadaEn = .now
        Task { await AvisosDeTareas.sincronizar(contexto) }
    }

    /// "Terminé" con pasos (Divídemela): si quedan pasos, pasa al siguiente y devuelve false;
    /// con el último (o sin pasos) termina la tarea entera y devuelve true. Una estrella por tarea.
    /// `seguir`: en la app, el paso siguiente arranca solo (sin otro "Empezar": el primer segundo es el que
    /// más cuesta). Desde la pantalla bloqueada no, porque allí el anillo en vivo se cierra.
    @discardableResult
    static func completarPaso(_ tarea: Tarea, en contexto: ModelContext, seguir: Bool = true) -> Bool {
        let pasos = tarea.pasos
        if !pasos.isEmpty && tarea.pasoActual < pasos.count - 1 {
            tarea.pasoActual += 1
            tarea.empezadaEn = seguir ? .now : nil
            return false
        }
        terminar(tarea, en: contexto)
        return true
    }

    /// Desde fuera de la app (pantalla bloqueada): termina la tarea que está en marcha.
    static func terminarLaEnCurso() async {
        let contexto = Almacen.contenedor.mainContext
        let pendientes = (try? contexto.fetch(FetchDescriptor<Tarea>(predicate: #Predicate { $0.terminadaEn == nil }))) ?? []
        var terminoLaTarea = true
        if let tarea = pendientes.first(where: \.estaEnCurso) {
            terminoLaTarea = completarPaso(tarea, en: contexto, seguir: false)
            try? contexto.save()
            // Fuera de la app iOS puede dormirla pronto: se espera a que los avisos queden al día.
            await AvisosDeTareas.sincronizar(contexto)
        }
        await AnilloEnVivo.terminarTodo()
        // Si solo terminó un paso, la tarea sigue: el widget no la borra.
        if terminoLaTarea { Widgets.tareaTerminadaFuera() }
    }
}
