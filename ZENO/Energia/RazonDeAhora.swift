import Foundation

// "Por qué ahora" (Diaz, 21 nov 2026): que el cerebro se note. La tarjeta Ahora lleva una línea corta con
// la razón verdadera de la elección (nunca inventada). Funciones puras; las frases varían para no cansar.

/// La razón más fuerte por la que ZENO propone esta tarea en este momento.
enum RazonDeAhora: Equatable {
    /// La persona la planeó para esta hora.
    case planeada
    /// Antes dijo "Esta no me llama": se ofrece dividirla o preguntar su porqué.
    case noLeLlamo
    /// Tiene su porqué y la energía da para ella.
    case porque
    /// Esta es una de sus horas fuertes.
    case horaFuerte
    /// A esta hora lo grande le cuesta: por eso va algo más chico.
    case grandeCuesta
    /// La energía del día va bajando: por eso algo pequeño.
    case energiaBajando
    /// Aún sin historial: se parte del ritmo que contó en el registro.
    case sinHistorial
}

extension MotorDeEnergia {
    /// La razón de proponer `tarea` ahora, por prioridad. nil si ninguna es verdad (no se dice nada).
    /// `horasDelDia`: la energía esperada de cada hora (la misma curva de la mejor hora).
    static func razon(tarea: Tarea, puntaje: Double, eventos: [Senal], horasDelDia: [Double],
                      hayGrandes: Bool, ahora: Date = .now, calendario: Calendar = .current) -> RazonDeAhora? {
        let nivel = nivel(puntaje)
        let hora = calendario.component(.hour, from: ahora)

        // 1. La planeó para este rato (±30 min, como al elegir).
        if let fecha = tarea.fechaPlaneada, abs(fecha.timeIntervalSince(ahora)) < 30 * 60 { return .planeada }

        // 2. Antes no le llamó (y aún no está dividida o le falta el porqué): ofrecer ayuda.
        let id = tarea.persistentModelID
        let noLeLlamo = eventos.contains {
            $0.tipo == .ahoraNo && $0.motivo == .noMeLlama && $0.tareaID == id && ahora.timeIntervalSince($0.fecha) < 14 * 86_400
        }
        if noLeLlamo && (tarea.pasos.isEmpty || tarea.anzuelo == nil) { return .noLeLlamo }

        // 3. Tiene porqué y hay energía para ella.
        if tarea.anzuelo != nil && nivel != .baja { return .porque }

        // 4. Una de sus horas fuertes (entre las tres mejores, con historial suficiente).
        if Aprendizaje.horasFuertes(eventos: eventos, ahora: ahora).prefix(3).contains(hora) && nivel != .baja {
            return .horaFuerte
        }

        // 5. Lo grande le cuesta a esta hora, por eso va algo más chico.
        if Aprendizaje.patronDeAhora(propuesta: tarea.tamano, tipo: nil, hayGrandes: hayGrandes, nivel: nivel,
                                     franja: hora, eventos: eventos, ahora: ahora) == .grandeCuestaAEstaHora {
            return .grandeCuesta
        }

        // 6. La energía viene bajando (la curva del día cae) y se propone algo pequeño.
        let pequena = tarea.tamano == .chica || tarea.primerPaso != nil || tarea.pasoDeAhora != nil
        if pequena, nivel != .alta, horasDelDia.count == 24 {
            let antes = horasDelDia[(hora + 23) % 24], ahoraE = horasDelDia[hora], despues = horasDelDia[(hora + 1) % 24]
            if despues < ahoraE - 2 && ahoraE <= antes + 1 { return .energiaBajando }
        }

        // 7. Aún sin historial: parte del registro.
        if eventos.filter({ $0.tipo == .tareaTerminada }).count < Aprendizaje.minimoDeMuestras { return .sinHistorial }
        return nil
    }
}

extension RazonDeAhora {
    /// Una línea corta (máx. 8 palabras), con el tono de Lumi. `turno` cambia la manera de decirlo.
    func texto(turno: String = "") -> String {
        let v = turno.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0xFFFF } % 2
        switch self {
        case .planeada: return v == 0 ? Idioma.texto("La planeaste para esta hora.") : Idioma.texto("Tú la pusiste a esta hora.")
        case .noLeLlamo: return Idioma.texto("Antes no te llamó. ¿La hacemos distinta?")
        case .porque: return v == 0 ? Idioma.texto("Te importa, y hay energía para ella.") : Idioma.texto("Tiene su porqué, y te da la energía.")
        case .horaFuerte: return v == 0 ? Idioma.texto("Esta suele ser una de tus horas.") : Idioma.texto("A esta hora sueles rendir.")
        case .grandeCuesta: return v == 0 ? Idioma.texto("A esta hora lo grande cuesta: algo chico.") : Idioma.texto("Lo grande puede esperar; ahora, algo chico.")
        case .energiaBajando: return v == 0 ? Idioma.texto("Tu energía va bajando: algo pequeño.") : Idioma.texto("Viene bajando la energía; algo corto.")
        case .sinHistorial: return v == 0 ? Idioma.texto("Empiezo por tu ritmo del registro.") : Idioma.texto("Por ahora sigo el ritmo que me contaste.")
        }
    }
}
