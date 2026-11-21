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
    /// "Divídemela" (fase IA, 16 nov 2026): pasos de unos 5 minutos, uno por línea. nil = sin pasos.
    /// Con valor por defecto: los datos que ya existen migran solos.
    var pasosCrudo: String? = nil
    /// El paso en el que va (0 = el primero).
    var pasoActual: Int = 0
    /// "¿Para qué te importa?" (opcional, una línea). El TDAH se mueve por interés: este anzuelo
    /// acompaña a la tarea en Hoy, en las frases de Chispa y al dividirla. nil = no lo dijo.
    var porque: String? = nil

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

    /// Los pasos de "Divídemela" (vacío si no tiene).
    var pasos: [String] {
        get { (pasosCrudo ?? "").split(separator: "\n").map(String.init).filter { !$0.isEmpty } }
        set {
            let limpios = newValue.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            pasosCrudo = limpios.isEmpty ? nil : limpios.joined(separator: "\n")
            pasoActual = min(pasoActual, max(limpios.count - 1, 0))
        }
    }

    /// El paso de ahora, si la tarea está dividida.
    var pasoDeAhora: String? {
        let p = pasos
        return p.indices.contains(pasoActual) ? p[pasoActual] : nil
    }

    /// Lo que se le muestra a la persona: el paso de ahora, el primer paso o el título.
    var textoVisible: String { pasoDeAhora ?? primerPaso ?? titulo }

    /// El porqué, si lo dijo y no suena a crisis (en ese caso ZENO no lo repite).
    var anzuelo: String? {
        guard let p = porque?.trimmingCharacters(in: .whitespacesAndNewlines), !p.isEmpty else { return nil }
        if Cuidado.suenaACrisis(p) { return nil }
        return p
    }
}
