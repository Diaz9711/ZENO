import SwiftUI
import CoreHaptics

// MARK: - Tiempo de cada tarea

extension Tarea {
    /// Cuánto dura el anillo de luz. Un primer paso es de dos minutos, como promete la app.
    var minutosPrevistos: Double {
        if primerPaso != nil { return 2 }
        switch tamano {
        case .chica: return 5
        case .mediana: return 15
        case .grande: return 25
        }
    }

    /// Una tarea empezada hace poco sigue "en curso" aunque se cierre y se abra la app.
    var estaEnCurso: Bool {
        guard terminadaEn == nil, let inicio = empezadaEn else { return false }
        return Date.now.timeIntervalSince(inicio) < 6 * 3600
    }
}

// MARK: - Celebración

/// Cómo celebra Lumi una tarea terminada. Sin confeti ni sonidos: luz, postura y movimiento.
struct Celebracion: Equatable {
    /// Tarea grande: la onda llega más lejos y Lumi queda un poco más brillante el resto del día.
    var grande = false
    /// Tercera tarea seguida: Lumi da un giro lento sobre sí misma.
    var enRacha = false
    /// Terminada con energía baja: el fondo se calienta un poco.
    var conEnergiaBaja = false

    /// A partir del historial de hoy (incluido el evento recién guardado).
    static func para(_ tarea: Tarea, eventos: [EventoDeEnergia], puntaje: Double,
                     calendario: Calendar = .current) -> Celebracion {
        let hoy = eventos.filter { calendario.isDateInToday($0.fecha) }
        // Las últimas tres decisiones de hoy fueron "terminé".
        let decisiones = hoy.filter { $0.tipo == .tareaTerminada || $0.tipo == .ahoraNo }.suffix(2)
        let seguidas = decisiones.count == 2 && decisiones.allSatisfy { $0.tipo == .tareaTerminada }
        return Celebracion(grande: tarea.tamano == .grande && tarea.primerPaso == nil,
                           enRacha: seguidas,
                           conEnergiaBaja: MotorDeEnergia.nivel(puntaje) == .baja)
    }
}

// MARK: - Anillo de tiempo

/// Un anillo de luz alrededor de Lumi que se va consumiendo: el tiempo hecho visible.
/// Cuando se acaba no hay alarma; queda un círculo tenue, sin prisa.
struct AnilloDeTiempoView: View {
    let inicio: Date
    let minutos: Double
    var color: Color = .oroZeno

    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento

    var body: some View {
        TimelineView(.animation(minimumInterval: reducirMovimiento ? 1 : 1.0 / 20, paused: false)) { linea in
            let total = max(minutos * 60, 1)
            let restante = max(0, 1 - linea.date.timeIntervalSince(inicio) / total)
            let terminado = restante <= 0

            ZStack {
                // Huella del recorrido completo, muy tenue.
                Circle()
                    .stroke(color.opacity(terminado ? 0.30 : 0.10), lineWidth: 2)

                if !terminado {
                    // Brillo difuso detrás de la línea.
                    Circle()
                        .trim(from: 0, to: restante)
                        .stroke(color.opacity(0.55), style: StrokeStyle(lineWidth: 9, lineCap: .round))
                        .blur(radius: 7)
                    // La línea de luz.
                    Circle()
                        .trim(from: 0, to: restante)
                        .stroke(LinearGradient(colors: [color.opacity(0.65), color, .white.opacity(0.95)],
                                               startPoint: .bottomLeading, endPoint: .topTrailing),
                                style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
                }
            }
            .rotationEffect(.degrees(-90))
            .animation(.easeInOut(duration: 1.2), value: terminado)
            .accessibilityElement()
            .accessibilityLabel(Text("Tiempo de la tarea"))
            .accessibilityValue(terminado
                ? Text("Terminado, sin prisa")
                : Text("Quedan \(Int(ceil(restante * minutos))) minutos"))
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Onda de luz

/// La onda cálida que sale de Lumi y recorre toda la pantalla (1,5 segundos).
struct OndaDeLuzView: View {
    let centro: CGPoint
    let grande: Bool
    let numero: Int

    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    private let calido = Color(red: 1.0, green: 0.78, blue: 0.45)

    var body: some View {
        GeometryReader { geo in
            let alcance = hypot(geo.size.width, geo.size.height) * (grande ? 2.6 : 1.9)

            KeyframeAnimator(initialValue: 0.0, trigger: numero) { p in
                let activo = numero > 0 && p > 0 && p < 1
                ZStack {
                    // Un resplandor que baña todo un instante.
                    calido.opacity(activo ? 0.22 * (1 - p) * (grande ? 1.3 : 1) : 0)
                        .blendMode(.plusLighter)

                    if !reducirMovimiento {
                        // El cuerpo de la onda: ancho y difuso.
                        Circle()
                            .stroke(calido.opacity(0.5), lineWidth: grande ? 110 : 80)
                            .blur(radius: grande ? 36 : 28)
                            .frame(width: alcance, height: alcance)
                            .scaleEffect(max(p, 0.001))
                            .opacity(activo ? (1 - p) : 0)
                            .position(centro)
                            .blendMode(.plusLighter)
                        // El frente de la onda: una línea de luz que se lee claramente.
                        Circle()
                            .stroke(calido.opacity(0.9), lineWidth: grande ? 10 : 7)
                            .blur(radius: 5)
                            .frame(width: alcance, height: alcance)
                            .scaleEffect(max(p, 0.001))
                            .opacity(activo ? (1 - p) * 0.9 : 0)
                            .position(centro)
                            .blendMode(.plusLighter)
                    }
                }
            } keyframes: { _ in
                // Lumi primero inhala (0,35 s) y luego suelta la onda.
                KeyframeTrack {
                    LinearKeyframe(0.0, duration: 0.35)
                    CubicKeyframe(1.0, duration: 1.15)
                    LinearKeyframe(0.0, duration: 0.01)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Háptica

/// Vibraciones suaves con Core Haptics: una ola que sube y baja, nunca un golpe seco.
final class Haptica {
    static let compartida = Haptica()
    private var motor: CHHapticEngine?

    private init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        motor = try? CHHapticEngine()
        motor?.isAutoShutdownEnabled = true
        motor?.resetHandler = { [weak self] in try? self?.motor?.start() }
    }

    /// La ola que acompaña a la onda de luz.
    func onda(grande: Bool) {
        guard let motor else { return }
        let fuerza: Float = grande ? 0.75 : 0.5
        let duracion = grande ? 0.9 : 0.6
        let continuo = CHHapticEvent(eventType: .hapticContinuous,
                                     parameters: [CHHapticEventParameter(parameterID: .hapticIntensity, value: fuerza),
                                                  CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.12)],
                                     relativeTime: 0.32, duration: duracion)
        let curva = CHHapticParameterCurve(parameterID: .hapticIntensityControl,
                                           controlPoints: [.init(relativeTime: 0, value: 0.15),
                                                           .init(relativeTime: duracion * 0.3, value: 1),
                                                           .init(relativeTime: duracion, value: 0)],
                                           relativeTime: 0.32)
        do {
            try motor.start()
            let patron = try CHHapticPattern(events: [continuo], parameterCurves: [curva])
            try motor.makePlayer(with: patron).start(atTime: CHHapticTimeImmediate)
        } catch {
            // Sin háptica no pasa nada: la luz ya celebra.
        }
    }
}
