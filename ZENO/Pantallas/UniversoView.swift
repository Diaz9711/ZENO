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
    @Query(sort: \EventoDeEnergia.fecha) private var eventos: [EventoDeEnergia]
    @Query private var tareas: [Tarea]

    @State private var paso = PasoDeRegistro.bienvenida
    @State private var borrador = BorradorDeRegistro()
    @State private var lumiNacida = false
    @State private var nacimientos = 0
    @State private var momento = Momento.tarea   // al abrir se va directo a Hoy (decisión de Diaz)
    @State private var visita = 0            // cambia cada vez que se abre la app
    @State private var estuvoEnFondo = false
    @State private var mostrarLaboratorio = false
    @State private var pagina = Pagina.hoy
    @State private var sentido: CGFloat = 1   // hacia dónde se mueve el cambio de página
    @State private var viajes = 0             // cada cambio de página: Lumi toma impulso
    @State private var pedirAgregar = 0
    @State private var editando = false
    @AppStorage("modoPrueba") private var modoPrueba = false
    @State private var escuchando = false    // Lumi está oyendo una tarea dictada
    @State private var ahora = Date()        // se refresca cada pocos minutos
    @State private var abiertaDesde = Date()
    @State private var energiaDePrueba: Double?   // solo para probar (DEBUG)
    @State private var celebracion = Celebracion()
    @State private var celebraciones = 0
    @State private var vueltas = 0.0          // giros lentos de Lumi (tres tareas seguidas)
    @AppStorage("diaCalido") private var diaCalido = ""   // terminó algo con energía baja
    @State private var llegada = false        // al abrir, el universo se acerca
    @State private var presentando = true     // al abrir: la presentación corta de ZENO
    @State private var desplazamiento = DesplazamientoDePagina()   // lo que se desliza en Tareas y Ajustes

    /// Solo para elegir el botón (se abre con el argumento -galeriaBotones YES).
    private static var verGaleria: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: "galeriaBotones")
        #else
        false
        #endif
    }

    /// El cielo antes de que exista la persona: tranquilo, sin dueño todavía.
    private static let semillaNeutra = Semilla(nombre: "zeno", anio: 2026, mes: 1, dia: 1)

    var body: some View {
        let persona = personas.first
        let enRegistro = persona == nil
        let semilla = persona?.semilla ?? (paso.yaNacio ? borrador.semilla : Self.semillaNeutra)
        let apariencia = AparienciaLumi(semilla: semilla)
        let forma = persona?.formaDeLumi ?? borrador.forma
        // Al abrir, Lumi aún no está: nace del sol de la presentación cuando esta termina.
        let hayLumi = (persona != nil && !presentando) || lumiNacida
        let viajando = (enRegistro || presentando) && !llegada
        // El puntaje de energía real: cronotipo + comportamiento en la app.
        let puntaje = energiaDePrueba ?? persona.map { MotorDeEnergia.puntaje(persona: $0, eventos: eventos, ahora: ahora) } ?? 72
        let energia = hayLumi ? puntaje / 100 : 0.30

        // Dónde está Lumi: en el centro durante la presencia, arriba cuando llega la tarea.
        let enTarea = persona != nil && momento == .tarea
        let enPresencia = persona != nil && momento == .presencia
        // En Tareas y Ajustes, Lumi viaja arriba y se hace pequeña: acompaña sin estorbar.
        let enOtraPagina = enTarea && pagina != .hoy
        let centro = UnitPoint(x: 0.5, y: enOtraPagina ? 0.115 : (enTarea ? 0.245 : (enPresencia ? 0.34 : 0.33)))
        let tamano = (enOtraPagina ? 0.38 : (enTarea ? 0.80 : 1.0)) * (escuchando ? 1.12 : 1.0)
        let tareaEnCurso = enTarea ? tareas.first(where: \.estaEnCurso) : nil
        let calidez = min(1, Cielo.calidez(hora: Cielo.horaActual()) + (diaCalido == Self.hoyTexto ? 0.28 : 0))

        ZStack {
            Color("FondoArranque").ignoresSafeArea()

            GeometryReader { geo in
                ZStack {
                    NebulosaView(apariencia: apariencia,
                                 energia: energia,
                                 calidez: calidez,
                                 centro: centro)
                        .id(semilla)
                        .transition(.opacity)
                        // Bienvenida: la cámara viaja hacia el cielo, que gira apenas al llegar.
                        .scaleEffect(viajando ? 1.55 : 1)
                        .rotationEffect(.degrees(viajando ? -6 : 0))

                    let anchoLumi = min(geo.size.width, 430) * 0.98
                    LumiQueSeRetira(desplazamiento: desplazamiento, activo: enOtraPagina) {
                        LumiView(apariencia: apariencia, energia: energia, forma: forma, destello: destelloDeHoy)
                            .frame(width: anchoLumi)
                    }
                        // Al terminar una tarea: inhala, se encoge un instante y suelta la onda.
                        .keyframeAnimator(initialValue: 1.0, trigger: celebraciones) { vista, escala in
                            vista.scaleEffect(escala)
                        } keyframes: { _ in
                            KeyframeTrack {
                                CubicKeyframe(0.88, duration: 0.35)
                                SpringKeyframe(1.08, duration: 0.45, spring: .bouncy)
                                SpringKeyframe(1.0, duration: 0.7, spring: .smooth)
                            }
                        }
                        // Al cambiar de página, Lumi se estira al arrancar y se asienta al llegar.
                        .keyframeAnimator(initialValue: CGSize(width: 1, height: 1), trigger: viajes) { vista, forma in
                            vista.scaleEffect(x: forma.width, y: forma.height)
                        } keyframes: { _ in
                            KeyframeTrack {
                                CubicKeyframe(CGSize(width: 0.94, height: 1.09), duration: 0.14)
                                SpringKeyframe(CGSize(width: 1.05, height: 0.96), duration: 0.24, spring: .bouncy)
                                SpringKeyframe(CGSize(width: 1, height: 1), duration: 0.4, spring: .smooth)
                            }
                        }
                        .rotationEffect(.degrees(vueltas))
                        .scaleEffect(hayLumi ? tamano : 0.04)
                        .opacity(hayLumi ? 1 : 0)
                        .position(x: geo.size.width * centro.x,
                                  y: geo.size.height * centro.y)

                    if let tarea = tareaEnCurso, let inicio = tarea.empezadaEn {
                        AnilloDeTiempoView(inicio: inicio, minutos: tarea.minutosPrevistos)
                            .frame(width: anchoLumi * tamano * 0.50, height: anchoLumi * tamano * 0.50)
                            .position(x: geo.size.width * centro.x, y: geo.size.height * centro.y)
                            .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    }

                    OndaDeLuzView(centro: CGPoint(x: geo.size.width * centro.x, y: geo.size.height * centro.y),
                                  grande: celebracion.grande,
                                  numero: celebraciones)
                }
                .animation(.easeInOut(duration: 0.6), value: tareaEnCurso?.persistentModelID)
                // El cielo de la persona aparece despacio, como si se condensara.
                .animation(.easeInOut(duration: 2.6), value: semilla)
                // La energía nunca salta: Lumi y el cielo cambian despacio.
                .animation(.easeInOut(duration: 1.8), value: energia)
            }
            .ignoresSafeArea()
            .ignoresSafeArea(.keyboard)

            // Al llegar, el espacio está casi a oscuras y se va aclarando.
            if enRegistro || presentando {
                Color(red: 0.01, green: 0.015, blue: 0.05)
                    .opacity(llegada ? 0 : 0.92)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // Un velo suave bajo Lumi: el texto se lee nítido sin apagar el cielo.
            LinearGradient(stops: [.init(color: .black.opacity(enOtraPagina ? 0.22 : 0), location: 0.16),
                                   .init(color: .black.opacity(enOtraPagina ? 0.40 : 0.30), location: 0.62),
                                   .init(color: .black.opacity(0.42), location: 1)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            if Self.verGaleria {
                #if DEBUG
                GaleriaDeLumi(apariencia: apariencia)
                #endif
            } else if let persona {
                if presentando {
                    // Cada vez que se abre: el universo, el sol y ZENO. Sin botón; sigue sola.
                    BienvenidaView(conBoton: false) {
                        withAnimation(movimientoDeLumi) { presentando = false }
                    }
                    .transition(.desenfoque)
                } else {
                    contenido(de: persona, puntaje: puntaje)
                }
            } else {
                RegistroView(paso: $paso, borrador: $borrador, lumiNacida: lumiNacida, alTerminar: terminarRegistro)
                    .transition(.opacity)
            }
        }
        .environment(\.desplazamientoDePagina, desplazamiento)
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
                momento = .tarea
                pagina = .hoy
                withAnimation(.easeInOut(duration: 1.2)) { lumiNacida = false }
            }
        }
        .onChange(of: fase) { _, nueva in
            // Cada vez que la persona vuelve a la app, empieza en Hoy.
            if nueva == .background {
                estuvoEnFondo = true
                registrarCierre()
                if let persona = personas.first {
                    Task { await Avisos.alSalir(persona, eventos: eventos) }
                }
            } else if nueva == .active && estuvoEnFondo {
                estuvoEnFondo = false
                visita += 1
                registrarApertura()
                // Al volver se entra directo a Hoy, sin fecha ni frase.
                withAnimation(movimientoDeLumi) { pagina = .hoy }
            }
        }
        .task {
            if reducirMovimiento {
                llegada = true
                presentando = false
            } else {
                withAnimation(.easeOut(duration: 5.0)) { llegada = true }
            }
            #if DEBUG
            DatosDeEjemplo.cargarSiHaceFalta(en: contexto, hayPersona: !personas.isEmpty)
            #endif
            registrarApertura()
        }
        .onReceive(Timer.publish(every: 300, on: .main, in: .common).autoconnect()) { ahora = $0 }
        .fullScreenCover(isPresented: $mostrarLaboratorio) {
            LaboratorioView()
                .preferredColorScheme(.dark)
        }
    }

    /// Lumi se mueve como un objeto físico: resorte con un pequeño rebote al llegar.
    private var movimientoDeLumi: Animation {
        reducirMovimiento ? .easeInOut(duration: 0.4) : .spring(response: 0.7, dampingFraction: 0.74)
    }

    @ViewBuilder
    private func contenido(de persona: Persona, puntaje: Double) -> some View {
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
                .transition(.desenfoque)

            case .tarea:
                // Lumi se dibuja a pantalla completa; aquí se descuenta el margen de arriba.
                let arriba = geo.safeAreaInsets.top
                let altoTotal = geo.size.height + arriba + geo.safeAreaInsets.bottom
                ZStack(alignment: .bottom) {
                    switch pagina {
                    case .hoy:
                        ZStack(alignment: .top) {
                            VStack(spacing: 0) {
                                TareaDelMomentoView(
                                    centroDeLumi: CGPoint(x: geo.size.width / 2, y: altoTotal * 0.245 - arriba),
                                    inicioDelContenido: altoTotal * 0.405 - arriba,
                                    escuchando: $escuchando,
                                    puntaje: puntaje,
                                    eventos: eventos,
                                    alTerminar: celebrar,
                                    mejorHora: MotorDeEnergia.mejorHora(persona: persona, eventos: eventos),
                                    pedirAgregar: pedirAgregar,
                                    editando: $editando)
                            }
                            // Encima y no debajo: si empujan el contenido, la barra se sale de la pantalla.
                            .overlay(alignment: .top) {
                                botonesDePrueba(persona, puntaje: puntaje)
                                    .padding(.top, 96)
                            }
                            EncabezadoDeHoy(nombre: persona.nombre, puntaje: puntaje)
                                .padding(.horizontal, 22)
                                .padding(.top, 6)
                                .aparece(0)
                        }
                        .transition(.pasoDePagina(sentido: sentido))

                    case .tareas:
                        MisTareasView(margenSuperior: altoTotal * 0.185 - arriba)
                            .transition(.pasoDePagina(sentido: sentido))

                    case .ajustes:
                        AjustesView(persona: persona, margenSuperior: altoTotal * 0.185 - arriba)
                            .transition(.pasoDePagina(sentido: sentido))
                    }

                    if !editando {
                        BarraZeno(pagina: Binding(get: { pagina }, set: { ir(a: $0) })) {
                            // El "+" siempre lleva a escribir una tarea en la página de hoy.
                            ir(a: .hoy)
                            pedirAgregar += 1
                        }
                        .padding(.bottom, 4)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.desenfoque)
            }
        }
    }

    /// Cambia de página. Primero se fija el sentido y, un instante después, se mueve:
    /// así la página que sale ya sabe por qué lado irse.
    private func ir(a destino: Pagina) {
        guard destino != pagina else { return }
        sentido = destino.rawValue > pagina.rawValue ? 1 : -1
        DispatchQueue.main.async {
            // La página nueva empieza arriba: Lumi vuelve a su tamaño junto con el cambio.
            withAnimation(.easeOut(duration: 0.3)) { desplazamiento.valor = 0 }
            if !reducirMovimiento { viajes += 1 }
            // Rápido y suave, sin rebote largo: la página llega en menos de medio segundo.
            withAnimation(reducirMovimiento ? .easeInOut(duration: 0.3)
                                            : .spring(response: 0.46, dampingFraction: 0.84)) {
                pagina = destino
                // Si se estaba escribiendo en Hoy, al salir la barra vuelve siempre.
                if destino != .hoy { editando = false }
            }
        }
    }

    // MARK: Celebración

    private static var hoyTexto: String {
        Date.now.formatted(.iso8601.year().month().day())
    }

    /// Lumi queda un poco más brillante el resto del día por cada tarea difícil terminada.
    private var destelloDeHoy: Double {
        let grandesHoy = eventos.filter {
            $0.tipo == .tareaTerminada && Calendar.current.isDateInToday($0.fecha)
                && $0.tarea?.tamano == .grande && $0.tarea?.primerPaso == nil
        }.count
        // Cada tarea terminada hoy suma luz; las difíciles, más. Nunca se resta.
        let hechasHoy = eventos.filter { $0.tipo == .tareaTerminada && Calendar.current.isDateInToday($0.fecha) }.count
        return min(Double(grandesHoy) * 0.5 + Double(hechasHoy) * 0.14, 1)
    }

    private func celebrar(_ nueva: Celebracion) {
        celebracion = nueva
        celebraciones += 1
        Haptica.compartida.onda(grande: nueva.grande)
        if nueva.conEnergiaBaja {
            withAnimation(.easeInOut(duration: 3)) { diaCalido = Self.hoyTexto }
        }
        if nueva.enRacha && !reducirMovimiento {
            // Un giro lento sobre sí misma, después de la onda.
            withAnimation(.easeInOut(duration: 2.8).delay(0.6)) { vueltas += 360 }
        }
    }

    // MARK: Señales de comportamiento

    private func registrarApertura() {
        ahora = .now
        abiertaDesde = .now
        guard let persona = personas.first else { return }
        contexto.insert(EventoDeEnergia(tipo: .abrioLaApp))
        Task { await Avisos.alAbrir(persona, eventos: eventos) }
    }

    /// Abrir y cerrar sin hacer nada también es una señal (sin juicio: solo cuenta para la energía).
    private func registrarCierre() {
        guard !personas.isEmpty else { return }
        let hizoAlgo = eventos.contains {
            $0.fecha >= abiertaDesde && [.tareaEmpezada, .tareaTerminada, .ahoraNo].contains($0.tipo)
        } || tareas.contains { $0.creadaEn >= abiertaDesde }
        if !hizoAlgo {
            contexto.insert(EventoDeEnergia(tipo: .cerroSinHacerNada))
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
        presentando = false
        momento = .tarea
        visita += 1
        withAnimation(.easeInOut(duration: 0.9)) {
            contexto.insert(borrador.comoPersona())
        }
    }

    @ViewBuilder
    private func botonesDePrueba(_ persona: Persona, puntaje: Double) -> some View {
        #if DEBUG
        // Botones temporales para probar (se activan en Ajustes → Modo de prueba).
        if modoPrueba {
        Button(energiaDePrueba == nil ? "Energía \(Int(puntaje)) · real" : "Energía \(Int(puntaje)) · de prueba") {
            // Cada toque cambia: real → alta → media → baja → real.
            switch energiaDePrueba {
            case nil: energiaDePrueba = 85
            case 85: energiaDePrueba = 50
            case 50: energiaDePrueba = 15
            default: energiaDePrueba = nil
            }
        }
        .font(.zenoTexto(.footnote))
        .foregroundStyle(.white.opacity(0.6))
        .padding(.bottom, 6)
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
        .font(.zenoTexto(.footnote))
        .foregroundStyle(.white.opacity(0.6))
        .padding(.bottom, 8)
        }
        Color.clear.frame(height: modoPrueba ? 76 : 0)   // los controles de prueba quedan sobre la barra
        #endif
    }
}

#Preview {
    UniversoView()
        .fontDesign(.rounded)
        .preferredColorScheme(.dark)
        .modelContainer(for: [Persona.self, Tarea.self, EventoDeEnergia.self], inMemory: true)
}

#if DEBUG
/// Solo para comparar: Lumi con energía baja, media y alta, en sus dos formas.
struct GaleriaDeLumi: View {
    let apariencia: AparienciaLumi
    private static let nombres = ["Ana", "Skdn", "Diaz", "Luis", "Mar", "Teo", "Sol", "Iván"]
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
            ForEach(Self.nombres, id: \.self) { n in
                VStack(spacing: 0) {
                    LumiView(apariencia: AparienciaLumi(semilla: Semilla(nombre: n, anio: 1999, mes: 6, dia: 15)),
                             energia: 0.6)
                        .frame(width: 170, height: 170)
                    Text(verbatim: n).font(.zenoTexto(.caption)).foregroundStyle(Color.oroZeno)
                }
            }
        }
        .padding(.top, 50)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.black.opacity(0.25))
    }
}

#endif
