import Foundation

// FASE IA, parte 3: frases de Chispa que no se repiten.
// La IA escribe frases nuevas en segundo plano y se guardan (nunca se genera dentro de una vista).
// Sin IA, se usa el banco escrito a mano. Las frases con números u horas siguen escritas a mano en
// `Cohete.consejo` (los números los pone el código, nunca la IA).

/// Los momentos de Chispa que pueden variar (los "reto, novedad y pasión" del pedido van aquí:
/// invitar a empezar es el reto; la novedad es que la frase cambia; la pasión, el tono).
enum CategoriaDeFrase: String, CaseIterable {
    case ahora, enMarcha, descanso, nada, celebracion

    func descripcion(es: Bool) -> String {
        switch self {
        case .ahora: es ? "invitar con suavidad a empezar una tarea pequeña, como un reto amable" : "gently invite them to start a small task, like a friendly challenge"
        case .enMarcha: es ? "acompañar mientras la persona hace su tarea" : "keep them company while they work on their task"
        case .descanso: es ? "su energía está baja: descansar también cuenta" : "their energy is low: resting counts too"
        case .nada: es ? "no tiene nada pendiente: invitar a escribir una sola cosa" : "nothing pending: invite them to write just one thing"
        case .celebracion: es ? "celebrar que terminó una tarea, sin exagerar" : "celebrate that they finished a task, without overdoing it"
        }
    }
}

/// El banco escrito a mano (sin IA). 15 frases por momento y por idioma.
enum BancoDeFrases {
    static func frases(_ c: CategoriaDeFrase, _ idioma: Idioma) -> [String] {
        idioma == .espanol ? es[c] ?? [] : en[c] ?? []
    }

    private static let es: [CategoriaDeFrase: [String]] = [
        .ahora: ["Cuando quieras, toca Empezar. Yo te acompaño.", "Solo el primer movimiento. El resto viene solo.",
                 "Un pasito y ya cuenta.", "Empezar pequeño también es empezar.", "¿Despegamos juntos con esta?",
                 "No hace falta hacerlo perfecto, solo empezar.", "Esta cabe en tu energía de ahora.",
                 "Un rato corto, y luego vemos.", "Tú pones el primer paso, yo la compañía.", "Hoy basta con una cosa.",
                 "Si te apetece, probamos con esta.", "Lo pequeño mueve lo grande.", "Aquí estoy, sin prisa.",
                 "Una sola cosa. Ahora, si quieres.", "Lista cuando tú lo estés."],
        .enMarcha: ["Vas bien. Cuando acabes, toca Terminé.", "Aquí sigo, a tu lado.", "Paso a paso, sin prisa.",
                    "Lo estás haciendo. Eso ya es mucho.", "Sigue a tu ritmo.", "Un momento a la vez.",
                    "Tu cielo te acompaña.", "Concéntrate solo en esto.", "Respira. Vas por buen camino.",
                    "Cada minuto suma.", "Estoy contigo hasta el final.", "Con calma también se llega.",
                    "Esto es tuyo, a tu manera.", "Lo difícil ya pasó: empezaste.", "Toca Terminé cuando estés."],
        .descanso: ["Tu energía está baja, y está bien. Descansar también cuenta.", "Hoy toca cuidarte.",
                    "Pausa sin culpa. Mañana seguimos.", "Descansar es parte del camino.", "Tu cielo puede esperar.",
                    "Un respiro también es avanzar.", "Escucha a tu cuerpo hoy.", "Lo que hiciste ya cuenta.",
                    "Bajar el ritmo está bien.", "Recarga, que aquí sigo.", "Nada se escapa por descansar.",
                    "Hoy, suave.", "Tu luz vuelve después de descansar.", "Date permiso de parar.", "Aquí te espero, tranquilo."],
        .nada: ["Escribe una sola cosa y despegamos juntos.", "Tu cielo está tranquilo. ¿Una cosa pequeña?",
                "Nada pendiente. Disfruta este rato.", "Cuando quieras, anota lo que viene.", "Espacio libre para lo que elijas.",
                "Una idea basta para empezar.", "Aquí estoy si se te ocurre algo.", "Todo en calma por ahora.",
                "Puedes dictarme lo que tengas en mente.", "Hoy puedes elegir sin prisa.", "Un pensamiento, una tarea.",
                "Cielo despejado. Bien hecho.", "Si algo te ronda, escríbelo aquí.", "Nada que perseguir ahora mismo.",
                "Tu lista está ligera. Respira."],
        .celebracion: ["¡Hecho! Una estrella más en tu cielo.", "Lo terminaste. Eso brilla.", "Tu cielo ganó luz.",
                       "Bien hecho. Disfrútalo un momento.", "Otra estrella tuya para siempre.", "Lo lograste, a tu manera.",
                       "Eso cuenta, y mucho.", "Mira cómo brilla tu cielo.", "Terminado. Respira y celébralo.",
                       "Un paso grande, aunque pareciera pequeño.", "Tu esfuerzo ya es luz.", "Hecho. Ahora, lo que quieras.",
                       "Qué bien se siente terminar.", "Sumaste una estrella.", "Gracias por empezar. Y por terminar."]
    ]

    private static let en: [CategoriaDeFrase: [String]] = [
        .ahora: ["Whenever you're ready, tap Start. I'm with you.", "Just the first move. The rest follows.",
                 "One small step already counts.", "Starting small is still starting.", "Shall we lift off with this one?",
                 "It doesn't need to be perfect, just started.", "This one fits your energy right now.",
                 "A short while, then we'll see.", "You take the first step, I'll keep you company.", "One thing is enough today.",
                 "If you feel like it, let's try this one.", "Small things move big things.", "I'm here, no rush.",
                 "One thing. Now, if you like.", "Ready when you are."],
        .enMarcha: ["You're doing great. When you finish, tap I'm done.", "Still right here with you.", "Step by step, no rush.",
                    "You're doing it. That's a lot.", "Keep your own pace.", "One moment at a time.",
                    "Your sky is with you.", "Focus on just this.", "Breathe. You're on track.",
                    "Every minute adds up.", "I'm with you to the end.", "Calm gets there too.",
                    "This is yours, your way.", "The hard part is done: you started.", "Tap I'm done when you are."],
        .descanso: ["Your energy is low, and that's okay. Rest counts too.", "Today is for taking care of you.",
                    "A guilt-free pause. We'll continue tomorrow.", "Resting is part of the way.", "Your sky can wait.",
                    "A breather is progress too.", "Listen to your body today.", "What you did already counts.",
                    "Slowing down is fine.", "Recharge, I'm still here.", "Nothing slips away by resting.",
                    "Gently, today.", "Your light comes back after rest.", "Give yourself permission to stop.", "I'll wait here, calmly."],
        .nada: ["Write just one thing and we'll lift off together.", "Your sky is calm. One small thing?",
                "Nothing pending. Enjoy this moment.", "Whenever you like, note what's next.", "Free space for whatever you choose.",
                "One idea is enough to start.", "I'm here if something comes to mind.", "All calm for now.",
                "You can tell me what's on your mind.", "Today you can choose without rushing.", "One thought, one task.",
                "Clear sky. Well done.", "If something's on your mind, write it here.", "Nothing to chase right now.",
                "Your list is light. Breathe."],
        .celebracion: ["Done! One more star in your sky.", "You finished it. That shines.", "Your sky gained light.",
                       "Well done. Enjoy it for a moment.", "Another star of yours, forever.", "You did it, your way.",
                       "That counts, a lot.", "Look how your sky shines.", "Finished. Breathe and celebrate.",
                       "A big step, even if it looked small.", "Your effort is light now.", "Done. Now, whatever you like.",
                       "Finishing feels good.", "You added a star.", "Thanks for starting. And for finishing."]
    ]
}

/// Las frases de Chispa: un depósito guardado (lo de la IA) + el banco, y los últimos 30 mostrados.
/// No es observable: elige una frase por momento y la mantiene (si no, parpadearía en cada redibujado).
final class MemoriaDeFrases {
    static let compartida = MemoriaDeFrases()
    private let ajustes = UserDefaults.standard
    private var claveActual: String?
    private var fraseActual = ""

    private func claveDeposito(_ c: CategoriaDeFrase, _ i: Idioma) -> String { "frasesIA.\(i.rawValue).\(c.rawValue)" }
    private var recientes: [String] {
        get { ajustes.stringArray(forKey: "frasesRecientes") ?? [] }
        set { ajustes.set(Array(newValue.suffix(30)), forKey: "frasesRecientes") }
    }

    /// Lo guardado de la IA, vuelto a revisar (idioma incluido) cada vez: si una frase no pasa, no se usa.
    func deposito(_ c: CategoriaDeFrase, _ i: Idioma) -> [String] {
        (ajustes.stringArray(forKey: claveDeposito(c, i)) ?? []).filter { Self.esDelIdioma($0, i) }
    }

    /// Palabras muy comunes de cada idioma: una frase en español no puede tener ninguna en inglés, y al revés.
    private static let comunesES: Set<String> = ["el", "la", "los", "las", "de", "que", "y", "en", "un", "una", "tu", "te", "con", "para",
                                                 "aquí", "estoy", "es", "lo", "más", "sin", "tus", "por", "ya", "hoy", "bien", "cada", "sigue", "paso"]
    private static let comunesEN: Set<String> = ["the", "you", "your", "and", "is", "to", "a", "of", "with", "for", "here", "i'm", "it",
                                                 "one", "let's", "just", "rest", "today", "step", "steps", "my", "me", "join", "quiet", "gently"]
    static func esDelIdioma(_ frase: String, _ i: Idioma) -> Bool {
        let p = frase.lowercased().components(separatedBy: CharacterSet.letters.union(CharacterSet(charactersIn: "'")).inverted).filter { !$0.isEmpty }
        let es = p.filter { comunesES.contains($0) }.count, en = p.filter { comunesEN.contains($0) }.count
        return i == .espanol ? (es >= 1 && en == 0) : (en >= 1 && es == 0)
    }

    func guardar(_ nuevas: [String], _ c: CategoriaDeFrase, _ i: Idioma) {
        var d = deposito(c, i)
        for f in nuevas where !d.contains(f) { d.append(f) }
        ajustes.set(Array(d.suffix(24)), forKey: claveDeposito(c, i))
    }

    /// Una frase para este momento. `turno` cambia cuando debe cambiar la frase (otra tarea, otra media hora).
    func frase(_ c: CategoriaDeFrase, turno: String, idioma: Idioma) -> String {
        let clave = "\(c.rawValue)|\(turno)|\(idioma.rawValue)"
        if clave == claveActual { return fraseActual }
        // Las frases de la IA quedan apagadas hasta que Diaz las apruebe (algunas sonaban raras):
        // por defecto, solo el banco escrito a mano. Ajustes → Modo de prueba las enciende (`frasesIA`).
        let conIA = UserDefaults.standard.bool(forKey: "frasesIA")
        let opciones = (conIA ? deposito(c, idioma) : []) + BancoDeFrases.frases(c, idioma)
        let usadas = Set(recientes.map { $0.lowercased() })
        let libres = opciones.filter { !usadas.contains($0.lowercased()) }
        let lista = libres.isEmpty ? opciones : libres
        var h = Hasher(); h.combine(clave)
        let elegida = lista.isEmpty ? "" : lista[abs(h.finalize()) % lista.count]
        claveActual = clave; fraseActual = elegida
        recientes = recientes + [elegida]
        return elegida
    }

    var ultimas: [String] { recientes.reversed() }

    /// Frases válidas: 3–15 palabras, sin números, sin culpa ni presión, sin repetir las últimas 30.
    static func validar(_ crudas: [String], evitar: [String], idioma: Idioma? = nil) -> [String] {
        let prohibidas = ["deberías", "debes", "tienes que", "culpa", "tarde", "rápido", "apúrate", "prisa ya", "médic", "diagnós",
                          "should", "must", "hurry", "late", "guilt", "doctor", "medic", "diagnos"]
        let vistas = Set(evitar.map { $0.lowercased() })
        var salida: [String] = []
        for f in crudas {
            let t = f.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "\"«»“”-•")))
            let palabras = t.split(whereSeparator: \.isWhitespace).count
            let baja = t.lowercased()
            guard (3...15).contains(palabras), t.rangeOfCharacter(from: .decimalDigits) == nil,
                  !prohibidas.contains(where: { baja.contains($0) }), !vistas.contains(baja),
                  !salida.contains(where: { $0.lowercased() == baja }),
                  idioma.map({ Self.esDelIdioma(t, $0) }) ?? true else { continue }
            salida.append(t)
        }
        return salida
    }
}

extension ServicioDeIA {
    /// En segundo plano: si la IA local está, rellena un poco el depósito de cada momento.
    func refrescarFrases() async {
        let idioma = Idioma.actual
        let m = motor
        guard !(m is MotorSimple) else { return }
        for c in CategoriaDeFrase.allCases where MemoriaDeFrases.compartida.deposito(c, idioma).count < 12 {
            let evitar = MemoriaDeFrases.compartida.deposito(c, idioma) + MemoriaDeFrases.compartida.ultimas
            guard let crudas = try? await m.frases(c, cuantas: 6, evitar: evitar, idioma: idioma) else { continue }
            let validas = MemoriaDeFrases.validar(crudas, evitar: evitar + BancoDeFrases.frases(c, idioma), idioma: idioma)
            MemoriaDeFrases.compartida.guardar(validas, c, idioma)
            anotar("Frases «\(c.rawValue)»: \(validas.count) nuevas — \(validas.first ?? "")")
        }
    }
}
