import Foundation

/// Decide solo si una tarea es chica, mediana o grande, a partir de la frase.
/// Es una regla sencilla por palabras clave y longitud (español e inglés); no usa internet.
/// Si se equivoca no pasa nada grave: una "grande" solo provoca la pregunta del primer paso.
enum ClasificadorDeTamano {
    // Raíces de palabra, para que valgan "organizar", "organiza", "organizando"…
    private static let grandes = [
        "proyecto", "tesis", "mudanza", "mudar", "organiz", "ordenar todo", "planea", "planific",
        "prepar", "estudi", "termin", "informe", "reporte", "ensayo", "presentaci", "impuesto",
        "declaraci", "renov", "remodel", "limpiar la casa", "limpiar todo", "limpiar el cuarto",
        "curriculum", "tramite", "buscar trabajo", "aprend", "investig", "disen", "constru",
        "project", "thesis", "organis", "plan ", "study", "finish", "report", "essay",
        "presentation", "taxes", "clean the house", "resume", "learn", "research", "build"
    ]

    /// Inicios de palabra de cosas rápidas ("llam" vale para llamar, llama, llamé…).
    private static let chicas = [
        "llam", "envi", "mand", "respond", "contest", "pagar", "pague", "paga ", "compr", "regar", "riega",
        "agend", "confirm", "tender la cama", "lavar los platos", "tirar la basura", "saca la basura",
        "sacar la basura", "escrib", "avis", "recoger",
        "call", "send", "email", "reply", "answer", "pay ", "buy", "water", "book", "confirm", "text "
    ]

    static func tamano(de frase: String) -> TamanoDeTarea {
        let texto = frase
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased() + " "
        let palabras = texto.split(whereSeparator: { $0.isWhitespace }).count

        if grandes.contains(where: texto.contains) { return .grande }
        if palabras >= 10 { return .grande }
        // Las chicas se buscan al inicio de una palabra, para no confundir "pagar" con "página".
        let conEspacio = " " + texto
        if chicas.contains(where: { conEspacio.contains(" " + $0) }) { return .chica }
        if palabras <= 2 { return .chica }
        return .mediana
    }
}

/// El tipo de una tarea (llamadas, trámites, papeles…), por palabras clave. Sirve para aprender qué
/// tipos le cuestan a la persona y dividirlos en pasos más pequeños. nil = otro tipo.
enum TipoDeTarea: String, CaseIterable {
    case llamada, tramite, papeles, correo, compras, limpieza, estudio

    private var raices: [String] {
        switch self {
        case .llamada: ["llam", "telefon", "call ", "phone"]
        case .tramite: ["tramite", "cita", "banco", "renov", "pasaporte", "licencia", "seguro", "hacienda", "impuesto",
                        "appointment", "bank", "renew", "passport", "license", "insurance", "taxes"]
        case .papeles: ["papel", "factura", "formulario", "document", "firmar", "declaraci", "recibo",
                        "paperwork", "form", "invoice", "sign ", "receipt", "bill"]
        case .correo: ["correo", "mail", "respond", "contest", "mensaje", "email", "reply", "inbox"]
        case .compras: ["compr", "super", "buy", "shop", "grocer"]
        case .limpieza: ["limpi", "ordenar", "lavar", "barrer", "basura", "clean", "tidy", "laundry", "dishes"]
        case .estudio: ["estudi", "tarea de", "examen", "leer", "ensayo", "study", "exam", "read", "essay", "homework"]
        }
    }

    static func de(_ titulo: String) -> TipoDeTarea? {
        let texto = " " + titulo.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased() + " "
        return allCases.first { tipo in tipo.raices.contains { texto.contains(" " + $0) } }
    }
}
