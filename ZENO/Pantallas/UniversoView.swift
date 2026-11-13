import SwiftUI
import SwiftData

/// La raíz de ZENO: un solo universo continuo.
/// El cielo y Lumi viven aquí y nunca se destruyen; lo que cambia encima es el contenido
/// (registro, presencia, tarea). Así Lumi jamás desaparece y reaparece: se mueve.
struct UniversoView: View {
    /// Qué se ve cuando la persona ya existe.
    enum Momento { case presencia, tarea }

    @Environment(\.modelContext) private var contexto
    @Environment(\.scenePhase) private var fase
    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    @Query private var personas: [Persona]

    @State private var paso = PasoDeRegistro.bienvenida
    @State private var borrador = BorradorDeRegistro()
    @State private var lumiNacida = false
    @State private var nacimientos = 0
    @State private var momento = Momento.presencia
    @State private var visita = 0            // cambia cada vez que se abre la app
    @State private var estuvoEnFondo = false
    @State private var mostrarLaboratorio = false
    @State private var escuchando = false    // Lumi está oyendo una tarea dictada

    /// El cielo antes de que exista la persona: tranquilo, sin dueño todavía.
    private static let semillaNeutra = Semilla(nombre: "zeno", anio: 2026, mes: 1, dia: 1)

    var body: some View {
        let persona = personas.first
        let enRegistro = persona == nil
        let semilla = persona?.semilla ?? (paso.yaNacio ? borrador.semilla : Self.semillaNeutra)
        let apariencia = AparienciaLumi(semilla: semilla)
        let forma = persona?.formaDeLumi ?? borrador.forma
        let hayLumi = persona != nil || lumiNacida
        // La energía real llega en la Fase 5; por ahora un valor amable.
        let energia = hayLumi ? 0.72 : 0.30

        // Dónde está Lumi: en el centro durante la presencia, arriba cuando llega la tarea.
        let enTarea = persona != nil && momento == .tarea
        let enPresencia = persona != nil && momento == .presencia
        let centro = UnitPoint(x: 0.5, y: enTarea ? 0.23 : (enPresencia ? 0.34 : 0.33))
        let tamano = (enTarea ? 0.74 : 1.0) * (escuchando ? 1.12 : 1.0)

        ZStack {
            Color("FondoArranque").ignoresSafeArea()

            GeometryReader { geo in
                ZStack {
                    NebulosaView(apariencia: apariencia,
                                 energia: energia,
                                 calidez: Cielo.calidez(hora: Cielo.horaActual()),
                                 centro: centro)
                        .id(semilla)
                        .transition(.opacity)

                    LumiView(apariencia: apariencia, energia: energia, forma: forma)
                        .frame(width: min(geo.size.width, 430) * 0.98)
                        .scaleEffect(hayLumi ? tamano : 0.04)
                        .opacity(hayLumi ? 1 : 0)
                        .position(x: geo.size.width * centro.x,
                                  y: geo.size.height * centro.y)
                }
                // El cielo de la persona aparece despacio, como si se condensara.
                .animation(.easeInOut(duration: 2.6), value: semilla)
            }
            .ignoresSafeArea()
            .ignoresSafeArea(.keyboard)

            if let persona {
                contenido(de: persona)
            } else {
                RegistroView(paso: $paso, borrador: $borrador, lumiNacida: lumiNacida, alTerminar: terminarRegistro)
                    .transition(.opacity)
            }
        }
        .sensoryFeedback(.impact(weight: .medium, intensity: 0.7), trigger: nacimientos)
        .sensoryFeedback(.impact(weight: .light, intensity: 0.6), trigger: momento)
        .onChange(of: paso) { _, nuevo in
            if nuevo == .nacimiento && !lumiNacida { nacer() }
        }
        .onChange(of: enRegistro) { _, ahora in
            // Si se borran los datos, el registro empieza limpio.
            if ahora {
                borrador = BorradorDeRegistro()
                paso = .bienvenida
                momento = .presencia
                withAnimation(.easeInOut(duration: 1.2)) { lumiNacida = false }
            }
        }
        .onChange(of: fase) { _, nueva in
            // Cada vez que la persona vuelve a la app, se repite el momento de presencia.
            if nueva == .background {
                estuvoEnFondo = true
            } else if nueva == .active && estuvoEnFondo {
                estuvoEnFondo = false
                visita += 1
                withAnimation(movimientoDeLumi) { momento = .presencia }
            }
        }
        .fullScreenCover(isPresented: $mostrarLaboratorio) {
            LaboratorioView()
                .fontDesign(.rounded)
                .preferredColorScheme(.dark)
        }
    }

    /// Lumi se mueve como un objeto físico: resorte con un pequeño rebote al llegar.
    private var movimientoDeLumi: Animation {
        reducirMovimiento ? .easeInOut(duration: 0.6) : .spring(response: 1.0, dampingFraction: 0.70)
    }

    @ViewBuilder
    private func contenido(de persona: Persona) -> some View {
        GeometryReader { geo in
            switch momento {
            case .presencia:
                // Las tres líneas, debajo de Lumi.
                PresenciaView(persona: persona) {
                    withAnimation(movimientoDeLumi) { momento = .tarea }
                }
                .id(visita)
                .frame(height: geo.size.height * 0.34)
                .position(x: geo.size.width / 2, y: geo.size.height * 0.70)
                .transition(.opacity)

            case .tarea:
                // Lumi se dibuja a pantalla completa; aquí se descuenta el margen de arriba.
                let arriba = geo.safeAreaInsets.top
                let altoTotal = geo.size.height + arriba + geo.safeAreaInsets.bottom
                VStack(spacing: 0) {
                    TareaDelMomentoView(
                        centroDeLumi: CGPoint(x: geo.size.width / 2, y: altoTotal * 0.23 - arriba),
                        inicioDelContenido: altoTotal * 0.40 - arriba,
                        escuchando: $escuchando)
                    botonesDePrueba(persona)
                }
                .transition(.opacity.combined(with: .offset(y: 18)))
            }
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
        momento = .presencia
        visita += 1
        withAnimation(.easeInOut(duration: 0.9)) {
            contexto.insert(borrador.comoPersona())
        }
    }

    @ViewBuilder
    private func botonesDePrueba(_ persona: Persona) -> some View {
        #if DEBUG
        // Botones temporales para probar; no estarán en la app final.
        HStack(spacing: 20) {
            Button("Ver presencia") {
                visita += 1
                withAnimation(movimientoDeLumi) { momento = .presencia }
            }
            Button("Laboratorio") { mostrarLaboratorio = true }
            Button("Repetir registro") {
                withAnimation(.easeInOut(duration: 0.8)) { contexto.delete(persona) }
            }
        }
        .font(.footnote)
        .foregroundStyle(.white.opacity(0.6))
        .padding(.bottom, 8)
        #endif
    }
}

#Preview {
    UniversoView()
        .fontDesign(.rounded)
        .preferredColorScheme(.dark)
        .modelContainer(for: [Persona.self, Tarea.self, EventoDeEnergia.self], inMemory: true)
}
