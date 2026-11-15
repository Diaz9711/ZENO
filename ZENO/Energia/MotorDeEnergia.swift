import Foundation

enum NivelDeEnergia: Equatable {
    case baja, media, alta
}

/// Lo que ZENO decide mostrar en la pantalla de la tarea.
enum Eleccion {
    case tarea(Tarea)
    /// Energía baja y nada pequeño que ofrecer: permiso de descansar.
    case descanso
    /// Todo lo pendiente recibió un "Ahora no" hace poco: se intenta más tarde.
    case masTarde
    case nadaPendiente
}

/// Calcula el puntaje de energía (0–100) sin permisos de salud, con dos señales:
///   A. la curva base del cronotipo (las tres respuestas del registro), y
///   B. el comportamiento dentro de la app (lo aprendido por hora + lo que pasa hoy).
/// Todo sale del historial de eventos, así que siempre se puede recalcular.
/// En la versión 2 aquí cabe una tercera señal (salud) sumando otro ajuste.
enum MotorDeEnergia {

    // MARK: Puntaje

    static func puntaje(persona: Persona, eventos: [Senal], ahora: Date = .now,
                        calendario: Calendar = .current) -> Double {
        let c = calendario.dateComponents([.hour, .minute], from: ahora)
        let hora = Double(c.hour ?? 12) + Double(c.minute ?? 0) / 60
        let base = curvaBase(hora: hora, despertar: persona.horaDespertar,
                             pico: persona.horaPico, apagado: persona.horaApagado)
        let aprendido = ajusteAprendido(franja: c.hour ?? 12, eventos: eventos, ahora: ahora)
        let hoy = ajusteDeHoy(eventos: eventos, ahora: ahora, calendario: calendario)
        // Nunca llega a cero: Lumi baja su luz para dar permiso de descansar, no como castigo.
        return min(max(base + aprendido + hoy, 8), 100)
    }

    static func nivel(_ puntaje: Double) -> NivelDeEnergia {
        puntaje >= 67 ? .alta : (puntaje >= 34 ? .media : .baja)
    }

    // MARK: A. Curva base por cronotipo

    /// Energía esperada a una hora del día, solo con las respuestas del registro.
    static func curvaBase(hora: Double, despertar: Double, pico: Double, apagado: Double) -> Double {
        func horasDesde(_ a: Double, _ b: Double) -> Double {
            let d = (b - a).truncatingRemainder(dividingBy: 24)
            return d < 0 ? d + 24 : d
        }
        var despierto = horasDesde(despertar, apagado)
        if despierto < 1 { despierto = 16 }
        let t = horasDesde(despertar, hora)
        if t > despierto { return 10 }            // hora de dormir

        let aPico = min(horasDesde(hora, pico), horasDesde(pico, hora))
        var e = 32 + 58 * exp(-(aPico * aPico) / (2 * 3.0 * 3.0))
        e *= min(1, 0.55 + 0.45 * t)              // la primera hora cuesta arrancar
        let restante = despierto - t
        if restante < 2 { e *= 0.6 + 0.2 * restante }   // las últimas horas se apagan
        return min(max(e, 8), 95)
    }

    // MARK: B1. Lo aprendido por franja horaria

    /// Confianza de una hora del día: sube cuando ahí se terminan tareas,
    /// baja con los "Ahora no". Los eventos viejos pesan cada vez menos.
    static func ajusteAprendido(franja: Int, eventos: [Senal], ahora: Date) -> Double {
        var suma = 0.0
        for evento in eventos {
            let dias = ahora.timeIntervalSince(evento.fecha) / 86_400
            guard dias >= 0, dias <= 28 else { continue }
            let distancia = min(abs(evento.franjaHoraria - franja), 24 - abs(evento.franjaHoraria - franja))
            let cercania: Double = distancia == 0 ? 1 : (distancia == 1 ? 0.5 : 0)
            guard cercania > 0 else { continue }

            let efecto: Double
            switch evento.tipo {
            case .tareaTerminada: efecto = 6
            case .tareaEmpezada: efecto = 2
            case .ahoraNo, .tareaIgnorada: efecto = -5
            case .cerroSinHacerNada: efecto = -3
            default: efecto = 0
            }
            suma += efecto * cercania * exp(-dias / 14)
        }
        return min(max(suma, -25), 25)
    }

    // MARK: B2. Lo que pasa hoy

    static func ajusteDeHoy(eventos: [Senal], ahora: Date, calendario: Calendar = .current) -> Double {
        let deHoy = eventos.filter { calendario.isDate($0.fecha, inSameDayAs: ahora) && $0.fecha <= ahora }
        var ajuste = 0.0

        // "Ahora no" recientes: la persona no está para eso en este rato.
        let rechazos = deHoy.filter { $0.tipo == .ahoraNo && ahora.timeIntervalSince($0.fecha) < 90 * 60 }.count
        ajuste -= min(Double(rechazos) * 6, 18)

        // Abrir y cerrar sin hacer nada.
        let vacios = deHoy.filter { $0.tipo == .cerroSinHacerNada }.count
        ajuste -= min(Double(vacios) * 4, 12)

        // Cuánto tarda en empezar la primera tarea del día.
        if let abrio = deHoy.filter({ $0.tipo == .abrioLaApp }).map(\.fecha).min() {
            if let empezo = deHoy.filter({ $0.tipo == .tareaEmpezada }).map(\.fecha).min() {
                let minutos = empezo.timeIntervalSince(abrio) / 60
                if minutos < 5 { ajuste += 4 } else if minutos > 30 { ajuste -= 5 }
            } else if ahora.timeIntervalSince(abrio) > 45 * 60 {
                ajuste -= 4
            }
        }

        // Qué tan rápido termina hoy frente a su promedio.
        let duraciones = eventos.filter { $0.tipo == .tareaTerminada }.compactMap(\.valor).filter { $0 > 0 }
        let duracionesHoy = deHoy.filter { $0.tipo == .tareaTerminada }.compactMap(\.valor).filter { $0 > 0 }
        if duraciones.count >= 3, !duracionesHoy.isEmpty {
            let promedio = duraciones.reduce(0, +) / Double(duraciones.count)
            let hoy = duracionesHoy.reduce(0, +) / Double(duracionesHoy.count)
            if hoy < promedio * 0.8 { ajuste += 5 } else if hoy > promedio * 1.3 { ajuste -= 4 }
        }

        return min(max(ajuste, -25), 12)
    }

    // MARK: Elegir la tarea del momento

    /// Energía alta: la más difícil. Media: una rutinaria. Baja: algo de dos minutos, o descanso.
    /// Lo que recibió un "Ahora no" hace menos de 90 minutos no se vuelve a ofrecer todavía.
    static func elegir(pendientes: [Tarea], puntaje: Double, eventos: [Senal],
                       quiereAlgoIgual: Bool = false, ahora: Date = .now) -> Eleccion {
        guard !pendientes.isEmpty else { return .nadaPendiente }

        let rechazadas = Set(eventos
            .filter { $0.tipo == .ahoraNo && ahora.timeIntervalSince($0.fecha) < 90 * 60 }
            .compactMap(\.tareaID))
        let calendario = Calendar.current
        let manana = calendario.startOfDay(for: ahora).addingTimeInterval(86_400)
        // Lo planeado para otro día no se propone hoy.
        let disponibles = pendientes.filter {
            !rechazadas.contains($0.persistentModelID) && ($0.fechaPlaneada.map { $0 < manana } ?? true)
        }
        guard !disponibles.isEmpty else {
            return pendientes.allSatisfy({ $0.fechaPlaneada.map { $0 >= manana } ?? false }) ? .nadaPendiente : .masTarde
        }

        // Lo que la persona planeó para este rato va primero, sin importar la energía:
        // ella ya decidió. (Si su hora pasó, vuelve a la cola normal, sin reproche.)
        if let planeada = disponibles
            .filter({ t in t.fechaPlaneada.map { abs($0.timeIntervalSince(ahora)) < 30 * 60 } ?? false })
            .min(by: { ($0.fechaPlaneada ?? ahora) < ($1.fechaPlaneada ?? ahora) }) {
            return .tarea(planeada)
        }

        // Lo aprendido: lo que suele posponer a esta hora pasa al final de la fila.
        let franja = calendario.component(.hour, from: ahora)
        func primera(_ tamanos: TamanoDeTarea...) -> Tarea? {
            for tamano in Aprendizaje.ordenar(tamanos, franja: franja, eventos: eventos, ahora: ahora) {
                if let tarea = disponibles.first(where: { $0.tamano == tamano }) { return tarea }
            }
            return nil
        }
        /// Algo de dos minutos: una tarea chica, o una que ya tenga su primer paso.
        var pequena: Tarea? {
            primera(.chica) ?? disponibles.first(where: { $0.primerPaso != nil })
        }

        switch nivel(puntaje) {
        case .alta:
            return .tarea(primera(.grande, .mediana, .chica) ?? disponibles[0])
        case .media:
            return .tarea(primera(.mediana, .chica, .grande) ?? disponibles[0])
        case .baja:
            if let tarea = pequena { return .tarea(tarea) }
            if quiereAlgoIgual { return .tarea(primera(.mediana, .grande) ?? disponibles[0]) }
            return .descanso
        }
    }

    // MARK: Para las notificaciones (Fase 7)

    /// La hora del día con más energía según la curva base y lo aprendido.
    static func mejorHora(persona: Persona, eventos: [Senal], ahora: Date = .now) -> Int {
        (0..<24).max { a, b in
            valor(a, persona, eventos, ahora) < valor(b, persona, eventos, ahora)
        } ?? Int(persona.horaPico)
    }

    private static func valor(_ hora: Int, _ persona: Persona, _ eventos: [Senal], _ ahora: Date) -> Double {
        curvaBase(hora: Double(hora) + 0.5, despertar: persona.horaDespertar,
                  pico: persona.horaPico, apagado: persona.horaApagado)
            + ajusteAprendido(franja: hora, eventos: eventos, ahora: ahora)
    }
}
