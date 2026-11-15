import SwiftUI
import SwiftData

/// Las partes del día. "Cuando quieras" guarda lo que no tiene hora (solo se ve en el día de hoy).
enum ParteDelDia: Int, CaseIterable, Identifiable {
    case cuandoQuieras, manana, tarde, noche
    var id: Int { rawValue }

    var titulo: LocalizedStringKey {
        switch self {
        case .cuandoQuieras: "Cuando quieras"
        case .manana: "Mañana"
        case .tarde: "Tarde"
        case .noche: "Noche"
        }
    }

    static func de(_ fecha: Date, calendario: Calendar = .current) -> ParteDelDia {
        switch calendario.component(.hour, from: fecha) {
        case 5..<12: .manana
        case 12..<19: .tarde
        default: .noche
        }
    }
}

/// La página Tareas como vista del día (decisión de Diaz): paneles apilados que se solapan, uno
/// abierto y los demás como pestañas visibles, y abajo la tira de la semana. Sin vencidas, sin rojo.
struct MisTareasView: View {
    /// Dónde empieza el contenido, debajo de Lumi. Lo de encima se funde con el cielo.
    var arriba: CGFloat = 0
    @Environment(\.modelContext) private var contexto
    @Query(filter: #Predicate<Tarea> { $0.terminadaEn == nil }, sort: \Tarea.creadaEn)
    private var pendientes: [Tarea]
    @Query private var personas: [Persona]

    @State private var dia = Calendar.current.startOfDay(for: .now)
    @State private var abierta: ParteDelDia?
    @State private var marcando: Set<PersistentIdentifier> = []
    /// La tarea que se está editando: la página cambia a su editor, dentro del mismo universo.
    @State private var editando: Tarea?
    @Namespace private var espacio
    private let calendario = Calendar.current

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                if let tarea = editando {
                    EditorDeTarea(tarea: tarea) {
                        withAnimation(Lujo.curva()) { editando = nil }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, arriba + 4)
                    .padding(.bottom, 120)
                    .informaDesplazamiento()
                    .transition(.desenfoque)
                } else {
                    dia_
                        .padding(.top, 4)
                        .padding(.horizontal, 20)
                        // La hoja casi transparente se desliza con el contenido: sin líneas fijas.
                        .background(alignment: .top) { HojaDeFondo().padding(.top, -14) }
                        .padding(.top, arriba)
                        .padding(.bottom, 210)       // sitio para la tira de la semana y la barra
                        .informaDesplazamiento()
                        .transition(.desenfoque)
                }
            }
            .coordinateSpace(name: "pagina")
            .bordesFundidos(arriba: arriba, abajo: 190)
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)

            if editando == nil {
                FranjaDeSemana(dia: $dia)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 92)
                    .aparece(5)
                    .transition(.opacity)
            }
        }
        .foregroundStyle(Lujo.marfil)
        .onAppear {
            Desplazamiento.compartido.valor = 0
            #if DEBUG
            // -abrirEditor YES: abre directamente el editor de la primera tarea (para probar).
            if UserDefaults.standard.bool(forKey: "abrirEditor") { editando = pendientes.first }
            #endif
        }
        .onChange(of: dia) { _, _ in withAnimation(Lujo.curva()) { abierta = nil } }
    }

    // MARK: El día

    private var dia_: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 6) {
                EtiquetaLujo(calendario.isDateInToday(dia) ? "Hoy" : "Tus tareas")
                Text(dia, format: .dateTime.weekday(.wide))
                    .font(.zenoTitulo(.largeTitle))
                    .foregroundStyle(Lujo.marfil)
                    .textCase(nil)
                Text(dia, format: .dateTime.day().month(.wide))
                    .font(.zenoTexto(.footnote))
                    .foregroundStyle(Lujo.marfilSecundario)
            }
            .padding(.leading, 8)
            .aparece(0)

            // Los paneles se solapan: cada uno asoma sobre el anterior.
            VStack(spacing: -22) {
                ForEach(Array(partesVisibles.enumerated()), id: \.element) { orden, parte in
                    panel(parte)
                        .zIndex(Double(orden))
                        .aparece(orden + 1)
                }
            }
        }
    }

    private var esHoy: Bool { calendario.isDateInToday(dia) }

    private var partesVisibles: [ParteDelDia] {
        ParteDelDia.allCases.filter { $0 != .cuandoQuieras || esHoy }
    }

    /// Las tareas de una parte del día, para el día elegido.
    private func tareas(_ parte: ParteDelDia) -> [Tarea] {
        let inicio = dia
        let fin = calendario.date(byAdding: .day, value: 1, to: inicio) ?? inicio
        return pendientes.filter { t in
            guard let f = t.fechaPlaneada else { return parte == .cuandoQuieras && esHoy }
            // Si su hora ya pasó en otro día, vuelve a "cuando quieras" de hoy, sin reproche.
            if f < calendario.startOfDay(for: .now) { return parte == .cuandoQuieras && esHoy }
            return f >= inicio && f < fin && parte != .cuandoQuieras && ParteDelDia.de(f) == parte
        }
        .sorted { ($0.fechaPlaneada ?? .distantPast) < ($1.fechaPlaneada ?? .distantPast) }
    }

    /// El panel abierto: el que eligió la persona; si no, el de ahora (o el primero que tenga algo).
    private var panelAbierto: ParteDelDia {
        if let abierta, partesVisibles.contains(abierta) { return abierta }
        if esHoy {
            if !tareas(.cuandoQuieras).isEmpty { return .cuandoQuieras }
            let ahora = ParteDelDia.de(.now)
            if !tareas(ahora).isEmpty { return ahora }
        }
        return partesVisibles.first { !tareas($0).isEmpty } ?? (esHoy ? ParteDelDia.de(.now) : .manana)
    }

    // MARK: Paneles

    private func tinte(_ parte: ParteDelDia) -> Color {
        // Solo se toman los tonos de la nebulosa como referencia para los paneles; la nebulosa no se toca.
        let a = AparienciaLumi(semilla: personas.first?.semilla ?? Semilla(nombre: "zeno", anio: 2026, mes: 1, dia: 1))
        let c: SIMD3<Float>
        switch parte {
        case .cuandoQuieras: return Lujo.marfil
        case .manana: c = a.colorBrasa
        case .tarde: c = a.colorNube
        case .noche: c = a.colorFondo * 1.6
        }
        return Color(red: Double(c.x), green: Double(c.y), blue: Double(c.z))
    }

    private func panel(_ parte: ParteDelDia) -> some View {
        let lista = tareas(parte)
        let abierto = panelAbierto == parte
        let forma = RoundedRectangle(cornerRadius: 28, style: .continuous)
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(Lujo.curva(0.55)) { abierta = parte }
            } label: {
                HStack(spacing: 10) {
                    Text(parte.titulo)
                        .font(.zenoTitulo(.title3, .regular))
                        .foregroundStyle(Lujo.marfil)
                    Spacer()
                    if !lista.isEmpty {
                        Text(verbatim: "\(lista.count)")
                            .font(.zenoTexto(.caption, .medium))
                            .foregroundStyle(abierto ? Lujo.oro : Lujo.marfilSecundario)
                            .contentTransition(.numericText())
                    }
                    IconoDeParte(parte: parte, color: abierto ? Lujo.oro : Lujo.marfilSecundario)
                }
                .padding(.horizontal, 20)
                .frame(height: 58)
                .contentShape(Rectangle())
            }
            .buttonStyle(EstiloLujo())
            .sensoryFeedback(.selection, trigger: abierto) { _, ahora in ahora }
            .accessibilityAddTraits(abierto ? .isSelected : [])

            if abierto {
                VStack(spacing: 8) {
                    if lista.isEmpty {
                        Text(esHoy && parte == .cuandoQuieras ? "Nada pendiente." : "Nada aquí. Está bien.")
                            .font(.zenoTexto(.footnote))
                            .foregroundStyle(Lujo.marfilSecundario)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                    }
                    ForEach(lista) { tarea in fila(tarea) }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 34)              // sitio para que el panel siguiente asome sin tapar
                .transition(.opacity.combined(with: .offset(y: -6)))
            } else {
                Spacer().frame(height: 22)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                forma.fill(Color(red: 0.07, green: 0.075, blue: 0.13).opacity(0.86))
                forma.fill(LinearGradient(colors: [tinte(parte).opacity(parte == .cuandoQuieras ? 0.05 : 0.20),
                                                   tinte(parte).opacity(0.03)],
                                          startPoint: .top, endPoint: .bottom))
            }
        }
        .cantoPulido(radio: 28)
    }

    // MARK: Filas

    private func fila(_ tarea: Tarea) -> some View {
        let hecha = marcando.contains(tarea.persistentModelID)
        return HStack(alignment: .center, spacing: 14) {
            if let f = tarea.fechaPlaneada, f >= calendario.startOfDay(for: .now) {
                Text(f, format: .dateTime.hour().minute())
                    .font(.zenoTexto(.caption, .medium))
                    .foregroundStyle(Lujo.marfilSecundario)
                    .frame(width: 46, alignment: .leading)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(tarea.titulo)
                    .font(.zenoTitulo(.body, .regular))
                    .foregroundStyle(Lujo.marfil)
                if let paso = tarea.primerPaso {
                    Text("Primer paso: \(paso)")
                        .font(.zenoTexto(.caption))
                        .foregroundStyle(Lujo.marfilSecundario)
                } else if tarea.momentoDelAviso != nil {
                    Text("Con aviso")
                        .font(.zenoTexto(.caption))
                        .foregroundStyle(Lujo.oro.opacity(0.75))
                }
            }
            Spacer(minLength: 0)
            Button { completar(tarea) } label: {
                CheckDibujado(hecho: hecha)
                    .frame(width: 26, height: 26)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.success, trigger: hecha)
            .accessibilityLabel(Text("Marcar como hecha"))
        }
        .padding(.leading, 16)
        .padding(.trailing, 4)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Lujo.marfil.opacity(0.045)))
        .cantoPulido(radio: 18, intensidad: 0.7)
        .opacity(hecha ? 0.45 : 1)
        .scaleEffect(hecha ? 0.98 : 1)
        .animation(Lujo.curva(), value: hecha)
        // Tocar la tarea la abre para editarla (día, hora, aviso).
        .contentShape(Rectangle())
        .onTapGesture { withAnimation(Lujo.curva()) { editando = tarea } }
        .accessibilityAction(named: Text("Editar")) { editando = tarea }
        .contextMenu {
            Button("Editar") { withAnimation(Lujo.curva()) { editando = tarea } }
            Button("Borrar", role: .destructive) {
                withAnimation { contexto.delete(tarea) }
                Task { await AvisosDeTareas.sincronizar(contexto) }
            }
        }
    }

    /// El check se dibuja y la tarjeta se atenúa; un instante después la tarea se va.
    private func completar(_ tarea: Tarea) {
        withAnimation(Lujo.curva(0.5)) { _ = marcando.insert(tarea.persistentModelID) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let evento = EventoDeEnergia(tipo: .tareaTerminada)
            contexto.insert(evento)
            evento.tarea = tarea
            evento.tamanoCrudo = tarea.tamanoCrudo
            withAnimation(Lujo.curva()) { tarea.terminadaEn = .now }
            Task { await AvisosDeTareas.sincronizar(contexto) }
        }
    }
}

/// El check de completar: un círculo fino; al marcar, el trazo se dibuja solo.
struct CheckDibujado: View {
    let hecho: Bool

    var body: some View {
        ZStack {
            Circle().strokeBorder(Lujo.oro.opacity(hecho ? 0.9 : 0.5), lineWidth: 0.9)
            TrazoDeCheck()
                .trim(from: 0, to: hecho ? 1 : 0)
                .stroke(Lujo.oro, style: StrokeStyle(lineWidth: 1.3, lineCap: .round, lineJoin: .round))
                .padding(7)
        }
        .animation(Lujo.curva(0.55), value: hecho)
    }
}

private struct TrazoDeCheck: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY + r.height * 0.05))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.38, y: r.maxY - r.height * 0.12))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.15))
        return p
    }
}

/// Icono fino de cada parte del día (misma familia de trazo).
struct IconoDeParte: View {
    let parte: ParteDelDia
    var color: Color

    var body: some View {
        Canvas { ctx, size in
            let s = min(size.width, size.height)
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            var p = Path()
            switch parte {
            case .cuandoQuieras:
                p.addEllipse(in: CGRect(x: c.x - s * 0.32, y: c.y - s * 0.32, width: s * 0.64, height: s * 0.64))
                p.move(to: CGPoint(x: c.x - s * 0.12, y: c.y)); p.addLine(to: CGPoint(x: c.x + s * 0.12, y: c.y))
            case .manana:
                p.addEllipse(in: CGRect(x: c.x - s * 0.16, y: c.y - s * 0.16, width: s * 0.32, height: s * 0.32))
                for i in 0..<8 {
                    let a = Double(i) * .pi / 4
                    p.move(to: CGPoint(x: c.x + cos(a) * s * 0.27, y: c.y + sin(a) * s * 0.27))
                    p.addLine(to: CGPoint(x: c.x + cos(a) * s * 0.40, y: c.y + sin(a) * s * 0.40))
                }
            case .tarde:
                p.addArc(center: CGPoint(x: c.x, y: c.y + s * 0.12), radius: s * 0.26,
                         startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
                p.move(to: CGPoint(x: c.x - s * 0.42, y: c.y + s * 0.12)); p.addLine(to: CGPoint(x: c.x + s * 0.42, y: c.y + s * 0.12))
            case .noche:
                p.addArc(center: c, radius: s * 0.3, startAngle: .degrees(60), endAngle: .degrees(300), clockwise: false)
                p.addArc(center: CGPoint(x: c.x + s * 0.14, y: c.y), radius: s * 0.22,
                         startAngle: .degrees(270), endAngle: .degrees(90), clockwise: true)
            }
            ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: 1.1, lineCap: .round, lineJoin: .round))
        }
        .frame(width: 18, height: 18)
        .accessibilityHidden(true)
    }
}

/// La tira de días: esta semana y las dos siguientes (cubre todo lo que se puede planear),
/// se desliza de lado. Hoy siempre en oro; el día elegido, con un borde fino que se desliza.
struct FranjaDeSemana: View {
    @Binding var dia: Date
    @Namespace private var espacio
    @State private var ancla: Date?
    private let calendario = Calendar.current

    @ViewBuilder
    private func celda(_ d: Date) -> some View {
                let elegido = calendario.isDate(d, inSameDayAs: dia)
                let hoy = calendario.isDateInToday(d)
                Button {
                    withAnimation(Lujo.curva(0.5)) { dia = d }
                } label: {
                    VStack(spacing: 5) {
                        Text(d, format: .dateTime.weekday(.narrow))
                            .font(.lujoEtiqueta(.caption2, .medium))
                            .foregroundStyle(hoy ? Lujo.oro : Lujo.marfilSecundario)
                        Text(d, format: .dateTime.day())
                            .font(.zenoTitulo(.callout, hoy ? .regular : .light))
                            .foregroundStyle(hoy ? Lujo.oro : Lujo.marfil.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background {
                        if elegido {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Lujo.oro.opacity(0.7), lineWidth: 0.75)
                                .matchedGeometryEffect(id: "dia", in: espacio)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(EstiloLujo())
                .sensoryFeedback(.selection, trigger: elegido) { _, ahora in ahora }
                .accessibilityAddTraits(elegido ? .isSelected : [])
    }

    private var semana: [Date] {
        let hoy = calendario.startOfDay(for: .now)
        let inicio = calendario.dateInterval(of: .weekOfYear, for: hoy)?.start ?? hoy
        return (0..<21).compactMap { calendario.date(byAdding: .day, value: $0, to: inicio) }
    }

    /// La semana a la que pertenece un día (0, 1 o 2), para deslizar de semana en semana.
    private func semanaDe(_ d: Date) -> Int {
        (semana.firstIndex { calendario.isDate($0, inSameDayAs: d) } ?? 0) / 7
    }

    var body: some View {
        GeometryReader { geo in
            let ancho = geo.size.width / 7
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(semana, id: \.self) { d in
                        celda(d)
                            .frame(width: ancho)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            // Se asienta de semana en semana (7 días por página).
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $ancla, anchor: .leading)
            .onAppear { ancla = semana[semanaDe(dia) * 7] }
        }
        .frame(height: 52)
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color(red: 0.06, green: 0.065, blue: 0.11).opacity(0.88)))
        .cantoPulido(radio: 22)
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
    }
}
