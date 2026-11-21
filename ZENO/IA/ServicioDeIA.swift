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
    /// El porqué de la tarea ("¿Para qué te importa?"), vacío si no lo dijo.
    var porque: String = ""
    var tamano: TamanoDeTarea
    var energia: NivelDeEnergia
    var idioma: Idioma
    /// Lo aprendido: este tipo de tarea le suele costar (la pospone mucho). Pasos más pequeños.
    var masPequenos: Bool = false
}

/// Una tarea encontrada en lo que la persona dijo.
struct TareaCapturada: Equatable, Identifiable {
    var id = UUID()
    var titulo: String
    var tamano: TamanoDeTarea
    /// Solo si la persona dijo cuándo (se calcula en código, nunca la inventa la IA).
    var fecha: Date?
    var incluida = true
    /// "¿Para qué te importa?" (opcional), escrito en la vista previa.
    var porque = ""
    var conPorque = false
}

/// Un motor de IA. Para cambiar de motor no hace falta tocar el resto de la app.
protocol MotorDeIA {
    var nombre: String { get }
    /// Si se puede usar ahora mismo, y si no, por qué (para el modo de prueba).
    var estado: (disponible: Bool, motivo: String) { get }
    func dividir(_ pedido: PedidoDeDivision) async throws -> [String]
    /// De lo dicho a una lista de tareas: (título, tamaño, "cuándo" tal como lo dijo).
    func capturar(_ texto: String, idioma: Idioma) async throws -> [(titulo: String, tamano: TamanoDeTarea, cuando: String)]
    /// Frases nuevas para Chispa de una categoría (cortas, cálidas, sin culpa).
    func frases(_ categoria: CategoriaDeFrase, cuantas: Int, evitar: [String], idioma: Idioma) async throws -> [String]
}

enum ErrorDeIA: Error { case noDisponible, respuestaInvalida }

// MARK: - Motor simple (sin IA): siempre funciona

struct MotorSimple: MotorDeIA {
    let nombre = "Sin IA (plantilla)"
    var estado: (disponible: Bool, motivo: String) { (true, "Siempre disponible") }

    func dividir(_ p: PedidoDeDivision) async throws -> [String] { Self.plantilla(p) }

    /// Sin IA: nunca se parte por la puntuación (el dictado la pone al azar y salían tareas basura).
    /// Solo se separa donde la persona encadenó otra acción ("y después", "y luego", "and then");
    /// si no, todo lo dicho es una sola tarea. El tamaño lo pone el clasificador de siempre.
    func capturar(_ texto: String, idioma: Idioma) async throws -> [(titulo: String, tamano: TamanoDeTarea, cuando: String)] {
        Self.partirPorConectores(texto).map { (titulo: $0, tamano: ClasificadorDeTamano.tamano(de: $0), cuando: $0) }
    }

    /// Los conectores que de verdad separan una acción de otra.
    static let conectores = ["y después", "y despues", "y luego", "y también", "y tambien", "y además", "y ademas",
                             "después de eso", "and then", "and after that", "and also"]

    static func partirPorConectores(_ texto: String) -> [String] {
        var partes = [texto]
        for conector in conectores {
            partes = partes.flatMap { $0.components(separatedBy: conector) }
            partes = partes.flatMap { $0.components(separatedBy: conector.prefix(1).uppercased() + conector.dropFirst()) }
        }
        let limpias = partes
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: ".,;!?"))) }
            .filter { !$0.isEmpty }
        // Cada parte con su mayúscula inicial, como una tarea escrita.
        return limpias.map { $0.prefix(1).uppercased() + $0.dropFirst() }
    }

    /// Sin IA: las frases escritas a mano (el banco).
    func frases(_ categoria: CategoriaDeFrase, cuantas: Int, evitar: [String], idioma: Idioma) async throws -> [String] {
        Array(BancoDeFrases.frases(categoria, idioma).filter { !evitar.contains($0) }.prefix(cuantas))
    }

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
        // Lo aprendido: si este tipo le cuesta, un primer paso casi nulo y partes de 2 minutos.
        if p.masPequenos {
            pasos[0] = es ? "Solo deja a la vista lo que necesitas para «\(t)»" : "Just put what you need for “\(t)” where you can see it"
            if let i = pasos.firstIndex(of: es ? "Haz solo la primera parte, 5 minutos" : "Do just the first part, 5 minutes") {
                pasos[i] = es ? "Haz solo la primera parte, 2 minutos" : "Do just the first part, 2 minutes"
                pasos.insert(es ? "Mira qué es lo primero que hay que hacer" : "Look at what the very first thing is", at: i)
            }
        }
        return Array(pasos.prefix(7))
    }
}

// MARK: - Motor en la nube: solo la puerta (apagado, sin red)

/// Preparado para el futuro, apagado: ZENO no tiene servidores (lo dice su política de privacidad).
/// Para encenderlo haría falta un permiso explícito de la persona y cambiar esa política.
struct MotorEnLaNube: MotorDeIA {
    let nombre = "Nube (apagado)"
    var estado: (disponible: Bool, motivo: String) { (false, "Apagado: ZENO no envía nada fuera del iPhone") }
    func dividir(_ pedido: PedidoDeDivision) async throws -> [String] { throw ErrorDeIA.noDisponible }
    func capturar(_ texto: String, idioma: Idioma) async throws -> [(titulo: String, tamano: TamanoDeTarea, cuando: String)] { throw ErrorDeIA.noDisponible }
    func frases(_ categoria: CategoriaDeFrase, cuantas: Int, evitar: [String], idioma: Idioma) async throws -> [String] { throw ErrorDeIA.noDisponible }
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
@Generable(description: "Una tarea que la persona dijo")
struct TareaDicha {
    @Guide(description: "La tarea en pocas palabras, usando las mismas palabras de la persona. Sin fecha ni hora.")
    var titulo: String
    @Guide(description: "Esfuerzo que pide la tarea", .anyOf(["small", "medium", "large"]))
    var esfuerzo: String
    @Guide(description: "Cuándo, solo si la persona lo dijo, con el día y la hora juntos tal como los dijo (por ejemplo «mañana a las 5 de la tarde»). Vacío si no lo dijo.")
    var cuando: String
}

@available(iOS 26.0, *)
@Generable(description: "Las tareas que la persona dijo en voz alta")
struct TareasDichas {
    @Guide(description: "Cada tarea distinta que la persona mencionó, en el orden en que la dijo", .count(1...10))
    var tareas: [TareaDicha]
}

@available(iOS 26.0, *)
@Generable(description: "Frases cortas de un compañero amable")
struct FrasesNuevas {
    @Guide(description: "Frases distintas entre sí, de 4 a 15 palabras cada una", .count(1...8))
    var frases: [String]
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
            ? "Ayudas a personas con TDAH a empezar tareas. Divides una tarea en pasos muy concretos de unos 5 minutos. El primer paso es ridículamente fácil (por ejemplo: «Abre el documento»). Si la persona dijo para qué le importa, usa ese interés para que los pasos den ganas (sin repetirlo en cada paso). Sin culpa, sin presión, sin consejos médicos. Responde siempre en español."
            : "You help people with ADHD start tasks. You split a task into very concrete steps of about 5 minutes. The first step is ridiculously easy (for example: “Open the document”). If the person said why it matters to them, use that interest to make the steps appealing (without repeating it in every step). No guilt, no pressure, no medical advice. Always answer in English."
        let pedido = es
            ? "Tarea: \(p.titulo)\nPor qué: \(p.porque.isEmpty ? "(no lo dijo)" : p.porque)\nEsfuerzo: \(esfuerzo)\nEnergía de ahora: \(energia)"
                + (p.masPequenos ? "\nEste tipo de tarea le suele costar mucho empezarlo: haz pasos aún más pequeños y concretos (de 2 o 3 minutos), entre 5 y 7, y que el primero sea casi nada." : "")
            : "Task: \(p.titulo)\nWhy: \(p.porque.isEmpty ? "(not given)" : p.porque)\nEffort: \(esfuerzo)\nCurrent energy: \(energia)"
                + (p.masPequenos ? "\nThis kind of task is usually very hard for them to start: make the steps even smaller and more concrete (2 or 3 minutes), between 5 and 7, with an almost-nothing first step." : "")
        let sesion = LanguageModelSession(instructions: instrucciones)
        let respuesta = try await sesion.respond(to: pedido, generating: PasosGenerados.self,
                                                 options: GenerationOptions(temperature: 0.4))
        return respuesta.content.pasos
    }

    func capturar(_ texto: String, idioma: Idioma) async throws -> [(titulo: String, tamano: TamanoDeTarea, cuando: String)] {
        guard estado.disponible else { throw ErrorDeIA.noDisponible }
        let es = idioma == .espanol
        let instrucciones = es
            ? "Conviertes lo que una persona dijo en voz alta en una lista de tareas. Una tarea es una acción con su objeto; el día y la hora van con su tarea, no son otra tarea. No separes por comas ni puntos: el dictado los pone al azar. Ejemplo: «llama al dentista mañana a las cinco y después revisa el correo» son dos tareas: «Llamar al dentista» (cuándo: «mañana a las cinco») y «Revisar el correo». Solo tareas que dijo de verdad, con sus palabras. No inventes tareas, fechas ni detalles. Responde en español."
            : "You turn what a person said out loud into a list of tasks. A task is one action with its object; the day and time belong to their task, they are not a task. Don't split on commas or periods: dictation adds them at random. Example: “call the dentist tomorrow at five and then check my email” is two tasks: “Call the dentist” (when: “tomorrow at five”) and “Check my email”. Only tasks they really said, in their words. Don't invent tasks, dates or details. Answer in English."
        let sesion = LanguageModelSession(instructions: instrucciones)
        let r = try await sesion.respond(to: (es ? "Lo que dijo: " : "What they said: ") + texto,
                                         generating: TareasDichas.self, options: GenerationOptions(temperature: 0.2))
        return r.content.tareas.map { t in
            let tamano: TamanoDeTarea = t.esfuerzo == "small" ? .chica : (t.esfuerzo == "large" ? .grande : .mediana)
            return (titulo: t.titulo, tamano: tamano, cuando: t.cuando)
        }
    }

    func frases(_ categoria: CategoriaDeFrase, cuantas: Int, evitar: [String], idioma: Idioma) async throws -> [String] {
        guard estado.disponible else { throw ErrorDeIA.noDisponible }
        let es = idioma == .espanol
        let instrucciones = es
            ? "Escribes frases de Chispa, un pequeño cohete que acompaña a personas con TDAH. Tono cálido, tranquilo y breve (máximo 15 palabras). Nunca culpa, prisa, presión, reproches ni consejos médicos. Sin números ni horas. Responde en español."
            : "You write lines for Chispa, a small rocket that keeps people with ADHD company. Warm, calm and brief (15 words max). Never guilt, hurry, pressure, blame or medical advice. No numbers or times. Answer in English."
        let pedido = (es ? "Momento: " : "Moment: ") + categoria.descripcion(es: es)
            + (evitar.isEmpty ? "" : (es ? "\nNo repitas estas: " : "\nDon't repeat these: ") + evitar.prefix(12).joined(separator: " | "))
        let sesion = LanguageModelSession(instructions: instrucciones)
        let r = try await sesion.respond(to: pedido, generating: FrasesNuevas.self, options: GenerationOptions(temperature: 0.7))
        return Array(r.content.frases.prefix(cuantas))
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
        anotar("Divídemela «\(pedido.titulo)» → \(division.pasos.count) pasos (\(division.motor))")
        return division
    }

    /// Guarda una línea para el modo de prueba (las últimas 30).
    func anotar(_ linea: String) {
        historial.insert(linea, at: 0)
        if historial.count > 30 { historial.removeLast(historial.count - 30) }
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
        // Lo aprendido alimenta a Divídemela: un tipo que pospone mucho → pasos más pequeños
        for energia in [NivelDeEnergia.baja, .media, .alta] {
            let p = PedidoDeDivision(titulo: "Llamar al banco", tamano: .grande, energia: energia, idioma: .espanol, masPequenos: true)
            ok(ServicioDeIA.validarPasos(MotorSimple.plantilla(p)) != nil, "plantilla más pequeña válida (energía \(energia))")
        }
        ok(TipoDeTarea.de("Llamar al dentista") == .llamada && TipoDeTarea.de("Pagar la factura") == .papeles, "tipo de tarea por palabras")
        let ahora = Date.now
        let llamadas = (0..<4).map { Senal(tipo: .ahoraNo, fecha: ahora.addingTimeInterval(-Double($0) * 86_400), franjaHoraria: 10, tipoDeTarea: .llamada) }
            + [Senal(tipo: .tareaEmpezada, fecha: ahora, franjaHoraria: 10, tipoDeTarea: .llamada)]
        ok(Aprendizaje.leCuesta(tipo: .llamada, eventos: llamadas), "4 de 5 llamadas pospuestas → le cuesta")
        ok(!Aprendizaje.leCuesta(tipo: .correo, eventos: llamadas), "sin datos de correo → no se cambia nada")
        // Modo silencioso y bucle de retorno
        let tresNo = (1...3).map { Senal(tipo: .ahoraNo, fecha: ahora.addingTimeInterval(-Double($0) * 300), franjaHoraria: 10) }
        ok(MotorDeEnergia.tocaSilencio(puntaje: 60, eventos: tresNo), "tres «Ahora no» seguidos → silencio")
        ok(!MotorDeEnergia.tocaSilencio(puntaje: 60, eventos: tresNo + [Senal(tipo: .tareaEmpezada, fecha: ahora, franjaHoraria: 10)]), "empezar algo corta la cuenta")
        ok(MotorDeEnergia.tocaSilencio(puntaje: 15, eventos: []), "energía muy baja → silencio")
        ok(!MotorDeEnergia.tocaSilencio(puntaje: 50, eventos: []), "energía normal → sin silencio")
        let hora = Calendar.current.component(.hour, from: ahora)
        let grandesPospuestas = (1...4).map { Senal(tipo: .ahoraNo, fecha: ahora.addingTimeInterval(-Double($0) * 86_400), franjaHoraria: hora, tamano: .grande) }
        ok(Aprendizaje.patronDeAhora(propuesta: .chica, tipo: nil, hayGrandes: true, nivel: .alta, franja: hora, eventos: grandesPospuestas) == .grandeCuestaAEstaHora, "patrón: a esta hora lo grande espera")
        ok(Aprendizaje.patronDeAhora(propuesta: .chica, tipo: nil, hayGrandes: true, nivel: .alta, franja: hora, eventos: []) == nil, "sin datos no hay patrón")
        // Captura (sin IA): nunca se parte por puntos ni comas; solo por "y después", "y luego"...
        let dicho = "Llamar al dentista mañana a las 5. Comprar pan. Terminar el informe del trabajo."
        let sinIA = ServicioDeIA.validarCaptura((try? await MotorSimple().capturar(dicho, idioma: .espanol)) ?? [], dicho: dicho, exigirPalabras: false) ?? []
        ok(sinIA.count == 1, "captura sin IA: los puntos ya no parten la frase")
        let dentista = "llama al dentista mañana a las cinco y después revisa el correo"
        let sinIA2 = ServicioDeIA.validarCaptura((try? await MotorSimple().capturar(dentista, idioma: .espanol)) ?? [], dicho: dentista, exigirPalabras: false) ?? []
        ok(sinIA2.map(\.titulo) == ["Llama al dentista mañana a las cinco", "Revisa el correo"], "captura sin IA: «y después» separa dos tareas")
        ok(sinIA2.first?.fecha != nil && sinIA2.last?.fecha == nil, "captura sin IA: la hora solo va con su tarea")
        ok(ServicioDeIA.validarCaptura([(titulo: "Pasear al perro", tamano: .chica, cuando: "")], dicho: dicho) == nil, "captura rechaza una tarea inventada")
        let conIA = ServicioDeIA.validarCaptura([(titulo: "Llamar al dentista", tamano: .chica, cuando: "mañana a las 5"),
                                                 (titulo: "Revisar el correo", tamano: .chica, cuando: "")], dicho: dentista) ?? []
        ok(conIA.count == 2, "captura con IA: «Llamar» vale aunque dijo «llama»")
        ok(conIA.first?.fecha != nil, "captura con IA: «5» vale aunque dijo «cinco»")
        ok(ServicioDeIA.numerosComoCifras("a las cinco, la dosis") == "a las 5, la dosis", "cifras solo en horas")
        ok(ServicioDeIA.fechaEn("mañana a las 5") != nil, "fecha en español: «mañana a las 5»")
        ok(ServicioDeIA.fechaEn("tomorrow at 5pm") != nil, "fecha en inglés: «tomorrow at 5pm»")
        // Frases
        ok(MemoriaDeFrases.validar(["Vas muy bien, sigue así con calma"], evitar: []).count == 1, "frase válida")
        ok(MemoriaDeFrases.validar(["Deberías terminar esto ya"], evitar: []).isEmpty, "frase con culpa se rechaza")
        ok(MemoriaDeFrases.validar(["Te faltan 3 tareas hoy"], evitar: []).isEmpty, "frase con números se rechaza")
        ok(MemoriaDeFrases.validar(["Rest es una pausa especial"], evitar: [], idioma: .espanol).isEmpty, "frase con idiomas mezclados se rechaza")
        ok(MemoriaDeFrases.validar(["Tiny sparks support your steady steps"], evitar: [], idioma: .espanol).isEmpty, "frase en inglés no entra en español")
        for c in CategoriaDeFrase.allCases { ok(BancoDeFrases.frases(c, .espanol).count == 15 && BancoDeFrases.frases(c, .ingles).count == 15, "banco de 15 + 15 frases: \(c.rawValue)") }
        // Motor real (en el iPhone con Apple Intelligence; en el simulador suele no estar)
        let servicio = await ServicioDeIA.compartido
        for m in await servicio.motores { print("PRUEBA-IA motor · \(m.nombre): \(m.estado.motivo)") }
        for titulo in ["Preparar la presentación del lunes", "Limpiar la cocina", "Hacer la declaración de impuestos"] {
            let d = await servicio.dividir(PedidoDeDivision(titulo: titulo, tamano: .grande, energia: .media, idioma: .espanol))
            ok((3...7).contains(d.pasos.count), "dividir «\(titulo)» con \(d.motor)")
            d.pasos.enumerated().forEach { print("PRUEBA-IA   \($0.offset + 1). \($0.element)") }
        }
        for dicho in ["llama al dentista mañana a las cinco y después revisa el correo",
                      "Mañana tengo que llamar al dentista a las cinco, comprar pan y terminar el informe del trabajo",
                      "I need to email my boss, pick up the kids at four and clean the kitchen tonight"] {
            let c = await servicio.capturar(dicho)
            ok(!c.tareas.isEmpty, "capturar con \(c.motor)")
            c.tareas.forEach { print("PRUEBA-IA   · \($0.titulo) [\($0.tamano.rawValue)]\($0.fecha.map { " · \($0.formatted())" } ?? "")") }
        }
        await servicio.refrescarFrases()
        for c in CategoriaDeFrase.allCases {
            let d = MemoriaDeFrases.compartida.deposito(c, Idioma.actual)
            print("PRUEBA-IA frases \(c.rawValue): \(d.count) en el depósito · \(d.prefix(3).joined(separator: " | "))")
        }
    }
}
#endif
