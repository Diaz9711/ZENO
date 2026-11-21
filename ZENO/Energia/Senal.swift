import Foundation
import SwiftData

/// Una copia ligera de un `EventoDeEnergia`: solo los datos que usa el cerebro, en memoria.
/// Leer el historial directamente de SwiftData en cada redibujado (y abrir la tarea de cada evento)
/// hacía que la app se sintiera lenta a medida que el historial crecía. El cerebro trabaja con esto.
struct Senal: Equatable {
    var tipo: TipoDeEvento?
    var fecha: Date
    var franjaHoraria: Int
    var valor: Double?
    /// Tamaño de la tarea en ese momento (guardado en el evento, o el de la tarea si es antiguo).
    var tamano: TamanoDeTarea?
    var tareaID: PersistentIdentifier?
    /// La tarea tenía un primer paso de dos minutos.
    var conPrimerPaso: Bool
    /// Tipo de la tarea (llamada, trámite…), si se sabe.
    var tipoDeTarea: TipoDeTarea?

    init(tipo: TipoDeEvento?, fecha: Date, franjaHoraria: Int, valor: Double? = nil,
         tamano: TamanoDeTarea? = nil, tareaID: PersistentIdentifier? = nil, conPrimerPaso: Bool = false,
         tipoDeTarea: TipoDeTarea? = nil) {
        self.tipo = tipo
        self.fecha = fecha
        self.franjaHoraria = franjaHoraria
        self.valor = valor
        self.tamano = tamano
        self.tareaID = tareaID
        self.conPrimerPaso = conPrimerPaso
        self.tipoDeTarea = tipoDeTarea
    }

    init(_ e: EventoDeEnergia) {
        let tarea = e.tarea
        self.init(tipo: e.tipo, fecha: e.fecha, franjaHoraria: e.franjaHoraria, valor: e.valor,
                  tamano: e.tamanoCrudo.flatMap(TamanoDeTarea.init(rawValue:)) ?? tarea?.tamano,
                  tareaID: tarea?.persistentModelID, conPrimerPaso: tarea?.primerPaso != nil,
                  tipoDeTarea: e.tipoDeTareaCrudo.flatMap(TipoDeTarea.init(rawValue:)) ?? tarea.flatMap { TipoDeTarea.de($0.titulo) })
    }
}

extension Array where Element == EventoDeEnergia {
    /// Copia ligera, recordando lo ya copiado: solo se leen de la base de datos los eventos nuevos.
    var senales: [Senal] { Memoria.compartida.senales(de: self) }
}

/// Recuerda las copias ligeras y los cálculos del cerebro para no repetirlos en cada redibujado.
/// No es observable a propósito: las vistas ya se redibujan cuando cambia el historial.
final class Memoria {
    static let compartida = Memoria()

    private var porID: [PersistentIdentifier: Senal] = [:]
    private var firma: Firma?
    private var copia: [Senal] = []

    private struct Firma: Equatable {
        var cuantos: Int
        var ultimo: PersistentIdentifier?
        var ultimaTarea: PersistentIdentifier?
    }

    func senales(de eventos: [EventoDeEnergia]) -> [Senal] {
        let nueva = Firma(cuantos: eventos.count, ultimo: eventos.last?.persistentModelID,
                          ultimaTarea: eventos.last?.tarea?.persistentModelID)
        if nueva == firma { return copia }
        var vistos = Set<PersistentIdentifier>()
        copia = eventos.map { e in
            let id = e.persistentModelID
            vistos.insert(id)
            if let ya = porID[id], ya.tareaID != nil || e.tarea == nil { return ya }
            let s = Senal(e)
            porID[id] = s
            return s
        }
        // Lo borrado se olvida.
        if porID.count > vistos.count { porID = porID.filter { vistos.contains($0.key) } }
        firma = nueva
        return copia
    }

    // MARK: Cálculos recordados (se repiten solo si cambia el historial, la hora o la persona)

    private struct Clave: Hashable {
        var cuantos: Int
        var ultima: Date?
        var minuto: Int
        var persona: [Double]
    }
    private var clave: Clave?
    private var puntajeGuardado = 72.0
    private var mejorHoraGuardada = 12

    private var claveResumen: String?
    private var resumenGuardado: [String] = []

    /// "Tu ritmo" en Ajustes: se recalcula solo si cambió el historial, la hora o el idioma.
    func resumen(senales: [Senal]) -> [String] {
        let c = "\(senales.count)|\(senales.last?.fecha.timeIntervalSince1970 ?? 0)|\(Int(Date.now.timeIntervalSince1970 / 3600))|\(Idioma.actual.rawValue)"
        if c != claveResumen {
            resumenGuardado = Aprendizaje.resumen(eventos: senales)
            claveResumen = c
        }
        return resumenGuardado
    }

    /// La energía de cada hora (para la curva de Hoy), calculada junto con el cerebro.
    private(set) var horasGuardadas: [Double] = []

    func cerebro(persona: Persona, senales: [Senal], ahora: Date) -> (puntaje: Double, mejorHora: Int) {
        let c = Clave(cuantos: senales.count, ultima: senales.last?.fecha,
                      minuto: Int(ahora.timeIntervalSinceReferenceDate / 60),
                      persona: [persona.horaDespertar, persona.horaPico, persona.horaApagado])
        if c != clave {
            puntajeGuardado = MotorDeEnergia.puntaje(persona: persona, eventos: senales, ahora: ahora)
            mejorHoraGuardada = MotorDeEnergia.mejorHora(persona: persona, eventos: senales, ahora: ahora)
            horasGuardadas = MotorDeEnergia.horasDelDia(persona: persona, eventos: senales, ahora: ahora)
            clave = c
        }
        return (puntajeGuardado, mejorHoraGuardada)
    }
}
