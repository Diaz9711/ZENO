import Foundation
import SwiftData

/// Tamaño que la app asigna sola a cada tarea.
enum TamanoDeTarea: String, Codable, CaseIterable {
    case chica, mediana, grande
}

/// Una tarea. Sin fechas de vencimiento ni deuda: solo pendiente o terminada.
@Model
final class Tarea {
    var titulo: String
    var tamanoCrudo: String
    /// Para tareas grandes: "¿cuál es el primer paso de dos minutos?"
    var primerPaso: String?

    var creadaEn: Date
    var empezadaEn: Date?
    var terminadaEn: Date?

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
