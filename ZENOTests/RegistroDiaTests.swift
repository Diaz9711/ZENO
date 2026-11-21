import XCTest
@testable import ZENO

/// Las tres horas del registro siempre forman un día válido (el pico dentro del día).
@MainActor
final class RegistroDiaTests: XCTestCase {
    func testPicoFueraDelDiaSeAjusta() {
        let tarde = DiaDeEnergia(despertar: 11, pico: 10, apagado: 22).ajustado()
        XCTAssertTrue(tarde.picoCabe(tarde.pico))
        XCTAssertEqual(tarde.pico, 13)
        let temprano = DiaDeEnergia(despertar: 5.5, pico: 21, apagado: 20.5).ajustado()
        XCTAssertTrue(temprano.picoCabe(temprano.pico))
    }

    func testApagadoDespuesDeMedianoche() {
        let noche = DiaDeEnergia(despertar: 9, pico: 21, apagado: 2)
        XCTAssertEqual(noche.horasDespierto, 17)
        XCTAssertTrue(noche.picoCabe(21))
    }

    func testTocarSiempreDaUnDiaValido() {
        var dia = DiaDeEnergia.comun
        for i in 0..<200 {
            dia = dia.siguiente(DiaDeEnergia.Parte.allCases[i % 3])
            XCTAssertTrue(dia.picoCabe(dia.pico), "\(dia)")
            XCTAssertTrue(DiaDeEnergia.opcionesDespertar.contains(dia.despertar))
            XCTAssertTrue(DiaDeEnergia.opcionesApagado.contains(dia.apagado))
        }
    }

    func testArrastrarVaALaOpcionMasCercana() {
        XCTAssertEqual(DiaDeEnergia.cercana(8.2, en: DiaDeEnergia.opcionesDespertar), 9)
        XCTAssertEqual(DiaDeEnergia.cercana(23.5, en: DiaDeEnergia.opcionesApagado), 0)
        XCTAssertEqual(DiaDeEnergia.hora(5.5), "5:30")
        XCTAssertEqual(DiaDeEnergia.hora(24), "0:00")
    }
}
