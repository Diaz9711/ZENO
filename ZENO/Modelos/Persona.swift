import Foundation
import SwiftData

/// La persona dueña de la estrella. En el MVP solo existe una.
@Model
final class Persona {
    var nombre: String

    // El nacimiento se guarda como día, mes y año (no como instante)
    // para que la estrella no cambie si la persona viaja de zona horaria.
    var nacimientoAnio: Int
    var nacimientoMes: Int
    var nacimientoDia: Int

    // Cronotipo: horas del día (0–23.99) respondidas en el registro.
    var horaDespertar: Double
    var horaPico: Double
    var horaApagado: Double

    // Ajustes
    /// La forma de Lumi que la persona eligió (0 = estrella, 1 = esfera). Puede cambiarla en Ajustes.
    var formaDeLumiCruda: Int = 0
    var mostrarEdad: Bool
    var notificacionesActivas: Bool

    var creadaEn: Date

    init(
        nombre: String,
        nacimientoAnio: Int,
        nacimientoMes: Int,
        nacimientoDia: Int,
        horaDespertar: Double = 7,
        horaPico: Double = 10,
        horaApagado: Double = 22
    ) {
        self.nombre = nombre
        self.nacimientoAnio = nacimientoAnio
        self.nacimientoMes = nacimientoMes
        self.nacimientoDia = nacimientoDia
        self.horaDespertar = horaDespertar
        self.horaPico = horaPico
        self.horaApagado = horaApagado
        self.mostrarEdad = true
        self.notificacionesActivas = false   // cero notificaciones por defecto
        self.creadaEn = .now
    }

    var formaDeLumi: FormaDeLumi {
        get { FormaDeLumi(rawValue: formaDeLumiCruda) ?? .estrella }
        set { formaDeLumiCruda = newValue.rawValue }
    }

    /// La huella de la que nace Lumi. Siempre la misma para la misma persona.
    var semilla: Semilla {
        Semilla(nombre: nombre, anio: nacimientoAnio, mes: nacimientoMes, dia: nacimientoDia)
    }

    /// Edad en años cumplidos.
    func edad(en fecha: Date = .now, calendario: Calendar = .current) -> Int {
        let hoy = calendario.dateComponents([.year, .month, .day], from: fecha)
        var edad = (hoy.year ?? nacimientoAnio) - nacimientoAnio
        let yaCumplio = (hoy.month ?? 1, hoy.day ?? 1) >= (nacimientoMes, nacimientoDia)
        if !yaCumplio { edad -= 1 }
        return max(edad, 0)
    }
}
