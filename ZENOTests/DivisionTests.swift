import XCTest
@testable import ZENO

/// Tests de Divídemela, la captura por voz y los avisos (todo lo que se puede comprobar sin la IA).
@MainActor
final class DivisionTests: XCTestCase {

    // MARK: Pasos

    func testValidarPasos() {
        XCTAssertNotNil(ServicioDeIA.validarPasos(["Abre el archivo", "Escribe el título", "Escribe 3 ideas"]))
        XCTAssertNil(ServicioDeIA.validarPasos(["Uno", "Dos"]), "menos de 3 pasos")
        XCTAssertNil(ServicioDeIA.validarPasos(Array(repeating: "Igual", count: 5)), "repetidos")
        XCTAssertNil(ServicioDeIA.validarPasos((1...8).map { "Paso distinto \($0)" }), "más de 7")
        XCTAssertEqual(ServicioDeIA.validarPasos(["1. Abre", "- Lee", "• Escribe"]), ["Abre", "Lee", "Escribe"])
    }

    func testPlantillaSiempreValida() {
        for tamano in TamanoDeTarea.allCases {
            for energia in [NivelDeEnergia.baja, .media, .alta] {
                for pequenos in [false, true] {
                    for idioma in [Idioma.espanol, .ingles] {
                        let p = PedidoDeDivision(titulo: "Preparar la presentación", tamano: tamano, energia: energia,
                                                 idioma: idioma, masPequenos: pequenos)
                        XCTAssertNotNil(ServicioDeIA.validarPasos(MotorSimple.plantilla(p)), "\(tamano) \(energia) \(pequenos) \(idioma)")
                    }
                }
            }
        }
    }

    func testLoQueCuestaDaPasosMasPequenos() {
        let normal = MotorSimple.plantilla(PedidoDeDivision(titulo: "Llamar al banco", tamano: .mediana, energia: .media, idioma: .espanol))
        let pequenos = MotorSimple.plantilla(PedidoDeDivision(titulo: "Llamar al banco", tamano: .mediana, energia: .media,
                                                              idioma: .espanol, masPequenos: true))
        XCTAssertGreaterThan(pequenos.count, normal.count)
        XCTAssertTrue(pequenos.contains { $0.contains("2 minutos") })
    }

    func testConEnergiaBajaMenosPasos() {
        let baja = MotorSimple.plantilla(PedidoDeDivision(titulo: "Limpiar", tamano: .mediana, energia: .baja, idioma: .espanol))
        let media = MotorSimple.plantilla(PedidoDeDivision(titulo: "Limpiar", tamano: .mediana, energia: .media, idioma: .espanol))
        XCTAssertLessThan(baja.count, media.count)
    }

    func testCrisis() {
        XCTAssertTrue(Cuidado.suenaACrisis("ya no quiero vivir"))
        XCTAssertTrue(Cuidado.suenaACrisis("I want to die"))
        XCTAssertFalse(Cuidado.suenaACrisis("Preparar la presentación del lunes"))
    }

    func testElPorqueConCrisisNoSeRepite() {
        let t = Tarea(titulo: "Escribir")
        t.porque = "  Me hace feliz  "
        XCTAssertEqual(t.anzuelo, "Me hace feliz")
        t.porque = "no quiero vivir"
        XCTAssertNil(t.anzuelo)
        t.porque = "   "
        XCTAssertNil(t.anzuelo)
    }

    // MARK: Captura por voz

    func testSinIANoSePartePorPuntos() {
        XCTAssertEqual(MotorSimple.partirPorConectores("Comprar pan. Llamar a Ana, luego ver"), ["Comprar pan. Llamar a Ana, luego ver"])
    }

    func testSinIASeparaPorConectores() {
        XCTAssertEqual(MotorSimple.partirPorConectores("llama al dentista mañana a las cinco y después revisa el correo"),
                       ["Llama al dentista mañana a las cinco", "Revisa el correo"])
        XCTAssertEqual(MotorSimple.partirPorConectores("email my boss and then clean the kitchen"),
                       ["Email my boss", "Clean the kitchen"])
    }

    func testCapturaAceptaOtraFormaDelVerbo() {
        let dicho = "llama al dentista mañana a las cinco y después revisa el correo"
        let r = ServicioDeIA.validarCaptura([(titulo: "Llamar al dentista", tamano: .chica, cuando: "mañana a las 5"),
                                             (titulo: "revisar el correo", tamano: .chica, cuando: "")], dicho: dicho)
        XCTAssertEqual(r?.map(\.titulo), ["Llamar al dentista", "Revisar el correo"])
        XCTAssertNotNil(r?.first?.fecha, "«5» vale aunque dijo «cinco»")
        XCTAssertNil(r?.last?.fecha)
    }

    func testCapturaRechazaLoInventado() {
        XCTAssertNil(ServicioDeIA.validarCaptura([(titulo: "Pasear al perro", tamano: .chica, cuando: "")],
                                                 dicho: "Comprar pan y terminar el informe"))
    }

    func testCapturaNoInventaFechas() {
        let r = ServicioDeIA.validarCaptura([(titulo: "Comprar pan", tamano: .chica, cuando: "el viernes a las 8")],
                                            dicho: "comprar pan")
        XCTAssertNil(r?.first?.fecha, "el cuándo no estaba en lo dicho")
    }

    func testSinIALaHoraVaSoloConSuTarea() {
        let dicho = "llama al dentista mañana a las cinco y después revisa el correo"
        let partes = MotorSimple.partirPorConectores(dicho).map { (titulo: $0, tamano: TamanoDeTarea.mediana, cuando: $0) }
        let r = ServicioDeIA.validarCaptura(partes, dicho: dicho, exigirPalabras: false)
        XCTAssertNotNil(r?.first?.fecha)
        XCTAssertNil(r?.last?.fecha)
    }

    func testNumerosSoloEnHoras() {
        XCTAssertEqual(ServicioDeIA.numerosComoCifras("a las cinco, la dosis, una tarea"), "a las 5, la dosis, una tarea")
        XCTAssertEqual(ServicioDeIA.numerosComoCifras("at five"), "at 5")
    }

    func testMismaRaiz() {
        XCTAssertTrue(ServicioDeIA.mismaRaiz("llamar", "llama"))
        XCTAssertTrue(ServicioDeIA.mismaRaiz("revisar", "revisa"))
        XCTAssertFalse(ServicioDeIA.mismaRaiz("pan", "papel"))
        XCTAssertFalse(ServicioDeIA.mismaRaiz("5", "15"))
    }

    // MARK: Chispa y el porqué

    func testSinPorqueChispaDiceLoMismoQueAntes() {
        for i in 0..<40 {
            let turno = "t\(i)"
            XCTAssertEqual(Cohete.consejo(.tarea(enMarcha: false, primerPaso: true, minutosReales: nil, enRacha: false), turno: turno),
                           Idioma.texto("Solo dos minutos. Yo te acompaño."))
            XCTAssertEqual(Cohete.consejo(.tarea(enMarcha: false, primerPaso: false, minutosReales: 12, enRacha: false,
                                                 conEnergia: true), turno: turno),
                           Idioma.texto("Algo así suele tomarte unos \(12) min. ¿Despegamos?"))
        }
    }

    func testConPorqueYEnergiaLoMencionaMasQueSinEnergia() {
        func veces(_ energia: Bool) -> Int {
            (0..<200).filter { i in
                Cohete.consejo(.tarea(enMarcha: false, primerPaso: false, minutosReales: 12, enRacha: false,
                                      anzuelo: "Mi sobrina", conEnergia: energia), turno: "t\(i)").contains("Mi sobrina")
            }.count
        }
        XCTAssertGreaterThan(veces(true), veces(false))
        XCTAssertLessThan(veces(true), 200, "las frases de minutos no deben desaparecer")
    }

    func testPorqueLargoSeAcorta() {
        XCTAssertLessThanOrEqual(Cohete.acortar(String(repeating: "a", count: 120)).count, 41)
        XCTAssertEqual(Cohete.acortar("corto"), "corto")
    }

    // MARK: Avisos según la energía

    func testTipoDeAvisoSegunEnergia() {
        XCTAssertEqual(Avisos.tipo(para: .baja), .frase)
        XCTAssertEqual(Avisos.tipo(para: .media), .paso)
        XCTAssertEqual(Avisos.tipo(para: .alta), .paso)
    }

    func testConEnergiaBajaNuncaDosEnLaMismaHora() {
        let fecha = Date(timeIntervalSince1970: 1_800_000_000)
        let otro = fecha.addingTimeInterval(40 * 60)
        XCTAssertFalse(Avisos.caben(fecha, nivel: .baja, otros: [otro]))
        XCTAssertTrue(Avisos.caben(fecha, nivel: .baja, otros: [fecha.addingTimeInterval(2 * 3600)]))
        XCTAssertTrue(Avisos.caben(fecha, nivel: .alta, otros: [otro]))
    }

    func testNivelEsperado() {
        var horas = [Double](repeating: 50, count: 24)
        horas[9] = 80; horas[23] = 10
        XCTAssertEqual(Avisos.nivelEsperado(hora: 9, horasDelDia: horas), .alta)
        XCTAssertEqual(Avisos.nivelEsperado(hora: 23, horasDelDia: horas), .baja)
        XCTAssertEqual(Avisos.nivelEsperado(hora: 30, horasDelDia: horas), .media)
    }

    func testPlanDeAvisos() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let uso = Date(timeIntervalSince1970: 1_800_000_000)
        XCTAssertEqual(Avisos.plan(activos: false, enPausa: false, mejorHora: 10, ultimoUso: uso, calendario: cal), Avisos.Plan())
        let plan = Avisos.plan(activos: true, enPausa: true, mejorHora: 10, ultimoUso: uso, calendario: cal)
        XCTAssertNil(plan.diario, "en pausa no hay aviso diario")
        XCTAssertNotNil(plan.sigueAqui)
    }
}
