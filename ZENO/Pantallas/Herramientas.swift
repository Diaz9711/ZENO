import SwiftUI
import SwiftData

#if DEBUG
/// Solo para desarrollo: dibuja el ícono de la app a pantalla completa para capturarlo.
/// Se abre con el argumento de arranque `-generarIcono YES`.
struct IconoDeLaApp: View {
    var body: some View {
        GeometryReader { geo in
            let lado = geo.size.width
            ZStack {
                Color.black.ignoresSafeArea()
                ZStack {
                    NebulosaView(apariencia: AparienciaLumi(semilla: Semilla(nombre: UserDefaults.standard.string(forKey: "semillaIcono") ?? "lumi", anio: 2026, mes: 1, dia: 1)),
                                 energia: 0.45, calidez: 0.15, centro: .center)
                    if UserDefaults.standard.bool(forKey: "iconoLogo") {
                        // Ícono con el logo elegido por Diaz: la O de ZENO es una órbita.
                        ContenidoDelIcono(estilo: EstiloDeO(rawValue: UserDefaults.standard.integer(forKey: "estiloO")) ?? .planeta,
                                          soloO: UserDefaults.standard.bool(forKey: "iconoSoloO"), lado: lado)
                    } else {
                        LumiView(apariencia: AparienciaLumi(semilla: Semilla(nombre: UserDefaults.standard.string(forKey: "semillaIcono") ?? "lumi", anio: 2026, mes: 1, dia: 1)),
                                 energia: 0.85, forma: .estrella)
                            .frame(width: lado * 1.15)
                    }
                }
                .frame(width: lado, height: lado)
                .clipped()
                .position(x: lado / 2, y: geo.size.height / 2)
            }
        }
        .ignoresSafeArea()
    }
}

/// Cuadros por segundo reales de la pantalla (para saber si la fluidez es del simulador o de la app).
struct MedidorFPS: View {
    @State private var fps = 0.0
    @State private var cuadros = 0
    @State private var desde = Date()

    var body: some View {
        TimelineView(.animation) { linea in
            Text("\(Int(fps.rounded())) fps")
                .monospacedDigit()
                .onChange(of: linea.date) { _, ahora in
                    cuadros += 1
                    let t = ahora.timeIntervalSince(desde)
                    if t >= 1 {
                        fps = Double(cuadros) / t
                        cuadros = 0
                        desde = ahora
                    }
                }
        }
    }
}

/// Llena la app con tareas y logros de ejemplo, para ver las pantallas como las vería alguien que la usa.
enum DatosDeEjemplo {
    /// Con el argumento de arranque `-datosDeEjemplo YES` y sin persona: crea una de prueba con sus datos.
    @MainActor
    static func cargarSiHaceFalta(en contexto: ModelContext, hayPersona: Bool) {
        guard UserDefaults.standard.bool(forKey: "datosDeEjemplo"), !hayPersona else { return }
        contexto.insert(Persona(nombre: "Diaz", nacimientoAnio: 1999, nacimientoMes: 6, nacimientoDia: 15))
        cargar(en: contexto)
    }

    /// `-cieloDeEjemplo YES`: tareas terminadas repartidas en los últimos 12 días, para ver la constelación.
    @MainActor
    static func cargarCielo(en contexto: ModelContext) {
        guard UserDefaults.standard.bool(forKey: "cieloDeEjemplo") else { return }
        // Solo una vez: al abrir la app varias veces con esta prueba, el cielo se llenaba de más.
        guard !UserDefaults.standard.bool(forKey: "cieloDeEjemploCargado") else { return }
        UserDefaults.standard.set(true, forKey: "cieloDeEjemploCargado")
        let tamanos: [TamanoDeTarea] = [.chica, .mediana, .grande, .chica, .mediana]
        // `-estrellasDeEjemplo 200`: un cielo de alguien que lleva meses usando ZENO.
        let cuantas = UserDefaults.standard.integer(forKey: "estrellasDeEjemplo")
        if cuantas > 0 {
            for i in 0..<cuantas {
                let evento = EventoDeEnergia(tipo: .tareaTerminada, fecha: Date.now.addingTimeInterval(-Double(i + 1) * 14_000), valor: 600)
                evento.tamanoCrudo = tamanos[i % tamanos.count].rawValue
                contexto.insert(evento)
            }
            return
        }
        for dia in 1...12 {
            for i in 0..<(2 + dia % 4) {
                let fecha = Date.now.addingTimeInterval(-Double(dia) * 86_400 + Double(i) * 3_700)
                let evento = EventoDeEnergia(tipo: .tareaTerminada, fecha: fecha, valor: 600)
                evento.tamanoCrudo = tamanos[(dia + i) % tamanos.count].rawValue
                contexto.insert(evento)
            }
        }
    }

    /// `-pasosDeEjemplo N`: una tarea dividida con su porqué, en el paso 3 de 5, empezada hace N minutos
    /// (para ver el anillo de pasos y cómo baja su luz pasados los 10 minutos). Solo una vez.
    @MainActor
    static func cargarPasos(en contexto: ModelContext) {
        #if DEBUG
        guard let texto = UserDefaults.standard.string(forKey: "pasosDeEjemplo"), let minutos = Double(texto) else { return }
        let todas = (try? contexto.fetch(FetchDescriptor<Tarea>())) ?? []
        let tarea = todas.first(where: { $0.titulo == "Preparar la presentación del lunes" && $0.pasosCrudo != nil })
            ?? {
                let t = Tarea(titulo: "Preparar la presentación del lunes", tamano: .grande)
                contexto.insert(t)
                return t
            }()
        tarea.porque = "Que mi jefa vea lo que sé hacer"
        tarea.pasos = ["Abre el documento", "Escribe el título", "Elige las tres ideas principales",
                       "Haz una diapositiva por idea", "Revísala y guárdala"]
        tarea.pasoActual = 2
        tarea.empezadaEn = Date.now.addingTimeInterval(-minutos * 60)
        #endif
    }

    @MainActor
    static func cargar(en contexto: ModelContext) {
        let pendientes: [(String, TamanoDeTarea, String?)] = [
            ("Responder el correo de Ana", .chica, nil),
            ("Preparar la presentación del lunes", .grande, "Abrir el archivo y escribir el título"),
            ("Ordenar el escritorio", .mediana, nil),
            ("Llamar al dentista", .chica, nil),
            ("Leer diez páginas", .mediana, nil)
        ]
        for (titulo, tamano, paso) in pendientes {
            contexto.insert(Tarea(titulo: titulo, tamano: tamano, primerPaso: paso))
        }

        // Dos tareas ya hechas hoy, con su duración.
        let hechas: [(String, TimeInterval, TimeInterval)] = [
            ("Tender la cama", 35 * 60, 4 * 60),
            ("Pagar la luz", 2 * 3600, 9 * 60)
        ]
        for (titulo, haceCuanto, duracion) in hechas {
            let tarea = Tarea(titulo: titulo, tamano: .chica)
            let fin = Date.now.addingTimeInterval(-haceCuanto)
            tarea.empezadaEn = fin.addingTimeInterval(-duracion)
            tarea.terminadaEn = fin
            contexto.insert(tarea)
            let evento = EventoDeEnergia(tipo: .tareaTerminada, fecha: fin, valor: duracion)
            contexto.insert(evento)
            evento.tarea = tarea
            evento.tamanoCrudo = tarea.tamanoCrudo
        }
    }
}
#endif
