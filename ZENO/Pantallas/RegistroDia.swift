import SwiftUI

// Las tres horas del día en una sola pantalla (Diaz, 21 nov 2026: "nada genérico, natural, fluido y con
// calidad"). Diaz eligió la 1, Curva viva: es la del registro. Las otras quedan para pruebas (`-disenoDia 2|3`).
// 1 · Curva viva: su curva de energía real (la misma cuenta que usa ZENO) se transforma al tocar.
// 2 · Esfera: un reloj de 24 horas con su día encendido; se gira tocando o arrastrando el aro.
// 3 · Frase: una frase con tres palabras doradas que ruedan al tocarlas.

/// Las tres horas y sus valores posibles (los mismos del registro de siempre). Funciones puras.
struct DiaDeEnergia: Equatable {
    var despertar: Double
    var pico: Double
    var apagado: Double

    static let opcionesDespertar: [Double] = [5.5, 7, 9, 11]
    static let opcionesPico: [Double] = [10, 13, 17, 21]
    static let opcionesApagado: [Double] = [20.5, 22, 0, 2]
    static let comun = DiaDeEnergia(despertar: 7, pico: 10, apagado: 22)

    /// El apagado en la misma escala que el despertar (las 0 y las 2 son "después de medianoche").
    var apagadoSeguido: Double { apagado < despertar ? apagado + 24 : apagado }
    var horasDespierto: Double { apagadoSeguido - despertar }

    /// ¿Cabe el pico dentro del día (al menos una hora después de despertar y antes de apagarse)?
    func picoCabe(_ p: Double) -> Bool { p >= despertar + 1 && p <= apagadoSeguido - 1 }

    /// Siempre un día válido: si el pico quedó fuera, pasa al valor posible más cercano que sí cabe.
    func ajustado() -> DiaDeEnergia {
        guard !picoCabe(pico) else { return self }
        var copia = self
        let validos = Self.opcionesPico.filter(picoCabe)
        copia.pico = validos.min(by: { abs($0 - pico) < abs($1 - pico) }) ?? (despertar + horasDespierto / 2)
        return copia
    }

    /// El valor siguiente al tocar (el pico salta los que no caben).
    func siguiente(_ parte: Parte) -> DiaDeEnergia {
        var copia = self
        switch parte {
        case .despertar: copia.despertar = Self.despues(despertar, en: Self.opcionesDespertar)
        case .apagado: copia.apagado = Self.despues(apagado, en: Self.opcionesApagado)
        case .pico:
            let validos = Self.opcionesPico.filter(picoCabe)
            copia.pico = Self.despues(pico, en: validos.isEmpty ? Self.opcionesPico : validos)
        }
        return copia.ajustado()
    }

    enum Parte: CaseIterable { case despertar, pico, apagado }

    static func despues(_ valor: Double, en opciones: [Double]) -> Double {
        guard let i = opciones.firstIndex(of: valor) else { return opciones.first ?? valor }
        return opciones[(i + 1) % opciones.count]
    }

    /// La opción posible más cercana a una hora cualquiera (para arrastrar sin tener que ser preciso).
    static func cercana(_ hora: Double, en opciones: [Double]) -> Double {
        func distancia(_ a: Double, _ b: Double) -> Double { let d = abs(a - b).truncatingRemainder(dividingBy: 24); return min(d, 24 - d) }
        return opciones.min(by: { distancia($0, hora) < distancia($1, hora) }) ?? hora
    }

    static func hora(_ h: Double) -> String {
        let t = (h.truncatingRemainder(dividingBy: 24) + 24).truncatingRemainder(dividingBy: 24)
        return String(format: "%d:%02d", Int(t), Int((t - floor(t)) * 60 + 0.5))
    }

    static func momento(_ pico: Double) -> LocalizedStringKey {
        switch pico {
        case ..<12: "por la mañana"
        case ..<15: "al mediodía"
        case ..<19: "por la tarde"
        default: "por la noche"
        }
    }

    static func momentoCorto(_ pico: Double) -> LocalizedStringKey {
        switch pico {
        case ..<12: "Mañana"
        case ..<15: "Mediodía"
        case ..<19: "Tarde"
        default: "Noche"
        }
    }
}

// MARK: - 1 · Curva viva

/// La curva de energía del día (la misma `curvaBase` del cerebro), como forma animable:
/// al cambiar una hora, la curva se transforma suavemente hacia la nueva.
private struct FormaDeCurva: Shape {
    var despertar: Double
    var pico: Double
    var apagado: Double
    /// La ventana dibujada: de las 4 a las 4 del día siguiente.
    static let inicio = 4.0
    var cerrada = false

    var animatableData: AnimatablePair<Double, AnimatablePair<Double, Double>> {
        get { AnimatablePair(despertar, AnimatablePair(pico, apagado)) }
        set { despertar = newValue.first; pico = newValue.second.first; apagado = newValue.second.second }
    }

    static func x(_ hora: Double, ancho: CGFloat) -> CGFloat {
        var h = hora - inicio
        while h < 0 { h += 24 }
        while h > 24 { h -= 24 }
        return ancho * h / 24
    }

    static func energia(_ hora: Double, _ d: Double, _ p: Double, _ a: Double) -> Double {
        MotorDeEnergia.curvaBase(hora: hora.truncatingRemainder(dividingBy: 24), despertar: d, pico: p,
                                 apagado: a.truncatingRemainder(dividingBy: 24))
    }

    /// La energía suavizada (media gaussiana de ±1,5 h): la curva base tiene escalones al despertar y al
    /// dormir; aquí se ve como una onda continua, que es como se siente un día.
    static func suave(_ hora: Double, _ d: Double, _ p: Double, _ a: Double) -> Double {
        var suma = 0.0, pesos = 0.0
        for k in -6...6 {
            let w = exp(-Double(k * k) / 18)
            suma += w * energia(hora + Double(k) * 0.25, d, p, a)
            pesos += w
        }
        return suma / pesos
    }

    static func y(_ e: Double, alto: CGFloat) -> CGFloat { alto - alto * CGFloat((e - 6) / 92) }

    func path(in r: CGRect) -> Path {
        var linea = Path()
        let pasos = 96
        let puntos = (0...pasos).map { i -> CGPoint in
            let hora = Self.inicio + 24 * Double(i) / Double(pasos)
            return CGPoint(x: r.width * CGFloat(i) / CGFloat(pasos), y: Self.y(Self.suave(hora, despertar, pico, apagado), alto: r.height))
        }
        linea.move(to: puntos[0])
        for i in 1..<puntos.count {
            let medio = CGPoint(x: (puntos[i - 1].x + puntos[i].x) / 2, y: (puntos[i - 1].y + puntos[i].y) / 2)
            linea.addQuadCurve(to: medio, control: puntos[i - 1])
        }
        linea.addLine(to: puntos[pasos])
        if cerrada {
            linea.addLine(to: CGPoint(x: r.width, y: r.height))
            linea.addLine(to: CGPoint(x: 0, y: r.height))
            linea.closeSubpath()
        }
        return linea
    }
}

struct DiaCurvaViva: View {
    @Binding var dia: DiaDeEnergia
    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    @State private var toques = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 44) {
            GeometryReader { geo in
                let ancho = geo.size.width, alto = geo.size.height
                let picoX = FormaDeCurva.x(dia.pico, ancho: ancho)
                let picoY = FormaDeCurva.y(FormaDeCurva.suave(dia.pico, dia.despertar, dia.pico, dia.apagadoSeguido), alto: alto)
                ZStack(alignment: .topLeading) {
                    // La línea del horizonte y las horas de referencia, muy tenues.
                    Rectangle().fill(Lujo.marfil.opacity(0.10)).frame(height: 0.5).offset(y: alto)
                    ForEach([6.0, 12, 18, 24], id: \.self) { h in
                        Text(verbatim: DiaDeEnergia.hora(h))
                            .font(.zenoTexto(.caption2))
                            .foregroundStyle(Lujo.marfil.opacity(0.28))
                            .position(x: FormaDeCurva.x(h, ancho: ancho), y: alto + 14)
                    }
                    // La curva: un velo dorado debajo y el trazo fino encima.
                    FormaDeCurva(despertar: dia.despertar, pico: dia.pico, apagado: dia.apagadoSeguido, cerrada: true)
                        .fill(LinearGradient(colors: [Lujo.oro.opacity(0.20), Lujo.oro.opacity(0)], startPoint: .top, endPoint: .bottom))
                    FormaDeCurva(despertar: dia.despertar, pico: dia.pico, apagado: dia.apagadoSeguido)
                        .stroke(LinearGradient(colors: [Lujo.oro.opacity(0.35), Lujo.oro, Lujo.oro.opacity(0.35)],
                                               startPoint: .leading, endPoint: .trailing),
                                style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
                    // Despertar y apagado: una marca fina sobre el horizonte.
                    marca(x: FormaDeCurva.x(dia.despertar, ancho: ancho), alto: alto)
                    marca(x: FormaDeCurva.x(dia.apagado, ancho: ancho), alto: alto)
                    // El pico: una estrellita de cuatro puntas con su halo.
                    EstrellitaDeCuatro()
                        .fill(Lujo.oro)
                        .frame(width: 12, height: 12)
                        .shadow(color: Lujo.oro.opacity(0.7), radius: 6)
                        .position(x: picoX, y: picoY - 10)
                }
                .contentShape(Rectangle())
                // Tocar la curva: la marca más cercana va a la hora posible más cercana.
                .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                    mover(a: FormaDeCurva.inicio + 24 * Double(g.location.x / max(ancho, 1)))
                })
            }
            .frame(height: 190)
            .padding(.top, 18)
            .animation(reducirMovimiento ? nil : .spring(response: 0.55, dampingFraction: 0.86), value: dia)

            HStack(alignment: .top, spacing: 0) {
                valor("Despierto", Text(verbatim: DiaDeEnergia.hora(dia.despertar)), .despertar)
                valor("Más energía", Text(DiaDeEnergia.momentoCorto(dia.pico)), .pico)
                valor("Me apago", Text(verbatim: DiaDeEnergia.hora(dia.apagado)), .apagado)
            }
        }
        .sensoryFeedback(.selection, trigger: toques)
    }

    private func marca(x: CGFloat, alto: CGFloat) -> some View {
        Capsule().fill(Lujo.marfil.opacity(0.55)).frame(width: 1, height: 10).position(x: x, y: alto - 5)
    }

    private func valor(_ titulo: LocalizedStringKey, _ texto: Text, _ parte: DiaDeEnergia.Parte) -> some View {
        Button {
            toques += 1
            dia = dia.siguiente(parte)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                EtiquetaLujo(titulo)
                texto
                    .font(.zenoTitulo(.title3, .regular))
                    .foregroundStyle(Lujo.marfil)
                    .contentTransition(.numericText())
                Rectangle().fill(Lujo.oro.opacity(0.5)).frame(width: 18, height: 0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(EstiloLujo(conReflejo: false))
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("Toca para cambiarlo"))
    }

    private func mover(a hora: Double) {
        // La marca más cercana a donde se tocó (el pico cuenta por su posición en la curva).
        let candidatos: [(DiaDeEnergia.Parte, Double)] = [(.despertar, dia.despertar), (.pico, dia.pico), (.apagado, dia.apagado)]
        func d(_ a: Double, _ b: Double) -> Double { let x = abs(a - b).truncatingRemainder(dividingBy: 24); return min(x, 24 - x) }
        guard let parte = candidatos.min(by: { d($0.1, hora) < d($1.1, hora) })?.0 else { return }
        var nuevo = dia
        switch parte {
        case .despertar: nuevo.despertar = DiaDeEnergia.cercana(hora, en: DiaDeEnergia.opcionesDespertar)
        case .pico: nuevo.pico = DiaDeEnergia.cercana(hora, en: DiaDeEnergia.opcionesPico.filter(dia.picoCabe))
        case .apagado: nuevo.apagado = DiaDeEnergia.cercana(hora, en: DiaDeEnergia.opcionesApagado)
        }
        nuevo = nuevo.ajustado()
        if nuevo != dia { toques += 1; dia = nuevo }
    }
}

// MARK: - 2 · Esfera de 24 horas

/// Un arco del aro de 24 horas, animable (de una hora a otra; las 12 arriba, la medianoche abajo).
private struct ArcoDeHoras: Shape {
    var desde: Double
    var hasta: Double
    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(desde, hasta) }
        set { desde = newValue.first; hasta = newValue.second }
    }
    static func angulo(_ hora: Double) -> Angle { .degrees(hora / 24 * 360 + 90) }
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.addArc(center: CGPoint(x: r.midX, y: r.midY), radius: min(r.width, r.height) / 2,
                 startAngle: Self.angulo(desde), endAngle: Self.angulo(hasta), clockwise: false)
        return p
    }
}

struct DiaEsfera: View {
    @Binding var dia: DiaDeEnergia
    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    @State private var toques = 0

    var body: some View {
        VStack(spacing: 26) {
            GeometryReader { geo in
                let lado = min(geo.size.width, geo.size.height)
                let radio = lado / 2 - 18
                let centro = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                ZStack {
                    // Las 24 horas: rayitas finas, las cuatro principales algo más largas, con su número.
                    ForEach(0..<24, id: \.self) { h in
                        let principal = h % 6 == 0
                        Capsule()
                            .fill(Lujo.marfil.opacity(principal ? 0.45 : 0.16))
                            .frame(width: 1, height: principal ? 9 : 5)
                            .offset(y: -(radio + 9))
                            .rotationEffect(ArcoDeHoras.angulo(Double(h)) - .degrees(270))
                    }
                    ForEach([0, 6, 12, 18], id: \.self) { h in
                        let a = ArcoDeHoras.angulo(Double(h)).radians
                        Text(verbatim: "\(h)")
                            .font(.zenoTexto(.caption2))
                            .foregroundStyle(Lujo.marfil.opacity(0.35))
                            .position(x: centro.x + cos(a) * (radio - 16), y: centro.y + sin(a) * (radio - 16))
                    }
                    // La noche: el aro entero, apenas visible. El día: el arco encendido en oro.
                    Circle().stroke(Lujo.marfil.opacity(0.07), lineWidth: 2)
                        .frame(width: radio * 2, height: radio * 2)
                    ArcoDeHoras(desde: dia.despertar, hasta: dia.apagadoSeguido)
                        .stroke(Lujo.oro.opacity(0.16), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: radio * 2, height: radio * 2)
                    ArcoDeHoras(desde: dia.despertar, hasta: dia.apagadoSeguido)
                        .stroke(LinearGradient(colors: [Lujo.oro.opacity(0.6), Lujo.oro], startPoint: .bottomLeading, endPoint: .topTrailing),
                                style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                        .frame(width: radio * 2, height: radio * 2)
                    // Los extremos del día y el pico (estrellita) sobre el aro.
                    punto(dia.despertar, centro: centro, radio: radio) { Circle().fill(Lujo.marfil).frame(width: 7, height: 7) }
                    punto(dia.apagadoSeguido, centro: centro, radio: radio) {
                        Circle().strokeBorder(Lujo.marfil, lineWidth: 1.2).frame(width: 8, height: 8)
                    }
                    punto(dia.pico, centro: centro, radio: radio) {
                        EstrellitaDeCuatro().fill(Lujo.oro).frame(width: 14, height: 14)
                            .shadow(color: Lujo.oro.opacity(0.8), radius: 6)
                    }
                    // En el centro: cuántas horas de día tiene.
                    VStack(spacing: 2) {
                        Text(verbatim: "\(Int(dia.horasDespierto.rounded())) h")
                            .font(.zenoTitulo(.title, .light))
                            .foregroundStyle(Lujo.marfil)
                            .contentTransition(.numericText())
                        Text("de día")
                            .font(.zenoTexto(.caption))
                            .foregroundStyle(Lujo.marfilSecundario)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .contentShape(Circle().inset(by: -10))
                // Tocar o arrastrar sobre el aro: lo más cercano (despertar, pico o apagado) va ahí.
                .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                    let dx = g.location.x - centro.x, dy = g.location.y - centro.y
                    guard hypot(dx, dy) > radio * 0.45 else { return }
                    var grados = atan2(dy, dx) * 180 / .pi - 90
                    while grados < 0 { grados += 360 }
                    mover(a: grados / 360 * 24)
                })
            }
            .frame(height: 250)
            .animation(reducirMovimiento ? nil : .spring(response: 0.5, dampingFraction: 0.85), value: dia)

            HStack(spacing: 0) {
                leyenda("Despierto", Text(verbatim: DiaDeEnergia.hora(dia.despertar)), .despertar)
                leyenda("Más energía", Text(DiaDeEnergia.momentoCorto(dia.pico)), .pico)
                leyenda("Me apago", Text(verbatim: DiaDeEnergia.hora(dia.apagado)), .apagado)
            }
        }
        .sensoryFeedback(.selection, trigger: toques)
    }

    private func punto<V: View>(_ hora: Double, centro: CGPoint, radio: CGFloat, @ViewBuilder _ marca: () -> V) -> some View {
        let a = ArcoDeHoras.angulo(hora).radians
        return marca().position(x: centro.x + cos(a) * radio, y: centro.y + sin(a) * radio)
    }

    private func leyenda(_ titulo: LocalizedStringKey, _ texto: Text, _ parte: DiaDeEnergia.Parte) -> some View {
        Button {
            toques += 1
            dia = dia.siguiente(parte)
        } label: {
            VStack(spacing: 5) {
                EtiquetaLujo(titulo)
                texto.font(.zenoTitulo(.title3, .regular)).foregroundStyle(Lujo.marfil).contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(EstiloLujo(conReflejo: false))
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("Toca para cambiarlo"))
    }

    private func mover(a hora: Double) {
        func d(_ a: Double, _ b: Double) -> Double { let x = abs(a - b).truncatingRemainder(dividingBy: 24); return min(x, 24 - x) }
        let candidatos: [(DiaDeEnergia.Parte, Double)] = [(.despertar, dia.despertar), (.pico, dia.pico), (.apagado, dia.apagado)]
        guard let parte = candidatos.min(by: { d($0.1, hora) < d($1.1, hora) })?.0 else { return }
        var nuevo = dia
        switch parte {
        case .despertar: nuevo.despertar = DiaDeEnergia.cercana(hora, en: DiaDeEnergia.opcionesDespertar)
        case .pico: nuevo.pico = DiaDeEnergia.cercana(hora, en: DiaDeEnergia.opcionesPico.filter(dia.picoCabe))
        case .apagado: nuevo.apagado = DiaDeEnergia.cercana(hora, en: DiaDeEnergia.opcionesApagado)
        }
        nuevo = nuevo.ajustado()
        if nuevo != dia { toques += 1; dia = nuevo }
    }
}

// MARK: - 3 · Frase

struct DiaFrase: View {
    @Binding var dia: DiaDeEnergia
    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    @State private var toques = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            linea { Text("Me despierto a las") } valor: {
                palabra(Text(verbatim: DiaDeEnergia.hora(dia.despertar)), .despertar)
                Text(verbatim: ",").padding(.leading, -6)
            }
            linea { Text("tengo más energía") } valor: { EmptyView() }
            linea { EmptyView() } valor: {
                palabra(Text(DiaDeEnergia.momento(dia.pico)), .pico)
            }
            linea { Text("y me apago a las") } valor: {
                palabra(Text(verbatim: DiaDeEnergia.hora(dia.apagado)), .apagado)
                Text(verbatim: ".").padding(.leading, -6)
            }
            Text("Toca las palabras doradas para cambiarlas.")
                .font(.zenoTexto(.footnote))
                .foregroundStyle(Lujo.marfilSecundario)
                .padding(.top, 18)
        }
        .font(.zenoTitulo(.title, .light))
        .foregroundStyle(Lujo.marfil)
        .animation(reducirMovimiento ? nil : .spring(response: 0.45, dampingFraction: 0.86), value: dia)
        .sensoryFeedback(.selection, trigger: toques)
    }

    private func linea<A: View, B: View>(@ViewBuilder _ texto: () -> A, @ViewBuilder valor: () -> B) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            texto()
            valor()
        }
    }

    /// Una palabra dorada que rueda hacia arriba al tocarla, con un subrayado de puntos finos.
    private func palabra(_ texto: Text, _ parte: DiaDeEnergia.Parte) -> some View {
        Button {
            toques += 1
            dia = dia.siguiente(parte)
        } label: {
            texto
                .font(.zenoTitulo(.title, .regular, cursiva: true))
                .foregroundStyle(Lujo.oro)
                .contentTransition(.numericText(countsDown: false))
                .id(textoId(parte))
                .transition(.asymmetric(insertion: .push(from: .bottom), removal: .push(from: .bottom)))
                .padding(.bottom, 4)
                .overlay(alignment: .bottom) {
                    Line().stroke(Lujo.oro.opacity(0.55), style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [1, 4]))
                        .frame(height: 1)
                }
                .clipped()
                .contentShape(Rectangle())
        }
        .buttonStyle(EstiloLujo(conReflejo: false))
        .accessibilityHint(Text("Toca para cambiarlo"))
    }

    private func textoId(_ parte: DiaDeEnergia.Parte) -> String {
        switch parte {
        case .despertar: "d\(dia.despertar)"
        case .pico: "p\(dia.pico)"
        case .apagado: "a\(dia.apagado)"
        }
    }

    private struct Line: Shape {
        func path(in r: CGRect) -> Path {
            var p = Path(); p.move(to: CGPoint(x: 0, y: r.midY)); p.addLine(to: CGPoint(x: r.width, y: r.midY)); return p
        }
    }
}
