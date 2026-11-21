import XCTest
@testable import ZENO

/// Tests de las funciones puras del cerebro: energía, aprendizaje, modo silencioso y salud.
/// Fechas y calendario fijos para que den siempre lo mismo.
@MainActor
final class CerebroTests: XCTestCase {
    /// Un martes cualquiera a las 10:00 (UTC).
    let ahora = Date(timeIntervalSince1970: 1_800_007_200)
    var utc: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    func senal(_ tipo: TipoDeEvento, haceMin minutos: Double = 0, hora: Int = 10, valor: Double? = nil,
               tamano: TamanoDeTarea? = nil, tipoDeTarea: TipoDeTarea? = nil, motivo: MotivoDeRechazo? = nil) -> Senal {
        Senal(tipo: tipo, fecha: ahora.addingTimeInterval(-minutos * 60), franjaHoraria: hora, valor: valor,
              tamano: tamano, tipoDeTarea: tipoDeTarea, motivo: motivo)
    }

    // MARK: Curva base

    func testCurvaBaseCimaEnLaHoraPico() {
        let pico = MotorDeEnergia.curvaBase(hora: 10, despertar: 7, pico: 10, apagado: 22)
        let tarde = MotorDeEnergia.curvaBase(hora: 16, despertar: 7, pico: 10, apagado: 22)
        XCTAssertGreaterThan(pico, tarde)
        XCTAssertGreaterThanOrEqual(pico, 67, "en su pico la energía es alta")
    }

    func testCurvaBaseDormidoEsBaja() {
        XCTAssertEqual(MotorDeEnergia.curvaBase(hora: 3, despertar: 7, pico: 10, apagado: 22), 10)
    }

    func testCurvaBaseSiempreEntreLimites() {
        for h in stride(from: 0.0, to: 24, by: 0.5) {
            let e = MotorDeEnergia.curvaBase(hora: h, despertar: 7, pico: 10, apagado: 22)
            XCTAssert((8...95).contains(e), "hora \(h): \(e)")
        }
    }

    func testNiveles() {
        XCTAssertEqual(MotorDeEnergia.nivel(20), .baja)
        XCTAssertEqual(MotorDeEnergia.nivel(34), .media)
        XCTAssertEqual(MotorDeEnergia.nivel(66), .media)
        XCTAssertEqual(MotorDeEnergia.nivel(67), .alta)
    }

    func testPuntajeNuncaLlegaACero() {
        let persona = Persona(nombre: "Prueba", nacimientoAnio: 1999, nacimientoMes: 6, nacimientoDia: 15)
        let rechazos = (0..<20).map { senal(.ahoraNo, haceMin: Double($0)) }
        let p = MotorDeEnergia.puntaje(persona: persona, eventos: rechazos, ahora: ahora, calendario: utc)
        XCTAssertGreaterThanOrEqual(p, 8)
    }

    // MARK: Lo aprendido y lo de hoy

    func testTerminarSubeYAhoraNoBaja() {
        let terminadas = (1...3).map { senal(.tareaTerminada, haceMin: Double($0) * 1440) }
        let rechazos = (1...3).map { senal(.ahoraNo, haceMin: Double($0) * 1440) }
        XCTAssertGreaterThan(MotorDeEnergia.ajusteAprendido(franja: 10, eventos: terminadas, ahora: ahora), 0)
        XCTAssertLessThan(MotorDeEnergia.ajusteAprendido(franja: 10, eventos: rechazos, ahora: ahora), 0)
        XCTAssertEqual(MotorDeEnergia.ajusteAprendido(franja: 18, eventos: terminadas, ahora: ahora), 0,
                       "lo de las 10 no cambia las 18")
    }

    func testAjusteDeHoyLimitado() {
        let muchos = (0..<30).map { senal(.ahoraNo, haceMin: Double($0)) }
        XCTAssertGreaterThanOrEqual(MotorDeEnergia.ajusteDeHoy(eventos: muchos, ahora: ahora, calendario: utc), -25)
    }

    // MARK: Modo compañero silencioso

    func testTresAhoraNoSeguidosEsSilencio() {
        let tres = (1...3).map { senal(.ahoraNo, haceMin: Double($0) * 5) }.reversed()
        XCTAssertEqual(MotorDeEnergia.ahoraNoSeguidos(eventos: Array(tres), ahora: ahora), 3)
        XCTAssertTrue(MotorDeEnergia.tocaSilencio(puntaje: 70, eventos: Array(tres), ahora: ahora))
    }

    func testEmpezarCortaLaCuenta() {
        let eventos = [senal(.ahoraNo, haceMin: 30), senal(.ahoraNo, haceMin: 20), senal(.tareaEmpezada, haceMin: 10),
                       senal(.ahoraNo, haceMin: 5)]
        XCTAssertEqual(MotorDeEnergia.ahoraNoSeguidos(eventos: eventos, ahora: ahora), 1)
        XCTAssertFalse(MotorDeEnergia.tocaSilencio(puntaje: 70, eventos: eventos, ahora: ahora))
    }

    func testAhoraNoViejosNoCuentan() {
        let viejos = (1...3).map { senal(.ahoraNo, haceMin: 200 + Double($0)) }
        XCTAssertEqual(MotorDeEnergia.ahoraNoSeguidos(eventos: viejos, ahora: ahora), 0)
    }

    func testEnergiaMuyBajaEsSilencio() {
        XCTAssertTrue(MotorDeEnergia.tocaSilencio(puntaje: MotorDeEnergia.umbralDeSilencio - 1, eventos: [], ahora: ahora))
        XCTAssertFalse(MotorDeEnergia.tocaSilencio(puntaje: 40, eventos: [], ahora: ahora))
    }

    // MARK: "No quiero" frente a "No puedo"

    func testNoMeLlamaNoCambiaElPuntaje() {
        let persona = Persona(nombre: "Prueba", nacimientoAnio: 1999, nacimientoMes: 6, nacimientoDia: 15)
        let base = [senal(.abrioLaApp, haceMin: 60)]
        let sinNada = MotorDeEnergia.puntaje(persona: persona, eventos: base, ahora: ahora, calendario: utc)
        let conNoMeLlama = MotorDeEnergia.puntaje(persona: persona, eventos: base + [senal(.ahoraNo, haceMin: 5, motivo: .noMeLlama)],
                                                  ahora: ahora, calendario: utc)
        XCTAssertEqual(sinNada, conNoMeLlama, accuracy: 0.0001)
        let viejos = (1...3).map { senal(.ahoraNo, haceMin: Double($0) * 1440, motivo: .noMeLlama) }
        XCTAssertEqual(MotorDeEnergia.ajusteAprendido(franja: 10, eventos: viejos, ahora: ahora), 0)
    }

    func testSinPilasSiBajaElPuntaje() {
        let persona = Persona(nombre: "Prueba", nacimientoAnio: 1999, nacimientoMes: 6, nacimientoDia: 15)
        let base = [senal(.abrioLaApp, haceMin: 60)]
        let sinNada = MotorDeEnergia.puntaje(persona: persona, eventos: base, ahora: ahora, calendario: utc)
        let sinPilas = MotorDeEnergia.puntaje(persona: persona, eventos: base + [senal(.ahoraNo, haceMin: 5, motivo: .sinPilas)],
                                              ahora: ahora, calendario: utc)
        XCTAssertLessThan(sinPilas, sinNada)
    }

    func testEventosViejosSinMotivoSiguenIgual() {
        let persona = Persona(nombre: "Prueba", nacimientoAnio: 1999, nacimientoMes: 6, nacimientoDia: 15)
        let base = [senal(.abrioLaApp, haceMin: 60)]
        let sinMotivo = MotorDeEnergia.puntaje(persona: persona, eventos: base + [senal(.ahoraNo, haceMin: 5)], ahora: ahora, calendario: utc)
        let sinPilas = MotorDeEnergia.puntaje(persona: persona, eventos: base + [senal(.ahoraNo, haceMin: 5, motivo: .sinPilas)], ahora: ahora, calendario: utc)
        XCTAssertEqual(sinMotivo, sinPilas, accuracy: 0.0001, "sin motivo cuenta como siempre (cansancio)")
    }

    func testNoMeLlamaNoLlevaAlSilencio() {
        let tres = (1...3).map { senal(.ahoraNo, haceMin: Double(4 - $0) * 5, motivo: .noMeLlama) }
        XCTAssertFalse(MotorDeEnergia.tocaSilencio(puntaje: 70, eventos: tres, ahora: ahora))
    }

    // MARK: "Por qué ahora"

    func testRazonPlaneada() {
        let t = Tarea(titulo: "Llamar a mamá", tamano: .chica)
        t.fechaPlaneada = ahora.addingTimeInterval(10 * 60)
        XCTAssertEqual(MotorDeEnergia.razon(tarea: t, puntaje: 50, eventos: [], horasDelDia: [], hayGrandes: false,
                                            ahora: ahora, calendario: utc), .planeada)
    }

    func testRazonNuncaDicePlaneadaSiNoLoEsta() {
        let t = Tarea(titulo: "Llamar a mamá", tamano: .chica)
        t.fechaPlaneada = ahora.addingTimeInterval(5 * 3600)
        XCTAssertNotEqual(MotorDeEnergia.razon(tarea: t, puntaje: 50, eventos: [], horasDelDia: [], hayGrandes: false,
                                               ahora: ahora, calendario: utc), .planeada)
    }

    func testRazonPorqueSoloConEnergia() {
        let t = Tarea(titulo: "Escribir el cuento", tamano: .mediana)
        t.porque = "Mi sobrina"
        XCTAssertEqual(MotorDeEnergia.razon(tarea: t, puntaje: 60, eventos: [], horasDelDia: [], hayGrandes: false,
                                            ahora: ahora, calendario: utc), .porque)
        XCTAssertNotEqual(MotorDeEnergia.razon(tarea: t, puntaje: 20, eventos: [], horasDelDia: [], hayGrandes: false,
                                               ahora: ahora, calendario: utc), .porque)
    }

    func testRazonSinHistorial() {
        let t = Tarea(titulo: "Ordenar", tamano: .mediana)
        XCTAssertEqual(MotorDeEnergia.razon(tarea: t, puntaje: 50, eventos: [], horasDelDia: [], hayGrandes: false,
                                            ahora: ahora, calendario: utc), .sinHistorial)
    }

    func testRazonEnergiaBajando() {
        let t = Tarea(titulo: "Responder a Ana", tamano: .chica)
        var horas = [Double](repeating: 40, count: 24)
        horas[9] = 60; horas[10] = 55; horas[11] = 45
        let terminadas = (1...3).map { senal(.tareaTerminada, haceMin: Double($0) * 1440, hora: 20) }
        XCTAssertEqual(MotorDeEnergia.razon(tarea: t, puntaje: 50, eventos: terminadas, horasDelDia: horas, hayGrandes: false,
                                            ahora: ahora, calendario: utc), .energiaBajando)
    }

    func testRazonTextoCorto() {
        for r in [RazonDeAhora.planeada, .noLeLlamo, .porque, .horaFuerte, .grandeCuesta, .energiaBajando, .sinHistorial] {
            for turno in ["a", "b", "c"] {
                XCTAssertLessThanOrEqual(r.texto(turno: turno).split(separator: " ").count, 8, "\(r)")
            }
        }
    }

    // MARK: Vuelta amable

    func testDeVueltaTrasTresDias() {
        let antes = [senal(.abrioLaApp, haceMin: 4 * 1440), senal(.abrioLaApp, haceMin: 1)]
        XCTAssertTrue(MotorDeEnergia.deVuelta(eventos: antes, ahora: ahora, calendario: utc))
        let ayer = [senal(.abrioLaApp, haceMin: 1440), senal(.abrioLaApp, haceMin: 1)]
        XCTAssertFalse(MotorDeEnergia.deVuelta(eventos: ayer, ahora: ahora, calendario: utc))
        XCTAssertFalse(MotorDeEnergia.deVuelta(eventos: [], ahora: ahora, calendario: utc), "la primera vez no es una vuelta")
        XCTAssertFalse(MotorDeEnergia.deVuelta(eventos: antes + [senal(.tareaTerminada, haceMin: 0)], ahora: ahora, calendario: utc),
                       "tras terminar algo hoy, todo vuelve a lo normal")
    }

    // MARK: Elegir (con el porqué)

    func testConEnergiaAltaVaPrimeroLaQueTienePorque() {
        let sin = Tarea(titulo: "Ordenar cajones", tamano: .mediana)
        let con = Tarea(titulo: "Escribir el cuento", tamano: .mediana)
        con.porque = "Me encanta inventar historias"
        guard case .tarea(let elegida) = MotorDeEnergia.elegir(pendientes: [sin, con], puntaje: 60, eventos: [], ahora: ahora)
        else { return XCTFail("debía proponer una tarea") }
        XCTAssertEqual(elegida.titulo, "Escribir el cuento")
    }

    func testSinPendientesNoHayNada() {
        guard case .nadaPendiente = MotorDeEnergia.elegir(pendientes: [], puntaje: 60, eventos: [], ahora: ahora)
        else { return XCTFail() }
    }

    // MARK: Aprendizaje

    func testMinutosRealesNecesitaTresMuestras() {
        let dos = [senal(.tareaTerminada, valor: 600, tamano: .mediana), senal(.tareaTerminada, valor: 900, tamano: .mediana)]
        XCTAssertNil(Aprendizaje.minutosReales(.mediana, eventos: dos))
        let tres = dos + [senal(.tareaTerminada, valor: 1200, tamano: .mediana)]
        XCTAssertEqual(Aprendizaje.minutosReales(.mediana, eventos: tres), 15)
    }

    func testSuelePosponerLoGrandeYLoMandaAlFinal() {
        let eventos = (1...4).map { senal(.ahoraNo, haceMin: Double($0) * 1440, tamano: .grande) }
            + [senal(.tareaEmpezada, haceMin: 5 * 1440, tamano: .grande)]
        XCTAssertTrue(Aprendizaje.suelePosponer(.grande, franja: 10, eventos: eventos, ahora: ahora))
        XCTAssertEqual(Aprendizaje.ordenar([.grande, .mediana, .chica], franja: 10, eventos: eventos, ahora: ahora),
                       [.mediana, .chica, .grande])
    }

    func testTipoQueCuestaNecesitaDatos() {
        XCTAssertFalse(Aprendizaje.leCuesta(tipo: .llamada, eventos: [], ahora: ahora))
        let llamadas = (1...3).map { senal(.ahoraNo, haceMin: Double($0) * 1440, tipoDeTarea: .llamada) }
        XCTAssertTrue(Aprendizaje.leCuesta(tipo: .llamada, eventos: llamadas, ahora: ahora))
        XCTAssertFalse(Aprendizaje.leCuesta(tipo: nil, eventos: llamadas, ahora: ahora))
    }

    func testPatronDeAhora() {
        let grandes = (1...4).map { senal(.ahoraNo, haceMin: Double($0) * 1440, tamano: .grande) }
        XCTAssertEqual(Aprendizaje.patronDeAhora(propuesta: .chica, tipo: nil, hayGrandes: true, nivel: .alta,
                                                 franja: 10, eventos: grandes, ahora: ahora), .grandeCuestaAEstaHora)
        XCTAssertNil(Aprendizaje.patronDeAhora(propuesta: .chica, tipo: nil, hayGrandes: true, nivel: .media,
                                               franja: 10, eventos: grandes, ahora: ahora),
                     "con energía media lo grande no iba primero: no hay nada que contar")
    }

    func testTipoDeTarea() {
        XCTAssertEqual(TipoDeTarea.de("Llamar al dentista"), .llamada)
        XCTAssertEqual(TipoDeTarea.de("Renovar el pasaporte"), .tramite)
        XCTAssertEqual(TipoDeTarea.de("Call mom"), .llamada)
        XCTAssertNil(TipoDeTarea.de("Pasear"))
    }

    // MARK: Salud (señal C)

    func testSaludSinDatosNoCambiaNada() {
        XCTAssertEqual(MotorDeEnergia.ajusteDeSalud(nil), 0)
        XCTAssertEqual(MotorDeEnergia.ajusteDeSalud(SenalDeSalud()), 0)
    }

    func testSaludSuaveYLimitada() {
        XCTAssertLessThan(MotorDeEnergia.ajusteDeSalud(SenalDeSalud(horasDeSueno: 4.5)), 0)
        XCTAssertGreaterThan(MotorDeEnergia.ajusteDeSalud(SenalDeSalud(horasDeSueno: 8)), 0)
        let peor = SenalDeSalud(horasDeSueno: 3, pulsoEnReposo: 90, pulsoHabitual: 60)
        XCTAssertGreaterThanOrEqual(MotorDeEnergia.ajusteDeSalud(peor), -12)
    }

    // MARK: Anillo

    func testAnilloBajaSuLuzPasados10Minutos() {
        // (La vista solo la usa en tareas divididas; una tarea larga conserva su luz.)
        XCTAssertEqual(AnilloDeTiempoView.intensidad(segundos: 5 * 60), 1)
        XCTAssertEqual(AnilloDeTiempoView.intensidad(segundos: 10 * 60), 1)
        XCTAssertLessThan(AnilloDeTiempoView.intensidad(segundos: 12 * 60), 1)
        XCTAssertEqual(AnilloDeTiempoView.intensidad(segundos: 30 * 60), 0.4, accuracy: 0.001, "tenue, nunca apagado")
    }
}
