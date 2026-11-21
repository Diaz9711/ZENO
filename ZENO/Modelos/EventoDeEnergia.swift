import Foundation
import SwiftData

/// Cosas que pasan dentro de la app y que sirven para aprender la curva de energía.
enum TipoDeEvento: String, Codable, CaseIterable {
    case abrioLaApp
    case cerroSinHacerNada
    case tareaPropuesta
    case tareaEmpezada
    case tareaTerminada
    case ahoraNo
    case tareaIgnorada
}

/// Historial de eventos. Se guarda completo para poder recalcular la curva
/// (y para que en la versión 2 quepan señales de salud como otra fuente).
@Model
final class EventoDeEnergia {
    var fecha: Date
    var tipoCrudo: String
    /// Hora del día en que ocurrió (0–23), la "franja" que aprende.
    var franjaHoraria: Int
    /// Dato opcional: segundos que tardó, puntaje propuesto, etc.
    var valor: Double?
    /// De dónde viene la señal: "app" en el MVP; "salud" en la versión 2.
    var fuente: String
    /// Tamaño de la tarea en ese momento (chica, mediana, grande). Se guarda aparte para que
    /// lo aprendido no se pierda si la tarea se borra después.
    var tamanoCrudo: String? = nil
    /// Tipo de la tarea (llamada, trámite, papeles…), guardado aparte por la misma razón.
    var tipoDeTareaCrudo: String? = nil

    var tarea: Tarea?

    init(
        tipo: TipoDeEvento,
        fecha: Date = .now,
        valor: Double? = nil,
        tarea: Tarea? = nil,
        fuente: String = "app",
        calendario: Calendar = .current
    ) {
        self.fecha = fecha
        self.tipoCrudo = tipo.rawValue
        self.franjaHoraria = calendario.component(.hour, from: fecha)
        self.valor = valor
        self.tarea = tarea
        self.tamanoCrudo = tarea?.tamanoCrudo
        self.tipoDeTareaCrudo = tarea.flatMap { TipoDeTarea.de($0.titulo)?.rawValue }
        self.fuente = fuente
    }

    var tipo: TipoDeEvento? { TipoDeEvento(rawValue: tipoCrudo) }
}
