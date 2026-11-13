import SwiftUI
import SwiftData

/// La raíz de ZENO: un solo universo continuo.
/// El cielo y Lumi viven aquí y nunca se destruyen; lo que cambia encima es el contenido
/// (registro, y más adelante presencia y tareas). Así Lumi jamás desaparece y reaparece.
struct UniversoView: View {
    @Environment(\.modelContext) private var contexto
    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    @Query private var personas: [Persona]

    @State private var paso = PasoDeRegistro.bienvenida
    @State private var borrador = BorradorDeRegistro()
    @State private var lumiNacida = false
    @State private var nacimientos = 0
    @State private var mostrarLaboratorio = false

    /// El cielo antes de que exista la persona: tranquilo, sin dueño todavía.
    private static let semillaNeutra = Semilla(nombre: "zeno", anio: 2026, mes: 1, dia: 1)
    private let centroDeLumi = UnitPoint(x: 0.5, y: 0.33)

    var body: some View {
        let persona = personas.first
        let enRegistro = persona == nil
        let semilla = persona?.semilla ?? (paso.yaNacio ? borrador.semilla : Self.semillaNeutra)
        let apariencia = AparienciaLumi(semilla: semilla)
        let forma = persona?.formaDeLumi ?? borrador.forma
        let hayLumi = persona != nil || lumiNacida
        // La energía real llega en la Fase 5; por ahora un valor amable.
        let energia = hayLumi ? 0.72 : 0.30

        ZStack {
            Color("FondoArranque").ignoresSafeArea()

            GeometryReader { geo in
                ZStack {
                    NebulosaView(apariencia: apariencia,
                                 energia: energia,
                                 calidez: Cielo.calidez(hora: Cielo.horaActual()),
                                 centro: centroDeLumi)
                        .id(semilla)
                        .transition(.opacity)

                    LumiView(apariencia: apariencia, energia: energia, forma: forma)
                        .frame(width: min(geo.size.width, 430) * 0.98)
                        .scaleEffect(hayLumi ? 1 : 0.04)
                        .opacity(hayLumi ? 1 : 0)
                        .position(x: geo.size.width * centroDeLumi.x,
                                  y: geo.size.height * centroDeLumi.y)
                }
                // El cielo de la persona aparece despacio, como si se condensara.
                .animation(.easeInOut(duration: 2.6), value: semilla)
            }
            .ignoresSafeArea()
            .ignoresSafeArea(.keyboard)

            if let persona {
                casaProvisional(persona)
                    .transition(.opacity)
            } else {
                RegistroView(paso: $paso, borrador: $borrador, lumiNacida: lumiNacida, alTerminar: terminarRegistro)
                    .transition(.opacity)
            }
        }
        .sensoryFeedback(.impact(weight: .medium, intensity: 0.7), trigger: nacimientos)
        .onChange(of: paso) { _, nuevo in
            if nuevo == .nacimiento && !lumiNacida { nacer() }
        }
        .onChange(of: enRegistro) { _, ahora in
            // Si se borran los datos, el registro empieza limpio.
            if ahora {
                borrador = BorradorDeRegistro()
                paso = .bienvenida
                withAnimation(.easeInOut(duration: 1.2)) { lumiNacida = false }
            }
        }
        .fullScreenCover(isPresented: $mostrarLaboratorio) {
            LaboratorioView()
                .fontDesign(.rounded)
                .preferredColorScheme(.dark)
        }
    }

    /// El nacimiento: primero se condensa el cielo de la persona, luego se enciende Lumi.
    private func nacer() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            let animacion: Animation = reducirMovimiento
                ? .easeInOut(duration: 1.6)
                : .spring(response: 1.7, dampingFraction: 0.60)
            withAnimation(animacion) { lumiNacida = true }
            nacimientos += 1
        }
    }

    private func terminarRegistro() {
        withAnimation(.easeInOut(duration: 0.9)) {
            contexto.insert(borrador.comoPersona())
        }
    }

    /// Lugar provisional después del registro. En la Fase 3 aquí va el momento de presencia.
    private func casaProvisional(_ persona: Persona) -> some View {
        VStack(spacing: 8) {
            Spacer()
            Text("Hola, \(persona.nombre)")
                .font(.largeTitle.weight(.light))
            Text("Tu estrella ya vive aquí.")
                .font(.body.weight(.light))
                .opacity(0.8)
            Spacer().frame(height: 90)

            #if DEBUG
            // Botones temporales para probar; no estarán en la app final.
            HStack(spacing: 22) {
                Button("Laboratorio") { mostrarLaboratorio = true }
                Button("Repetir registro") {
                    withAnimation(.easeInOut(duration: 0.8)) { contexto.delete(persona) }
                }
            }
            .font(.footnote)
            .opacity(0.6)
            .padding(.bottom, 22)
            #endif
        }
        .foregroundStyle(.white)
    }
}

#Preview {
    UniversoView()
        .fontDesign(.rounded)
        .preferredColorScheme(.dark)
        .modelContainer(for: [Persona.self, Tarea.self, EventoDeEnergia.self], inMemory: true)
}
