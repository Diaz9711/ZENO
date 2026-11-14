import Foundation

/// Lo que ZENO aprende de la persona, siempre desde el historial `EventoDeEnergia`
/// (en el teléfono). Funciones puras: lo mismo entra, lo mismo sale; se recalcula cada vez.
/// Mientras más se usa la app, más datos hay y más personal se vuelve. Nunca se usa para culpar:
/// lo que se pospone solo cambia el orden en que se proponen las cosas.
enum Aprendizaje {
    /// Muestras mínimas antes de confiar en algo aprendido (antes de eso, valores por defecto).
    static let minimoDeMuestras = 3

    /// El tamaño de la tarea de un evento, aunque la tarea ya no exista.
    static func tamano(de evento: EventoDeEnergia) -> TamanoDeTarea? {
        evento.tamanoCrudo.flatMap(TamanoDeTarea.init(rawValue:)) ?? evento.tarea?.tamano
    }

    // MARK: Cuánto tarda de verdad

    /// Minutos que de verdad le toma una tarea de ese tamaño (la mediana de las que terminó con el anillo).
    static func minutosReales(_ tamano: TamanoDeTarea, eventos: [EventoDeEnergia]) -> Double? {
        let duraciones = eventos
            .filter { $0.tipo == .tareaTerminada && tamano == Self.tamano(de: $0) && $0.tarea?.primerPaso == nil }
            .compactMap(\.valor)
            .filter { $0 > 30 && $0 < 4 * 3600 }      // descarta toques por error y olvidos
            .sorted()
        guard duraciones.count >= minimoDeMuestras else { return nil }
        let mitad = duraciones.count / 2
        let mediana = duraciones.count % 2 == 0 ? (duraciones[mitad - 1] + duraciones[mitad]) / 2 : duraciones[mitad]
        return min(max(mediana / 60, 2), 90)
    }

    /// Los minutos del anillo: lo aprendido si ya hay datos; si no, lo previsto (5, 15, 25).
    /// Un primer paso siempre es de dos minutos: es la promesa de ZENO.
    static func minutosPrevistos(_ tarea: Tarea, eventos: [EventoDeEnergia]) -> Double {
        if tarea.primerPaso != nil { return 2 }
        return (minutosReales(tarea.tamano, eventos: eventos)?.rounded()) ?? tarea.minutosPrevistos
    }

    // MARK: A qué horas rinde

    /// Las horas del día en que más termina tareas (con más peso lo reciente), de mejor a peor.
    static func horasFuertes(eventos: [EventoDeEnergia], ahora: Date = .now) -> [Int] {
        var peso = [Double](repeating: 0, count: 24)
        for e in eventos where e.tipo == .tareaTerminada {
            let dias = ahora.timeIntervalSince(e.fecha) / 86_400
            guard dias >= 0, dias <= 60 else { continue }
            peso[e.franjaHoraria] += exp(-dias / 21)
        }
        let total = eventos.filter { $0.tipo == .tareaTerminada }.count
        guard total >= minimoDeMuestras else { return [] }
        return (0..<24).filter { peso[$0] > 0 }.sorted { peso[$0] > peso[$1] }
    }

    /// Un rango legible "de 9 a 11": la hora más fuerte y su vecina más fuerte.
    static func franjaFuerte(eventos: [EventoDeEnergia], ahora: Date = .now) -> (desde: Int, hasta: Int)? {
        let horas = horasFuertes(eventos: eventos, ahora: ahora)
        guard let mejor = horas.first else { return nil }
        let vecina = horas.dropFirst().first { abs($0 - mejor) == 1 }
        let desde = min(mejor, vecina ?? mejor)
        return (desde, (max(mejor, vecina ?? mejor) + 1) % 24)
    }

    // MARK: Qué pospone

    /// Qué tan seguido dice "Ahora no" a un tamaño de tarea cerca de esta hora (±1 h), de 0 a 1.
    /// nil si aún no hay suficientes datos.
    static func tasaDePosponer(_ tamano: TamanoDeTarea, franja: Int, eventos: [EventoDeEnergia],
                               ahora: Date = .now) -> Double? {
        let cerca = eventos.filter { e in
            let d = abs(e.franjaHoraria - franja)
            return min(d, 24 - d) <= 1 && tamano == Self.tamano(de: e)
                && ahora.timeIntervalSince(e.fecha) < 45 * 86_400
        }
        let pospuestas = cerca.filter { $0.tipo == .ahoraNo }.count
        let decididas = pospuestas + cerca.filter { $0.tipo == .tareaEmpezada }.count
        guard decididas >= minimoDeMuestras else { return nil }
        return Double(pospuestas) / Double(decididas)
    }

    /// ¿Suele posponer este tamaño a esta hora? Entonces se le propone otra cosa primero.
    static func suelePosponer(_ tamano: TamanoDeTarea, franja: Int, eventos: [EventoDeEnergia],
                              ahora: Date = .now) -> Bool {
        (tasaDePosponer(tamano, franja: franja, eventos: eventos, ahora: ahora) ?? 0) >= 0.6
    }

    /// El orden de tamaños que pide la energía, ajustado a lo aprendido: lo que suele posponer
    /// a esta hora pasa al final (sigue disponible, solo no va primero).
    static func ordenar(_ tamanos: [TamanoDeTarea], franja: Int, eventos: [EventoDeEnergia],
                        ahora: Date = .now) -> [TamanoDeTarea] {
        let comodos = tamanos.filter { !suelePosponer($0, franja: franja, eventos: eventos, ahora: ahora) }
        let pospuestos = tamanos.filter { suelePosponer($0, franja: franja, eventos: eventos, ahora: ahora) }
        return comodos + pospuestos
    }

    // MARK: Lo que la persona puede leer

    /// Frases amables de lo aprendido, para Ajustes. Vacío si aún no hay datos.
    static func resumen(eventos: [EventoDeEnergia], ahora: Date = .now) -> [String] {
        var frases: [String] = []
        if let franja = franjaFuerte(eventos: eventos, ahora: ahora) {
            frases.append(Idioma.texto("Sueles terminar más cosas entre las \(franja.desde):00 y las \(franja.hasta):00. Ahí te propongo lo que pide más de ti."))
        }
        for tamano in TamanoDeTarea.allCases {
            if let minutos = minutosReales(tamano, eventos: eventos) {
                let m = Int(minutos.rounded())
                switch tamano {
                case .chica: frases.append(Idioma.texto("Una tarea chica te toma unos \(m) minutos."))
                case .mediana: frases.append(Idioma.texto("Una tarea mediana te toma unos \(m) minutos."))
                case .grande: frases.append(Idioma.texto("Una tarea grande te toma unos \(m) minutos."))
                }
            }
        }
        let hora = Calendar.current.component(.hour, from: ahora)
        if suelePosponer(.grande, franja: hora, eventos: eventos, ahora: ahora) {
            frases.append(Idioma.texto("A esta hora las tareas grandes suelen esperar; te propongo antes otras más ligeras."))
        }
        return frases
    }
}
