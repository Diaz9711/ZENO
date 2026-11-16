import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

// FASE IA (Diaz, 16 nov 2026; plan revisado con Fable).
// El cerebro de energía NO usa IA. La IA solo ayuda a dividir tareas (y después: captura por voz y
// mensajes de Chispa). Un solo servicio con varios motores: si el motor local no está, la versión
// simple sin IA responde siempre. La app nunca se rompe por esto.

/// Lo que se le pide a un motor para dividir una tarea.
struct PedidoDeDivision: Equatable {
    var titulo: String
    /// El porqué de la tarea. ZENO no lo pregunta todavía: va vacío.
    var porque: String = ""
    var tamano: TamanoDeTarea
    var energia: NivelDeEnergia
    var idioma: Idioma
}

/// Un motor de IA. Para cambiar de motor no hace falta tocar el resto de la app.
protocol MotorDeIA {
    var nombre: String { get }
    /// Si se puede usar ahora mismo, y si no, por qué (para el modo de prueba).
    var estado: (disponible: Bool, motivo: String) { get }
    func dividir(_ pedido: PedidoDeDivision) async throws -> [String]
}

enum ErrorDeIA: Error { case noDisponible, respuestaInvalida }

// MARK: - Motor simple (sin IA): siempre funciona

struct MotorSimple: MotorDeIA {
    let nombre = "Sin IA (plantilla)"
    var estado: (disponible: Bool, motivo: String) { (true, "Siempre disponible") }

    func dividir(_ p: PedidoDeDivision) async throws -> [String] { Self.plantilla(p) }

    /// Pasos genéricos de unos 5 minutos; el primero, ridículamente fácil.
    static func plantilla(_ p: PedidoDeDivision) -> [String] {
        let t = p.titulo
        let es = p.idioma == .espanol
        var pasos = es
            ? ["Abre lo que necesitas para «\(t)»",
               "Haz solo la primera parte, 5 minutos",
               "Sigue con la parte siguiente",
               "Revisa lo que hiciste y guárdalo"]
            : ["Open what you need for “\(t)”",
               "Do just the first part, 5 minutes",
               "Move on to the next part",
               "Check what you did and save it"]
        // Con poca energía, menos pasos; una tarea grande con energía, uno más.
        if p.energia == .baja { pasos.removeLast() }
        if p.tamano == .grande && p.energia == .alta {
            pasos.insert(es ? "Haz otra parte pequeña, 5 minutos" : "Do one more small part, 5 minutes", at: 3)
        }
        return pasos
    }
}

// MARK: - Motor en la nube: solo la puerta (apagado, sin red)

/// Preparado para el futuro, apagado: ZENO no tiene servidores (lo dice su política de privacidad).
/// Para encenderlo haría falta un permiso explícito de la persona y cambiar esa política.
struct MotorEnLaNube: MotorDeIA {
    let nombre = "Nube (apagado)"
    var estado: (disponible: Bool, motivo: String) { (false, "Apagado: ZENO no envía nada fuera del iPhone") }
    func dividir(_ pedido: PedidoDeDivision) async throws -> [String] { throw ErrorDeIA.noDisponible }
}

// MARK: - Motor local: Foundation Models de Apple (dentro del iPhone, sin internet)

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable(description: "Pasos pequeños para empezar y terminar una tarea")
struct PasosGenerados {
    @Guide(description: "Entre 3 y 7 pasos de unos 5 minutos cada uno. El primero es ridículamente fácil, como abrir algo. Cada paso es una frase corta que empieza con un verbo.", .count(3...7))
    var pasos: [String]
}

@available(iOS 26.0, *)
struct MotorLocal: MotorDeIA {
    let nombre = "Apple Foundation Models (en el iPhone)"

    var estado: (disponible: Bool, motivo: String) {
        let modelo = SystemLanguageModel.default
        switch modelo.availability {
        case .available:
            return modelo.supportsLocale(Idioma.actual.locale) ? (true, "Disponible") : (false, "No admite el idioma elegido")
        case .unavailable(.deviceNotEligible): return (false, "Este dispositivo no tiene Apple Intelligence")
        case .unavailable(.appleIntelligenceNotEnabled): return (false, "Apple Intelligence está apagada en Ajustes del iPhone")
        case .unavailable(.modelNotReady): return (false, "El modelo se está descargando")
        default: return (false, "No disponible")
        }
    }

    func dividir(_ p: PedidoDeDivision) async throws -> [String] {
        guard estado.disponible else { throw ErrorDeIA.noDisponible }
        let es = p.idioma == .espanol
        let energia: String = switch p.energia {
        case .baja: es ? "baja: pasos aún más pequeños y suaves" : "low: even smaller, gentler steps"
        case .media: es ? "media" : "medium"
        case .alta: es ? "alta" : "high"
        }
        let esfuerzo: String = switch p.tamano {
        case .chica: es ? "pequeño" : "small"
        case .mediana: es ? "medio" : "medium"
        case .grande: es ? "grande" : "large"
        }
        let instrucciones = es
            ? "Ayudas a personas con TDAH a empezar tareas. Divides una tarea en pasos muy concretos de unos 5 minutos. El primer paso es ridículamente fácil (por ejemplo: «Abre el documento»). Sin culpa, sin presión, sin consejos médicos. Responde siempre en español."
            : "You help people with ADHD start tasks. You split a task into very concrete steps of about 5 minutes. The first step is ridiculously easy (for example: “Open the document”). No guilt, no pressure, no medical advice. Always answer in English."
        let pedido = es
            ? "Tarea: \(p.titulo)\nPor qué: \(p.porque.isEmpty ? "(no lo dijo)" : p.porque)\nEsfuerzo: \(esfuerzo)\nEnergía de ahora: \(energia)"
            : "Task: \(p.titulo)\nWhy: \(p.porque.isEmpty ? "(not given)" : p.porque)\nEffort: \(esfuerzo)\nCurrent energy: \(energia)"
        let sesion = LanguageModelSession(instructions: instrucciones)
        let respuesta = try await sesion.respond(to: pedido, generating: PasosGenerados.self,
                                                 options: GenerationOptions(temperature: 0.4))
        return respuesta.content.pasos
    }
}
#endif

// MARK: - El servicio: elige el motor, valida y nunca falla

@MainActor
@Observable
final class ServicioDeIA {
    static let compartido = ServicioDeIA()

    /// Lo último generado (para el modo de prueba).
    private(set) var historial: [String] = []
    private(set) var ultimoMotor = ""
    /// El último error de un motor (para el modo de prueba).
    private(set) var ultimoError: String?

    /// El motor que se usaría ahora (el local si está; si no, el simple).
    var motor: MotorDeIA {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), UserDefaults.standard.bool(forKey: "iaSinModelo") == false {
            let local = MotorLocal()
            if local.estado.disponible { return local }
        }
        #endif
        return MotorSimple()
    }

    /// Todos los motores, con su estado (para el modo de prueba).
    var motores: [MotorDeIA] {
        var lista: [MotorDeIA] = []
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) { lista.append(MotorLocal()) }
        #endif
        lista.append(MotorSimple())
        lista.append(MotorEnLaNube())
        return lista
    }

    struct Division {
        var pasos: [String]
        var motor: String
        /// Si se usó la versión sin IA porque la IA falló o no estaba.
        var deRespaldo: Bool
    }

    /// Divide una tarea en pasos. Siempre devuelve algo válido.
    func dividir(_ pedido: PedidoDeDivision) async -> Division {
        let elegido = motor
        var division: Division
        do {
            let crudos = try await elegido.dividir(pedido)
            if let validos = Self.validarPasos(crudos) {
                division = Division(pasos: validos, motor: elegido.nombre, deRespaldo: false)
            } else {
                division = Division(pasos: MotorSimple.plantilla(pedido), motor: MotorSimple().nombre + " · respaldo", deRespaldo: true)
            }
        } catch {
            division = Division(pasos: MotorSimple.plantilla(pedido), motor: MotorSimple().nombre + " · respaldo", deRespaldo: true)
            ultimoError = String(describing: error)
            #if DEBUG
            print("PRUEBA-IA error del motor \(elegido.nombre): \(error)")
            #endif
        }
        ultimoMotor = division.motor
        historial.insert("Divídemela «\(pedido.titulo)» → \(division.pasos.count) pasos (\(division.motor))", at: 0)
        if historial.count > 30 { historial.removeLast(historial.count - 30) }
        return division
    }

    /// El formato lo garantiza el motor; el contenido se revisa aquí: 3 a 7 pasos, no vacíos,
    /// cortos y sin repetir. Si algo falla, nil (y se usa la versión sin IA).
    nonisolated static func validarPasos(_ crudos: [String]) -> [String]? {
        var vistos = Set<String>()
        let pasos = crudos
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "-•*·0123456789.)"))) }
            .filter { !$0.isEmpty && $0.count <= 120 }
            .filter { vistos.insert($0.lowercased()).inserted }
        guard (3...7).contains(pasos.count) else { return nil }
        return pasos
    }
}

// MARK: - Crisis: se revisa en código, antes de cualquier motor (también sin IA)

enum Cuidado {
    /// Frases que suenan a crisis emocional. Si aparecen, ZENO no divide ni responde como terapeuta.
    private static let señales = [
        "suicid", "matarme", "quitarme la vida", "no quiero vivir", "no quiero seguir viviendo", "acabar con todo",
        "hacerme daño", "lastimarme", "autolesi", "desaparecer para siempre",
        "kill myself", "end my life", "suicide", "want to die", "hurt myself", "self harm", "self-harm"
    ]

    static func suenaACrisis(_ texto: String) -> Bool {
        let t = texto.lowercased().folding(options: .diacriticInsensitive, locale: nil)
        return señales.contains { t.contains($0.folding(options: .diacriticInsensitive, locale: nil)) }
    }
}

// MARK: - Comprobación propia (sin target de tests): `-probarIA YES` imprime PASS/FAIL en la consola

#if DEBUG
enum PruebaDeIA {
    static func correr() async {
        func ok(_ c: Bool, _ nombre: String) { print("PRUEBA-IA \(c ? "PASS" : "FAIL") · \(nombre)") }
        // Validación
        ok(ServicioDeIA.validarPasos(["Abre el archivo", "Escribe el título", "Escribe 3 ideas"]) != nil, "3 pasos válidos")
        ok(ServicioDeIA.validarPasos(["Uno", "Dos"]) == nil, "2 pasos se rechazan")
        ok(ServicioDeIA.validarPasos(Array(repeating: "Igual", count: 5)) == nil, "pasos repetidos se rechazan")
        ok(ServicioDeIA.validarPasos(["1. Abre", "- Lee", "• Escribe"]) == ["Abre", "Lee", "Escribe"], "se limpian viñetas y números")
        // Crisis
        ok(Cuidado.suenaACrisis("ya no quiero vivir"), "crisis detectada (es)")
        ok(Cuidado.suenaACrisis("I want to die"), "crisis detectada (en)")
        ok(!Cuidado.suenaACrisis("Preparar la presentación del lunes"), "tarea normal no es crisis")
        // Plantilla sin IA
        for (titulo, tamano, energia) in [("Preparar la presentación del lunes", TamanoDeTarea.grande, NivelDeEnergia.alta),
                                          ("Ordenar el escritorio", .mediana, .baja),
                                          ("Responder el correo de Ana", .chica, .media)] {
            let p = PedidoDeDivision(titulo: titulo, tamano: tamano, energia: energia, idioma: .espanol)
            ok(ServicioDeIA.validarPasos(MotorSimple.plantilla(p)) != nil, "plantilla válida: \(titulo)")
        }
        // Motor real (en el iPhone con Apple Intelligence; en el simulador suele no estar)
        let servicio = await ServicioDeIA.compartido
        for m in await servicio.motores { print("PRUEBA-IA motor · \(m.nombre): \(m.estado.motivo)") }
        for titulo in ["Preparar la presentación del lunes", "Limpiar la cocina", "Hacer la declaración de impuestos"] {
            let d = await servicio.dividir(PedidoDeDivision(titulo: titulo, tamano: .grande, energia: .media, idioma: .espanol))
            ok((3...7).contains(d.pasos.count), "dividir «\(titulo)» con \(d.motor)")
            d.pasos.enumerated().forEach { print("PRUEBA-IA   \($0.offset + 1). \($0.element)") }
        }
    }
}
#endif
