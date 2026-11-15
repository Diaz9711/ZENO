import SwiftUI
import SwiftData

/// Ajustes: lo poco que la persona decide, con el sistema de lujo (tarjetas, oro champán, hojas propias).
struct AjustesView: View {
    @Bindable var persona: Persona

    @Environment(\.modelContext) private var contexto
    @AppStorage(Sesion.clave) private var sesionAbierta = true
    @AppStorage(Idioma.clave) private var idioma = Idioma.actual.rawValue
    @State private var permisoDenegado = false
    @State private var hayClave = Clave.existe
    @State private var pendientes: [(id: String, fecha: Date?)] = []
    /// El historial ligero que ya tiene el universo (no se vuelve a leer de la base de datos).
    var eventos: [Senal] = []
    /// Dónde empieza el contenido, debajo de Lumi. Lo de encima se funde con el cielo.
    var arriba: CGFloat = 0
    @AppStorage("modoPrueba") private var modoPrueba = false
    @Namespace private var espacio
    /// "Cómo funciona ZENO": una página dentro de Ajustes, nunca una hoja de sistema.
    @State private var leyendo = false
    @State private var calidadNueva = CalidadVisual.nivel > 0.5

    var body: some View {
        let apariencia = AparienciaLumi(semilla: persona.semilla)

        ScrollViewReader { lector in
        ScrollView {
            MarcaDeLista(id: "zeno.arriba")
            if leyendo {
                ComoFuncionaView { withAnimation(Lujo.curva()) { leyendo = false } }
                    .padding(.top, 8)
                    .padding(.horizontal, Lujo.margen)
                    .background(alignment: .top) { HojaDeFondo().padding(.top, -14) }
                    .padding(.top, arriba)
                    .padding(.bottom, 150)
                    .informaDesplazamiento()
                    .transition(.desenfoque)
            } else {
            VStack(alignment: .leading, spacing: 34) {
                VStack(alignment: .leading, spacing: 8) {
                    EtiquetaLujo("ZENO")
                    Text("Ajustes")
                        .font(.zenoTitulo(.largeTitle))
                        .foregroundStyle(Lujo.marfil)
                        .shadow(color: .black.opacity(0.45), radius: 12, y: 2)
                    ChispaDiscreta(frase: Idioma.texto("Todo lo tuyo se queda en este iPhone."))
                        .padding(.top, 6)
                }
                .padding(.leading, 4)
                .aparece(0)

                // — Forma de Lumi —
                seccion("Tu Lumi", orden: 1) {
                    HStack(spacing: 12) {
                        ForEach(FormaDeLumi.allCases) { forma in
                            tarjeta(forma, apariencia: apariencia)
                        }
                    }
                    Text("Los colores y el movimiento son solo tuyos; la forma la eliges tú.")
                        .font(.zenoTexto(.caption))
                        .foregroundStyle(Lujo.marfilSecundario)
                }

                // — Idioma —
                seccion("Idioma", orden: 2) {
                    HStack(spacing: 10) {
                        ForEach(Idioma.allCases) { opcion in idiomaChip(opcion) }
                    }
                    .sensoryFeedback(.selection, trigger: idioma)
                }

                // — Avisos —
                seccion("Avisos", orden: 3) {
                    VStack(alignment: .leading, spacing: 0) {
                        Toggle(isOn: interruptorDeAvisos) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Un aviso amable al día")
                                    .font(.zenoTexto(.body))
                                    .foregroundStyle(Lujo.marfil)
                                Text("Como mucho uno, a las \(mejorHora):00, tu mejor hora. Nunca un día en que ya abriste ZENO.")
                                    .font(.zenoTexto(.caption))
                                    .foregroundStyle(Lujo.marfilSecundario)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .toggleStyle(InterruptorLujo())

                        if persona.notificacionesActivas && persona.avisosEnPausa {
                            SeparadorLujo().padding(.vertical, 12)
                            Text("Los dejé en pausa porque parecía que no hacían falta.")
                                .font(.zenoTexto(.caption))
                                .foregroundStyle(Lujo.marfilSecundario)
                            BotonTerciarioLujo(titulo: "Volver a recibirlos") {
                                Task { await Avisos.reanudar(persona, eventos: eventos) }
                            }
                            .padding(.leading, -12)
                        }

                        if permisoDenegado {
                            SeparadorLujo().padding(.vertical, 12)
                            Text("Para recibirlos, permite las notificaciones de ZENO en los Ajustes del iPhone.")
                                .font(.zenoTexto(.caption))
                                .foregroundStyle(Lujo.marfilSecundario)
                            BotonTerciarioLujo(titulo: "Abrir Ajustes del iPhone") {
                                if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .padding(.leading, -12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .tarjetaLujo()
                }

                // — Lo aprendido —
                seccion("Tu ritmo", orden: 4) {
                    let aprendido = Memoria.compartida.resumen(senales: eventos)
                    VStack(alignment: .leading, spacing: 14) {
                        if aprendido.isEmpty {
                            Text("Mientras más uses ZENO, más te conoceré: a qué horas rindes, cuánto te toman las cosas y qué prefieres dejar para después.")
                                .font(.zenoTexto(.footnote))
                                .foregroundStyle(Lujo.marfilSecundario)
                        } else {
                            ForEach(Array(aprendido.enumerated()), id: \.offset) { i, frase in
                                if i > 0 { SeparadorLujo() }
                                HStack(alignment: .firstTextBaseline, spacing: 12) {
                                    Circle().fill(Lujo.oro).frame(width: 4, height: 4)
                                    Text(verbatim: frase)
                                        .font(.zenoTexto(.subheadline))
                                        .foregroundStyle(Lujo.marfil)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .tarjetaLujo()
                }

                // — Sesión y clave —
                seccion("Sesión", orden: 5) {
                    VStack(alignment: .leading, spacing: 0) {
                        fila(icono: .llave,
                             titulo: hayClave ? "Cambiar tu clave" : "Proteger con una clave",
                             detalle: hayClave ? "Tu clave protege ZENO en este iPhone."
                                               : "Al volver te la pedirá. Se recupera con Face ID.") {
                            Hojas.compartidas.mostrar {
                                HojaDeNuevaClave(cambiando: hayClave) { hayClave = Clave.existe }
                            }
                        }
                        SeparadorLujo()
                        fila(icono: .cara,
                             titulo: persona.cuentaApple == nil ? "Entraste como invitado" : "Entraste con Apple",
                             detalle: "Todo vive solo en este teléfono.", accion: nil)
                    }
                    .padding(.horizontal, 20)
                    .tarjetaLujo()

                    HStack(spacing: 12) {
                        BotonSecundarioLujo("Cerrar sesión") {
                            Hojas.compartidas.mostrar {
                                HojaDeConfirmacion(
                                    titulo: "¿Cerrar sesión?",
                                    detalle: "Tu estrella, tus tareas y tu historial se quedan guardados en este teléfono. Para volver, entra de nuevo.",
                                    accion: "Cerrar sesión", destructiva: false, alConfirmar: cerrarSesion)
                            }
                        }
                    }
                    if hayClave {
                        BotonTerciarioLujo(titulo: "Quitar la clave", icono: .papelera, destructivo: true) {
                            Hojas.compartidas.mostrar {
                                HojaDeConfirmacion(
                                    titulo: "¿Quitar la clave?",
                                    detalle: "ZENO dejará de pedirla al entrar.",
                                    accion: "Quitar", destructiva: true) {
                                        Clave.borrar()
                                        withAnimation(Lujo.curva()) { hayClave = false }
                                    }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                // — Por qué funciona —
                seccion("Saber más", orden: 6) {
                    fila(icono: .ojo, titulo: "Cómo funciona ZENO",
                         detalle: "Tareas pequeñas, energía, tiempo y sin culpa, con estudios.") {
                        withAnimation(Lujo.curva()) { leyendo = true }
                        Desplazamiento.compartido.valor = 0
                    }
                    .padding(.horizontal, 20)
                    .tarjetaLujo()
                }

                // — Datos —
                seccion("Tus datos", orden: 6) {
                    Text("Todo vive solo en este teléfono. Sin cuentas, sin servidores.")
                        .font(.zenoTexto(.caption))
                        .foregroundStyle(Lujo.marfilSecundario)
                    BotonTerciarioLujo(titulo: "Borrar mis datos", icono: .papelera, destructivo: true) {
                        Hojas.compartidas.mostrar {
                            HojaDeConfirmacion(
                                titulo: "¿Borrar todo?",
                                detalle: "Se borran tu estrella, tus tareas y tu historial de energía. No se puede deshacer.",
                                accion: "Borrar mis datos", destructiva: true, alConfirmar: borrarTodo)
                        }
                    }
                    .padding(.leading, -12)
                }

                #if DEBUG
                // Solo en desarrollo: los controles de prueba ya no ensucian la pantalla principal.
                VStack(alignment: .leading, spacing: 10) {
                    Toggle(isOn: $modoPrueba) {
                        Text("Modo de prueba").font(.zenoTexto(.body))
                    }
                    .toggleStyle(InterruptorLujo())

                    if modoPrueba {
                        // Comparar en vivo el cielo y Lumi de siempre con la nueva calidad.
                        Toggle(isOn: Binding(get: { calidadNueva }, set: { nuevo in
                            calidadNueva = nuevo
                            CalidadVisual.nivel = nuevo ? 1 : 0
                            UserDefaults.standard.set(CalidadVisual.nivel, forKey: CalidadVisual.clave)
                        })) {
                            Text(verbatim: "Nueva calidad del cielo y Lumi").font(.zenoTexto(.subheadline))
                        }
                        .toggleStyle(InterruptorLujo())
                        Button("Cargar datos de ejemplo") { DatosDeEjemplo.cargar(en: contexto) }
                            .font(.zenoTexto(.subheadline, .medium))
                        Button("Enviar un aviso de prueba en 10 segundos") {
                            Task { await Avisos.enviarPrueba() ; pendientes = await Avisos.pendientes() }
                        }
                        .font(.zenoTexto(.subheadline, .medium))
                        Text("Avisos programados:")
                            .font(.zenoTexto(.footnote, .semibold))
                        if pendientes.isEmpty {
                            Text("Ninguno").font(.zenoTexto(.footnote)).opacity(0.6)
                        }
                        ForEach(pendientes, id: \.id) { p in
                            Text("\(p.id) · \(p.fecha?.formatted(date: .abbreviated, time: .shortened) ?? "—")")
                                .font(.zenoTexto(.caption))
                                .opacity(0.75)
                        }
                        Text("Ignorados seguidos: \(persona.avisosIgnorados) · En pausa: \(persona.avisosEnPausa ? "sí" : "no")")
                            .font(.zenoTexto(.caption))
                            .opacity(0.75)
                            .task {
                                pendientes = await Avisos.pendientes()
                                // Al abrir la app los avisos se reprograman un instante después: se vuelve a mirar.
                                try? await Task.sleep(for: .seconds(1.5))
                                pendientes = await Avisos.pendientes()
                            }
                    }
                }
                .foregroundStyle(Lujo.marfil)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .tarjetaLujo()
                #endif

                Text("ZENO acompaña tu día. No diagnostica ni reemplaza un tratamiento.")
                    .font(.zenoTitulo(.footnote, .regular, cursiva: true))
                    .foregroundStyle(Lujo.marfil.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)
            .padding(.horizontal, Lujo.margen)
            // La hoja casi transparente se desliza con el contenido: nunca queda una línea fija que corte.
            .background(alignment: .top) { HojaDeFondo().padding(.top, -14) }
            .padding(.top, arriba)
            .padding(.bottom, 150)      // deja sitio a la barra
            .informaDesplazamiento()
            .transition(.desenfoque)
            }
            MarcaDeLista(id: "zeno.abajo")
        }
        .deslizablePorAutopiloto(lector)
        }
        // Al abrir o cerrar "Cómo funciona ZENO" se empieza arriba.
        .id(leyendo)
        .coordinateSpace(name: "pagina")
        .bordesFundidos(arriba: arriba)
        .foregroundStyle(Lujo.marfil)
        .scrollIndicators(.hidden)
        .onAppear {
            Desplazamiento.compartido.valor = 0
            hayClave = Clave.existe
        }
    }

    // MARK: Piezas

    private func seccion<C: View>(_ titulo: LocalizedStringKey, orden: Int, @ViewBuilder contenido: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            EtiquetaLujo(titulo).padding(.leading, 4)
            contenido()
        }
        .aparece(orden)
    }

    /// Una fila de tarjeta: icono fino, una idea y un dato; si tiene acción, toda la fila se toca.
    @ViewBuilder
    private func fila(icono: IconoLujo, titulo: LocalizedStringKey, detalle: LocalizedStringKey,
                      accion: (() -> Void)?) -> some View {
        let contenido = HStack(spacing: 14) {
            IconoFino(icono: icono, color: accion == nil ? Lujo.marfilSecundario : Lujo.oro, tamano: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(titulo).font(.zenoTexto(.body)).foregroundStyle(Lujo.marfil)
                Text(detalle).font(.zenoTexto(.caption)).foregroundStyle(Lujo.marfilSecundario)
            }
            Spacer(minLength: 0)
            if accion != nil {
                IconoFino(icono: .atras, color: Lujo.marfilSecundario, tamano: 12)
                    .rotationEffect(.degrees(180))
            }
        }
        .padding(.vertical, 14)
        .frame(minHeight: Lujo.altoMinimo)
        .contentShape(Rectangle())

        if let accion {
            Button(action: accion) { contenido }
                .buttonStyle(EstiloLujo())
                .sensoryFeedback(.selection, trigger: hayClave)
        } else {
            contenido
        }
    }

    private func idiomaChip(_ opcion: Idioma) -> some View {
        let elegido = idioma == opcion.rawValue
        return Button {
            cambiarIdioma(a: opcion)
        } label: {
            Text(verbatim: opcion.nombre)
                .font(.zenoTexto(.callout, elegido ? .medium : .regular))
                .foregroundStyle(elegido ? Lujo.oro : Lujo.marfil.opacity(0.6))
                .frame(maxWidth: .infinity)
                .frame(height: Lujo.altoBoton)
                .background {
                    RoundedRectangle(cornerRadius: Lujo.radioChip, style: .continuous).fill(Lujo.marfil.opacity(0.03))
                    if elegido {
                        RoundedRectangle(cornerRadius: Lujo.radioChip, style: .continuous)
                            .strokeBorder(Lujo.oro.opacity(0.85), lineWidth: 0.75)
                            .matchedGeometryEffect(id: "idioma", in: espacio)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(EstiloLujo())
        .accessibilityAddTraits(elegido ? .isSelected : [])
    }

    /// Una vista previa viva de cada forma, con la semilla de la persona (la estrella no cambia: solo se elige).
    private func tarjeta(_ forma: FormaDeLumi, apariencia: AparienciaLumi) -> some View {
        let elegida = persona.formaDeLumi == forma
        return Button {
            withAnimation(Lujo.curva()) { persona.formaDeLumi = forma }
        } label: {
            VStack(spacing: 4) {
                // Viva, como siempre (medido: con el cielo en pausa al deslizar, ya no frena la página).
                LumiView(apariencia: apariencia, energia: 0.75, forma: forma, cuadros: 30)
                    .frame(maxWidth: .infinity)
                    .frame(height: 124)
                    .clipShape(RoundedRectangle(cornerRadius: Lujo.radioTarjeta, style: .continuous))
                Text(forma == .estrella ? "Estrella" : "Esfera")
                    .font(.lujoEtiqueta(.caption, .medium))
                    .versalitas(1.6)
                    .foregroundStyle(elegida ? Lujo.oro : Lujo.marfilSecundario)
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity)
            .tarjetaLujo()
            .overlay {
                if elegida {
                    RoundedRectangle(cornerRadius: Lujo.radioTarjeta, style: .continuous)
                        .strokeBorder(Lujo.oro.opacity(0.8), lineWidth: 0.75)
                        .matchedGeometryEffect(id: "forma", in: espacio)
                }
            }
        }
        .buttonStyle(EstiloLujo())
        .sensoryFeedback(.selection, trigger: elegida)
        .accessibilityAddTraits(elegida ? .isSelected : [])
    }

    private var mejorHora: Int {
        Memoria.compartida.cerebro(persona: persona, senales: eventos, ahora: .now).mejorHora
    }

    /// Encender pide permiso (solo entonces); apagar borra solo el aviso diario.
    private var interruptorDeAvisos: Binding<Bool> {
        Binding(
            get: { persona.notificacionesActivas },
            set: { quiere in
                if quiere {
                    Task {
                        let resultado = await Avisos.activar(persona, eventos: eventos)
                        withAnimation(Lujo.curva()) { permisoDenegado = resultado == .denegados }
                        pendientes = await Avisos.pendientes()
                    }
                } else {
                    Avisos.desactivar(persona)
                    permisoDenegado = false
                    pendientes = []
                }
            })
    }

    /// Cambia el idioma de toda la app al momento y reescribe los avisos ya programados en el nuevo idioma.
    private func cambiarIdioma(a nuevo: Idioma) {
        guard idioma != nuevo.rawValue else { return }
        withAnimation(Lujo.curva()) { idioma = nuevo.rawValue }
        Task {
            if persona.notificacionesActivas { await Avisos.programar(persona, eventos: eventos) }
            await AvisosDeTareas.sincronizar(contexto)
        }
    }

    /// Cierra la sesión sin borrar nada. Mientras esté cerrada no llega ningún aviso.
    private func cerrarSesion() {
        Avisos.cancelarTodo()
        persona.avisoDiarioProgramado = nil      // si no, al volver contaría como un aviso ignorado
        Task { await AnilloEnVivo.terminarTodo() }
        Widgets.olvidar()                         // con la sesión cerrada, el widget no muestra tareas
        withAnimation(.spring(response: 0.75, dampingFraction: 0.74)) { sesionAbierta = false }
    }

    private func borrarTodo() {
        Avisos.cancelarTodo()
        Clave.borrar()
        try? contexto.delete(model: EventoDeEnergia.self)
        try? contexto.delete(model: Tarea.self)
        try? contexto.delete(model: Persona.self)
        UserDefaults.standard.removeObject(forKey: "diaCalido")
        Task { await AnilloEnVivo.terminarTodo() }
        Widgets.olvidar()
    }
}

/// Crear o cambiar la clave, en una hoja de ZENO.
struct HojaDeNuevaClave: View {
    var cambiando = false
    var alTerminar: () -> Void = {}
    @State private var clave = ""
    @State private var repetida = ""
    @State private var problema: Clave.Problema?
    @State private var guardada = 0
    @FocusState private var enfoque: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                EtiquetaLujo("Sesión")
                Text(cambiando ? "Tu clave nueva" : "Crea tu clave")
                    .font(.zenoTitulo(.title2, .regular))
                    .foregroundStyle(Lujo.marfil)
            }
            CampoDeClave(texto: $clave, sugerencia: "Una clave", error: problema != nil && problema != .noCoinciden,
                         enfocado: $enfoque, indice: 0) { enfoque = 1 }
            CampoDeClave(texto: $repetida, sugerencia: "Repítela", error: problema == .noCoinciden,
                         enfocado: $enfoque, indice: 1) { guardar() }
            Group {
                if let problema {
                    Text(verbatim: problema.mensaje).foregroundStyle(Lujo.rojizo)
                } else {
                    Text("Al menos \(Clave.minimo) caracteres. Solo vive en este iPhone; si la olvidas, la recuperas con Face ID.")
                        .foregroundStyle(Lujo.marfilSecundario)
                }
            }
            .font(.zenoTexto(.caption))
            .fixedSize(horizontal: false, vertical: true)
            BotonPrimarioLujo("Guardar clave", accion: guardar)
        }
        .sensoryFeedback(.success, trigger: guardada)
        .sensoryFeedback(.error, trigger: problema) { _, nuevo in nuevo != nil }
        .task {
            // El campo recibe el teclado cuando la pantalla ya terminó de entrar.
            try? await Task.sleep(for: .milliseconds(450))
            enfoque = 0
        }
        .onChange(of: clave) { _, _ in if problema != nil { withAnimation(Lujo.curva()) { problema = nil } } }
    }

    private func guardar() {
        if let fallo = Clave.validar(nueva: clave, repetida: repetida) {
            withAnimation(Lujo.curva()) { problema = fallo }
            return
        }
        Clave.guardar(clave)
        guardada += 1
        enfoque = nil
        alTerminar()
        Hojas.compartidas.cerrar()
    }
}

/// Una confirmación en una hoja de ZENO, en vez de un diálogo gris de sistema.
struct HojaDeConfirmacion: View {
    let titulo: LocalizedStringKey
    let detalle: LocalizedStringKey
    let accion: LocalizedStringKey
    var destructiva = true
    let alConfirmar: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text(titulo)
                    .font(.zenoTitulo(.title2, .regular))
                    .foregroundStyle(Lujo.marfil)
                Text(detalle)
                    .font(.zenoTexto(.footnote))
                    .foregroundStyle(Lujo.marfilSecundario)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 12) {
                BotonSecundarioLujo("Cancelar") { Hojas.compartidas.cerrar() }
                if destructiva {
                    Button {
                        Hojas.compartidas.cerrar()
                        alConfirmar()
                    } label: {
                        Text(accion)
                            .font(.lujoEtiqueta(.footnote, .medium))
                            .versalitas(1.8)
                            .foregroundStyle(Lujo.rojizo)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity)
                            .frame(height: Lujo.altoBoton)
                            .background(RoundedRectangle(cornerRadius: Lujo.radioBoton, style: .continuous)
                                .strokeBorder(Lujo.rojizo.opacity(0.55), lineWidth: 0.75))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(EstiloLujo())
                } else {
                    BotonPrimarioLujo(accion) {
                        Hojas.compartidas.cerrar()
                        alConfirmar()
                    }
                }
            }
        }
    }
}
