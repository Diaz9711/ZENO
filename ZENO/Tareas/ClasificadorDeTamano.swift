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

    private static let chicas = [
        "llamar", "enviar", "mandar", "responder", "contestar", "pagar", "comprar", "sacar", "regar",
        "tomar", "agendar", "confirmar", "revisar el correo", "tender la cama", "lavar los platos",
        "call", "send", "email", "reply", "answer", "pay", "buy", "water", "book", "confirm", "text "
    ]

    static func tamano(de frase: String) -> TamanoDeTarea {
        let texto = frase
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased() + " "
        let palabras = texto.split(whereSeparator: { $0.isWhitespace }).count

        if grandes.contains(where: texto.contains) { return .grande }
        if palabras >= 10 { return .grande }
        if chicas.contains(where: texto.contains) { return .chica }
        if palabras <= 2 { return .chica }
        return .mediana
    }
}
