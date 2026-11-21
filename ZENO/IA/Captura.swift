import Foundation

// FASE IA, parte 2: captura por voz. La persona habla libremente; la IA separa lo dicho en tareas
// (título y esfuerzo). Las fechas las calcula el código (nunca la IA) y solo si la persona las dijo.
// Nada se guarda sin que la persona confirme en la vista previa.

extension ServicioDeIA {
    struct Captura {
        var tareas: [TareaCapturada]
        var motor: String
        var deRespaldo: Bool
    }

    /// De lo dicho a tareas. Siempre devuelve algo (con la versión sin IA si hace falta).
    func capturar(_ texto: String) async -> Captura {
        let idioma = Idioma.actual
        let limpio = texto.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !limpio.isEmpty else { return Captura(tareas: [], motor: "", deRespaldo: true) }
        let elegido = motor
        var captura: Captura
        if !(elegido is MotorSimple), let crudas = try? await elegido.capturar(limpio, idioma: idioma),
           let validas = Self.validarCaptura(crudas, dicho: limpio) {
            captura = Captura(tareas: validas, motor: elegido.nombre, deRespaldo: false)
        } else {
            let crudas = (try? await MotorSimple().capturar(limpio, idioma: idioma)) ?? []
            let validas = Self.validarCaptura(crudas, dicho: limpio, exigirPalabras: false) ?? [TareaCapturada(titulo: limpio, tamano: .mediana)]
            captura = Captura(tareas: validas, motor: MotorSimple().nombre + (elegido is MotorSimple ? "" : " · respaldo"), deRespaldo: true)
        }
        anotar("Captura «\(limpio.prefix(40))» → \(captura.tareas.count) tareas (\(captura.motor))")
        return captura
    }

    /// Revisa lo que dio el motor: títulos no vacíos y cortos, sin repetir, como mucho 10, y (con IA)
    /// que la mayoría de sus palabras estén en lo que la persona dijo: la IA no puede inventar tareas.
    nonisolated static func validarCaptura(_ crudas: [(titulo: String, tamano: TamanoDeTarea, cuando: String)],
                                           dicho: String, exigirPalabras: Bool = true) -> [TareaCapturada]? {
        let dichas = Set(palabras(dicho))
        let dichoNormal = palabras(numerosComoCifras(dicho))
        var salida: [TareaCapturada] = []
        for c in crudas {
            let titulo = c.titulo.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: ".,;-•")))
            guard !titulo.isEmpty, titulo.count <= 100 else { continue }
            if exigirPalabras {
                let suyas = palabras(titulo)
                guard !suyas.isEmpty else { continue }
                // Tolerante a la forma del verbo: "Llamar" vale si dijo "llama" (misma raíz).
                let presentes = suyas.filter { s in dichas.contains(s) || dichas.contains { mismaRaiz($0, s) } }.count
                guard Double(presentes) / Double(suyas.count) >= 0.6 else {
                    #if DEBUG
                    print("PRUEBA-IA captura descarta «\(titulo)»: no está en lo dicho")
                    #endif
                    continue
                }
            }
            guard !salida.contains(where: { $0.titulo.lowercased() == titulo.lowercased() }) else { continue }
            // La fecha: solo si "cuándo" está en lo dicho, y la calcula el sistema (no la IA).
            let cuando = c.cuando.trimmingCharacters(in: .whitespacesAndNewlines)
            // Si la IA copió solo la hora ("a las cinco") pero la persona dijo "mañana", se le añade el día.
            var cuandoCompleto = cuando
            let bajo = dicho.lowercased()
            for dia in ["pasado mañana", "mañana", "tomorrow"] where bajo.contains(dia) && !cuando.lowercased().contains(dia) {
                cuandoCompleto = dia + " " + cuando; break
            }
            // El "cuándo" vale si sus palabras están en lo dicho ("cinco" y "5" cuentan igual).
            let palabrasCuando = palabras(numerosComoCifras(cuando))
            let cuandoDicho = bajo.contains(cuando.lowercased())
                || (!palabrasCuando.isEmpty && palabrasCuando.allSatisfy { p in dichoNormal.contains { mismaRaiz($0, p) } })
            let fecha: Date?
            if !exigirPalabras {
                // Sin IA: solo hay fecha si esa parte dice una hora ("a las 5"), con su día si lo dijo.
                fecha = horaDicha(en: c.titulo, dicho: dicho).flatMap { fechaEn($0) }
            } else {
                fecha = cuando.isEmpty || !cuandoDicho ? nil : fechaEn(numerosComoCifras(cuandoCompleto))
            }
            salida.append(TareaCapturada(titulo: titulo.prefix(1).uppercased() + titulo.dropFirst(), tamano: c.tamano, fecha: fecha))
        }
        guard (1...10).contains(salida.count) else { return nil }
        return salida
    }

    /// Palabras con significado (3 letras o más, o cifras), sin tildes ni mayúsculas.
    nonisolated static func palabras(_ texto: String) -> [String] {
        texto.lowercased().folding(options: .diacriticInsensitive, locale: nil)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 3 || ($0.first?.isNumber ?? false) }
    }

    /// Sin IA: "mañana a las 5" si esa parte dice una hora; el día sale de la parte o, si no, de lo dicho.
    nonisolated static func horaDicha(en parte: String, dicho: String) -> String? {
        let texto = numerosComoCifras(parte)
        guard let r = texto.range(of: "\\b(a las|a la|at) \\d{1,2}(:\\d{2})?( ?(am|pm|de la tarde|de la mañana|de la noche))?",
                                  options: [.regularExpression, .caseInsensitive]) else { return nil }
        let hora = String(texto[r])
        for dia in ["pasado mañana", "mañana", "tomorrow", "hoy", "today"] {
            if parte.lowercased().contains(dia) || dicho.lowercased().contains(dia) { return dia + " " + hora }
        }
        return hora
    }

    /// Dos palabras con la misma raíz: iguales, o que comparten las primeras 4 letras
    /// ("llamar"/"llama", "revisar"/"revisa", "comprar"/"compra"). Las cifras, solo iguales.
    nonisolated static func mismaRaiz(_ a: String, _ b: String) -> Bool {
        if a == b { return true }
        guard a.count >= 4, b.count >= 4, !(a.first?.isNumber ?? true), !(b.first?.isNumber ?? true) else { return false }
        return a.prefix(4) == b.prefix(4)
    }

    /// "a las cinco" → "a las 5", para que el detector de fechas y la comparación entiendan lo dicho.
    nonisolated static func numerosComoCifras(_ texto: String) -> String {
        let numeros = ["una": "1", "uno": "1", "dos": "2", "tres": "3", "cuatro": "4", "cinco": "5", "seis": "6",
                       "siete": "7", "ocho": "8", "nueve": "9", "diez": "10", "once": "11", "doce": "12",
                       "one": "1", "two": "2", "three": "3", "four": "4", "five": "5", "six": "6", "seven": "7",
                       "eight": "8", "nine": "9", "ten": "10", "eleven": "11", "twelve": "12"]
        // Solo después de "las"/"la"/"at": "a las cinco", "at five" (no "una tarea", "dos cosas").
        var salida = texto
        for (palabra, cifra) in numeros {
            salida = salida.replacingOccurrences(of: "\\b(las|la|at) \(palabra)\\b", with: "$1 \(cifra)",
                                                 options: [.regularExpression, .caseInsensitive])
        }
        return salida
    }

    /// Una fecha dicha con palabras ("mañana a las 5", "tomorrow at 5pm"), con el detector del sistema.
    /// Solo fechas futuras y de los próximos 60 días.
    nonisolated static func fechaEn(_ texto: String, ahora: Date = .now) -> Date? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else { return nil }
        let rango = NSRange(texto.startIndex..., in: texto)
        guard let fecha = detector.firstMatch(in: texto, options: [], range: rango)?.date,
              fecha > ahora.addingTimeInterval(-60), fecha < ahora.addingTimeInterval(60 * 86_400) else { return nil }
        return fecha
    }
}
