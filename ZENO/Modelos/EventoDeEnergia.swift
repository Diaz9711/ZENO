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
        self.fuente = fuente
    }

    var tipo: TipoDeEvento? { TipoDeEvento(rawValue: tipoCrudo) }
}
