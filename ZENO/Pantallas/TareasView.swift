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
        // Una tarjeta ancha con lo de ahora (la única acción), y debajo dos tarjetas medianas con datos.
        VStack(alignment: .leading, spacing: 14) {
            tarjetaDeAhora
                .aparece(1)

            if mostrarCampoRapido {
                CampoRapido { abrirAgregar() }
                    .aparece(2)
            }

            HStack(alignment: .top, spacing: 12) {
                tarjetaDelDia
                tarjetaDeMejorHora
            }
            .fixedSize(horizontal: false, vertical: true)
            .aparece(3)

            if let aviso = dictado.aviso {
                Text(aviso)
                    .font(.zenoTexto(.footnote))
                    .foregroundStyle(Lujo.marfilSecundario)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 22)
        Spacer()
            .frame(minHeight: 96)      // deja sitio a la barra
    }

    /// La tarjeta ancha: la tarea del momento (tocar empieza, mantener termina) o el estado del día.
    @ViewBuilder
    private var tarjetaDeAhora: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch eleccion {
            case .tarea(let tarea):
                let enMarcha = enCurso == tarea.persistentModelID
                HStack {
                    EtiquetaLujo(enRacha && enCurso == nil ? "Vas en racha · ¿una más?"
                                 : (tarea.primerPaso != nil ? "Primer paso" : (enCurso == nil ? "Ahora" : "En curso")))
                    Spacer()
                    if let fecha = tarea.fechaPlaneada, Calendar.current.isDateInToday(fecha) {
                        Text(fecha, format: .dateTime.hour().minute())
                            .font(.zenoTexto(.caption, .medium))
                            .foregroundStyle(Lujo.oro.opacity(0.85))
                    }
                }
                // Sin botón: la tarea misma es el control (decisión de Diaz).
                TareaTocable(tarea: tarea, enCurso: enMarcha,
                             alEmpezar: { empezar(tarea) },
                             alTerminar: { terminar(tarea) })
                    .id(tarea.persistentModelID)
                    .transition(.desenfoque)
                SeparadorLujo()
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(enMarcha ? "Mantén presionada la tarea cuando termines" : "Toca la tarea para empezar")
                            .font(.zenoTexto(.caption))
                            .foregroundStyle(Lujo.marfilSecundario)
                            .contentTransition(.opacity)
                        // Lo aprendido, dicho en voz baja: cuánto suele tomarle de verdad algo así.
                        if !enMarcha, tarea.primerPaso == nil,
                           let minutos = Aprendizaje.minutosReales(tarea.tamano, eventos: eventos) {
                            Text("Algo así suele tomarte unos \(Int(minutos.rounded())) min.")
                                .font(.zenoTexto(.caption))
                                .foregroundStyle(Lujo.oro.opacity(0.8))
                        }
                    }
                    .animation(Lujo.curva(), value: enMarcha)
                    Spacer(minLength: 8)
                    BotonTerciarioLujo(titulo: enMarcha ? "Dejarla para después" : "Ahora no") { ahoraNo(tarea) }
                        .padding(.trailing, -12)
                }

            case .descanso:
                EtiquetaLujo("Descanso")
                Titular(texto: Idioma.texto("Hoy descansa, mañana atacamos"), tamano: .title2, alineacion: .leading)
                SeparadorLujo()
                HStack {
                    Text("Tu energía está baja, y está bien.")
                        .font(.zenoTexto(.caption))
                        .foregroundStyle(Lujo.marfilSecundario)
                    Spacer(minLength: 8)
                    BotonTerciarioLujo(titulo: "Quiero hacer algo igual") {
                        toques += 1
                        withAnimation(Lujo.curva()) { quiereAlgoIgual = true }
                    }
                    .padding(.trailing, -12)
                }

            case .masTarde:
                EtiquetaLujo("Ahora")
                Text("Por ahora, nada")
                    .font(.zenoTitulo(.title2))
                    .foregroundStyle(Lujo.marfil)
                Text(vuelveA.map { Idioma.texto("Vuelvo a proponerte algo a las \($0.formatted(date: .omitted, time: .shortened)).") }
                     ?? Idioma.texto("Lo intentamos más tarde."))
                    .font(.zenoTexto(.caption))
                    .foregroundStyle(Lujo.marfilSecundario)

            case .nadaPendiente:
                EtiquetaLujo("Ahora")
                Titular(texto: Idioma.texto("No tienes nada pendiente"), tamano: .title2, alineacion: .leading)
                Text("Cuando quieras, agrega una sola cosa.")
                    .font(.zenoTexto(.caption))
                    .foregroundStyle(Lujo.marfilSecundario)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tarjetaLujo(radio: 24)
    }

    /// Mediana izquierda: lo hecho hoy. Solo progreso; sin ceros que parezcan deuda.
    private var tarjetaDelDia: some View {
        VStack(alignment: .leading, spacing: 8) {
            EtiquetaLujo("Hoy")
            if hechasHoy.isEmpty {
                Text("Lo pequeño suma.")
                    .font(.zenoTitulo(.title3, .light))
                    .foregroundStyle(Lujo.marfil)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("\(hechasHoy.count)")
                    .font(.zenoTitulo(.largeTitle, .light))
                    .foregroundStyle(Lujo.marfil)
                    .contentTransition(.numericText())
                Text("Hechas · \(minutosEnFoco)′ en foco")
                    .font(.zenoTexto(.caption))
                    .foregroundStyle(Lujo.marfilSecundario)
                    .contentTransition(.numericText())
            }
            Spacer(minLength: 0)
            LineaDeLuz(cantidad: Double(hechasHoy.count) / 4)
                .frame(width: 58, height: 6)
                .accessibilityHidden(true)
        }
        .animation(Lujo.curva(), value: hechasHoy.count)
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
        .tarjetaLujo()
        .accessibilityElement(children: .combine)
    }

    /// Mediana derecha: la mejor hora, aprendida de la persona.
    private var tarjetaDeMejorHora: some View {
        VStack(alignment: .leading, spacing: 8) {
            EtiquetaLujo("Tu mejor hora")
            Text(verbatim: "\(mejorHora):00")
                .font(.zenoTitulo(.largeTitle, .light))
                .foregroundStyle(Lujo.marfil)
                .contentTransition(.numericText())
            Spacer(minLength: 0)
            PuntoDelDia(hora: mejorHora)
                .frame(height: 6)
                .accessibilityHidden(true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
        .tarjetaLujo()
        .accessibilityElement(children: .combine)
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
            // Los botones quedan siempre a la vista, aunque el teclado esté abierto.
            // El reloj abre el día y la hora (opcional): se baja el teclado y Lumi sube.
            HStack(spacing: 12) {
                botonChico("Cancelar", fuerte: false) { cerrarAgregar() }
                Button {
                    // El día y la hora se eligen en una hoja: Lumi no se mueve y el teclado se baja.
                    escribiendo = false
                    let enlace = $plan
                    Hojas.compartidas.mostrar { HojaDePlan(plan: enlace) }
                } label: {
                    IconoReloj(activo: plan.conFecha)
                        .frame(width: 44, height: 44)
                        .cristal(activo: plan.conFecha)
                }
                .buttonStyle(EstiloPresion())
                .accessibilityLabel(Text("Día y hora"))
                botonChico("Guardar", fuerte: true) { guardarFrase() }
                    .disabled(limpio(frase).isEmpty)
            }
            if plan.conFecha {
                EtiquetaDePlanBorrador(plan: plan)
                    .transition(.opacity)
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
        plan = BorradorDePlan()
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
        plan = BorradorDePlan()
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

// MARK: - Titular y campo rápido

/// Titular grande de revista: la última palabra va en cursiva dorada.
/// El texto lo escribe la persona, así que nunca pasa por el catálogo de traducciones.
struct Titular: View {
    let texto: String
    var tamano: Font.TextStyle = .largeTitle
    var alineacion: TextAlignment = .center

    var body: some View {
        partes
            .font(.zenoTitulo(tamano, .light))
            .multilineTextAlignment(alineacion)
            .frame(maxWidth: .infinity, alignment: alineacion == .leading ? .leading : .center)
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
            .foregroundStyle(Lujo.oro)
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
    @State private var toques = 0

    var body: some View {
        Button {
            toques += 1
            accion()
        } label: {
            HStack(spacing: 12) {
                Text("Escribe una tarea…")
                    .font(.zenoTexto(.callout))
                    .foregroundStyle(Lujo.marfil.opacity(0.5))
                Spacer(minLength: 0)
                IconoFino(icono: .mas, color: Lujo.oro, tamano: 16)
                    .frame(width: 32, height: 32)
                    .overlay(Circle().strokeBorder(Lujo.oro.opacity(0.4), lineWidth: 0.75))
            }
            .padding(.leading, 18)
            .padding(.trailing, 8)
            .frame(height: 50)
            .background(RoundedRectangle(cornerRadius: Lujo.radioBoton, style: .continuous).fill(Lujo.marfil.opacity(0.03)))
            .cantoPulido(radio: Lujo.radioBoton)
            .contentShape(Rectangle())
        }
        .buttonStyle(EstiloLujo())
        .sensoryFeedback(.impact(weight: .light, intensity: 0.45), trigger: toques)
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
        VStack(alignment: .leading, spacing: 6) {
            Titular(texto: tarea.textoVisible, tamano: .largeTitle, alineacion: .leading)
            if tarea.primerPaso != nil {
                // Se muestra el primer paso; la tarea grande queda como contexto.
                Text("Primer paso de: \(tarea.titulo)")
                    .font(.zenoTexto(.footnote))
                    .foregroundStyle(Lujo.marfilSecundario)
            }
        }
        .padding(.vertical, 4)
        // Sin empezar, la tarea respira una luz dorada: "empieza". Al mantenerla, se enciende.
        // El resplandor es una capa fija; solo cambia su opacidad (barato para la GPU).
        .background {
            Titular(texto: tarea.textoVisible, tamano: .largeTitle, alineacion: .leading)
                .colorMultiply(Lujo.oro)
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
