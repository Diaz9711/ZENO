import SwiftUI

/// Pantalla de prueba de la Fase 1. No forma parte de la app final:
/// sirve para ver a Lumi y a su nebulosa con distintas energías, horas y personas.
struct LaboratorioView: View {
    @State private var persona = PersonaDePrueba(nombre: "Diaz", anio: 1999, mes: 6, dia: 15)
    @State private var energia = 70.0
    @State private var hora = Cielo.horaActual()
    @State private var cambios = 0
    @Environment(\.dismiss) private var cerrar
    @Environment(\.isPresented) private var presentado
    @State private var cielo = TonoDeCielo.azulado
    @State private var forma = FormaDeLumi.estrella

    private let centroDeLumi = UnitPoint(x: 0.5, y: 0.33)

    var body: some View {
        let apariencia = AparienciaLumi(semilla: persona.semilla, cielo: cielo)
        let identidad = "\(persona.semilla.valor)-\(cielo.rawValue)"

        ZStack(alignment: .bottom) {
          Color("FondoArranque").ignoresSafeArea()

          // Lumi y la nebulosa usan la pantalla completa, para que el calor nazca justo donde está la estrella.
          GeometryReader { geo in
            ZStack {
                NebulosaView(apariencia: apariencia,
                             energia: energia / 100,
                             calidez: Cielo.calidez(hora: hora),
                             centro: centroDeLumi)
                    .id(identidad)
                    .transition(.opacity)

                LumiView(apariencia: apariencia, energia: energia / 100, forma: forma)
                    .frame(width: min(geo.size.width, 430) * 0.98)
                    .position(x: geo.size.width * centroDeLumi.x,
                              y: geo.size.height * centroDeLumi.y)
                    .id(persona.semilla)
                    .transition(.opacity)
            }
          }
          .ignoresSafeArea()

          controles
        }
        .sensoryFeedback(.impact(weight: .light), trigger: cambios)
    }

    private var controles: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Estrella de \(persona.nombre)")
                        .font(.headline.weight(.medium))
                    Text(persona.fechaLegible)
                        .font(.footnote)
                        .opacity(0.7)
                }
                Spacer()
                if presentado {
                    Button("Cerrar") { cerrar() }
                        .font(.subheadline)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Energía")
                    Spacer()
                    Text("\(Int(energia)) · \(nivel)")
                        .monospacedDigit()
                        .opacity(0.75)
                }
                .font(.subheadline)
                Slider(value: $energia, in: 0...100)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Hora del día")
                    Spacer()
                    Text(horaLegible)
                        .monospacedDigit()
                        .opacity(0.75)
                }
                .font(.subheadline)
                Slider(value: $hora, in: 0...23.99)
            }

            Picker("Forma de Lumi", selection: $forma) {
                Text("Estrella").tag(FormaDeLumi.estrella)
                Text("Esfera").tag(FormaDeLumi.esfera)
            }
            .pickerStyle(.segmented)

            Button {
                cambios += 1
                withAnimation(.easeInOut(duration: 1.6)) {
                    persona = .alAzar()
                }
            } label: {
                Text("Probar otra estrella")
                    .font(.body.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(.white.opacity(0.14), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.white)
        .tint(Color.oroZeno)
        .padding(20)
        .background(.ultraThinMaterial.opacity(0.75), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 14)
        .padding(.bottom, 6)
    }

    private var nivel: String {
        switch energia {
        case ..<34: Idioma.texto("baja")
        case ..<67: Idioma.texto("media")
        default: Idioma.texto("alta")
        }
    }

    private var horaLegible: String {
        let h = Int(hora)
        let m = Int((hora - Double(h)) * 60)
        return String(format: "%02d:%02d", h, m)
    }
}

/// Una persona inventada para probar semillas distintas.
struct PersonaDePrueba: Equatable {
    var nombre: String
    var anio: Int
    var mes: Int
    var dia: Int

    var semilla: Semilla { Semilla(nombre: nombre, anio: anio, mes: mes, dia: dia) }

    var fechaLegible: String {
        let fecha = Calendar.current.date(from: DateComponents(year: anio, month: mes, day: dia)) ?? .now
        return fecha.formatted(date: .long, time: .omitted)
    }

    static func alAzar() -> PersonaDePrueba {
        let nombres = ["Marina", "Leo", "Sofía", "Andrés", "Valentina", "Mateo", "Camila", "Iván",
                       "Lucía", "Emilio", "Renata", "Tomás", "Alma", "Bruno", "Noa", "Julián"]
        return PersonaDePrueba(nombre: nombres.randomElement() ?? "Alma",
                               anio: Int.random(in: 1965...2008),
                               mes: Int.random(in: 1...12),
                               dia: Int.random(in: 1...28))
    }
}

#Preview {
    LaboratorioView()
        .fontDesign(.rounded)
        .preferredColorScheme(.dark)
}
