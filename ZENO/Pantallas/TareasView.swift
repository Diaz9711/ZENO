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
    var eventos: [Senal]
    /// Avisa a Lumi que celebre una tarea terminada.
    var alTerminar: (Celebracion) -> Void = { _ in }
    /// La hora de más energía, para la tarjeta de hoy.
    var mejorHora: Int = 12
    /// Cambia cada vez que se toca el "+" de la barra.
    var pedirAgregar: Int = 0
    /// iPhone más bajo que el Pro Max: no cabe todo, así que el campo de escribir se queda en el "+"
    /// de la barra (hace lo mismo) y la barra nunca queda fuera de la pantalla.
    var compacto = false
    /// Avisa cuando se está escribiendo, para esconder la barra.
    @Binding var editando: Bool

    @Environment(\.modelContext) private var contexto
    /// Letra grande del iPhone (auditoría): con xxxL o más, lo secundario cede su sitio para que la tarea
    /// y sus dos botones se vean enteros y la barra no los tape.
    @Environment(\.dynamicTypeSize) private var tamanoDeLetra
    private var letraGrande: Bool { tamanoDeLetra >= .xxxLarge }
    /// Leído para que, al cambiar de idioma, también se redibujen las frases armadas en código.
    @Environment(\.locale) private var idiomaElegido
    @Query(filter: #Predicate<Tarea> { $0.terminadaEn == nil }, sort: \Tarea.creadaEn)
    private var pendientes: [Tarea]
    @Query private var personas: [Persona]
    /// Qué va en la parte baja de las tarjetas Hoy y Tu mejor hora (Diaz: "que no esté tan vacío").
    /// Elegido (Fable, con permiso de Diaz, 15 nov 2026): 2 · Estrellas y curva. Para comparar en pruebas:
    /// `-disenoMedianas 0|1|3` (0 = como antes, 1 Estrellas y reloj, 3 Frases).
    private var disenoMedianas: Int {
        #if DEBUG
        if let n = UserDefaults.standard.object(forKey: "disenoMedianas") as? Int { return n }
        if let t = UserDefaults.standard.string(forKey: "disenoMedianas"), let n = Int(t) { return n }
        #endif
        return 2
    }

    @State private var modo = Modo.ver
    @State private var frase = ""
    @State private var primerPaso = ""
    /// "¿Para qué te importa?" (opcional): se abre con un toque, nunca estorba.
    @State private var porque = ""
    @State private var conPorque = false
    @FocusState private var escribiendoPorque: Bool
    @State private var quiereAlgoIgual = false
    /// Bucle de retorno: el patrón que Chispa cuenta ahora (cada uno, como mucho una vez al día).
    @State private var patronDeAhora: Aprendizaje.Patron?
    @AppStorage("patronesDichos") private var patronesDichos = ""
    @State private var plan = BorradorDePlan()
    @State private var dictado = Dictado()
    @State private var toques = 0
    /// Cada paso terminado de una tarea dividida (un toque suave).
    @State private var pasosHechos = 0
    /// Unos segundos después de terminar una tarea, Chispa lo celebra con una frase.
    @State private var celebrando = false
    /// Recuerda la tarea elegida: la pantalla la pide muchas veces por dibujo y calcularla recorre el historial.
    @State private var memoria = MemoriaDeEleccion()
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
        }
        .ignoresSafeArea(.keyboard)
        .sensoryFeedback(.selection, trigger: toques)
        .sensoryFeedback(.impact(weight: .light), trigger: escuchando)
        .sensoryFeedback(.impact(weight: .medium, intensity: 0.6), trigger: pasosHechos)
        .onChange(of: dictado.texto) { _, nuevo in
            // Lo que se dicta va apareciendo en el campo activo.
            guard !nuevo.isEmpty else { return }
            if modo == .primerPaso { primerPaso = nuevo } else { frase = nuevo }
        }
        .onChange(of: idPropuesta, initial: true) { _, nueva in
            // Queda registrado qué se propuso y con cuánta energía, para aprender.
            // Sin repetir: una misma propuesta se anota como mucho una vez cada media hora
            // (si no, el historial crecía en cada redibujado y la app se volvía lenta).
            let yaAnotada = eventos.reversed().prefix(40).contains {
                $0.tipo == .tareaPropuesta && $0.tareaID == nueva && Date.now.timeIntervalSince($0.fecha) < 30 * 60
            }
            if let nueva, !yaAnotada, let tarea = pendientes.first(where: { $0.persistentModelID == nueva }), enCurso != nueva {
                registrar(.tareaPropuesta, valor: puntaje, tarea: tarea)
            }
        }
        .onChange(of: dictado.activo) { antes, activo in
            withAnimation(Lujo.curva(0.4)) { escuchando = activo }
            // Al dejar de dictar: si dijo varias cosas, Chispa las separa y las muestra antes de guardar.
            if antes && !activo && modo == .agregar { procesarDictado() }
        }
        .onChange(of: idPropuesta, initial: true) { _, _ in revisarPatron() }
        .onChange(of: pedirAgregar) { _, _ in abrirAgregar() }
        // El widget de inicio muestra la misma tarea de ahora.
        .onChange(of: firmaParaWidget, initial: true) { _, _ in
            if case .tarea(let tarea) = eleccion {
                Widgets.tarea(tarea.textoVisible, inicio: enCurso == tarea.persistentModelID ? tarea.empezadaEn : nil,
                              minutos: Aprendizaje.minutosPrevistos(tarea, eventos: eventos))
            } else {
                Widgets.tarea(nil, inicio: nil, minutos: 0)
            }
        }
        .onChange(of: modo) { _, nuevo in
            withAnimation(Ritmo.contenido) { editando = nuevo != .ver }
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
            // El amigo: una sola frase según el momento; al tocarlo, ofrece ayuda.
            // Cada pieza llega en su turno (Fable): Chispa, Ahora, el campo y las dos medianas.
            CoheteAmigo(frase: Cohete.consejo(momentoDelCohete, turno: turnoDeFrase)) { pedirAyuda() }
                .aparece(1)
            tarjetaDeAhora
                .aparece(2)

            if mostrarCampoRapido && !(compacto && hayTareaPropuesta) && !letraGrande {
                CampoRapido { abrirAgregar() }
                    .aparece(3)
            }

            // Las dos tarjetas se estiran con el espacio que sobra (sin tareas, en marcha, en descanso),
            // así abajo no queda un hueco vacío; con una tarea propuesta quedan en su mínimo (Fable).
            // Con letra grande las medianas (solo datos) se retiran: lo primero es la tarea.
            if !letraGrande {
                HStack(alignment: .top, spacing: 12) {
                    tarjetaDelDia.aparece(4)
                    tarjetaDeMejorHora.aparece(5)
                }
                .frame(minHeight: 128, maxHeight: hayTareaPropuesta ? nil : 184)
                // Con una tarea propuesta no sobra espacio: tamaño justo, como antes.
                .fixedSize(horizontal: false, vertical: hayTareaPropuesta)
            }

            if let aviso = dictado.aviso {
                Text(aviso)
                    .font(.zenoTexto(.footnote))
                    .foregroundStyle(Lujo.marfilSecundario)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 22)
        Color.clear
            .frame(height: 72)         // deja sitio a la barra (alta ~70 pt); lo que sobra lo toman las tarjetas
    }

    /// Qué ve el cohete ahora mismo, para decir su frase.
    /// Cuándo cambia la frase de Chispa: con otra tarea, otra cosa hecha o cada media hora (nunca en cada redibujado).
    private var turnoDeFrase: String {
        "\(idPropuesta.map { "\($0.hashValue)" } ?? "-")|\(enCurso != nil)|\(hechasHoy.count)|\(Int(Date.now.timeIntervalSince1970 / 1800))"
    }

    private var momentoDelCohete: Cohete.Momento {
        if celebrando { return .celebrando }
        switch eleccion {
        case .tarea(let tarea):
            let minutos = tarea.primerPaso == nil
                ? Aprendizaje.minutosReales(tarea.tamano, eventos: eventos).map { Int($0.rounded()) } : nil
            return .tarea(enMarcha: enCurso == tarea.persistentModelID, primerPaso: tarea.primerPaso != nil,
                          minutosReales: minutos, enRacha: enRacha && enCurso == nil, anzuelo: tarea.anzuelo,
                          patron: patronDeAhora)
        case .descanso: return .descanso
        case .masTarde: return .masTarde(vuelveA: vuelveA)
        case .silencio: return .silencio
        case .nadaPendiente: return .nada(hechasHoy: hechasHoy.count)
        }
    }

    /// La ayuda del cohete: escribir, dictar y, si hay una tarea, dejarla para después.
    private func pedirAyuda() {
        var acciones = [
            HojaDeAyuda.Accion(titulo: "Escribir una tarea", icono: .mas) { abrirAgregar() },
            HojaDeAyuda.Accion(titulo: "Dictar una tarea", icono: .microfono) { alternarVoz() }
        ]
        if case .tarea(let tarea) = eleccion {
            // Divídemela (fase IA): pasos de unos 5 minutos; si ya está dividida, se editan sus pasos.
            acciones.insert(HojaDeAyuda.Accion(titulo: tarea.pasos.isEmpty ? "Divídemela" : "Cambiar los pasos", icono: .check) {
                dividir(tarea)
            }, at: 0)
            acciones.append(HojaDeAyuda.Accion(titulo: "Dejar esta para después", icono: .reloj) { ahoraNo(tarea) })
        }
        Hojas.compartidas.mostrar { HojaDeAyuda(acciones: acciones) }
    }

    /// Abre "Divídemela" para una tarea. Espera un instante a que se cierre la hoja de Chispa.
    private func dividir(_ tarea: Tarea) {
        let nivel = MotorDeEnergia.nivel(puntaje)
        let cuesta = Aprendizaje.leCuesta(tipo: TipoDeTarea.de(tarea.titulo), eventos: eventos)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.35))
            Hojas.compartidas.mostrar { HojaDividir(tarea: tarea, energia: nivel, masPequenos: cuesta) }
        }
    }

    /// La tarjeta ancha: la tarea del momento (con su botón Empezar / Terminé) o el estado del día.
    @ViewBuilder
    private var tarjetaDeAhora: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch eleccion {
            case .tarea(let tarea):
                let enMarcha = enCurso == tarea.persistentModelID
                HStack {
                    Group {
                        if !tarea.pasos.isEmpty {
                            EtiquetaLujo("Paso \(tarea.pasoActual + 1) de \(tarea.pasos.count)")
                        } else {
                            EtiquetaLujo(enRacha && enCurso == nil ? "Vas en racha · ¿una más?"
                                         : (tarea.primerPaso != nil ? "Primer paso" : (enCurso == nil ? "Ahora" : "En curso")))
                        }
                    }
                        .contentTransition(.opacity)
                    Spacer()
                    if let fecha = tarea.fechaPlaneada, Calendar.current.isDateInToday(fecha) {
                        Text(fecha, format: .dateTime.hour().minute())
                            .font(.zenoTexto(.caption, .medium))
                            .foregroundStyle(Lujo.oro.opacity(0.85))
                    }
                }
                // La siguiente tarea sube desde abajo mientras la anterior se va hacia arriba (sin desenfoque).
                TareaTocable(tarea: tarea, enCurso: enMarcha)
                    .id("\(tarea.persistentModelID.hashValue)-\(tarea.pasoActual)")
                    .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 12)),
                                            removal: .opacity.combined(with: .offset(y: -8))))
                // Un botón visible y claro (pedido de Diaz): Empezar y, en marcha, Terminé. Solo tocar.
                HStack(alignment: .center, spacing: 10) {
                    BotonDeAhora(enMarcha: enMarcha) {
                        if enMarcha { terminar(tarea) } else { empezar(tarea) }
                    }
                    BotonTerciarioLujo(titulo: enMarcha ? "Dejarla para después" : "Ahora no") { ahoraNo(tarea) }
                }
                // "Empezar" → "Terminé" se funde en vez de saltar.
                .contentTransition(.opacity)
                .padding(.top, 4)

            case .descanso:
                EtiquetaLujo("Descanso")
                Titular(texto: Idioma.texto("Hoy descansa, mañana atacamos"), tamano: .title2, alineacion: .leading)
                HStack {
                    BotonTerciarioLujo(titulo: "Quiero hacer algo igual") {
                        toques += 1
                        withAnimation(Lujo.curva()) { quiereAlgoIgual = true }
                    }
                    .padding(.trailing, -12)
                }

            case .silencio:
                // Modo compañero: nada que proponer. Una frase de presencia y una puerta discreta.
                EtiquetaLujo("Sin prisa")
                Titular(texto: Idioma.texto("Estoy aquí contigo"), tamano: .title2, alineacion: .leading)
                HStack {
                    BotonTerciarioLujo(titulo: "Quiero hacer algo") {
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

            case .nadaPendiente:
                EtiquetaLujo("Ahora")
                Titular(texto: Idioma.texto("No tienes nada pendiente"), tamano: .title2, alineacion: .leading)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tarjetaLujo(radio: 24)
    }

    /// Mediana izquierda: lo hecho hoy. Solo progreso; sin ceros que parezcan deuda.
    private var tarjetaDelDia: some View {
        VStack(alignment: .leading, spacing: 6) {
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
            switch disenoMedianas {
            case 1, 2:
                // Una estrellita por cada tarea de hoy (sin huecos vacíos: nunca parece una racha rota).
                if hechasHoy.isEmpty {
                    LineaDeLuz(cantidad: 0).frame(width: 58, height: 6).accessibilityHidden(true)
                } else {
                    EstrellasDeHoy(cantidad: hechasHoy.count).accessibilityHidden(true)
                }
            case 3:
                if let ultima = hechasHoy.last?.tareaID, let texto = tituloDe(ultima) {
                    Text("Lo último: \(texto)")
                        .font(.zenoTexto(.caption))
                        .foregroundStyle(Lujo.marfilSecundario)
                        .lineLimit(2)
                }
                LineaDeLuz(cantidad: Double(hechasHoy.count) / 4).frame(width: 58, height: 6).accessibilityHidden(true)
            default:
                LineaDeLuz(cantidad: Double(hechasHoy.count) / 4)
                    .frame(width: 58, height: 6)
                    .accessibilityHidden(true)
            }
        }
        .animation(Lujo.curva(), value: hechasHoy.count)
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity, minHeight: 128, maxHeight: .infinity, alignment: .topLeading)
        .tarjetaLujo()
        .accessibilityElement(children: .combine)
    }

    /// Mediana derecha: la mejor hora, aprendida de la persona.
    private var tarjetaDeMejorHora: some View {
        VStack(alignment: .leading, spacing: 6) {
            EtiquetaLujo("Tu mejor hora")
            // La hora y, a su lado (misma línea, para no alargar la tarjeta), cuándo llega.
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(verbatim: "\(mejorHora):00")
                    .font(.zenoTitulo(.largeTitle, .light))
                    .foregroundStyle(Lujo.marfil)
                    .contentTransition(.numericText())
                if disenoMedianas != 0 {
                    Text(CuandoEsTuHora.texto(mejorHora))
                        .font(.zenoTexto(.caption))
                        .foregroundStyle(Lujo.marfilSecundario)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            Spacer(minLength: 0)
            if disenoMedianas == 2, let persona = personas.first {
                let _ = Memoria.compartida.cerebro(persona: persona, senales: eventos, ahora: .now)
                CurvaDelDia(valores: Memoria.compartida.horasGuardadas, mejorHora: mejorHora)
                    .frame(minHeight: 22, maxHeight: 70)
                    .accessibilityHidden(true)
            } else {
                PuntoDelDia(hora: mejorHora, conAhora: disenoMedianas != 0)
                    .frame(height: 6)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity, minHeight: 128, maxHeight: .infinity, alignment: .topLeading)
        .tarjetaLujo()
        .accessibilityElement(children: .combine)
    }

    /// El campo para escribir aparece cuando no hay una tarea en marcha ni descanso:
    /// así la pantalla sigue teniendo una sola acción principal.
    /// Con una tarea propuesta la tarjeta Ahora es alta: en iPhones bajos el campo no cabe (queda el "+").
    private var hayTareaPropuesta: Bool {
        // Solo propuesta (no en marcha): en marcha el campo se esconde y sí sobra espacio.
        if case .tarea = eleccion, enCurso == nil { return true }
        return false
    }

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

    /// El título de una tarea terminada (para "Lo último").
    private func tituloDe(_ id: PersistentIdentifier) -> String? {
        (contexto.model(for: id) as? Tarea)?.textoVisible
    }

    private var hechasHoy: [Senal] {
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
        return memoria.eleccion(pendientes: pendientes, puntaje: puntaje, eventos: eventos,
                                quiereAlgoIgual: quiereAlgoIgual)
    }

    private var firmaParaWidget: String {
        guard case .tarea(let tarea) = eleccion else { return "" }
        return "\(tarea.textoVisible)|\(enCurso == tarea.persistentModelID ? tarea.empezadaEn?.timeIntervalSince1970 ?? 0 : 0)"
    }

    private var idPropuesta: PersistentIdentifier? {
        if case .tarea(let tarea) = eleccion { return tarea.persistentModelID }
        return nil
    }

    // MARK: Agregar

    private var agregar: some View {
        VStack(spacing: 14) {
            // Con el porqué abierto, el título se retira para que todo quepa sobre el teclado.
            if !conPorque {
                Text(escuchando ? "Te escucho…" : "¿Qué quieres hacer?")
                    .font(.zenoTitulo(.title2))
                    .foregroundStyle(Lujo.marfil)
                    .shadow(color: .black.opacity(0.45), radius: 12, y: 2)
                    .transition(.opacity)
            }
            campo($frase, sugerencia: "Una sola frase")
            campoDelPorque
            // Los botones quedan siempre a la vista, aunque el teclado esté abierto.
            // El reloj abre el día y la hora (opcional) en una hoja.
            HStack(spacing: 10) {
                // Cancelar es una ✕ fina (con cinco botones el texto no cabía).
                Button { cerrarAgregar() } label: {
                    IconoFino(icono: .cerrar, color: Lujo.marfil.opacity(0.75), tamano: 15)
                        .frame(width: Lujo.altoBoton, height: Lujo.altoBoton)
                        .background(RoundedRectangle(cornerRadius: Lujo.radioBoton, style: .continuous)
                            .fill(Lujo.marfil.opacity(0.03)))
                        .cantoPulido(radio: Lujo.radioBoton, oro: false)
                }
                .buttonStyle(EstiloLujo())
                .accessibilityLabel(Text("Cancelar"))
                Button {
                    // El día y la hora se eligen en una hoja: Lumi no se mueve y el teclado se baja.
                    escribiendo = false
                    let enlace = $plan
                    Hojas.compartidas.mostrar { HojaDePlan(plan: enlace) }
                } label: {
                    IconoFino(icono: .reloj, color: plan.conFecha ? Lujo.oro : Lujo.marfil.opacity(0.75), tamano: 19)
                        .frame(width: Lujo.altoBoton, height: Lujo.altoBoton)
                        .background(RoundedRectangle(cornerRadius: Lujo.radioBoton, style: .continuous)
                            .fill(Lujo.marfil.opacity(0.03)))
                        .cantoPulido(radio: Lujo.radioBoton, oro: plan.conFecha)
                }
                .buttonStyle(EstiloLujo())
                .accessibilityLabel(Text("Día y hora"))
                // Dictar: un toque empieza a escuchar, otro toque termina. La voz no sale del teléfono.
                Button { alternarVoz() } label: {
                    IconoMicrofono(activo: dictado.activo)
                        .frame(width: Lujo.altoBoton, height: Lujo.altoBoton)
                        .background(RoundedRectangle(cornerRadius: Lujo.radioBoton, style: .continuous)
                            .fill(Lujo.marfil.opacity(dictado.activo ? 0.06 : 0.03)))
                        .cantoPulido(radio: Lujo.radioBoton, oro: dictado.activo)
                }
                .buttonStyle(EstiloLujo())
                .accessibilityLabel(dictado.activo ? Text("Dejar de dictar") : Text("Dictar la tarea"))
                // El porqué (opcional): una estrellita, la misma que lo acompaña luego en Hoy.
                Button {
                    toques += 1
                    if conPorque {
                        escribiendoPorque = true
                    } else {
                        withAnimation(Lujo.curva()) { conPorque = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { escribiendoPorque = true }
                    }
                } label: {
                    EstrellitaDeCuatro()
                        .fill(conPorque || !limpio(porque).isEmpty ? Lujo.oro : Lujo.marfil.opacity(0.75))
                        .frame(width: 17, height: 17)
                        .frame(width: Lujo.altoBoton, height: Lujo.altoBoton)
                        .background(RoundedRectangle(cornerRadius: Lujo.radioBoton, style: .continuous)
                            .fill(Lujo.marfil.opacity(0.03)))
                        .cantoPulido(radio: Lujo.radioBoton, oro: conPorque)
                }
                .buttonStyle(EstiloLujo())
                .accessibilityLabel(Text("¿Para qué te importa?"))
                botonChico("Guardar", fuerte: true) { guardarFrase() }
                    .disabled(limpio(frase).isEmpty)
            }
            if plan.conFecha {
                EtiquetaDePlanBorrador(plan: plan)
                    .transition(.opacity)
            }
            Text(conPorque ? Idioma.texto("Lo que te llama de esto. Opcional.")
                 : (dictado.aviso ?? Idioma.texto("Toca el micrófono para dictarla. La estrellita guarda para qué te importa.")))
                .font(.zenoTexto(.caption))
                .foregroundStyle(Lujo.marfilSecundario)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.horizontal, Lujo.margen)
    }

    /// El anzuelo de la tarea, cerrado hasta que la persona lo pide. Una línea, opcional.
    @ViewBuilder
    private var campoDelPorque: some View {
        if conPorque {
            TextField("", text: $porque, prompt: Text("¿Para qué te importa? (opcional)").foregroundStyle(Lujo.marfil.opacity(0.3)))
                .font(.zenoTexto(.callout))
                .foregroundStyle(Lujo.marfil)
                .tint(Lujo.oro)
                .multilineTextAlignment(.center)
                .submitLabel(.done)
                .focused($escribiendoPorque)
                .onSubmit { guardarFrase() }
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Lujo.marfil.opacity(0.03)))
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Lujo.oro.opacity(escribiendoPorque ? 0.7 : 0.12)).frame(height: 0.75)
                        .animation(Lujo.curva(), value: escribiendoPorque)
                }
                .transition(.opacity.combined(with: .offset(y: -6)))
        }
    }

    private var preguntaDelPrimerPaso: some View {
        VStack(spacing: 14) {
            Text("¿Cuál es el primer paso de dos minutos?")
                .font(.zenoTitulo(.title3))
                .foregroundStyle(Lujo.marfil)
                .shadow(color: .black.opacity(0.45), radius: 12, y: 2)
                .multilineTextAlignment(.center)
            campo($primerPaso, sugerencia: "Algo muy pequeño")
            HStack(spacing: 10) {
                botonChico("Saltar", fuerte: false) { guardarTarea(conPaso: false) }
                botonChico("Listo", fuerte: true) { guardarTarea(conPaso: true) }
                    .disabled(limpio(primerPaso).isEmpty)
            }
            // O que Chispa la divida en pasos de unos 5 minutos (fase IA).
            BotonTerciarioLujo(titulo: "Divídemela", icono: .check) {
                if let tarea = guardarTarea(conPaso: false) { dividir(tarea) }
            }
            Text(verbatim: limpio(frase))
                .font(.zenoTexto(.caption))
                .foregroundStyle(Lujo.marfilSecundario)
        }
        .padding(.horizontal, Lujo.margen)
    }

    private func campo(_ texto: Binding<String>, sugerencia: LocalizedStringKey) -> some View {
        // Se ve editable: fondo muy sutil, cursor dorado y una línea de oro fina al escribir.
        TextField("", text: texto, prompt: Text(sugerencia).foregroundStyle(Lujo.marfil.opacity(0.3)), axis: .vertical)
            .font(.zenoTitulo(.title3, .regular))
            .foregroundStyle(Lujo.marfil)
            .tint(Lujo.oro)
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
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Lujo.marfil.opacity(0.035)))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(LinearGradient(colors: [Lujo.oro.opacity(0.1), Lujo.oro, Lujo.oro.opacity(0.1)],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(height: 0.75)
                    .scaleEffect(x: escribiendo ? 1 : 0.0001)
                    .animation(Lujo.curva(), value: escribiendo)
            }
    }

    @ViewBuilder
    private func botonChico(_ titulo: LocalizedStringKey, fuerte: Bool, accion: @escaping () -> Void) -> some View {
        if fuerte {
            BotonPrimarioLujo(titulo, accion: accion)
        } else {
            BotonSecundarioLujo(titulo, accion: accion)
        }
    }

    // MARK: Voz

    /// El micrófono: un toque empieza a escuchar, otro toque deja de escuchar.
    private func alternarVoz() {
        toques += 1
        if dictado.activo {
            dictado.detener()
            return
        }
        escribiendo = false
        if modo == .ver {
            frase = ""
            withAnimation(Ritmo.contenido) { modo = .agregar }
        }
        dictado.empezar()
    }

    /// Captura por voz (fase IA): de lo dicho a tareas, con vista previa. Si es una sola, queda en el campo.
    private func procesarDictado() {
        // Las últimas palabras pueden llegar un instante después de dejar de escuchar.
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.7))
            separarLoDicho()
        }
    }

    private func separarLoDicho() {
        let dicho = limpio(frase)
        guard !dicho.isEmpty, modo == .agregar else { return }
        if Cuidado.suenaACrisis(dicho) {
            Hojas.compartidas.mostrar { VistaDeCuidado() }
            return
        }
        Task { @MainActor in
            let captura = await ServicioDeIA.compartido.capturar(dicho)
            // Varias tareas, o una con su día y hora: vista previa antes de guardar.
            let conFecha = captura.tareas.count == 1 && captura.tareas[0].fecha != nil
            guard captura.tareas.count > 1 || conFecha, modo == .agregar else { return }
            escribiendo = false
            Hojas.compartidas.mostrar {
                HojaCaptura(tareas: captura.tareas, conIA: !captura.deRespaldo) {
                    frase = ""
                    cerrarAgregar()
                }
            }
        }
    }

    /// Si la propuesta de ahora se explica por un patrón claro, Chispa lo dice (una vez al día cada uno).
    private func revisarPatron() {
        guard case .tarea(let tarea) = eleccion, enCurso == nil else { patronDeAhora = nil; return }
        let patron = Aprendizaje.patronDeAhora(
            propuesta: tarea.tamano, tipo: TipoDeTarea.de(tarea.titulo),
            hayGrandes: pendientes.contains { $0.tamano == .grande },
            nivel: MotorDeEnergia.nivel(puntaje), franja: Calendar.current.component(.hour, from: .now), eventos: eventos)
        // Si ya está dividida, "la divido en pasos" no aplica.
        let valido = patron.flatMap { p -> Aprendizaje.Patron? in
            if case .tipoCuesta = p, !tarea.pasos.isEmpty { return nil }
            return p
        }
        // Una vez al día cada patrón, para una tarea: si se vuelve a Hoy con esa misma tarea, sigue a la vista.
        let hoy = Date.now.formatted(.iso8601.year().month().day())
        var dichos = patronesDichos.hasPrefix(hoy) ? patronesDichos : hoy
        guard let valido else { patronDeAhora = nil; return }
        let marca = valido.clave + ":" + String(tarea.titulo.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0xFFFFFF })
        let yaDichos = dichos.split(separator: "|").dropFirst()
        if yaDichos.contains(Substring(marca)) { patronDeAhora = valido; return }
        if yaDichos.contains(where: { $0.hasPrefix(valido.clave + ":") }) { patronDeAhora = nil; return }
        dichos += "|" + marca
        patronesDichos = dichos
        patronDeAhora = valido
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
        porque = ""
        conPorque = false
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
        escribiendoPorque = false
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

    @discardableResult
    private func guardarTarea(conPaso: Bool) -> Tarea? {
        let titulo = limpio(frase)
        guard !titulo.isEmpty else { return nil }
        let paso = limpio(primerPaso)
        let tarea = Tarea(titulo: titulo,
                          tamano: ClasificadorDeTamano.tamano(de: titulo),
                          primerPaso: conPaso && !paso.isEmpty ? paso : nil)
        let anzuelo = String(limpio(porque).prefix(120))
        tarea.porque = anzuelo.isEmpty ? nil : anzuelo
        contexto.insert(tarea)
        plan.aplicar(a: tarea)
        plan = BorradorDePlan()
        Task { await AvisosDeTareas.sincronizar(contexto) }
        toques += 1
        escribiendo = false
        frase = ""
        primerPaso = ""
        porque = ""
        conPorque = false
        escribiendoPorque = false
        withAnimation(Ritmo.contenido) { modo = .ver }
        if Cuidado.suenaACrisis(anzuelo) {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.4))
                Hojas.compartidas.mostrar { VistaDeCuidado() }
            }
        }
        return tarea
    }

    /// Guarda un evento en el historial. La tarea se enlaza después de insertar, para que siempre quede guardada.
    private func registrar(_ tipo: TipoDeEvento, valor: Double? = nil, tarea: Tarea) {
        let evento = EventoDeEnergia(tipo: tipo, valor: valor)
        contexto.insert(evento)
        evento.tarea = tarea
        evento.tamanoCrudo = tarea.tamanoCrudo
        evento.tipoDeTareaCrudo = TipoDeTarea.de(tarea.titulo)?.rawValue
    }

    // Sin `toques += 1` en empezar, terminar y "Ahora no": el botón ya da su toque
    // (antes vibraba dos veces; Fable).
    private func empezar(_ tarea: Tarea) {
        registrar(.tareaEmpezada, tarea: tarea)
        withAnimation(Ritmo.contenido) { tarea.empezadaEn = .now }
    }

    private func terminar(_ tarea: Tarea) {
        // Con pasos (Divídemela): si quedan, se pasa al siguiente con un toque suave; la estrella y la
        // celebración llegan con el último.
        if !tarea.pasos.isEmpty && tarea.pasoActual < tarea.pasos.count - 1 {
            withAnimation(Ritmo.contenido) { AccionesDeTarea.completarPaso(tarea, en: contexto) }
            pasosHechos += 1
            return
        }
        celebrando = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(6))
            withAnimation(Lujo.curva()) { celebrando = false }
        }
        let celebracion = Celebracion.para(tarea, eventos: eventos, puntaje: puntaje)
        alTerminar(celebracion)
        // La tarea se va despacio, mientras Lumi celebra. Guarda cuánto tardó (para su propio promedio).
        withAnimation(Ritmo.contenido.delay(0.4)) {
            AccionesDeTarea.terminar(tarea, en: contexto)
            quiereAlgoIgual = false
        }
    }

    /// "Ahora no" nunca es un fracaso: la app aprende que esta hora no era, y lo intenta más tarde.
    private func ahoraNo(_ tarea: Tarea) {
        registrar(.ahoraNo, tarea: tarea)
        withAnimation(Ritmo.contenido) { tarea.empezadaEn = nil }
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
            .shadow(color: Lujo.oro.opacity(0.22), radius: 20)
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

/// La tarea del momento, en grande. Ya no tiene gestos ocultos: se empieza y se termina
/// con el botón de debajo (pedido de Diaz: era difícil de descubrir).
private struct TareaTocable: View {
    let tarea: Tarea
    let enCurso: Bool

    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    @State private var respira = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Los pasos de Divídemela son frases más largas: un poco más pequeñas, para que se lean enteras.
            Titular(texto: tarea.textoVisible, tamano: tarea.pasoDeAhora != nil ? .title : .largeTitle, alineacion: .leading)
            if tarea.pasoDeAhora != nil {
                Text("Paso de: \(tarea.titulo)")
                    .font(.zenoTexto(.footnote))
                    .foregroundStyle(Lujo.marfilSecundario)
                    .lineLimit(1)
            } else if tarea.primerPaso != nil {
                // Se muestra el primer paso; la tarea grande queda como contexto.
                Text("Primer paso de: \(tarea.titulo)")
                    .font(.zenoTexto(.footnote))
                    .foregroundStyle(Lujo.marfilSecundario)
            }
            // El anzuelo de la persona viste la tarea (y cada paso): para qué le importa.
            if let anzuelo = tarea.anzuelo {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    EstrellitaDeCuatro()
                        .fill(Lujo.oro.opacity(0.85))
                        .frame(width: 8, height: 8)
                    Text(verbatim: anzuelo)
                        .font(.zenoTitulo(.callout, .light, cursiva: true))
                        .foregroundStyle(Lujo.oro.opacity(0.9))
                        .lineLimit(2)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text("Para qué: \(anzuelo)"))
            }
        }
        .padding(.vertical, 4)
        // Sin empezar, la tarea respira una luz dorada: "empieza". Al mantenerla, se enciende.
        // El resplandor es una capa fija; solo cambia su opacidad (barato para la GPU).
        .background {
            Titular(texto: tarea.textoVisible, tamano: tarea.pasoDeAhora != nil ? .title : .largeTitle, alineacion: .leading)
                .colorMultiply(Lujo.oro)
                .blur(radius: 18)
                // Se dibuja una sola vez como imagen: el latido solo cambia la opacidad (no recalcula el desenfoque).
                .drawingGroup()
                .opacity(enCurso ? 0.35 : (respira ? 0.5 : 0.15))
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .onAppear {
            guard !reducirMovimiento else { return }
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) { respira = true }
        }
    }
}

/// Guarda la última elección de `MotorDeEnergia` y la repite mientras nada relevante cambie
/// (las tareas, la energía, el historial, "quiero algo igual" o el minuto). No es observable a propósito.
final class MemoriaDeEleccion {
    private var clave: Int?
    private var guardada: Eleccion = .nadaPendiente

    func eleccion(pendientes: [Tarea], puntaje: Double, eventos: [Senal], quiereAlgoIgual: Bool) -> Eleccion {
        var h = Hasher()
        for t in pendientes {
            h.combine(t.persistentModelID)
            h.combine(t.textoVisible)
            h.combine(t.tamanoCrudo)
            h.combine(t.porque)
            h.combine(t.fechaPlaneada)
            h.combine(t.empezadaEn)
        }
        h.combine(Int(puntaje.rounded()))
        h.combine(eventos.count)
        h.combine(eventos.last?.fecha)
        h.combine(quiereAlgoIgual)
        h.combine(Int(Date.now.timeIntervalSinceReferenceDate / 60))
        let nueva = h.finalize()
        if nueva != clave {
            guardada = MotorDeEnergia.elegir(pendientes: pendientes, puntaje: puntaje, eventos: eventos,
                                             quiereAlgoIgual: quiereAlgoIgual)
            clave = nueva
        }
        return guardada
    }
}
