import SwiftUI

/// El momento de presencia: al abrir la app, tres líneas traen a la persona al hoy.
/// Sin botones. Acompaña, nunca avergüenza.
struct PresenciaView: View {
    let persona: Persona
    var alTerminar: () -> Void

    @State private var visibles = 0
    @State private var terminado = false

    var body: some View {
        let lineas = Self.lineas(para: persona)

        VStack(spacing: 14) {
            ForEach(Array(lineas.enumerated()), id: \.offset) { indice, linea in
                Text(linea)
                    .font(indice == lineas.count - 1 ? .title3.weight(.regular) : .title2.weight(.light))
                    .multilineTextAlignment(.center)
                    .opacity(visibles > indice ? (indice == lineas.count - 1 ? 1 : 0.85) : 0)
                    .offset(y: visibles > indice ? 0 : 10)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        // Quien ya lo leyó puede tocar para seguir.
        .onTapGesture(perform: terminar)
        .accessibilityElement(children: .combine)
        .task {
            // Aparecen una por una; después de un respiro, Lumi sube sola.
            for i in 1...lineas.count {
                try? await Task.sleep(for: .seconds(i == 1 ? 0.9 : 0.7))
                withAnimation(.easeOut(duration: 0.7)) { visibles = i }
            }
            try? await Task.sleep(for: .seconds(2.3))
            terminar()
        }
    }

    private func terminar() {
        guard !terminado else { return }
        terminado = true
        alTerminar()
    }

    /// Fecha de hoy, edad (si la persona quiere verla) y la frase del día.
    static func lineas(para persona: Persona, hoy: Date = .now) -> [String] {
        var lineas: [String] = []

        let fecha = hoy.formatted(.dateTime.weekday(.wide).day().month(.wide))
        lineas.append(fecha.prefix(1).uppercased() + fecha.dropFirst())

        if persona.mostrarEdad {
            lineas.append(String(localized: "Tienes \(persona.edad(en: hoy)) años"))
        }

        lineas.append(FraseDelDia.frase(hoy: hoy, semilla: persona.semilla))
        return lineas
    }
}

/// Una frase corta que cambia cada día. Siempre amable: nada de culpa, deuda ni rachas.
enum FraseDelDia {
    static let frases: [String.LocalizationValue] = [
        "Hoy es suficiente.",
        "Estás aquí. Eso ya cuenta.",
        "Un paso pequeño también es un paso.",
        "No hay prisa.",
        "Empieza por lo más pequeño.",
        "Respira. Ya llegaste.",
        "Hoy solo una cosa.",
        "Lo que puedas, como puedas.",
        "Este momento es tuyo.",
        "No tienes que poder con todo.",
        "Despacio también se llega.",
        "Hoy empieza ahora.",
        "Tu ritmo está bien.",
        "Una cosa a la vez.",
        "Descansar también es avanzar.",
        "No vas tarde.",
        "Lo de ayer ya pasó. Hoy es hoy.",
        "Basta con empezar.",
        "Vas a tu paso, y está bien.",
        "Aquí y ahora.",
        "Hoy puedes ser amable contigo.",
        "Lo pequeño suma.",
        "Sin apuro. Lumi te acompaña.",
        "Solo lo siguiente.",
        "Hoy cuenta, sea como sea.",
        "Tu energía manda. Escúchala.",
        "No hace falta que sea perfecto.",
        "Un momento a la vez.",
        "Estás justo donde toca.",
        "Empezar ya es mucho.",
        "Hoy, con calma."
    ]

    /// La misma frase durante todo el día; distinta para cada persona.
    static func frase(hoy: Date = .now, semilla: Semilla, calendario: Calendar = .current) -> String {
        let dia = calendario.ordinality(of: .day, in: .era, for: hoy) ?? 0
        let indice = (dia + Int(semilla.valor % 97)) % frases.count
        return String(localized: frases[indice])
    }
}
