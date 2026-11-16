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
    @Query(sort: \EventoDeEnergia.fecha) private var eventosGuardados: [EventoDeEnergia]
    /// El historial como copia ligera en memoria (ver `Memoria`): rápido de recorrer.
    private var eventos: [Senal] { eventosGuardados.senales }
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
    /// Cada toque a Lumi en Hoy: se hincha un poco y se asienta (Diaz echaba de menos que reaccionara).
    /// Solo la reacción: no activa la voz ni ninguna acción (eso se quitó a su pedido el 14 nov).
    @State private var caricias = 0
    @State private var vueltas = 0.0          // giros lentos de Lumi (tres tareas seguidas)
    @AppStorage("diaCalido") private var diaCalido = ""   // terminó algo con energía baja
    @State private var llegada = false        // al abrir, el universo se acerca
    @State private var presentando = true     // al abrir: la presentación corta de ZENO
    @AppStorage(Sesion.clave) private var sesionAbierta = true
    /// El cielo que eligió la persona en Ajustes (azul de siempre o negro).
    @AppStorage(TonoDeCielo.clave) private var tonoDeCielo = TonoDeCielo.azulado

    /// Solo para elegir el botón (se abre con el argumento -galeriaBotones YES).
    private static var verGaleria: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: "galeriaBotones")
        #else
        false
        #endif
    }

    /// Para elegir el cohete (-galeriaCohetes YES, solo DEBUG).
    private static var verCohetes: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: "galeriaCohetes")
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
        // La presentación y el registro siempre con el cielo azul de siempre; el elegido, ya dentro.
        let tono: TonoDeCielo = persona == nil ? .azulado : tonoDeCielo
        let apariencia = AparienciaLumi(semilla: semilla, cielo: tono)
        let forma = persona?.formaDeLumi ?? borrador.forma
        // Al abrir, Lumi aún no está: nace del sol de la presentación cuando esta termina.
        let hayLumi = (persona != nil && !presentando && sesionAbierta) || lumiNacida
        let viajando = (enRegistro || presentando) && !llegada
        // El puntaje de energía real: cronotipo + comportamiento en la app.
        // El cerebro se calcula una vez y se recuerda hasta que cambie el historial o pase un minuto.
        let cerebro = persona.map { Memoria.compartida.cerebro(persona: $0, senales: eventos, ahora: ahora) }
        let puntaje = energiaDePrueba ?? Pruebas.energia ?? cerebro?.puntaje ?? 72
        let energia = hayLumi ? puntaje / 100 : 0.30

        // Dónde está Lumi: en el centro durante la presencia, arriba cuando llega la tarea.
        let enTarea = persona != nil && momento == .tarea
        let enPresencia = persona != nil && momento == .presencia
        // En Tareas y Ajustes, Lumi viaja arriba y se hace pequeña: acompaña sin estorbar.
        let enOtraPagina = enTarea && pagina != .hoy
        let centro = UnitPoint(x: 0.5, y: enOtraPagina ? 0.115 : (enTarea ? 0.245 : (enPresencia ? 0.34 : 0.33)))
        let tamano = (enOtraPagina ? 0.38 : (enTarea ? 0.80 : 1.0)) * (escuchando ? 1.12 : 1.0)
        let tareaEnCurso = enTarea ? tareas.first(where: \.estaEnCurso) : nil
        // En el cielo negro la mañana no abre tanto el resplandor (se volvería niebla gris).
        let calidez = min(tono == .negro ? 0.45 : 1,
                          Cielo.calidez(hora: Cielo.horaActual()) + (diaCalido == Self.hoyTexto ? 0.28 : 0))

        ZStack {
            (tono == .negro ? Color(red: Double(apariencia.colorFondo.x), green: Double(apariencia.colorFondo.y),
                                    blue: Double(apariencia.colorFondo.z)) : Color("FondoArranque"))
                .ignoresSafeArea()

            GeometryReader { geo in
                ZStack {
                    if !Pruebas.sinCielo {
                    NebulosaView(apariencia: apariencia,
                                 energia: energia,
                                 calidez: calidez,
                                 centro: centro)
                        // El calor del cielo sigue a Lumi con su mismo resorte.
                        .animation(reducirMovimiento ? .easeInOut(duration: 0.5) : Ritmo.lumi, value: pagina)
                        // Al cambiar de cielo en Ajustes, el nuevo aparece fundiéndose sobre el anterior.
                        .id(CieloElegido(semilla: semilla, tono: tono))
                        .transition(.opacity)
                        // Bienvenida: la cámara viaja hacia el cielo, que gira apenas al llegar.
                        .scaleEffect(viajando ? 1.55 : 1)
                        .rotationEffect(.degrees(viajando ? -6 : 0))
                    }

                    // Cada tarea terminada es una estrella nueva en tu cielo (encima de la nebulosa,
                    // sin tocarla). Nace de Lumi. No aparece en la presentación ni en el registro.
                    if let persona, !presentando, sesionAbierta {
                        EstrellasGanadas(hechas: eventos.filter { $0.tipo == .tareaTerminada },
                                         semilla: persona.semilla, origen: centro,
                                         luzMaxima: tono == .negro ? 0.85 : 1)
                            .transition(.opacity)
                    }

                    let anchoLumi = min(geo.size.width, 430) * 0.98
                    RetiradaAlDeslizar(activa: enOtraPagina) {
                    // Se dibuja al tamaño en que se ve (no grande y luego encogida): el mismo dibujo,
                    // con muchos menos píxeles que calcular en cada cuadro cuando Lumi está pequeña.
                    LumiView(apariencia: apariencia, energia: energia, forma: forma, destello: destelloDeHoy)
                        .id(tono)
                        .transition(.opacity)
                        .opacity(Pruebas.sinCielo ? 0 : 1)
                        .frame(width: anchoLumi * tamano)
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
                                CubicKeyframe(CGSize(width: 0.90, height: 1.16), duration: 0.22)
                                SpringKeyframe(CGSize(width: 1.10, height: 0.92), duration: 0.38, spring: .bouncy)
                                SpringKeyframe(CGSize(width: 1, height: 1), duration: 0.6, spring: .smooth)
                            }
                        }
                        // Al tocarla: se hincha un poco, como si respirara hondo, y se asienta. Con Reducir
                        // Movimiento solo vibra.
                        .keyframeAnimator(initialValue: 1.0, trigger: caricias) { vista, escala in
                            vista.scaleEffect(escala)
                        } keyframes: { _ in
                            KeyframeTrack {
                                if reducirMovimiento {
                                    LinearKeyframe(1.0, duration: 0.1)
                                } else {
                                    CubicKeyframe(1.07, duration: 0.22)
                                    SpringKeyframe(0.98, duration: 0.30, spring: .smooth)
                                    SpringKeyframe(1.0, duration: 0.55, spring: .smooth)
                                }
                            }
                        }
                        .rotationEffect(.degrees(vueltas))
                        // Solo el corazón de Lumi recibe el toque, y solo en Hoy.
                        .contentShape(Circle().scale(0.42))
                        .onTapGesture { caricias += 1 }
                        .allowsHitTesting(enTarea && pagina == .hoy && hayLumi && !presentando)
                        .sensoryFeedback(.impact(weight: .light, intensity: 0.6), trigger: caricias)
                        .accessibilityLabel(Text("Lumi"))
                    }
                        .scaleEffect(hayLumi ? 1 : 0.04)
                        .opacity(hayLumi ? 1 : 0)
                        .position(x: geo.size.width * centro.x,
                                  y: geo.size.height * centro.y)
                        // Lumi viaja con su propio resorte, aunque el contenido cambie más rápido.
                        .animation(reducirMovimiento ? .easeInOut(duration: 0.5) : Ritmo.lumi, value: pagina)

                    if let tarea = tareaEnCurso, let inicio = tarea.empezadaEn {
                        AnilloDeTiempoView(inicio: inicio, minutos: Aprendizaje.minutosPrevistos(tarea, eventos: eventos))
                            .frame(width: anchoLumi * tamano * 0.50, height: anchoLumi * tamano * 0.50)
                            .position(x: geo.size.width * centro.x, y: geo.size.height * centro.y)
                            .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    }

                    OndaDeLuzView(centro: CGPoint(x: geo.size.width * centro.x, y: geo.size.height * centro.y),
                                  grande: celebracion.grande,
                                  numero: celebraciones)

                    // Chispa celebra contigo: una vuelta alrededor de Lumi.
                    VueloDeChispa(numero: celebraciones, radio: anchoLumi * tamano * 0.30)
                        .position(x: geo.size.width * centro.x, y: geo.size.height * centro.y)
                }
                .animation(.easeInOut(duration: 0.6), value: tareaEnCurso?.persistentModelID)
                // El cielo de la persona aparece despacio, como si se condensara.
                .animation(.easeInOut(duration: 2.6), value: semilla)
                // La energía nunca salta: Lumi y el cielo cambian despacio.
                .animation(.easeInOut(duration: 1.8), value: energia)
                // Al ganar luz, Lumi se enciende despacio (cuando la estrella nueva ya salió de ella).
                .animation(.easeInOut(duration: 2.4).delay(1.2), value: destelloDeHoy)
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
            } else if Self.verCohetes {
                #if DEBUG
                GaleriaDeCohetes()
                #endif
            } else if UserDefaults.standard.bool(forKey: "galeriaWidget") {
                #if DEBUG
                GaleriaDeWidgets(apariencia: apariencia, forma: forma)
                #endif
            } else if UserDefaults.standard.bool(forKey: "galeriaAnillo") {
                #if DEBUG
                GaleriaDeAnillos()
                #endif
            } else if UserDefaults.standard.bool(forKey: "galeriaLogos") {
                #if DEBUG
                GaleriaDeLogos()
                #endif
            } else if let persona {
                if !sesionAbierta {
                    // Sesión cerrada: el universo, ZENO y el menú de entrada. Todo lo suyo sigue guardado.
                    BienvenidaView(alEmpezar: { abrirSesion() },
                                   alEntrarConApple: { cuenta, _ in
                                       persona.cuentaApple = cuenta
                                       abrirSesion()
                                   },
                                   vuelve: true)
                    .transition(.presentacion)
                } else if presentando {
                    // Cada vez que se abre: el universo, el sol y ZENO. Sin botón; sigue sola.
                    BienvenidaView(conBoton: false) {
                        withAnimation(movimientoDeLumi) { presentando = false }
                    }
                    .transition(.presentacion)
                } else {
                    contenido(de: persona, puntaje: puntaje)
                }
            } else {
                RegistroView(paso: $paso, borrador: $borrador, lumiNacida: lumiNacida, alTerminar: terminarRegistro)
                    .transition(.opacity)
            }
            // Las hojas que suben desde abajo (selectores, confirmaciones): encima de todo.
            CapaDeHojas()
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
                momento = .tarea
                pagina = .hoy
                withAnimation(.easeInOut(duration: 1.2)) { lumiNacida = false }
            }
        }
        .onChange(of: fase) { _, nueva in
            // Cada vez que la persona vuelve a la app, empieza en Hoy.
            if nueva == .background {
                estuvoEnFondo = true
                actualizarWidget(puntaje: puntaje, conRetrato: true)
                registrarCierre()
                if let persona = personas.first, sesionAbierta {
                    Task { await Avisos.alSalir(persona, eventos: eventos) }
                }
            } else if nueva == .active && estuvoEnFondo {
                estuvoEnFondo = false
                actualizarEnVivo()
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
            // Fase IA: si la IA del iPhone está, rellena en segundo plano las frases nuevas de Chispa.
            Task(priority: .background) { await ServicioDeIA.compartido.refrescarFrases() }
            #if DEBUG
            DatosDeEjemplo.cargarSiHaceFalta(en: contexto, hayPersona: !personas.isEmpty)
            DatosDeEjemplo.cargarCielo(en: contexto)
            // Atajos para probar sin tocar: -formaDePrueba 0|1, -paginaInicial 0|1|2, -sinPresentacion YES.
            let ajustes = UserDefaults.standard
            if let forma = ajustes.string(forKey: "formaDePrueba").flatMap(Int.init) { personas.first?.formaDeLumiCruda = forma }
            if let p = ajustes.string(forKey: "paginaInicial").flatMap(Int.init), let destino = Pagina(rawValue: p) { pagina = destino }
            if ajustes.bool(forKey: "sinPresentacion") { presentando = false; llegada = true }
            // -pasoDeRegistro 1…7: abre el registro en ese paso (para ver su diseño sin tocar).
            if personas.isEmpty, let n = ajustes.string(forKey: "pasoDeRegistro").flatMap(Int.init),
               let destino = PasoDeRegistro(rawValue: n) {
                borrador.nombre = "Diaz"
                paso = destino
            }
            // -claveDePrueba xxxxxx: deja guardada esa clave (para probar la entrada).
            if let c = ajustes.string(forKey: "claveDePrueba") { Clave.guardar(c) }
            if Autopiloto.activo { Task { await recorridoDePrueba() } }
            if ajustes.bool(forKey: "sesionCerrada") { sesionAbierta = false }
            // -probarSiri "texto": corre el mismo atajo que usa Siri para agregar una tarea.
            if let frase = ajustes.string(forKey: "probarSiri") {
                let atajo = AgregarTareaIntent()
                atajo.tarea = frase
                _ = try? await atajo.perform()
            }
            #endif
            registrarApertura()
            actualizarWidget(puntaje: puntaje)
            // Si quitó el permiso de Apple desde el iPhone, la sesión se cierra (sus datos se quedan).
            if let persona = personas.first, sesionAbierta,
               !(await Sesion.sigueValida(cuentaApple: persona.cuentaApple)) {
                withAnimation(movimientoDeLumi) { sesionAbierta = false }
            }
        }
        .onReceive(Timer.publish(every: 300, on: .main, in: .common).autoconnect()) {
            ahora = $0
            actualizarWidget(puntaje: puntaje)
        }
        // El anillo en la Isla Dinámica sigue al estado: empezar, terminar, "Ahora no", borrar,
        // borrar todo o cerrar sesión lo abren o lo cierran solos.
        .onChange(of: firmaEnVivo, initial: true) { _, _ in actualizarEnVivo() }
        .onChange(of: persona?.formaDeLumiCruda) { _, _ in actualizarWidget(puntaje: puntaje) }
        // El widget y el anillo abren ZENO en Hoy.
        .onOpenURL { abrir($0) }
        .onChange(of: pagina, initial: true) { _, nueva in if !Autopiloto.activo { Fluidez.marcar("\(nueva)") } }
        // "Escribir una tarea" desde Siri, Atajos o el botón de Acción.
        .onChange(of: PuenteDeAtajos.compartido.pedidosDeEscribir, initial: true) { _, pedidos in
            guard pedidos > 0, !personas.isEmpty else { return }
            PuenteDeAtajos.compartido.pedidosDeEscribir = 0
            abrir(EnlaceZeno.escribir)
        }
        .fullScreenCover(isPresented: $mostrarLaboratorio) {
            LaboratorioView()
                .preferredColorScheme(.dark)
        }
    }

    /// Lumi se mueve como un objeto físico: resorte con un pequeño rebote al llegar.
    private var movimientoDeLumi: Animation {
        reducirMovimiento ? .easeInOut(duration: 0.6) : .spring(response: 1.0, dampingFraction: 0.70)
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
                // En iPhones más bajos que el Pro Max el contenido de Hoy no cabía y empujaba la barra
                // fuera de la pantalla: ahí empieza un poco más arriba (en el Pro Max, igual que siempre).
                let inicioHoy = altoTotal * 0.405
                ZStack(alignment: .bottom) {
                    // La página nunca puede agrandar este espacio: así la barra queda siempre anclada
                    // al fondo de la pantalla, aunque una tarea tenga un título largo (Diaz, 16 nov 2026).
                    Group {
                    switch pagina {
                    case .hoy:
                        ZStack(alignment: .top) {
                            HojaDeFondo()
                                .padding(.top, inicioHoy - arriba - 18)
                                .aparece(1)
                            VStack(spacing: 0) {
                                TareaDelMomentoView(
                                    centroDeLumi: CGPoint(x: geo.size.width / 2, y: altoTotal * 0.245 - arriba),
                                    inicioDelContenido: inicioHoy - arriba,
                                    escuchando: $escuchando,
                                    puntaje: puntaje,
                                    eventos: eventos,
                                    alTerminar: celebrar,
                                    mejorHora: Memoria.compartida.cerebro(persona: persona, senales: eventos, ahora: ahora).mejorHora,
                                    pedirAgregar: pedirAgregar,
                                    compacto: altoTotal < 900,
                                    editando: $editando)
                            }
                            EncabezadoDeHoy(nombre: persona.nombre, puntaje: puntaje)
                                .padding(.horizontal, 22)
                                .padding(.top, 6)
                                .aparece(0)
                        }
                        .transition(.pasoDePagina(sentido: sentido))

                    case .tareas:
                        MisTareasView(arriba: altoTotal * 0.185 - arriba)
                            .transition(.pasoDePagina(sentido: sentido))

                    case .ajustes:
                        AjustesView(persona: persona, eventos: eventos, arriba: altoTotal * 0.185 - arriba)
                            .transition(.pasoDePagina(sentido: sentido))
                    }
                    }
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .top)

                    if !editando {
                        BarraZeno(pagina: Binding(get: { pagina }, set: { ir(a: $0) })) {
                            // El "+" siempre lleva a escribir una tarea en la página de hoy.
                            ir(a: .hoy)
                            pedirAgregar += 1
                        }
                        .padding(.bottom, 4)
                        // Con el teclado abierto (editar una tarea) la barra se queda abajo, no sube encima.
                        .ignoresSafeArea(.keyboard)
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
            if !reducirMovimiento { viajes += 1 }
            withAnimation(reducirMovimiento ? .easeInOut(duration: 0.3) : Ritmo.contenido) {
                pagina = destino
                // Si se estaba escribiendo en Hoy, al salir la barra vuelve siempre.
                if destino != .hoy { editando = false }
            }
        }
    }

    #if DEBUG
    /// El recorrido del autopiloto: cada fase queda marcada en el medidor de fluidez.
    private func recorridoDePrueba() async {
        UIApplication.shared.isIdleTimerDisabled = true
        func espera(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }
        await espera(8)
        Fluidez.marcar("1-hoy-reposo"); await espera(10)
        for i in 0..<8 {
            let destino: Pagina = [.tareas, .ajustes, .hoy, .ajustes][i % 4]
            ir(a: destino)
            Fluidez.marcar("2-cambio-pagina")
            await espera(1.25)
        }
        ir(a: .ajustes); await espera(3)
        Fluidez.marcar("3-ajustes-reposo"); await espera(6)
        Fluidez.marcar("4-ajustes-desliza")
        for _ in 0..<6 { Autopiloto.compartido.desplazar += 1; await espera(1.7) }
        ir(a: .tareas); await espera(3)
        Fluidez.marcar("5-tareas-reposo"); await espera(6)
        Fluidez.marcar("6-tareas-desliza")
        for _ in 0..<6 { Autopiloto.compartido.desplazar += 1; await espera(1.7) }
        ir(a: .hoy); await espera(3)
        Fluidez.marcar("7-hojas")
        for _ in 0..<5 {
            Hojas.compartidas.mostrar { HojaDeAyuda(acciones: []) }
            Fluidez.marcar("7-hojas")
            await espera(1.2)
            Hojas.compartidas.cerrar()
            Fluidez.marcar("7-hojas")
            await espera(1.2)
        }
        Fluidez.marcar("8-fin")
        UIApplication.shared.isIdleTimerDisabled = false
    }
    #endif

    // MARK: Fuera de la app (Isla Dinámica y widget)

    /// La tarea en marcha, si la sesión está abierta.
    private var tareaEnMarcha: Tarea? {
        guard !personas.isEmpty, sesionAbierta else { return nil }
        return tareas.first(where: \.estaEnCurso)
    }

    private var firmaEnVivo: String {
        guard let tarea = tareaEnMarcha, let inicio = tarea.empezadaEn else { return "" }
        return "\(tarea.textoVisible)|\(inicio.timeIntervalSince1970)"
    }

    private func actualizarEnVivo() {
        let tarea = tareaEnMarcha
        let minutos = tarea.map { Aprendizaje.minutosPrevistos($0, eventos: eventos) } ?? 0
        Task { await AnilloEnVivo.sincronizar(titulo: tarea?.textoVisible, inicio: tarea?.empezadaEn, minutos: minutos) }
    }

    private func actualizarWidget(puntaje: Double, conRetrato: Bool = false) {
        guard let persona = personas.first else { return }
        Widgets.luz(apariencia: AparienciaLumi(semilla: persona.semilla, cielo: tonoDeCielo), forma: persona.formaDeLumi,
                    energia: puntaje / 100, conRetrato: conRetrato)
        Widgets.revisarTarea(pendientes: Set(tareas.filter { $0.terminadaEn == nil }.map(\.textoVisible)))
    }

    /// zeno://hoy (widget, anillo) y zeno://escribir (atajo): siempre a Hoy.
    private func abrir(_ enlace: URL) {
        guard !personas.isEmpty, sesionAbierta else { return }
        withAnimation(movimientoDeLumi) {
            presentando = false
            llegada = true
            momento = .tarea
        }
        ir(a: .hoy)
        if enlace.host == "escribir" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { pedirAgregar += 1 }
        }
    }

    // MARK: Celebración

    private static var hoyTexto: String {
        Date.now.formatted(.iso8601.year().month().day())
    }

    /// La luz que Lumi gana con lo que haces (Diaz: "nuestra estrella ilumina más").
    /// Una parte es para siempre (crece despacio con todas las tareas terminadas y nunca baja) y otra
    /// es del día: cada tarea de hoy suma, las difíciles más. Nunca se resta como castigo.
    private var destelloDeHoy: Double {
        let total = eventos.filter { $0.tipo == .tareaTerminada }.count
        let paraSiempre = min(Double(total) / 120, 0.35)
        let grandesHoy = eventos.filter {
            $0.tipo == .tareaTerminada && Calendar.current.isDateInToday($0.fecha)
                && $0.tamano == .grande && !$0.conPrimerPaso
        }.count
        // Cada tarea terminada hoy suma luz; las difíciles, más. Nunca se resta.
        let hechasHoy = eventos.filter { $0.tipo == .tareaTerminada && Calendar.current.isDateInToday($0.fecha) }.count
        return min(paraSiempre + Double(grandesHoy) * 0.4 + Double(hechasHoy) * 0.18, 1)
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
        guard let persona = personas.first, sesionAbierta else { return }
        contexto.insert(EventoDeEnergia(tipo: .abrioLaApp))
        Task {
            await Avisos.alAbrir(persona, eventos: eventos)
            await AvisosDeTareas.sincronizar(contexto)
        }
    }

    /// Abrir y cerrar sin hacer nada también es una señal (sin juicio: solo cuenta para la energía).
    private func registrarCierre() {
        guard !personas.isEmpty, sesionAbierta else { return }
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

    /// Volver a entrar: directo a Hoy, y los avisos vuelven a programarse.
    private func abrirSesion() {
        presentando = false
        pagina = .hoy
        withAnimation(movimientoDeLumi) { sesionAbierta = true }
        registrarApertura()
    }

    private func terminarRegistro() {
        sesionAbierta = true
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
        .font(.zenoTexto(.caption2))
        .foregroundStyle(.white.opacity(0.5))
        VStack(alignment: .trailing, spacing: 4) {
            Button("Ver presencia") {
                visita += 1
                withAnimation(movimientoDeLumi) { momento = .presencia }
            }
            Button("Laboratorio") { mostrarLaboratorio = true }
            Button("Repetir registro") {
                withAnimation(.easeInOut(duration: 0.8)) { contexto.delete(persona) }
            }
        }
        .font(.zenoTexto(.caption2))
        .foregroundStyle(.white.opacity(0.5))
        }
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
