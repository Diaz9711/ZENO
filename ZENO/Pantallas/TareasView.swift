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
    /// Puntaje de energía actual (0–100) y el historial del que sale.
    var puntaje: Double
    var eventos: [EventoDeEnergia]
    /// Avisa a Lumi que celebre una tarea terminada.
    var alTerminar: (Celebracion) -> Void = { _ in }
    /// La hora de más energía, para la tarjeta de hoy.
    var mejorHora: Int = 12
    /// Cambia cada vez que se toca el "+" de la barra.
    var pedirAgregar: Int = 0
    /// Avisa cuando se está escribiendo, para esconder la barra.
    @Binding var editando: Bool

    @Environment(\.modelContext) private var contexto
    /// Leído para que, al cambiar de idioma, también se redibujen las frases armadas en código.
    @Environment(\.locale) private var idiomaElegido
    @Query(filter: #Predicate<Tarea> { $0.terminadaEn == nil }, sort: \Tarea.creadaEn)
    private var pendientes: [Tarea]

    @State private var modo = Modo.ver
    @State private var frase = ""
    @State private var primerPaso = ""
    @State private var quiereAlgoIgual = false
    @State private var plan = BorradorDePlan()
    @State private var dictado = Dictado()
    @State private var toques = 0
    @FocusState private var escribiendo: Bool

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 14) {
                Spacer().frame(height: inicioDelContenido)
                switch modo {
                case .ver: Group { ver }.transition(.desenfoque)
                case .agregar: agregar.transition(.desenfoque)
                case .primerPaso: preguntaDelPrimerPaso.transition(.desenfoque)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .foregroundStyle(Color.marfil)

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
        .onChange(of: idPropuesta, initial: true) { _, nueva in
            // Queda registrado qué se propuso y con cuánta energía, para aprender.
            if let nueva, let tarea = pendientes.first(where: { $0.persistentModelID == nueva }), enCurso != nueva {
                registrar(.tareaPropuesta, valor: puntaje, tarea: tarea)
            }
        }
        .onChange(of: dictado.activo) { _, activo in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { escuchando = activo }
        }
        .onChange(of: pedirAgregar) { _, _ in abrirAgregar() }
        .onChange(of: modo) { _, nuevo in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { editando = nuevo != .ver }
        }
    }

    // MARK: Ver la tarea del momento

    /// La tarea empezada (si hay una); sobrevive aunque se cierre la app.
    private var enCurso: PersistentIdentifier? {
        pendientes.first(where: \.estaEnCurso)?.persistentModelID
    }

    /// Dos tareas terminadas en menos de 30 minutos: está en racha.
    private var enRacha: Bool {
        let recientes = eventos.filter { $0.tipo == .tareaTerminada && Date.now.timeIntervalSince($0.fecha) < 30 * 60 }
        return recientes.count >= 2
    }

    @ViewBuilder
    private var ver: some View {
        switch eleccion {
        case .tarea(let tarea):
            if enRacha && enCurso == nil {
                // Si va rápido, se le ofrece una más, sin presión.
                Etiqueta("Vas en racha · ¿una más?")
                    .transition(.opacity)
            } else {
                Etiqueta(tarea.primerPaso != nil ? "Primer paso" : (enCurso == nil ? "Ahora" : "En curso"))
            }
            // Sin botón: la tarea misma es el control (decisión de Diaz).
            // Tocarla la empieza y el anillo aparece en Lumi; mantenerla presionada la termina.
            let enMarcha = enCurso == tarea.persistentModelID
            TareaTocable(tarea: tarea, enCurso: enMarcha,
                         alEmpezar: { empezar(tarea) },
                         alTerminar: { terminar(tarea) })
                .id(tarea.persistentModelID)
                .transition(.desenfoque)

            Text(enMarcha ? "Mantén presionada la tarea cuando termines" : "Toca la tarea para empezar")
                .font(.zenoTexto(.footnote))
                .foregroundStyle(Color.marfil.opacity(0.6))
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.5), value: enMarcha)
                .accessibilityHidden(true)
            // Lo aprendido, dicho en voz baja: cuánto suele tomarle de verdad algo así.
            if !enMarcha, tarea.primerPaso == nil,
               let minutos = Aprendizaje.minutosReales(tarea.tamano, eventos: eventos) {
                Text("Algo así suele tomarte unos \(Int(minutos.rounded())) min.")
                    .font(.zenoTexto(.caption))
                    .foregroundStyle(Color.oroZeno.opacity(0.75))
                    .transition(.opacity)
            }

            Spacer().frame(height: 4)
            Button(enMarcha ? "Dejarla para después" : "Ahora no") { ahoraNo(tarea) }
                .font(.zenoTexto(.body))
                .opacity(0.75)

        case .descanso:
            Etiqueta("Descanso")
            Titular(texto: Idioma.texto("Hoy descansa, mañana atacamos"), tamano: .title)
                .padding(.horizontal, 32)
            Text("Tu energía está baja, y está bien.")
                .font(.zenoTexto(.footnote))
                .opacity(0.65)
            Button("Quiero hacer algo igual") {
                toques += 1
                withAnimation(.easeInOut(duration: 0.4)) { quiereAlgoIgual = true }
            }
            .font(.zenoTexto(.body))
            .opacity(0.75)
            .padding(.top, 10)

        case .masTarde:
            Text("Por ahora, nada")
                .font(.zenoTitulo(.title3))
                .luminoso()
            Text(vuelveA.map { Idioma.texto("Vuelvo a proponerte algo a las \($0.formatted(date: .omitted, time: .shortened)).") }
                 ?? Idioma.texto("Lo intentamos más tarde."))
                .font(.zenoTexto(.footnote))
                .opacity(0.65)

        case .nadaPendiente:
            Titular(texto: Idioma.texto("No tienes nada pendiente"), tamano: .title)
                .padding(.horizontal, 32)
            Text("Cuando quieras, agrega una sola cosa.")
                .font(.zenoTexto(.footnote))
                .opacity(0.65)
        }

        Spacer()

        // Escribir una tarea sin buscar el "+": al tocarlo, el campo sube bajo Lumi.
        if mostrarCampoRapido {
            CampoRapido { abrirAgregar() }
                .padding(.horizontal, 28)
                .padding(.bottom, 4)
                .aparece(1)
        }

        if let aviso = dictado.aviso {
            Text(aviso)
                .font(.zenoTexto(.footnote))
                .multilineTextAlignment(.center)
                .opacity(0.75)
                .padding(.horizontal, 32)
        }
        // La tarjeta solo aparece cuando hay algo que celebrar: una fila de ceros parece un marcador vacío.
        Group {
            if hechasHoy.isEmpty {
                Color.clear.frame(height: 1)
            } else {
                TarjetaDeHoy(hechas: hechasHoy.count, minutos: minutosEnFoco, mejorHora: mejorHora)
                    .aparece(2)
            }
        }
        .padding(.bottom, 92)      // deja sitio a la barra
    }

    /// El campo para escribir aparece cuando no hay una tarea en marcha ni descanso:
    /// así la pantalla sigue teniendo una sola acción principal.
    private var mostrarCampoRapido: Bool {
        guard enCurso == nil else { return false }
        if case .descanso = eleccion { return false }
        return true
    }

    /// Cuándo termina la pausa del último "Ahora no".
    private var vuelveA: Date? {
        eventos.filter { $0.tipo == .ahoraNo && Date.now.timeIntervalSince($0.fecha) < 90 * 60 }
            .map { $0.fecha.addingTimeInterval(90 * 60) }
            .min()
    }

    private var hechasHoy: [EventoDeEnergia] {
        eventos.filter { $0.tipo == .tareaTerminada && Calendar.current.isDateInToday($0.fecha) }
    }

    private var minutosEnFoco: Int {
        Int((hechasHoy.compactMap(\.valor).reduce(0, +) / 60).rounded())
    }

    /// La tarea que toca ahora: la que ya está en curso, o la que elige la energía.
    private var eleccion: Eleccion {
        if let id = enCurso, let tarea = pendientes.first(where: { $0.persistentModelID == id }) {
            return .tarea(tarea)
        }
        return MotorDeEnergia.elegir(pendientes: pendientes, puntaje: puntaje, eventos: eventos,
                                     quiereAlgoIgual: quiereAlgoIgual)
    }

    private var idPropuesta: PersistentIdentifier? {
        if case .tarea(let tarea) = eleccion { return tarea.persistentModelID }
        return nil
    }

    // MARK: Agregar

    private var agregar: some View {
        VStack(spacing: 14) {
            Text(escuchando ? "Te escucho…" : "¿Qué quieres hacer?")
                .font(.zenoTitulo(.title2))
                .luminoso()
            campo($frase, sugerencia: "Una sola frase")
            PlanDeTareaView(plan: $plan)
                .padding(.horizontal, 28)
                .onChange(of: plan.conFecha) { _, si in if si { escribiendo = false } }
            HStack(spacing: 12) {
                botonChico("Cancelar", fuerte: false) { cerrarAgregar() }
                botonChico("Guardar", fuerte: true) { guardarFrase() }
                    .disabled(limpio(frase).isEmpty)
            }
            Text(dictado.aviso ?? Idioma.texto("También puedes mantener presionada a Lumi y hablar."))
                .font(.zenoTexto(.footnote))
                .multilineTextAlignment(.center)
                .opacity(0.6)
                .padding(.horizontal, 32)
        }
    }

    private var preguntaDelPrimerPaso: some View {
        VStack(spacing: 14) {
            Text("¿Cuál es el primer paso de dos minutos?")
                .font(.zenoTitulo(.title3))
                .luminoso()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            campo($primerPaso, sugerencia: "Algo muy pequeño")
            HStack(spacing: 12) {
                botonChico("Saltar", fuerte: false) { guardarTarea(conPaso: false) }
                botonChico("Listo", fuerte: true) { guardarTarea(conPaso: true) }
                    .disabled(limpio(primerPaso).isEmpty)
            }
            Text(verbatim: limpio(frase))
                .font(.zenoTexto(.footnote))
                .opacity(0.55)
                .padding(.horizontal, 32)
        }
    }

    private func campo(_ texto: Binding<String>, sugerencia: LocalizedStringKey) -> some View {
        TextField("", text: texto, prompt: Text(sugerencia).foregroundStyle(.white.opacity(0.35)), axis: .vertical)
            .font(.zenoTitulo(.title3, .regular))
            .luminoso()
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
            .cristal(radio: 20)
            .padding(.horizontal, 28)
    }

    @ViewBuilder
    private func botonChico(_ titulo: LocalizedStringKey, fuerte: Bool, accion: @escaping () -> Void) -> some View {
        if fuerte {
            BotonZeno(titulo, compacto: true, accion: accion)
        } else {
            Button(action: accion) {
                Text(titulo)
                    .font(.zenoTexto(.body, .medium))
                    .padding(.vertical, 11)
                    .padding(.horizontal, 26)
                    .cristal()
            }
            .buttonStyle(EstiloPresion())
        }
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
            withAnimation(Ritmo.contenido) { modo = .agregar }
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
        withAnimation(Ritmo.contenido) { modo = .agregar }
        enfocarPronto()
    }

    /// El campo nuevo tarda un instante en existir; el teclado se le da cuando ya está en pantalla.
    private func enfocarPronto() {
        escribiendo = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if modo != .ver { escribiendo = true }
        }
    }

    private func cerrarAgregar() {
        toques += 1
        escribiendo = false
        withAnimation(Ritmo.contenido) { modo = .ver }
    }

    private func guardarFrase() {
        guard !limpio(frase).isEmpty else { return }
        toques += 1
        if ClasificadorDeTamano.tamano(de: frase) == .grande {
            // Tarea grande: Lumi pregunta por el primer paso.
            primerPaso = ""
            withAnimation(Ritmo.contenido) { modo = .primerPaso }
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
        plan.aplicar(a: tarea)
        plan = BorradorDePlan()
        Task { await AvisosDeTareas.sincronizar(contexto) }
        toques += 1
        escribiendo = false
        frase = ""
        primerPaso = ""
        withAnimation(Ritmo.contenido) { modo = .ver }
    }

    /// Guarda un evento en el historial. La tarea se enlaza después de insertar, para que siempre quede guardada.
    private func registrar(_ tipo: TipoDeEvento, valor: Double? = nil, tarea: Tarea) {
        let evento = EventoDeEnergia(tipo: tipo, valor: valor)
        contexto.insert(evento)
        evento.tarea = tarea
        evento.tamanoCrudo = tarea.tamanoCrudo
    }

    private func empezar(_ tarea: Tarea) {
        toques += 1
        registrar(.tareaEmpezada, tarea: tarea)
        withAnimation(.easeInOut(duration: 0.4)) { tarea.empezadaEn = .now }
    }

    private func terminar(_ tarea: Tarea) {
        toques += 1
        // Cuánto tardó: sirve para comparar con su propio promedio.
        let segundos = tarea.empezadaEn.map { Date.now.timeIntervalSince($0) }
        let celebracion = Celebracion.para(tarea, eventos: eventos, puntaje: puntaje)
        registrar(.tareaTerminada, valor: segundos, tarea: tarea)
        alTerminar(celebracion)
        // La tarea se va despacio, mientras Lumi celebra.
        withAnimation(.easeInOut(duration: 0.8).delay(0.4)) {
            tarea.terminadaEn = .now
            quiereAlgoIgual = false
        }
        Task { await AvisosDeTareas.sincronizar(contexto) }
    }

    /// "Ahora no" nunca es un fracaso: la app aprende que esta hora no era, y lo intenta más tarde.
    private func ahoraNo(_ tarea: Tarea) {
        toques += 1
        registrar(.ahoraNo, tarea: tarea)
        withAnimation(.easeInOut(duration: 0.4)) { tarea.empezadaEn = nil }
    }
}

/// Lo pendiente, sin fechas vencidas, sin rojo y sin contadores.
struct MisTareasView: View {
    /// Dónde empieza el contenido, debajo de Lumi. Lo de encima se funde con el cielo.
    var arriba: CGFloat = 0
    @Environment(\.modelContext) private var contexto
    @Query(filter: #Predicate<Tarea> { $0.terminadaEn == nil }, sort: \Tarea.creadaEn)
    private var pendientes: [Tarea]
    @State private var marcando: Set<PersistentIdentifier> = []
    /// La tarea que se está editando: la página cambia a su editor, dentro del mismo universo.
    @State private var editando: Tarea?

    var body: some View {
        ScrollView {
            if let tarea = editando {
                EditorDeTarea(tarea: tarea) {
                    withAnimation(Ritmo.contenido) { editando = nil }
                }
                .padding(.horizontal, 20)
                .padding(.top, arriba + 4)
                .padding(.bottom, 120)
                .informaDesplazamiento()
                .transition(.desenfoque)
            } else {
                lista
                    .transition(.desenfoque)
            }
        }
        .coordinateSpace(name: "pagina")
        .bordesFundidos(arriba: arriba)
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .foregroundStyle(Color.marfil)
        .onAppear { Desplazamiento.compartido.valor = 0 }
    }

    private var lista: some View {
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 6) {
                        Etiqueta("Pendiente")
                        Text("Mis tareas")
                            .font(.zenoTitulo(.largeTitle))
                            .luminoso()
                    }
                    Spacer()
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 14)

                if pendientes.isEmpty {
                    Text("Nada pendiente.")
                        .font(.zenoTitulo(.title3))
                        .luminoso()
                        .padding(.top, 120)
                } else {
                    VStack(spacing: 10) {
                        ForEach(pendientes) { tarea in fila(tarea) }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, arriba + 4)
            .padding(.bottom, 120)
            .informaDesplazamiento()
    }

    private func fila(_ tarea: Tarea) -> some View {
        let hecha = marcando.contains(tarea.persistentModelID)
        return HStack(alignment: .center, spacing: 14) {
            Button {
                // Se enciende un instante en oro antes de irse.
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { _ = marcando.insert(tarea.persistentModelID) }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                    let evento = EventoDeEnergia(tipo: .tareaTerminada)
                    contexto.insert(evento)
                    evento.tarea = tarea
                    evento.tamanoCrudo = tarea.tamanoCrudo
                    withAnimation(.easeInOut(duration: 0.4)) { tarea.terminadaEn = .now }
                    Task { await AvisosDeTareas.sincronizar(contexto) }
                }
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(Color.oroZeno.opacity(hecha ? 0 : 0.6), lineWidth: 1.4)
                    Circle()
                        .fill(Color.oroZeno)
                        .shadow(color: Color.oroZeno.opacity(0.8), radius: 8)
                        .scaleEffect(hecha ? 1 : 0.01)
                        .opacity(hecha ? 1 : 0)
                }
                .frame(width: 24, height: 24)
                .contentShape(Rectangle().inset(by: -10))
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.success, trigger: hecha)
            .accessibilityLabel(Text("Marcar como hecha"))

            VStack(alignment: .leading, spacing: 4) {
                Text(tarea.titulo)
                    .font(.zenoTitulo(.body, .regular))
                if let paso = tarea.primerPaso {
                    Text("Primer paso: \(paso)")
                        .font(.zenoTexto(.footnote))
                        .opacity(0.6)
                }
                EtiquetaDePlan(tarea: tarea)
            }
            Spacer(minLength: 0)
        }
        // Tocar la tarea la abre para editarla (día, hora, aviso).
        .contentShape(Rectangle())
        .onTapGesture { withAnimation(Ritmo.contenido) { editando = tarea } }
        .accessibilityAction(named: Text("Editar")) { editando = tarea }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .cristal(radio: 20)
        .opacity(hecha ? 0.55 : 1)
        .contextMenu {
            Button("Editar") { withAnimation(Ritmo.contenido) { editando = tarea } }
            Button("Borrar", role: .destructive) {
                withAnimation { contexto.delete(tarea) }
                Task { await AvisosDeTareas.sincronizar(contexto) }
            }
        }
    }
}

// MARK: - Titular y campo rápido

/// Titular grande de revista: la última palabra va en cursiva dorada.
/// El texto lo escribe la persona, así que nunca pasa por el catálogo de traducciones.
struct Titular: View {
    let texto: String
    var tamano: Font.TextStyle = .largeTitle

    var body: some View {
        partes
            .font(.zenoTitulo(tamano, .light))
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .minimumScaleFactor(0.7)
            .shadow(color: .black.opacity(0.5), radius: 10, y: 2)
            .shadow(color: Color.oroZeno.opacity(0.22), radius: 20)
            .accessibilityLabel(Text(verbatim: texto))
    }

    private var partes: Text {
        let (inicio, ultima, cierre) = Self.dividir(texto)
        let claro = Text(verbatim: inicio).foregroundStyle(Color.marfil)
        let oro = Text(verbatim: ultima)
            .font(.zenoTitulo(tamano, .regular, cursiva: true))
            .foregroundStyle(Color.oroZeno)
        return claro + oro + Text(verbatim: cierre).foregroundStyle(Color.marfil)
    }

    /// Separa "Ordenar el escritorio." en ("Ordenar el ", "escritorio", ".").
    /// Con una sola palabra, toda la palabra va dorada.
    static func dividir(_ texto: String) -> (String, String, String) {
        let limpio = texto.trimmingCharacters(in: .whitespacesAndNewlines)
        var cuerpo = Substring(limpio)
        var cierre = ""
        while let ultimo = cuerpo.last, ultimo.isPunctuation || ultimo.isSymbol {
            cierre = String(ultimo) + cierre
            cuerpo = cuerpo.dropLast()
        }
        guard let espacio = cuerpo.lastIndex(where: \.isWhitespace) else {
            return ("", String(cuerpo), cierre)
        }
        let siguiente = cuerpo.index(after: espacio)
        return (String(cuerpo[..<siguiente]), String(cuerpo[siguiente...]), cierre)
    }
}

/// Una píldora de cristal que parece un campo: al tocarla se abre la escritura bajo Lumi.
struct CampoRapido: View {
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            HStack(spacing: 12) {
                Text("Escribe una tarea…")
                    .font(.zenoTexto(.body))
                    .foregroundStyle(Color.marfil.opacity(0.55))
                Spacer(minLength: 0)
                ZStack {
                    // Discreta a propósito: lo único hecho de luz en Hoy es el botón principal.
                    Circle().strokeBorder(Color.oroZeno.opacity(0.45), lineWidth: 1)
                    FlechaDibujada()
                        .stroke(Color.oroZeno,
                                style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                        .frame(width: 14, height: 12)
                }
                .frame(width: 34, height: 34)
            }
            .padding(.leading, 20)
            .padding(.trailing, 7)
            .padding(.vertical, 7)
            .cristal()
        }
        .buttonStyle(EstiloPresion())
        .accessibilityLabel(Text("Escribe una tarea"))
    }
}

/// Flecha hacia la derecha, dibujada a mano (sin símbolos de sistema).
struct FlechaDibujada: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        p.move(to: CGPoint(x: r.maxX - r.height * 0.5, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        p.addLine(to: CGPoint(x: r.maxX - r.height * 0.5, y: r.maxY))
        return p
    }
}

/// La tarea del momento como control: tocar empieza; mantener presionada termina.
/// Terminar pide un gesto deliberado porque no tiene vuelta atrás.
private struct TareaTocable: View {
    let tarea: Tarea
    let enCurso: Bool
    let alEmpezar: () -> Void
    let alTerminar: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    @State private var respira = false
    @State private var presionando = false

    var body: some View {
        VStack(spacing: 8) {
            Titular(texto: tarea.textoVisible)
            if tarea.primerPaso != nil {
                // Se muestra el primer paso; la tarea grande queda como contexto.
                Text("Primer paso de: \(tarea.titulo)")
                    .font(.zenoTexto(.footnote))
                    .multilineTextAlignment(.center)
                    .opacity(0.6)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 12)
        // Sin empezar, la tarea respira una luz dorada: "empieza". Al mantenerla, se enciende.
        // El resplandor es una capa fija; solo cambia su opacidad (barato para la GPU).
        .background {
            Titular(texto: tarea.textoVisible)
                .padding(.horizontal, 32)
                .colorMultiply(.oroZeno)
                .blur(radius: 18)
                .opacity(presionando ? 0.95 : (!enCurso && respira ? 0.6 : 0.15))
                .accessibilityHidden(true)
        }
        .scaleEffect(presionando ? 1.04 : 1)
        .contentShape(Rectangle())
        .onTapGesture { if !enCurso { alEmpezar() } }
        .onLongPressGesture(minimumDuration: 0.7, pressing: { ahora in
            guard enCurso else { return }
            withAnimation(.easeInOut(duration: ahora ? 0.7 : 0.3)) { presionando = ahora }
        }, perform: {
            if enCurso { alTerminar() }
        })
        .sensoryFeedback(.selection, trigger: presionando) { _, ahora in ahora }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(enCurso ? Text("Mantén presionado para marcarla como terminada")
                                   : Text("Toca para empezar"))
        .accessibilityAction { if !enCurso { alEmpezar() } }
        .accessibilityAction(named: Text("Terminé")) { if enCurso { alTerminar() } }
        .onAppear {
            guard !reducirMovimiento else { return }
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) { respira = true }
        }
    }
}
