import Foundation
import SwiftData

/// Tamaño que la app asigna sola a cada tarea.
enum TamanoDeTarea: String, Codable, CaseIterable {
    case chica, mediana, grande
}

/// Una tarea. Sin vencimientos ni deuda: solo pendiente o terminada (el día y la hora son opcionales).
@Model
final class Tarea {
    var titulo: String
    var tamanoCrudo: String
    /// Para tareas grandes: "¿cuál es el primer paso de dos minutos?"
    var primerPaso: String?

    var creadaEn: Date
    var empezadaEn: Date?
    var terminadaEn: Date?

    // Día, hora y aviso (opcionales, elegidos por la persona). Nunca se vuelven "vencidas":
    // si la hora pasa, la tarea sigue pendiente sin rojo ni reproche.
    // Con valores por defecto para que los datos que ya existen migren solos.
    var fechaPlaneada: Date? = nil
    /// Minutos antes de `fechaPlaneada` para el aviso: 0 a la hora, 10, 60. nil = sin aviso.
    var avisoMinutosAntes: Int? = nil
    /// Hora exacta del aviso cuando la persona eligió "Otra hora".
    var avisoPersonalizado: Date? = nil
    /// Identificador del aviso en iOS. Se crea la primera vez que hace falta.
    var idAviso: String? = nil

    @Relationship(deleteRule: .nullify, inverse: \EventoDeEnergia.tarea)
    var eventos: [EventoDeEnergia] = []

    init(titulo: String, tamano: TamanoDeTarea = .mediana, primerPaso: String? = nil) {
        self.titulo = titulo
        self.tamanoCrudo = tamano.rawValue
        self.primerPaso = primerPaso
        self.creadaEn = .now
    }

    var tamano: TamanoDeTarea {
        get { TamanoDeTarea(rawValue: tamanoCrudo) ?? .mediana }
        set { tamanoCrudo = newValue.rawValue }
    }

    var estaTerminada: Bool { terminadaEn != nil }

    /// Lo que se le muestra a la persona: el primer paso si existe, si no el título.
    var textoVisible: String { primerPaso ?? titulo }
}
