import SwiftUI
import SwiftData

/// La pantalla de la tarea del momento: una sola tarea, y la forma de agregar otra
/// con una frase escrita o hablada. Lumi vive detrás, en `UniversoView`.
struct TareaDelMomentoView: View {
    enum Modo: Equatable { case ver, agregar, primerPaso }

    /// Dónde está Lumi dentro de esta vista, para poder mantenerla presionada.
    let centroDeLumi: CGPoint
    /// Dónde empieza el texto, debajo de Lumi.
    let inicioDelContenido: CGFloat
    @Binding var escuchando: Bool

    @Environment(\.modelContext) private var contexto
    @Query(filter: #Predicate<Tarea> { $0.terminadaEn == nil }, sort: \Tarea.creadaEn)
    private var pendientes: [Tarea]

    @State private var modo = Modo.ver
    @State private var frase = ""
    @State private var primerPaso = ""
    @State private var saltadas = 0
    @State private var mostrarLista = false
    @State private var dictado = Dictado()
    @State private var toques = 0
    @FocusState private var escribiendo: Bool

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 14) {
                Spacer().frame(height: inicioDelContenido)
                switch modo {
                case .ver: ver
                case .agregar: agregar
                case .primerPaso: preguntaDelPrimerPaso
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .foregroundStyle(.white)

            // Zona invisible sobre Lumi: mantener presionada para hablar.
            Circle()
                .fill(.white.opacity(0.001))
                .frame(width: 190, height: 190)
                .position(centroDeLumi)
                .gesture(mantenerParaHablar)
                .accessibilityLabel(Text("Lumi"))
                .accessibilityHint(Text("Mantén presionado para dictar una tarea"))
        }
        .ignoresSafeArea(.keyboard)
        .sensoryFeedback(.selection, trigger: toques)
        .sensoryFeedback(.impact(weight: .light), trigger: escuchando)
        .onChange(of: dictado.texto) { _, nuevo in
            // Lo que se dicta va apareciendo en el campo activo.
            guard !nuevo.isEmpty else { return }
            if modo == .primerPaso { primerPaso = nuevo } else { frase = nuevo }
        }
        .onChange(of: dictado.activo) { _, activo in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { escuchando = activo }
        }
        .sheet(isPresented: $mostrarLista) {
            MisTareasView()
                .fontDesign(.rounded)
                .preferredColorScheme(.dark)
        }
    }

    // MARK: Ver la tarea del momento

    @ViewBuilder
    private var ver: some View {
        if let tarea = tareaActual {
            VStack(spacing: 8) {
                Text(tarea.textoVisible)
                    .font(.title2.weight(.regular))
                    .multilineTextAlignment(.center)
                if tarea.primerPaso != nil {
                    // Se muestra el primer paso; la tarea grande queda como contexto.
                    Text("Primer paso de: \(tarea.titulo)")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .opacity(0.6)
                }
            }
            .padding(.horizontal, 32)
            .id(tarea.persistentModelID)
            .transition(.opacity.combined(with: .offset(y: 10)))

            Spacer().frame(height: 6)
            BotonZeno("Hecha") { terminar(tarea) }
            Button("Ahora no") { ahoraNo(tarea) }
                .font(.body)
                .opacity(0.75)
        } else {
            Text("No tienes nada pendiente")
                .font(.title3.weight(.light))
            Text("Cuando quieras, agrega una sola cosa.")
                .font(.footnote)
                .opacity(0.65)
        }

        Spacer()

        if let aviso = dictado.aviso {
            Text(aviso)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .opacity(0.75)
                .padding(.horizontal, 32)
        }
        HStack(spacing: 28) {
            Button("Agregar tarea") { abrirAgregar() }
            if !pendientes.isEmpty {
                Button("Mis tareas") { mostrarLista = true }
            }
        }
        .font(.subheadline.weight(.medium))
        .padding(.bottom, 10)
    }

    private var tareaActual: Tarea? {
        guard !pendientes.isEmpty else { return nil }
        return pendientes[saltadas % pendientes.count]
    }

    // MARK: Agregar

    private var agregar: some View {
        VStack(spacing: 14) {
            Text(escuchando ? "Te escucho…" : "¿Qué quieres hacer?")
                .font(.title2.weight(.light))
            campo($frase, sugerencia: "Una sola frase")
            HStack(spacing: 12) {
                botonChico("Cancelar", fuerte: false) { cerrarAgregar() }
                botonChico("Guardar", fuerte: true) { guardarFrase() }
                    .disabled(limpio(frase).isEmpty)
                    .opacity(limpio(frase).isEmpty ? 0.45 : 1)
            }
            Text(dictado.aviso ?? String(localized: "También puedes mantener presionada a Lumi y hablar."))
                .font(.footnote)
                .multilineTextAlignment(.center)
                .opacity(0.6)
                .padding(.horizontal, 32)
        }
    }

    private var preguntaDelPrimerPaso: some View {
        VStack(spacing: 14) {
            Text("¿Cuál es el primer paso de dos minutos?")
                .font(.title3.weight(.light))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            campo($primerPaso, sugerencia: "Algo muy pequeño")
            HStack(spacing: 12) {
                botonChico("Saltar", fuerte: false) { guardarTarea(conPaso: false) }
                botonChico("Listo", fuerte: true) { guardarTarea(conPaso: true) }
                    .disabled(limpio(primerPaso).isEmpty)
                    .opacity(limpio(primerPaso).isEmpty ? 0.45 : 1)
            }
            Text("\(limpio(frase))")
                .font(.footnote)
                .opacity(0.55)
                .padding(.horizontal, 32)
        }
    }

    private func campo(_ texto: Binding<String>, sugerencia: LocalizedStringKey) -> some View {
        TextField("", text: texto, prompt: Text(sugerencia).foregroundStyle(.white.opacity(0.35)), axis: .vertical)
            .font(.title3)
            .multilineTextAlignment(.center)
            .lineLimit(1...3)
            .submitLabel(.done)
            .focused($escribiendo)
            .onChange(of: texto.wrappedValue) { _, nuevo in
                // "Intro" guarda, en vez de saltar de línea.
                if nuevo.contains("\n") {
                    texto.wrappedValue = nuevo.replacingOccurrences(of: "\n", with: "")
                    if modo == .primerPaso { guardarTarea(conPaso: true) } else { guardarFrase() }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 28)
    }

    private func botonChico(_ titulo: LocalizedStringKey, fuerte: Bool, accion: @escaping () -> Void) -> some View {
        Button(action: accion) {
            Text(titulo)
                .font(.body.weight(.medium))
                .padding(.vertical, 11)
                .padding(.horizontal, 26)
                .background(.white.opacity(fuerte ? 0.20 : 0.07), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Voz

    /// Mantener presionada a Lumi: empieza a escuchar; al soltar, deja de escuchar.
    private var mantenerParaHablar: some Gesture {
        LongPressGesture(minimumDuration: 0.3)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { valor in
                if case .second(true, _) = valor, !dictado.activo, dictado.aviso == nil || !escuchando {
                    empezarAEscuchar()
                }
            }
            .onEnded { _ in
                dictado.detener()
                yaPidioEscuchar = false
            }
    }

    @State private var yaPidioEscuchar = false

    private func empezarAEscuchar() {
        guard !yaPidioEscuchar else { return }
        yaPidioEscuchar = true
        escribiendo = false
        if modo == .ver {
            frase = ""
            withAnimation(.easeInOut(duration: 0.4)) { modo = .agregar }
        }
        dictado.empezar()
    }

    // MARK: Acciones

    private func limpio(_ texto: String) -> String {
        texto.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func abrirAgregar() {
        toques += 1
        frase = ""
        primerPaso = ""
        dictado.aviso = nil
        withAnimation(.easeInOut(duration: 0.4)) { modo = .agregar }
        enfocarPronto()
    }

    /// El campo nuevo tarda un instante en existir; el teclado se le da cuando ya está en pantalla.
    private func enfocarPronto() {
        escribiendo = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if modo != .ver { escribiendo = true }
        }
    }

    private func cerrarAgregar() {
        toques += 1
        escribiendo = false
        withAnimation(.easeInOut(duration: 0.4)) { modo = .ver }
    }

    private func guardarFrase() {
        guard !limpio(frase).isEmpty else { return }
        toques += 1
        if ClasificadorDeTamano.tamano(de: frase) == .grande {
            // Tarea grande: Lumi pregunta por el primer paso.
            primerPaso = ""
            withAnimation(.easeInOut(duration: 0.4)) { modo = .primerPaso }
            enfocarPronto()
        } else {
            guardarTarea(conPaso: false)
        }
    }

    private func guardarTarea(conPaso: Bool) {
        let titulo = limpio(frase)
        guard !titulo.isEmpty else { return }
        let paso = limpio(primerPaso)
        let tarea = Tarea(titulo: titulo,
                          tamano: ClasificadorDeTamano.tamano(de: titulo),
                          primerPaso: conPaso && !paso.isEmpty ? paso : nil)
        contexto.insert(tarea)
        toques += 1
        escribiendo = false
        frase = ""
        primerPaso = ""
        withAnimation(.easeInOut(duration: 0.4)) { modo = .ver }
    }

    private func terminar(_ tarea: Tarea) {
        toques += 1
        contexto.insert(EventoDeEnergia(tipo: .tareaTerminada, tarea: tarea))
        withAnimation(.easeInOut(duration: 0.5)) { tarea.terminadaEn = .now }
    }

    private func ahoraNo(_ tarea: Tarea) {
        toques += 1
        contexto.insert(EventoDeEnergia(tipo: .ahoraNo, tarea: tarea))
        withAnimation(.easeInOut(duration: 0.4)) { saltadas += 1 }
    }
}

/// Lo pendiente, sin fechas, sin rojo y sin contadores.
struct MisTareasView: View {
    @Environment(\.modelContext) private var contexto
    @Environment(\.dismiss) private var cerrar
    @Query(filter: #Predicate<Tarea> { $0.terminadaEn == nil }, sort: \Tarea.creadaEn)
    private var pendientes: [Tarea]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Mis tareas")
                    .font(.title2.weight(.medium))
                Spacer()
                Button("Cerrar") { cerrar() }
                    .font(.subheadline)
            }
            .padding(.horizontal, 24)
            .padding(.top, 26)
            .padding(.bottom, 8)

            if pendientes.isEmpty {
                Spacer()
                Text("Nada pendiente.")
                    .font(.title3.weight(.light))
                    .opacity(0.8)
                Spacer()
            } else {
                List {
                    ForEach(pendientes) { tarea in
                        HStack(alignment: .top, spacing: 14) {
                            Button {
                                contexto.insert(EventoDeEnergia(tipo: .tareaTerminada, tarea: tarea))
                                withAnimation { tarea.terminadaEn = .now }
                            } label: {
                                Circle()
                                    .stroke(.white.opacity(0.55), lineWidth: 1.5)
                                    .frame(width: 24, height: 24)
                                    .contentShape(Rectangle().inset(by: -10))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text("Marcar como hecha"))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(tarea.titulo)
                                    .font(.body)
                                if let paso = tarea.primerPaso {
                                    Text("Primer paso: \(paso)")
                                        .font(.footnote)
                                        .opacity(0.6)
                                }
                            }
                        }
                        .padding(.vertical, 6)
                        .listRowBackground(Color.clear)
                        .listRowSeparatorTint(.white.opacity(0.12))
                    }
                    .onDelete { indices in
                        for i in indices { contexto.delete(pendientes[i]) }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .foregroundStyle(.white)
        .tint(.white)
        .presentationDetents([.medium, .large])
        // Azul profundo, del mismo mundo que la nebulosa (no gris).
        .presentationBackground(Color("FondoArranque").opacity(0.94))
    }
}
