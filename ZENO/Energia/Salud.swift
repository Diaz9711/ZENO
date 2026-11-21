import Foundation
#if canImport(HealthKit)
import HealthKit
#endif

// SEÑAL C (opcional, "modo bienestar"; Diaz, 20 nov 2026). PREPARADA, APAGADA.
// Sueño y pulso en reposo como una pista más de energía. Es bienestar, nunca diagnóstico.
// Sin datos de Salud (lo normal hoy), ZENO funciona exactamente igual con las señales A y B.
// Reglas: estos datos nunca van a ninguna IA (ni la local), nunca salen del iPhone y nunca se
// guardan en `Compartido/` (lo vería el widget).
// Para encenderla hace falta: la cuenta de desarrollador de pago, la capacidad HealthKit en Xcode,
// el texto NSHealthShareUsageDescription en Info.plist y un interruptor en Ajustes. Mientras tanto,
// `LectorDeSalud.disponible` es false y nada de esto corre.

/// Lo que se leería de Salud: solo dos números de la última noche y de los últimos días.
struct SenalDeSalud: Equatable {
    /// Horas dormidas la última noche.
    var horasDeSueno: Double?
    /// Pulso en reposo de hoy y su promedio de las últimas semanas (lo normal para esta persona).
    var pulsoEnReposo: Double?
    var pulsoHabitual: Double?
}

extension MotorDeEnergia {
    /// C. Un ajuste pequeño desde Salud (función pura). nil = sin datos = 0: nada cambia.
    /// Dormir poco baja un poco la energía esperada; dormir bien la sube un poco. Un pulso en reposo
    /// bastante por encima de lo habitual (cansancio, estrés) la baja un poco. Siempre suave.
    static func ajusteDeSalud(_ salud: SenalDeSalud?) -> Double {
        guard let salud else { return 0 }
        var ajuste = 0.0
        if let horas = salud.horasDeSueno, horas > 0 {
            if horas < 5 { ajuste -= 10 } else if horas < 6.5 { ajuste -= 5 } else if horas >= 7.5 { ajuste += 4 }
        }
        if let hoy = salud.pulsoEnReposo, let habitual = salud.pulsoHabitual, habitual > 0 {
            let diferencia = hoy - habitual
            if diferencia > 10 { ajuste -= 6 } else if diferencia > 5 { ajuste -= 3 }
        }
        return min(max(ajuste, -12), 6)
    }
}

/// Lee Salud cuando el modo bienestar esté encendido. Hoy está apagado: `ultima` siempre es nil.
final class LectorDeSalud: @unchecked Sendable {
    static let compartido = LectorDeSalud()

    /// Interruptor del modo bienestar (aún sin pantalla) y capacidad de Salud en este iPhone.
    /// Apagado a propósito hasta tener la capacidad HealthKit firmada.
    static let preparado = false
    var disponible: Bool {
        #if canImport(HealthKit)
        return Self.preparado && HKHealthStore.isHealthDataAvailable()
            && UserDefaults.standard.bool(forKey: "modoBienestar")
        #else
        return false
        #endif
    }

    /// La última lectura (nil sin permiso o sin datos).
    private(set) var ultima: SenalDeSalud?

    #if canImport(HealthKit)
    private let almacen = HKHealthStore()

    /// Pide permiso solo de lectura, solo sueño y pulso en reposo. Si dice que no, todo sigue igual.
    func pedirPermiso() async -> Bool {
        guard disponible else { return false }
        let tipos: Set<HKObjectType> = [HKCategoryType(.sleepAnalysis), HKQuantityType(.restingHeartRate)]
        do { try await almacen.requestAuthorization(toShare: [], read: tipos); return true } catch { return false }
    }

    /// Lee la última noche y el pulso en reposo (hoy y lo habitual de 28 días).
    func leer(ahora: Date = .now) async {
        guard disponible else { ultima = nil; return }
        let desde = ahora.addingTimeInterval(-18 * 3600)
        let sueno = try? await HKSampleQueryDescriptor(
            predicates: [.categorySample(type: HKCategoryType(.sleepAnalysis),
                                         predicate: HKQuery.predicateForSamples(withStart: desde, end: ahora))],
            sortDescriptors: []).result(for: almacen)
        let dormido = (sueno ?? []).filter {
            HKCategoryValueSleepAnalysis.allAsleepValues.map(\.rawValue).contains($0.value)
        }.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) } / 3600

        let pulsos = try? await HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: HKQuantityType(.restingHeartRate),
                                         predicate: HKQuery.predicateForSamples(withStart: ahora.addingTimeInterval(-28 * 86_400), end: ahora))],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)]).result(for: almacen)
        let unidad = HKUnit.count().unitDivided(by: .minute())
        let valores = (pulsos ?? []).map { $0.quantity.doubleValue(for: unidad) }
        ultima = SenalDeSalud(horasDeSueno: dormido > 0 ? dormido : nil,
                              pulsoEnReposo: valores.first,
                              pulsoHabitual: valores.count >= 5 ? valores.reduce(0, +) / Double(valores.count) : nil)
    }
    #endif
}
