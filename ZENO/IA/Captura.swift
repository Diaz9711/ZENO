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
        var salida: [TareaCapturada] = []
        for c in crudas {
            let titulo = c.titulo.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: ".,;-•")))
            guard !titulo.isEmpty, titulo.count <= 100 else { continue }
            if exigirPalabras {
                let suyas = palabras(titulo)
                guard !suyas.isEmpty else { continue }
                let presentes = suyas.filter { dichas.contains($0) }.count
                guard Double(presentes) / Double(suyas.count) >= 0.6 else { continue }
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
            let fecha = cuando.isEmpty ? nil : (bajo.contains(cuando.lowercased()) || !exigirPalabras ? fechaEn(cuandoCompleto) : nil)
            salida.append(TareaCapturada(titulo: titulo, tamano: c.tamano, fecha: fecha))
        }
        guard (1...10).contains(salida.count) else { return nil }
        return salida
    }

    /// Palabras con significado (3 letras o más), sin tildes ni mayúsculas.
    nonisolated static func palabras(_ texto: String) -> [String] {
        texto.lowercased().folding(options: .diacriticInsensitive, locale: nil)
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { $0.count >= 3 }
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
